---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with ultra-high design quality using SvelteKit + shadcn-svelte + Tailwind. Use this skill when the user asks to build web components, pages, landing pages, dashboards, applications, or when styling/beautifying any UI. Generates creative, polished SvelteKit code that avoids generic AI aesthetics and produces Champions-League-level visual output.
license: Complete terms in LICENSE.txt
---

This skill produces distinctive, production-grade frontend interfaces using SvelteKit + shadcn-svelte + Tailwind CSS that are visually extraordinary. No generic "AI slop". Every component fully styled, every detail intentional, every output memorable. Follow the user's global QWEN.md rules (UI Rules, Component Integrity, Complexity Detection) at all times.

Primary focus: websites, landing pages, dashboards, web applications, and desktop app UIs (Tauri). Everything is High Fidelity - no standard-looking output, no generic templates. Every UI must make people stop and stare.

Stack: SvelteKit + shadcn-svelte + Tailwind CSS (latest versions). No React, no Vue, no plain HTML/CSS. All code is .svelte components with TypeScript.

## Design Thinking

Before coding, commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this solve? Who uses it? What emotion should it evoke?
- **Tone**: Pick a clear direction - brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, dark-mode-cinematic, glass-layered-depth, swiss-precision. Commit fully.
- **Differentiation**: What makes this UNFORGETTABLE? What is the ONE visual moment someone will remember?
- **Signature element**: Every design needs one hero moment - an animation, a layout break, a color transition, a typographic statement that defines the entire interface.

**CRITICAL**: Intentionality over intensity. Bold maximalism and refined minimalism both work - but generic middle-ground does NOT. Pick a lane and execute with precision.

## Typography Mastery

Typography is the #1 differentiator between amateur and elite design:
- **Display fonts** (headings, hero text): Playfair Display, Clash Display, Satoshi, Cabinet Grotesk, General Sans, Instrument Serif, Plus Jakarta Sans, Space Mono (for code/tech), Fraunces, Outfit, Sora. Pick ONE per project and commit.
- **Body fonts**: Geist, Source Serif 4, Literata, Nunito Sans, DM Sans. Optimized for readability.
- **Pairing rule**: contrast display + body (serif display + sans body, or geometric display + humanist body). Never pair two similar fonts.
- **NEVER as display**: Arial, Roboto, system-ui, Inter (Inter is acceptable ONLY as body, NEVER as display/heading).
- **Fluid typography**: ALL font sizes via clamp(). Example: `text-[clamp(1.5rem,3vw,3rem)]`. No fixed px sizes for headings.
- **Type scale**: use mathematical ratio (1.25 major third or 1.333 perfect fourth). Consistent vertical rhythm.
- **Details**: letter-spacing on uppercase headings (tracking-wide/tracking-widest), proper line-height per size (tight for headings, relaxed for body), font-feature-settings for ligatures/tabular nums where appropriate.
- **Loading**: Google Fonts via @import or <link> with font-display: swap. Preload critical display font.

## Color Science

