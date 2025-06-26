FROM node:slim

WORKDIR /app

COPY package.json .

RUN npm -i \
 && mv node_modules /opt
