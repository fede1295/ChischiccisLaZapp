# Stage 1: Build
FROM node:20 AS builder
WORKDIR /app

RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

COPY . .
RUN pnpm run build

# Stage 2: Serve con Nginx (Adattato per Render)
FROM nginx:alpine AS runner

# Rimuovi la pagina HTML di default di Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia i file statici compilati da Vite
COPY --from=builder /app/dist /usr/share/nginx/html

# Configurazione speciale per Render:
# 1. Usa la porta 8080 (o la variabile d'ambiente PORT se passata da Render)
# 2. Sposta i file temporanei di Nginx in cartelle /tmp dove chiunque ha i permessi di scrittura
RUN echo 'server { \
    listen ${PORT:-8080}; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf.template

# Permetti a Nginx di funzionare senza privilegi di root modificando i percorsi di cache
RUN sed -i 's/user  nginx;//g' /etc/nginx/nginx.conf && \
    sed -i 's|/var/run/nginx.pid|/tmp/nginx.pid|g' /etc/nginx/nginx.conf && \
    mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chmod -R 777 /tmp /var/cache/nginx /var/run /var/log/nginx

# Usa envsubst per iniettare la variabile PORT di Render nella configurazione di Nginx prima di avviarlo
CMD /bin/sh -c "envsubst '\${PORT}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
