// =====================================================================
// RnR_07_corrections.do
// ---------------------------------------------------------------------
// PURPOSE : BKY sharpened q-values (Tables A4/A5 inputs) + Lin-adjusted robustness (Table A2).
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/tables/fig03_results.xlsx & fig04_results.xlsx (BKY sheets); output/tables/tableA2_lin_adjustment.xlsx
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_07_corrections.do
// (1) Sharpened BKY q-values across primary outcomes within Fig 3 and Fig 4
// (2) Lin-style covariate adjustment as a robustness check for SI
//     (treatment × demeaned female/educ/income/diet/env_att/poli_ori/ins_trust)
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

// =====================================================================
// (1) Sharpened BKY q-values
// =====================================================================

// ---------- Fig 3: collect p-values, compute q-values ----------
preserve
clear
set obs 9
gen str10 outcome = ""
gen str40 contrast = ""
gen double pval = .
restore

tempfile fig3_pvals
preserve
clear
set obs 0
gen str10 outcome = ""
gen str40 contrast = ""
gen double pval = .
gen str10 panel = ""
save `fig3_pvals', replace
restore

local i = 0
foreach y in vol gov busi {
    quietly regress state_`y'_t_info i.treat_action_state
    quietly margins, dydx(treat_action_state) post
    matrix R = r(table)
    local p = R[4, colnumb(R, "2.treat_action_state")]
    if missing(`p') local p = R[4, 1]
    preserve
    use `fig3_pvals', clear
    local newobs = _N + 1
    set obs `newobs'
    replace outcome  = "`y'"    in `newobs'
    replace contrast = "awareness (FW info vs FW no info)" in `newobs'
    replace pval     = `p'      in `newobs'
    replace panel    = "A"      in `newobs'
    save `fig3_pvals', replace
    restore

    quietly regress state_`y'_t_effect b1.treat_effect_3
    quietly margins, dydx(treat_effect_3) post
    matrix R = r(table)
    foreach con in 2 3 {
        local p = R[4, colnumb(R, "`con'.treat_effect_3")]
        if missing(`p') local p = R[4, `=`con''-1]
        local clab = cond(`con'==2, "negative vs no-frame", "positive vs no-frame")
        preserve
        use `fig3_pvals', clear
        local newobs = _N + 1
        set obs `newobs'
        replace outcome  = "`y'"     in `newobs'
        replace contrast = "`clab'"  in `newobs'
        replace pval     = `p'       in `newobs'
        replace panel    = "B"       in `newobs'
        save `fig3_pvals', replace
        restore
    }
}

preserve
use `fig3_pvals', clear
bky_qvalues pval, generate(qval)
sort panel outcome contrast
list, sepby(panel)
export excel using "output/tables/fig03_results.xlsx", sheet("BKY_qvalues", replace) firstrow(varlabels)
restore

// ---------- Fig 4: collect p-values, compute q-values ----------
tempfile fig4_pvals
preserve
clear
set obs 0
gen str10 outcome = ""
gen str40 contrast = ""
gen double pval = .
gen str10 panel = ""
save `fig4_pvals', replace
restore

foreach y in info tax mandate {
    quietly regress pol_supp_`y'_t_info i.treat_action_policy
    quietly margins, dydx(treat_action_policy) post
    matrix R = r(table)
    local p = R[4, colnumb(R, "1.treat_action_policy")]
    if missing(`p') local p = R[4, 1]
    preserve
    use `fig4_pvals', clear
    local newobs = _N + 1
    set obs `newobs'
    replace outcome  = "`y'"    in `newobs'
    replace contrast = "awareness (FW info vs burden)" in `newobs'
    replace pval     = `p'      in `newobs'
    replace panel    = "A"      in `newobs'
    save `fig4_pvals', replace
    restore

    quietly regress pol_supp_`y'_t_effect b1.treat_effect
    quietly margins, dydx(treat_effect) post
    matrix R = r(table)
    foreach con in 2 3 {
        local p = R[4, colnumb(R, "`con'.treat_effect")]
        if missing(`p') local p = R[4, `=`con''-1]
        local clab = cond(`con'==2, "negative vs no-frame", "positive vs no-frame")
        preserve
        use `fig4_pvals', clear
        local newobs = _N + 1
        set obs `newobs'
        replace outcome  = "`y'"     in `newobs'
        replace contrast = "`clab'"  in `newobs'
        replace pval     = `p'       in `newobs'
        replace panel    = "B"       in `newobs'
        save `fig4_pvals', replace
        restore
    }
}

