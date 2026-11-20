import Logo from './Logo.jsx'
import { APP_VERSION, REPO_URL } from '../content.js'
import { useCopy } from '../i18n.jsx'

export default function Footer() {
  const { t: { footer } } = useCopy()
  return (
    <footer className="footer">
      <div className="footer-brand">
        <Logo size={28} id="footer-logo" />
        <span>Gharcha {APP_VERSION}</span>
      </div>
      <p>{footer.tagline}</p>
      <nav>
        <a href={`${import.meta.env.BASE_URL}privacy.html`}>{footer.privacy}</a>
        <a href={REPO_URL} target="_blank" rel="noreferrer">{footer.source}</a>
        <a href={`${REPO_URL}/issues`} target="_blank" rel="noreferrer">{footer.bug}</a>
        <a href={`${REPO_URL}/actions`} target="_blank" rel="noreferrer">{footer.builds}</a>
      </nav>
    </footer>
  )
}
