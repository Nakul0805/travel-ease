FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --verbose || (echo "==== Dumping all .log files ====" && find . -type f -name "*.log" -exec cat {} \; && exit 1)
COPY . .
CMD ["npm" , "start"]
