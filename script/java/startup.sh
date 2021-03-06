#!/bin/sh
# Linux下启动java server
# 适用于spring-boot项目
# require jre/jdk 1.8+
# copy from by wukm <wukunmeng@gmail.com>
# modify by wukunmeng
set -e
app_dir=$(cd $(dirname $0); pwd)
echo "application home: $app_dir"
cd $app_dir
[ -d "log" ] || mkdir log
debug="$2"
pidfile=$app_dir/.pid
BOOT_NAME="com.xpc.pay.boot.ApplicationContext"
classpath=$app_dir/classes
#appjar=user-center-1.0-SNAPSHOT.jar
JAVA_OPTS="-server -Xms256M -Xmx256M -Xss256k
          -XX:+HeapDumpOnOutOfMemoryError
          -XX:+PrintGCApplicationStoppedTime -Xloggc:log/gc.log
          -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=1024k
          -Duser.timezone=Asia/Shanghai -Dfile.encoding=UTF-8 -Dapp=$main"
pid=-1
start() {
    pid=`ps -ef | grep java | grep $classpath | grep -v grep | awk '{print $2}'`
    if [ -z "$pid" ]; then
        output="/dev/null"
        if [[ "$debug" = "debug" ]]; then
            output="console.log"
        fi
        java -cp $classpath $JAVA_OPTS -Dproduct=true -Djava.ext.dirs=$app_dir/lib $BOOT_NAME > $output 2>&1 &
        echo $!>$pidfile
        echo "running pid: $!"
    else
        echo "server is runing pid:$pid"
    fi
}
shutdown() {
    echo "un-support"
}
stop() {
    pid=`ps -ef | grep java | grep $classpath | grep -v grep | awk '{print $2}'`
        if [ ! -z "$pid" ]; then
            kill $pid
            sleep 2s
            pid=`ps -ef | grep java | grep $classpath | grep -v grep | awk '{print $2}'`
            if [ ! -z "$pid" ]; then
                echo "force kill $pid"
                kill -9 $pid
            fi
        fi
        echo "server stoped!"
        rm -f $pidfile
}
net() {
    netstat -anp | grep `cat $pidfile`
}
log() {
    tail -fn 300 $app_dir/log/store_backend_api.log
}
lsof() {
    /usr/bin/lsof -p `cat $pidfile`
}
heap() {
    dd=`date +%m%d-%H%M`
    mkdir -p $app_dir/log/heap
    jmap -histo `cat $pidfile` > $app_dir/log/heap/$dd.txt
    jmap -dump:format=b,file=$app_dir/log/heap/$dd.bin `cat $pidfile`
}
gc() {
    jstat -gc `cat $pidfile` 5000
}
version() {
    if [[ -f "lib/$appjar" ]]; then
        unzip -p "lib/$appjar" META-INF/MANIFEST.MF | sed -e '/Manifest-Version.*$/d'
    else
        echo "$appjar file not found"
    fi
}
case "$1" in
    net)
        net;;
    log)
        log;;
    gc)
        gc;;
    lsof)
        lsof;;
    heap)
        heap;;
    start)
        start;;
    stop)
        stop;;
    shutdown)
        shutdown;;
    restart)
        stop
        start;;
    version)
        version;;
    *)
        echo "Usage: server {start|stop|restart|net|log|lsof|heap|gc|version}"
        exit;
esac
exit 0;