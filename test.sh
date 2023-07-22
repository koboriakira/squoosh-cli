#!/bin/bash
# 第1引数に指定されたファイルを、squoosh-cliで圧縮する


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

WORKDIR=$HOME/git/squoosh-cli/workdir
# 第1引数のファイルパスについて、ディレクトリ部分を除いてファイル名を取得
DIR_NAME=$(cd $(dirname $1); pwd)
FILE_NAME=$(basename $1)
FILE_PATH=$DIR_NAME/$FILE_NAME
# workdirの作成
if [ ! -d $WORKDIR ]; then
  mkdir $WORKDIR
fi

# 指定されたファイルをworkdirにコピー
echo "copy $DIR_NAME/$FILE_NAME to $WORKDIR/$FILE_NAME"
cp $DIR_NAME/$FILE_NAME $WORKDIR/$FILE_NAME

# 変換
docker run -it --rm -v $WORKDIR:/var squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /var /var/$FILE_NAME

# ファイルをコピーし、ファイル名のsuffixに「_squoosh」を付与
original_file_path=$DIR_NAME/$FILE_NAME
echo $original_file_path
file_path=${original_file_path%.*}_squoosh
ext=${original_file_path##*.}
copy_file_path=$file_path.$ext
echo "move $WORKDIR/$FILE_NAME to $copy_file_path"
mv -f $WORKDIR/$FILE_NAME $copy_file_path
