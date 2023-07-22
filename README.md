# squoosh-cli-on-docker

`squoosh-cli`をDocker環境上で利用できるようにしたツール。

## 利用例

```
docker pull koboriakira/squoosh-cli
```

```
docker run -it --rm -v {画像ファイルを含むディレクトリ}:/var koboriakira/squoosh-cli squoosh-cli --mozjpeg '{quality:30}' -d /var /var/{画像ファイル}
```

## シェルスクリプトの活用

リポジトリの`main.sh`を利用すると、Dockerコマンドを気にせずに画像ファイルを取り扱えます。

```
bash main.sh {画像ファイルのパス}

# 上書きでよい場合は、--forceオプションをつける
bash main.sh {画像ファイルのパス} --force
```
