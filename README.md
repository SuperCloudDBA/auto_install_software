# 数据库自动安装脚本

> 2020.03.18

该仓库用于存放数据库自动安装脚本，持续更新与维护。


---
使用语言：

1. python版本 3.7

2. bash

---


## Python

|文档|说明|
|:--|:--|
|[centos_install_python3.sh](centos_install_python3.sh)|CentOS服务器无法访问公网的情况下快速安装Python3和第三方模块|
|[auto_install_mysqlha_keepalived_2nodes](MySQL/auto_install_mysqlha_keepalived_2nodes)|MySQL5.6双机热备高可用一键部署工具|

## 计划

| 数据库                                          | 单实例安装 | 主从高可用 | 集群 |
| ----------------------------------------------- | ---------- | ---------- | ---- |
| [MySQL](https://dev.mysql.com/downloads/mysql/) |            |            |      |
| 5.6.49                                         |    √       |     √         |      |
| 5.7.31                                          |      √        |           |      |
| 8.0.21                                          |      √        |            |      |
| Oracle                                          |            |            |      |
| 11.2.0.4.0                                      |            |            |      |
| 12.2.0.1.0                                      |            |            |      |
| MongoDB                                         |            |            |      |
| 3.4                                             |            |            |      |
| 4.0                                             |            |            |      |
| 4.2                                             |            |            |      |
| [Redis](https://redis.io/download)              |            |            |      |
| 3.2.11                                           |     √         |            |      |
| 5.0.8                                           |            |            |      |
| 6.0.6                                           |            |            |      |



