FROM centos:latest
MAINTAINER Eric Wang <wdc-zhy@163.com>

ARG PATH=/bin:$PATH
 
ENV DATA_DIR=/data/database/ LOGS_DIR=/data/logs/ ETC_DIR=/data/etc/ MARIADB_VERSION=10.3.9

ADD Dockerfile /root/
ADD my.cnf $ETC_DIR


COPY docker-entrypoint.sh /usr/local/bin/ 
COPY wsrep-notify.sh /usr/local/bin/ 

ENV CONFIG "\
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DENABLED_LOCAL_INFILE=ON \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
    -DWITH_XTRADB_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STPRAGE_ENGINE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DWITH_FEDERATEDX_STORAGE_ENGINE=1\
    -DWITH_ARCHIVE_STORAGE_ENGINE=1\
    -DCOMPILATION_COMMENT='王殿臣的数据库' \
    -DWITH_READLINE=ON \
    -DEXTRA_CHARSETS=all \
    -DWITH_SSL=system  \
    -DWITH_ZLIB=system \
    -DWITH_LIBEDIT=0 \
    -DWITH_LIBWRAP=1 \
    -DWITH_WSREP=ON  \
    -DWITH_INNODB_DISALLOW_WRITES=ON \
    -DSYSCONFDIR=/data/etc/ \
    -DMYSQL_DATADIR=/data/database/ \
    -DMYSQL_UNIX_ADDR=/data/database/mysql.sock \
    -DWITH_EMBEDDED_SERVER=OFF \
    -DFEATURE_SET=community \
    -DENABLE_DTRACE=OFF \
    -DMYSQL_SERVER_SUFFIX='【EricWang】-' \
    -DWITH_UNIT_TESTS=0 \
    -DWITHOUT_TOKUDB=ON \
    -DWITHOUT_ROCKSDB=ON \
    -DWITH_PAM=ON \
    -DWITH_INNODB_MEMCACHED=ON \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=/usr/ \
    -DWITH_SCALABILITY_METRICS=ON \
"

RUN groupadd mysql && useradd -r -g mysql -s /bin/false mysql \
    && mkdir -p $DATA_DIR $LOGS_DIR  ${ETC_DIR} && yum install -y \
        cmake gcc g++ make bison kernel-devel openssl-devel openssl libxml2-devel gcc-c++  boost-program-options ncurses-devel --skip-broken \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone \
    && rpm -ivh http://mirrors.ustc.edu.cn/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm && yum update -y \
    && curl "https://mirrors.shu.edu.cn/mariadb//mariadb-$MARIADB_VERSION/source/mariadb-$MARIADB_VERSION.tar.gz" -o /root/mariadb-$MARIADB_VERSION.tar.gz \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f /root/mariadb-$MARIADB_VERSION.tar.gz && rm -rf /root/mariadb-$MARIADB_VERSION.tar.gz \
    && cd /usr/src/mariadb-$MARIADB_VERSION/ \
    && curl "http://yum.mariadb.org/10.3.9/centos/7.4/x86_64/rpms/galera-25.3.23-1.rhel7.el7.centos.x86_64.rpm" -o ./galera-25.3.23-1.rhel7.el7.centos.x86_64.rpm \
    && sed -i "s|Welcome to the MariaDB monitor|欢迎进入MariaDB|" client/mysql.cc    \ 
    && sed -i "s|Oracle, MariaDB Corporation Ab and others|Oracle, MariaDB版权信息声明|" include/welcome_copyright_notice.h    \ 
    && cmake . $CONFIG && make && make install && rpm -ivh galera-25.3.23-1.rhel7.el7.centos.x86_64.rpm && cd / && rm -rf /usr/local/mysql/mysql-test \
    && rm -rf /usr/src/ && rm -rf /usr/local/mysql/COPYING* /usr/local/mysql/README* \
    /usr/local/mysql/CREDITS /usr/local/mysql/EXCEPTIONS-CLIENT /usr/local/mysql/INSTALL-BINARY \
    && rm -rf \ 
    /usr/local/mysql/bin/myisam_ftdump \ 
    /usr/local/mysql/bin/mysql_find_rows \
    /usr/local/mysql/bin/mysql_fix_extensions \
    /usr/local/mysql/bin/mysql_waitpid \
    /usr/local/mysql/bin/mysqlaccess \
    /usr/local/mysql/bin/mysqlcheck \
    /usr/local/mysql/bin/mysqldump \
    /usr/local/mysql/bin/mysqldumpslow \
    /usr/local/mysql/bin/mysqlimport \
    /usr/local/mysql/bin/mariabackup \
    /usr/local/mysql/bin/mysqltest \
    /usr/local/mysql/bin/myisamchk \
    /usr/local/mysql/bin/mysql_client_test \
    /usr/local/mysql/bin/aria_dump_log \
    /usr/local/mysql/bin/aria_ftdump \
    /usr/local/mysql/bin/aria_pack \
    /usr/local/mysql/bin/aria_read_log \
    /usr/local/mysql/bin/aria_chk \
    /usr/local/mysql/bin/mysqlbinlog \
    /usr/local/mysql/bin/mysqlshow \
    /usr/local/mysql/bin/mysqlslap \
    /usr/local/mysql/bin/mysqldump \
    /usr/local/mysql/bin/myisamlog \
    /usr/local/mysql/bin/myisam_ftdump \
    /usr/local/mysql/bin/myisampack \
    /usr/local/mysql/bin/mysql_plugin \
    /usr/local/mysql/bin/mysql_upgrade \
    /usr/local/mysql/bin/perror \
    /usr/local/mysql/bin/mbstream \
    /usr/local/mysql/bin/innochecksum \
    && chmod +x /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/wsrep-notify.sh && chown mysql:mysql /usr/local/bin/wsrep-notify.sh \
    && chmod 700 /usr/local/bin/wsrep-notify.sh


EXPOSE 3306

ENTRYPOINT ["docker-entrypoint.sh"]





