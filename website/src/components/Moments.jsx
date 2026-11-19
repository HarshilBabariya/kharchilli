import Phone from './Phone.jsx'
import { moments } from '../content.js'
import { useReveal } from '../hooks/useReveal.js'

export default function Moments() {
  const ref = useReveal('.moment')
  return (
    <section className="section" id="moments" ref={ref}>
      {moments.map((m) => (
        <article className="moment" key={m.key}>
          <div className="moment-art"><Phone screen={m.screen} /></div>
          <div className="moment-copy">
            <span className="eyebrow">{m.eyebrow}</span>
            <h2>{m.title}</h2>
            <p>{m.body}</p>
            <ul>
              {m.bullets.map(([title, body]) => <li key={title}><b>{title}</b><span>{body}</span></li>)}
            </ul>
          </div>
        </article>
      ))}
    </section>
  )
}
