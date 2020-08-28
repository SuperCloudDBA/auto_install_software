systemctl stop keepalived
> /var/log/keepalived.log
> logs/check_mysql.log
> logs/notify.log
/etc/init.d/mysqld stop

mysql -uroot -pZyadmin123 -e "start slave;"

mysql -uroot -pZyadmin123 -e "show slave status\G" |grep "Running\|Error"

cd /alidata/keepalived-2.0.18/scripts
python check_mysql.py ; echo $?;tail ../logs/check_mysql.log

change master to master_user='slave',master_password='Slave@replication',master_host='192.168.14.131',master_auto_position=0;
change master to master_user='slave',master_password='Slave@replication',master_host='192.168.14.131',master_log_file="mysql-bin.000005",master_log_pos=191;
start slave;show slave status\G;


mysql -ukeepalived -pKeepalived@123 -h 10.0.0.88 -e "show databases"