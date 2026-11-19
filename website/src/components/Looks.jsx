import { useState } from 'react'
import { cardLooks, themes } from '../content.js'
import { useReveal } from '../hooks/useReveal.js'

export default function Looks() {
  const ref = useReveal('.share-card')
  const [theme, setTheme] = useState(0)
  const pick = (index) => {
    setTheme(index)
    document.documentElement.style.setProperty('--p', themes[index][1])
    document.documentElement.style.setProperty('--p2', themes[index][2])
  }
  return (
    <section className="section" id="looks" ref={ref}>
      <div className="section-head">
        <span className="eyebrow">Make it yours</span>
        <h2>Pick a colour. The whole app follows.</h2>
        <p>Twenty-four themes in the app; try a few on this page. Then send the family a card in any of five styles.</p>
      </div>
      <div className="theme-row" role="group" aria-label="Themes">
        {themes.map(([name, a, b], i) => (
          <button type="button" key={name} className={i === theme ? 'on' : ''} onClick={() => pick(i)} aria-pressed={i === theme}>
            <i style={{ background: `linear-gradient(135deg, ${a}, ${b})` }} />{name}
          </button>
        ))}
      </div>
      <div className="share-row">
        {cardLooks.map((name, i) => (
          <figure className={`share-card look-${i}`} key={name}>
            <div className="sc-head"><b>Gharcha</b><span>Expense</span></div>
            <div className="sc-panel">
              <span className="tile" style={{ '--c': '#FF7043', '--s': '40px' }}>🍴</span>
              <b>Frankie</b>
              <strong>₹380</strong>
              <dl>
                <div><dt>Date</dt><dd>19 Nov 2026</dd></div>
                <div><dt>Paid by</dt><dd>Harshil</dd></div>
                <div><dt>Mode</dt><dd>UPI</dd></div>
              </dl>
            </div>
            <figcaption>{name}</figcaption>
          </figure>
        ))}
      </div>
    </section>
  )
}
