#!/usr/bin/env bash

#declare -A options # -A声明map,也叫关联数组
#在 macOS 的 terminal 中出现了相同的错误："declare: -A: invalid option"
#升级 Bash 请参照：https://juejin.cn/post/6844904085146058766

declare -A options   # -A声明map,也叫关联数组
declare -a arguments # -a声明list
declare android_sdk

function handleOptions() {
  processOptions $*
}

function handleAndroidSdk() {
  processAndroidSdk $*
  echo "Android SDK Path = $android_sdk"
  export PATH=$android_sdk/tools:$android_sdk/platform-tools:$PATH
  export LANG=en_US.UTF-8
}

function preProcessBuild() {
  echo "preProcessBuild"
}

function startGradleBuild() {
  echo "startGradleBuild"
  sed -i '.bak' '/shellBuild/d' ../settings.gradle && rm -f ../settings.gradle.bak
}

function main() {
  source ./options.sh

  echo "Build Log:" >>build.log
  local buildOk=false
  handleOptions "$@"
  handleAndroidSdk "$@"
  preProcessBuild
  startGradleBuild && buildOk=true

  if isOptionEnabled "push"; then
    echo "is push enable=true"
  else
    echo "is push enable=false"
  fi

  #sudo chmod +x build.sh添加可执行权限
  #./build.sh --version=100 --channel=yyb --enable-push
  echo "options-01:${options["version"]}"
  echo "options-02:${options["channel"]}"

  if [ $buildOk = true ]; then
    echo "Build SUCCESS"
    return 0
  else
    echo "Build FAILURE!!!"
    return 1
  fi

}

main "$@"
