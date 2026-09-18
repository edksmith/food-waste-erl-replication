// =====================================================================
// check_reproduction.do
// ---------------------------------------------------------------------
// PURPOSE : Quick sanity check that the PUBLIC dataset reproduces the
//           headline numbers reported in the paper. Prints sample sizes,
//           baseline descriptives, and the headline coefficients next to
//           the values printed in the manuscript, so the author can
//           confirm the public data matches the accepted results.
// INPUTS  : data/public_food_waste_w12.dta  (via scripts/RnR_00_prep.do)
// OUTPUTS : console + logs/check_reproduction.log
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// USAGE   : do check_reproduction.do   (from the replication/ folder)
// =====================================================================

version 19.5
clear all
set more off
capture mkdir "logs"
capture log close check
log using "logs/check_reproduction.log", replace text name(check)

// Build the analysis-ready data from the public file (quietly).
qui do "scripts/RnR_00_prep.do"

di as txt _n(2) "{hline 78}"
di as txt "REPRODUCTION CHECK — computed value  [paper value]"
di as txt "{hline 78}"

// ---------------------------------------------------------------------
// 1. Sample sizes
// ---------------------------------------------------------------------
di as res _n "1. SAMPLE SIZES"
qui count
di as txt "   Rows in public data (all)        = " as res r(N)  as txt "   [9,817]"
qui count if !missing(w12_treat3)
di as txt "   Analytical N (took experiment)   = " as res r(N)  as txt "   [6,586]"
qui count if treat_assign==0
di as txt "   Untreated baseline arm (burden)  = " as res r(N)  as txt "   [3,295]"
qui count if treat_assign==1
di as txt "   Experimental module (food waste) = " as res r(N)  as txt "   [3,291]"

// ---------------------------------------------------------------------
// 2. Figure 2 — baseline means (untreated arm)
// ---------------------------------------------------------------------
di as res _n "2. FIGURE 2 — baseline means (POMS 0-1)"
foreach pair in "pol_supp_info_base info [0.77]" ///
                "pol_supp_tax_base tax [0.58]" ///
                "pol_supp_mandate_base mandate [0.67]" ///
                "state_vol_base vol [0.41]" ///
                "state_gov_base gov [0.56]" ///
                "state_busi_base busi [0.68]" {
    gettoken v rest : pair
    gettoken lab paper : rest
    qui mean `v'
    di as txt "   " %-8s "`lab'" " mean = " as res %5.3f el(r(table),1,1) as txt "   `paper'"
}

// ---------------------------------------------------------------------
// 3. Figure 3 — awareness AMEs on perceptions (Panel a)
// ---------------------------------------------------------------------
di as res _n "3. FIGURE 3a — awareness AMEs (info vs no info)"
local p3a_vol "[-0.02  (-0.04, -0.001)]"
local p3a_gov "[ 0.03  ( 0.01,  0.05)]"
local p3a_busi "[-0.02  (-0.04, -0.0004)]"
foreach y in vol gov busi {
    qui regress state_`y'_t_info i.treat_action_state
    qui margins, dydx(treat_action_state) post
    matrix R = r(table)
    local k = colnumb(R, "2.treat_action_state")
    di as txt "   " %-5s "`y'" " AME = " as res %6.3f R[1,`k'] ///
        as txt "  95% CI [" as res %6.3f R[5,`k'] as txt ", " ///
        as res %6.3f R[6,`k'] as txt "]   `p3a_`y''"
}

// ---------------------------------------------------------------------
// 4. Figure 3 — effectiveness AMEs on perception change (Panel b)
// ---------------------------------------------------------------------
di as res _n "4. FIGURE 3b — effectiveness AMEs on Δ perception (vs no-frame)"
di as txt "   paper: vol NEGATIVE -0.04 [-0.06,-0.02]; vol POSITIVE 0.05 [0.03,0.07];"
di as txt "          gov POSITIVE -0.03 [-0.04,-0.01]"
foreach y in vol gov busi {
    qui regress state_`y'_t_effect b1.treat_effect_3
    qui margins, dydx(treat_effect_3) post
    matrix R = r(table)
    foreach con in 2 3 {
        local k = colnumb(R, "`con'.treat_effect_3")
        local arm = cond(`con'==2, "will-not-achieve", "will-achieve   ")
        di as txt "   " %-5s "`y'" " `arm' AME = " as res %6.3f R[1,`k'] ///
            as txt "  [" as res %6.3f R[5,`k'] as txt ", " as res %6.3f R[6,`k'] as txt "]"
    }
}

// ---------------------------------------------------------------------
// 5. Figure 4 — awareness AMEs on policy support (Panel a)
// ---------------------------------------------------------------------
di as res _n "5. FIGURE 4a — awareness AMEs on policy support (FW info vs baseline)"
local p4a_info "[0.02 (0.003, 0.03)]"
local p4a_tax "[0.02 (0.01, 0.04)]"
local p4a_mandate "[0.03 (0.02, 0.05)]"
foreach y in info tax mandate {
    qui regress pol_supp_`y'_t_info i.treat_action_policy
    qui margins, dydx(treat_action_policy) post
    matrix R = r(table)
    local k = colnumb(R, "1.treat_action_policy")
    di as txt "   " %-8s "`y'" " AME = " as res %6.3f R[1,`k'] ///
        as txt "  [" as res %6.3f R[5,`k'] as txt ", " as res %6.3f R[6,`k'] ///
        as txt "]   `p4a_`y''"
}

// ---------------------------------------------------------------------
// 6. Figure 5 — top-priority distribution within no-frame arm
// ---------------------------------------------------------------------
di as res _n "6. FIGURE 5a — top-priority distribution (treat_effect==1 arm)"
qui count if treat_effect==1 & !missing(top_pref)
local tot = r(N)
local labs `" "Information (42.16%)" "Taxes (11.53%)" "Mandates (36.20%)" "Voluntary (10.11%)" "'
forvalues k = 1/4 {
    qui count if treat_effect==1 & top_pref==`k'
    local lab : word `k' of `labs'
    di as txt "   cat `k' = " as res %5.2f 100*r(N)/`tot' as txt "%   [`lab']"
}

// ---------------------------------------------------------------------
// 7. Table A1 — reliability (Cronbach's alpha) spot check
// ---------------------------------------------------------------------
di as res _n "7. TABLE A1 — Cronbach's alpha (spot check)"
qui alpha state_36_vol state_36_gov state_36_busi
di as txt "   perception 3-item alpha = " as res %4.2f r(alpha) as txt "   [0.75]"
local pol
foreach n of num 1/12 {
    local pol `pol' poms_policy_37_`n'
}
qui alpha `pol'
di as txt "   policy 12-item alpha    = " as res %4.2f r(alpha) as txt "   [0.89]"

di as txt _n "{hline 78}"
di as txt "If the computed values match the [paper] values, the public dataset"
di as txt "reproduces the accepted results."
di as txt "{hline 78}"

log close check
