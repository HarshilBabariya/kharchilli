import { more, trust } from '../content.js'
import { useReveal } from '../hooks/useReveal.js'

export default function More() {
  const ref = useReveal('.more-item, .trust-item', { delay: (el, i) => 30 * i })
  return (
    <section className="section" id="features" ref={ref}>
      <div className="section-head">
        <span className="eyebrow">And the rest</span>
        <h2>Built for how a home really spends.</h2>
        <p>Not just “Food and Transport”: kirana credit, the milk tally, chit funds and the papers in the drawer.</p>
      </div>
      <div className="more-grid">
        {more.map((f) => (
          <article className="more-item" key={f.key} data-tilt>
            <img src={`${import.meta.env.BASE_URL}art/feature_${f.key}.png`} alt="" loading="lazy" />
            <div><h3>{f.title}</h3><p>{f.body}</p></div>
          </article>
        ))}
      </div>
      <ul className="trust">
        {trust.map(([title, body]) => <li className="trust-item" key={title}><b>{title}</b><span>{body}</span></li>)}
      </ul>
    </section>
  )
}
