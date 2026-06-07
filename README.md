# ⚽ FIFA 2026 Heat Risk Analysis

![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-2.0-150458?logo=pandas&logoColor=white)
![NumPy](https://img.shields.io/badge/NumPy-1.24-013243?logo=numpy&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-Public-E97627?logo=tableau&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)

> An end-to-end data analytics pipeline that assesses athlete heat stress risk across all 104 FIFA 2026 World Cup matches using 20 years of historical weather data, WBGT climatology modeling, and an interactive Tableau dashboard.

---

## 📋 Table of Contents
- [Business Problem](#business-problem)
- [Key Findings](#key-findings)
- [Tech Stack](#tech-stack)
- [Project Architecture](#project-architecture)
- [Dashboard](#dashboard)
- [Methodology](#methodology)
- [Recommendations](#recommendations)
- [File Structure](#file-structure)
- [How to Run](#how-to-run)
- [Author](#author)

---

## 🎯 Business Problem

FIFA 2026 will be hosted across 16 cities in the United States, Canada, and Mexico during peak summer months (June–July). Heat stress is a documented risk for elite athletes — matches played in extreme heat can lead to heat exhaustion, performance decline, and serious health events.

**The question this project answers:**
> Which FIFA 2026 matches pose the greatest heat risk to athletes, and what scheduling or operational changes should organizers consider?

---

## 🔍 Key Findings

| Finding | Detail |
|---|---|
| **21% of matches are High Risk (Tier 3)** | 22 out of 104 matches carry elevated heat stress |
| **Houston is the most dangerous venue** | 100% of NRG Stadium matches are Tier 3 |
| **Dallas is second** | 89% of AT&T Stadium matches are Tier 3 |
| **The Semifinal is the highest risk match** | July 14 at AT&T Stadium Dallas, 2pm kickoff — WBGT 29.8°C |
| **The World Cup Final carries Tier 3 risk** | July 19 at MetLife Stadium, 3pm kickoff — WBGT 28.9°C |
| **Afternoon kickoffs are significantly hotter** | 12pm average WBGT is 4–6°C higher than 8pm kickoffs |
| **Mexico City is the coolest venue** | High altitude keeps WBGT below 18°C despite being in Mexico |

### Risk Distribution
```
Tier 3 (High Risk):      22 matches  (21%)
Tier 2 (Elevated Risk):  27 matches  (26%)
Tier 1 (Low Risk):       55 matches  (53%)
```

---

## 🛠 Tech Stack

| Tool | Purpose |
|---|---|
| **Python** (pandas, NumPy) | ETL pipeline, WBGT calculation, climatology modeling |
| **MySQL** | Normalized relational database, staging tables, index optimization |
| **Tableau Public** | Interactive dashboard — map, bar chart, match table, time analysis |
| **Jupyter Notebook** | Analysis environment and reproducible workflow |

---

## 🏗 Project Architecture

```
Raw Data (3 CSVs)
    │
    ▼
Python ETL Pipeline (Jupyter Notebook)
    ├── Data loading & quality checks (299,520 rows, 0 nulls)
    ├── WBGT heat stress calculation (Steadman formula)
    ├── Climatology modeling (Average + 95th percentile per city/month/day/hour)
    ├── Match risk scoring (104 matches × risk tier assignment)
    └── Export to Tableau-ready Excel files
    │
    ▼
MySQL Database (normalized schema)
    ├── COUNTRIES → CITIES → STADIUMS → MATCHES
    ├── WEATHER_OBSERVATIONS → WBGT_CALCULATIONS
    └── WBGT_CLIMATOLOGY (Average + Hot tiers)
    │
    ▼
Tableau Dashboard (4 views)
    ├── Match Risk Map (geographic bubble map)
    ├── Risk by City (horizontal bar chart)
    ├── High Risk Matches (filtered table)
    └── Kickoff Time vs Heat Risk (bar chart)
```

---

## 📊 Dashboard

🔗 **[View Live Dashboard on Tableau Public](https://public.tableau.com/app/profile/christianmedina007)**

The dashboard includes:
- **Match Risk Map** — all 16 host cities color-coded and sized by maximum risk tier
- **Risk by City** — match count per city broken down by risk tier
- **High Risk Matches** — filterable table of Tier 2 and Tier 3 matches with WBGT values
- **Kickoff Time vs Heat Risk** — average WBGT by kickoff hour, proving afternoon games are hotter

---

## 🔬 Methodology

### WBGT Calculation
Wet Bulb Globe Temperature (WBGT) is the internationally recognized index for assessing heat stress in athletic settings. The formula used approximates WBGT from standard meteorological observations:

```python
wet_bulb = (
    T * arctan(0.151977 * sqrt(RH + 8.313659))
    + arctan(T + RH)
    - arctan(RH - 1.676331)
    + 0.00391838 * RH^1.5 * arctan(0.023101 * RH)
    - 4.686035
)

globe_temp = T + (SolarRadiation / 1000) * 5

WBGT = (0.7 * wet_bulb) + (0.2 * globe_temp) + (0.1 * T)
```

Where:
- **T** = Air temperature (°C)
- **RH** = Relative humidity (%)
- **Solar Radiation** = W/m²
- Weights: 70% wet bulb (humidity/evaporation), 20% globe (radiant heat), 10% dry bulb

### Climatology Modeling
For each city × month × day × hour combination, two climatology values were computed from 20 years of historical data (2003–2022):
- **Average WBGT** — mean across all years
- **Hot WBGT** — 95th percentile (worst-case scenario)

### Risk Tier Assignment
| Tier | Condition | Interpretation |
|---|---|---|
| 5 | Avg WBGT > 32°C | Extreme — cancel or reschedule |
| 4 | Hot WBGT > 32°C OR Avg > 28°C | Very High — mandatory protocols |
| 3 | Hot WBGT > 28°C OR Avg > 26°C | High — cooling breaks required |
| 2 | Hot WBGT > 26°C | Elevated — enhanced monitoring |
| 1 | Below all thresholds | Low — standard protocols |

---

## 💡 Recommendations

Based on this analysis, three actionable recommendations for FIFA 2026 organizers:

**1. Reschedule afternoon kickoffs in Dallas and Houston**
All Dallas and Houston matches with 12pm–3pm kickoffs should be moved to 7pm or later. Analysis shows WBGT drops 4–6°C in evening hours at both venues, reducing risk from Tier 3 to Tier 1–2.

**2. Mandate cooling breaks at all Tier 3 matches**
22 matches require mandatory cooling breaks per FIFA heat protocol guidelines. AT&T Stadium, NRG Stadium, and Hard Rock Stadium should have medical staff and cooling stations at maximum capacity for these fixtures.

**3. Close retractable roofs at AT&T Stadium and NRG Stadium**
Both Dallas and Houston stadiums have retractable roofs — this data provides the evidence basis for requiring roof closure at all matches, which significantly reduces solar radiation and indoor temperature.

---

## 📁 File Structure

```
fifa-2026-heat-risk-analysis/
│
├── fifa_2026_heat_risk_analysis.ipynb   # Main Python ETL notebook
├── SchemaShakers.sql                     # MySQL schema creation + data population
├── Sec3_MP3.sql                          # Index optimization + security roles
│
├── data/
│   ├── fifa_2026_host_cities.csv         # 16 host cities with coordinates
│   ├── fifa_2026_match_schedule.csv      # 104 match schedule
│   └── fifa_2026_weather_hourly_2003_2022.csv  # 299,520 hourly weather obs
│
├── outputs/
│   ├── match_risk_geo.xlsx               # Match-level risk scores (Tableau input)
│   ├── city_map.xlsx                     # City-level summary (Tableau input)
│   └── city_risk_summary.csv             # City risk summary table
│
└── README.md
```

---

## ▶️ How to Run

**Prerequisites:**
- Python 3.8+
- Jupyter Notebook
- pandas, NumPy, openpyxl

**Install dependencies:**
```bash
pip install pandas numpy openpyxl jupyter
```

**Run the analysis:**
1. Clone this repository
2. Place the three CSV files in the root directory
3. Open `fifa_2026_heat_risk_analysis.ipynb` in Jupyter
4. Run all cells in order
5. Output files will be generated in the root directory

**Database setup:**
1. Run `SchemaShakers.sql` in MySQL Workbench to create schema and load data
2. Run `Sec3_MP3.sql` for index optimization and user roles

---

## 👤 Author

**Christian Medina**
- 📍 Dallas-Fort Worth, TX
- 🎓 B.S. Political Science, University of North Texas | M.S. Business Analytics (in progress)
- 💼 Assistant Property Manager → Transitioning to Data Analytics
- 🔗 [GitHub](https://github.com/christianmedina007-git)
- 🔗 [LinkedIn](https://linkedin.com/in/christianmedina)

---

*This project was built as part of a portfolio transition into data analytics and business intelligence roles. The analysis demonstrates end-to-end skills in ETL pipeline development, statistical modeling, SQL database design, and data visualization.*
