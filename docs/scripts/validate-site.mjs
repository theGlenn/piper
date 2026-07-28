import { access, readFile } from 'node:fs/promises'
import { join } from 'node:path'

const dist = join(import.meta.dirname, '..', '.vitepress', 'dist')
const siteBase = 'https://glennso.dev/piper'
const siteDescription = 'Flutter state management that cleans up after itself. Plain Dart ViewModels with automatic rebuilds, stream cleanup, and cooperative task cancellation.'

async function read(relativePath) {
  return readFile(join(dist, relativePath), 'utf8')
}

function assertIncludes(content, expected, source) {
  if (!content.includes(expected)) {
    throw new Error(`${source} is missing: ${expected}`)
  }
}

const home = await read('index.html')
assertIncludes(home, '<title>Piper State', 'index.html')
assertIncludes(home, `rel="canonical" href="${siteBase}/"`, 'index.html')
assertIncludes(
  home,
  `property="og:description" content="${siteDescription}"`,
  'index.html',
)
assertIncludes(
  home,
  `property="og:image" content="${siteBase}/og-image.png"`,
  'index.html',
)

const gettingStarted = await read('guide/getting-started.html')
assertIncludes(
  gettingStarted,
  `rel="canonical" href="${siteBase}/guide/getting-started"`,
  'guide/getting-started.html',
)

const sitemap = await read('sitemap.xml')
const locations = [...sitemap.matchAll(/<loc>(.*?)<\/loc>/g)].map(
  ([, location]) => location,
)

if (locations.length === 0) {
  throw new Error('sitemap.xml does not contain any locations')
}

const invalidLocation = locations.find(
  (location) => !location.startsWith(`${siteBase}/`),
)

if (invalidLocation) {
  throw new Error(`sitemap.xml contains an invalid location: ${invalidLocation}`)
}

await access(join(dist, 'og-image.png'))

console.log(`Validated ${locations.length} sitemap URLs and social metadata.`)