preserve
use `fig4_pvals', clear
bky_qvalues pval, generate(qval)
sort panel outcome contrast
list, sepby(panel)
export excel using "output/tables/fig04_results.xlsx", sheet("BKY_qvalues", replace) firstrow(varlabels)
restore

// =====================================================================
// (2) Lin-style covariate adjustment (SI)
// =====================================================================
// Demean covariates, then run treatment × demeaned covariates.
// For binary outcomes scaled 0-1 (POMS), use OLS.

// Recover dataset post-preserves
use "data/_analysis_data.dta", clear

// Demean covariates over the analysis sample (use complete-cases per model).
foreach v of varlist female educ income env_att poli_ori ins_trust {
    quietly sum `v'
    gen `v'_dm = `v' - r(mean)
}
// Diet is categorical: encode as dummies and demean each
levelsof diet, local(diet_lev)
foreach k of local diet_lev {
    gen byte _d_diet_`k' = (diet == `k') if !missing(diet)
    quietly sum _d_diet_`k'
    gen _d_diet_`k'_dm = _d_diet_`k' - r(mean)
}

local covars_dm female_dm educ_dm income_dm env_att_dm poli_ori_dm ins_trust_dm
local diet_dm_list
foreach k of local diet_lev {
    local diet_dm_list `diet_dm_list' _d_diet_`k'_dm
}
local covars_dm `covars_dm' `diet_dm_list'

local xlsx "output/tables/tableA2_lin_adjustment.xlsx"
capture rm "`xlsx'"
putexcel set "`xlsx'", sheet("readme") replace
putexcel A1 = "Lin-style covariate-adjusted robustness models (treatment × demeaned covariates)"
putexcel A2 = "Covariates: female, educ, income, env_att, poli_ori, ins_trust, diet dummies"
putexcel A3 = "Demeaning is over the full estimating sample (complete cases per model)."

