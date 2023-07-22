# squoosh-cli-on-docker

`squoosh-cli`をDocker環境上で利用できるようにしたツール。

## 利用例

```
docker pull koboriakira/squoosh-cli
```

```
docker run --rm -v {画像ファイルを含むディレクトリ}:/var koboriakira/squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /var /var/{画像ファイル}
```

## シェルスクリプトの活用

リポジトリの`main.sh`を利用すると、Dockerコマンドを気にせずに画像ファイルを取り扱えます。

```
bash main.sh {画像ファイルのパス}

# 上書きでよい場合は、--forceオプションをつける
bash main.sh {画像ファイルのパス} --force
```

次のような関数を定義しておけば、簡単にsquoosh-cliが利用できることになります。
```
function squoosh() {
  local shell_path={main.shの絶対パス}
  # shell_pathが存在するか確認
  if [ ! -e $shell_path ]; then
    echo "シェルスクリプトが存在しません。: $shell_path"
    return 1
  fi
  zsh $shell_path $@
}
```
