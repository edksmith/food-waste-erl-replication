// =====================================================================
// RnR_10_SI_heterogeneity.do
// ---------------------------------------------------------------------
// PURPOSE : SI heterogeneity figures.
//           Fig A3: env_att moderator on perception change scores.
//           Figs A4/A5/A6: prior-belief moderators (vol/gov/busi) x
//           (plan_industry/plan_effective/plan_goal), treat_action_state==2.
// INPUTS  : data/_analysis_data.dta
// OUTPUTS : output/figures/figA3_HTE_envatt.pdf
//           output/figures/figA4_HTE_priors_vol.pdf  (voluntary measures)
//           output/figures/figA5_HTE_priors_gov.pdf  (government measures)
//           output/figures/figA6_HTE_priors_busi.pdf (non-participating firms)
//           output/tables/SI_heterogeneity_envatt.xlsx
//           output/tables/SI_heterogeneity_priors.xlsx
// AUTHOR  : E. Keith Smith
// DATE    : 2026-09-18   |   STATA: 19.5
// NOTE    : Working directory / scheme are set in master.do; relative
//           paths only. Does not modify any main analysis file.
// =====================================================================

set more off

qui do "scripts/RnR_helpers.do"
use "data/_analysis_data.dta", clear

// Map perception outcome -> paper SI figure number (vol=A4, gov=A5, busi=A6)
local fnum_vol  A4
local fnum_gov  A5
local fnum_busi A6

local ti_vol  "Voluntary measures are sufficient"
local ti_gov  "Government measures are needed"
local ti_busi "Food businesses should be forced to reduce"

// Shorter outcome labels for the multi-panel grids (avoid title overlap).
local sti_vol  "Voluntary sufficient"
local sti_gov  "Government needed"
local sti_busi "Businesses forced"

