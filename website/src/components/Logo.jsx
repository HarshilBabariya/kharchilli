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
      <g fill="none" stroke="#fff" strokeWidth="112" strokeLinecap="round" strokeLinejoin="round">
        <path d="M372 262V762" />
        <path d="M372 598C470 560 560 500 628 410" />
        <path d="M486 548C540 640 590 712 664 762" />
      </g>
      <circle cx="726" cy="296" r="58" fill="#FFC531" />
    </svg>
  )
}
