export const REPO_URL = `https://github.com/${__REPO__}`
export const APP_VERSION = __APP_VERSION__

export const download = { file: 'Gharcha.apk', url: `${import.meta.env.BASE_URL}downloads/Gharcha.apk` }

export const stats = [
  { value: 33, label: 'badges to earn' },
  { value: 6130, label: 'bonus points on offer' },
  { value: 16, label: 'themes, 9 of them festive' },
  { value: 18, label: 'avatar outfits' }
]

export const features = [
  {
    key: 'log',
    title: 'Log in seconds',
    body: 'Centre + button, amount hero, Yesterday / Today / Tomorrow chips, inline Paid by and Cash · UPI · Card · Bank tiles. Credits (cashback, refunds) subtract from every total.'
  },
  {
    key: 'voice',
    title: 'Say it out loud',
    body: '“250 groceries by UPI” or “paid 120 for pani puri cash” — amount, category, mode and note are filled for you, in English, Hindi or Gujarati.'
  },
  {
    key: 'budgets',
    title: 'Budgets & forecast',
    body: 'Monthly and per-category limits, 80% / 100% alerts, and a plain-words forecast: “At this pace you’ll overspend by ₹4,200 around 24 Nov”.'
  },
  {
    key: 'groups',
    title: 'Groups & splitting',
    body: 'Home, trip, party — split equally or with custom amounts, see who owes whom, settle up with a minimal plan and share the summary to WhatsApp.'
  },
  {
    key: 'family',
    title: 'Family accounts',
    body: 'Every member has a profile, mobile number, optional PIN and their own avatar. App lock keeps the ledger private; everyone shares one household ledger.'
  },
  {
    key: 'insights',
    title: 'Insights & calendar',
    body: 'Week / Month / Year trends, category donut with ▲▼ change, payment-mode split, who paid, and a calendar that colours each day green or red against your daily budget.'
  },
  {
    key: 'khata',
    title: 'Kirana khata & services',
    body: 'Shop credit tallies, milk / maid / newspaper month grids with the maths spelt out, gold and chit funds valued at today’s rate.'
  },
  {
    key: 'reminders',
    title: 'Reminders & bills',
    body: 'A 30-day strip of what’s due, sassy nudges that never repeat themselves, and bills that log themselves on the due date. Tap a notification and it opens the right screen.'
  },
  {
    key: 'rewards',
    title: 'Points, levels & badges',
    body: '+10 per expense, streak bonuses, 10 levels from Rookie to Legend and 33 badges with full-screen celebrations and a cash-register ka-ching.'
  },
  {
    key: 'avatar',
    title: 'Your avatar',
    body: '16 hairstyles, 18 outfits, 13 accessories, 10 moods that react to your budget and streak, and seven actions — wave, jump, spin, dance, wink, cheer, laugh.'
  },
  {
    key: 'sounds',
    title: 'Sounds of a home',
    body: 'A cooker seeti for the daily nudge, a doorbell for bills, a debit ting for money out, microwave beeps at 80% of a budget, and a POS buzz when you cross it.'
  },
  {
    key: 'data',
    title: 'Local-first, yours',
    body: 'No account, no server, no tracking. Everything lives in the phone’s own database. Import and export CSV, export a PDF, or erase it all in one tap.'
  },
  {
    key: 'share',
    title: 'Weekly share card',
    body: 'A 1080×1350 card in your theme colours — week total, ▲▼ vs last week, top three categories, who paid, streak and points — made for the family group.'
  },
  {
    key: 'categories',
    title: 'Categories your way',
    body: 'Add your own with one of 26 icons, 40 preset colours or a custom hue; recolour the built-in ones. Voice entry learns your custom names too.'
  },
  {
    key: 'languages',
    title: 'English · हिन्दी · ગુજરાતી',
    body: 'Switch from onboarding or Me → Language. Dates, badges, rewards, mood lines and every notification follow — and the Polyglot badge lands when you do.'
  }
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
    rows: ['Listing in review', 'Signed release bundle is built on every push'],
    live: false
  },
  {
    key: 'ios',
    title: 'iPhone',
    tagline: 'One codebase, so iOS gets every feature on day one.',
    rows: ['App Store listing in preparation', 'iOS 13 and newer'],
    live: false
  }
]

export const installSteps = [
  ['Download', 'Tap Download for Android. The APK is the build this page was published with, so it is always the latest one that passed.'],
  ['Allow the install', 'Open the file; Android asks once to allow installs from your browser or file manager. Later builds install over it and keep your data.'],
  ['Set up', 'Pick a language, your name and mobile, a currency and an optional budget. A daily 8:30 PM nudge is ready for you; App lock is a switch on Me whenever you want it.'],
  ['Moving from HomeQuest?', 'Gharcha is a new app with its own id. Export a CSV from HomeQuest (Me → Your data) and import it in Gharcha (Me → Your data → Import CSV).']
]

export const languages = ['English', 'हिन्दी', 'ગુજરાતી']
