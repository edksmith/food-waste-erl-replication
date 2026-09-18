// =====================================================================
// build_public_data.do
// -----------------------------------------------------------------
// PURPOSE : Derive the PUBLIC replication dataset from the restricted
//           Swiss Environmental Panel (SEP) Wave 12 merged source file.
//           Keeps only the variables used to generate the results in the
//           accepted paper (main text + SI), replaces the SEP panel
//           respondent ID with a non-linkable anonymous ID, and drops
//           geographic identifiers, exact dates, open-text and unused
//           fields.
//
// INPUTS  : upanel_w12_MERGED.dta   (RESTRICTED — not distributed;
//                                     held by the SEP team / authors)
// OUTPUTS : public_food_waste_w12.dta
//           public_food_waste_w12.csv
//
// NOTE    : This script is NOT part of the public run path (master.do).
//           Public users start from public_food_waste_w12.dta and never
//           see the restricted source. It is included only to document
//           exactly how the public file was produced.
//
// AUTHOR  : E. Keith Smith
// DATE    : 2026-09-18
// STATA   : 19.5 (StataNow SE)
// =====================================================================

version 19.5
clear all
set more off

// ---- Point this at the restricted merged source file --------------
local RESTRICTED "../../upanel_w12_MERGED.dta"   // adjust path if needed

use "`RESTRICTED'", clear
di as txt "Source rows: " _N   // expected 9,817

// =====================================================================
// 1. Keep only the variables used in the paper (main text + SI)
// =====================================================================
// Panel ID (to be anonymised) + all raw variables the analysis reads.
#delimit ;
keep
    PubId
    /* --- SI demographics & covariates (Wave 10) --- */
    w10_q2 w10_q5 w10_q53 w10_q26 w10_q40
    w10_q8x1 w10_q8x2 w10_q8x3 w10_q8x4 w10_q8x5 w10_q8x6
    w10_q8x7 w10_q8x8 w10_q8x9 w10_q8x10 w10_q8x11 w10_q8x12
    w10_q44x1 w10_q44x2 w10_q44x3 w10_q44x4
    w10_q44x5 w10_q44x6 w10_q44x7 w10_q44x8
    /* --- Treatment assignment (Wave 12) --- */
    w12_treat3 w12_treat4 w12_treat5
    /* --- Prior beliefs --- */
    w12_q28 w12_q29 w12_q30
    /* --- Perception items (voluntary / gov / business) --- */
    w12_q31x1 w12_q31x2 w12_q31x3
    w12_q32x1 w12_q32x2 w12_q32x3
    w12_q36x1 w12_q36x2 w12_q36x3
    /* --- Policy-support items (12 per block) --- */
    w12_q33x1 w12_q33x2 w12_q33x3 w12_q33x4 w12_q33x5 w12_q33x6
    w12_q33x7 w12_q33x8 w12_q33x9 w12_q33x10 w12_q33x11 w12_q33x12
    w12_q37x1 w12_q37x2 w12_q37x3 w12_q37x4 w12_q37x5 w12_q37x6
    w12_q37x7 w12_q37x8 w12_q37x9 w12_q37x10 w12_q37x11 w12_q37x12
    /* --- Top policy priority --- */
    w12_q35x1
;
#delimit cr

di as txt "Variables kept (incl. PubId): " c(k)   // expected 66

// =====================================================================
// 2. Anonymise: replace the SEP panel ID with a non-linkable ID
// =====================================================================
// The SEP PubId links a respondent across waves. We destroy that linkage
// by shuffling rows under a fixed seed and issuing a fresh sequential ID.
// Row order is irrelevant to every downstream estimator (regress / mean /
// factor / mlogit / ttest are all order-invariant), so this changes no
// result. We sort by PubId first so the shuffle is fully deterministic.
sort PubId
set seed 20240918
gen double _shuffle = runiform()
sort _shuffle
gen long anon_id = _n
label var anon_id "Anonymous respondent ID (no linkage to SEP panel or other waves)"
drop PubId _shuffle
order anon_id
sort anon_id

// =====================================================================
// 3. Save public dataset (.dta) + CSV mirror
// =====================================================================
// NB: all rows are retained (N = 9,817). The analytical sample (N = 6,586)
// is defined downstream by non-missing treatment assignment, exactly as in
// the paper. Keeping all rows preserves the exact factor-scoring sample for
// env_att / ins_trust used in the SI (Figs A1, A3-A6; Table A3).
compress
label data "Public replication data - SEP Wave 12 food-waste experiment (anonymised)"
save "public_food_waste_w12.dta", replace
// CSV mirror uses the underlying NUMERIC codes (nolabel) so it matches
// exactly what the Stata analysis reads from the .dta.
export delimited using "public_food_waste_w12.csv", replace nolabel

di as txt _n "==> Public dataset written: " _N " rows, " c(k) " variables."
