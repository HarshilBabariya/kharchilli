import { APP_VERSION, installSteps, platforms, REPO_URL } from '../content.js'
import DownloadButton from './DownloadButton.jsx'
import { useReveal } from '../hooks/useReveal.js'

export default function Downloads() {
  const ref = useReveal('.build, .step')
  return (
    <section className="section download" id="download" ref={ref}>
      <div className="section-head">
        <span className="eyebrow">Get Gharcha {APP_VERSION}</span>
        <h2>One app, every phone.</h2>
        <p>Free, no ads, no account. Android installs from this page today; the Play Store and App Store listings are on their way.</p>
      </div>
      <div className="builds">
        {platforms.map((p) => (
          <article className={`build ${p.live ? 'build-live' : ''}`} key={p.key}>
            {!p.live && <span className="ribbon">Coming soon</span>}
            <h3>{p.title}</h3>
            <p>{p.tagline}</p>
            <ul>{p.rows.map((r) => <li key={r}>{r}</li>)}</ul>
            {p.live && (p.url ? <a className="btn btn-primary" href={p.url} target="_blank" rel="noreferrer">{p.cta}</a> : <DownloadButton />)}
          </article>
        ))}
      </div>
      <ol className="steps">
        {installSteps.map(([t, body], i) => (
          <li className="step" key={t}><span>{i + 1}</span><div><h4>{t}</h4><p>{body}</p></div></li>
        ))}
      </ol>
      <p className="download-foot">
        Built by GitHub Actions from the <a href={REPO_URL} target="_blank" rel="noreferrer">source</a> on every push; the button always serves the build this page was published with.
      </p>
    </section>
  )
}
