// =====================================================================
// RnR_helpers.do
// ---------------------------------------------------------------------
// PURPOSE : Shared programs re-sourced by each analysis script.
// INPUTS  : (none)
// OUTPUTS : (defines programs tost_eq, bky_qvalues)
// AUTHOR  : E. Keith Smith   |   DATE: 2026-09-18   |   STATA: 19.5
// NOTE    : Run via master.do (sets wd once); relative paths only.
// =====================================================================

// =====================================================================
// RnR_helpers.do — programs used across the RnR analysis files.
// Re-sourced at the top of each consumer .do file so they remain in
// memory when files are run individually.
// =====================================================================

// Two one-sided tests for equivalence (normal approx, large n).
capture program drop tost_eq
program define tost_eq, rclass
    syntax , Coef(real) SE(real) SESOI(real)
    if `se' <= 0 {
        return scalar tost_p = .
        return scalar equiv_bound = .
        exit
    }
    local p_lower = 1 - normal((`coef' + `sesoi')/`se')
    local p_upper = 1 - normal((`sesoi' - `coef')/`se')
    local tost_p = max(`p_lower', `p_upper')
    local equiv_bound = abs(`coef') + 1.645*`se'
    return scalar tost_p = `tost_p'
    return scalar equiv_bound = `equiv_bound'
end

// Sharpened BKY two-stage q-values (Anderson 2008 style).
capture program drop bky_qvalues
program define bky_qvalues
    syntax varname, Generate(name)
    tempvar pvar rank q1 q2 mreject
    qui gen double `pvar' = `varlist'
    qui count if !missing(`pvar')
    local m = r(N)
    if `m' == 0 {
        qui gen double `generate' = .
        exit
    }
    sort `pvar'
    qui gen long `rank' = _n if !missing(`pvar')
    qui gen double `q1' = `pvar' * `m' / `rank' if !missing(`pvar')
    qui replace `q1' = min(`q1', 1)
    forvalues i = `=`m'-1'(-1)1 {
        qui replace `q1' = min(`q1'[`=`i'+1'], `q1'[`i']) in `i'
    }
    qui gen byte `mreject' = `q1' <= 0.05/1.05 if !missing(`pvar')
    qui sum `mreject'
    local m0_hat = `m' - r(sum)
    if `m0_hat' < 1 local m0_hat = 1
    qui gen double `q2' = `pvar' * `m0_hat' / `rank' if !missing(`pvar')
    qui replace `q2' = min(`q2', 1)
    forvalues i = `=`m'-1'(-1)1 {
        qui replace `q2' = min(`q2'[`=`i'+1'], `q2'[`i']) in `i'
    }
    qui gen double `generate' = `q2'
end
