// Every animation on the page, as plain functions over DOM nodes; each returns its own clean-up.
import { animate, createDraggable, createSpring, createTimeline, onScroll, stagger, svg, utils } from 'animejs'

const still = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches

export function heroIntro(root) {
  const intro = createTimeline({ defaults: { ease: 'outExpo' } })
    .add(root.querySelectorAll('.hero-copy > *'), { opacity: [0, 1], translateY: [24, 0], duration: 900, delay: stagger(90) }, 150)
    .add(root.querySelector('.phone'), { opacity: [0, 1], translateY: [40, 0], duration: 1100 }, 250)
    .add(root.querySelectorAll('.float'), { opacity: [0, 1], scale: [0.7, 1], duration: 700, delay: stagger(140), ease: 'outBack(1.6)' }, '-=600')
    .add(svg.createDrawable(root.querySelector('.underline path')), { draw: ['0 0', '0 1'], duration: 900, ease: 'inOutQuad' }, 800)
  root.querySelectorAll('.stat b').forEach((el, i) => {
    const count = { n: 0 }
    animate(count, { n: Number(el.dataset.value), duration: 1600, delay: 700 + i * 120, ease: 'outExpo', modifier: utils.round(0), onUpdate: () => { el.textContent = count.n } })
  })
  return () => intro.cancel()
}

// A wave through the dot grid behind the phone: on its own every few seconds, and from wherever the art is pressed.
export function dotRipple(art) {
  const grid = art.querySelector('.dots')
  const dots = grid.querySelectorAll('i')
  const cols = Number(getComputedStyle(grid).getPropertyValue('--cols'))
  const rows = dots.length / cols
  const ripple = (from) => animate(dots, {
    scale: [{ to: 2.8, duration: 260 }, { to: 1, duration: 620 }],
    opacity: [{ to: 1, duration: 260 }, { to: 0.3, duration: 620 }],
    delay: stagger(38, { grid: [cols, rows], from }),
    ease: 'inOutQuad'
  })
  const press = (event) => {
    const box = grid.getBoundingClientRect()
    const col = utils.clamp(Math.floor((event.clientX - box.left) / box.width * cols), 0, cols - 1)
    const row = utils.clamp(Math.floor((event.clientY - box.top) / box.height * rows), 0, rows - 1)
    ripple(row * cols + col)
  }
  art.addEventListener('pointerdown', press)
  const beat = still() ? 0 : setInterval(() => ripple(utils.random(0, dots.length - 1)), 3600)
  return () => {
    art.removeEventListener('pointerdown', press)
    clearInterval(beat)
  }
}

// The floating cards can be pulled about and spring back to where they sit.
export function springy(art) {
  const pulls = [...art.querySelectorAll('.float')].map((card) => createDraggable(card, { container: [0, 0, 0, 0], releaseEase: createSpring({ stiffness: 120, damping: 6 }) }))
  return () => pulls.forEach((pull) => pull.revert())
}

