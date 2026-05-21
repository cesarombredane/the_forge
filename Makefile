.PHONY: install dev build lint typecheck k8s-apply k8s-delete

install:
	corepack enable && pnpm install

dev:
	pnpm dev

build:
	pnpm build

lint:
	pnpm lint

typecheck:
	pnpm typecheck

k8s-apply:
	kubectl apply -k k8s/overlays/dev

k8s-delete:
	kubectl delete -k k8s/overlays/dev --ignore-not-found
