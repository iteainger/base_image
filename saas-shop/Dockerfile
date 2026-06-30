FROM node:slim

WORKDIR /app

COPY package.json .

RUN npm install \
 && mv node_modules /opt
