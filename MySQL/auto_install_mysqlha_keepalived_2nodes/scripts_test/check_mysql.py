#!/usr/bin/python
# coding: utf-8

import time
import sys
import os
import getopt
import logging

# Third-part
import MySQLdb
import filelock
import config

dbhost = config.dbhost
dbport = config.dbport
dbuser = config.dbuser
dbpassword = config.dbpassword
log_dir = config.log_dir

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                    datefmt='%a, %d %b %Y %H:%M:%S',
                    filename='{0}/check_mysql.log'.format(log_dir),
                    filemode='a',
                    maxBytes=10485760,  # 10MB 设置日志文件的大小
                    backupCount=20,  # 文件最大的个数
                    encoding='utf8')


def checkMySQL():
    """
    test 数据库正常
    :return:
    """
    st = 0
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

    st = checkMySQL()
    if st == 1:
        os.popen("systemctl stop keepalived")
        logging.info("数据库服务异常，已将keepalived进程kill")
    sys.exit(st)