// =====================================================================
// A. env_att moderator — SI Figure A3
// =====================================================================
local mod_label_envatt "Pro-environmental attitudes (z-score)"
quietly sum env_att if treat_action_state==2
local env_min = -2
local env_max = 2
local env_step = (`env_max' - `env_min')/8

foreach y in vol gov busi {
    quietly regress state_`y'_t_effect b1.treat_effect_3##c.env_att ///
        if treat_action_state==2
    scalar N_envatt_`y' = e(N)
    quietly test 2.treat_effect_3#c.env_att 3.treat_effect_3#c.env_att
    scalar F_envatt_`y' = r(F)
    scalar pF_envatt_`y' = r(p)
    quietly margins, dydx(treat_effect_3) ///
        at(env_att=(`env_min'(`env_step')`env_max'))
    marginsplot, ///
        ti("{bf:`ti_`y''}", s(small)) ///
        xtitle("`mod_label_envatt'", s(small)) ///
        ytitle("AME on Δ perception", s(small)) ///
        ylab(-.10(0.05).10, format(%3.2f) labs(small)) ///
        xlab(, format(%4.1f) labs(small)) ///
        yline(0, lc(gs10) lp(dash)) ///
        plot1opts(lc(maroon) mc(maroon)) ///
        ci1opts(lc(maroon) recast(rline) lp(dash)) ///
        plot2opts(lc(forest_green) mc(forest_green)) ///
        ci2opts(lc(forest_green) recast(rline) lp(dash)) ///
        legend(order(3 "Will not achieve goal" 4 "Will achieve goal") ///
               rows(1) pos(6) si(small)) ///
        name(siA2_`y', replace) nodraw
}

grc1leg2 siA2_vol siA2_gov siA2_busi, ///
    ti("{bf:Heterogeneity in feedback effects}" "{bf:by `mod_label_envatt'}", s(small)) ///
    rows(3) xsize(8) ysize(11) name(siA2, replace)

gr export "output/figures/figA3_HTE_envatt.pdf", as(pdf) name("siA2") replace

// ---------- Tables: one sheet per outcome ----------
local xlsx_e "output/tables/SI_heterogeneity_envatt.xlsx"
capture rm "`xlsx_e'"

// Margins gives, at each moderator value, the AME of negative and positive
// frames vs no-frame reference. Use 9 grid points for the table.
local env_step_tab = (`env_max' - `env_min')/8

local first_sheet = 1
foreach y in vol gov busi {
    quietly regress state_`y'_t_effect b1.treat_effect_3##c.env_att ///
        if treat_action_state==2
    quietly margins, dydx(treat_effect_3) ///
        at(env_att=(`env_min'(`env_step_tab')`env_max')) post
    matrix R = r(table)
    if `first_sheet' == 1 {
        putexcel set "`xlsx_e'", sheet("`y'") replace
        local first_sheet = 0
    }
    else {
        putexcel set "`xlsx_e'", sheet("`y'") modify
    }
    putexcel A1 = "SI Fig A3 - env_att moderator, outcome: Δ`y' (FW akt=1)"
    local f_str  = strofreal(F_envatt_`y', "%6.3f")
    local pf_str = strofreal(pF_envatt_`y', "%6.4f")
    local nn_str = strofreal(N_envatt_`y')
    local note = "Joint interaction F = `f_str', p = `pf_str', n = `nn_str'"
    putexcel A2 = "`note'"
    putexcel A4 = "Moderator value (env_att)"
    putexcel B4 = "Treatment arm"
    putexcel C4 = "AME"
    putexcel D4 = "SE"
    putexcel E4 = "95% CI lower"
    putexcel F4 = "95% CI upper"
    putexcel G4 = "n"
    // dydx with 3-level factor (base=1) at 9 at points yields 27 columns:
    // positions 1-9 = level 1 (omitted), 10-18 = level 2 (negative), 19-27 = level 3 (positive).
    local row = 5
    forvalues j = 1/9 {
        local atval = `env_min' + (`j'-1) * `env_step_tab'
        // negative (level 2): column 9 + j
        local k = 9 + `j'
        putexcel A`row' = (`atval')
        putexcel B`row' = "Will not achieve goal vs no-frame"
        putexcel C`row' = (R[1,`k'])
        putexcel D`row' = (R[2,`k'])
        putexcel E`row' = (R[5,`k'])
        putexcel F`row' = (R[6,`k'])
        putexcel G`row' = (N_envatt_`y')
        local ++row
        // positive (level 3): column 18 + j
        local k = 18 + `j'
        putexcel A`row' = (`atval')
        putexcel B`row' = "Will achieve goal vs no-frame"
        putexcel C`row' = (R[1,`k'])
        putexcel D`row' = (R[2,`k'])
        putexcel E`row' = (R[5,`k'])
        putexcel F`row' = (R[6,`k'])
        putexcel G`row' = (N_envatt_`y')
        local ++row
    }
}

di as txt _n "==> SI Figure A3 (env_att) + table written."

// =====================================================================
// B. Prior-belief moderators — SI Figures A4-A6 (3 × 3 grid)
// =====================================================================

local priors plan_industry plan_effective plan_goal
local prior_label_plan_industry  "Industry will reduce FW"
local prior_label_plan_effective "Plan will be effective"
local prior_label_plan_goal      "Plan will achieve 50% goal"

