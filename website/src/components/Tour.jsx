import { useEffect, useRef } from 'react'
import { Screen } from './Phone.jsx'
import { tour } from '../content.js'
import { useCopy } from '../i18n.jsx'
import { tourScene } from '../motion.js'

const screens = [...new Set(tour.map(([screen]) => screen))]
const slices = Array.from({ length: 7 }, (_, i) => <i className="p3-slice" key={i} style={{ '--z': `${i * 2 - 6}px` }} />)
const ticks = Array.from({ length: tour.length * 5 + 1 }, (_, i) => <i key={i} className={i % 5 === 0 ? 'major' : ''} />)

// A 3D phone pinned to the screen while the page scrolls. The app runs inside its display: scrolling moves through
// the screens, a spotlight lands on one feature at a time and the caption beside the phone explains it.
// The bar at the bottom shows where the scroll is and can be pressed to jump.
export default function Tour() {
  const ref = useRef(null)
  const { t } = useCopy()
  useEffect(() => tourScene(ref.current, tour), [])
  return (
    <section className="tour" id="tour" ref={ref} style={{ '--steps': tour.length }}>
      <div className="tour-stage">
        <div className="tour-copy">
          {tour.map(([screen], i) => (
            <article className="tour-step" key={i}>
              <span className="eyebrow mono">{String(i + 1).padStart(2, '0')} / {tour.length} · {t.tour.screens[screen]}</span>
              <h2>{t.tour.steps[i][0]}</h2>
              <p>{t.tour.steps[i][1]}</p>
            </article>
          ))}
        </div>
        <div className="tour-art" aria-hidden="true">
          <div className="tour-rig">
            {slices}
            <div className="p3-front">
              <div className="p3-glass">
                <div className="tour-reel">
                  {screens.map((name) => <div className="tour-screen" data-screen={name} key={name}><Screen name={name} /></div>)}
                </div>
                <i className="tour-ring" />
              </div>
            </div>
          </div>
        </div>
        <div className="tour-scrub">
          <div className="tour-track">{ticks}<b className="tour-head" /></div>
        </div>
      </div>
    </section>
  )
}
