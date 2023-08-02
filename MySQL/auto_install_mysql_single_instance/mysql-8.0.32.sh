#!/bin/bash
#/server 目录应单独挂接磁盘
yum install libaio


DIR=`pwd`
DATE=`date +%Y%m%d%H%M%S`
server_id=$DATE

\mv /server/mysql /server/mysql.bak.$DATE &> /dev/null
mkdir -p /server/mysql
mkdir -p /server/mysql/data
mkdir -p /server/mysql/log
mkdir -p /server/install
mkdir -p /usr/local/mysql/bin

cd /server/install

if [ ! -f mysql-8.0.32-linux-glibc2.12-x86_64.tar.xz ];then
  wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.32-linux-glibc2.12-x86_64.tar.xz
fi
tar -xf mysql-8.0.32-linux-glibc2.12-x86_64.tar.xz
mv mysql-8.0.32-linux-glibc2.12-x86_64/* /server/mysql

#install mysql
groupadd mysql
useradd -g mysql -s /sbin/nologin mysql


\cp -f /server/mysql/support-files/mysql.server /etc/init.d/mysqld
sed -i 's#^basedir=$#basedir=/server/mysql#' /etc/init.d/mysqld
sed -i 's#^datadir=$#datadir=/server/mysql/data#' /etc/init.d/mysqld
cat > /etc/my.cnf <<END
[client]
port = 3306
socket = /server/mysql/data/mysql.sock

[mysql]
prompt="\u@mysqldb \R:\m:\s [\d]> "
no-auto-rehash

[mysqld]
user = mysql
port = 3306
basedir = /server/mysql
datadir = /server/mysql/data
socket = /server/mysql/data
pid-file = mysqldb.pid
# 字符集
character-set-server = utf8mb4
skip_name_resolve = 1
# 是否区分大小写
# 如果设置为 0，表名将按指定存储，并且比较区分大小写。
# 如果设置为 1，表名将以小写形式存储在磁盘上，并且比较不区分大小写。
# 如果设置为 2，则表名按给定方式存储，但以小写形式进行比较
lower_case_table_names = 1

# 查询熔断时间 单位 毫秒
max_execution_time = 2000
#若你的MySQL数据库主要运行在境外，请务必根据实际情况调整本参数
default_time_zone = "+0:00"

open_files_limit = 65535
back_log = 1024
max_connections = 20
max_connect_errors = 1000000
table_open_cache = 2000
table_definition_cache = 2000
table_open_cache_instances = 64
thread_stack = 512K
external-locking = FALSE
max_allowed_packet = 32M
sort_buffer_size = 4M
join_buffer_size = 4M
thread_cache_size = 768
interactive_timeout = 600
wait_timeout = 1800
tmp_table_size = 32M
max_heap_table_size = 32M
slow_query_log = 1
log_timestamps = SYSTEM
slow_query_log_file = /server/mysql/slow.log
log-error = /server/mysql/error.log
long_query_time = 2
log_queries_not_using_indexes =1
log_throttle_queries_not_using_indexes = 60
min_examined_row_limit = 100
log_slow_admin_statements = 1
log_slow_slave_statements = 1
server-id = $server_id
log-bin = /server/mysql/data/mybinlog
sync_binlog = 1
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G

#注意：MySQL 8.0开始，binlog_expire_logs_seconds选项也存在的话，会忽略expire_logs_days选项
expire_logs_days = 7

master_info_repository = TABLE
relay_log_info_repository = TABLE
gtid_mode = on
enforce_gtid_consistency = 1
log_slave_updates
slave-rows-search-algorithms = 'INDEX_SCAN,HASH_SCAN'
binlog_format = row
binlog_checksum = 1
relay_log_recovery = 1
relay-log-purge = 1
key_buffer_size = 32M
read_buffer_size = 8M
read_rnd_buffer_size = 4M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
lock_wait_timeout = 5
explicit_defaults_for_timestamp = 1
innodb_thread_concurrency = 0
innodb_sync_spin_loops = 100
innodb_spin_wait_delay = 30
# 隔离级别
transaction_isolation = REPEATABLE-READ
#innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size = $(num1=`cat /proc/meminfo | sed -n '1p'|awk '{print $2}'`;awk 'BEGIN{printf "%.0f\n",'$num1'*1024*0.75}')
innodb_buffer_pool_instances = 4
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 32M
innodb_log_file_size = 2G
innodb_log_files_in_group = 2
innodb_max_undo_log_size = 4G
innodb_undo_directory = /server/mysql/data/undolog
innodb_undo_tablespaces = 95

# 根据您的服务器IOPS能力适当调整
# 一般配普通SSD盘的话，可以调整到 10000 - 20000
# 配置高端PCIe SSD卡的话，则可以调整的更高，比如 50000 - 80000
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_sync = 0
innodb_flush_neighbors = 0
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_purge_threads = 4
innodb_page_cleaners = 4
innodb_open_files = 65535
innodb_max_dirty_pages_pct = 50
innodb_flush_method = O_DIRECT
innodb_lru_scan_depth = 4000
innodb_checksum_algorithm = crc32
innodb_lock_wait_timeout = 5
innodb_rollback_on_timeout = 1
innodb_print_all_deadlocks = 1
innodb_file_per_table = 1
innodb_online_alter_log_max_size = 4G
innodb_stats_on_metadata = 0
innodb_undo_log_truncate = 1

# some var for MySQL 5.7
innodb_checksums = 1
#innodb_file_format = Barracuda
#innodb_file_format_max = Barracuda
query_cache_size = 0
query_cache_type = 0
innodb_undo_logs = 128

#注意：MySQL 8.0.32开始删除该选项
internal_tmp_disk_storage_engine = InnoDB

innodb_status_file = 1
#注意: 开启 innodb_status_output & innodb_status_output_locks 后, 可能会导致log-error文件增长较快
innodb_status_output = 0
innodb_status_output_locks = 0

#performance_schema
performance_schema = 1
performance_schema_instrument = '%memory%=on'
performance_schema_instrument = '%lock%=on'

#innodb monitor
innodb_monitor_enable="module_innodb"
innodb_monitor_enable="module_server"
innodb_monitor_enable="module_dml"
innodb_monitor_enable="module_ddl"
innodb_monitor_enable="module_trx"
innodb_monitor_enable="module_os"
innodb_monitor_enable="module_purge"
innodb_monitor_enable="module_log"
innodb_monitor_enable="module_lock"
innodb_monitor_enable="module_buffer"
innodb_monitor_enable="module_index"
innodb_monitor_enable="module_ibuf_system"
innodb_monitor_enable="module_buffer_page"
innodb_monitor_enable="module_adaptive_hash"

[mysqldump]
quick
max_allowed_packet = 32M

END

chown -R mysql:mysql /server/mysql/
chown -R mysql:mysql /server/mysql/data/
chown -R mysql:mysql /server/mysql/log


/server/mysql/bin/mysqld --initialize-insecure --datadir=/server/mysql/data/  --user=mysql
ln -s /server/mysql/bin/mysqld /usr/local/mysql/bin/mysqld
chmod 755 /etc/init.d/mysqld
/server/mysql/bin/mysql_ssl_rsa_setup
/etc/init.d/mysqld start

#add PATH
if ! cat /etc/profile | grep "export PATH=\$PATH:/server/mysql/bin" &> /dev/null;then
	echo "export PATH=\$PATH:/server/mysql/bin" >> /etc/profile
fi
source /etc/profile
cd $DIR
bash
