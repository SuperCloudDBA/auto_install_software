#!/bin/bash

install_epel(){
	cd /alidata/install
	rpm -ivh epel-release-latest-7.noarch.rpm
	yum clean all
	yum make cache
}

python_reqiure(){
	yum install -y python-pip  python-devel
	pip install --upgrade pip
	pip install pymysql
	pip install filelock
}

install_epel
python_reqiure