// The pinned 3D phone. One timeline, scrubbed by the scroll position of the section; each step owns 1000 units.
// Just before a step begins the app inside the phone moves to its feature: the reel slides to another screen or the
// screen scrolls, and the spotlight ring travels to the part being explained. The phone itself only turns slowly, and
// where it is taller than the space it has, slides so that the ring stays in view.
export function tourScene(section, steps) {
  if (still()) {
    section.classList.add('tour-flat')
    return () => {}
  }
  const [art, rig, glass, reel, ring, head, track] = ['.tour-art', '.tour-rig', '.p3-glass', '.tour-reel', '.tour-ring', '.tour-head', '.tour-track'].map((part) => section.querySelector(part))
  const captions = section.querySelectorAll('.tour-step')
  const screens = [...section.querySelectorAll('.tour-screen')]
  const bodies = screens.map((screen) => screen.querySelector('.ph-body'))
  const travel = 400
  let scene
  let sized = []

  const build = () => {
    scene?.revert()
    sized = [window.innerWidth, window.innerHeight]
    const wide = window.innerWidth >= 900
    const k = wide ? Math.min(1.3, (window.innerHeight - 190) / rig.offsetHeight) : Math.min(1, (window.innerWidth - 64) / rig.offsetWidth)
    rig.style.setProperty('--k', k.toFixed(3))
    const slack = Math.max(0, (rig.offsetHeight * k - art.clientHeight) / 2 + 14)
    const stops = steps.map(([name, selector]) => {
      const index = screens.findIndex((screen) => screen.dataset.screen === name)
      const part = bodies[index].querySelector(selector)
      const view = glass.clientHeight - (screens[index].querySelector('.ph-nav')?.offsetHeight ?? 0)
      const scroll = utils.clamp(part.offsetTop - (view - part.offsetHeight) / 2, 0, Math.max(0, bodies[index].offsetHeight - view))
      const box = { x: part.offsetLeft - 5, y: part.offsetTop - scroll - 5, width: part.offsetWidth + 10, height: part.offsetHeight + 10 }
      const fromMiddle = glass.offsetTop + box.y + box.height / 2 - rig.offsetHeight / 2
      return { index, scroll, box, pan: utils.clamp(-fromMiddle * k, -slack, slack) / k }
    })
    const frame = (from, to, duration) => ({
      translateX: [from.x, to.x],
      translateY: [from.y, to.y],
      width: [`${from.width}px`, `${to.width}px`],
      height: [`${from.height}px`, `${to.height}px`],
      duration
    })
    bodies.forEach((body, index) => utils.set(body, { translateY: -(stops.find((stop) => stop.index === index)?.scroll ?? 0) }))
    utils.set(ring, { translateX: stops[0].box.x, translateY: stops[0].box.y, width: `${stops[0].box.width}px`, height: `${stops[0].box.height}px`, opacity: 1 })
    utils.set(rig, { translateY: stops[0].pan })

    scene = createTimeline({ defaults: { ease: 'inOutQuad' }, autoplay: onScroll({ target: section, enter: 'top top', leave: 'bottom bottom', sync: 0.5 }) })
      .add(rig, { rotateY: [-24, 18], rotateX: [9, 4], duration: 1000 * steps.length, ease: 'inOutSine' }, 0)
      .add(head, { left: ['0%', '100%'], duration: 1000 * steps.length, ease: 'linear' }, 0)
    stops.slice(1).forEach((stop, i) => {
      const before = stops[i]
      const at = 1000 * (i + 1) - travel + 40
      scene.add(rig, { translateY: [before.pan, stop.pan], duration: travel }, at)
      if (before.index === stop.index) {
        scene.add(bodies[stop.index], { translateY: [-before.scroll, -stop.scroll], duration: travel }, at).add(ring, frame(before.box, stop.box, travel), at)
      } else {
        scene
          .add(ring, { opacity: [1, 0], duration: 110, ease: 'linear' }, at)
          .add(reel, { translateX: [-before.index * glass.clientWidth, -stop.index * glass.clientWidth], duration: travel }, at)
          .add(ring, frame(before.box, stop.box, 60), at + 170)
          .add(ring, { opacity: [0, 1], duration: 130, ease: 'linear' }, at + travel - 130)
      }
    })
    captions.forEach((caption, i) => {
      if (i > 0) scene.add(caption, { opacity: [0, 1], translateY: [22, 0], duration: 200, ease: 'outQuad' }, 1000 * i + 40)
      if (i < captions.length - 1) scene.add(caption, { opacity: 0, translateY: -22, duration: 160, ease: 'inQuad' }, 1000 * (i + 1) - 160)
    })
    scene.init()
  }
  // A phone browser changes the window's height as its address bar hides; only a change the layout depends on rebuilds.
  const resize = () => {
    if (window.innerWidth !== sized[0] || (window.innerWidth >= 900 && window.innerHeight !== sized[1])) build()
  }
  const seek = (event) => {
    const box = track.getBoundingClientRect()
    const along = utils.clamp((event.clientX - box.left) / box.width, 0, 1)
    window.scrollTo({ top: section.offsetTop + along * (section.offsetHeight - window.innerHeight), behavior: 'smooth' })
  }

  build()
  let live = true
  document.fonts.ready.then(() => live && build())
  window.addEventListener('resize', resize)
  track.parentElement.addEventListener('click', seek)
  return () => {
    live = false
    window.removeEventListener('resize', resize)
    track.parentElement.removeEventListener('click', seek)
    scene.revert()
  }
}

