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
  # 引き数がひとつも指定されていない場合はエラー
  if [ $# -eq 0 ]; then
    echo "Error! 引数にファイルを指定してください"
    exit 1
  fi

  # 第1引数のファイルが存在しない場合はエラー
  if [ ! -e $1 ]; then
    echo "Error! 指定されたファイルが存在しません"
    exit 1
  fi

  # 第2引数は`-f`もしくは`--force`のみ許可
  if [ $# -eq 2 ]; then
    if [ $2 != "-f" ] && [ $2 != "--force" ]; then
      echo "Error! 第2引数は`-f`もしくは`--force`のみ許可されています"
      exit 1
    fi
  fi
}

function copy_to_workdir()
{
  # ファイルをworkdirにコピー
  WORK_FILE_PATH=$WORKDIR/$2
  cp $1/$2 $WORK_FILE_PATH
}

function optimize()
{
  local filename=$1
  local ext=$2

  if [ $ext = "jpg" ]; then
    docker run --rm -v $WORKDIR:/work koboriakira/squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /work /work/$filename
  elif [ $ext = "png" ]; then
    docker run --rm -v $WORKDIR:/work koboriakira/squoosh-cli squoosh-cli --oxipng '{quality:30}' -d /work /work/$filename
  else
    echo "Error! jpg,png以外の画像ファイルは対応していません"
    exit 1
    # NOTE: jpg,png以外の画像ファイル、webp形式に変換したいが、うまく動かないことのほうが多そう
    # docker run -it --rm -v $WORKDIR:/var squoosh-cli squoosh-cli --webp auto -d /var /var/$filename
  fi
}

function move_to_originaldir()
{
  dirname=$1
  basename=$2
  ext=$3
  force_update=$4

  message="update "
  # force_updateがfalseの場合はファイル名のsuffixに「_squoosh」を付与
  if [ $force_update = false ]; then
    basename=${basename}_squoosh
    message="create "
  fi
  copy_file_path=$dirname/${basename}.${ext}
  echo "${message} $copy_file_path"
  mv -f $WORK_FILE_PATH $copy_file_path
}

validate $1 $2
check_workdir

# ファイル名を取得
dirname=$(cd $(dirname $1); pwd) #ディレクトリ
filename=$(basename $1) #ファイル名
basename=${filename%.*} #拡張子を除いたファイル名
ext=$(echo ${filename##*.} | tr '[A-Z]' '[a-z]') #拡張子


# 上書きフラグ(bool)を取得
force_update=false
if [ $# -eq 2 ]; then
  if [ $2 = "-f" ] || [ $2 = "--force" ]; then
    force_update=true
  fi
fi

# 指定されたファイルをworkdirにコピー
copy_to_workdir $dirname $filename

# 変換
optimize $filename $ext

# workdirのファイルを元のディレクトリに移動
move_to_originaldir $dirname $basename $ext $force_update
