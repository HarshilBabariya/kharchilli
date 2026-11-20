import { useCopy } from '../i18n.jsx'

const tabs = ['🏠', '🧾', '👥', '🙂']
const shortcuts = [['🔔', '#FF7043'], ['🛒', '#43A047'], ['🎯', '#FFB300'], ['🤝', '#7C4DFF']]
const spends = [['🥛', '#7CC4FF', '₹77'], ['🍴', '#FF7043', '₹188'], ['⛽', '#039BE5', '₹310']]
const categories = [['🍴', '#FF7043'], ['🛒', '#43A047'], ['🚕', '#039BE5'], ['💡', '#FFB300']]
const legend = [['#FF7043', '27%'], ['#7C4DFF', '16%'], ['#039BE5', '12%'], ['#43A047', '9%']]

function Tile({ emoji, color, size = 34 }) {
  return <span className="tile" style={{ '--c': color, '--s': `${size}px` }}>{emoji}</span>
}

function Home({ app }) {
  const tab = (i) => <span key={i} className={i === 0 ? 'on' : ''}>{tabs[i]}<small>{app.tabs[i]}</small></span>
  return (
    <>
      <div className="ph-body ph-tabbed">
        <div className="ph-head">
          <span className="ph-avatar">🙂</span>
          <div className="ph-hello"><small>{app.greeting}</small><b>{app.me}</b></div>
          <span className="ph-coins">⭐ 57</span>
          <span className="ph-mic">🎙</span>
        </div>
        <div className="ph-hero">
          <div>
            <small>{app.spentIn}</small>
            <b>₹72,800</b>
            <span className="ph-left">{app.left}</span>
          </div>
          <span className="ph-ring">97%</span>
          <i className="ph-level"><i /></i>
        </div>
        <div className="ph-access">
          <div className="ph-title"><b>{app.quick}</b><span>{app.edit}</span></div>
          <div className="ph-quick">
            {shortcuts.map(([emoji, color], i) => <div key={emoji}><Tile emoji={emoji} color={color} size={42} /><small>{app.shortcuts[i]}</small></div>)}
          </div>
        </div>
        <div className="ph-stats">
          <div className="ph-card"><Tile emoji="🛡" color="#22A861" size={28} /><small>{app.safe}</small><b>₹62</b></div>
          <div className="ph-card"><Tile emoji="☀️" color="#FF9F1C" size={28} /><small>{app.today}</small><b>₹132</b></div>
        </div>
        <div className="ph-recent">
          <div className="ph-title"><b>{app.recent}</b><span>{app.seeAll}</span></div>
          {spends.map(([emoji, color, amount], i) => (
            <div className="ph-card ph-row" key={emoji}><Tile emoji={emoji} color={color} /><div><b>{app.spends[i][0]}</b><small>{app.spends[i][1]}</small></div><b>{amount}</b></div>
          ))}
        </div>
      </div>
      <div className="ph-nav">{tab(0)}{tab(1)}<span className="plus">+</span>{tab(2)}{tab(3)}</div>
    </>
  )
}

function Add({ app }) {
  return (
    <div className="ph-body">
      <div className="ph-bar"><span>✕</span><b>{app.add}</b></div>
      <div className="ph-card ph-voice"><span className="ph-mic">🎙</span><div><b>{app.voiceTitle}</b><small>{app.voiceHint}</small></div></div>
      <div className="ph-amount">₹380</div>
      <div className="ph-field"><small>{app.titleLabel}</small><b>{app.item}</b></div>
      <div className="ph-chips">{app.usuals.map((usual) => <span key={usual}>{usual}</span>)}</div>
      <div className="ph-cats">
        {categories.map(([emoji, color], i) => <div key={emoji} className={i === 0 ? 'on' : ''}><Tile emoji={emoji} color={color} size={36} /><small>{app.categories[i]}</small></div>)}
      </div>
      <div className="ph-seg">{app.modes.map((mode, i) => <span key={mode} className={i === 1 ? 'on' : ''}>{mode}</span>)}</div>
      <div className="ph-save">✓ {app.save}</div>
    </div>
  )
}

function Insights({ app }) {
  return (
    <div className="ph-body">
      <div className="ph-bar"><span>←</span><b>{app.insights}</b></div>
      <div className="ph-seg">{app.periods.map((period, i) => <span key={period} className={i === 1 ? 'on' : ''}>{period}</span>)}</div>
      <div className="ph-card ph-donut">
        <i><b>₹72,800</b></i>
        <ul>
          {legend.map(([color, share], i) => <li key={color}><span style={{ background: color }} />{app.legend[i]}<b>{share}</b></li>)}
        </ul>
      </div>
      <div className="ph-card">
        <small>{app.last7}</small>
        <div className="ph-bars">{[38, 62, 30, 80, 54, 92, 46].map((h, i) => <i key={i} style={{ height: `${h}%` }} />)}</div>
      </div>
      <div className="ph-stats">
        <div className="ph-card"><Tile emoji="🛡" color="#22A861" size={28} /><small>{app.safe}</small><b>₹62</b></div>
        <div className="ph-card"><Tile emoji="📅" color="#FF7043" size={28} /><small>{app.billsDue}</small><b>{app.billsCount}</b></div>
      </div>
      <div className="ph-card">
        <small>{app.whoPaid}</small>
        <div className="ph-who"><i style={{ width: '86%' }} /><i style={{ width: '14%' }} /></div>
        <div className="ph-goal"><b>{app.me} 86%</b><small>{app.other} 14%</small></div>
      </div>
    </div>
  )
}

function House({ app }) {
  return (
    <div className="ph-body">
      <div className="ph-bar"><span>←</span><b>{app.house}</b></div>
      <div className="ph-card ph-row"><Tile emoji="🏡" color="#7C4DFF" /><div><b>{app.group}</b><small>{app.members}</small></div><span className="ph-ok">{app.settled} ✓</span></div>
      <div className="ph-card ph-shop">
        <small>{app.shopping}</small>
        <ul className="ph-list">
          <li className="done">{app.toBuy[0]}</li>
          <li>{app.toBuy[1]}<span className="ph-count"><i>−</i>2<i>+</i></span></li>
          <li>{app.toBuy[2]}<span className="ph-count"><i>−</i>1<i>+</i></span></li>
        </ul>
      </div>
      <div className="ph-dues">
        <div className="ph-card ph-row"><Tile emoji="↗" color="#22A861" /><div><b>{app.friend}</b><small>{app.lent}</small></div><b>₹3,000</b></div>
        <div className="ph-card ph-row"><Tile emoji="📄" color="#FB8C00" /><div><b>PUC</b><small>{app.expires}</small></div><span className="ph-warn">{app.daysLeft}</span></div>
      </div>
      <div className="ph-card ph-saving">
        <div className="ph-goal"><b>{app.goal}</b><small>{app.goalSaved}</small></div>
        <i className="ph-level dark"><i style={{ width: '42%' }} /></i>
      </div>
      <div className="ph-card ph-row"><Tile emoji="🥛" color="#7CC4FF" /><div><b>{app.milk}</b><small>{app.milkTally}</small></div><b>₹1,540</b></div>
    </div>
  )
}

const screens = { home: Home, add: Add, insights: Insights, house: House }

/** One drawn app screen, without a frame, in the page's language. */
export function Screen({ name }) {
  const Drawn = screens[name]
  return <Drawn app={useCopy().t.app} />
}

export default function Phone({ screen }) {
  return (
    <div className="phone" aria-hidden="true">
      <div className="phone-screen"><Screen name={screen} /></div>
    </div>
  )
}
