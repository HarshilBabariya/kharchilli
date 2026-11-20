import { APP_VERSION, download, storeLinks } from '../content.js'
import { useCopy } from '../i18n.jsx'

const onIphone = typeof navigator !== 'undefined' && /iPhone|iPad|iPod/.test(navigator.userAgent)

export default function DownloadButton({ compact = false }) {
  const { t } = useCopy()
  const link = onIphone
    ? { href: storeLinks.ios || '#download', label: storeLinks.ios ? t.get.ios : t.get.iosSoon, short: storeLinks.ios ? t.get.short : t.get.soon, note: 'iOS' }
    : { href: download.url, download: download.file, label: t.get.android, short: t.get.short, note: `v${APP_VERSION} · ${download.megabytes ? `${download.megabytes} MB` : 'APK'}` }
  return (
    <a className={`btn btn-primary ${compact ? 'btn-compact' : 'btn-detail'}`} href={link.href} download={link.download} data-magnet>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M12 3v12m0 0 4-4m-4 4-4-4M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" />
      </svg>
      {compact ? <span>{link.short}</span> : <span><b>{link.label}</b><small>{link.note}</small></span>}
    </a>
  )
}
