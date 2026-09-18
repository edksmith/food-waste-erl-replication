// =====================================================================
// RnR_08_si.do
// ---------------------------------------------------------------------
// PURPOSE : SI: construct validity/alpha (Table A1), four-group plot (Fig A2), predictors (Fig A1), heterogeneity joint tests (Table A3).
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/figures/figA1_predictors_baseline.*; output/figures/figA2_four_group_policy_support.*; output/tables/SI_results.xlsx
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_08_si.do — Supplementary information items
// (1) CFA on three perception items + twelve policy items, plus α
// (2) Full four-group plot of policy support with burden as reference
// (3) Predictors of baseline preferences (coefplot)
// (4) Heterogeneity by env_att / poli_ori / ins_trust on full FW sample
// (5) Manipulation check on accordion timings (vars absent — noted)
// All Lin robustness already in tables/SI_lin_adjustment.xlsx
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

local xlsx "output/tables/SI_results.xlsx"
capture rm "`xlsx'"

// =====================================================================
// (1) Construct validity: CFA + Cronbach's α
// =====================================================================
// Perception items: use the burden-split Q36 items (state_36_vol, gov, busi)
// — these are the version asked of all baseline respondents.
quietly factor state_36_vol state_36_gov state_36_busi, ml factors(1)
matrix L_perc = e(L)
quietly alpha state_36_vol state_36_gov state_36_busi
scalar alpha_perc = r(alpha)

