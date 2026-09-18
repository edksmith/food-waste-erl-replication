// =====================================================================
// RnR_04_fig4.do
// ---------------------------------------------------------------------
// PURPOSE : Figure 4 - awareness & effectiveness effects on policy support.
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/figures/fig04_policy_support.*; output/tables/fig04_results.xlsx
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_04_fig4.do — Fig 4: effects on demand for stronger policy
// Panel A: awareness AMEs on pol_supp_y_t_info (burden vs FW no-frame)
//   for y in {info, tax, mandate}. n ≈ 3,295 vs ~1,110
// Panel B: feedback AMEs on pol_supp_y_t_effect (within FW, b1.treat_effect)
//   y in {info, tax, mandate}
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

local xlsx "output/tables/fig04_results.xlsx"
capture rm "`xlsx'"

// ====================== Panel A: awareness on policy support =======
foreach y in info tax mandate {
    quietly regress pol_supp_`y'_t_info i.treat_action_policy
    quietly margins, dydx(treat_action_policy) post
    matrix R_fig4a_`y' = r(table)
    scalar N_fig4a_`y' = e(N)
    est sto fig4a_`y'
}

coefplot ///
    (fig4a_info,    recast(bar) col(edkblue%70)     ciopts(recast(rcap) lc(black))) ///
    (fig4a_tax,     recast(bar) col(forest_green%70) ciopts(recast(rcap) lc(black))) ///
    (fig4a_mandate, recast(bar) col(maroon%70)      ciopts(recast(rcap) lc(black))) ///
    , vert barw(0.25) ///
    ti("{bf:Food-waste policy}" "{bf:awareness treatment}", s(medlarge)) ///
    yti("AME (policy info vs no info)") ///
    xlab(0.5 " " 1.5 " ") ///
    ylab(-.10(0.02).10, format(%3.2f)) ///
    yli(0, lc(gs10) lp(dash)) ///
    legend(order(2 "Information" "& Disclosures" ///
                 4 "Taxes" "& Charges" ///
                 6 "Mandates" "& Obligations") ///
           pos(6) row(1) si(small)) ///
    caption("{bf:a)}", pos(10) ring(12) size(small)) ///
    name(fig4a, replace) nodraw

putexcel set "`xlsx'", sheet("panelA_awareness") replace
putexcel A1 = "Fig 4 Panel A - Awareness (FW info vs burden) on policy support"
putexcel A3 = "Outcome"
putexcel B3 = "Contrast"
putexcel C3 = "AME (b)"
putexcel D3 = "SE"
putexcel E3 = "t"
putexcel F3 = "p"
putexcel G3 = "Lower 95% CI"
putexcel H3 = "Upper 95% CI"
putexcel I3 = "TOST p (SESOI=0.02)"
putexcel J3 = "Bound ruled out"
putexcel K3 = "n"

