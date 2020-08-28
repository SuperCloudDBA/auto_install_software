#!/bin/bash
DIR=`pwd`
DATE=`date +%Y%m%d%H%M%S`

mv /alidata/mysql /alidata/mysql.bak.$DATE &> /dev/null
mkdir -p /alidata/mysql
mkdir -p /alidata/mysql/log
mkdir -p /alidata/mysql/data
mkdir -p /alidata/mysql/tmp

cd /alidata/install
tar -xzvf mysql-5.6.45-linux-glibc2.12-x86_64.tar.gz
mv mysql-5.6.45-linux-glibc2.12-x86_64/* /alidata/mysql


#install mysql
yum install libaio autoconf -y
groupadd mysql
useradd -g mysql -s /sbin/nologin mysql
cp -f /alidata/mysql/support-files/mysql.server /etc/init.d/mysqld
sed -i 's#^basedir=$#basedir=/alidata/mysql#' /etc/init.d/mysqld
sed -i 's#^datadir=$#datadir=/alidata/mysql/data#' /etc/init.d/mysqld
cat > /etc/my.cnf <<END
#my.cnf
[client]
port            = 3306
socket          = /tmp/mysql3306.sock

[mysql]
prompt="\\u@\\h [\\d]>" 
no-auto-rehash

[mysqld]

user = mysql
basedir = /alidata/mysql
datadir = /alidata/mysql/data
port = 3306
socket = /tmp/mysql3306.sock
event_scheduler = 0

tmpdir = /alidata/mysql/tmp
#timeout
interactive_timeout = 28800
wait_timeout = 28800

#character set
character-set-server = utf8mb4

open_files_limit = 65535
max_connections = 1000
max_connect_errors = 100000
lower_case_table_names =1

#symi replication

#rpl_semi_sync_master_enabled=1
#rpl_semi_sync_master_timeout=1000 # 1 second
#rpl_semi_sync_slave_enabled=1

#logs
log-output=file
slow_query_log = 1
slow_query_log_file = /alidata/mysql/data/slow.log
log-error = /alidata/mysql/data/error.log
log_warnings = 2
pid-file = mysql.pid
long_query_time = 1
#log-slow-admin-statements = 1
#log-queries-not-using-indexes = 1
log-slow-slave-statements = 1

#binlog
binlog_format = row
server-id = 2003306
log-bin = /alidata/mysql/log/mysql-bin
binlog_cache_size = 4M
sync_binlog = 1
expire_logs_days = 10
#procedure 
log_bin_trust_function_creators=1

# gtid
gtid-mode = on
enforce-gtid-consistency=1


#relay log
skip_slave_start = 1
max_relay_log_size = 128M
relay_log_purge = 1
relay_log_recovery = 1
relay-log=relay-bin
relay-log-index=relay-bin.index
log_slave_updates
#slave-skip-errors=1032,1053,1062
#skip-grant-tables


#buffers & cache
table_open_cache = 2048
table_definition_cache = 2048
max_heap_table_size = 96M
sort_buffer_size = 128K
join_buffer_size = 128K
thread_cache_size = 200
query_cache_size = 0
query_cache_type = 0
query_cache_limit = 256K
query_cache_min_res_unit = 512
thread_stack = 192K
tmp_table_size = 96M
key_buffer_size = 8M
read_buffer_size = 2M
read_rnd_buffer_size = 16M
bulk_insert_buffer_size = 32M

#myisam
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1

#innodb
innodb_buffer_pool_size = $(num1=`cat /proc/meminfo | sed -n '1p'|awk '{print $2}'`;awk 'BEGIN{printf "%.0f\n",'$num1'*1024*0.75}')
innodb_buffer_pool_instances = 8
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 32M
innodb_log_file_size = 2G
innodb_log_files_in_group = 2

# mem bug
performance_schema_max_table_instances=600

[mysqldump]
quick
max_allowed_packet = 32M

END


chown -R mysql:mysql /alidata/mysql/
chown -R mysql:mysql /alidata/mysql/data/
chown -R mysql:mysql /alidata/mysql/log/
chown -R mysql:mysql /alidata/mysql/tmp/
chmod 755 /etc/init.d/mysqld
/alidata/mysql/scripts/mysql_install_db --datadir=/alidata/mysql/data --basedir=/alidata/mysql
mkdir -p /usr/local/mysql/bin
ln -s /alidata/mysql/bin/mysqld /usr/local/mysql/bin/mysqld
/etc/init.d/mysqld start

#add PATH
if ! cat /etc/profile | grep "export PATH=\$PATH:/alidata/mysql/bin" &> /dev/null;then
	echo "export PATH=\$PATH:/alidata/mysql/bin" >> /etc/profile
fi
source /etc/profile
cd $DIR