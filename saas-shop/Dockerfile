FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install \
 && mv node_modules /opt
