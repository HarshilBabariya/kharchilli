import { useEffect, useRef } from 'react'
import { animate, createTimeline, stagger, utils } from 'animejs'
import Phone from './Phone.jsx'
import DownloadButton from './DownloadButton.jsx'
import { APP_VERSION, stats } from '../content.js'

export default function Hero() {
  const ref = useRef(null)
  useEffect(() => {
    const root = ref.current
    const tl = createTimeline({ defaults: { ease: 'outExpo' } })
    tl.add(root.querySelectorAll('.hero-copy > *'), { opacity: [0, 1], translateY: [24, 0], duration: 900, delay: stagger(90) }, 150)
      .add(root.querySelector('.phone'), { opacity: [0, 1], translateY: [40, 0], duration: 1100 }, 250)
      .add(root.querySelectorAll('.float'), { opacity: [0, 1], scale: [0.7, 1], duration: 700, delay: stagger(140), ease: 'outBack(1.6)' }, '-=600')
    root.querySelectorAll('.stat b').forEach((el, i) => {
      const count = { n: 0 }
      animate(count, { n: Number(el.dataset.value), duration: 1600, delay: 700 + i * 120, ease: 'outExpo', modifier: utils.round(0), onUpdate: () => { el.textContent = count.n } })
    })
    return () => tl.cancel()
  }, [])

  return (
    <section className="hero" id="top" ref={ref}>
      <div className="hero-inner">
        <div className="hero-copy">
          <span className="eyebrow pill">v{APP_VERSION} · Free · Android</span>
          <h1>Ghar ka kharcha, <span className="grad">sorted.</span></h1>
          <p className="lead">
            Log a spend in five seconds, see what is safe to spend today, and run the whole house from one app:
            splits, shop credit, bills, goals and the shopping list. No account. Nothing leaves your phone.
          </p>
          <div className="hero-cta">
            <DownloadButton />
            <a className="btn btn-text" href="#moments">See it in action ↓</a>
          </div>
          <ul className="stats">
            {stats.map((s) => <li className="stat" key={s.label}><b data-value={s.value}>0</b><span>{s.label}</span></li>)}
          </ul>
        </div>
        <div className="hero-art">
          <Phone screen="home" />
          <div className="float widget">
            <div><small>Spent in November</small><b>₹72,800</b><small>Safe to spend today ₹62</small></div>
            <span>🎙</span><span>+</span>
          </div>
          <div className="float toast"><b>+10 ⭐</b><small>Logged by voice</small></div>
          <div className="float streak"><b>🔥 12-day streak</b><small>Safe for today</small></div>
        </div>
      </div>
    </section>
  )
}
