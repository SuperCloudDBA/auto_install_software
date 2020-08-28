# MySQL5.6双机热备高可用一键部署工具

本工具提供：

1. MySQL5.6双机热备高可用方案
2. MySQL5.6双机热备高可用自动搭建搭建脚本

## 文档结构

| Name                                                         | 说明                 |
| :----------------------------------------------------------- | -------------------- |
| [config](auto_install_mysqlha_keepalived_2nodes/tree/master/config) | 配置文件             |
| [scripts](auto_install_mysqlha_keepalived_2nodes/tree/master/scripts) | keepalived自定义脚本 |
| [scripts_test](auto_install_mysqlha_keepalived_2nodes/tree/master/scripts_test) | keepalived测试脚本   |
| [software](auto_install_mysqlha_keepalived_2nodes/tree/master/software) | 软件                 |
| [word](auto_install_mysqlha_keepalived_2nodes/tree/master/word) | 文档                 |
| [README.md](auto_install_mysqlha_keepalived_2nodes/blob/master/README.md) |                      |
| [auto_install_mysqlha_keepalived_2nodes.sh](auto_install_mysqlha_keepalived_2nodes/blob/master/auto_install_mysqlha_keepalived_2nodes.sh) | 主程序               |
| [keepalived-2.0.18.sh](auto_install_mysqlha_keepalived_2nodes/blob/master/keepalived-2.0.18.sh) | keepalived安装脚本   |
| [mysql-5.6.46.sh](auto_install_mysqlha_keepalived_2nodes/blob/master/mysql-5.6.46.sh) | mysql安装脚本        |
| [python-2.7.5.sh](auto_install_mysqlha_keepalived_2nodes/blob/master/python-2.7.5.sh) | python安装脚本       |



## 自动搭建MySQLHA+Keepalived

准备工作

```bash
git clone https://github.com/SuperCloudDBA/auto_install_software.git
cd MySQL/software
wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.6.48-linux-glibc2.12-i686.tar.gz
```

## 第一步先安装从库

```bash
bash auto_install_mysqlha_keepalived_2nodes.sh node2 slave
```

## 第二步再安装主库

```bash
bash auto_install_mysqlha_keepalived_2nodes.sh node1 master
```

