import { defineConfig } from 'vitepress'

const siteOrigin = 'https://glennso.dev'
const siteBase = '/piper/'
const siteDescription = 'Lifecycle-aware Flutter state management with automatic cleanup, explicit dependencies, and no code generation.'
const socialImageUrl = `${siteOrigin}${siteBase}og-image.png`

function pageUrl(relativePath: string) {
  const pagePath = relativePath
    .replace(/index\.md$/, '')
    .replace(/\.md$/, '')

  return new URL(`${siteBase}${pagePath}`, siteOrigin).toString()
}

export default defineConfig({
  title: 'Piper State',
  description: siteDescription,
  base: siteBase,
  lang: 'en-US',
  cleanUrls: true,
  lastUpdated: true,

  sitemap: {
    hostname: siteOrigin,
    transformItems: (items) => items.map((item) => {
      if (item.url.startsWith(siteBase)) {
        return item
      }

      const separator = item.url.startsWith('/') ? '' : '/'
      return { ...item, url: `${siteBase.slice(0, -1)}${separator}${item.url}` }
    })
  },

  head: [
    ['link', { rel: 'alternate', type: 'text/plain', href: '/piper/llms.txt', title: 'LLM Summary' }],
    ['link', { rel: 'alternate', type: 'text/plain', href: '/piper/llms-full.txt', title: 'LLM Full Reference' }],
    ['script', { type: 'application/ld+json' }, JSON.stringify({
      "@context": "https://schema.org",
      "@type": "SoftwareSourceCode",
      "name": "Piper",
      "description": "Flutter state management with lifecycle-aware ViewModels. Automatic cleanup, explicit dependencies, no boilerplate.",
      "codeRepository": "https://github.com/theGlenn/piper",
      "programmingLanguage": ["Dart", "Flutter"],
      "runtimePlatform": "Flutter",
      "license": "https://opensource.org/licenses/MIT",
      "author": {
        "@type": "Person",
        "name": "theGlenn"
      },
      "url": `${siteOrigin}${siteBase}`
    })],
    ['link', { rel: 'icon', href: '/piper/favicon.ico' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/piper/favicon-32x32.png' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/piper/favicon-16x16.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '180x180', href: '/piper/apple-touch-icon.png' }],
    ['meta', { name: 'theme-color', content: '#3c82f6' }],
    ['meta', { name: 'author', content: 'theGlenn' }],
    ['meta', { name: 'keywords', content: 'flutter, dart, state management, viewmodel, mvvm, architecture, piper' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:image', content: socialImageUrl }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],
    ['meta', { property: 'og:image:alt', content: 'Piper State — Flutter state management that cleans up after itself.' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:image', content: socialImageUrl }],
    ['meta', { name: 'twitter:image:alt', content: 'Piper State — Flutter state management that cleans up after itself.' }]
  ],

  transformHead: ({ pageData }) => {
    const canonicalUrl = pageUrl(pageData.relativePath)
    const title = pageData.title === 'Piper State'
      ? 'Piper State — Lifecycle-aware Flutter state management'
      : `${pageData.title} | Piper State`
    const description = pageData.description || siteDescription

    return [
      ['link', { rel: 'canonical', href: canonicalUrl }],
      ['meta', { property: 'og:title', content: title }],
      ['meta', { property: 'og:description', content: description }],
      ['meta', { property: 'og:url', content: canonicalUrl }],
      ['meta', { name: 'twitter:title', content: title }],
      ['meta', { name: 'twitter:description', content: description }]
    ]
  },

  themeConfig: {
    logo: '/logo.png',
    outline: [2, 3],

    search: {
      provider: 'local'
    },

    nav: [
      { text: 'Guide', link: '/guide/what-is-piper' },
      { text: 'Examples', link: '/examples/counter' }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
          items: [
            { text: 'What is Piper?', link: '/guide/what-is-piper' },
            { text: 'Getting Started', link: '/guide/getting-started' }
          ]
        },
        {
          text: 'Core Concepts',
          items: [
            { text: 'StateHolder', link: '/guide/state-holder' },
            { text: 'AsyncStateHolder', link: '/guide/async-state-holder' },
            { text: 'ViewModel', link: '/guide/view-model' },
            { text: 'Stream Bindings', link: '/guide/stream-bindings' },
            { text: 'Task', link: '/guide/task' }
          ]
        },
        {
          text: 'Flutter Integration',
          items: [
            { text: 'ViewModelScope', link: '/guide/view-model-scope' },
            { text: 'Building UI', link: '/guide/building-ui' },
            { text: 'Watch & Computed', link: '/guide/reactive' },
            { text: 'Dependency Injection', link: '/guide/dependency-injection' }
          ]
        },
        {
          text: 'Going Further',
          items: [
            { text: 'Testing', link: '/guide/testing' },
            { text: 'Comparison', link: '/guide/comparison' }
          ]
        }
      ],
      '/examples/': [
        {
          text: 'Examples',
          items: [
            { text: 'Counter', link: '/examples/counter' },
            { text: 'Authentication', link: '/examples/auth' },
            { text: 'Todo List', link: '/examples/todos' },
            { text: 'Search', link: '/examples/search' },
            { text: 'Form Validation', link: '/examples/form' },
            { text: 'Navigation', link: '/examples/navigation' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/theGlenn/piper' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025-present theGlenn'
    },

    editLink: {
      pattern: 'https://github.com/theGlenn/piper/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    }
  }
})
