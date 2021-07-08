FROM node:12.16.3-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY ./package.json .
RUN npm install

COPY . .

EXPOSE 80
CMD ["npm", "start"]
