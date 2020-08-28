#!/usr/bin/python
# coding: utf-8

import sys
import logging
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
    logging.info("Keepalived传递的参数为：")
    logging.info(sys.argv)

