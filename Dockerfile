# docker build -t squoosh-cli .
# docker run -it --rm squoosh-cli test.jpg
FROM node:14.19.0

RUN npm install -g @squoosh/cli
