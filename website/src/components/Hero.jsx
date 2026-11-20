import { useEffect, useRef } from 'react'
import Phone from './Phone.jsx'
import DownloadButton from './DownloadButton.jsx'
import { APP_VERSION, stats } from '../content.js'
import { useCopy } from '../i18n.jsx'
import { dotRipple, heroIntro, springy } from '../motion.js'

const dots = Array.from({ length: 120 }, (_, i) => <i key={i} />)

export default function Hero() {
  const ref = useRef(null)
  const { t } = useCopy()
  useEffect(() => {
    const art = ref.current.querySelector('.hero-art')
    const undo = [heroIntro(ref.current), dotRipple(art), springy(art)]
    return () => undo.forEach((stop) => stop())
  }, [])

  return (
    <section className="hero" id="top" ref={ref}>
      <div className="hero-inner">
        <div className="hero-copy">
          <span className="eyebrow pill">v{APP_VERSION} · {t.hero.free} · Android</span>
          <h1>{t.hero.title} <span className="underline"><span className="grad">{t.hero.accent}</span><svg viewBox="0 0 300 20" preserveAspectRatio="none" aria-hidden="true"><path d="M4 13 C 60 3, 120 20, 180 10 S 270 5, 296 11" /></svg></span></h1>
          <p className="lead">{t.hero.lead}</p>
          <div className="hero-cta">
            <DownloadButton />
            <a className="btn btn-text" href="#tour">{t.hero.see}</a>
          </div>
          <ul className="stats">
            {stats.map((value, i) => <li className="stat" key={i}><b data-value={value}>0</b><span>{t.hero.stats[i]}</span></li>)}
          </ul>
        </div>
        <div className="hero-art">
          <div className="dots" aria-hidden="true">{dots}</div>
          <Phone screen="home" />
          <div className="float widget">
            <div><small>{t.app.spentIn}</small><b>₹72,800</b><small>{t.app.safe} ₹62</small></div>
            <span>🎙</span><span>+</span>
          </div>
          <div className="float toast"><b>+10 ⭐</b><small>{t.hero.voice}</small></div>
          <div className="float streak"><b>🔥 {t.hero.streak}</b><small>{t.hero.safe}</small></div>
        </div>
      </div>
    </section>
  )
}
