// =====================================================================
// RnR_00_prep.do
// ---------------------------------------------------------------------
// PURPOSE : Environment, scheme, variable construction and helper
//           programs. Builds the analysis-ready dataset from the public
//           data and saves it for the downstream scripts.
// INPUTS  : data/public_food_waste_w12.dta
// OUTPUTS : data/_analysis_data.dta   (working file for later scripts)
// AUTHOR  : E. Keith Smith
// DATE    : 2026-09-18   |   STATA: 19.5
// NOTE    : Working directory is set once in master.do; paths here are
//           relative. British English throughout.
// =====================================================================

set more off
set linesize 120
set scheme plotplain

capture mkdir "output"
capture mkdir "output/figures"
capture mkdir "output/tables"

// ---------- Helper: TOST equivalence test (manual implementation) ----
// Two one-sided tests using normal approximation.
// Returns r(tost_p), r(equiv_bound) (smallest |Δ| ruled out at α=.05).
capture program drop tost_eq
program define tost_eq, rclass
    syntax , Coef(real) SE(real) SESOI(real)
    local p_lower = 1 - normal((`coef' + `sesoi')/`se')
    local p_upper = 1 - normal((`sesoi' - `coef')/`se')
    local tost_p = max(`p_lower', `p_upper')
    local equiv_bound = abs(`coef') + 1.645*`se'
    return scalar tost_p = `tost_p'
    return scalar equiv_bound = `equiv_bound'
end

// ---------- Helper: sharpened BKY q-values (Anderson 2008) -----------
// Input: variable holding p-values; Output: var with sharpened q-values.
capture program drop bky_qvalues
program define bky_qvalues
    syntax varname, Generate(name)
    tempvar pvar rank q1 q2 mreject
    qui gen double `pvar' = `varlist'
    qui count if !missing(`pvar')
    local m = r(N)
    sort `pvar'
    qui gen long `rank' = _n if !missing(`pvar')
    // Stage 1: standard BH q-values
    qui gen double `q1' = `pvar' * `m' / `rank' if !missing(`pvar')
    qui replace `q1' = min(`q1', 1)
    // Enforce monotonicity from bottom
    forvalues i = `=`m'-1'(-1)1 {
        qui replace `q1' = min(`q1'[`=`i'+1'], `q1'[`i']) in `i'
    }
    // Stage 2: BKY two-stage. Reject set at α/(1+α)≈.0476 with α=.05
    qui gen byte `mreject' = `q1' <= 0.05/1.05 if !missing(`pvar')
    qui sum `mreject'
    local m0_hat = `m' - r(sum)
    if `m0_hat' < 1 local m0_hat = 1
    // Stage 3: sharpened
    qui gen double `q2' = `pvar' * `m0_hat' / `rank' if !missing(`pvar')
    qui replace `q2' = min(`q2', 1)
    forvalues i = `=`m'-1'(-1)1 {
        qui replace `q2' = min(`q2'[`=`i'+1'], `q2'[`i']) in `i'
    }
    qui gen double `generate' = `q2'
end

// =====================================================================
// Load the merged dataset
// =====================================================================
use "data/public_food_waste_w12.dta", clear

// =====================================================================
// Treatment indicators (lifted from existing do file)
// =====================================================================
// FW vs Burden assignment
recode w12_treat3 (0=1 "FW treatment") (1=0 "Intergenerational Burden"), ///
    gen(treat_assign)
lab var treat_assign "Treatment assignment, Food Waste or Intergenerational Burden"

// Awareness (Food Waste Action Plan info) — for state-intervention block
recode w12_treat4 (-66 0=1 "No Info") (1=2 "Info"), gen(treat_action_state)
la var treat_action_state "FW Info Treatment"

recode w12_treat4 (-66=0 "No Info, Q36") (0=1 "No Info, Q31") ///
    (1=2 "Info, Q31"), gen(treat_action_state_3)
la var treat_action_state_3 "FW Info Treatment, for both q31 and q36"

// Awareness — for policy support block
gen treat_action_policy=.
replace treat_action_policy=0 if treat_assign==0
replace treat_action_policy=1 if treat_assign==1
la def treat_action_policy 0 "Not displayed" 1 "Displayed"
la val treat_action_policy treat_action_policy
la var treat_action_policy "FW Info Treatment - Displayed or not"

// Effectiveness/feedback frame
recode w12_treat5 (0=3 "Info, Achieve Goal") ///
    (1=2 "Info, Will Not Achieve Goal") ///
    (2=1 "Info, no effectiveness treatment") (else=.), gen(treat_effect_3)
la var treat_effect_3 "Effectiveness Treatment, Only Action Info Arm"

clonevar treat_effect = treat_effect_3
replace treat_effect = 0 if treat_assign==0
la def treat_effect 0 "Control, burden treatment arm" ///
    3 "Info, Achieve Goal" 2 "Info, Will Not Achieve Goal" ///
    1 "Info, no effectiveness treatment"
la val treat_effect treat_effect
la var treat_effect "Effectiveness Treatment"

// Order of Q32/Q33
capture confirm variable fl_93_do
if _rc == 0 {
    encode fl_93_do, gen(q32q33_order)
}

// =====================================================================
// Prior beliefs (within FW akt=1 only)
// =====================================================================
foreach pair in "28 plan_industry" "29 plan_effective" "30 plan_goal" {
    tokenize "`pair'"
    recode w12_q`1' (1=0) (2=.25) (3=.5) (4=.75) (5=1) ///
        (-77=.r) (-8=.d) (-66=.t), gen(`2')
}
lab var plan_industry "Industry will reduce food waste"
lab var plan_effective "Plan will be effective"
lab var plan_goal "Plan will achieve 50% reduction goal"

// Composite prior index for Fig 6 moderator analysis
egen plan_prior_avg = rowmean(plan_industry plan_effective plan_goal)
lab var plan_prior_avg "Average prior belief in plan effectiveness (POMS 0-1)"

// =====================================================================
// Subgroups
// =====================================================================
recode w10_q2 (1=1 "Female") (2 3=0 "Not Female") (-99 -77=.), gen(female)

recode w10_q5 ///
    (1 2=1 "Obligatory schooling") ///
    (3 4=2 "Vocational Certificate") ///
    (5=3 "Technical certificate") ///
    (6 7=4 "University degree") (else=.), gen(educ)

recode w10_q53 (-99/0=.), gen(income)

recode w10_q26 ///
    (1=1 "Omnivore (>1.5kg/week)") ///
    (2=2 "Omnivore (0.5-1.5kg/week)") ///
    (3=3 "Flexitarian (<0.5kg/week)") ///
    (4=4 "Vegetarian") (5=5 "Vegan") (else=.), gen(diet)

// Environmental attitudes (factor of w10_q8x1-w10_q8x12)
foreach n of numlist 1/12 {
    qui recode w10_q8x`n' (-99=.) (-97=.) (-77=.) (-8=.)
}
qui factor w10_q8x*, ipf mineigen(1)
qui predict drop_env_att
egen env_att = std(drop_env_att)
drop drop_env_att
lab var env_att "Environmental Attitudes"

// Political orientation (reversed so high=Left)
recode w10_q40 (-99/-7=.), gen(poli_ori_RL)
la def poli_ori_RL 1 "Left" 11 "Right"
la val poli_ori_RL poli_ori_RL
lab var poli_ori_RL "Political Orientation Left to Right"

gen poli_ori = 12 - poli_ori_RL
la def poli_ori 11 "Left" 1 "Right"
la val poli_ori poli_ori
lab var poli_ori "Political Orientation"

// Institutional trust (factor of w10_q44x1-w10_q44x8)
foreach n of numlist 1/8 {
    qui recode w10_q44x`n' (-99/0=.), gen(trust_`n')
}
qui factor trust_1-trust_8, ipf fac(1)
qui predict ins_trust
lab var ins_trust "Institutional Trust"
drop trust_*

// =====================================================================
// Perception items (state-intervention statements) — POMS 0-1 scale
// =====================================================================
foreach q in 31 32 36 {
    recode w12_q`q'x1 (1=0) (2=.25) (3=.5) (4=.75) (5=1) ///
        (-77=.r) (-8=.d) (-66=.t), gen(state_`q'_vol)
    lab var state_`q'_vol "Voluntary measures are sufficient"

    recode w12_q`q'x2 (1=0) (2=.25) (3=.5) (4=.75) (5=1) ///
        (-77=.r) (-8=.d) (-66=.t), gen(state_`q'_gov)
    lab var state_`q'_gov "Government measures are needed"

    recode w12_q`q'x3 (1=0) (2=.25) (3=.5) (4=.75) (5=1) ///
        (-77=.r) (-8=.d) (-66=.t), gen(state_`q'_busi)
    lab var state_`q'_busi "Food businesses should be forced to reduce"
}

foreach y in vol gov busi {
    clonevar state_`y'_base = state_36_`y'
    clonevar state_`y'_t_info = state_31_`y' if treat_assign==1
    gen state_`y'_t_effect = state_32_`y' - state_31_`y' if treat_assign==1
    lab var state_`y'_base "Baseline `y' (burden split, Q36)"
    lab var state_`y'_t_info "FW awareness `y' (Q31, FW only)"
    lab var state_`y'_t_effect "FW effectiveness Δ`y' (Q32-Q31, FW only)"
}

// =====================================================================
// Policy support items (12 items per Q33 and Q37) — POMS 0-1 scale
// =====================================================================
foreach q in 33 37 {
    foreach n of num 1/12 {
        recode w12_q`q'x`n' (1=0) (2=.25) (3=.5) (4=.75) (5=1) ///
            (-77=.r) (-8=.d) (-66=.t), gen(poms_policy_`q'_`n')
    }
    egen pol_supp_info_mi_`q' = rowmiss(poms_policy_`q'_1 poms_policy_`q'_2)
    egen pol_supp_info_`q' = rowmean(poms_policy_`q'_1 poms_policy_`q'_2) ///
        if pol_supp_info_mi_`q'==0
    lab var pol_supp_info_`q' "Information & Disclosures"

    egen pol_supp_tax_mi_`q' = rowmiss(poms_policy_`q'_3 poms_policy_`q'_4)
    egen pol_supp_tax_`q' = rowmean(poms_policy_`q'_3 poms_policy_`q'_4) ///
        if pol_supp_tax_mi_`q'==0
    lab var pol_supp_tax_`q' "Taxes & Charges"

    egen pol_supp_mandate_mi_`q' = rowmiss(poms_policy_`q'_5-poms_policy_`q'_12)
    egen pol_supp_mandate_`q' = rowmean(poms_policy_`q'_5-poms_policy_`q'_12) ///
        if pol_supp_mandate_mi_`q'==0
    lab var pol_supp_mandate_`q' "Mandates & Obligations"
}