Go beyond "pick a palette":
- **OKLCH color space**: use oklch() for perceptually uniform gradients that don't muddy in the middle. Tailwind v4 supports this natively.
- **Dominant + accent strategy**: one dominant color (60%), one secondary (30%), one sharp accent (10%). Not evenly distributed.
- **Gradients**: multi-stop gradients with oklch interpolation. Never simple two-color linear-gradient. Layer multiple radial-gradients for depth (gradient mesh effect).
- **Dark mode as its own design**: not inverted colors. Redesign shadows (subtle glow instead of dark drop), warm up accents, reduce contrast slightly, adjust gradient directions. Use dark: variants intentionally.
- **NEVER**: purple-gradient-on-white (the #1 AI slop cliche), generic blue, unsaturated gray-on-gray.
- **CSS variables via Tailwind**: define color tokens in tailwind.config, use semantic names (--color-surface, --color-accent, --color-muted).

## Depth & Dimension

Create interfaces that feel three-dimensional and alive:
- **Layered glassmorphism**: backdrop-blur-xl + bg-white/5 + border border-white/10 on dark backgrounds. Stack 2-3 glass layers at different opacities.
- **Multi-layer shadows**: not just shadow-lg. Stack 3-4 shadows at different offsets/blurs/opacities for realistic depth:
  `shadow-[0_1px_2px_rgba(0,0,0,0.04),0_4px_8px_rgba(0,0,0,0.06),0_12px_32px_rgba(0,0,0,0.08)]`
- **3D transforms**: perspective + rotateX/rotateY on cards, modals. Subtle (2-5deg) for elegance, dramatic (15-30deg) for impact.
- **Grain/noise texture**: SVG filter overlay or CSS background with noise texture at 2-5% opacity for tactile feel.
- **Gradient mesh backgrounds**: stack 3-5 radial-gradients at different positions/sizes/colors for organic, flowing backgrounds.
- **Elevation system**: consistent z-layer system (surface, raised, overlay, modal) with corresponding shadow + blur levels.

## Motion & Animation (Svelte-specific)

Animation is what separates good from extraordinary. Every animation must be High Fidelity - sophisticated, intentional, never cheap or standard:
- **Svelte transitions**: `transition:fly`, `transition:fade`, `transition:scale`, `transition:slide` with custom easing and duration. Use `in:` and `out:` for asymmetric transitions (fast in, graceful out).
- **Spring physics**: `import { spring } from 'svelte/motion'` for natural-feeling interactive elements. Springs for drag, resize, interactive feedback. Use stiffness/damping tuning for personality (snappy: stiffness 0.3, damping 0.8; smooth: stiffness 0.15, damping 0.95).
- **Tweened values**: `import { tweened } from 'svelte/motion'` for smooth number counters, color transitions, progress bars, gradient shifts. Combine with custom interpolators for non-linear transitions.
- **Staggered reveals**: in {#each} blocks, use `transition:fly={{ delay: i * 60, y: 20, duration: 400 }}` for cascading entrance animations. This is the #1 wow-factor technique. Vary the stagger timing per context (fast for lists: 40ms, dramatic for hero: 120ms).
- **Scroll-driven animations**: CSS `animation-timeline: scroll()` for parallax, progress indicators, reveal-on-scroll. Layer multiple scroll-triggered elements at different rates for depth.
- **View Transitions API**: `import { onNavigate } from '$app/navigation'` + `onNavigate((navigation) => { document.startViewTransition(...) })` for cinematic page transitions. Use view-transition-name on shared elements for morph effects between pages.
- **Page load choreography**: orchestrate the entrance of an entire page - background fades in first (0ms), then headline flies up (100ms), then body text fades (200ms), then CTAs spring in (350ms). The first 500ms define the user's emotional response.
- **Skeleton-to-content transitions**: when data loads, don't just swap - crossfade from skeleton to real content with a subtle scale(0.98) to scale(1) for perceived smoothness.
- **Performance**: ONLY animate transform and opacity (GPU-accelerated). Never animate width, height, top, left. Use will-change sparingly and only on actively animating elements.
- **Easing**: never use linear or ease. Use cubic-bezier curves: `cubic-bezier(0.16, 1, 0.3, 1)` (expo out) for entrances, `cubic-bezier(0.7, 0, 0.84, 0)` (expo in) for exits, `cubic-bezier(0.33, 1, 0.68, 1)` (smooth out) for hover state changes.
- **Animation discipline**: not everything should animate. Animate entrances, page transitions, state changes, and meaningful interactions. Static elements that don't change state should NOT animate. Sophisticated restraint beats overanimation.

## Hover Interactions (STRICT RULES)

FORBIDDEN on hover - NEVER do these:
- scale() of any kind (no scale(1.02), no scale(1.05), no growing elements)
- translateY() or translateX() to lift/shift elements
- Any transform that makes the element physically larger or move from its position
- Box-shadow size increases that simulate "lifting"

ALLOWED and encouraged hover effects:
- Color transitions: background-color shift, text color shift, border-color change (transition-colors duration-200)
- Underline animations: width-animated underlines on links (from 0% to 100% via pseudo-element or background-size)
- Opacity shifts on overlays or secondary elements (not on the element itself)
- Border/ring color changes: ring-2 ring-transparent to ring-accent
- Background gradient shifts: subtle hue rotation or gradient-position change
- Cursor changes for interactive affordance
- Text decoration animations
- Inner glow / box-shadow COLOR change (same size, different color)
- Smooth color transitions on icons/SVGs

All hover effects must use transition-colors or transition-all with duration-200 or duration-300. No instant state changes.

## Spatial Composition & Layout

Break the grid intentionally:
- **Asymmetric layouts**: CSS grid with unequal columns (2fr 1fr, 3fr 2fr). Not everything centered.
- **Overlap**: negative margins or absolute positioning for elements that break their container. Cards overlapping sections, images bleeding into adjacent areas.
- **Generous whitespace**: when in doubt, add more space. Cramped layouts are the enemy of elegance. Use py-24/py-32 for section spacing, not py-8.
- **Full-bleed moments**: some elements should escape the max-w container and go edge-to-edge.
- **Diagonal flow**: use clip-path or skew transforms for angled section dividers instead of straight lines.
- **Container queries**: @container for component-level responsive design, not just viewport media queries.
- **Subgrid**: use subgrid for aligning nested grid items to parent grid tracks.

## shadcn-svelte Integration

Build ON TOP of shadcn, not around it:
- shadcn-svelte components are the foundation - extend them, never replace them.
- Style via Tailwind classes on instances - no custom CSS overriding shadcn internals.
- Use shadcn variants as intended (variant="destructive"|"outline"|"ghost"|"secondary").
- Extend the shadcn theme in tailwind.config for project-specific design tokens.
- For elements shadcn doesn't cover (hero sections, custom cards, decorative elements): build with Tailwind directly, maintaining visual consistency with shadcn's design language.

## Responsive Excellence

Every design must be flawless on all screens:
- **Mobile-first**: write base styles for mobile, layer up with sm: md: lg: xl:
- **Fluid spacing**: clamp() for padding/margin. Example: `p-[clamp(1rem,3vw,3rem)]`
- **Touch targets**: minimum 44x44px on mobile for all interactive elements
- **No horizontal scroll**: ever. Test mentally at 320px width.
- **Responsive typography**: already handled by fluid clamp() sizes
- **Layout shifts**: set explicit dimensions on images/videos (aspect-ratio), reserve space for dynamic content

## UX Psychology & Emotional Design

Design is not decoration - it's psychology:
- **Visual hierarchy**: the user's eye must follow an intentional path. Size, contrast, color, and position guide attention. The most important element should be impossible to miss.
- **Perceived performance**: skeleton screens, optimistic UI updates, instant feedback on interactions. The UI must feel faster than the code actually is.
- **Micro-feedback**: every click/tap must acknowledge the action within 100ms. Button press states, loading spinners, success confirmations. The user must never wonder "did that work?"
- **Progressive disclosure**: don't show everything at once. Reveal complexity gradually. Collapsed sections, "show more" patterns, tooltip details.
- **Emotional response targets**: luxury = slow animations + generous whitespace + serif typography. Speed = snappy transitions + dense layout + mono/sans. Playful = spring physics + rounded corners + saturated colors. Choose consciously.
- **Contrast for scannability**: users scan, they don't read. Bold headings, clear section breaks, visual anchors (icons, colored badges, dividers). A page should be understandable in 3 seconds of scanning.
- **Delight through surprise**: one unexpected moment per page - an animation that reveals on scroll, a hover effect that changes the mood, a transition that morphs between states. Not gimmicky, but genuinely delightful.

## Anti-Patterns (NEVER DO)

- Generic purple-on-white gradients
- System fonts (Arial, Helvetica, system-ui) as design choices
- Uniform padding/spacing everywhere (monotonous rhythm)
- Drop shadows without layering (single shadow-lg looks flat)
- Centered-everything layouts (breaks visual hierarchy)
- Animations on every element (motion sickness, performance death)
- Gradients that muddy in the middle (use oklch to prevent)
- Dark mode = just invert colors
- Cookie-cutter card grids with no hierarchy (all same size, same shadow, same spacing)
- Hover effects that are just opacity changes (lazy)
- Hover scale/lift/grow effects (FORBIDDEN - no scale(), no translateY() on hover)
- Standard/generic-looking output (if it looks like a Bootstrap template, start over)
- Low-fidelity anything - every element must look intentionally designed

## Output Standard

Every frontend output must be:
1. **High Fidelity** - every single element looks intentionally designed. No generic, no template-looking, no "good enough". If it doesn't look like a senior designer crafted it, it's not done.
2. **Fully styled** - no raw/unstyled components. Every element has intentional styling from the first render.
3. **Fully functional** - all interactions work, all states handled (hover, focus, active, disabled, loading, empty, error).
4. **Fully responsive** - works flawlessly on desktop (primary), looks good on tablet/mobile.
5. **Sophisticatedly animated** - entrance animations, page transitions, state changes. Motion is not optional but is always tasteful and intentional. Never overanimated, never cheap.
6. **Psychologically effective** - the UX makes users feel something. The visual hierarchy guides them. The micro-feedback confirms their actions. The design earns trust and admiration.
7. **Visually unique** - no two designs should look the same. Vary fonts, colors, layouts, themes across projects.
8. **Production-grade** - no placeholders, no "style later", no TODO comments. Ship-ready on first output.

The bar is not "does it work" or "does it look nice". The bar is: would someone screenshot this and share it because they're impressed? That's the standard. Every pixel is a decision. Make it count.
