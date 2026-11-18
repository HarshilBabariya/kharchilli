export default function Logo({ size = 40, id = 'logo' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 1024 1024" aria-hidden="true">
      <defs>
        <linearGradient id={`${id}-bg`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#FF4D4D" />
          <stop offset=".55" stopColor="#E8203F" />
          <stop offset="1" stopColor="#B3124F" />
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" rx="236" fill={`url(#${id}-bg)`} />
      <path d="M512 236 L792 468 V716 Q792 788 720 788 H304 Q232 788 232 716 V468 Z" fill="#fff" stroke="#fff" strokeWidth="72" strokeLinejoin="round" />
      <g fill="none" stroke="#E8203F" strokeWidth="54" strokeLinecap="round" strokeLinejoin="round">
        <path d="M410 452 H614" />
        <path d="M410 540 H614" />
        <path d="M410 452 H486 Q576 452 576 540 Q576 628 486 628 H410 L560 760" />
      </g>
      <circle cx="770" cy="268" r="58" fill="#FFC531" />
    </svg>
  )
}
