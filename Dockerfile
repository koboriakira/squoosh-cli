# docker build -t squoosh-cli .
# docker run -it --rm squoosh-cli squoosh-cli --help
FROM node:14.19.0

RUN npm install -g @squoosh/cli

# squoosh-cli --mozjpeg '{quality:30}' 画像サンプル_大きめ.jpg
