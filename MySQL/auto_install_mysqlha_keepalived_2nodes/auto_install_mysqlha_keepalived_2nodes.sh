#!/bin/bash
node1=192.168.14.128
node2=192.168.14.129
mysql_bin=/alidata/mysql/bin/
root_pwd=Zyadmin123
slave_user=slave
slave_pwd=Slave@replication
keepalived_user=keepalived
keepalived_pwd=Keepalived@123
keepalived_dir=/alidata/keepalived-2.0.18/

auto_visit(){
	yes | ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ''
	ssh-copy-id root@$1
}

config_hosts(){
	cat >> /etc/hosts << ENDF
$node1 node1 
$node2 node2
ENDF
}

install_basic_softwares(){
	yum install -y gcc vim net-tools lrzsz
	systemctl stop firewalld
	setenforce 0	
}

init_user(){
	 ${mysql_bin}/mysqladmin -uroot password $root_pwd
	 ${mysql_bin}/mysql -uroot -p$root_pwd -e "delete from mysql.user where user='' or host='' or password='';"
	 ${mysql_bin}/mysql -uroot -p$root_pwd -e "grant all on *.* to '${keepalived_user}'@'%' identified by '${keepalived_pwd}';"
}

enable_semisync_master(){
	${mysql_bin}/mysql -uroot -p$root_pwd -e "install plugin rpl_semi_sync_master soname 'semisync_master.so';"
	${mysql_bin}/mysql -uroot -p$root_pwd -e "install plugin rpl_semi_sync_slave soname 'semisync_slave.so';"
	${mysql_bin}/mysql -uroot -p$root_pwd -e "set global sync_binlog=1;set global innodb_flush_log_at_trx_commit=1;"
	sed -i "s/^server-id.*$/server_id=1003306/" /etc/my.cnf
	sed -i "s/#rpl_semi_sync_master_enabled=1/rpl_semi_sync_master_enabled=1/" /etc/my.cnf
	sed -i "s/#rpl_semi_sync_master_timeout=1000 # 1 second/rpl_semi_sync_master_timeout=1000 # 1 second/" /etc/my.cnf
	sed -i "s/#rpl_semi_sync_slave_enabled=1/rpl_semi_sync_slave_enabled=1/" /etc/my.cnf
	/etc/init.d/mysqld restart
}

enable_semisync_slave(){
	${mysql_bin}/mysql -uroot -p$root_pwd -e "install plugin rpl_semi_sync_master soname 'semisync_master.so';"
	${mysql_bin}/mysql -uroot -p$root_pwd -e "install plugin rpl_semi_sync_slave soname 'semisync_slave.so';"
	${mysql_bin}/mysql -uroot -p$root_pwd -e "set global sync_binlog=0;set global innodb_flush_log_at_trx_commit=0;"
	sed -i "s/^server-id.*$/server_id=2003306/" /etc/my.cnf
	sed -i "s/#rpl_semi_sync_master_enabled=1/rpl_semi_sync_master_enabled=1/" /etc/my.cnf
	sed -i "s/#rpl_semi_sync_master_timeout=1000 # 1 second/rpl_semi_sync_master_timeout=1000 # 1 second/" /etc/my.cnf
	sed -i "s/#rpl_semi_sync_slave_enabled=1/rpl_semi_sync_slave_enabled=1/" /etc/my.cnf
	/etc/init.d/mysqld restart
}

ab_replication_master(){
	${mysql_bin}/mysql -uroot -p$root_pwd -e "grant replication slave on *.* to slave@'%' identified by 'Slave@replication';flush privileges;"
	${mysql_bin}/mysqldump -uroot -p$root_pwd -A --single-transaction --master-data=2 --set-gtid-purged=OFF > /tmp/mysql.all.sql
	scp /tmp/mysql.all.sql root@${1}:/tmp
}

ab_replication_slave(){
	cat > slave.file << ENDF
mysql_bin=/alidata/mysql/bin/
\${mysql_bin}/mysql -uroot -p$root_pwd < /tmp/mysql.all.sql
\${mysql_bin}/mysql -uroot -p$root_pwd -e "flush privileges;change master to master_user='${slave_user}',master_password='${slave_pwd}',master_host='$node1',master_auto_position=1;start slave;show slave status\G;"
ENDF
	scp slave.file root@node2:~
	ssh root@node2 bash slave.file
}


keepalived_config(){
    cd ${keepalived_dir}/etc/keepalived/
    mv keepalived.conf keepalived.conf.bac
    cp /root/mysql_git/config/keepalived.conf.${1} keepalived.conf
}

keepalived_scripts(){
    cd ${keepalived_dir}/scripts/
    cp  /root/mysql_git/scripts/*.py .
    chmod a+x *.py
    sed -i "s/^dbhost=.*$/dbhost='${1}'/" config.py
    sed -i "s/^other_node=.*$/other_node='${2}'/" config.py
}

mkdir /alidata/install -p
cp ./software/* /alidata/install

# 1. 设置node1和node2免密登陆
case $1 in 
node1)
	auto_visit ${node2};
	config_hosts;;
node2)
	auto_visit ${node1};
	config_hosts;;
*)
	echo "Plase input node1 | node2";;
esac

# 2. 安装必要的软件
install_basic_softwares
# 3. 安装mysql5.6
bash mysql-5.6.46.sh
# 4. 初始化用户和密码
init_user
# 5. 开启主从半同步复制
case $2 in 
master) 
	enable_semisync_master;
	ab_replication_master node2;
	ab_replication_slave;;
slave)	
	enable_semisync_slave;;
*)
    echo "若需要开启，请填写角色 master or slave";;
esac


# 6. 安装python
bash python-2.7.5.sh

# 7. 安装keepalived
bash keepalived-2.0.18.sh

# 8. 准备配置文件和脚本
case $2 in
master)
    keepalived_config master;
    keepalived_scripts $node1 $node2;;
slave)
    keepalived_config slave;
    keepalived_scripts $node2 $node1;;
esac
# 9. 启动keepalived