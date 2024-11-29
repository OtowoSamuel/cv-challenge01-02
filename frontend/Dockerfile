FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm cache clean --force && \
    npm install --fetch-timeout=60000


COPY . .
# COPY .env ./

RUN npm run build

RUN ls -alh dist

CMD ["npx", "serve", "-s", "dist", "-l", "3000"]

