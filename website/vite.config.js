import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { existsSync, readdirSync, readFileSync } from 'node:fs'

const pubspec = readFileSync(new URL('../pubspec.yaml', import.meta.url), 'utf8')
const version = pubspec.match(/^version: ([^+\s]+)/m)[1]
const repo = process.env.GITHUB_REPOSITORY ?? 'HarshilBabariya/housequest'
const downloads = new URL('./public/downloads/', import.meta.url)
const apk = (existsSync(downloads) ? readdirSync(downloads) : []).find((file) => file.endsWith('.apk')) ?? 'Gharcha.apk'

export default defineConfig({
  base: `/${repo.split('/')[1]}/`,
  plugins: [react()],
  define: { __APP_VERSION__: JSON.stringify(version), __REPO__: JSON.stringify(repo), __APK__: JSON.stringify(apk) }
})
