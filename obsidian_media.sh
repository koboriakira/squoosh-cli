#!/bin/bash
# Obsidianメディアフォルダ内の1MB以上の画像ファイルを一括最適化するスクリプト
# 使用方法:
#   bash obsidian_media.sh           # 通常実行（_squooshサフィックス付きで保存）
#   bash obsidian_media.sh --force   # 元ファイルを上書き
#
# 対象: /Users/a_kobori/Library/Mobile Documents/iCloud~md~obsidian/Documents/my-vault/media
# 条件: 1MB以上のjpg, jpeg, png ファイル
# 圧縮設定: JPG=mozjpeg(quality:30), PNG=oxipng(quality:30)

# Obsidianメディアディレクトリのパス
OBSIDIAN_MEDIA_DIR="/Users/a_kobori/Library/Mobile Documents/iCloud~md~obsidian/Documents/my-vault/media"

# 作業ディレクトリの準備
# 環境変数WORKDIRで変更可能（デフォルト: /tmp/squoosh）
function check_workdir() {
  # 環境変数WORKDIRが設定されていない場合は、デフォルト値を設定
  if [ -z "$WORKDIR" ]; then
    WORKDIR=/tmp/squoosh
  fi

  # ディレクトリが存在しない場合は作成
  if [ ! -d "$WORKDIR" ]; then
    mkdir -p "$WORKDIR"
  fi
}

