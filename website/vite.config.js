import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'

const pubspec = readFileSync(new URL('../pubspec.yaml', import.meta.url), 'utf8')
const version = pubspec.match(/^version: ([^+\s]+)/m)[1]
const repo = process.env.GITHUB_REPOSITORY ?? 'HarshilBabariya/housequest'
const [owner, name] = repo.split('/')
const downloads = new URL('./public/downloads/', import.meta.url)
const apk = (existsSync(downloads) ? readdirSync(downloads) : []).find((file) => file.endsWith('.apk'))
const megabytes = apk ? Math.round(statSync(new URL(apk, downloads)).size / 1048576) : 0

// Link previews (WhatsApp, Telegram, X) only follow full addresses, so index.html writes %SITE% where it needs one.
const site = `https://${owner.toLowerCase()}.github.io/${name}/`
const fullAddresses = { name: 'full-addresses', transformIndexHtml: (html) => html.replaceAll('%SITE%', site) }

export default defineConfig({
  base: `/${name}/`,
  plugins: [react(), fullAddresses],
  define: { __APP_VERSION__: JSON.stringify(version), __REPO__: JSON.stringify(repo), __APK__: JSON.stringify(apk ?? 'Gharcha.apk'), __APK_MB__: megabytes }
})
