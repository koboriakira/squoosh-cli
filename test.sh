#!/bin/bash
# 第1引数に指定されたファイルを、squoosh-cliで圧縮する

function check_workdir() {
  # 環境変数WORKDIRが設定されていない場合は、デフォルト値を設定
  if [ -z $WORKDIR ]; then
    WORKDIR=/tmp/squoosh
  fi

  # ディレクトリが存在しない場合は作成
  if [ ! -d $WORKDIR ]; then
    mkdir $WORKDIR
  fi
}

function validate(){
  # 第1引数が指定されていない場合はエラー
  if [ $# -ne 1 ]; then
    echo "Error! 最適化したいファイルを指定してください"
    exit 1
  fi

  # 第1引数のファイルが存在しない場合はエラー
  if [ ! -e $1 ]; then
    echo "Error! 指定されたファイルが存在しません"
    exit 1
  fi
}

function copy_to_workdir()
{
  # ファイルをworkdirにコピー
  WORK_FILE_PATH=$WORKDIR/$2
  echo "copy $1/$2 to $WORK_FILE_PATH"
  cp $1/$2 $WORK_FILE_PATH
}

function optimize()
{
  docker run -it --rm -v $WORKDIR:/var squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /var /var/$1
}

function move_to_originaldir()
{
  # ファイルをコピーし、ファイル名のsuffixに「_squoosh」を付与
  copy_file_path=$1/${2}_squoosh.${3}
  echo "move $WORK_FILE_PATH to $copy_file_path"
  mv -f $WORK_FILE_PATH $copy_file_path
}

validate $1
check_workdir

# ファイル名を取得
dirname=$(cd $(dirname $1); pwd) #ディレクトリ
filename=$(basename $1) #ファイル名
basename=${filename%.*} #拡張子を除いたファイル名
ext=${filename##*.} #拡張子

# 指定されたファイルをworkdirにコピー
copy_to_workdir $dirname $filename

# 変換
optimize $filename

# ファイルをコピーし、ファイル名のsuffixに「_squoosh」を付与
move_to_originaldir $dirname $basename $ext
