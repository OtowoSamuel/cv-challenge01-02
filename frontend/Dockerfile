FROM node:18-alpine3.18

WORKDIR /app

COPY package*.json /app/

RUN npm install
 
COPY . /app/

CMD npm run dev -- --host 0.0.0.0
