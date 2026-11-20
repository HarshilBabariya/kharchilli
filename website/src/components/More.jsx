import { more } from '../content.js'
import { useCopy } from '../i18n.jsx'
import { useReveal } from '../hooks/useReveal.js'

export default function More() {
  const ref = useReveal('.more-item, .trust-item', { delay: (el, i) => 30 * i })
  const { t } = useCopy()
  return (
    <section className="section" id="features" ref={ref}>
      <div className="section-head">
        <span className="eyebrow">{t.more.eyebrow}</span>
        <h2>{t.more.title}</h2>
        <p>{t.more.lead}</p>
      </div>
      <div className="more-grid">
        {more.map((key) => (
          <article className="more-item" key={key} data-tilt>
            <img src={`${import.meta.env.BASE_URL}art/feature_${key}.png`} alt="" loading="lazy" />
            <div><h3>{t.more.items[key][0]}</h3><p>{t.more.items[key][1]}</p></div>
          </article>
        ))}
      </div>
      <ul className="trust">
        {t.more.trust.map(([title, body]) => <li className="trust-item" key={title}><b>{title}</b><span>{body}</span></li>)}
      </ul>
    </section>
  )
}
