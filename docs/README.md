# Documentation website

This folder contains the VitePress project for The Forge documentation. Run the
commands below from `docs/`. The Flutter application has a separate toolchain;
Node is needed only for this website.

## Prerequisites

- Node.js 22 or newer and npm
- A checkout of the whole repository, because the site also reads the root
  `README.md`, `ARCHITECTURE.md`, and `AGENTS.md`
- Network access for the initial dependency installation

## Install and run locally

From the repository root:

```bash
cd docs
npm ci
npm run dev
```

Open the local URL printed by VitePress, normally `http://127.0.0.1:5173`.
Edits to Markdown reload the site automatically. Stop the server with `Ctrl+C`.
Use `npm ci` for reproducible installation from `package-lock.json`; use
`npm install` when intentionally changing dependencies.

## Build and preview

```bash
npm run build
npm run preview
```

The build produces static files in `.vitepress/dist/`. Preview serves that build,
normally at `http://127.0.0.1:4173`; rebuild after editing to update preview.
Both commands print the actual address, which can change if a port is occupied.
To select a port explicitly, run `npm run dev -- --port 5174`.

The site is configured for serving at `/`. No deployment workflow is configured.
If hosting under a subdirectory later, configure VitePress `base` and verify
navigation and assets under that path before publishing.

## Where to edit

| Source | Website page |
| --- | --- |
| [Root README](../README.md) | Overview and app setup (`/`) |
| [Architecture](../ARCHITECTURE.md) | `/architecture.html` |
| [Agent procedure](../AGENTS.md) | `/agents.html` |
| [Development](development.md) | `/development.html` |
| [Database](database.md) | `/database.html` |
| [Behavior](behavior.md) | `/behavior.html` |
| This file | `/website.html` |

Markdown files remain the source of truth for both repository readers and the
website. There are no generated content copies to edit. `index.md`,
`architecture.md`, and `agents.md` include the corresponding root files through
VitePress Markdown includes. Keep those three wrapper files as includes only.
VitePress reads pages from `docs/`, excludes dependencies, and maps this internal
README to `/website.html`.

Use links relative to the Markdown source file. The Markdown renderer translates
documentation links to website routes and source-code links to the repository's
`main` branch on GitHub. Those external source links require access to GitHub and
show committed code, not local edits. Keep heading anchors in links where useful.
VitePress's broken-page-link check remains enabled.

Add additional guides as `docs/<name>.md`, and add their navigation entry in
`.vitepress/config.mjs`. New guides receive `/<name>.html` routes automatically.
Change colors in `.vitepress/theme/custom.css`. Mermaid fenced code blocks render
as diagrams, and built-in local search indexes documentation without a hosted
search service. Search, fonts, and diagram assets are bundled with the site.

## Validation and dependencies

After website changes, run `npm run build`, then check navigation, search, and
diagrams in the preview. From the repository root, also run the required
`flutter analyze`. There is currently no automated application test suite.

This project uses stable VitePress 1.6.4 and `vitepress-plugin-mermaid` 2.0.17,
whose peer range supports VitePress 1. Mermaid and Vue are explicit dependencies.
The lockfile records the resolved versions. VitePress 1's Vite/esbuild dependency
chain currently has npm audit advisories; `npm audit` can show their details.
The dev and preview servers bind to localhost. Review upstream compatibility
when updating dependencies rather than applying forced major-version overrides.

`node_modules/`, `.vitepress/cache/`, `.vitepress/dist/`, and `.vitepress/.temp/`
are ignored. The `.temp/` directory contains generated intermediate build files
and should not be committed. Commit decisions belong to the user; keep the
manifest and lockfile with the source.

Reference: [VitePress 1 documentation](https://vuejs.github.io/vitepress/v1/).