// ---------- Fig 3 awareness panel A (treat_action_state) -------------
putexcel set "`xlsx'", sheet("fig3a_awareness_Lin") modify
putexcel A1 = "Fig 3 Panel A awareness — Lin-adjusted AMEs on state_y_t_info"
putexcel A3 = "Outcome"
putexcel B3 = "Contrast"
putexcel C3 = "AME (b)"
putexcel D3 = "SE"
putexcel E3 = "p"
putexcel F3 = "Lower 95% CI"
putexcel G3 = "Upper 95% CI"
putexcel H3 = "n"
local row = 4
foreach y in vol gov busi {
    quietly regress state_`y'_t_info i.treat_action_state ///
        i.treat_action_state#c.(`covars_dm')
    quietly margins, dydx(treat_action_state) post
    matrix R = r(table)
    local k = colnumb(R, "2.treat_action_state")
    if `k' == . local k 1
    putexcel A`row' = "`y'"
    putexcel B`row' = "FW info vs FW no info"
    putexcel C`row' = (R[1,`k'])
    putexcel D`row' = (R[2,`k'])
    putexcel E`row' = (R[4,`k'])
    putexcel F`row' = (R[5,`k'])
    putexcel G`row' = (R[6,`k'])
    putexcel H`row' = (e(N))
    local ++row
}

// ---------- Fig 3 Panel B effectiveness -----------------------------
putexcel set "`xlsx'", sheet("fig3b_effectiveness_Lin") modify
putexcel A1 = "Fig 3 Panel B effectiveness — Lin-adjusted AMEs on state_y_t_effect (FW only)"
putexcel A3 = "Outcome"
putexcel B3 = "Contrast"
putexcel C3 = "AME (b)"
putexcel D3 = "SE"
putexcel E3 = "p"
putexcel F3 = "Lower 95% CI"
putexcel G3 = "Upper 95% CI"
putexcel H3 = "n"
local row = 4
foreach y in vol gov busi {
    quietly regress state_`y'_t_effect b1.treat_effect_3 ///
        b1.treat_effect_3#c.(`covars_dm')
    quietly margins, dydx(treat_effect_3) post
    matrix R = r(table)
    foreach con in 2 3 {
        local k = colnumb(R, "`con'.treat_effect_3")
        if `k' == . local k `=`con''
        local clab = cond(`con'==2, "Negative vs no-frame", "Positive vs no-frame")
        putexcel A`row' = "`y'"
        putexcel B`row' = "`clab'"
        putexcel C`row' = (R[1,`k'])
        putexcel D`row' = (R[2,`k'])
        putexcel E`row' = (R[4,`k'])
        putexcel F`row' = (R[5,`k'])
        putexcel G`row' = (R[6,`k'])
        putexcel H`row' = (e(N))
        local ++row
    }
}

// ---------- Fig 4 Panel A awareness on policy support ---------------
putexcel set "`xlsx'", sheet("fig4a_awareness_Lin") modify
putexcel A1 = "Fig 4 Panel A awareness — Lin-adjusted AMEs on pol_supp_y_t_info"
putexcel A3 = "Outcome"
putexcel B3 = "Contrast"
putexcel C3 = "AME (b)"
putexcel D3 = "SE"
putexcel E3 = "p"
putexcel F3 = "Lower 95% CI"
putexcel G3 = "Upper 95% CI"
putexcel H3 = "n"
local row = 4
foreach y in info tax mandate {
    quietly regress pol_supp_`y'_t_info i.treat_action_policy ///
        i.treat_action_policy#c.(`covars_dm')
    quietly margins, dydx(treat_action_policy) post
    matrix R = r(table)
    local k = colnumb(R, "1.treat_action_policy")
    if `k' == . local k 1
    putexcel A`row' = "`y'"
    putexcel B`row' = "FW info vs burden"
    putexcel C`row' = (R[1,`k'])
    putexcel D`row' = (R[2,`k'])
    putexcel E`row' = (R[4,`k'])
    putexcel F`row' = (R[5,`k'])
    putexcel G`row' = (R[6,`k'])
    putexcel H`row' = (e(N))
    local ++row
}

// ---------- Fig 4 Panel B effectiveness on policy support -----------
putexcel set "`xlsx'", sheet("fig4b_effectiveness_Lin") modify
putexcel A1 = "Fig 4 Panel B effectiveness — Lin-adjusted AMEs on pol_supp_y_t_effect (FW only)"
putexcel A3 = "Outcome"
putexcel B3 = "Contrast"
putexcel C3 = "AME (b)"
putexcel D3 = "SE"
putexcel E3 = "p"
putexcel F3 = "Lower 95% CI"
putexcel G3 = "Upper 95% CI"
putexcel H3 = "n"
local row = 4
foreach y in info tax mandate {
    quietly regress pol_supp_`y'_t_effect b1.treat_effect ///
        b1.treat_effect#c.(`covars_dm')
    quietly margins, dydx(treat_effect) post
    matrix R = r(table)
    foreach con in 2 3 {
        local k = colnumb(R, "`con'.treat_effect")
        if `k' == . local k `=`con''
        local clab = cond(`con'==2, "Negative vs no-frame", "Positive vs no-frame")
        putexcel A`row' = "`y'"
        putexcel B`row' = "`clab'"
        putexcel C`row' = (R[1,`k'])
        putexcel D`row' = (R[2,`k'])
        putexcel E`row' = (R[4,`k'])
        putexcel F`row' = (R[5,`k'])
        putexcel G`row' = (R[6,`k'])
        putexcel H`row' = (e(N))
        local ++row
    }
}

di as txt _n "==> Corrections (BKY q-values + Lin robustness) written."
