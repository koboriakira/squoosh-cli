# docker build -t koboriakira/squoosh-cli:{version} .
# docker run -it --rm squoosh-cli test.jpg
FROM node:14.19.0

RUN npm install -g @squoosh/cli
