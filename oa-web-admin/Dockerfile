FROM node:slim

WORKDIR /app

COPY package.json .

RUN npm install --include=dev  \
 && mv node_modules /opt