foreach y in info tax mandate {
    clonevar pol_supp_`y'_base = pol_supp_`y'_37
    clonevar pol_supp_`y'_t_info = pol_supp_`y'_37
    replace pol_supp_`y'_t_info = pol_supp_`y'_33 ///
        if treat_effect==1 & treat_assign==1
    clonevar pol_supp_`y'_t_effect = pol_supp_`y'_33
    lab var pol_supp_`y'_base "Baseline policy support: `y' (Q37, burden split)"
    lab var pol_supp_`y'_t_info "Awareness policy support: `y'"
    lab var pol_supp_`y'_t_effect "Effectiveness policy support: `y' (FW only)"
}

// =====================================================================
// Top policy priority (Q35x1)
// =====================================================================
recode w12_q35x1 ///
    (1 3=1 "Information & Disclosures") ///
    (4 7=2 "Taxes & Charges") ///
    (2 6 8=3 "Mandates & Obligations") ///
    (5=4 "Continue voluntary action plan") ///
    (-77=.r) (-8=.d) (-66=.t), gen(top_pref)
lab var top_pref "Top Policy Preference"

// =====================================================================
// Save analysis-ready dataset
// =====================================================================
compress
save "data/_analysis_data.dta", replace

di as txt _n "==> Prep complete. N=" _N " saved to data/_analysis_data.dta"