// The share cards start as a fanned stack and deal out into a row as the section scrolls in.
export function fanCards(row) {
  const cards = row.querySelectorAll('.share-card')
  const middle = (cards.length - 1) / 2
  const deal = animate(cards, {
    translateX: { from: (card, i) => `${(middle - i) * 70}%`, to: '0%' },
    translateY: { from: 70, to: 0 },
    rotate: { from: (card, i) => (i - middle) * 7, to: 0 },
    opacity: { from: 0.5, to: 1 },
    ease: 'outQuad',
    autoplay: onScroll({ target: row, enter: 'bottom top', leave: 'center center', sync: 0.35 })
  })
  return () => deal.revert()
}

// Badges cascade smoothly into view on scroll and send a crisp, non-overlapping ripple when pressed.
export function badgeWall(wall) {
  if (!wall) return () => {}
  const tiles = [...wall.children]
  if (still()) return () => {}

  const grid = () => {
    const cols = Math.max(1, tiles.filter((tile) => tile.offsetTop === tiles[0].offsetTop).length)
    return [cols, Math.ceil(tiles.length / cols)]
  }

  let activeWave = null
  let activePop = null
  let poppedTile = null
  let popTimer = 0

  // Smooth staggered pop-in on first scroll reveal
  utils.set(tiles, { opacity: 0, translateY: 16, scale: 0.88 })
  const reveal = () => {
    activeWave?.cancel()
    activeWave = animate(tiles, {
      opacity: [0, 1],
      translateY: [16, 0],
      scale: [0.88, 1],
      duration: 540,
      delay: stagger(24, { grid: grid(), from: 'center' }),
      ease: 'outBack(1.3)'
    })
  }

  // Tactile, tight ripple on click without colliding tiles
  const wave = (from) => {
    activeWave?.cancel()
    activeWave = animate(tiles, {
      translateY: [{ to: -7, duration: 170, ease: 'outQuad' }, { to: 0, duration: 420, ease: 'outBack(1.4)' }],
      scale: [{ to: 1.07, duration: 170, ease: 'outQuad' }, { to: 1, duration: 420, ease: 'outBack(1.2)' }],
      delay: stagger(28, { grid: grid(), from })
    })
  }

  const press = (event) => {
    const tile = event.target.closest('.badge-tile')
    const index = tiles.indexOf(tile)
    if (index < 0) return
    wave(index)
    const img = tile.querySelector('img')
    if (img) {
      activePop?.cancel()
      activePop = animate(img, {
        scale: [{ to: 1.2, duration: 160, ease: 'outQuad' }, { to: 1, duration: 360, ease: 'outBack(1.8)' }],
        rotate: [{ to: -7, duration: 110 }, { to: 6, duration: 130 }, { to: 0, duration: 220 }],
        ease: 'outQuad'
      })
    }
    poppedTile?.classList.remove('is-popped')
    tile.classList.add('is-popped')
    poppedTile = tile
    clearTimeout(popTimer)
    popTimer = setTimeout(() => tile.classList.remove('is-popped'), 650)
  }

  wall.addEventListener('click', press)
  let revealed = false
  const seen = onScroll({
    target: wall,
    onEnter: () => {
      if (revealed) return
      revealed = true
      reveal()
    }
  })
  return () => {
    wall.removeEventListener('click', press)
    clearTimeout(popTimer)
    activeWave?.cancel()
    activePop?.cancel()
    seen.revert()
  }
}

// A day plays through on a loop: the line fills and each moment lights up as the playhead reaches it.
export function dayLoop(day) {
  if (still()) return () => {}
  const events = day.querySelectorAll('.day-event')
  const span = 1100 * events.length
  utils.set(events, { opacity: 0.28 })
  const loop = createTimeline({ loop: true, loopDelay: 1600, autoplay: onScroll({ target: day }) })
    .add(day.querySelector('.day-fill'), { scaleX: [0, 1], duration: span, ease: 'linear' }, 0)
    .add(events, { opacity: [0.28, 1], translateY: [12, 0], duration: 650, ease: 'outExpo', delay: stagger(span / events.length) }, 0)
    .add(day.querySelectorAll('.day-dot'), { scale: [{ to: 1.7, duration: 220 }, { to: 1, duration: 380 }], delay: stagger(span / events.length) }, 0)
  return () => loop.revert()
}
