# Stage 1: Build
# Usiamo l'immagine Node completa invece della "slim" per avere tutti gli strumenti di compilazione (C++, Python) necessari a Vite/esbuild
FROM node:20 AS builder
WORKDIR /app

# Abilitiamo pnpm usando la versione che hai usato in locale per generare il lockfile
RUN corepack enable

# Copiamo prima i manifesti
COPY package.json pnpm-lock.yaml ./

# Rimuoviamo --frozen-lockfile. Se la versione di pnpm nel container è più recente, 
# il flag frozen bloccherebbe l'installazione rilevando differenze di formato.
RUN pnpm install

# Copiamo il resto del codice e avviamo la build
COPY . .
RUN pnpm run build
