# Stage 1: Build
FROM node:20 AS builder
WORKDIR /app

RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

COPY . .
RUN pnpm run build

# Stage 2: Serve con Nginx
FROM nginx:alpine AS runner

# Rimuovi la pagina HTML di default di Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia i file statici compilati da Vite
COPY --from=builder /app/dist /usr/share/nginx/html

# Scrivi il template in /etc/nginx/templates/ 
# L'immagine ufficiale di nginx:alpine processa automaticamente tutti i file .template 
# in questa cartella usando envsubst all'avvio del container.
# Usiamo solo ${PORT} (senza fallback) perché su Render questa variabile esiste sempre.
RUN mkdir -p /etc/nginx/templates && echo 'server { \
    listen ${PORT}; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/templates/default.conf.template

# Permetti a Nginx di funzionare senza privilegi di root modificando i percorsi di cache e disabilitando l'utente nginx
RUN sed -i 's/user  nginx;//g' /etc/nginx/nginx.conf && \
    sed -i 's|/var/run/nginx.pid|/tmp/nginx.pid|g' /etc/nginx/nginx.conf && \
    mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chmod -R 777 /tmp /var/cache/nginx /var/run /var/log/nginx /etc/nginx/conf.d

# Lasciamo che Nginx usi il suo punto d'ingresso originale (che processa i template e avvia Nginx)
# Non abbiamo bisogno di sovrascrivere il CMD
