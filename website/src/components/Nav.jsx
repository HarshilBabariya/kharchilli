import { useEffect, useRef, useState } from 'react'
import { animate, onScroll } from 'animejs'
import Logo from './Logo.jsx'
import DownloadButton from './DownloadButton.jsx'
import { REPO_URL } from '../content.js'
import { languages, useCopy } from '../i18n.jsx'

const sections = ['tour', 'features', 'looks', 'festivals', 'rewards', 'download']

export default function Nav() {
  const [solid, setSolid] = useState(false)
  const bar = useRef(null)
  const { lang, t, setLang } = useCopy()
  useEffect(() => {
    const onScrollY = () => setSolid(window.scrollY > 24)
    onScrollY()
    window.addEventListener('scroll', onScrollY, { passive: true })
    const progress = animate(bar.current, {
      scaleX: [0, 1],
      ease: 'linear',
      autoplay: onScroll({ target: document.body, enter: 'top top', leave: 'bottom bottom', sync: true })
    })
    return () => { window.removeEventListener('scroll', onScrollY); progress.revert() }
  }, [])
  return (
    <header className={`nav ${solid ? 'nav-solid' : ''}`}>
      <i className="scroll-progress" ref={bar} />
      <a className="brand" href="#top">
        <Logo size={34} />
        <span>Gharcha</span>
      </a>
      <nav className="nav-links">
        {sections.map((id) => <a key={id} href={`#${id}`}>{t.nav[id]}</a>)}
        <a href={REPO_URL} target="_blank" rel="noreferrer">GitHub</a>
      </nav>
      <div className="nav-end">
        <div className="lang" role="group" aria-label={t.nav.language}>
          {languages.map(([code, short, name]) => (
            <button type="button" key={code} lang={code} className={code === lang ? 'on' : ''} title={name} aria-label={name} aria-pressed={code === lang} onClick={() => setLang(code)}>{short}</button>
          ))}
        </div>
        <div className="nav-cta">
          <DownloadButton compact />
        </div>
      </div>
    </header>
  )
}
