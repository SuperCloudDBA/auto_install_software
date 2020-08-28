#!/usr/bin/python
# coding: utf-8

import time
import sys
import os
import logging

# Third-part
import mysql_helper
import filelock
import config

log_dir = config.log_dir

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                    datefmt='%a, %d %b %Y %H:%M:%S',
                    filename='{0}/check_mysql.log'.format(log_dir),
                    filemode='a',
                    maxBytes=10485760,  # 10MB 设置日志文件的大小
                    backupCount=20,  # 文件最大的个数
                    encoding='utf8')


class instanceMySQL:
    def __init__(self, **kwargs):
        self.params = kwargs

    def check_connect(self):
        """
        检查是否能够正常连接数据库
        check_result = 0 连接失败
        chekc_result = 1 连接成功
        """
        check_result = 0
        try:
            self.conn = mysql_helper.MysqlHelper(**self.params)
        except Exception, e:
            logging.info("数据库连接异常 " + str(e))
        else:
            check_result = 1
            logging.info("数据库连接正常")
            self.conn.close()
        return check_result

    def check_mysqld(self):
        """
        检查mysqld_safe进程是否存在
        check_result = 0 不存在
        check_result = 1 存在
        """
        check_result = 0
        cmd = "ps -ef | egrep -i \"mysqld\" | grep %s | egrep -iv \"mysqld_safe\" | grep -v grep | wc -l" % self.params["port"]
        mysqldNum = os.popen(cmd).read()
        if (int(mysqldNum) <= 0):
            logging.error("数据库mysqld_safe进程不存在")
        else:
            check_result = 1
            logging.info("数据库mysqld_safe进程正常")
        return check_result

    def check_port(self):
        """
        检查监听端口是否存在
        check_result = 0 不存在
        check_result = 1 存在
        """
        check_result = 0
        cmd = "netstat -tunlp | grep \":%s\" | wc -l" % self.params["port"]
        mysqlPortNum = os.popen(cmd).read()
        if (int(mysqlPortNum) <= 0):
            logging.error("数据库监听端口不存在")
        else:
            check_result = 1
            logging.info("数据库监听端口正常")
        return check_result


def checkMySQL(**kwargs):
    """
    检测算法

    1. 判断数据库是否能够正常连接
    2. 判断监听端口为3306的mysqld_safe进程是否存在
    3. 判断监听端口是否存在

    若 数据库能够正常连接 ；则 返回数据正常;

    否则 判断进程和端口是否存在：

    - 若此时进程和端口均存在，则连续check 5次 数据库连接情况是否正常，每次check后等待1秒；若5次check后都无法正常连接数据库，则返回数据库异常；若在完成5次check前恢复数据库连接，则返回数据库正常。
    - 若此时进程不存在  or 监听端口 不存在 ；则直接返回数据库异常；

    st = 0  数据库退出值为0 代表正常
    st = 1  数据库退出值为1 代表异常
    :return:
    """
    params = {
        "url": kwargs["dbhost"],
        "port": kwargs["dbport"],
        "username": kwargs["dbuser"],
        "password": kwargs["dbpassword"],
        "dbname": "mysql",
    }

    db = instanceMySQL(**params)
    checkout_mysqld = db.check_mysqld()
    checkout_port = db.check_port()
    checkout_connect = db.check_connect()
    if checkout_connect == 1:
        logging.info("数据库正常")
        st = 0
    else:
        if checkout_mysqld == 1 and checkout_port == 1:
            for i in range(5):
                checkout_connect = db.check_connect()
                if checkout_connect == 1:
                    logging.info("已持续 {} 秒 无法连接数据库,目前已成功连接数据库".format(i))
                    st = 0
                    break
                else:
                    logging.info("已持续 {} 秒 无法连接数据库".format(i))
                time.sleep(1)
            else:
                st = 1
                logging.info("数据库异常，已超过 {} 秒 无法连接数据库".format(str(i + 1)))
        elif checkout_mysqld == 0 or checkout_port == 0:
            logging.info("数据库异常")
            st = 1

    return st


if __name__ == "__main__":
    lock = filelock.FileLock("/tmp/kpc.txt")
    if lock:
        logging.info("ZST Get Lock.start!!!")
    try:
        with lock.acquire(timeout=5):
            pass
    except filelock.timeout:
        print "timeout"
        logging.warning("get file lock timeout")

    params = {
        "dbhost": config.dbhost,
        "dbport": config.dbport,
        "dbuser": config.dbuser,
        "dbpassword": config.dbpassword,
    }

    st = checkMySQL(**params)
    if st == 1:
        os.popen("systemctl stop keepalived")
        logging.info("数据库服务异常，已将keepalived进程kill")
    sys.exit(st)
