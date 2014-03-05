#!/bin/bash
#
#Name:mytask
#Ver:1.0
#Author:lykyl
#
#
#程序说明:
#从指定的目录(默认为此脚本所在目录的tasks子目录中)调用任务脚本
#每个任务脚本都必须包含初始化语句和任务函数，函数名要保证唯一性。
#RunArg="<调用函数名>#<起始运行时间>#<运行周期>"
#以＃符分隔参数依次定义为：调用函数名、起始运行时间、运行周期
#调用的函数名必须当前脚本中定义
#
#起始运行时间分两部分。
#第一部分为初始时间，格式为"yyyy/MM/dd hh:mm:ss"也可以是时间值片断，例如："2013/03/05"、"03/05"、“03/05 21:30”、"21:30"或当前时间"now"。
#第二部分为修正时间，格式为"+时间单位"或“-时间单位”，意思为在初始时间的基础上做进一步的时间修正。
#例如："+5s"、"-10m"等。
#时间的单位区别大小写，具体定义如下：
#y=年、M=月、d=日、h=时、m=分、s=秒、w=星期
#
#运行周期即为任务函数运行的间隔时间，取值与修正时间类似，只是取消了+-号，如果值为不带单位的0则表示只运行一次。
#
#例如：
#RunArg='_backdb#00:00#1d'
#在凌晨零点开始执行_backdb函数，每隔1天运行一次。
#
#RunArg='_test1func#now+2m#5m'
#在当前时间的2分钟后开始执行_test1func函数，每隔5分钟运行一次。
#
#RunArg='_test2func#10:10-5m#1h'
#在10点10分的5分钟前开始执行_test2func函数，每隔1小时运行一次。
#
#RunArg='_test3func#10:00#30s'
#在10点开始执行_test3func函数，每隔30秒运行一次。
#
#RunArg='_test4func#now#1M'
#启动即开始执行_test4func函数，每隔1个月运行一次。
#
#RunArg='RunArg='_test5func#5/12 14:30#0'
#在5月12日14点30开始执行_test2func函数，只运行一次。


FUNCDIR=`dirname $0`"/tasks"
LOGFILE=`dirname $0`"/mytask.log"
PIDFILE=`dirname $0`"/mytask.pid"
LOCKFILE=`dirname $0`"/mytask.lock"
MISSTIMES=10
ONEHOUR=3600
ONEDAY=86400
ONEWEEK=604800
INIT=-99999999999
MAXTIME=99999999999

if [ -f $LOCKFILE ]; then
  exit 0
else
  touch $LOCKFILE
  echo "mytask start at "`date` >$LOGFILE
fi
trap "rm -f $LOCKFILE;rm -f $FUNCDIR/*_lock;echo 'exit';kill -15 $$" SIGINT EXIT

declare -a aRunList

echo "$$">$PIDFILE
for i in `ls $FUNCDIR/*.sh`
do
  if [ -f "$i" ]; then
    RunArg=
    . $i
    if [ "${RunArg:-'none'}" = "none" ]; then
      continue
    fi
    fn=`echo $RunArg|awk -F# '{print $1}'`
    startRun=`echo $RunArg|awk -F# '{print $2}'`
    atime=`echo $RunArg|awk -F# '{print $3}'`
    if (( ${#fn} < 1 )) || (( ${#startRun} < 1 )) || (( ${#atime} < 1 )); then
      continue
    fi
    startTime=${startRun%[+|-]*}
    startSec=`date -d "$startTime" +%s`
    fixTime=${startRun:${#startTime}:$[ ${#startRun} - ${#startTime} ]}
    case ${fixTime:$[ ${#fixTime} - 1]} in
      s|[0-9])
        startSec=$[ $startSec + ${fixTime%s} ]
        ;;
      m)
        startSec=$[ $startSec + ${fixTime%m} * 60 ]
        ;;
      h)
        startSec=$[ $startSec + ${fixTime%h} * $ONEHOUR ]
        ;;
      d)
        startSec=$[ $startSec + ${fixTime%d} * $ONEDAY ]
        ;;
      w)
        startSec=$[ $startSec + ${fixTime%w} * $ONEWEEK ]
        ;;
      M)
        ty=`date -d $startTime +%y`
        tm=$[ `date -d $startTime +%m` + ${fixTime%M} ]
        td=$[ `date -d $startTime +%d` - 1 ]
        tt=`date -d $startTime +%T`
        if (( $tm > 12 )); then
          tm=$[ $tm % 12 ]
          ty=$[ $ty + $tm / 12 ]
        fi
        startSec=$[ `date -d "$ty-$tm-1 $tt" +%s` + $td * $ONEDAY ]
        ;;
      y)
        ty=$[ `date -d $startTime +%y` + ${fixTime%y} ]
        td=$[ `date -d $startTime +%j` - 1 ]
        tt=`date -d $startTime +%T`
        startSec=$[ `date -d "$ty-1-1 $tt" +%s` + $td * $ONEDAY ]
        ;;
    esac
    tp=s
    case ${atime:$[ ${#atime} - 1]} in
      s)
        addTime=${atime%s}
        ;;
      m)
        addTime=$[ ${atime%m} * 60 ]
        ;;
      h)
        addTime=$[ ${atime%h} * $ONEHOUR ]
        ;;
      d)
        addTime=$[ ${atime%d} * $ONEDAY ]
        ;;
      w)
        addTime=$[ ${atime%w} * $ONEWEEK ]
        ;;
      M)
        addTime=${atime%M}
        tp=M
        ;;
      y)
        addTime=${atime%y}
        tp=y
        ;;
      *)        
        addTime=$MAXTIME
        tp=0
        ;;
    esac
    aRunList=(${aRunList[@]} "$fn#$startSec#$addTime#$tp")
    echo "function name is $fn,start time is $startSec action type is $tp, action time is $addTime">>$LOGFILE;
  fi
