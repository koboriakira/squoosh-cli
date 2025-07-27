#!/bin/bash
# 指定されたファイルをsquoosh-cliで圧縮するスクリプト
# 使用方法:
#   bash main.sh path/to/image.jpg           # _squooshサフィックス付きで保存
#   bash main.sh path/to/image.jpg --force   # 元ファイルを上書き
#   echo "path/to/image.jpg" | bash main.sh  # パイプ入力
#
# 対応形式: jpg, jpeg, png
# 圧縮設定: JPG=mozjpeg(quality:30), PNG=oxipng(quality:30)

# 標準入力があるかチェックする（パイプ入力対応）
if [ -p /dev/stdin ]; then
    # 標準入力がある場合
    input=$(cat)
    force_update_option=$1
else
    # 標準入力がない場合
    input=$1
    force_update_option=$2
fi


# 作業ディレクトリの準備
# 環境変数WORKDIRで変更可能（デフォルト: /tmp/squoosh）
function check_workdir() {
  # 環境変数WORKDIRが設定されていない場合は、デフォルト値を設定
  if [ -z "$WORKDIR" ]; then
    WORKDIR=/tmp/squoosh
  fi

  # ディレクトリが存在しない場合は作成
  if [ ! -d "$WORKDIR" ]; then
    mkdir "$WORKDIR"
  fi
}

# 入力値の検証
# - ファイル存在チェック
# - オプション引数の妥当性チェック
function validate(){
  local input=$1
  local force_update_option=$2
  # 引き数がひとつも指定されていない場合はエラー
  if [ $# -eq 0 ]; then
    echo "Error! 引数にファイルを指定してください"
    exit 1
  fi

  # 第1引数のファイルが存在しない場合はエラー
  if [ ! -e "$input" ]; then
    echo "Error! 指定されたファイルが存在しません"
    exit 1
  fi

  # 第2引数は`-f`もしくは`--force`のみ許可
  if [ $# -eq 2 ]; then
    if [ "$force_update_option" != "-f" ] && [ "$force_update_option" != "--force" ]; then
      echo "Error! 第2引数は\`-f\`もしくは\`--force\`のみ許可されています"
      exit 1
    fi
  fi
}

# 元ファイルを作業ディレクトリにコピー
# 処理中に元ファイルを保護するため
function copy_to_workdir()
{
  local dirname="$1"
  local filename="$2"
  # ファイルをworkdirにコピー
  WORK_FILE_PATH="$WORKDIR/$filename"
  cp "$dirname/$filename" "$WORK_FILE_PATH"
}

# 画像最適化処理
# 拡張子に応じてDocker経由でsquoosh-cliを実行
# JPG: mozjpeg（quality:30） / PNG: oxipng（quality:30）
function optimize()
{
  local filename="$1"
  local ext="$2"

  if [ "$ext" = "jpg" ] || [ "$ext" = "jpeg" ]; then
    # JPEG最適化（mozjpeg使用）
    docker run --rm -v "$WORKDIR:/work" koboriakira/squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /work "/work/$filename"
  elif [ "$ext" = "png" ]; then
    # PNG最適化（oxipng使用）
    docker run --rm -v "$WORKDIR:/work" koboriakira/squoosh-cli squoosh-cli --oxipng '{quality:30}' -d /work "/work/$filename"
  else
    echo "Error! jpg,jpeg,png以外の画像ファイルは対応していません"
    exit 1
    # NOTE: jpg,png以外の画像ファイル、webp形式に変換したいが、うまく動かないことのほうが多そう
    # docker run -it --rm -v $WORKDIR:/var squoosh-cli squoosh-cli --webp auto -d /var /var/$filename
  fi
}

# 最適化済みファイルを元ディレクトリに移動
# --forceオプションなし: {元ファイル名}_squoosh.{拡張子}
# --forceオプションあり: 元ファイルを上書き
function move_to_originaldir()
{
  dirname="$1"
  basename="$2"
  ext="$3"
  force_update="$4"

  message="update "
  # force_updateがfalseの場合はファイル名のsuffixに「_squoosh」を付与
  if [ "$force_update" = false ]; then
    basename="${basename}_squoosh"
    message="create "
  fi
  copy_file_path="$dirname/${basename}.${ext}"
  echo "${message} $copy_file_path"
  mv -f "$WORK_FILE_PATH" "$copy_file_path"
}

# ==========================================================
# メイン処理開始
# ==========================================================

# 入力値検証と作業ディレクトリ準備
validate $input $force_update_option
check_workdir

# ファイル情報の抽出
dirname=$(cd "$(dirname "$input")"; pwd) #ディレクトリ
filename=$(basename "$input") #ファイル名
basename=${filename%.*} #拡張子を除いたファイル名
ext=$(echo ${filename##*.} | tr '[A-Z]' '[a-z]') #拡張子（小文字変換）


# 上書きフラグ(bool)を取得
# --force または -f が指定されていれば元ファイルを上書き
force_update=false
if [ $# -eq 2 ]; then
  if [ "$force_update_option" = "-f" ] || [ "$force_update_option" = "--force" ]; then
    force_update=true
  fi
fi

# 処理実行
copy_to_workdir "$dirname" "$filename"  # ファイルを作業ディレクトリにコピー
optimize "$filename" "$ext"             # 画像最適化実行
move_to_originaldir "$dirname" "$basename" "$ext" "$force_update"  # 結果ファイルを移動
