## 该版本是mariadb源码编译安装组建比较全的一个版本，专门为了使用xtrabackup集群而出现的，已经内置了sphinx、MariaDB-Galera和xtrabackup等,该镜像比较大，找时间再进行精简

```
docker pull w303972870/mariadb-galera
```

|软件|版本|
|:---|:---|
|mariadb|10.3.10|


#### 启动命令示例：为了初始化必须指定一个默认的root密码MYSQL_ROOT_PASSWORD

```
docker run -dit -p 3306:3306  -p 4567:4567 -p 4568:4568 -p 4444:4444 -v /data/mariadb/:/data/ -v /etc/localtime:/etc/localtime -e MYSQL_ROOT_HOST=192.168.12.% -e MYSQL_ROOT_PASSWORD=123456 -e WSREP_NEW_CLUSTER=yes docker.io/w303972870/mariadb-galera
```

|变量|解释|
|:---|:---|
|MYSQL_ROOT_HOST|'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}|
|MYSQL_ROOT_PASSWORD|'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}|
|MYSQL_RANDOM_ROOT_PASSWORD|随机生成一个root密码|
|MYSQL_INITDB_SKIP_TZINFO|不导入时区信息到MYSQL中，默认不使用该参数进行导入时区|
|MYSQL_DATABASE|默认创建一个数据库|
|MYSQL_USER|新建一个用户|
|MYSQL_PASSWORD|新建用户的密码|
|WSREP_NEW_CLUSTER|集群用参，作为集群时，启动集群第一台时该值传入yes其他的传入no或者不传入即可(如果是全新的数据库，需要mysql_install_db先不要用这个参数，等初始化数据库后结束容器再加上这个参数启动第一台)|
|SKIP_INIT_SCRIPT|当存在这个参数任意值时不执行初始化等操作直接执行启动mysql命令，同时上面这些参数也会失效(集群非第一台机器启动命令要用到)|

### 使用集群必须再加上映射端口4567,4568,4444


### 启动之后，需要mysql -h 127.0.0.1 -p3306 -u root连接容器mysql后重新配置访问限制，例如：

```
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.12.%' IDENTIFIED BY '123456' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.17.0.%' IDENTIFIED BY '123456' WITH GRANT OPTION;
```

### 数据目录：/data/database/
### bin-log目录：/data/bin-logs/
### 日志目录：/data/logs/
### 默认配置文件：/data/etc/my.cnf


### 已开放3306端口

### 我的/data/mariadb-galera/目录结构，注意目录权限，无权限会影响启动
```
/data/mariadb-galera/
├── database
├── bin-logs
├── docker-entrypoint-initdb.d
├── etc
│   └── my.cnf
└── logs
```

### docker-entrypoint-initdb.d目录内可以放置.sh,.sql,.sq.gz三类文件，作用可以看docker-entrypoint.sh
```
  for f in /data/docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; execute < "$f"; echo ;;
      *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | execute; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done
```


## 使用步骤

1. 全新数据库需要初始化，第一台机器先初始化数据库：（先不要使用-e WSREP_NEW_CLUSTER=yes  选项，  
同时my.cnf先将wsrep_on=0之后执行以下命令启动容器，初始化数据库），初始化完成后需要GRANT设置访问权限

```
docker run -dit -p 3306:3306 --net host -p 4567:4567 -p 4568:4568 -p 4444:4444 -v /data/mariadb-galera/:/data/  -v /etc/localtime:/etc/localtime -e MYSQL_ROOT_HOST=172.17.0.% -e MYSQL_ROOT_PASSWORD=123456  docker.io/w303972870/mariadb-galera
```
2. 将第1步启动起来的容器结束掉，将my.cnf中的wsrep_on=1，重新启动第一台机器要加上 -e WSREP_NEW_CLUSTER=yes

```
docker run -dit -p 3306:3306 --net host -p 4567:4567 -p 4568:4568 -p 4444:4444 -v /data/mariadb-galera/:/data/  -v /etc/localtime:/etc/localtime -e MYSQL_ROOT_HOST=172.17.0.% -e MYSQL_ROOT_PASSWORD=123456 -e WSREP_NEW_CLUSTER=yes  docker.io/w303972870/mariadb-galera
```
3. 第二台机器不需要初始化数据库，直接启动加入集群即可，但是由于没有数据库，所以需要加上-e SKIP_INIT_SCRIPT=yes跳过初始化脚本

