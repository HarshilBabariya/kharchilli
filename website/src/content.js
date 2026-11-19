export const REPO_URL = `https://github.com/${__REPO__}`
export const APP_VERSION = __APP_VERSION__

// Paste the store pages here once they exist; a platform with a link goes live on the site, an empty one shows "Coming soon".
export const storeLinks = { play: '', ios: '' }

export const download = { file: 'Gharcha.apk', url: `${import.meta.env.BASE_URL}downloads/${__APK__}` }

export const stats = [
  { value: 33, label: 'badges to earn' },
  { value: 24, label: 'colour themes' },
  { value: 35, label: 'avatar outfits' },
  { value: 3, label: 'languages' }
]

// The three things the page leads with; `screen` names a mock in components/Phone.jsx.
export const moments = [
  {
    key: 'log',
    screen: 'add',
    eyebrow: 'Log it',
    title: 'Five seconds, then back to your day.',
    body: 'Type it, say it, or paste the bank message. Gharcha fills in the rest.',
    bullets: [
      ['Say it', '“250 groceries by UPI” in English, Hindi or Gujarati.'],
      ['One-tap repeats', 'Your usual spends show up as chips under the title.'],
      ['It remembers', 'A shop keeps the category you gave it last time.']
    ]
  },
  {
    key: 'see',
    screen: 'insights',
    eyebrow: 'See it',
    title: 'Know what is safe to spend today.',
    body: 'One number for today, a clear picture of the month, and no surprise bills.',
    bullets: [
      ['Safe to spend', 'What is left of the budget, spread over the days remaining.'],
      ['Where it went', 'Categories, payment modes and who paid, by week, month or year.'],
      ['Bill calendar', 'Due days on a grid, with a heads-up three days early.']
    ]
  },
  {
    key: 'share',
    screen: 'house',
    eyebrow: 'Share it',
    title: 'One place for the whole house.',
    body: 'Splits, shop credit, the maid’s salary, the shopping list and the papers that expire.',
    bullets: [
      ['Split fairly', 'Equal, exact amounts, percentages or shares. Settle up in the fewest payments.'],
      ['Lent and borrowed', 'Who owes whom outside the groups, with a reminder card for WhatsApp.'],
      ['Nothing lapses', 'Warranties, insurance and PUC with a nudge a week before they expire.']
    ]
  }
]

// Everything else, as one-liners. `key` picks art/feature_<key>.png.
export const more = [
  { key: 'widget', title: 'Home-screen widget', body: 'This month and today, with Add and Voice buttons.' },
  { key: 'goals', title: 'Savings goals', body: 'A target, a date and what to put aside each month.' },
  { key: 'shopping', title: 'Shopping list', body: 'Tick things off, then log the lot as one expense.' },
  { key: 'accounts', title: 'Accounts', body: 'Cash, bank and wallets, each with a running balance.' },
  { key: 'budgets', title: 'Budgets & forecast', body: 'Limits per category and a plain-words forecast.' },
  { key: 'groups', title: 'Groups', body: 'Home, trips and parties, with who owes whom.' },
  { key: 'family', title: 'Family accounts', body: 'A profile, PIN and avatar for every member.' },
  { key: 'khata', title: 'Khata & home help', body: 'Shop credit, milk and maid tallies, gold and chits.' },
  { key: 'reminders', title: 'Reminders', body: 'Bills that log themselves and nudges that never repeat.' },
  { key: 'rewards', title: 'Points & badges', body: 'Ten levels, 33 badges and a shop to spend points in.' },
  { key: 'avatar', title: 'Your avatar', body: 'Full outfits, hair and accessories; moods that follow your budget.' },
  { key: 'sounds', title: 'Sounds of a home', body: 'A cooker whistle for nudges, a doorbell for bills.' },
  { key: 'categories', title: 'Your categories', body: 'Add your own, recolour the built-in ones.' },
  { key: 'data', title: 'Backup & lock', body: 'One-file backup, CSV and PDF export, PIN or fingerprint.' },
  { key: 'languages', title: 'English · हिन्दी · ગુજરાતી', body: 'Every screen, badge and notification follows.' }
]

