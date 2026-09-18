// =====================================================================
// RnR_01_balance.do
// ---------------------------------------------------------------------
// PURPOSE : Pre-analysis balance / equivalence / manipulation checks (supporting).
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/tables/balance_tests.xlsx
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_01_balance.do
// Pre-analysis tests:
//   (1) Q36 vs Q31 akt=0 equivalence on the three perception items
//   (2) Q32/Q33 order balance across treat_effect_3 arms
//   (3) Manipulation check on plan_industry/plan_effective/plan_goal
//       (a) descriptives within akt=1
//       (b) prior balance across treat_effect_3 arms
// Results written to tables/balance_tests.xlsx (one sheet each).
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

local xlsx "output/tables/balance_tests.xlsx"
capture rm "`xlsx'"

// ---------- (1) Q36 vs Q31 akt=0 equivalence ----------
putexcel set "`xlsx'", sheet("q36_vs_q31") replace
putexcel A1 = "Q36 (burden split, akt=0) vs Q31 (FW akt=0) - t-tests on POMS 0-1 perception items"
local hdrs `" "Outcome" "Mean Q36" "Mean Q31" "Diff" "SE diff" "t" "df" "p" "n (Q36)" "n (Q31)" "TOST p (SESOI=0.02)" "Bound ruled out" "'
local cols A B C D E F G H I J K L
local i = 1
foreach h of local hdrs {
    local c : word `i' of `cols'
    putexcel `c'3 = "`h'"
    local ++i
}

local row = 4
foreach y in vol gov busi {
    tempvar tmp
    gen `tmp' = state_36_`y' if treat_action_state_3==0
    replace `tmp' = state_31_`y' if treat_action_state_3==1
    quietly ttest `tmp' if treat_action_state_3 < 2, by(treat_action_state_3)
    local m1 = r(mu_1)
    local m2 = r(mu_2)
    local diff = `m2' - `m1'
    local sed  = r(se)
    local t    = r(t)
    local df   = r(df_t)
    local p    = r(p)
    local n1   = r(N_1)
    local n2   = r(N_2)
    tost_eq, coef(`diff') se(`sed') sesoi(0.02)
    local tost_p = r(tost_p)
    local bound  = r(equiv_bound)
    putexcel A`row' = "`y'"
    putexcel B`row' = (`m1')
    putexcel C`row' = (`m2')
    putexcel D`row' = (`diff')
    putexcel E`row' = (`sed')
    putexcel F`row' = (`t')
    putexcel G`row' = (`df')
    putexcel H`row' = (`p')
    putexcel I`row' = (`n1')
    putexcel J`row' = (`n2')
    putexcel K`row' = (`tost_p')
    putexcel L`row' = (`bound')
    local ++row
    drop `tmp'
}

di as txt "Q36 vs Q31 akt=0 equivalence written."

// ---------- (2) Q32/Q33 order balance across treat_effect_3 ----------
capture confirm variable q32q33_order
if _rc == 0 {
    putexcel set "`xlsx'", sheet("order_balance") modify
    putexcel A1 = "Q32/Q33 display order balance"

    // Chi-square test of order × treat_effect_3
    quietly tab q32q33_order treat_effect_3, chi2
    local chi2 = r(chi2)
    local p_chi = r(p)
    local dfr = r(r) - 1
    local dfc = r(c) - 1
    local dft = `dfr'*`dfc'
    putexcel A3 = "Chi-square: q32q33_order × treat_effect_3"
    putexcel A4 = "chi2"
    putexcel B4 = (`chi2')
    putexcel A5 = "df"
    putexcel B5 = (`dft')
    putexcel A6 = "p"
    putexcel B6 = (`p_chi')

    // Outcome means by order within each effectiveness arm
    putexcel A8 = "Outcome means by order, within treat_effect_3"
    putexcel A9 = "Outcome"
    putexcel B9 = "treat_effect_3"
    putexcel C9 = "Mean order=1"
    putexcel D9 = "Mean order=2"
    putexcel E9 = "Diff"
    putexcel F9 = "p (ttest)"
    putexcel G9 = "n"
    local row = 10
    foreach y in vol gov busi {
        forvalues e = 1/3 {
            capture noisily quietly ttest state_`y'_t_effect if treat_effect_3==`e', by(q32q33_order)
            if _rc == 0 {
                local m1 = r(mu_1)
                local m2 = r(mu_2)
                local d  = `m2' - `m1'
                local p  = r(p)
                local n  = r(N_1) + r(N_2)
                putexcel A`row' = "`y'_t_effect"
                putexcel B`row' = (`e')
                putexcel C`row' = (`m1')
                putexcel D`row' = (`m2')
                putexcel E`row' = (`d')
                putexcel F`row' = (`p')
                putexcel G`row' = (`n')
                local ++row
            }
        }
    }
    di as txt "Order balance written."
}
else {
    di as error "fl_93_do / q32q33_order missing — order balance test skipped."
}

// ---------- (3) Manipulation check on prior beliefs ----------
putexcel set "`xlsx'", sheet("priors_manip") modify
putexcel A1 = "Prior beliefs in plan effectiveness - within FW akt=1 (treat_action_state==2)"
putexcel A3 = "Variable"
putexcel B3 = "Mean"
putexcel C3 = "SD"
putexcel D3 = "Min"
putexcel E3 = "Max"
putexcel F3 = "n"
local row = 4
foreach v in plan_industry plan_effective plan_goal plan_prior_avg {
    quietly sum `v' if treat_action_state==2
    putexcel A`row' = "`v'"
    putexcel B`row' = (r(mean))
    putexcel C`row' = (r(sd))
    putexcel D`row' = (r(min))
    putexcel E`row' = (r(max))
    putexcel F`row' = (r(N))
    local ++row
}

putexcel A`=`row'+1' = "Balance of priors across treat_effect_3 arms (regression F-test)"
local row = `row' + 2
putexcel A`row' = "Variable"
putexcel B`row' = "F"
putexcel C`row' = "df1"
putexcel D`row' = "df2"
putexcel E`row' = "p"
putexcel F`row' = "n"
local ++row
foreach v in plan_industry plan_effective plan_goal {
    quietly regress `v' i.treat_effect_3 if treat_action_state==2
    quietly test 2.treat_effect_3 3.treat_effect_3
    putexcel A`row' = "`v'"
    putexcel B`row' = (r(F))
    putexcel C`row' = (r(df))
    putexcel D`row' = (r(df_r))
    putexcel E`row' = (r(p))
    putexcel F`row' = (e(N))
    local ++row
}
di as txt "Manipulation check written."

di as txt _n "==> Balance tests written to `xlsx'"
