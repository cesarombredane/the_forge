# The Forge

The Forge turns consistent sport effort into visible progression. This repository now contains the first implementation slice of a Kubernetes-first architecture for web development.

## Architecture

The stack is split into 3 containerized components:

1. `web`: Next.js (TypeScript) + MUI component library.
2. `api`: Express.js (TypeScript) + Drizzle ORM.
3. `db`: PostgreSQL 16 (StatefulSet with persistent volume).

Repository layout:

```
.
├── apps/
│   ├── api/
│   └── web/
├── k8s/
│   ├── base/
│   └── overlays/dev/
├── packages/
│   └── shared-types/
├── devspace.yaml
└── Makefile
```

## Tech Choices

1. Frontend: Next.js + MUI.
2. Backend: Express + Drizzle.
3. Database: PostgreSQL.
4. Orchestration: Kubernetes on Minikube.
5. Dev workflow: DevSpace.

## Prerequisites

Install the following on your machine:

1. Docker
2. Node.js 20+
3. pnpm 9+
4. kubectl
5. Minikube
6. DevSpace CLI

## Local Setup

1. Install dependencies:

```bash
make install
```

2. Enable script execution permissions:

```bash
chmod +x ./scripts/*.sh
```

3. Start Minikube and deploy:

```bash
./scripts/bootstrap-minikube.sh
```

4. Start live dev mode (port forwarding via DevSpace):

```bash
devspace dev
```

5. Open services:

1. Web: http://localhost:3000
2. API: http://localhost:3001/api/v1/health
2. Devspace: http://localhost:8090/logs/containers

## Useful Commands

```bash
make dev         # Run local monorepo dev scripts
make build       # Build all packages
make lint        # Lint workspaces
make typecheck   # Typecheck workspaces
make k8s-apply   # Apply k8s overlay manually
make k8s-delete  # Tear down k8s overlay
```

## Environment Variables

1. Frontend: `apps/web/.env.example`
2. API: `apps/api/.env.example`

For local non-k8s API execution, copy these into `.env.local` files and adjust values as needed.

## Current Status

This is an architecture baseline intended to accelerate feature development. It already includes:

1. Monorepo workspace setup.
2. Frontend app shell with MUI theming.
3. API service with health endpoint and activities read endpoint.
4. Drizzle schema + migration/seed scripts.
5. Dockerfiles for web and api.
6. Kubernetes manifests and DevSpace config for all 3 components.

## Next Implementation Steps

1. Add auth boundaries and user sessions.
2. Expand database model to goals/streaks/progression tables.
3. Add migration job/initContainer flow in API deployment.
4. Add CI for build, typecheck, lint, and manifest validation.
