#!/bin/bash
# Usage： bash redis-5.0.8.sh
# 安装前需要升级你第一步安装的gcc 至版本9

#yum install centos-release-scl -y
#yum install devtoolset-9-gcc* -y
#scl enable devtoolset-9 bash
source /opt/rh/devtoolset-9/enable


SRC_URI="https://download.redis.io/releases/redis-5.0.8.tar.gz"
PKG_NAME=`basename $SRC_URI`
DIR=`pwd`
DATE=`date +%Y%m%d%H%M%S`
CPU_NUM=$(cat /proc/cpuinfo | grep processor | wc -l)


\mv /alidata/redis /alidata/redis.bak.$DATE

yum install gcc-c++ -y
yum install -y jemalloc*

mkdir -p /alidata/redis
cd /alidata/redis
mkdir conf data log pid

mkdir -p /alidata/install
cd /alidata/install

if [ ! -s $PKG_NAME ]; then
    wget -c $SRC_URI
fi

rm -rf redis-5.0.8
tar xvf $PKG_NAME
cd redis-5.0.8

if [ $CPU_NUM -gt 1 ];then
    make -j$CPU_NUM
else
    make
fi

make install

\cp /alidata/install/redis-5.0.8/* /alidata/redis/ -rp

cd /alidata/redis

i=6379
mkdir data/$i &> /dev/null
grep -v '^#\|^$' redis.conf > /alidata/redis/conf/redis${i}.conf
sed -i 's/daemonize no/daemonize yes/' /alidata/redis/conf/redis${i}.conf
sed -i 's/appendonly no/appendonly yes/' /alidata/redis/conf/redis${i}.conf
sed -i "s/port.*/port $i/" /alidata/redis/conf/redis${i}.conf
sed -i "s@dir.*@dir \/alidata\/redis\/data\/${i}@" /alidata/redis/conf/redis${i}.conf
sed -i "s@pid.*@pidfile \/alidata\/redis\/pid\/redis${i}.pid@" /alidata/redis/conf/redis${i}.conf
sed -i "s@logfile.*@logfile \/alidata\/redis\/log\/redis${i}.log@" /alidata/redis/conf/redis${i}.conf


if ! cat /etc/sysctl.conf | grep "vm.overcommit_memory = 1" &> /dev/null;then
    echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
fi
sysctl -p 2>&1 /dev/null


cat > /etc/init.d/redis << EOT
#!/bin/sh
#Configurations injected by install_server below....

EXEC=`which redis-server`
CLIEXEC=`which redis-cli`
PIDFILE="/alidata/redis/pid/redis6379.pid"
CONF="/alidata/redis/conf/redis6379.conf"
REDISPORT="6379"


case "\$1" in
    start)
        if [ -f \$PIDFILE ]
        then
            echo "\$PIDFILE exists, process is already running or crashed"
        else
            echo "Starting Redis server..."
            \$EXEC \$CONF
        fi
        ;;
    stop)
        if [ ! -f \$PIDFILE ]
        then
            echo "\$PIDFILE does not exist, process is not running"
        else
            PID=\$(cat \$PIDFILE)
            echo "Stopping ..."
            \$CLIEXEC -p \$REDISPORT shutdown
            while [ -x /proc/\${PID} ]
            do
                echo "Waiting for Redis to shutdown ..."
                sleep 1
            done
            echo "Redis stopped"
        fi
        ;;
    status)
        PID=\$(cat \$PIDFILE)
        if [ ! -x /proc/\${PID} ]
        then
            echo 'Redis is not running'
        else
            echo "Redis is running (\$PID)"
        fi
        ;;
    restart)
        \$0 stop
        \$0 start
        ;;
    *)
        echo "Please use start, stop, restart or status as first argument"
        ;;
esac

EOT


chmod a+x /etc/init.d/redis

cd $DIR
