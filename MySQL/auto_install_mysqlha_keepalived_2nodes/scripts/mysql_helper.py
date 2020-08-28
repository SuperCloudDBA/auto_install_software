# -*- coding:utf8 -*-

import sys
import pymysql
import json


class MysqlHelper:
    def __init__(self, **kwargs):
        self.url = kwargs['url']
        self.port = kwargs['port']
        self.username = kwargs['username']
        self.password = kwargs['password']
        self.dbname = kwargs['dbname']
        self.charset = "utf8"
        self.conn = pymysql.connect(host=self.url, user=self.username, passwd=self.password, port=self.port,
                                    charset=self.charset, db=self.dbname)
        self.cur = self.conn.cursor(cursor=pymysql.cursors.DictCursor)

    def col_query(self, sql):
        """
        打印表的列名
        :return list
        """
        self.cur.execute(sql)
        return self.cur.fetchall()

    def commit(self):
        self.conn.commit()

    def close(self):
        self.cur.close()
        self.conn.close()

if __name__ == "__main__":
    print("This is mysql api.")