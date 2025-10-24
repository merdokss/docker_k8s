FROM node:18-alpine

WORKDIR /app

# Kopiuj package.json i zainstaluj zależności
COPY package.json .
RUN npm install --production

# Kopiuj kod aplikacji
COPY app.js .

# Utwórz katalog dla secretów (będzie montowany przez CSI)
RUN mkdir -p /mnt/secrets

EXPOSE 3000

CMD ["npm", "start"]

