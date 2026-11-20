import { useEffect, useRef } from 'react'
import { dayTimes } from '../content.js'
import { useCopy } from '../i18n.jsx'
import { dayLoop } from '../motion.js'

export default function Day() {
  const ref = useRef(null)
  const { t } = useCopy()
  useEffect(() => dayLoop(ref.current), [])
  return (
    <section className="section" id="day">
      <div className="section-head">
        <span className="eyebrow">{t.day.eyebrow}</span>
        <h2>{t.day.title}</h2>
        <p>{t.day.lead}</p>
      </div>
      <div className="day" ref={ref}>
        <i className="day-line"><i className="day-fill" /></i>
        {dayTimes.map((time, i) => (
          <article className="day-event" key={time}>
            <i className="day-dot" />
            <span className="mono">{time}</span>
            <h3>{t.day.events[i][0]}</h3>
            <p>{t.day.events[i][1]}</p>
          </article>
        ))}
      </div>
    </section>
  )
}
