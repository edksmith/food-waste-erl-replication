// =====================================================================
// RnR_02_fig2.do
// ---------------------------------------------------------------------
// PURPOSE : Figure 2 - baseline food-waste policy preferences (untreated arm).
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/figures/fig02_baseline_preferences.*; output/tables/fig02_results.xlsx
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_02_fig2.do — Fig 2: baseline preferences (burden split)
// Panel A: mean policy support (info/tax/mandate), Q37, burden split
// Panel B: mean perceptions (vol/gov/busi), Q36, burden split
// =====================================================================

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

// ---------- Panel A: policy support ----------
gr bar (mean) pol_supp_info_base pol_supp_tax_base pol_supp_mandate_base, ///
    ti("{bf:Support for stronger}" "{bf:food-waste policies}", s(large)) ///
    bar(1, col(edkblue)) bar(2, col(forest_green)) bar(3, col(maroon)) ///
    ylab(0(0.2)1, format(%3.2f) gmax labs(medium)) ///
    blabel(bar, pos(north) format(%3.2f) s(medsmall)) ///
    leg(order(1 "Information" "& Disclosures" ///
              2 "Taxes" "& Charges" ///
              3 "Mandates" "& Obligations") ///
        row(2) pos(6) si(small)) ///
    caption("{bf:a)}", pos(10) ring(12) size(medsmall)) ///
    name(fig2a, replace) nodraw

// ---------- Panel B: perceptions ----------
gr bar (mean) state_vol_base state_gov_base state_busi_base, ///
    ti("{bf:Perceptions of voluntary measures and}" "{bf:demand for government action}", s(large)) ///
    bar(1, col(sand)) bar(2, col(sienna)) bar(3, col(teal)) ///
    ylab(0(0.2)1, format(%3.2f) gmax labs(medium)) ///
    blabel(bar, pos(1) format(%3.2f) s(medsmall)) ///
    leg(order(1 "Voluntary measures" "are sufficient" ///
              2 "Government measures" "are needed" ///
              3 "Non-participating firms" "required to reduce waste") ///
        row(2) pos(6) si(small) region(style(none))) ///
    caption("{bf:b)}", pos(10) ring(12) size(medsmall)) ///
    name(fig2b, replace) nodraw

gr combine fig2a fig2b, ycomm name(fig2, replace) xsize(8)
gr export "output/figures/fig02_baseline_preferences.pdf", as(pdf) name("fig2") replace
gr export "output/figures/fig02_baseline_preferences.png", as(png) name("fig2") replace

// ---------- Underlying numbers ----------
local xlsx "output/tables/fig02_results.xlsx"
capture rm "`xlsx'"

// Panel A
putexcel set "`xlsx'", sheet("panelA_policy_support") replace
putexcel A1 = "Fig 2 Panel A - Baseline policy support means, burden split"
putexcel A3 = "Outcome"
putexcel B3 = "Mean"
putexcel C3 = "SE"
putexcel D3 = "Lower 95% CI"
putexcel E3 = "Upper 95% CI"
putexcel F3 = "n"
local row = 4
foreach y in info tax mandate {
    quietly mean pol_supp_`y'_base
    matrix b = r(table)
    putexcel A`row' = "`y'"
    putexcel B`row' = (b[1,1])
    putexcel C`row' = (b[2,1])
    putexcel D`row' = (b[5,1])
    putexcel E`row' = (b[6,1])
    putexcel F`row' = (e(N))
    local ++row
}

// Panel B
putexcel set "`xlsx'", sheet("panelB_perceptions") modify
putexcel A1 = "Fig 2 Panel B - Baseline perception means, burden split"
putexcel A3 = "Outcome"
putexcel B3 = "Mean"
putexcel C3 = "SE"
putexcel D3 = "Lower 95% CI"
putexcel E3 = "Upper 95% CI"
putexcel F3 = "n"
local row = 4
foreach y in vol gov busi {
    quietly mean state_`y'_base
    matrix b = r(table)
    putexcel A`row' = "`y'"
    putexcel B`row' = (b[1,1])
    putexcel C`row' = (b[2,1])
    putexcel D`row' = (b[5,1])
    putexcel E`row' = (b[6,1])
    putexcel F`row' = (e(N))
    local ++row
}

di as txt _n "==> Fig 2 + table written."
