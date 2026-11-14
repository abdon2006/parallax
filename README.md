# PARALLAX
### Bridging Planetary Exploration Through Terrestrial Analog Discovery

> **NASA Space Apps Challenge 2026 — Alexandria, Egypt**
> *Team Alex Vega*

---

## What is Parallax?

**Parallax** is a decision-support tool for researchers and mission planners to identify Earth locations that environmentally resemble the Moon or Mars — without leaving the ground.

Before any crewed mission, astronauts and engineers need to train and test equipment in conditions as close as possible to their target. Parallax helps them **find those conditions on Earth**, ranked and filterable by what matters most to their specific mission.

> *"Parallax helps researchers shortlist Earth analog sites for Moon and Mars missions without inventing a new score. It filters on each site's reported weak conditions, compares up to three candidates, and produces a shareable mission brief."*

---

## The Problem

Finding analog sites is currently:
- **Scattered** — data lives across different databases with no unified interface
- **Incomplete** — most sites lack consistent environmental characterization
- **Inflexible** — different missions have different priorities, requiring different rankings

---

## Our Solution

Parallax combines **187 Earth analog sites** from the USGS Terrestrial Analog Sites dataset with **10 environmental attributes** sourced from NASA POWER API, Open-Elevation, and NASA Fact Sheets — then ranks them by similarity to Moon and Mars conditions.

The app lets researchers **filter, compare, and generate a mission brief** — all in one place.

---

## Five Environmental Dimensions

| Dimension | Attributes |
|---|---|
| 🌡️ **Temperature** | Average, Maximum, Minimum (°C) |
| 🌬️ **Atmosphere** | Atmospheric pressure (hPa), Wind speed (m/s) |
| ☀️ **Radiation** | Solar radiation (W/m²), UV index |
| 💧 **Moisture** | Humidity (%), Rainfall (mm/day) |
| ⛰️ **Terrain** | Elevation (m) |

---

## Algorithm

Sites are ranked# Parallax

**Find Earth's closest training grounds for the Moon and Mars.**

Parallax is a decision tool for researchers and mission planners. It helps you
filter, compare, and brief a shortlist of Earth analog sites for Moon or Mars
missions.

> Environmental analogs only. The dataset does not include site access,
> logistics, cost, permits, or surface composition.

This repository is being built step by step: setup → design system → data →
state → screens → tests.

## Run

```bash
flutter pub get
flutter run
```
 using a **Weighted Similarity Score** comparing each Earth site's conditions against Moon/Mars reference vectors:

| Group | Weight |
|---|---|
| Temperature | 30% |
| Atmosphere | 25% |
| Radiation | 25% |
| Moisture | 15% |
| Terrain | 5% |

**Validation:** Sensitivity analysis across all weight scenarios showed **rank correlation > 0.994**, confirming the ranking is robust.

**Key principle:** The app does not recalculate scores. It uses the pre-computed ranking and filters sites by their `weak_conditions` — the worst ~15% of a site's environmental match. This keeps the science transparent and the ranking honest.

---

## Key Numbers

| Metric | Value |
|---|---|
| Earth analog sites | 187 |
| Environmental attributes | 10 |
| Moon-ready sites | 54 Recommended |
| Mars-ready sites | 3 Recommended |
| Sites recommended for **both** Moon & Mars | **2** (Monturaqui, Carancas) |
| Algorithm consistency | 98.5% |
| Tests passing | 25 |

---

## App Features

### 🏠 Home
Select Moon or Mars. Choose a mission preset (Balanced, Thermal, Atmosphere, Radiation, Low-risk) or build a Custom profile. See live stats and your top match.

### 🎛️ Fine-tune
Toggle individual environmental conditions on/off. See how many sites are affected by each condition before applying. Filter by risk level.

### 🔭 Explore
Search, sort, and filter 187 sites. Browse by status (Recommended / Acceptable / Not recommended). Open any site for a full report.

### 📋 Site Detail
Full environmental breakdown. Comparison table against the Moon/Mars reference. Trade-off explanations. Cross-target badge if the site qualifies for **both** Moon and Mars.

### ⭐ Shortlist & Compare
Add up to 3 sites. Side-by-side comparison table. Automatic recommendation for Primary, Backup, and Lowest-risk candidate.

### 📄 Mission Brief
One-tap generation of a structured, copyable text report: selected analogs, strengths, trade-offs, methodology, and limitations. Ready to paste into an email or report.

---

## Architecture

```
lib/
├── core/           Design system, router, utilities, shared widgets
├── data/           Models, repository (Either<Failure, Data>), local storage
├── logic/          BLoC state management (AnalogBloc + MissionBloc)
└── presentation/   Splash, Home, Fine-tune, Explore, Detail, Shortlist, Brief, About
```

**Stack:** Flutter · flutter_bloc · go_router · dartz · shared_preferences · flutter_svg

**Data flow:**
```
results.json → AnalogRepository → AnalogBloc → Screens
                                               ↕
                              MissionBloc (filters + shortlist + persistence)
```

---

## Data Sources

| Source | Used for |
|---|---|
| [USGS Terrestrial Analog Sites](https://www.usgs.gov/) | 187 Earth analog site locations |
| [NASA POWER API](https://power.larc.nasa.gov/) | Temperature, wind, humidity, rainfall, UV, solar radiation, pressure |
| [Open-Elevation API](https://open-elevation.com/) | Elevation per site |
| [NASA Fact Sheets](https://nssdc.gsfc.nasa.gov/planetary/factsheet/) | Moon & Mars reference values |

---

## Running the App

```bash
flutter pub get
flutter run
```

**Verify:**
```bash
flutter analyze    # → No issues found
flutter test       # → 25 tests passed
flutter build apk --release
```

---

## Limitations

- Environmental analogs only — no logistics, access, cost, or permits data
- `weak_conditions` represent the worst ~15% of a site's match, not every imperfection
- Similarity is relative: score 100 = best match in the dataset, not a perfect match

---

## Team Alex Vega

Built for **NASA Space Apps Challenge 2026 — Alexandria, Egypt**

---

*PARALLAX — Find your planetary analog.*