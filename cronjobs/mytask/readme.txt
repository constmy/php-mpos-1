脚本以终端无关的形式在后台执行
启动命令:nohup mytask.sh & 
结束运行的命令:kill -15 `cat mytask.pid`

脚本在centos6 及ubuntu12测试通过。