// A few of the app's themes; picking one recolours this page (--p and --p2 in styles.css).
export const themes = [
  ['Sunrise', '#E8203F', '#FF7A59'],
  ['Ocean', '#2563EB', '#0EA5E9'],
  ['Forest', '#15803D', '#22C55E'],
  ['Midnight', '#7C3AED', '#06B6D4'],
  ['Candy', '#EC4899', '#A78BFA'],
  ['Mango', '#F59E0B', '#EF4444'],
  ['Peacock', '#0E7490', '#10B981'],
  ['Ink', '#334155', '#0EA5E9']
]

export const cardLooks = ['Classic', 'Sunset', 'Emerald', 'Night', 'Charcoal']

export const trust = [
  ['No account', 'Open it and start. Nothing to sign up for.'],
  ['No server', 'Everything stays in the phone’s own database.'],
  ['No ads, no tracking', 'Free, and nothing is collected.'],
  ['Yours to take', 'Back up to one file, export CSV or PDF, erase in one tap.']
]

export const festivals = [
  { key: 'uttarayan', emoji: '🪁', name: 'Uttarayan', when: '13–15 Jan', effect: 'Kites climb the screen with fluttering tails', sound: 'Kite flutter and whistles', outfit: 'Kite-flyer tee', look: { name: 'Kite Sky', c: ['#0284C7', '#FACC15', '#EF4444', '#0F2031'] } },
  { key: 'tiranga', emoji: '🇮🇳', name: 'Republic & Independence Day', when: '26 Jan · 15 Aug', effect: 'A shower of tricolour confetti', sound: 'Bugle fanfare', outfit: 'Tiranga jacket', look: { name: 'Tiranga', c: ['#F26B0F', '#138808', '#1E3A8A', '#181E1A'] } },
  { key: 'holi', emoji: '🎨', name: 'Holi', when: 'March', effect: 'Colour clouds burst across the screen with flying droplets', sound: 'Dhol, pichkari and a water-balloon splash', outfit: 'Holi white kurta + gulal face', look: { name: 'Holi Rang', c: ['#E91E8C', '#FFC400', '#00B8D4', '#2A1224'] } },
  { key: 'rakhi', emoji: '🎀', name: 'Raksha Bandhan', when: 'August', effect: 'Rose petals drift down the screen', sound: 'Temple bell and santoor plucks', outfit: 'Rakhi pastel kurta', look: { name: 'Rakhi Pastel', c: ['#DB2777', '#F59E0B', '#FB923C', '#2B1720'] } },
  { key: 'ganesh', emoji: '🌺', name: 'Ganesh Chaturthi', when: '10 days, Aug–Sep', effect: 'Marigold petals shower down the screen', sound: 'Dhol-tasha and bell', outfit: 'Bappa kurta', look: { name: 'Bappa Saffron', c: ['#EA580C', '#DC2626', '#EAB308', '#2B190C'] } },
  { key: 'navratri', emoji: '💃', name: 'Navratri', when: '9 nights, Sep–Oct', effect: 'Glowing colour lights fall like a garba night', sound: 'Garba dhol with dandiya clicks', outfit: 'Garba kediyu', look: { name: 'Garba Nights', c: ['#D9271C', '#FF9F1C', '#16A34A', '#291512'] } },
  { key: 'diwali', emoji: '🪔', name: 'Diwali', when: 'Dhanteras → Bhai Dooj', effect: 'Rockets climb and burst into rounds of fireworks', sound: 'Anaar, rocket and a string of firecrackers', outfit: 'Diwali silk kurta', look: { name: 'Diwali Glow', c: ['#B4231F', '#F5B301', '#FF7A1A', '#2A130C'] } },
  { key: 'christmas', emoji: '🎄', name: 'Christmas', when: '24–26 Dec', effect: 'Soft snowfall over the whole screen', sound: 'Sleigh bells and chimes', outfit: 'Santa suit + Santa hat', look: { name: 'Jingle Red', c: ['#C62828', '#2E7D32', '#D4A017', '#16201A'] } },
  { key: 'newyear', emoji: '🎆', name: 'New Year', when: '31 Dec – 1 Jan', effect: 'Rockets climb and burst into rounds of fireworks', sound: 'Countdown beeps, popper and party horn', outfit: 'Sequin party jacket + party hat', look: { name: 'New Year Gold', c: ['#7C3AED', '#F5C451', '#E879F9', '#17143A'] } }
]

