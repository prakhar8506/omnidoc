---
name: Serene Clinical
colors:
  surface: '#f9f9ff'
  surface-dim: '#d8d9e3'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3fd'
  surface-container: '#ecedf7'
  surface-container-high: '#e6e7f1'
  surface-container-highest: '#e1e2ec'
  on-surface: '#191b22'
  on-surface-variant: '#434656'
  inverse-surface: '#2e3038'
  inverse-on-surface: '#eff0fa'
  outline: '#747688'
  outline-variant: '#c4c5d9'
  surface-tint: '#124af0'
  primary: '#0040e0'
  on-primary: '#ffffff'
  primary-container: '#2e5bff'
  on-primary-container: '#efefff'
  inverse-primary: '#b8c3ff'
  secondary: '#5d5e66'
  on-secondary: '#ffffff'
  secondary-container: '#dddce6'
  on-secondary-container: '#606069'
  tertiary: '#515560'
  on-tertiary: '#ffffff'
  tertiary-container: '#6a6d78'
  on-tertiary-container: '#eef0fd'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dde1ff'
  primary-fixed-dim: '#b8c3ff'
  on-primary-fixed: '#001356'
  on-primary-fixed-variant: '#0035be'
  secondary-fixed: '#e3e1eb'
  secondary-fixed-dim: '#c6c5cf'
  on-secondary-fixed: '#1a1b22'
  on-secondary-fixed-variant: '#46464e'
  tertiary-fixed: '#e0e2ef'
  tertiary-fixed-dim: '#c3c6d3'
  on-tertiary-fixed: '#181b25'
  on-tertiary-fixed-variant: '#434751'
  background: '#f9f9ff'
  on-background: '#191b22'
  surface-variant: '#e1e2ec'
  surface-card: '#FFFFFF'
  surface-card-dark: '#17181F'
  text-primary: '#16181D'
  text-secondary: '#8D909C'
  text-on-dark: '#FFFFFF'
  accent-coral: '#FF6B81'
  accent-teal: '#4FD1C5'
  accent-gold: '#FFC94A'
  nav-background: '#16181D'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '500'
    lineHeight: 22px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
  space-2xl: 2rem
---

# UI Design System — Health Companion

Style direction: Apple-like, minimalist, generous whitespace, one confident accent color against soft neutrals, soft depth via shadow rather than heavy borders.

## 1. Color Palette

- `background.base`: `#EAEBF5` (Screen background - soft lavender-gray)
- `surface.card`: `#FFFFFF` (White cards - booking, claim status, reports)
- `surface.cardDark`: `#17181F` (Dark/navy feature cards - e.g. featured specialty card)
- `accent.primary`: `#2E5BFF` (Primary CTA buttons, selected date, active states)
- `text.primary`: `#16181D` (Headlines, primary body text)
- `text.secondary`: `#8D909C` (Timestamps, subtitles, secondary labels)
- `text.onDark`: `#FFFFFF` (Text/icons on dark or accent-colored surfaces)
- `accent.coral`: `#FF6B81` (List-item accent, alert indicator)
- `accent.teal`: `#4FD1C5` (List-item accent alternate, normal vitals)
- `accent.gold`: `#FFC94A` (Rating badges, pending / moderate indicators)
- `nav.background`: `#16181D` (Floating bottom nav pill)

## 2. Typography
- Family: Inter, -apple-system, BlinkMacSystemFont, "SF Pro", sans-serif
- Display / Headline: Bold, 28–32px, tight line-height
- Title: Semibold, 18–20px
- Body: Regular/Medium, 14–15px
- Caption / Meta: Regular, 12–13px, text.secondary color

## 3. Shape & Spacing
- Corner radius: 20–24px on cards, fully pill (999px) on buttons and bottom nav bar
- Card padding: 16–20px internal padding
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32px
- Shadow: soft, low-opacity drop shadow: `0px 8px 24px rgba(20, 20, 40, 0.06)`

## 4. Navigation & Layout
- Floating pill bottom nav: 4 tabs (Home, Search / Triage, Schedule / Appointments, Profile / Records)
- Minimalist header with greeting or breadcrumb, avatar profile button, and quick actions