# オプション引数の妥当性チェック
function validate_options(){
  local force_update_option=$1

  # 引数が指定されている場合は、`-f`もしくは`--force`のみ許可
  if [ $# -eq 1 ]; then
    if [ "$force_update_option" != "-f" ] && [ "$force_update_option" != "--force" ]; then
      echo "Error! 引数は\`-f\`もしくは\`--force\`のみ許可されています"
      exit 1
    fi
  fi
}

# Obsidianメディアディレクトリの存在確認
function check_obsidian_dir() {
  if [ ! -d "$OBSIDIAN_MEDIA_DIR" ]; then
    echo "Error! Obsidianメディアディレクトリが存在しません: $OBSIDIAN_MEDIA_DIR"
    exit 1
  fi
}

# 1MB以上の画像ファイルを検索
function find_large_images() {
  # 1MB = 1048576 bytes
  find "$OBSIDIAN_MEDIA_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -size +1M
}

# 元ファイルを作業ディレクトリにコピー
function copy_to_workdir()
{
  local file_path="$1"
  local filename=$(basename "$file_path")

  # ファイルをworkdirにコピー
  WORK_FILE_PATH="$WORKDIR/$filename"
  cp "$file_path" "$WORK_FILE_PATH"
}

# 画像最適化処理
# 拡張子に応じてDocker経由でsquoosh-cliを実行
# JPG: mozjpeg（quality:30） / PNG: quant+oxipng（色数削減 + 最適化）
function optimize()
{
  local filename="$1"
  local ext="$2"

  if [ "$ext" = "jpg" ] || [ "$ext" = "jpeg" ]; then
    # JPEG最適化（mozjpeg使用）
    docker run --rm -v "$WORKDIR:/work" koboriakira/squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /work "/work/$filename"
  elif [ "$ext" = "png" ]; then
    # PNG最適化（色数削減 + oxipng使用）
    # 色数を削減してからoxipngで最適化することで、より効果的な圧縮を実現
    docker run --rm -v "$WORKDIR:/work" koboriakira/squoosh-cli squoosh-cli --quant '{numColors:64}' --oxipng '{}' -d /work "/work/$filename"
  else
    echo "Error! jpg,jpeg,png以外の画像ファイルは対応していません"
    exit 1
  fi
}

# 最適化済みファイルを元ディレクトリに移動
# --forceオプションなし: {元ファイル名}_squoosh.{拡張子}
# --forceオプションあり: 元ファイルを上書き
function move_to_originaldir()
{
  local original_file_path="$1"
  local dirname=$(dirname "$original_file_path")
  local filename=$(basename "$original_file_path")
  local basename=${filename%.*}
  local original_ext=$(echo ${filename##*.} | tr '[A-Z]' '[a-z]')
  local force_update="$2"

  # squoosh-cliが生成した実際のファイルを探す
  # JPEGの場合、.jpeg → .jpg に変換される可能性がある
  local optimized_file=""
  if [ "$original_ext" = "jpeg" ]; then
    # .jpeg の場合、.jpg ファイルが生成される可能性がある
    if [ -f "$WORKDIR/${basename}.jpg" ]; then
      optimized_file="$WORKDIR/${basename}.jpg"
    elif [ -f "$WORKDIR/${basename}.jpeg" ]; then
      optimized_file="$WORKDIR/${basename}.jpeg"
    fi
  else
    # その他の拡張子の場合は元の拡張子をそのまま使用
    optimized_file="$WORKDIR/${basename}.${original_ext}"
  fi

  # 最適化されたファイルが見つからない場合はエラー
  if [ ! -f "$optimized_file" ]; then
    echo "Error: 最適化されたファイルが見つかりません: $optimized_file"
    return 1
  fi

  message="update "
  local target_ext="$original_ext"

  # force_updateがfalseの場合はファイル名のsuffixに「_squoosh」を付与
  if [ "$force_update" = false ]; then
    basename="${basename}_squoosh"
    message="create "
  fi

  copy_file_path="$dirname/${basename}.${target_ext}"
  echo "${message} $copy_file_path"
  mv -f "$optimized_file" "$copy_file_path"
}

# ファイルサイズを人間が読みやすい形式で表示
function format_size() {
  local size_bytes=$1
  if [ $size_bytes -ge 1073741824 ]; then
    echo "$(( size_bytes / 1073741824 ))GB"
  elif [ $size_bytes -ge 1048576 ]; then
    echo "$(( size_bytes / 1048576 ))MB"
  elif [ $size_bytes -ge 1024 ]; then
    echo "$(( size_bytes / 1024 ))KB"
  else
    echo "${size_bytes}B"
  fi
}

# 単一ファイルを処理
function process_file() {
  local file_path="$1"
  local force_update="$2"

  # ファイル情報の抽出
  local filename=$(basename "$file_path")
  local basename=${filename%.*}
  local ext=$(echo ${filename##*.} | tr '[A-Z]' '[a-z]')
  local file_size=$(stat -f%z "$file_path")
  local file_size_formatted=$(format_size $file_size)

  echo "処理中: $filename ($file_size_formatted)"

  # 処理実行
  copy_to_workdir "$file_path"  # ファイルを作業ディレクトリにコピー
  optimize "$filename" "$ext"   # 画像最適化実行
  move_to_originaldir "$file_path" "$force_update"  # 結果ファイルを移動

  # 最適化後のファイルサイズを確認
  local optimized_file_path
  if [ "$force_update" = true ]; then
    optimized_file_path="$file_path"
  else
    local dirname=$(dirname "$file_path")
    optimized_file_path="$dirname/${basename}_squoosh.${ext}"
  fi

  if [ -f "$optimized_file_path" ]; then
    local new_size=$(stat -f%z "$optimized_file_path")
    local new_size_formatted=$(format_size $new_size)
    local reduction_percent=$(( (file_size - new_size) * 100 / file_size ))
    echo "完了: $filename $file_size_formatted → $new_size_formatted (${reduction_percent}% 削減)"
  fi

  echo ""
}

# ==========================================================
# メイン処理開始
# ==========================================================

echo "Obsidianメディアフォルダ画像最適化スクリプト"
echo "対象ディレクトリ: $OBSIDIAN_MEDIA_DIR"
echo "条件: 1MB以上のjpg, jpeg, png ファイル"
echo ""

# オプション引数の取得
force_update_option=$1

# 入力値検証と作業ディレクトリ準備
validate_options $force_update_option
check_obsidian_dir
check_workdir

# 上書きフラグ(bool)を取得
force_update=false
if [ "$force_update_option" = "-f" ] || [ "$force_update_option" = "--force" ]; then
  force_update=true
  echo "モード: 元ファイル上書き"
else
  echo "モード: _squooshサフィックス付きで新規作成"
fi
echo ""

# 1MB以上の画像ファイルを検索
echo "1MB以上の画像ファイルを検索中..."
large_images=$(find_large_images)

if [ -z "$large_images" ]; then
  echo "対象となる画像ファイルが見つかりませんでした。"
  exit 0
fi

# 見つかったファイル数を表示
file_count=$(echo "$large_images" | wc -l)
echo "対象ファイル数: $file_count"
echo ""

# 各ファイルを処理
while IFS= read -r file_path; do
  process_file "$file_path" "$force_update"
done <<< "$large_images"

echo "すべての画像最適化が完了しました。"
