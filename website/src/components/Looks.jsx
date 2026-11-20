import { useEffect, useRef, useState } from 'react'
import { themes } from '../content.js'
import { useCopy } from '../i18n.jsx'
import { fanCards } from '../motion.js'

export default function Looks() {
  const ref = useRef(null)
  useEffect(() => fanCards(ref.current), [])
  const { t } = useCopy()
  const [theme, setTheme] = useState(() => Math.max(0, themes.findIndex(([first]) => first === document.documentElement.style.getPropertyValue('--p'))))
  const pick = (index) => {
    setTheme(index)
    document.documentElement.style.setProperty('--p', themes[index][0])
    document.documentElement.style.setProperty('--p2', themes[index][1])
  }
  return (
    <section className="section" id="looks">
      <div className="section-head">
        <span className="eyebrow">{t.looks.eyebrow}</span>
        <h2>{t.looks.title}</h2>
        <p>{t.looks.lead}</p>
      </div>
      <div className="theme-row" role="group" aria-label={t.nav.looks}>
        {themes.map(([a, b], i) => (
          <button type="button" key={a} className={i === theme ? 'on' : ''} onClick={() => pick(i)} aria-pressed={i === theme}>
            <i style={{ background: `linear-gradient(135deg, ${a}, ${b})` }} />{t.looks.themes[i]}
          </button>
        ))}
      </div>
      <div className="share-row" ref={ref}>
        {t.looks.cards.map((name, i) => (
          <figure className={`share-card look-${i}`} key={name}>
            <div className="sc-head"><b>Gharcha</b><span>{t.app.expense}</span></div>
            <div className="sc-panel">
              <span className="tile" style={{ '--c': '#FF7043', '--s': '40px' }}>🍴</span>
              <b>{t.app.item}</b>
              <strong>₹380</strong>
              <dl>
                <div><dt>{t.app.date}</dt><dd>{t.app.day}</dd></div>
                <div><dt>{t.app.paidBy}</dt><dd>{t.app.me}</dd></div>
                <div><dt>{t.app.mode}</dt><dd>UPI</dd></div>
              </dl>
            </div>
            <figcaption>{name}</figcaption>
          </figure>
        ))}
      </div>
    </section>
  )
}
