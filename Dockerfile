FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --verbose \ echo "==== Dumping all .log files ===="
COPY . .
CMD ["npm" , "start"]
