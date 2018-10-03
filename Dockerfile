FROM alpine:latest
MAINTAINER Eric Wang <wdc-zhy@163.com>

ARG PATH=/bin:$PATH
 
ENV DATA_DIR=/data/database/ LOGS_DIR=/data/logs/ ETC_DIR=/data/etc/ MARIADB_VERSION=10.3.9

ADD Dockerfile /root/
ADD my.cnf $ETC_DIR


COPY docker-entrypoint.sh /usr/local/bin/ 

ENV CONFIG "\
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DENABLED_LOCAL_INFILE=ON \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
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
    -DWITH_LIBWRAP=0 \
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

RUN addgroup -S mysql && adduser -D -S -h /var/cache/mysql -s /sbin/nologin -G mysql mysql \
    && mkdir -p $DATA_DIR $LOGS_DIR  ${ETC_DIR}apk update && apk add --no-cache --virtual .build-deps \
        cmake gcc g++ make bison openssl-dev libxml2-dev ncurses-dev linux-headers curl tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone \
    && curl "https://mirrors.shu.edu.cn/mariadb//mariadb-$MARIADB_VERSION/source/mariadb-$MARIADB_VERSION.tar.gz" -o /root/mariadb-$MARIADB_VERSION.tar.gz \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f /root/mariadb-$MARIADB_VERSION.tar.gz && rm -rf /root/mariadb-$MARIADB_VERSION.tar.gz \
    && cd /usr/src/mariadb-$MARIADB_VERSION/ \
    && sed -i "s|Welcome to the MariaDB monitor|欢迎进入MariaDB|" client/mysql.cc    \ 
    && sed -i "s|Oracle, MariaDB Corporation Ab and others|Oracle, MariaDB版权信息声明|" include/welcome_copyright_notice.h    \ 
    && cmake . $CONFIG && make && make install && cd / && rm -rf /usr/local/mysql/mysql-test \
    && rm -rf /usr/src/ && rm -rf /usr/local/mysql/COPYING* /usr/local/mysql/README* \
    /usr/local/mysql/CREDITS /usr/local/mysql/EXCEPTIONS-CLIENT /usr/local/mysql/INSTALL-BINARY && apk del .build-deps && rm -rf /var/cache/apk/*  \
    && chmod +x /usr/local/bin/docker-entrypoint.sh 

ADD libcrypto.so.1.0.0 /lib/
ADD libgcc_s.so.1 /usr/lib/
ADD libssl.so.1.0.0 /usr/lib/
ADD libstdc++.so.6 /usr/lib/
ADD libncursesw.so.6.1 /usr/lib/
ADD ld-musl-x86_64.so.1 /lib/
ADD libxml2.so.2.9.8 /usr/lib/

RUN ln -s /usr/lib/libncursesw.so.6.1 /usr/lib/libncursesw.so.6 && ln -s /usr/lib/libxml2.so.2.9.8 /usr/lib/libxml2.so.2
 
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306

CMD ["/usr/local/mysql/bin/mysqld_safe" ,  "--defaults-file=/data/etc/my.cnf" ,  "--basedir=/usr/local/mysql/"]



