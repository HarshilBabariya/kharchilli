import { useEffect, useRef } from 'react'
import { animate, stagger, utils } from 'animejs'
import { festivals } from '../content.js'
import { useCopy } from '../i18n.jsx'
import { reducedMotion, useReveal } from '../hooks/useReveal.js'

function Sparks() {
  const ref = useRef(null)
  useEffect(() => {
    if (reducedMotion()) return
    animate(ref.current.querySelectorAll('i'), {
      translateY: () => [utils.random(20, 80), utils.random(-160, -40)],
      translateX: () => utils.random(-30, 30),
      opacity: [{ to: 1 }, { to: 0 }],
      scale: () => utils.random(0.4, 1.3, 2),
      duration: () => utils.random(2400, 4200),
      delay: stagger(140),
      loop: true,
      ease: 'outSine'
    })
  }, [])
  return (
    <div className="sparks" ref={ref} aria-hidden="true">
      {Array.from({ length: 28 }, (_, i) => <i key={i} style={{ left: `${(i * 37) % 100}%`, background: ['#fbbf24', '#f97316', '#ec4899', '#38bdf8'][i % 4] }} />)}
    </div>
  )
}

export default function Festivals() {
  const ref = useReveal('.fest-card, .perk')
  const { t: { fest } } = useCopy()
  return (
    <section className="section fest" id="festivals" ref={ref}>
      <Sparks />
      <div className="section-head">
        <span className="eyebrow">{fest.eyebrow}</span>
        <h2>{fest.title}</h2>
        <p>{fest.lead}</p>
      </div>
      <ul className="perks">
        {fest.perks.map((p) => <li className="perk" key={p}><span>✦</span>{p}</li>)}
      </ul>
      <div className="fest-grid">
        {festivals.map(({ key, emoji, colors }) => (
          <article className="fest-card" key={key} style={{ '--a': colors[0], '--b': colors[2] }}>
            <span className="fest-emoji">{emoji}</span>
            <h3>{fest.items[key].name}</h3>
            <small>{fest.items[key].when}</small>
            <dl>
              <div><dt>{fest.labels.look}</dt><dd><i className="swatches">{colors.map((c) => <b key={c} style={{ background: c }} />)}</i>{fest.items[key].look}</dd></div>
              <div><dt>{fest.labels.outfit}</dt><dd>{fest.items[key].outfit}</dd></div>
              <div><dt>{fest.labels.celebration}</dt><dd>{fest.items[key].effect}</dd></div>
              <div><dt>{fest.labels.sound}</dt><dd>{fest.items[key].sound}</dd></div>
            </dl>
          </article>
        ))}
      </div>
    </section>
  )
}
