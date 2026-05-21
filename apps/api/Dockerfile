FROM node:20-alpine AS builder
WORKDIR /app

RUN npm install -g pnpm@9.12.0

COPY package.json pnpm-workspace.yaml pnpm-lock.yaml tsconfig.base.json ./
COPY apps/api/package.json ./apps/api/package.json
COPY packages/shared-types/package.json ./packages/shared-types/package.json

RUN pnpm install --filter @the-forge/api... --frozen-lockfile

COPY apps/api ./apps/api
COPY packages/shared-types ./packages/shared-types

RUN pnpm --filter @the-forge/api build

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3001

COPY --from=builder /app/apps/api/dist ./apps/api/dist
COPY --from=builder /app/apps/api/package.json ./apps/api/package.json
COPY --from=builder /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3001

CMD ["node", "apps/api/dist/index.js"]

