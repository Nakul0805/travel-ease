FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

# Fail if package.json is missing
RUN if [ ! -f package.json ]; then \
    echo "ERROR: package.json is required but missing!" ; \
    exit 1; \
  fi

RUN npm install --verbose || (echo "==== NPM LOGS ====" && find . -type f -name "*.log" -exec cat {} \; && exit 1)

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
