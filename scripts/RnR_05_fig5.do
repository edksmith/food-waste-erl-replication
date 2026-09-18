// =====================================================================
// RnR_05_fig5.do
// ---------------------------------------------------------------------
// PURPOSE : Figure 5 - top-ranked policy priorities (distribution + mlogit AMEs).
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/figures/fig05_priorities.*; output/tables/fig05_results.xlsx
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_05_fig5.do — Fig 5: priorities
// Panel A: distribution of top_pref within treat_effect==1 (FW no-frame), ~1,110
// Panel B: mlogit top_pref b1.treat_effect_3 + margins(dydx) — FW only
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

local xlsx "output/tables/fig05_results.xlsx"
capture rm "`xlsx'"

// ====================== Panel A: distribution =====================
catplot if treat_effect==1, over(top_pref) percent vert ///
    asyvars ///
    bar(1, color(navy)) ///
    bar(2, color(maroon)) ///
    bar(3, color(forest_green)) ///
    bar(4, color(sand)) ///
    ylab(0(20)100, format(%3.1f) gmax labs(small)) ///
    yti("Percent") ///
    blabel(bar, pos(north) format(%3.1f) s(small)) ///
    leg(order(1 "Information" "& Disclosures" ///
              2 "Taxes" "& Charges" ///
              3 "Mandates" "& Obligations" ///
              4 "Continue voluntary" "action plan") ///
        row(1) pos(6) si(small)) ///
	fxsize(80) fysize(60) /// 
    caption("{bf:a)}", pos(10) ring(12) size(vsmall)) ///
    name(fig5a, replace) nodraw

// Underlying numbers for Panel A
putexcel set "`xlsx'", sheet("panelA_distribution") replace
putexcel A1 = "Fig 5 Panel A - top_pref distribution within FW no-frame arm (treat_effect==1)"
putexcel A3 = "Category"
putexcel B3 = "Label"
putexcel C3 = "Count"
putexcel D3 = "Percent"
putexcel E3 = "Total n"

quietly count if treat_effect==1 & !missing(top_pref)
scalar fig5_total = r(N)
local row = 4
local labels `" "Information & Disclosures" "Taxes & Charges" "Mandates & Obligations" "Continue voluntary action plan" "'
forvalues k = 1/4 {
    local lab : word `k' of `labels'
    quietly count if treat_effect==1 & top_pref==`k'
    local cnt = r(N)
    local pct = 100 * `cnt' / fig5_total
    putexcel A`row' = (`k')
    putexcel B`row' = "`lab'"
    putexcel C`row' = (`cnt')
    putexcel D`row' = (`pct')
    putexcel E`row' = (fig5_total)
    local ++row
}

// ====================== Panel B: mlogit margins ===================
quietly mlogit top_pref b1.treat_effect_3
margins, dydx(treat_effect_3) post
matrix R_fig5b = r(table)
scalar N_fig5b = e(N)
est sto effect_top_pref

coefplot ///
    (effect_top_pref, ///
        keep(*:1._predict) label("Information" "& Disclosures") ///
        mc(navy) ms(Oh) msize(medium) ///
        ciopts(lc(navy) recast(rcap))) ///
    (effect_top_pref, ///
        keep(*:2._predict) label("Taxes" "& Charges") ///
        mc(maroon) ms(Dh) msize(medium) ///
        ciopts(lc(maroon) recast(rcap))) ///
    (effect_top_pref, ///
        keep(*:3._predict) label("Mandates" "& Obligations") ///
        mc(forest_green) ms(Sh) msize(medium) ///
        ciopts(lc(forest_green) recast(rcap))) ///
    (effect_top_pref, ///
        keep(*:4._predict) label("Continue voluntary" "action plan") ///
        mc(sand) ms(Th) msize(medium) ///
        ciopts(lc(sand) recast(rcap))) ///
    , swapnames ///
    xline(0) xla(-0.10(0.05)0.10, format(%3.2f)) ///
    coeflabels(2.treat_effect_3 = "Will Not Achieve Goal" ///
               3.treat_effect_3 = "Will Achieve Goal") ///
    xti("AME (Treatments vs control (no treatment))") ///
    legend(rows(1) pos(6)) ///
    caption("{bf:b)}", pos(10) ring(12) size(vsmall)) ///
    name(fig5b, replace) nodraw

// Underlying numbers for Panel B
putexcel set "`xlsx'", sheet("panelB_mlogit_AMEs") modify
putexcel A1 = "Fig 5 Panel B - mlogit AMEs of treat_effect_3 (b1 reference) on top_pref, FW only"
putexcel A3 = "Predicted category"
putexcel B3 = "Contrast (treat_effect_3 vs no-frame)"
putexcel C3 = "AME (b)"
putexcel D3 = "SE"
putexcel E3 = "t"
putexcel F3 = "p"
putexcel G3 = "Lower 95% CI"
putexcel H3 = "Upper 95% CI"
putexcel I3 = "TOST p (SESOI=0.02)"
putexcel J3 = "Bound ruled out"
putexcel K3 = "n"

local catlab1 "Information & Disclosures"
local catlab2 "Taxes & Charges"
local catlab3 "Mandates & Obligations"
local catlab4 "Continue voluntary action plan"
local row = 4

matrix R = R_fig5b
local cn : colnames R
foreach c of numlist 1/4 {
    foreach e in 2 3 {
        // mlogit margins, dydx() colnames look like "1.predict:2.treat_effect_3" or
        // "2#3" — let's search the colnames for tokens matching the pattern.
        local name1 "`c'._predict:`e'.treat_effect_3"
        local name2 "`e'.treat_effect_3:`c'._predict"
        local k1 : list posof "`name1'" in cn
        local k2 : list posof "`name2'" in cn
        local k = max(`k1', `k2')
        if `k' == 0 continue
        local b  = R[1,`k']
        local se = R[2,`k']
        local t  = R[3,`k']
        local p  = R[4,`k']
        local ll = R[5,`k']
        local ul = R[6,`k']
        tost_eq, coef(`b') se(`se') sesoi(0.02)
        local tp = r(tost_p)
        local eb = r(equiv_bound)
        local clab = cond(`e'==2, "Will not achieve goal vs no-frame", "Will achieve goal vs no-frame")
        putexcel A`row' = "`catlab`c''"
        putexcel B`row' = "`clab'"
        putexcel C`row' = (`b')
        putexcel D`row' = (`se')
        putexcel E`row' = (`t')
        putexcel F`row' = (`p')
        putexcel G`row' = (`ll')
        putexcel H`row' = (`ul')
        putexcel I`row' = (`tp')
        putexcel J`row' = (`eb')
        putexcel K`row' = (N_fig5b)
        local ++row
    }
}

// Diagnostic: print actual column names for Panel B in case the heuristic missed
di as txt "Panel B mlogit margins colnames:"
matrix list R_fig5b, noheader

// ====================== Combine and export =========================
grc1leg2 fig5a fig5b, ///
    ti("{bf:Priority of food-waste policies}") ///
    subti("{it:After food-waste policy awareness treatment}", s(small)) ///
    xsize(8) name(fig5, replace)
gr export "output/figures/fig05_priorities.pdf", as(pdf) name("fig5") replace
gr export "output/figures/fig05_priorities.png", as(png) name("fig5") replace

di as txt _n "==> Fig 5 + tables written."
