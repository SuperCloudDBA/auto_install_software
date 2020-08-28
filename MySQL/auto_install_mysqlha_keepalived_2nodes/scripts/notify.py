#!/usr/bin/python
# coding: utf-8

import time
import sys
import os
import logging
import json

# Third-part
import mysql_helper
import filelock
import config

preSlaveSQL = "set global read_only=1;"
preMasterSQL = "set global read_only=0;"
log_dir = config.log_dir

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                    datefmt='%a, %d %b %Y %H:%M:%S',
                    filename='{0}/notify.log'.format(log_dir),
                    filemode='a',
                    maxBytes=10485760,  # 10MB 设置日志文件的大小
                    backupCount=20,  # 文件最大的个数
                    encoding='utf8')


class DBase:
    def __init__(self, **kwargs):
        self.params = kwargs["mysql"]
        self.keepalived = kwargs["keepalived"]
        self.other_node = kwargs["other_node"]
        try:
            self.conn = mysql_helper.MysqlHelper(**self.params)
        except Exception as e:
            logging.info("数据库连接异常 " + str(e))
            exit(1)

    def alert(self):
        print("{}".format(self.keepalived))

    def make_master(self):
        """
        将从库切换为主库
        1. 获取从库slave状态
        2. 判断主从是否存在延迟
        3. 如存在延迟等待1分钟
        4. 停止slave
        :return:
        """
        slave_status = self.conn.col_query("show slave status")[0]
        logging.info(json.dumps(slave_status, indent=2))
        Master_Host = slave_status["Master_Host"]
        Master_Log_File = slave_status["Master_Log_File"]
        Read_Master_Log_Pos = slave_status["Read_Master_Log_Pos"]
        Relay_Master_Log_File = slave_status["Relay_Master_Log_File"]
        Exec_Master_Log_Pos = slave_status["Exec_Master_Log_Pos"]

        if Master_Log_File == Relay_Master_Log_File and Read_Master_Log_Pos == Exec_Master_Log_Pos:
            self.conn.col_query("stop slave;")
            self.conn.col_query("set global sync_binlog=1;")
            self.conn.col_query("set global innodb_flush_log_at_trx_commit=1;")
            self.conn.col_query("set global read_only=0;")
            master_status = self.conn.col_query("show master status;")[0]
            logging.info("stop slave;show master status;")
            logging.info("记录新主库的binlog位置：")
            logging.info(json.dumps(master_status, indent=2))
            with open("/alidata/keepalived-2.0.18/logs/master_info", 'w') as f:
                f.write(json.dumps(master_status, indent=1))

        else:
            time.sleep(60)
            slave_status = self.conn.col_query("show slave status")[0]
            logging.info(json.dumps(slave_status, indent=2))
            self.conn.col_query("stop slave;")
            self.conn.col_query("set global sync_binlog=1;")
            self.conn.col_query("set global innodb_flush_log_at_trx_commit=1;")
            self.conn.col_query("set global read_only=0;")
            master_status = self.conn.col_query("show master status;")[0]
            logging.info(json.dumps(master_status, indent=2))
            with open("/alidata/keepalived-2.0.18/logs/master_info", 'w') as f:
                f.write(json.dumps(master_status, indent=1))

        # 记录主库真实的binlog文件和position编号
        try:
            os.popen(
                "scp root@{0}:/alidata/mysql/log/mysql-bin.index /alidata/keepalived-2.0.18/logs/{0}-mysql-bin.index".format(
                    Master_Host))
            master_binlog_file_real = \
                open("/alidata/keepalived-2.0.18/logs/{0}-mysql-bin.index".format(Master_Host)).readlines()[-1].strip()
            os.popen(
                "scp root@{0}:{1}  /alidata/keepalived-2.0.18/logs/{0}-{2}".format(Master_Host, master_binlog_file_real,
                                                                                   master_binlog_file_real.split('/')[
                                                                                       -1]))
            master_binlog_file_slave = "/alidata/keepalived-2.0.18/logs/{0}-{1}".format(Master_Host,
                                                                                        master_binlog_file_real.split(
                                                                                            '/')[-1])
            cmd = "/alidata/mysql/bin/mysqlbinlog -vv " + master_binlog_file_slave + " | tail -n 100|grep end_log_pos|tail -n 2|head -n 1|awk '{print $7}'"
            master_binlog_pos_real = os.popen(cmd).read()
        except Exception as e:
            logging.error(str(e))

        else:
            logging.info("主库 {0} 最后一个binlog日志文件 {1}  位置编号为 {2}".format(Master_Host, master_binlog_file_real,
                                                                       master_binlog_pos_real))
            logging.info("从库 {0} 重演主库binlog日志文件 {1}  位置编号为 {2}".format(
                self.params["url"],
                slave_status["Relay_Master_Log_File"],
                slave_status["Exec_Master_Log_Pos"]))

    def make_slave(self):
        """
        清空slave配置，重新获取远程日志文件及位置编号，并开启半同步复制；
        :return:
        """
        try:
            os.popen(
                "scp root@{0}:/alidata/keepalived-2.0.18/logs/master_info /alidata/keepalived-2.0.18/logs/{0}-master_info".format(
                    self.other_node))
            master_info = json.loads(
                open("/alidata/keepalived-2.0.18/logs/{0}-master_info".format(self.other_node)).read())
        except Exception as e:
            logging.error("无法获取远程日志文件及位置编号")
            logging.error(str(e))
        else:
            self.conn.col_query("stop slave;")
            logging.info("stop slave;")
            sql = "change master to master_user='slave',master_password='Slave@replication',master_host='{0}',master_auto_position=0;"
            self.conn.col_query(sql)
            logging.info(sql)
            sql = "change master to master_user='slave',master_password='Slave@replication',master_host='{0}',master_log_file='{1}',master_log_pos={2};".format(
                self.other_node, master_info["File"], master_info["Position"])
            self.conn.col_query(sql)
            self.conn.col_query("start slave;")
            self.conn.col_query("set global read_only=1;")
            logging.info("start slave;")
            logging.info("set global read_only=1;")
            logging.info(sql)
            slave_status = self.conn.col_query("show slave status;")[0]
            logging.info(json.dumps(slave_status, indent=2))

    def stop_mysql(self):
        try:
            master_status = self.conn.col_query("show master status;")[0]
        except:
            logging.error("数据库服务异常")
        else:
            logging.info("数据库正常")
            logging.info(json.dumps(master_status, indent=2))
            logging.info("主库 {0} 最后一个binlog日志文件 {1}  位置编号为 {2}".format(
                self.params["url"], master_status["File"], master_status["Position"]))


        try:
            slave_status = self.conn.col_query("show slave status;")[0]
        except:
            logging.error("数据库服务异常")
        else:
            logging.info("数据库正常")
            logging.info(json.dumps(slave_status, indent=2))
            logging.info("从库 {0} 重演主库binlog日志文件 {1}  位置编号为 {2}".format(
                self.params["url"],
                slave_status["Relay_Master_Log_File"],
                slave_status["Exec_Master_Log_Pos"]))

    def start(self):
        if self.keepalived == "MASTER":
            self.make_master()
            logging.info("切换状态为MASTER")
        elif self.keepalived == "BACKUP":
            self.make_slave()
            logging.info("切换状态为BACKUP")
        elif self.keepalived == "STOP":
            self.stop_mysql()
            logging.info("切换状态为STOP")
        else:
            logging.error("keepalived配置有误或脚本执行异常")

        self.conn.close()


if __name__ == "__main__":
    lock = filelock.FileLock("/tmp/kps.txt")
    if lock:
        logging.info("ZST Get Lock.start!!!")
    try:
        with lock.acquire(timeout=5):
            pass
    except filelock.timeout:
        print "timeout"
        logging.warning("get file lock timeout")

    mysql = {
        "url": config.dbhost,
        "port": config.dbport,
        "username": config.dbuser,
        "password": config.dbpassword,
        "dbname": "mysql",
    }

    params = {
        "mysql": mysql,
        "keepalived": sys.argv[3].upper(),
        "other_node": config.other_node,
    }

    db = DBase(**params)
    db.start()
