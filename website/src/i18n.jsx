import { createContext, useContext, useEffect, useState } from 'react'
import en from './i18n/en.json'
import hi from './i18n/hi.json'
import gu from './i18n/gu.json'

const copy = { en, hi, gu }
const stored = 'gharcha-lang'

// Code, the short label on the switch, and the full name read out for it.
export const languages = [['en', 'EN', 'English'], ['hi', 'हिं', 'हिन्दी'], ['gu', 'ગુ', 'ગુજરાતી']]

function remembered() {
  try { return localStorage.getItem(stored) } catch { return null }
}

// A link can ask for a language (?lang=hi); otherwise the last choice, then the browser's language, then English.
function firstLanguage() {
  const wanted = new URLSearchParams(window.location.search).get('lang') ?? remembered() ?? navigator.language.slice(0, 2)
  return copy[wanted] ? wanted : 'en'
}

const Copy = createContext({ lang: 'en', t: en, setLang: () => {} })

export function CopyProvider({ children }) {
  const [lang, setLang] = useState(firstLanguage)
  useEffect(() => {
    document.documentElement.lang = lang
    document.title = copy[lang].meta.title
    try { localStorage.setItem(stored, lang) } catch { /* storage is blocked: the choice lasts for this visit */ }
  }, [lang])
  return <Copy.Provider value={{ lang, t: copy[lang], setLang }}>{children}</Copy.Provider>
}

export const useCopy = () => useContext(Copy)
