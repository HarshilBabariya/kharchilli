import { download, storeLinks } from '../content.js'

const onIphone = typeof navigator !== 'undefined' && /iPhone|iPad|iPod/.test(navigator.userAgent)

export default function DownloadButton({ compact = false }) {
  const link = onIphone
    ? { href: storeLinks.ios || '#download', label: storeLinks.ios ? 'Download for iPhone' : 'iPhone app coming soon', short: storeLinks.ios ? 'Download' : 'Soon', note: 'iOS' }
    : { href: download.url, download: download.file, label: 'Download for Android', short: 'Download', note: '.apk' }
  return (
    <a className={`btn btn-primary ${compact ? 'btn-compact' : ''}`} href={link.href} download={link.download} data-magnet>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M12 3v12m0 0 4-4m-4 4-4-4M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" />
      </svg>
      <span>{compact ? link.short : link.label}</span>
      {!compact && <small>{link.note}</small>}
    </a>
  )
}
