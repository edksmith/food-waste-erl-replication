// =====================================================================
// master.do
// ---------------------------------------------------------------------
// Replication package for:
//   Smith, E. K. & Bernauer, T. "Do Voluntary Industry Measures Shift
//   Support for Stronger Environmental Governance?" Environmental
//   Research Letters (accepted). DOI: <PLACEHOLDER>.
//
// Runs the full analysis against the PUBLIC dataset and writes all
// figures and tables to output/. Expected total runtime: ~3-6 minutes.
//
// USAGE : open Stata, then:  do master.do
//         (adjust the one cd line below to point at this folder).
//
// AUTHOR : E. Keith Smith   |   DATE: 2026-09-18
// STATA  : 19.5 (StataNow SE), macOS
// =====================================================================

version 19.5
clear all
set more off
set linesize 120

// ---------------------------------------------------------------------
// 0. Working directory — SET ONCE HERE. Everything below is relative.
// ---------------------------------------------------------------------
cd "/Users/esmith/Desktop/food waste RnR/replication"   // <-- EDIT THIS

// ---------------------------------------------------------------------
// 1. Output folders (created if missing)
// ---------------------------------------------------------------------
capture mkdir "output"
capture mkdir "output/figures"
capture mkdir "output/tables"
capture mkdir "logs"

// ---------------------------------------------------------------------
// 2. Required user-written commands
//    Installed once; wrapped in capture so re-runs do not fail.
//    Versions pulled on 2026-09-18.
// ---------------------------------------------------------------------
capture which coefplot
if _rc ssc install coefplot, replace          // Ben Jann (SSC); pulled 2026-09-18
capture which catplot
if _rc ssc install catplot, replace           // N. J. Cox (SSC); pulled 2026-09-18
capture which blindschemes
if _rc ssc install blindschemes, replace       // D. Bischof (SSC); scheme plotplain; pulled 2026-09-18
// grc1leg2 is NOT on SSC — it installs from the CGD Stata repository:
capture which grc1leg2
if _rc net install grc1leg2, ///
    from("http://digital.cgdev.org/doc/stata/MO/Misc") replace   // pulled 2026-09-18

set scheme plotplain

// ---------------------------------------------------------------------
// 3. Reproducibility seed
// ---------------------------------------------------------------------
set seed 20240918

// ---------------------------------------------------------------------
// 4. Logging
// ---------------------------------------------------------------------
local stamp = subinstr("`c(current_date)'_`c(current_time)'", ":", "-", .)
local stamp = subinstr("`stamp'", " ", "-", .)
capture log close _all
log using "logs/master_`stamp'.log", replace text name(master)

di as txt _n "=== Step 0: data prep ==="
do "scripts/RnR_00_prep.do"

di as txt _n "=== Step 1: balance & pre-analysis checks ==="
do "scripts/RnR_01_balance.do"

di as txt _n "=== Step 2: Figure 2 (baseline preferences) ==="
do "scripts/RnR_02_fig2.do"

di as txt _n "=== Step 3: Figure 3 (perceptions) ==="
do "scripts/RnR_03_fig3.do"

di as txt _n "=== Step 4: Figure 4 (policy support) ==="
do "scripts/RnR_04_fig4.do"

di as txt _n "=== Step 5: Figure 5 (priorities) ==="
do "scripts/RnR_05_fig5.do"

di as txt _n "=== Step 6: corrections (BKY q-values + Lin robustness; Tables A2/A4/A5) ==="
do "scripts/RnR_07_corrections.do"

di as txt _n "=== Step 7: SI items (Tables A1/A3; Figs A1/A2) ==="
do "scripts/RnR_08_si.do"

di as txt _n "=== Step 8: console summary (Tables A4/A5) ==="
do "scripts/RnR_09_summary.do"

di as txt _n "=== Step 9: SI heterogeneity (Figs A3-A6) ==="
do "scripts/RnR_10_SI_heterogeneity.do"

di as txt _n "=== Done. See output/figures/ and output/tables/. ==="
log close master
