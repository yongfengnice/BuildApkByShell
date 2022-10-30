#!/usr/bin/env bash

# processOptions $@
function processOptions() {
  for arg in "$@"; do
    #echo ${arg} >>build.log #--channel=yyb
    if [ "${arg:0:1}"=="-" ] && [ "${arg:1:1}"=="-" ]; then
      option="${arg:2}"          # channel=yyb
      option_key="${option%%=*}" # %%表示右删除，%%=*删除等号右边所有
      if [[ $option =~ = ]]; then # =~表示正则匹配，是否含=
        option_value="${option##*=}" # ##表示左删除，##*=删除等号左边所有
      else
        option_value="DEFAULT" #给个默认值
      fi
      options["$option_key"]="$option_value"
      #      echo "option_value222=${options["$option_key"]}"
    else
      arguments+=("$arg")
      echo "arg=$arg"
    fi
  done
}

# shell 语言中 0 代表 true，0 以外的值代表 false
# isOptionEnabled "push"
# isOptionEnabled "push" "true"

# if isOptionEnabled "push"; 等价于下面两句
# isOptionEnabled "push"
# if [ $? ];  # if [ 一元表达式 ]; 和 if 逻辑表达式; 这两个if情况一个带[]一个不带[]是不同的

# $?表示获取isOptionEnabled函数调用结果，shell是通过$?获取函数返回值的
# 类似local isXX=isOptionEnabled "push" 报语法错误
# 如果想接收函数返回值结果可以使用类似下面的两句
# isOptionEnabled "push"
# local isXX=$?   # =号两边中间不能有空格
function isOptionEnabled() {
  local option_key="enable-$1" #$1表示第一次参数
  local option_value="${options[$option_key]}"
  if [ "$option_value" == "true" ] || [ "$option_value" == "DEFAULT" ]; then
    return 0
  fi
  if [ "$option_value" == "false" ]; then
    return 1
  fi

  option_key="disable-$1"
  option_value="${options[$option_key]}"
  if [ "$option_value" == "true" ] || [ "$option_value" == "DEFAULT" ]; then
    return 1
  fi
  if [ "$option_value" == "false" ]; then
    return 0
  fi

  if [ "$2" == "true" ]; then
    return 0
  else
    return 1
  fi
}

function processAndroidSdk() {
  local android_relative_path
  local adb_relative_path
  echo "processAndroidSdk $OSTYPE"
  if [ "$OSTYPE" = "cygwin" ]; then
    android_relative_path="tools/android.bat"
    adb_relative_path="platform-tools/adb.exe"
  else # "linux-gnu"
    android_relative_path="tools/android"
    adb_relative_path="platform-tools/adb"
  fi

  if [ -f ../android-sdk.properties ]; then #可以换为local.properties
    local sdk_line=$(grep "sdk.dir=" ../android-sdk.properties)
    local sdk_dir=${sdk_line##*=}
    if [ "$OSTYPE" = "cygwin" ]; then
      sdk_dir=$(cygpath -u $sdk_dir)
    fi

    if [ -f $sdk_dir/$android_relative_path ] && [ -f $sdk_dir/$adb_relative_path ]; then
      androidSdk=$sdk_dir
    else
      echo "Please specify the correct sdk.dir in ../android-sdk.properties"
      return 1
    fi
  fi

  if [ -z $androidSdk ]; then
    adb_path=$(which adb 2>/dev/null)
    if [ -f $adb_path ]; then
      androidSdk=$(dirname $(dirname $adb_path))
    fi
  fi

  if [ -z $androidSdk ] || ! [ -d $androidSdk ]; then
    echo "Please set ANDROID_SDK to the correct path:"
    echo "* specify sdk.dir in android-sdk.properties or"
    echo "* add <SDK>/tools and <SDK>/platform-tools to system path or"
    echo "* set ANDROID_SDK environment variable"
    return 1
  fi

  return 0
}