foreach y in vol gov busi {
    foreach p of local priors {
        quietly regress state_`y'_t_effect b1.treat_effect_3##c.`p' ///
            if treat_action_state==2
        scalar N_`y'_`p' = e(N)
        quietly test 2.treat_effect_3#c.`p' 3.treat_effect_3#c.`p'
        scalar F_`y'_`p' = r(F)
        scalar pF_`y'_`p' = r(p)
        quietly margins, dydx(treat_effect_3) at(`p'=(0 0.25 0.5 0.75 1))
        marginsplot, ///
            ti("{bf:`prior_label_`p''}", s(small)) ///
            ytitle("AME on Δ perception", s(small)) ///
            ylab(-.15(0.05).15, format(%3.2f) labs(small)) ///
            xlab(0(0.25)1, labs(small) format(%3.2f)) ///
			xti("") ///
            yline(0, lc(gs10) lp(dash)) ///
            plot1opts(lc(maroon) mc(maroon)) ///
            ci1opts(lc(maroon) recast(rline) lp(dash)) ///
            plot2opts(lc(forest_green) mc(forest_green)) ///
            ci2opts(lc(forest_green) recast(rline) lp(dash)) ///
            legend(order(3 "Will not achieve goal" 4 "Will achieve goal") ///
                   rows(1) pos(6) si(small)) ///
            name(siA3_`y'_`p', replace) nodraw
    }
grc1leg2 ///
    siA3_`y'_plan_industry  siA3_`y'_plan_effective  siA3_`y'_plan_goal ///
	, ti("{bf:Heterogeneity in feedback effects}" ///
		"{bf:on `ti_`y''}" ///
         "{bf:by prior beliefs}", s(medium)) ///
    rows(3) xsize(8) ysize(11) name(siA3_`y', replace)

local fnum "`fnum_`y''"   // vol->A4, gov->A5, busi->A6
gr export "output/figures/fig`fnum'_HTE_priors_`y'.pdf", as(pdf) name("siA3_`y'") replace

}


// ---------- Long-format table + joint F-tests ----------
local xlsx_p "output/tables/SI_heterogeneity_priors.xlsx"
capture rm "`xlsx_p'"

putexcel set "`xlsx_p'", sheet("AMEs_long") replace
putexcel A1 = "SI Figs A4-A6 - AMEs by outcome × prior × moderator value × frame, FW akt=1"
putexcel A3 = "Outcome"
putexcel B3 = "Prior moderator"
putexcel C3 = "Moderator value"
putexcel D3 = "Treatment arm"
putexcel E3 = "AME"
putexcel F3 = "SE"
putexcel G3 = "95% CI lower"
putexcel H3 = "95% CI upper"
putexcel I3 = "n"
local row = 4

foreach y in vol gov busi {
    foreach p of local priors {
        quietly regress state_`y'_t_effect b1.treat_effect_3##c.`p' ///
            if treat_action_state==2
        quietly margins, dydx(treat_effect_3) ///
            at(`p'=(0 0.25 0.5 0.75 1)) post
        matrix R = r(table)
        // 5 at points × 3 levels = 15 columns. Cols 1-5: level 1 (omitted),
        // 6-10: level 2 (negative), 11-15: level 3 (positive).
        local atvals 0 0.25 0.5 0.75 1
        forvalues j = 1/5 {
            local av : word `j' of `atvals'
            // Negative
            local k = 5 + `j'
            putexcel A`row' = "`y'"
            putexcel B`row' = "`p'"
            putexcel C`row' = (`av')
            putexcel D`row' = "Will not achieve goal vs no-frame"
            putexcel E`row' = (R[1,`k'])
            putexcel F`row' = (R[2,`k'])
            putexcel G`row' = (R[5,`k'])
            putexcel H`row' = (R[6,`k'])
            putexcel I`row' = (N_`y'_`p')
            local ++row
            // Positive
            local k = 10 + `j'
            putexcel A`row' = "`y'"
            putexcel B`row' = "`p'"
            putexcel C`row' = (`av')
            putexcel D`row' = "Will achieve goal vs no-frame"
            putexcel E`row' = (R[1,`k'])
            putexcel F`row' = (R[2,`k'])
            putexcel G`row' = (R[5,`k'])
            putexcel H`row' = (R[6,`k'])
            putexcel I`row' = (N_`y'_`p')
            local ++row
        }
    }
}

// Joint F-tests for each model
putexcel set "`xlsx_p'", sheet("joint_F_tests") modify
putexcel A1 = "SI Figs A4-A6 - Joint interaction F-tests, FW akt=1"
putexcel A3 = "Outcome"
putexcel B3 = "Prior moderator"
putexcel C3 = "F"
putexcel D3 = "p"
putexcel E3 = "n"
local row = 4
foreach y in vol gov busi {
    foreach p of local priors {
        putexcel A`row' = "`y'"
        putexcel B`row' = "`p'"
        putexcel C`row' = (F_`y'_`p')
        putexcel D`row' = (pF_`y'_`p')
        putexcel E`row' = (N_`y'_`p')
        local ++row
    }
}

di as txt _n "==> SI Figures A4-A6 (priors) + table written."
