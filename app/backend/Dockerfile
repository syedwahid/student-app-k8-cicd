FROM node:18-alpine

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies with clean cache
RUN npm install --production --no-optional && npm cache clean --force

# Copy source code
COPY . .

EXPOSE 3000

USER node

CMD ["node", "app.js"]
