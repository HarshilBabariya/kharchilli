import { APP_VERSION, platforms, REPO_URL, storeLinks } from '../content.js'
import DownloadButton from './DownloadButton.jsx'
import { useReveal } from '../hooks/useReveal.js'
import { useCopy } from '../i18n.jsx'

export default function Downloads() {
  const ref = useReveal('.build, .step')
  const { t: { download } } = useCopy()
  return (
    <section className="section download" id="download" ref={ref}>
      <div className="section-head">
        <span className="eyebrow">{download.eyebrow.replace('{version}', APP_VERSION)}</span>
        <h2>{download.title}</h2>
        <p>{download.lead}</p>
      </div>
      <div className="builds">
        {platforms.map((key) => {
          const words = download.platforms[key]
          const store = storeLinks[key]
          const live = key === 'android' || Boolean(store)
          const rows = key === 'android' ? words.rows : [store ? words.live : words.pending, ...words.rows]
          return (
            <article className={`build ${live ? 'build-live' : ''}`} key={key}>
              {!live && <span className="ribbon">{download.soon}</span>}
              <h3>{words.title}</h3>
              <p>{words.tagline}</p>
              <ul>{rows.map((row) => <li key={row}>{row}</li>)}</ul>
              {store && <a className="btn btn-primary" href={store} target="_blank" rel="noreferrer">{words.cta}</a>}
              {key === 'android' && <DownloadButton />}
            </article>
          )
        })}
      </div>
      <ol className="steps">
        {download.steps.map(([title, body], i) => (
          <li className="step" key={title}><span>{i + 1}</span><div><h4>{title}</h4><p>{body}</p></div></li>
        ))}
      </ol>
      <p className="download-foot">
        {download.foot[0]}<a href={REPO_URL} target="_blank" rel="noreferrer">{download.foot[1]}</a>{download.foot[2]}
      </p>
    </section>
  )
}
