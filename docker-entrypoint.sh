#!/usr/bin/bash
chmod 644 /data/etc/my.cnf

_get_config() {
  conf="$1"
   /usr/local/mysql/bin/mysqld --verbose --help --log-bin-index="$(mktemp -u)" 2>/dev/null | awk '$1 == "'"$conf"'" { print $2; exit }'
}
WSREP-NEW-CLUSTER="no"
DATA_DIR="$(_get_config 'datadir')"
if [ ! -d "$DATA_DIR/mysql" ]; then
  if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
    echo >&2 '错误：数据库未初始化，密码选项未指定 '
    echo >&2 '  你需要指定一个 MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD'
    exit 1
  fi

  mkdir -p "$DATA_DIR"
  chown mysql: "$DATA_DIR"

  echo "初始化数据库中($DATA_DIR)"
  /usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir="$DATA_DIR" --skip-name-resolve --force --basedir=/usr/local/mysql/ --rpm > /data/logs/mysql_install_db.log
  chown -R mysql: "$DATA_DIR"
  echo '数据库初始化完成'

  sed -i "s|server_audit_file_path|#server_audit_file_path|" /data/etc/my.cnf

  # Start mysqld to config it
  echo "执行启动/usr/local/mysql/bin/mysqld_safe --defaults-file=/data/etc/my.cnf --user=mysql --datadir="$DATA_DIR" --skip-name-resolve --basedir=/usr/local/mysql/ --skip-networking --nowatch"
  /usr/local/mysql/bin/mysqld_safe --defaults-file=/data/etc/my.cnf --user=mysql --datadir="$DATA_DIR" --skip-name-resolve --basedir=/usr/local/mysql/ --skip-networking --nowatch
  echo '执行成功'
  sleep 3

  mysql_options='--protocol=socket -uroot'

  if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
    # sed is for https://bugs.mysql.com/bug.php?id=20545
    echo "开始设置时区表/usr/local/mysql/bin/mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | /usr/local/mysql/bin/mysql $mysql_options mysql"
    /usr/local/mysql/bin/mysql_tzinfo_to_sql /usr/share/zoneinfo | \
      sed 's/Local time zone must be set--see zic manual page/FCTY/' | \
      /usr/local/mysql/bin/mysql $mysql_options mysql
  fi

  if [ -n "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
    export MYSQL_ROOT_PASSWORD="$(tr -dc _A-Z-a-z-0-9 < /dev/urandom | head -c10)"
    echo "生成root随机密码: $MYSQL_ROOT_PASSWORD"
  fi
    execute() {
        statement="$1"
        if [ -n "$statement" ]; then
          /usr/local/mysql/bin/mysql -ss $mysql_options -e "$statement"
        else
          cat /dev/stdin | /usr/local/mysql/bin/mysql -ss $mysql_options
       fi
    }

  # Create root user, set root password, drop useless table
  # Delete root user except for
  execute <<SQL
    -- What's done in this file shouldn't be replicated
    --  or products like mysql-fabric won't work
    SET @@SESSION.SQL_LOG_BIN=0;
    DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost','127.0.0.1') or User='' or Password='' ;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
    INSTALL PLUGIN sphinx SONAME 'ha_sphinx.so';
    INSTALL PLUGIN server_audit SONAME 'server_audit.so';
    INSTALL PLUGIN query_cache_info SONAME 'query_cache_info.so'; 
    DROP DATABASE IF EXISTS test ;
    FLUSH PRIVILEGES ;
SQL

  # https://mariadb.com/kb/en/library/mariadb-environment-variables/
  export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"

  # Create root user for $MYSQL_ROOT_HOST
  if [ "$MYSQL_ROOT_HOST" != '127.0.0.1' ]; then
    execute <<SQL
      CREATE USER 'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
      GRANT ALL ON *.* TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION ;
      FLUSH PRIVILEGES ;
SQL
  fi

  if [ "$MYSQL_DATABASE" ]; then
    execute "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;"
  fi
  if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
    execute "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;"

    if [ "$MYSQL_DATABASE" ]; then
      execute "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;"
    fi

    execute 'FLUSH PRIVILEGES ;'
  fi

  # Database cannot be specified when creating user,
  # otherwise it will fail with "Unknown database"
  if [ "$MYSQL_DATABASE" ]; then
    mysql_options="$mysql_options \"$MYSQL_DATABASE\""
  fi

  echo
  for f in /data/docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; execute < "$f"; echo ;;
      *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | execute; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done
  echo "尝试关闭数据库：/usr/local/mysql/bin/mysqladmin -uroot -p$MYSQL_PWD shutdown"
  if ! /usr/local/mysql/bin/mysqladmin -uroot -p$MYSQL_PWD shutdown; then
    echo >&2 '尝试验证停止失败'
    exit 1
  fi

  echo
  echo '数据库初始化完成，等待启动.'
  echo
  sed -i "s|#server_audit_file_path|server_audit_file_path|" /data/etc/my.cnf
fi

chown -R mysql: "$DATA_DIR"

if [ "$WSREP_NEW_CLUSTER" == 'yes' ]; then
    echo "WSREP_NEW_CLUSTER yes:$WSREP_NEW_CLUSTER"
    /usr/local/mysql/bin/mysqld_safe --defaults-file=/data/etc/my.cnf --basedir=/usr/local/mysql/ --wsrep-new-cluster  --wsrep-cluster-address="gcomm://"
else
    echo "WSREP_NEW_CLUSTER no:$WSREP_NEW_CLUSTER"
    /usr/local/mysql/bin/mysqld_safe --defaults-file=/data/etc/my.cnf --basedir=/usr/local/mysql/
fi
exec "$@"