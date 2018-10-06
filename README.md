## 该版本是mariadb源码编译安装组建比较全的一个版本，已经内置了sphinx、MariaDB-Galera和xtrabackup等

```
docker pull w303972870/mariadb-galera
```

|软件|版本|
|:---|:---|
|mariadb|10.3.9|


#### 启动命令示例：为了初始化必须指定一个默认的root密码MYSQL_ROOT_PASSWORD

```
docker run -dit -p 3306:3306 -v /data/mariadb/:/data/ -e MYSQL_ROOT_HOST=192.168.12.% -e MYSQL_ROOT_PASSWORD=123456 -e WSREP_NEW_CLUSTER=yes docker.io/w303972870/mariadb-galera
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
|WSREP_NEW_CLUSTER|集群用参，作为集群时，启动集群第一台时该值传入yes其他的传入no或者不传入即可|

### 启动之后，需要mysql -h 127.0.0.1 -p3306 -u root连接容器mysql后重新配置访问限制，例如：

```
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.12.%' IDENTIFIED BY '123456' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '123456' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.17.0.%' IDENTIFIED BY '123456' WITH GRANT OPTION;
```

### 数据目录：/data/database/
### 日志目录：/data/logs/
### 默认配置文件：/data/etc/my.cnf


### 已开放3306端口

### 我的/data/mariadb/目录结构
```
/data/mariadb/
├── database
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
bind-address = 0.0.0.0
server-id = 1
 
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
 
log_bin = mysql-bin
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
 
default_storage_engine = InnoDB
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
wsrep_provider_options="gcache.size=1G"
wsrep_cluster_address=gcomm://192.168.12.2,192.168.12.3,192.168.12.4
wsrep_node_name = master_node
wsrep_node_address=192.168.12.2
wsrep_slave_threads=16
wsrep_certify_nonPK=1
wsrep_max_ws_rows=131072
wsrep_max_ws_size=1073741824
wsrep_debug=0
wsrep_convert_LOCK_to_trx=0
wsrep_retry_autocommit=1
wsrep_auto_increment_control=1
wsrep_drupal_282555_workaround=0
wsrep_causal_reads=0
wsrep_notify_cmd=/usr/local/bin/wsrep-notify.sh
wsrep_sst_method=xtrabackup-v2
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
|MEMORY             |YES    |NO |NO |NO |
|MRG_MyISAM         |YES    |NO |NO |NO |
|CSV                |YES    |NO |NO |NO |
|BLACKHOLE          |YES    |NO |NO |NO |
|MyISAM             |YES    |NO |NO |NO |
|ARCHIVE            |YES    |NO |NO |NO |
|FEDERATED          |YES    |YES|NO |YES|
|PERFORMANCE_SCHEMA |YES    |NO |NO |NO |
|SEQUENCE           |YES    |YES|NO |YES|
|InnoDB             |DEFAULT|YES|YES|YES|
|Aria               |YES    |NO |NO |NO |
|SPHINX             |YES    |NO |NO |NO |

