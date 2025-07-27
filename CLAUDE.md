# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

`squoosh-cli-on-docker`は、Google Chromeチームが開発したsquoosh-cliをDocker環境で利用するためのツールです。画像最適化を行うコマンドラインインターフェースを提供します。

## アーキテクチャ

### コアコンポーネント

- **main.sh**: メインのシェルスクリプト。標準入力と引数の両方に対応し、画像ファイルの圧縮処理を管理
- **Dockerfile**: Node.js 14.19.0ベースのコンテナで@squoosh/cliをインストール
- **sample/**: テスト用のサンプル画像ファイル

### 処理フロー

1. 入力検証（ファイル存在確認、引数チェック）
2. 作業ディレクトリ（デフォルト: /tmp/squoosh）の準備
3. 入力ファイルを作業ディレクトリにコピー
4. 拡張子に応じたDocker圧縮処理実行
   - JPG: mozjpeg（quality:30）
   - PNG: oxipng（quality:30）
5. 圧縮済みファイルを元ディレクトリに移動

### 入力処理

- 標準入力からのパイプ入力をサポート
- ファイルパス引数をサポート
- --force/-fオプションで上書き保存可能（デフォルトは_squooshサフィックス付与）

## 開発コマンド

### ビルド
```bash
docker build -t koboriakira/squoosh-cli:{version} .
```

### 実行
```bash
# 直接Docker実行
docker run --rm -v {画像ディレクトリ}:/var koboriakira/squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /var /var/{画像ファイル}

# シェルスクリプト経由（推奨）
bash main.sh sample/sample1.jpg
bash main.sh sample/sample1.jpg --force  # 上書き保存
```

### テスト
```bash
# サンプル画像でのテスト
bash main.sh sample/sample1.jpg
bash main.sh sample/sample2.png
```

## 重要な制約

- jpg,png形式のみサポート（webp対応は未実装）
- Docker環境必須
- 作業用の一時ディレクトリが必要（WORKDIR環境変数で変更可能）
- 拡張子の大文字小文字に対応済み