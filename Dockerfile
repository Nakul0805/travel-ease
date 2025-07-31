FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --verbose \ || (echo "==== NPM INSTALL FAILED ====" 
COPY . .
CMD ["npm" , "start"]
