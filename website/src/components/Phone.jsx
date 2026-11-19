const nav = [['🏠', 'Home'], ['🧾', 'Expenses'], ['+', ''], ['👥', 'Groups'], ['🙂', 'Me']]

function Tile({ emoji, color, size = 34 }) {
  return <span className="tile" style={{ '--c': color, '--s': `${size}px` }}>{emoji}</span>
}

function Home() {
  return (
    <>
      <div className="ph-head">
        <span className="ph-avatar">🙂</span>
        <div className="ph-hello"><small>Good evening,</small><b>Harshil</b></div>
        <span className="ph-coins">⭐ 57</span>
        <span className="ph-mic">🎙</span>
      </div>
      <div className="ph-hero">
        <div>
          <small>Spent in November</small>
          <b>₹72,800</b>
          <span className="ph-left">₹2,200 left of ₹75,000</span>
        </div>
        <span className="ph-ring">97%</span>
        <i className="ph-level"><i /></i>
      </div>
      <div className="ph-title"><b>Quick access</b><span>Edit</span></div>
      <div className="ph-quick">
        {[['🔔', '#FF7043', 'Bills'], ['🛒', '#43A047', 'Shopping'], ['🎯', '#FFB300', 'Goals'], ['🤝', '#7C4DFF', 'Lent']].map(([e, c, l]) => (
          <div key={l}><Tile emoji={e} color={c} size={42} /><small>{l}</small></div>
        ))}
      </div>
      <div className="ph-stats">
        <div className="ph-card"><Tile emoji="🛡" color="#22A861" size={28} /><small>Safe to spend today</small><b>₹62</b></div>
        <div className="ph-card"><Tile emoji="☀️" color="#FF9F1C" size={28} /><small>Today</small><b>₹132</b></div>
      </div>
    </>
  )
}

function Add() {
  return (
    <>
      <div className="ph-bar"><span>✕</span><b>Add expense</b></div>
      <div className="ph-card ph-voice"><span className="ph-mic">🎙</span><div><b>Say it or type it</b><small>“380 frankie by UPI”</small></div></div>
      <div className="ph-amount">₹380</div>
      <div className="ph-field"><small>Title</small><b>Frankie</b></div>
      <div className="ph-chips">
        {['Milk · ₹77', 'Petrol · ₹350', 'Rapido · ₹150'].map((c) => <span key={c}>{c}</span>)}
      </div>
      <div className="ph-cats">
        {[['🍴', '#FF7043', 'Dining', true], ['🛒', '#43A047', 'Groceries'], ['🚕', '#039BE5', 'Transport'], ['💡', '#FFB300', 'Bills']].map(([e, c, l, on]) => (
          <div key={l} className={on ? 'on' : ''}><Tile emoji={e} color={c} size={36} /><small>{l}</small></div>
        ))}
      </div>
      <div className="ph-seg">{['Cash', 'UPI', 'Card', 'Bank'].map((m) => <span key={m} className={m === 'UPI' ? 'on' : ''}>{m}</span>)}</div>
      <div className="ph-save">✓ Save</div>
    </>
  )
}

function Insights() {
  return (
    <>
      <div className="ph-bar"><span>←</span><b>Insights</b></div>
      <div className="ph-seg">{['Week', 'Month', 'Year'].map((m) => <span key={m} className={m === 'Month' ? 'on' : ''}>{m}</span>)}</div>
      <div className="ph-card ph-donut">
        <i><b>₹72,800</b></i>
        <ul>
          {[['#FF7043', 'Rent', '27%'], ['#7C4DFF', 'Savings', '16%'], ['#039BE5', 'Transport', '12%'], ['#43A047', 'Food', '9%']].map(([c, l, v]) => (
            <li key={l}><span style={{ background: c }} />{l}<b>{v}</b></li>
          ))}
        </ul>
      </div>
      <div className="ph-card">
        <small>Last 7 days</small>
        <div className="ph-bars">{[38, 62, 30, 80, 54, 92, 46].map((h, i) => <i key={i} style={{ height: `${h}%` }} />)}</div>
      </div>
      <div className="ph-stats">
        <div className="ph-card"><Tile emoji="🛡" color="#22A861" size={28} /><small>Safe to spend today</small><b>₹62</b></div>
        <div className="ph-card"><Tile emoji="📅" color="#FF7043" size={28} /><small>Bills due</small><b>3 this week</b></div>
      </div>
      <div className="ph-card">
        <small>Who paid</small>
        <div className="ph-who"><i style={{ width: '86%' }} /><i style={{ width: '14%' }} /></div>
        <div className="ph-goal"><b>Harshil 86%</b><small>Hitansi 14%</small></div>
      </div>
    </>
  )
}

function House() {
  return (
    <>
      <div className="ph-bar"><span>←</span><b>Our house</b></div>
      <div className="ph-card ph-row"><Tile emoji="🏡" color="#7C4DFF" /><div><b>Ghar</b><small>2 members</small></div><span className="ph-ok">Settled ✓</span></div>
      <div className="ph-card">
        <small>Shopping list</small>
        <ul className="ph-list">
          <li className="done">Atta 5 kg</li>
          <li>Tomatoes</li>
          <li>Detergent</li>
        </ul>
      </div>
      <div className="ph-card ph-row"><Tile emoji="↗" color="#22A861" /><div><b>Kenil</b><small>I lent · due in 4 days</small></div><b>₹3,000</b></div>
      <div className="ph-card ph-row"><Tile emoji="📄" color="#FB8C00" /><div><b>PUC</b><small>Expires 2 Dec 2026</small></div><span className="ph-warn">12 days left</span></div>
      <div className="ph-card ph-row"><Tile emoji="🥛" color="#7CC4FF" /><div><b>Milk</b><small>28 days · 1 litre a day</small></div><b>₹1,540</b></div>
      <div className="ph-card">
        <div className="ph-goal"><b>Goa trip</b><small>₹5,000 of ₹12,000</small></div>
        <i className="ph-level dark"><i style={{ width: '42%' }} /></i>
      </div>
    </>
  )
}

const screens = { home: Home, add: Add, insights: Insights, house: House }

export default function Phone({ screen }) {
  const Screen = screens[screen]
  return (
    <div className="phone" aria-hidden="true">
      <div className="phone-screen">
        <Screen />
        {screen === 'home' && (
          <div className="ph-nav">
            {nav.map(([icon, label], i) => <span key={i} className={icon === '+' ? 'plus' : i === 0 ? 'on' : ''}>{icon}{label && <small>{label}</small>}</span>)}
          </div>
        )}
      </div>
    </div>
  )
}
