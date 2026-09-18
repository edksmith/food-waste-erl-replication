// =====================================================================
// RnR_03_fig3.do
// ---------------------------------------------------------------------
// PURPOSE : Figure 3 - awareness & effectiveness effects on perceptions.
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/figures/fig03_perceptions.*; output/tables/fig03_results.xlsx
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_03_fig3.do — Fig 3: effects on perceptions of voluntary measures
// Panel A: awareness AMEs on state_y_t_info (FW akt=1 vs FW akt=0)
// Panel B: effectiveness/feedback AMEs on state_y_t_effect (Δ within FW)
// Also: F-test of mean change vs zero in treat_effect_3==1 (control)
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

local xlsx "output/tables/fig03_results.xlsx"
capture rm "`xlsx'"

// ====================== Panel A: awareness =========================
foreach y in vol gov busi {
    quietly regress state_`y'_t_info i.treat_action_state
    quietly margins, dydx(treat_action_state) post
    matrix R_fig3a_`y' = r(table)
    scalar N_fig3a_`y' = e(N)
    est sto fig3a_`y'
}

coefplot ///
    (fig3a_vol,   recast(bar) col(sand%70)   ciopts(recast(rcap) lc(black))) ///
    (fig3a_gov,   recast(bar) col(sienna%70) ciopts(recast(rcap) lc(black))) ///
    (fig3a_busi,  recast(bar) col(teal%70)   ciopts(recast(rcap) lc(black))) ///
    , vert barw(0.25) ///
    ti("{bf:Food-waste policy}" "{bf:awareness treatment}", s(medlarge)) ///
    yti("AME (policy info vs no info)") ///
    xlab(0.5 " " 1.5 " ") ///
    ylab(-.10(0.02).10, format(%3.2f)) ///
    yli(0, lc(gs10) lp(dash)) ///
    legend(order(2 "Voluntary measures" "are sufficient" ///
                 4 "Government measures" "are needed" ///
                 6 "Non-participating firms" "required to reduce waste") ///
           pos(6) row(1) si(small)) ///
    caption("{bf:a)}", pos(10) ring(12) size(small)) ///
    name(fig3a, replace) nodraw

// Write Panel A numbers
putexcel set "`xlsx'", sheet("panelA_awareness") replace
putexcel A1 = "Fig 3 Panel A - Awareness (Food-waste info vs no info)"
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
foreach y in vol gov busi {
    matrix R = R_fig3a_`y'
    local cn : colnames R
    local k : list posof "2.treat_action_state" in cn
    if `k' == 0 local k 1
    local b  = R[1,`k']
    local se = R[2,`k']
    local t  = R[3,`k']
    local p  = R[4,`k']
    local ll = R[5,`k']
    local ul = R[6,`k']
    local nn = N_fig3a_`y'
    tost_eq, coef(`b') se(`se') sesoi(0.02)
    local tp = r(tost_p)
    local eb = r(equiv_bound)
    putexcel A`row' = "`y'"
    putexcel B`row' = "FW info vs FW no info"
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

// ====================== Panel B: effectiveness/feedback ============
foreach y in vol gov busi {
    quietly regress state_`y'_t_effect b1.treat_effect_3
    quietly margins, dydx(treat_effect_3) post
    matrix R_fig3b_`y' = r(table)
    scalar N_fig3b_`y' = e(N)
    est sto fig3b_`y'
}

// Layout: for each outcome, plot two bars (negative vs control, positive vs control).
// Use coefplot with three model series (one per outcome), keeping both contrasts.
coefplot ///
    (fig3b_vol,  recast(bar) col(sand%70)   ciopts(recast(rcap) lc(black))) ///
    (fig3b_gov,  recast(bar) col(sienna%70) ciopts(recast(rcap) lc(black))) ///
    (fig3b_busi, recast(bar) col(teal%70)   ciopts(recast(rcap) lc(black))) ///
    , vert barw(0.25) ///
    ti("{bf:Effectiveness treatment}" "{bf:(ΔPost-Pre)}", s(medlarge)) ///
    yti("AME (Treatments vs control (no treatment))") ///
    coeflabels(2.treat_effect_3 = `""Will not" "achieve goal""' ///
               3.treat_effect_3 = `""Will" "achieve goal""') ///
    ylab(-.10(0.02).10, format(%3.2f)) ///
    yli(0, lc(gs10) lp(dash)) ///
    legend(order(2 "Voluntary measures" "are sufficient" ///
                 4 "Government measures" "are needed" ///
                 6 "Non-participating firms" "required to reduce waste") ///
           pos(6) row(1) si(small)) ///
    caption("{bf:b)}", pos(10) ring(12) size(small)) ///
    name(fig3b, replace) nodraw

putexcel set "`xlsx'", sheet("panelB_effectiveness") modify
putexcel A1 = "Fig 3 Panel B - Effectiveness/feedback AMEs on within-person Δ (Q32-Q31), FW only"
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
foreach y in vol gov busi {
    matrix R = R_fig3b_`y'
    local cn : colnames R
    foreach con in 2 3 {
        local k : list posof "`con'.treat_effect_3" in cn
        local b  = R[1,`k']
        local se = R[2,`k']
        local t  = R[3,`k']
        local p  = R[4,`k']
        local ll = R[5,`k']
        local ul = R[6,`k']
        local nn = N_fig3b_`y'
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

// ====================== F-test: mean change vs zero, control arm =====
putexcel set "`xlsx'", sheet("controlArm_meanChange") modify
putexcel A1 = "Mean within-person change in perceptions (Δ Q32-Q31) within control arm (treat_effect_3==1, no effectiveness frame)"
putexcel A3 = "Outcome"
putexcel B3 = "Mean Δ"
putexcel C3 = "SE"
putexcel D3 = "t"
putexcel E3 = "df"
putexcel F3 = "p (H0: Δ=0)"
putexcel G3 = "n"
local row = 4
foreach y in vol gov busi {
    quietly ttest state_`y'_t_effect == 0 if treat_effect_3 == 1
    putexcel A`row' = "`y'"
    putexcel B`row' = (r(mu_1))
    putexcel C`row' = (r(sd)/sqrt(r(N_1)))
    putexcel D`row' = (r(t))
    putexcel E`row' = (r(df_t))
    putexcel F`row' = (r(p))
    putexcel G`row' = (r(N_1))
    local ++row
}

// ====================== Combine and export =========================
graph combine fig3a fig3b, col(2) xsize(8) ysize(4) name(fig3, replace)
gr export "output/figures/fig03_perceptions.pdf", as(pdf) name("fig3") replace
gr export "output/figures/fig03_perceptions.png", as(png) name("fig3") replace

di as txt _n "==> Fig 3 + tables written."