```
docker run -dit -p 3306:3306 --net host -p 4567:4567 -p 4568:4568 -p 4444:4444 -v /data/mariadb-galera/:/data/  -v /etc/localtime:/etc/localtime -e MYSQL_ROOT_HOST=172.17.0.% -e MYSQL_ROOT_PASSWORD=123456 -e SKIP_INIT_SCRIPT=yes  docker.io/w303972870/mariadb-galera
```

4. 第四台机器及以后多机器启动，跟第二台启动一样



**附上一个简单的my.cnf配置文件**

```
[client]
port= 3306
socket = /data/database/mysql.sock
default-character-set = utf8mb4
 
[mysqld]
port= 3306
socket = /data/database/mysql.sock
tmpdir = /tmp/
basedir=/usr/
datadir = /data/database/
pid-file = /data/database/mysql.pid
user = mysql
server-id = 1
bind-address=0.0.0.0 
init-connect = 'SET NAMES utf8mb4'
character-set-server = utf8mb4
skip-name-resolve
#skip-networking
 
max_connections= 16384
open_files_limit = 65535
table_open_cache = 1024
max_allowed_packet= 100M
binlog_cache_size = 1M
max_heap_table_size = 8M
tmp_table_size = 128M
 
read_buffer_size = 2M
read_rnd_buffer_size = 8M
sort_buffer_size = 8M
join_buffer_size = 8M
  
query_cache_limit = 2M
 
ft_min_word_len = 4
 
log_bin = /data/bin-logs/mysql-bin
binlog_format = ROW
expire_logs_days = 30
 
log_error = /data/logs/mysql-error.log
slow_query_log = 1
long_query_time = 1
slow_query_log_file = /data/logs/mysql-slow.log
general_log = 1
log_output = FILE
general_log_file =  /data/logs/general.log
 
performance_schema = 0
 
#lower_case_table_names = 1
 
skip-external-locking
 
default_storage_engine=innodb
#default-storage-engine = MyISAM
innodb_open_files = 500
innodb_write_io_threads = 4

 
#####################################################################33

skip_external_locking
lower_case_table_names=1
event_scheduler=0
back_log=512
default-time-zone='+8:00'
max_connect_errors=99999
max_length_for_sort_data = 16k
wait_timeout=172800
interactive_timeout=172800
net_buffer_length = 8K
table_open_cache_instances = 2
table_definition_cache = 4096
thread_cache_size = 512
explicit_defaults_for_timestamp=ON

#******************************* MyISAM Specific options ****************************
key_buffer_size = 256M
bulk_insert_buffer_size = 8M
myisam_sort_buffer_size = 64M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
myisam_recover_options=force

# ***************************** INNODB Specific options ****************************
innodb_file_per_table = 1
innodb_strict_mode = 1
innodb_flush_method = O_DIRECT
innodb_checksum_algorithm=crc32
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
#### Buffer Pool options
innodb_buffer_pool_size = 4G
innodb_buffer_pool_instances = 2
innodb_max_dirty_pages_pct = 90
innodb_adaptive_flushing = ON
innodb_flush_neighbors = 0
innodb_lru_scan_depth = 4096
#innodb_change_buffering = inserts
innodb_old_blocks_time = 1000

#### galera
wsrep_on=1
wsrep_provider="/usr/lib64/galera/libgalera_smm.so"
wsrep_cluster_name=eric_cluster
wsrep_provider_options="pc.ignore_sb=true;pc.ignore_quorum=true"
wsrep_cluster_address="gcomm://192.168.12.2,192.168.12.3,192.168.12.4"
wsrep_slave_threads=16
wsrep_node_name='manager-node'
wsrep_node_address='192.168.12.2'
wsrep_certify_nonPK=1
wsrep_max_ws_rows=131072
wsrep_max_ws_size=1073741824
wsrep_debug=0
wsrep_convert_LOCK_to_trx=0
wsrep_retry_autocommit=1
wsrep_auto_increment_control=1
wsrep_drupal_282555_workaround=0
wsrep_causal_reads=0
#wsrep_notify_cmd=/usr/local/bin/wsrep-notify.sh
wsrep_sst_method=mariabackup
wsrep_sst_auth="root:123456"

#### audit
#server_audit_file_path = /data/logs/server_audit.log



[mysqldump]
quick
max_allowed_packet = 2G
default-character-set = utf8mb4
 
[myisamchk]
key_buffer = 512M
sort_buffer_size = 512M
read_buffer = 8M
write_buffer = 8M

[mysqlhotcopy]
interactive-timeout

[mysqld_safe]
open-files-limit = 65535

[mysql]
no-auto-rehash
show-warnings
prompt="\\u@\\h : \\d \\r:\\m:\\s> "
default-character-set = utf8mb4
```

