FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --verbose || (echo "==== NPM Install Logs ====" && cat /root/.npm/_logs/* || true && exit 1)
COPY . .
CMD ["npm" , "start"]
