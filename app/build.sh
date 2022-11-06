#!/usr/bin/env bash

#declare -A options # -A声明map,也叫关联数组
#在 macOS 的 terminal 中出现了相同的错误："declare: -A: invalid option"
#升级 Bash 请参照：https://juejin.cn/post/6844904085146058766

declare -A options   # -A声明map,也叫关联数组
declare -a arguments # -a声明list
declare androidSdk
declare buildType
declare lastGitVer

function handleOptions() {
  processOptions $*
  buildType=${options["buildType"]}
  if ! [ "$buildType" == "debug" ] && ! [ "$buildType" == "release" ]; then
    buildType="debug"
  fi
  echo "buildType==$buildType"
}

function handleAndroidSdk() {
  processAndroidSdk $*
  echo "Android SDK Path=$androidSdk"
  export PATH=$androidSdk/tools:$androidSdk/platform-tools:$PATH
  export LANG=en_US.UTF-8
}

function preProcessBuild() {
  if [ -z $lastGitVer ]; then
    lastGitVer=$(git log --pretty=format:'%h' -n 1)
  fi
  echo "lastGitVer=$lastGitVer"

  echo "preProcessBuild"
}

function startGradleBuild() {
  local buildOk="false"
  echo "startGradleBuild"
  # mac下执行sed -i需要备份，所以这里先给个bak备份然后再删除bak备份文件
  sed -i '.bak' '/shellBuild/d' ../settings.gradle && rm -f ../settings.gradle.bak

  bash ../gradlew "clean"
  rm -Rf bin

  #bash ../gradlew :app:depend --scan #--configuration implementation
  #-i/--info -d/--debug -s/--stacktrace
  #-P传递构建参数给project ext，可以通过project.ext.get("newPkgName")获取
  bash ../gradlew ":app:assemble${buildType}" -s \
    -PnewPkgName=${options["newPkgName"]} \
    2>&1 | tee -a buildLog && buildOk="true"

  [ -d bin ] || mkdir -p bin
  cp -Rf build/outputs/apk/* bin/ && buildOk="true"
  if [ "$buildOk" = "false" ] || ! [ -d "bin/${buildType}" ]; then
    echo "Build FAILURE!!! Please see log in buildLog"
    return 1
  else
    return 0
  fi
}

function main() {
  source ./options.sh

  echo "Build Log:" >buildLog
  local buildOk=false
  handleOptions "$@"
  handleAndroidSdk "$@"
  preProcessBuild
  startGradleBuild && buildOk=true

  #test isOptionEnabled call
  if isOptionEnabled "push"; then
    echo "is push enable=true"
  else
    echo "is push enable=false"
  fi

  #打开Terminal，cd app切换到app目录下，sudo chmod +x build.sh添加可执行权限
  #./build.sh --buildType=debug --newPkgName="com.suyf.test" --channel=yyb --enable-push
  #./build.sh --buildType=release --newPkgName="com.suyf.test" --channel=yyb --enable-push
  echo "options-01:${options["newPkgName"]}"
  echo "options-02:${options["channel"]}"

  if [ $buildOk = true ]; then
    echo "Build SUCCESS"
    return 0
  else
    echo "Build FAILURE!!!"
    return 1
  fi
  if ! [ -z $lastGitVer ]; then
    git reset --hard $lastGitVer
  fi

}

main "$@"