### MariaDB [(none)]> show ENGINES;


|Engine|Support|Transactions|XA|Savepoints|
|:---|:---|:---|:---|:---|
| MRG_MyISAM         | YES     | NO | NO | NO |
| MyISAM             | YES     | NO | NO | NO |
| BLACKHOLE          | YES     | NO | NO | NO |
| MEMORY             | YES     | NO | NO | NO |
| Aria               | YES     | NO | NO | NO |
| ARCHIVE            | YES     | NO | NO | NO |
| CSV                | YES     | NO | NO | NO |
| PERFORMANCE_SCHEMA | YES     | NO | NO | NO |
| SEQUENCE           | YES     | YES| NO | YES|
| InnoDB             | DEFAULT | YES| YES| YES|
| FEDERATED          | YES     | YES| NO | YES|
| SPHINX             | YES     | NO | NO | NO |




**附上一个脚本，用来配置my.cnf中的wsrep_notify_cmd=/data/etc/wsrep-notify.sh,用来创建wsrep概要，生成'membeship'和'status'两张表，记录所有的成员和节点状态变化**

```
#!/bin/sh -eu

USER=root
PSWD=123456
HOST=192.168.12.2
PORT=3306

SCHEMA="wsrep"
MEMB_TABLE="$SCHEMA.membership"
STATUS_TABLE="$SCHEMA.status"

BEGIN="
   SET wsrep_on=0;
   DROP SCHEMA IF EXISTS $SCHEMA; CREATE SCHEMA $SCHEMA;
   CREATE TABLE $MEMB_TABLE (
      idx  INT UNIQUE PRIMARY KEY,
      uuid CHAR(40) UNIQUE, /* node UUID */
      name VARCHAR(32),     /* node name */
      addr VARCHAR(256)     /* node address */
   ) ENGINE=MEMORY;
   CREATE TABLE $STATUS_TABLE (
      size   INT,      /* component size   */
      idx    INT,      /* this node index  */
      status CHAR(16), /* this node status */
      uuid   CHAR(40), /* cluster UUID */
      prim   BOOLEAN   /* if component is primary */
   ) ENGINE=MEMORY;
   BEGIN;
   DELETE FROM $MEMB_TABLE;
   DELETE FROM $STATUS_TABLE;
"
END="COMMIT;"

configuration_change()
{
   echo "$BEGIN;"

   local idx=0

   for NODE in $(echo $MEMBERS | sed s/,/\ /g)
   do
      echo "INSERT INTO $MEMB_TABLE VALUES ( $idx, "
      # Don't forget to properly quote string values
      echo "'$NODE'" | sed  s/\\//\',\'/g
      echo ");"
      idx=$(( $idx + 1 ))
   done

   echo "
      INSERT INTO $STATUS_TABLE
      VALUES($idx, $INDEX,'$STATUS', '$CLUSTER_UUID', $PRIMARY);
   "

   echo "$END"
}

status_update()
{
   echo "
      SET wsrep_on=0;
      BEGIN;
      UPDATE $STATUS_TABLE SET status='$STATUS';
      COMMIT;
   "
}

COM=status_update # not a configuration change by default

while [ $# -gt 0 ]
do
   case $1 in
      --status)
         STATUS=$2
         shift
         ;;
      --uuid)
         CLUSTER_UUID=$2
         shift
         ;;
      --primary)
         [ "$2" = "yes" ] && PRIMARY="1" || PRIMARY="0"
         COM=configuration_change
         shift
         ;;
      --index)
         INDEX=$2
         shift
         ;;
      --members)
         MEMBERS=$2
         shift
         ;;
         esac
         shift
   done

# Undefined means node is shutting down
if [ "$STATUS" != "Undefined" ]
then
   $COM | mysql -B -u$USER -p$PSWD -h$HOST -P$PORT
fi

exit 0
```