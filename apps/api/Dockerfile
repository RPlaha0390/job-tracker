# ---- build stage: has dev dependencies + TypeScript compiler ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---- runtime stage: only production deps + compiled JS ----
FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
COPY migrations ./migrations
# Don't run as root. Numeric UID (1000 = the image's `node` user) so
# Kubernetes' runAsNonRoot check can verify it.
USER 1000
EXPOSE 3000
CMD ["node", "dist/index.js"]
# TODO(stage 1): compare image size with a single-stage build (`docker images`)
# and note the difference in docs/decisions.md.
