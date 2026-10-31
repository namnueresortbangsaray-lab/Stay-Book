# ui-ux-pro-max design-system lookup

The skill's generator (`search.py "<query>" --design-system`) needs Python 3, which is not installed here (see
`CLAUDE.md` → Blockers). The generator aggregates rows from `data/products.csv`, `ui-reasoning.csv`, `styles.csv`,
`colors.csv` and `typography.csv`, so the same rows were read directly for the requested context: product
"hotel/resort management back-office (PMS)", audience "front-desk and housekeeping staff", style "clean,
professional, data-dense, flat".

## Rows the generator would draw on

| Source | Row | Recommendation |
|---|---|---|
| products.csv | Hotel/Hospitality | Style "Liquid Glass + Minimalism & Swiss Style", secondary "Glassmorphism, Soft UI Evolution", landing "Hero-Centric + Social Proof", dashboard "Revenue Management Dashboard", palette "Warm neutrals + Gold (#D4AF37)" |
| ui-reasoning.csv | Hotel/Hospitality | Must have room booking and virtual tour; anti-patterns "poor photos, complex booking" |
| colors.csv | Hotel/Hospitality | Primary `#1E3A8A`, secondary `#3B82F6`, accent `#A16207`, background `#F8FAFC`, muted `#E9EEF5`, muted text `#475569`, border `#BFDBFE`, destructive `#DC2626` |
| products.csv | Analytics Dashboard / Productivity Tool | "Data-Dense Dashboard", "Flat Design + Micro-interactions", "Minimalism & Swiss Style"; "Clarity > aesthetics", "Ease of use. Speed & efficiency focus" |
| styles.csv | Data-Dense Dashboard | Data tables, KPI cards, minimal padding, row highlighting, maximum data visibility; requires contrast 4.5, keyboard, visible focus, reduced motion |
| styles.csv | Flat Design / Minimalism & Swiss Style | No gradients or shadows, simple colour/opacity hover, 150–250 ms transitions, grid-based, high contrast; best for enterprise apps and dashboards |
| typography.csv | (all hospitality / enterprise rows) | Google Fonts pairings (Playfair, Karla, Plus Jakarta Sans…) |

## Comparison with the current tokens

| Aspect | Skill suggests | Current (`Styles/tokens.css`, `tailwind.config.js`) | Decision |
|---|---|---|---|
| Overall style | Hotel row: Liquid Glass / glassmorphism / hero; dashboard rows: data-dense, flat, Swiss | Flat, data-dense tables, hairlines, one popover shadow | Keep. The hotel row describes a guest-facing marketing site; the dashboard and flat rows match a staff PMS and agree with the current direction |
| Primary | Navy `#1E3A8A` / blue `#3B82F6` | Blue `#1D5FD1` (dark `#5B9BFF`) | Keep (project constraint: blue and white). Same hue family |
| Background / surface | `#F8FAFC` / white | `#F4F7FB` / white | Keep: equivalent cool off-white |
| Accent | Gold `#A16207` / `#D4AF37` | Amber `#A86A12` (pets, regular guests, highlights) | Keep: already a gold-amber, used sparingly |
| Muted text | `#475569` | ink-muted `#4A5A73`, ink-subtle `#5A6880` | Keep: comparable, both ≥ 4.5:1 |
| Border | `#BFDBFE` (blue-tinted) | line `#DCE4EF`, line-strong `#C3CFDF`, control `#7C8AA3` | Keep: the skill's border is fine for hairlines but inputs need the 3:1 `control` token |
| Destructive | `#DC2626` | `#C0392B` (brief value) | Keep the brief value (5.4:1 on white; `#DC2626` is 4.8:1) |
| Typography | Google Fonts pairings | Self-hosted IBM Plex Sans Thai + Noto Serif Thai | Keep (constraint: self-hosted, Thai-first). No Thai-capable pairing appears in the skill's rows |
| Motion | 150–300 ms, simple hover | 120–200 ms ad hoc | Adopt tokens (finding SA-13) |
| Density | Dense dashboard spacing (8–32 px) | 8 px grid, compact density toggle | Keep |

Rejected suggestions: glassmorphism and Liquid Glass, hero/social-proof layouts, virtual tours, gold-heavy palettes,
Google Fonts imports. They fit a guest-facing hotel website, not a back-office tool, and conflict with the project
constraints.
