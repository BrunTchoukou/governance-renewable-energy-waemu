# Governance and Renewable Energy Production in WAEMU

## Overview
This repository contains the Stata-based panel econometric analysis of the effect of governance quality on renewable energy production in six WAEMU countries (Benin, Burkina Faso, Côte d'Ivoire, Mali, Senegal, and Togo) for the period 2000–2023.  

The study examines the role of governance dimensions, namely control of corruption, government effectiveness, and political stability, in renewable energy production, using PMG-ARDL, FMOLS, DOLS estimations, and panel causality tests.

## Requirements

- Stata 16 or higher
- Required Stata packages (automatically installed in the do-file if missing):
  - `xtpmg` (PMG/Dynamic panel estimation)
  - `xtcips` (Pesaran CIPS unit root test)
  - `pescadf` (Pesaran CADF test)
  - `xtcointtest` (Pedroni & Kao cointegration tests)
  - `xtwest` (Westerlund cointegration tests)
  - `xtcointreg` (FMOLS/DOLS estimation)
  - `estout` (esttab tables)
  - `xtgcause` (Dumitrescu-Hurlin causality)

## Data

- **Data.xlsx**: Contains panel data for the six WAEMU countries from 2000–2023.
- Key variables include:
  - Governance: `CC` (Control of Corruption), `GE` (Government Effectiveness), `PV` (Political Stability)
  - Renewable energy: `REP` (Renewable Energy Production)
  - Macroeconomic and control variables: GDP, GFCF, CO2, trade openness, education, ICT, etc.
- The data file has been structured with countries as rows and years as columns for panel analysis.

## Analysis

1. **Data Import and Panel Declaration**:  
   - Import Excel data and encode country variable.
   - Declare panel structure: `xtset country_id year`.

2. **Descriptive Statistics**:  
   - Summaries for all raw variables.

3. **Variable Transformations**:  
   - Log transformations for positive variables.
   - Inverse hyperbolic sine transformation for FDI.
   - Creation of linear time trend.

4. **First Differences**:  
   - Generation of first-differenced variables (`d_var`) for dynamic panel analysis.

5. **Cross-Sectional Dependence & Panel Unit Root Tests**:  
   - Pesaran (2007) CIPS test.
   - Pesaran CADF test.

6. **Panel Cointegration Tests**:  
   - Pedroni (1999, 2004) tests.
   - Kao (1999) tests.
   - Westerlund (2007) error-correction-based tests.

7. **Panel Estimation**:  
   - PMG / DFE ARDL for short- and long-run effects.
   - FMOLS / DOLS for robustness.
   - Panel Granger causality and Dumitrescu & Hurlin (2012) tests.

8. **Results**:  
   - Exported tables are available in `output/` as RTF files ready for publication.

## How to Reproduce

1. Clone or download this repository.
2. Open Stata 16 or higher.
3. Set working directory to the project folder (do-file handles global paths).
4. Run `do/analysis.do` to reproduce all analyses and export results.

## Citation / Reference

Please cite the work as:  

**Tchoukou, G. B.-U., & Lokonon, K. O. B. (2025). Governance and Renewable Energy Production in WAEMU. University of Abomey-Calavi.**
