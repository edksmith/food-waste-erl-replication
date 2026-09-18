// =====================================================================
// RnR_09_summary.do
// ---------------------------------------------------------------------
// PURPOSE : Console + text summary of significance / BKY q / TOST equivalence for Figs 3-4.
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/tables/_summary.txt (significance & equivalence; Tables A4/A5)
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_09_summary.do — Console summary
// For every primary contrast in Figs 3-4:
//   - Significant at p<.05? (also BKY-sharpened q<.05)
//   - TOST-bounded at SESOI=0.02? (smallest Δ ruled out < 0.02)
//   - Neither.
// Output: output/tables/_summary.txt and stdout.
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

tempname fh
file open `fh' using "output/tables/_summary.txt", write replace
file write `fh' "Food Waste RnR — significance & equivalence summary" _n
file write `fh' "===================================================" _n _n
file write `fh' "SESOI = 0.02 on 0-1 POMS scale. BKY q-values are within-figure." _n _n

// Recompute p-values, then q-values within each figure, and store labels.
local outcomes_fig3 vol gov busi
local outcomes_fig4 info tax mandate

// ---------- Build the contrast list for Fig 3 ----------
tempfile contrasts_fig3
preserve
clear
set obs 0
gen str10 outcome = ""
gen str40 contrast = ""
gen double b = .
gen double se = .
gen double pval = .
gen str10 panel = ""
save `contrasts_fig3', replace
restore

foreach y in vol gov busi {
    // Panel A: awareness on perception
    quietly regress state_`y'_t_info i.treat_action_state
    quietly margins, dydx(treat_action_state) post
    matrix R = r(table)
    local k = colnumb(R, "2.treat_action_state")
    if `k' == . local k 1
    local b  = R[1,`k']
    local se = R[2,`k']
    local p  = R[4,`k']
    preserve
    use `contrasts_fig3', clear
    local newobs = _N + 1
    set obs `newobs'
    replace outcome = "`y'" in `newobs'
    replace contrast = "awareness FW info vs FW no info" in `newobs'
    replace b = `b' in `newobs'
    replace se = `se' in `newobs'
    replace pval = `p' in `newobs'
    replace panel = "A" in `newobs'
    save `contrasts_fig3', replace
    restore

    // Panel B: effectiveness on perception Δ
    quietly regress state_`y'_t_effect b1.treat_effect_3
    quietly margins, dydx(treat_effect_3) post
    matrix R = r(table)
    foreach con in 2 3 {
        local k = colnumb(R, "`con'.treat_effect_3")
        if `k' == . local k `=`con''
        local b  = R[1,`k']
        local se = R[2,`k']
        local p  = R[4,`k']
        local clab = cond(`con'==2, "negative vs no-frame", "positive vs no-frame")
        preserve
        use `contrasts_fig3', clear
        local newobs = _N + 1
        set obs `newobs'
        replace outcome = "`y'" in `newobs'
        replace contrast = "`clab'" in `newobs'
        replace b = `b' in `newobs'
        replace se = `se' in `newobs'
        replace pval = `p' in `newobs'
        replace panel = "B" in `newobs'
        save `contrasts_fig3', replace
        restore
    }
}

// ---------- Same for Fig 4 ----------
tempfile contrasts_fig4
preserve
clear
set obs 0
gen str10 outcome = ""
gen str40 contrast = ""
gen double b = .
gen double se = .
gen double pval = .
gen str10 panel = ""
save `contrasts_fig4', replace
restore

foreach y in info tax mandate {
    quietly regress pol_supp_`y'_t_info i.treat_action_policy
    quietly margins, dydx(treat_action_policy) post
    matrix R = r(table)
    local k = colnumb(R, "1.treat_action_policy")
    if `k' == . local k 1
    local b  = R[1,`k']
    local se = R[2,`k']
    local p  = R[4,`k']
    preserve
    use `contrasts_fig4', clear
    local newobs = _N + 1
    set obs `newobs'
    replace outcome = "`y'" in `newobs'
    replace contrast = "awareness FW info vs burden" in `newobs'
    replace b = `b' in `newobs'
    replace se = `se' in `newobs'
    replace pval = `p' in `newobs'
    replace panel = "A" in `newobs'
    save `contrasts_fig4', replace
    restore

    quietly regress pol_supp_`y'_t_effect b1.treat_effect
    quietly margins, dydx(treat_effect) post
    matrix R = r(table)
    foreach con in 2 3 {
        local k = colnumb(R, "`con'.treat_effect")
        if `k' == . local k `=`con''
        local b  = R[1,`k']
        local se = R[2,`k']
        local p  = R[4,`k']
        local clab = cond(`con'==2, "negative vs no-frame", "positive vs no-frame")
        preserve
        use `contrasts_fig4', clear
        local newobs = _N + 1
        set obs `newobs'
        replace outcome = "`y'" in `newobs'
        replace contrast = "`clab'" in `newobs'
        replace b = `b' in `newobs'
        replace se = `se' in `newobs'
        replace pval = `p' in `newobs'
        replace panel = "B" in `newobs'
        save `contrasts_fig4', replace
        restore
    }
}

// ---------- Summarise per figure ----------
foreach figno in 3 4 {
    preserve
    use `contrasts_fig`figno'', clear
    bky_qvalues pval, generate(qval)
    gen double tost_p = .
    gen double bound = .
    forvalues i = 1/`=_N' {
        tost_eq, coef(`=b[`i']') se(`=se[`i']') sesoi(0.02)
        qui replace tost_p = r(tost_p) in `i'
        qui replace bound  = r(equiv_bound) in `i'
    }
    gen byte sig_p   = pval < 0.05
    gen byte sig_q   = qval < 0.05
    gen byte equiv   = bound < 0.02
    gen str20 verdict = ""
    replace verdict = "significant"    if sig_p == 1
    replace verdict = "equivalent"     if sig_p == 0 & equiv == 1
    replace verdict = "inconclusive"   if sig_p == 0 & equiv == 0

    di as txt _n _n "=== Fig `figno' contrasts ==="
    list panel outcome contrast b se pval qval bound verdict, ///
        sepby(panel) noobs abbrev(20) divider

    file write `fh' _n "=== Fig `figno' ===" _n
    file write `fh' _col(1) "panel" _col(8) "outcome" _col(20) "contrast" ///
        _col(50) "b" _col(60) "p" _col(70) "q(BKY)" _col(82) "bound" _col(94) "verdict" _n
    forvalues i = 1/`=_N' {
        file write `fh' _col(1) (panel[`i']) ///
            _col(8) (outcome[`i']) ///
            _col(20) (contrast[`i']) ///
            _col(50) %8.4f (b[`i']) ///
            _col(60) %8.4f (pval[`i']) ///
            _col(70) %8.4f (qval[`i']) ///
            _col(82) %8.4f (bound[`i']) ///
            _col(94) (verdict[`i']) _n
    }
    restore
}

file close `fh'
type "output/tables/_summary.txt"

di as txt _n "==> Summary written to output/tables/_summary.txt"
