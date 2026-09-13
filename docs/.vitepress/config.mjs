import { statSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

const repositoryRoot = fileURLToPath(new URL('../../', import.meta.url))
const repositoryUrl = 'https://github.com/cesarombredane/the_forge'
const sourceRoutes = {
  'README.md': 'index.md',
  'ARCHITECTURE.md': 'architecture.md',
  'AGENTS.md': 'agents.md',
  'docs/README.md': 'website.md',
}
const includedSources = {
  'index.md': 'README.md',
  'architecture.md': 'ARCHITECTURE.md',
  'agents.md': 'AGENTS.md',
}

function pageRoute(source) {
  return sourceRoutes[source] ?? source.replace(/^docs\//, '')
}

const config = withMermaid(defineConfig({
  title: 'The Forge',
  description: 'Application documentation and contributor guides for The Forge.',
  lang: 'en-US',
  appearance: 'force-dark',
  srcExclude: ['**/node_modules/**'],
  rewrites: { 'README.md': 'website.md' },
  themeConfig: {
    siteTitle: 'THE FORGE',
    nav: [
      { text: 'Overview', link: '/' },
      { text: 'Architecture', link: '/architecture' },
      { text: 'Run this site', link: '/website' },
    ],
    sidebar: [
      {
        text: 'The application',
        items: [
          { text: 'Overview & setup', link: '/' },
          { text: 'Architecture', link: '/architecture' },
          { text: 'Behavior rules', link: '/behavior' },
          { text: 'Local database', link: '/database' },
        ],
      },
      {
        text: 'Contributing',
        items: [
          { text: 'Development workflow', link: '/development' },
          { text: 'Agent procedure', link: '/agents' },
          { text: 'Documentation website', link: '/website' },
        ],
      },
    ],
    search: { provider: 'local' },
    outline: { level: [2, 3] },
    socialLinks: [{ icon: 'github', link: repositoryUrl }],
    footer: { message: 'The Forge · Personal Android training companion' },
  },
  markdown: {
    config(md) {
      // Resolve links against the original file, before VitePress converts them
      // to website routes. Repository-relative links still work on GitHub.
      const renderLink = md.renderer.rules.link_open
      md.renderer.rules.link_open = (tokens, index, options, env, renderer) => {
        const token = tokens[index]
        const href = token.attrGet('href')
        if (href && !/^(?:[a-z][a-z\d+.-]*:|\/|#)/i.test(href)) {
          const [, target, suffix] = href.match(/^([^?#]*)(.*)$/)
          const page = env.realPath ?? env.path
          const included = includedSources[path.basename(page)]
          const original = included ? path.join(repositoryRoot, included) : page
          const source = path.relative(repositoryRoot,
            path.resolve(path.dirname(original), target)).split(path.sep).join('/')
          if (source.endsWith('.md')) {
            token.attrSet('href', `/${pageRoute(source)}${suffix}`)
          } else {
            const kind = statSync(path.join(repositoryRoot, source)).isDirectory()
              ? 'tree' : 'blob'
            token.attrSet('href', `${repositoryUrl}/${kind}/main/${source}${suffix}`)
          }
        }
        return renderLink(tokens, index, options, env, renderer)
      }
    },
  },
  mermaid: { theme: 'dark' },
  vite: {
    optimizeDeps: { include: ['mermaid', '@mermaid-js/mermaid-mindmap', 'fastdom'] },
    server: {
      host: '127.0.0.1',
      watch: { ignored: ['**/.vitepress/dist/**'] },
    },
  },
}))

// The plugin also lists debug for older Mermaid releases; Mermaid 11 no longer
// installs it. Do not ask Vite to prebundle a package that is not used.
config.vite.optimizeDeps.include = config.vite.optimizeDeps.include
  .filter((dependency) => dependency !== 'debug')

export default config
