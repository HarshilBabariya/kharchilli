import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import { CopyProvider, useCopy } from './i18n.jsx'
import './styles.css'

// Keyed by language, so a switch rebuilds the page and every scroll scene measures the new text.
function Page() {
  const { lang } = useCopy()
  return <App key={lang} />
}

createRoot(document.getElementById('root')).render(<CopyProvider><Page /></CopyProvider>)
