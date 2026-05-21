ARG NODE_IMAGE=node:22-alpine3.22

FROM ${NODE_IMAGE} AS builder
WORKDIR /app

RUN npm install -g pnpm@9.12.0

COPY package.json pnpm-workspace.yaml pnpm-lock.yaml tsconfig.base.json ./
COPY apps/web/package.json ./apps/web/package.json

RUN pnpm install --filter @the-forge/web... --frozen-lockfile

COPY apps/web ./apps/web

RUN pnpm --filter @the-forge/web build

FROM ${NODE_IMAGE} AS runner
WORKDIR /app

RUN apk upgrade --no-cache

ENV NODE_ENV=production

COPY --from=builder /app/apps/web/.next ./apps/web/.next
COPY --from=builder /app/apps/web/public ./apps/web/public
COPY --from=builder /app/apps/web/package.json ./apps/web/package.json
COPY --from=builder /app/apps/web/node_modules ./apps/web/node_modules
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000

CMD ["node", "apps/web/node_modules/next/dist/bin/next", "start", "apps/web", "-p", "3000"]