done

while :
do
  if (( ${#aRunList[@]} <1 )); then
    exit 0
  fi
  IntervalTime=$INIT;
  nowTime=`date +%T`
  nowSec=`date +%s`
  for i in ${aRunList[@]}
  do
    fn=`echo $i|awk -F# '{print $1}'`
    startSec=`echo $i|awk -F# '{print $2}'`
    addTime=`echo $i|awk -F# '{print $3}'`
    tp=`echo $i|awk -F# '{print $4}'`
    if (( ${#fn} < 1 )) || (( ${#startSec} < 1 )) || (( ${#addTime} < 1 )) || (( ${#tp} < 1 )); then
      continue
    fi
    ntarg="${fn}_ntime"
    flagfile="${FUNCDIR}/${fn}_lock"
    eval ${ntarg}=\${${ntarg}:=$startSec}
    eval tntarg=\$${ntarg}
    tdiff=$[ $nowSec - $tntarg ]
    if (( $tdiff >= 0 )); then
      if ! [ -e $flagfile ] && (( $tdiff < $MISSTIMES )) ; then
        { 
        touch $flagfile;
        echo "$fn start at "`date`\(`date +%s`\) >>$LOGFILE;
        result=`$fn`;
        echo "$fn finished at "`date`\(`date +%s`\) >>$LOGFILE;
        rm -f $flagfile;
        } &
      else
        echo "$fn has skipped" >>$LOGFILE
      fi
      case $tp in
        s)
          addSec=$addTime
          ;;
        M)
          ty=`date +%y`
          tm=$[ `date +%m` + $addTime ]
          td=$[ `date +%d` - 1 ]
          if (( $tm > 12 )); then
            tm=$[ $tm % 12 ]
            ty=$[ $ty + $tm / 12 ]
          fi
          addSec=$[ `date -d "$ty-$tm-1 $nowTime" +%s` + $td * $ONEDAY ]
          ;;
        y)
          ty=$[ `date +%y` +$addTime ]
          td=$[ `date +%d` - 1 ]
          addSec=$[ `date -d "$ty-1-1 $nowTime" +%s` + $td * $ONEDAY ]
          ;;
        *)
          aRunList=(`echo ${aRunList[@]} |sed "s/$fn\(#[^#]*\)\{2\}#[^ ]*//g"`)
          IntervalTime=0;
          continue
          ;;
      esac
      tntarg=$[ $tntarg + ( $tdiff / $addSec ) * $addSec + $addSec ]
      eval ${ntarg}=$tntarg
      tdiff=$[ $nowSec - $tntarg ]
      echo "$fn next at $tntarg" >>$LOGFILE
    fi
    if (( $tdiff > $IntervalTime )) ; then      
      IntervalTime=$tdiff;
    fi
  done
  if (( $IntervalTime <= $INIT )); then
    IntervalTime=1;
  fi
  if (( $IntervalTime < 0 )); then
    IntervalTime=$[ $IntervalTime * -1 ];
  fi
  echo "interval:$IntervalTime" >>$LOGFILE
 (( $IntervalTime>0 )) && sleep $IntervalTime
done