export const festivalPerks = [
  'Themes and decorations switch on 3 days before the festival and stay for 3 days after',
  'A full-screen celebration on first open, with the festival’s own sound and your avatar already dressed up',
  'Tap the festival banner on Home any time to replay the celebration: fireworks, colour clouds, kites, tricolour confetti, petal showers or snow',
  'Claim my gifts: the pack, +50 points and the outfit — free during the window, yours for good',
  'A festival banner on Home with its own looping particle show and a countdown from a week before'
]

export const points = [
  ['+10', 'per expense logged'],
  ['+5', 'first log of the day'],
  ['+2 / day', 'streak bonus, up to +20'],
  ['+30', 'create a group'],
  ['+15', 'settle a balance'],
  ['+20', 'add a family member'],
  ['+100', 'finish a month under budget'],
  ['+50', 'claim a festival pack']
]

export const levels = ['Rookie', 'Saver', 'Planner', 'Tracker', 'Strategist', 'Accountant', 'Treasurer', 'Guardian', 'Master', 'Legend']

export const badges = [
  ['badge_first_step', 'First step'],
  ['badge_ten_logged', 'Getting serious'],
  ['badge_century', 'Century'],
  ['badge_half_k', 'Half a thousand'],
  ['badge_week_warrior', 'Week warrior'],
  ['badge_month_master', 'Month master'],
  ['badge_streak_60', 'Iron streak'],
  ['badge_streak_100', 'Legendary streak'],
  ['badge_early_bird', 'Early bird'],
  ['badge_night_owl', 'Night owl'],
  ['badge_voice', 'Say it out loud'],
  ['badge_notes', 'Note taker'],
  ['badge_explorer', 'Explorer'],
  ['badge_custom_cat', 'Make it yours'],
  ['badge_payment_pro', 'Payment pro'],
  ['badge_big_spender', 'Big spender'],
  ['badge_penny', 'Penny counter'],
  ['badge_team_player', 'Team player'],
  ['badge_group_guru', 'Group guru'],
  ['badge_fair_share', 'Fair share'],
  ['badge_settler', 'Settler'],
  ['badge_family_first', 'Family first'],
  ['badge_full_house', 'Full house'],
  ['badge_bill_planner', 'Bill planner'],
  ['badge_budget_boss', 'Budget boss'],
  ['badge_budget_hattrick', 'Budget hat-trick'],
  ['badge_stylist', 'Stylist'],
  ['badge_accessorized', 'Accessorized'],
  ['badge_new_look', 'New look'],
  ['badge_collector', 'Collector'],
  ['badge_polyglot', 'Polyglot'],
  ['badge_level_5', 'Rising star'],
  ['badge_level_10', 'Legend']
]

export const platforms = [
  {
    key: 'android',
    title: 'Android',
    tagline: 'Install the latest build straight from this page.',
    rows: ['Android 7 and newer', 'Every feature, no account, no ads', 'Updates install over the previous build and keep your data'],
    live: true
  },
  {
    key: 'play',
    title: 'Google Play',
    tagline: 'The same app, with automatic updates.',
    rows: [storeLinks.play ? 'Installs and updates through the Play Store' : 'Listing in preparation', 'Signed release bundle is built on every push'],
    url: storeLinks.play,
    cta: 'Get it on Google Play',
    live: Boolean(storeLinks.play)
  },
  {
    key: 'ios',
    title: 'iPhone',
    tagline: 'One codebase, so iOS gets every feature on day one.',
    rows: [storeLinks.ios ? 'Installs and updates through the App Store' : 'App Store listing in preparation', 'iOS 13 and newer'],
    url: storeLinks.ios,
    cta: 'Download on the App Store',
    live: Boolean(storeLinks.ios)
  }
]

export const installSteps = [
  ['Download', 'Tap Download for Android. The APK is the build this page was published with, so it is always the latest one that passed.'],
  ['Allow the install', 'Open the file; Android asks once to allow installs from your browser or file manager. Later builds install over it and keep your data.'],
  ['Set up', 'Pick a language, your name and mobile, a currency and an optional budget. A daily 8:30 PM nudge is ready for you; App lock is a switch on Me whenever you want it.'],
  ['Moving from HomeQuest?', 'Gharcha is a new app with its own id. Export a CSV from HomeQuest (Me → Your data) and import it in Gharcha (Me → Your data → Import CSV).']
]

export const languages = ['English', 'हिन्दी', 'ગુજરાતી']
