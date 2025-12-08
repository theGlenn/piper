import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Piper',
  description: 'State management that gets out of your way',

  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32x32.png' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon-16x16.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' }]
  ],

  themeConfig: {
    logo: '/logo.png',
    outline: [2, 3],
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
      { icon: 'github', link: 'https://github.com/theglenn/piper' }
    ]
  }
})