putexcel set "`xlsx'", sheet("CFA_perceptions") replace
putexcel A1 = "CFA: perception items (Q36, burden split)"
putexcel A3 = "Item"
putexcel B3 = "Loading"
putexcel C3 = "Uniqueness"
local items state_36_vol state_36_gov state_36_busi
local i = 0
foreach v of local items {
    local ++i
    putexcel A`=`i'+3' = "`v'"
    putexcel B`=`i'+3' = (L_perc[`i', 1])
}
putexcel A`=`i'+5' = "Cronbach's alpha"
putexcel B`=`i'+5' = (alpha_perc)

// Policy items: use the Q37 items (burden split)
local pol_items
foreach n of num 1/12 {
    local pol_items `pol_items' poms_policy_37_`n'
}
quietly factor `pol_items', ml factors(1)
matrix L_pol = e(L)
quietly alpha `pol_items'
scalar alpha_pol = r(alpha)

putexcel set "`xlsx'", sheet("CFA_policy") modify
putexcel A1 = "CFA: policy items (Q37, burden split)"
putexcel A3 = "Item"
putexcel B3 = "Loading"
local i = 0
foreach v of local pol_items {
    local ++i
    putexcel A`=`i'+3' = "`v'"
    putexcel B`=`i'+3' = (L_pol[`i', 1])
}
putexcel A`=`i'+5' = "Cronbach's alpha (12-item)"
putexcel B`=`i'+5' = (alpha_pol)

// Per-subscale α
foreach pair in "info 1 2" "tax 3 4" "mandate 5 6 7 8 9 10 11 12" {
    tokenize "`pair'"
    local name `1'
    macro shift
    local idxs `*'
    local items
    foreach k of local idxs {
        local items `items' poms_policy_37_`k'
    }
    quietly alpha `items'
    scalar alpha_`name' = r(alpha)
}
putexcel A`=`i'+7' = "Cronbach's alpha — Information & Disclosures"
putexcel B`=`i'+7' = (alpha_info)
putexcel A`=`i'+8' = "Cronbach's alpha — Taxes & Charges"
putexcel B`=`i'+8' = (alpha_tax)
putexcel A`=`i'+9' = "Cronbach's alpha — Mandates & Obligations"
putexcel B`=`i'+9' = (alpha_mandate)

// =====================================================================
// (2) Full four-group plot of policy support effects with burden ref
// =====================================================================
// Use b0.treat_effect: 0=burden control, 1=FW no-frame, 2=FW negative, 3=FW positive.
// Outcome: pol_supp_y_t_info (which mixes Q37 burden + Q33 FW; the burden
// reference is meaningful only for the awareness comparison). For the four-
// group display, use pol_supp_y_t_effect with burden=0 set to Q37 baseline.

// Simpler: just run the original Fig 5a four-group plot from old submission,
// using treat_effect (4 levels) on a combined outcome.
foreach y in info tax mandate {
    gen pol_supp_`y'_4grp = pol_supp_`y'_37 if treat_assign==0
    replace pol_supp_`y'_4grp = pol_supp_`y'_33 if treat_assign==1
}

foreach y in info tax mandate {
    quietly regress pol_supp_`y'_4grp b0.treat_effect
    quietly margins, dydx(treat_effect) post
    matrix R_4g_`y' = r(table)
    scalar N_4g_`y' = e(N)
    est sto si_4g_`y'
}

coefplot ///
    (si_4g_info,    recast(bar) col(edkblue%70)     ciopts(recast(rcap) lc(black))) ///
    (si_4g_tax,     recast(bar) col(forest_green%70) ciopts(recast(rcap) lc(black))) ///
    (si_4g_mandate, recast(bar) col(maroon%70)      ciopts(recast(rcap) lc(black))) ///
    , vert barw(0.25) ///
    ti("{bf:Policy support effectiveness treatment}", s(medlarge)) ///
    subti("{it:Comparison with untreated alt. survey arm }", s(small)) ///
    yti("AME (treatments vs control [untreated])") ///
    coeflabels(1.treat_effect = `""Food-waste info" "no effectiveness frame""' ///
               2.treat_effect = `""Food-waste info" "will not achieve goal""' ///
               3.treat_effect = `""Food-waste info" "will achieve goal""') ///
    ylab(-.10(0.02).10, format(%3.2f)) ///
    yli(0, lc(gs10) lp(dash)) ///
    legend(order(2 "Information" "& Disclosures" ///
                 4 "Taxes" "& Charges" ///
                 6 "Mandates" "& Obligations") ///
           pos(6) row(1) si(small)) ///
    name(si_4group, replace)

gr export "output/figures/figA2_four_group_policy_support.pdf", as(pdf) name("si_4group") replace
gr export "output/figures/figA2_four_group_policy_support.png", as(png) name("si_4group") replace

putexcel set "`xlsx'", sheet("four_group_polsupp") modify
putexcel A1 = "SI: four-group policy support effects vs burden control"
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
    matrix R = R_4g_`y'
    forvalues con = 1/3 {
        local k = colnumb(R, "`con'.treat_effect")
        if `k' == . local k `con'
        local clab : word `con' of "FW_no_frame" "FW_will_not_achieve" "FW_will_achieve"
        putexcel A`row' = "`y'"
        putexcel B`row' = "`clab' vs burden"
        putexcel C`row' = (R[1,`k'])
        putexcel D`row' = (R[2,`k'])
        putexcel E`row' = (R[4,`k'])
        putexcel F`row' = (R[5,`k'])
        putexcel G`row' = (R[6,`k'])
        putexcel H`row' = (N_4g_`y')
        local ++row
    }
}

// =====================================================================
// (3) Predictors of baseline preferences (existing coefplot lifted)
// =====================================================================
preserve
foreach x of varlist income env_att ins_trust poli_ori {
    quietly sum `x'
    local max_`x' = r(max)
    local min_`x' = r(min)
    gen `x'_poms = (`x' - `min_`x'')/(`max_`x'' - `min_`x'')
}

foreach y in info tax mandate {
    quietly regress pol_supp_`y'_base ///
        i.female income_poms i.educ i.diet ///
        env_att_poms ins_trust_poms poli_ori_poms
    matrix reg_`y' = r(table)
}
foreach y in vol gov busi {
    quietly regress state_`y'_base ///
        i.female income_poms i.educ i.diet ///
        env_att_poms ins_trust_poms poli_ori_poms
    matrix reg_`y' = r(table)
}

coefplot ///
    (mat(reg_info), mc(edkblue) ci((reg_info[5] reg_info[6])) ciopts(lc(edkblue) recast(rcap))) ///
    (mat(reg_tax),  mc(forest_green) ci((reg_tax[5] reg_tax[6])) ciopts(lc(forest_green) recast(rcap))) ///
    (mat(reg_mandate), mc(maroon) ci((reg_mandate[5] reg_mandate[6])) ciopts(lc(maroon) recast(rcap))) ///
    , ti("{bf:Support for stronger}" "{bf:food-waste policies}", s(medlarge)) ///
    drop(_cons) xline(0, lp(dash) lc(gs12)) ///
    xlab(-1(0.25)1, format(%3.2f) labs(small)) ///
	xti("Estimated min–max effect on food-waste reduction preference", s(small)) ///
    coefl(1.female="Gender: female" income_poms="Income" ///
          2.educ=`""{it:Ref: Obligatory}" "Vocational""' 3.educ="Technical" 4.educ="University" ///
          2.diet="Light Omnivore" 3.diet="Flexitarian" 4.diet="Vegetarian" 5.diet="Vegan" ///
          env_att_poms=`""Pro-environmental" "attitudes""' ///
          ins_trust_poms=`""Institutional" "trust""' ///
          poli_ori_poms=`""Political" "orientation""') ///
    legend(order(2 "Information" "& Disclosures" ///
                 4 "Taxes" "& Charges" ///
                 6 "Mandates" "& Obligations") ///
           pos(6) row(2) si(small)) ///
	fysize(90) /// 
    name(si_pred_supp, replace) nodraw

coefplot ///
    (mat(reg_vol),  mc(sand)   ci((reg_vol[5] reg_vol[6])) ciopts(lc(sand) recast(rcap))) ///
    (mat(reg_gov),  mc(sienna) ci((reg_gov[5] reg_gov[6])) ciopts(lc(sienna) recast(rcap))) ///
    (mat(reg_busi), mc(teal)   ci((reg_busi[5] reg_busi[6])) ciopts(lc(teal) recast(rcap))) ///
	, ti("{bf:Perceptions of voluntary measures and}" "{bf:demand for government action}", s(medlarge)) /// 
    drop(_cons) xline(0, lp(dash) lc(gs12)) ///
    xlab(-1(0.25)1, format(%3.2f) labs(small)) ///
	xti("Estimated min–max effect on food-waste reduction preference", s(small)) ///
    coefl(1.female="Gender: female" income_poms="Income" ///
          2.educ=`""{it:Ref: Obligatory}" "Vocational""' 3.educ="Technical" 4.educ="University" ///
          2.diet="Light Omnivore" 3.diet="Flexitarian" 4.diet="Vegetarian" 5.diet="Vegan" ///
          env_att_poms=`""Pro-environmental" "attitudes""' ///
          ins_trust_poms=`""Institutional" "trust""' ///
          poli_ori_poms=`""Political" "orientation""') ///
    legend(order(2 "Voluntary measures" "are sufficient" ///
                 4 "Government measures" "are needed" ///
                 6 "Non-participating firms" "required to reduce waste") ///
           pos(6) row(2) si(small)) ///
    name(si_pred_state, replace) nodraw

gr combine si_pred_supp si_pred_state, xsize(8) ysize(6) name(si_predictors, replace)
gr export "output/figures/figA1_predictors_baseline.pdf", as(pdf) name("si_predictors") replace
gr export "output/figures/figA1_predictors_baseline.png", as(png) name("si_predictors") replace
restore

// =====================================================================
// (4) Heterogeneity on full FW by env_att / poli_ori / ins_trust
// =====================================================================
putexcel set "`xlsx'", sheet("heterogeneity_full_FW") modify
putexcel A1 = "Heterogeneity of feedback (treat_effect_3) effects by attitudes (FW only)"
putexcel A3 = "Moderator"
putexcel B3 = "Outcome"
putexcel C3 = "Outcome type"
putexcel D3 = "Joint interaction F"
putexcel E3 = "p"
putexcel F3 = "n"
local row = 4
foreach M in env_att poli_ori ins_trust {
    foreach y in vol gov busi {
        quietly regress state_`y'_t_effect b1.treat_effect_3##c.`M' if treat_assign==1
        quietly test 2.treat_effect_3#c.`M' 3.treat_effect_3#c.`M'
        putexcel A`row' = "`M'"
        putexcel B`row' = "`y'"
        putexcel C`row' = "perception Δ"
        putexcel D`row' = (r(F))
        putexcel E`row' = (r(p))
        putexcel F`row' = (e(N))
        local ++row
    }
    foreach y in info tax mandate {
        quietly regress pol_supp_`y'_t_effect b1.treat_effect_3##c.`M' if treat_assign==1
        quietly test 2.treat_effect_3#c.`M' 3.treat_effect_3#c.`M'
        putexcel A`row' = "`M'"
        putexcel B`row' = "`y'"
        putexcel C`row' = "policy support"
        putexcel D`row' = (r(F))
        putexcel E`row' = (r(p))
        putexcel F`row' = (e(N))
        local ++row
    }
}

// =====================================================================
// (5) Manipulation check — accordion timing (vars absent)
// =====================================================================
putexcel set "`xlsx'", sheet("manip_accordion_timing") modify
putexcel A1 = "Accordion timing variables (q32_intro3_t, q32_intro5_t) not present in this dataset; manipulation check therefore relies on prior beliefs (see tables/balance_tests.xlsx)."

di as txt _n "==> SI items written."