local row = 4
foreach y in info tax mandate {
    matrix R = R_fig4a_`y'
    local cn : colnames R
    local k : list posof "1.treat_action_policy" in cn
    if `k' == 0 local k 1
    local b  = R[1,`k']
    local se = R[2,`k']
    local t  = R[3,`k']
    local p  = R[4,`k']
    local ll = R[5,`k']
    local ul = R[6,`k']
    local nn = N_fig4a_`y'
    tost_eq, coef(`b') se(`se') sesoi(0.02)
    local tp = r(tost_p)
    local eb = r(equiv_bound)
    putexcel A`row' = "`y'"
    putexcel B`row' = "FW info vs burden"
    putexcel C`row' = (`b')
    putexcel D`row' = (`se')
    putexcel E`row' = (`t')
    putexcel F`row' = (`p')
    putexcel G`row' = (`ll')
    putexcel H`row' = (`ul')
    putexcel I`row' = (`tp')
    putexcel J`row' = (`eb')
    putexcel K`row' = (`nn')
    local ++row
}

// ====================== Panel B: effectiveness on policy support ====
// Use b1.treat_effect: reference is "FW no-frame" (treat_effect==1).
// Missingness restricts to FW. Contrasts: 2 vs 1, 3 vs 1.
foreach y in info tax mandate {
    quietly regress pol_supp_`y'_t_effect b1.treat_effect
    quietly margins, dydx(treat_effect) post
    matrix R_fig4b_`y' = r(table)
    scalar N_fig4b_`y' = e(N)
    est sto fig4b_`y'
}

coefplot ///
    (fig4b_info,    recast(bar) col(edkblue%70)     ciopts(recast(rcap) lc(black))) ///
    (fig4b_tax,     recast(bar) col(forest_green%70) ciopts(recast(rcap) lc(black))) ///
    (fig4b_mandate, recast(bar) col(maroon%70)      ciopts(recast(rcap) lc(black))) ///
    , vert barw(0.25) ///
    keep(2.treat_effect 3.treat_effect) ///
    ti("{bf:Effectiveness treatment}" "{bf:(Δbetween)}", s(medlarge)) ///
    yti("AME (Treatments vs control (no treatment))") ///
    coeflabels(2.treat_effect = `""Will not" "achieve goal""' ///
               3.treat_effect = `""Will" "achieve goal""') ///
    ylab(-.10(0.02).10, format(%3.2f)) ///
    yli(0, lc(gs10) lp(dash)) ///
    legend(order(2 "Information" "& Disclosures" ///
                 4 "Taxes" "& Charges" ///
                 6 "Mandates" "& Obligations") ///
           pos(6) row(1) si(small)) ///
    caption("{bf:b)}", pos(10) ring(12) size(small)) ///
    name(fig4b, replace) nodraw

putexcel set "`xlsx'", sheet("panelB_effectiveness") modify
putexcel A1 = "Fig 4 Panel B - Effectiveness (vs FW no-frame) on policy support, FW only"
putexcel A3 = "Outcome"
putexcel B3 = "Contrast"
putexcel C3 = "AME (b)"
putexcel D3 = "SE"
putexcel E3 = "t"
putexcel F3 = "p"
putexcel G3 = "Lower 95% CI"
putexcel H3 = "Upper 95% CI"
putexcel I3 = "TOST p (SESOI=0.02)"
putexcel J3 = "Bound ruled out"
putexcel K3 = "n"

local row = 4
foreach y in info tax mandate {
    matrix R = R_fig4b_`y'
    local cn : colnames R
    foreach con in 2 3 {
        local k : list posof "`con'.treat_effect" in cn
        local b  = R[1,`k']
        local se = R[2,`k']
        local t  = R[3,`k']
        local p  = R[4,`k']
        local ll = R[5,`k']
        local ul = R[6,`k']
        local nn = N_fig4b_`y'
        tost_eq, coef(`b') se(`se') sesoi(0.02)
        local tp = r(tost_p)
        local eb = r(equiv_bound)
        local clabel = cond(`con'==2, "Will not achieve goal vs no-frame", "Will achieve goal vs no-frame")
        putexcel A`row' = "`y'"
        putexcel B`row' = "`clabel'"
        putexcel C`row' = (`b')
        putexcel D`row' = (`se')
        putexcel E`row' = (`t')
        putexcel F`row' = (`p')
        putexcel G`row' = (`ll')
        putexcel H`row' = (`ul')
        putexcel I`row' = (`tp')
        putexcel J`row' = (`eb')
        putexcel K`row' = (`nn')
        local ++row
    }
}

// ====================== Combine and export =========================
graph combine fig4a fig4b, col(2) xsize(8) ysize(4) name(fig4, replace)
gr export "output/figures/fig04_policy_support.pdf", as(pdf) name("fig4") replace
gr export "output/figures/fig04_policy_support.png", as(png) name("fig4") replace

di as txt _n "==> Fig 4 + tables written."
