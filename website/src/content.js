export const REPO_URL = `https://github.com/${__REPO__}`
export const APP_VERSION = __APP_VERSION__

// Paste the store pages here once they exist; a platform with a link goes live on the site, an empty one shows "Coming soon".
export const storeLinks = { play: '', ios: '' }
export const platforms = ['android', 'play', 'ios']

// megabytes is 0 when the site is built without the APK beside it.
export const download = { file: 'Gharcha.apk', url: `${import.meta.env.BASE_URL}downloads/${__APK__}`, megabytes: __APK_MB__ }

// Everything below is language-neutral. The words that go with it are in i18n/<language>.json, matched by position or by key.
export const stats = [33, 24, 35, 3]

// The scroll tour (components/Tour.jsx): the screen each step is on and the part of that screen the spotlight lands on.
export const tour = [
  ['home', '.ph-hero'],
  ['home', '.ph-access'],
  ['home', '.ph-stats'],
  ['home', '.ph-recent'],
  ['add', '.ph-voice'],
  ['add', '.ph-chips'],
  ['insights', '.ph-donut'],
  ['house', '.ph-shop'],
  ['house', '.ph-dues'],
  ['house', '.ph-saving']
]

// Each key picks art/feature_<key>.png.
export const more = ['widget', 'goals', 'shopping', 'accounts', 'budgets', 'groups', 'family', 'khata', 'reminders', 'rewards', 'avatar', 'sounds', 'categories', 'data', 'languages']

// A few of the app's themes; picking one recolours this page (--p and --p2 in styles.css).
export const themes = [
  ['#E8203F', '#FF7A59'], ['#2563EB', '#0EA5E9'], ['#15803D', '#22C55E'], ['#7C3AED', '#06B6D4'],
  ['#EC4899', '#A78BFA'], ['#F59E0B', '#EF4444'], ['#0E7490', '#10B981'], ['#334155', '#0EA5E9']
]

// One day, told in five moments (components/Day.jsx plays them on a loop).
export const dayTimes = ['07:40', '13:10', '18:30', '20:30', '21:00']

export const festivals = [
  { key: 'uttarayan', emoji: '🪁', colors: ['#0284C7', '#FACC15', '#EF4444'] },
  { key: 'tiranga', emoji: '🇮🇳', colors: ['#F26B0F', '#138808', '#1E3A8A'] },
  { key: 'holi', emoji: '🎨', colors: ['#E91E8C', '#FFC400', '#00B8D4'] },
  { key: 'rakhi', emoji: '🎀', colors: ['#DB2777', '#F59E0B', '#FB923C'] },
  { key: 'ganesh', emoji: '🌺', colors: ['#EA580C', '#DC2626', '#EAB308'] },
  { key: 'navratri', emoji: '💃', colors: ['#D9271C', '#FF9F1C', '#16A34A'] },
  { key: 'diwali', emoji: '🪔', colors: ['#B4231F', '#F5B301', '#FF7A1A'] },
  { key: 'christmas', emoji: '🎄', colors: ['#C62828', '#2E7D32', '#D4A017'] },
  { key: 'newyear', emoji: '🎆', colors: ['#7C3AED', '#F5C451', '#E879F9'] }
]

export const badges = [
  'badge_first_step', 'badge_ten_logged', 'badge_century', 'badge_half_k',
  'badge_week_warrior', 'badge_month_master', 'badge_streak_60', 'badge_streak_100',
  'badge_early_bird', 'badge_night_owl', 'badge_voice', 'badge_notes',
  'badge_explorer', 'badge_custom_cat', 'badge_payment_pro', 'badge_big_spender',
  'badge_penny', 'badge_team_player', 'badge_group_guru', 'badge_fair_share',
  'badge_settler', 'badge_family_first', 'badge_full_house', 'badge_bill_planner',
  'badge_budget_boss', 'badge_budget_hattrick', 'badge_stylist', 'badge_accessorized',
  'badge_new_look', 'badge_collector', 'badge_polyglot', 'badge_level_5',
  'badge_level_10'
]
