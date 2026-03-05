# Stage 1: Build
FROM node:20-slim AS builder
WORKDIR /app

# Abilita corepack per usare la versione di pnpm corretta (consigliato)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copia i file delle dipendenze
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copia il codice sorgente e crea la build
COPY . .
RUN pnpm run build

# Stage 2: Serve con Nginx
FROM nginx:alpine AS runner

# Rimuovi la pagina HTML di default di Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia i file statici compilati da Vite nella cartella che Nginx usa per servirli
COPY --from=builder /app/dist /usr/share/nginx/html

# (Opzionale ma utile) Aggiungi una configurazione per le Single Page Application 
# per reindirizzare tutte le rotte a index.html se usi il router lato client
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

# Avvia Nginx in primo piano
CMD ["nginx", "-g", "daemon off;"]
