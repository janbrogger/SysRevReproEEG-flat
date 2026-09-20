version 18
clear all
set more off
set scheme stcolor, permanently

* Set working directory - adjust path as needed for your system
* The script assumes working directory is 6Manuscript2/v6/

cap log close


cd "C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6"
local logfile "3log/recalc van donselaar 1992 unfiltered schouten"
log using "`logfile'.smcl", replace
pwd


// ================================================================
// VAN DONSELAAR 1992 -- Design-corrected kappa, revision 2
//
// DIFFERENCES FROM "recalc van donselaar 1992.do":
//
// 1. NO mean-pairwise-kappa pre-filter. The original script kept
//    only distributions with mean pairwise kappa in [0.495, 0.505]
//    before applying the thesis-table constraints. But the
//    published kappa=0.50 is Schouten's group kappa,
//    (mean Po - mean Pe)/(1 - mean Pe), and the thesis-table
//    constraints fix mean Po (=472/600) while the marginals fix
//    mean Pe, so every distribution satisfying the thesis table
//    already reproduces the published 0.50 EXACTLY. The pre-filter
//    was a stricter condition than the published data warrant and
//    could clip the feasible set. Here the thesis constraints are
//    applied to the FULL enumerated set.
//
// 2. Weighted group kappa reported in the SCHOUTEN convention
//    (ratio of means: (mean Po_w - mean Pe_w)/(1 - mean Pe_w)),
//    matching the convention behind the published unweighted 0.50,
//    instead of the mean of the six pairwise weighted kappas.
//    Both are computed for comparison.
//
// Epileptiform discharges: yes/no, 4 raters, 50 EEGs
// ================================================================
//
// WHY NOT ENUMERATE ALL 16-CELL DISTRIBUTIONS THEN FILTER?
// The unconstrained count of non-negative integer vectors summing
// to 50 across 16 cells is C(65,15) ~ 4.5x10^11 rows.
// At 64 bytes/row that is ~29 terabytes -- not storable, not
// generatable. Stata's practical .dta ceiling is ~2 GB.
//
// SOLUTION: impose the 4 marginal constraints + total DURING
// generation. This reduces the system to 5 free integer parameters,
// enumerable via nested loops in Mata. The 6 pairwise "both-yes"
// cells (a-values) are the intermediate quantities linking the
// outer (a-value) loop to the inner (free-parameter) loop.
// ================================================================

clear all
set more off

// ================================================================
// STEP 1: Known constants from van Donselaar 1992
// ================================================================

// Positive counts per observer (EEGs rated "epileptiform: yes")
// A=10, B=13 (R.-J.S., the pre-classifier: he coded ALL EEGs,
// blinded to clinical information, and the stratified sample was
// drawn from his categories), C=17, D=20
local MA = 10
local MB = 13
local MC = 17
local MD = 20
local N  = 50

local MA_neg = 40
local MB_neg = 37
local MC_neg = 33
local MD_neg = 30

// Reported pairwise kappa range across all 6 observer pairs
local kappa_lo = 0.27
local kappa_hi = 0.62

di as text "Known constants:"
di as text "  n(EEGs)=" as result `N' as text ///
   "  A+=" as result `MA' as text ///
   "  B+=" as result `MB' as text ///
   "  C+=" as result `MC' as text ///
   "  D+=" as result `MD'
di as text "  Pairwise kappa range: [" as result `kappa_lo' ///
   as text ", " as result `kappa_hi' as text "]"

// ================================================================
// STEP 2: Pairwise chance agreement Pe -- FIXED by marginals
// Pe_ij = (ni_pos*nj_pos + ni_neg*nj_neg) / N^2
// These are constants; they do not vary across distributions
// ================================================================

local Pe_AB = (`MA'*`MB'  + `MA_neg'*`MB_neg') / (`N'^2)
local Pe_AC = (`MA'*`MC'  + `MA_neg'*`MC_neg') / (`N'^2)
local Pe_AD = (`MA'*`MD'  + `MA_neg'*`MD_neg') / (`N'^2)
local Pe_BC = (`MB'*`MC'  + `MB_neg'*`MC_neg') / (`N'^2)
local Pe_BD = (`MB'*`MD'  + `MB_neg'*`MD_neg') / (`N'^2)
local Pe_CD = (`MC'*`MD'  + `MC_neg'*`MD_neg') / (`N'^2)

di as text _newline "Pairwise Pe (fixed by marginals -- these never change):"
foreach pair in AB AC AD BC BD CD {
    di as text "  Pe_`pair' = " as result %6.4f `Pe_`pair''
}

// Mean pairwise Pe -- constant, needed for Schouten group kappa
local Pe_mean = (`Pe_AB'+`Pe_AC'+`Pe_AD'+`Pe_BC'+`Pe_BD'+`Pe_CD') / 6
di as text "  Pe_mean = " as result %6.4f `Pe_mean'

// ================================================================
// STEP 3: Feasible integer range of each pairwise both-yes cell
//
// For pair (i,j) with marginals ni+, nj+, n=50:
//   d  = N - ni+ - nj+ + a        (both-no cell)
//   Po = (a + d) / N              (observed agreement)
//   kappa = (Po - Pe) / (1-Pe)
//
// Solving for a given kappa:
//   a = [ N*(kappa*(1-Pe) + Pe) - (N - ni+ - nj+) ] / 2
//
// a_min = ceil(a at kappa=kappa_lo), bounded below by max(0, ni++nj+-N)
// a_max = floor(a at kappa=kappa_hi), bounded above by min(ni+,nj+)
//
// NOTE: pair marginals defined BEFORE the loop to avoid brace-
// counting conflict with Stata's foreach parser. Never use inline
// { } on if statements inside a foreach block.
// ================================================================

local ni_AB = `MA'
local nj_AB = `MB'
local ni_AC = `MA'
local nj_AC = `MC'
local ni_AD = `MA'
local nj_AD = `MD'
local ni_BC = `MB'
local nj_BC = `MC'
local ni_BD = `MB'
local nj_BD = `MD'
local ni_CD = `MC'
local nj_CD = `MD'

foreach pair in AB AC AD BC BD CD {
    local ni = `ni_`pair''
    local nj = `nj_`pair''

    local base = `N' - `ni' - `nj'
    local cap  = min(`ni', `nj')

    local a_`pair'_min = max(0, ceil( ///
        (`N'*(`kappa_lo'*(1-`Pe_`pair'')+`Pe_`pair'') - `base') / 2))
    local a_`pair'_max = min(`cap', floor( ///
        (`N'*(`kappa_hi'*(1-`Pe_`pair'')+`Pe_`pair'') - `base') / 2))
}

di as text _newline "Feasible range of both-yes cell (a) per pair:"
foreach pair in AB AC AD BC BD CD {
    di as text "  a_`pair' in [" as result `a_`pair'_min' ///
       as text ", " as result `a_`pair'_max' as text "]"
}

local n_outer = 1
foreach pair in AB AC AD BC BD CD {
    local n_outer = `n_outer' * (`a_`pair'_max' - `a_`pair'_min' + 1)
}
di as text _newline "Max outer-loop (a-value) combinations: " as result `n_outer'

// ================================================================
// STEP 4: Enumerate valid 16-cell distributions (Mata)
//
// CELL DECOMPOSITION
// ------------------
// Digit order in cell names: A B C D (1=yes, 0=no)
//
// k=4 (all yes):  n1111  <- free parameter q
// k=3 (3 yes):    n1110 n1101 n1011 n0111  <- free: tABC tABD tACD tBCD
// k=2 (2 yes):    n1100 n1010 n1001 n0110 n0101 n0011  <- derived
// k=1 (1 yes):    n1000 n0100 n0010 n0001  <- derived from marginals
// k=0 (all no):   n0000  <- derived from total=50
//
// DERIVATION OF 2-WAY CELLS FROM a-VALUES AND FREE PARAMETERS:
//   pAB = ab_a - tABC - tABD - q
//   pAC = ac_a - tABC - tACD - q
//   pAD = ad_a - tABD - tACD - q
//   pBC = bc_a - tABC - tBCD - q
//   pBD = bd_a - tABD - tBCD - q
//   pCD = cd_a - tACD - tBCD - q
//
// DERIVATION OF 1-WAY CELLS FROM MARGINALS:
//   n1000 = MA - pAB - pAC - pAD - tABC - tABD - tACD - q
//   n0100 = MB - pAB - pBC - pBD - tABC - tABD - tBCD - q
//   n0010 = MC - pAC - pBC - pCD - tABC - tACD - tBCD - q
//   n0001 = MD - pAD - pBD - pCD - tABD - tACD - tBCD - q
//
// DERIVATION OF n0000 FROM total=50:
//   n0000 = -10 + (pAB+pAC+pAD+pBC+pBD+pCD)
//               + 2*(tABC+tABD+tACD+tBCD) + 3*q
//   (where -10 = N - MA - MB - MC - MD = 50 - 60)
// ================================================================

mata:
void enumerate_vd1992(
    real scalar MA, real scalar MB, real scalar MC, real scalar MD,
    real scalar N,
    real scalar ab_lo, real scalar ab_hi,
    real scalar ac_lo, real scalar ac_hi,
    real scalar ad_lo, real scalar ad_hi,
    real scalar bc_lo, real scalar bc_hi,
    real scalar bd_lo, real scalar bd_hi,
    real scalar cd_lo, real scalar cd_hi)
{
    real scalar ab_a, ac_a, ad_a, bc_a, bd_a, cd_a
    real scalar q, q_max
    real scalar tABC, tABC_max
    real scalar tABD, tABD_max
    real scalar tACD, tACD_max
    real scalar tBCD, tBCD_max
    real scalar pAB, pAC, pAD, pBC, pBD, pCD
    real scalar n1000, n0100, n0010, n0001, n0000
    real scalar nrow, chunk
    real matrix buf

    chunk = 500000
    buf   = J(chunk, 16, .)
    nrow  = 0

    // --- Outer loop: 6 pairwise both-yes cells ---
    for (ab_a=ab_lo; ab_a<=ab_hi; ab_a++) {
    for (ac_a=ac_lo; ac_a<=ac_hi; ac_a++) {
    for (ad_a=ad_lo; ad_a<=ad_hi; ad_a++) {
    for (bc_a=bc_lo; bc_a<=bc_hi; bc_a++) {
    for (bd_a=bd_lo; bd_a<=bd_hi; bd_a++) {
    for (cd_a=cd_lo; cd_a<=cd_hi; cd_a++) {

    // --- Inner loop: 5 free parameters ---
    // q = n1111: bounded by all 6 a-values
    q_max = min((ab_a, ac_a, ad_a, bc_a, bd_a, cd_a))
    for (q=0; q<=q_max; q++) {

    // tABC = n1110: consumes from pairs AB, AC, BC
    tABC_max = min((ab_a-q, ac_a-q, bc_a-q))
    for (tABC=0; tABC<=tABC_max; tABC++) {

    // tABD = n1101: consumes from pairs AB, AD, BD
    tABD_max = min((ab_a-q-tABC, ad_a-q, bd_a-q))
    for (tABD=0; tABD<=tABD_max; tABD++) {

    // tACD = n1011: consumes from pairs AC, AD, CD
    tACD_max = min((ac_a-q-tABC, ad_a-q-tABD, cd_a-q))
    for (tACD=0; tACD<=tACD_max; tACD++) {

    // tBCD = n0111: consumes from pairs BC, BD, CD
    tBCD_max = min((bc_a-q-tABC, bd_a-q-tABD, cd_a-q-tACD))
    for (tBCD=0; tBCD<=tBCD_max; tBCD++) {

        // Derive 2-way cells
        pAB = ab_a - tABC - tABD - q
        pAC = ac_a - tABC - tACD - q
        pAD = ad_a - tABD - tACD - q
        pBC = bc_a - tABC - tBCD - q
        pBD = bd_a - tABD - tBCD - q
        pCD = cd_a - tACD - tBCD - q

        // pAD, pBD, pCD not guaranteed >= 0 by loop bounds -- check
        if (pAD<0 | pBD<0 | pCD<0) continue

        // Derive 1-way cells from marginals
        n1000 = MA - pAB - pAC - pAD - tABC - tABD - tACD - q
        n0100 = MB - pAB - pBC - pBD - tABC - tABD - tBCD - q
        n0010 = MC - pAC - pBC - pCD - tABC - tACD - tBCD - q
        n0001 = MD - pAD - pBD - pCD - tABD - tACD - tBCD - q

        if (n1000<0 | n0100<0 | n0010<0 | n0001<0) continue

        // Derive n0000 from total=50
        n0000 = -10 + pAB+pAC+pAD+pBC+pBD+pCD ///
                    + 2*(tABC+tABD+tACD+tBCD) + 3*q

        if (n0000 < 0) continue

        // Valid -- store in pattern order 0000..1111
        // Column order: n0000 n0001 n0010 n0011(=pCD)
        //               n0100 n0101(=pBD) n0110(=pBC) n0111(=tBCD)
        //               n1000 n1001(=pAD) n1010(=pAC) n1011(=tACD)
        //               n1100(=pAB) n1101(=tABD) n1110(=tABC) n1111(=q)
        nrow++
        if (nrow > rows(buf)) buf = buf \ J(chunk, 16, .)

        buf[nrow,.] = (n0000, n0001, n0010, pCD,
                       n0100, pBD,   pBC,   tBCD,
                       n1000, pAD,   pAC,   tACD,
                       pAB,   tABD,  tABC,  q)

    }}}}} // end inner loops (5: tBCD tACD tABD tABC q)
    }}}}}} // end outer loops (6: cd_a bd_a bc_a ad_a ac_a ab_a)

    buf = buf[1..nrow, .]
    st_matrix("__res__", buf)
    st_numscalar("__nrow__", nrow)
    printf("\nEnumeration complete: %g valid distributions found.\n", nrow)
}
end

// ================================================================
// STEP 5: Run the enumeration
// ================================================================

di as text _newline "Running Mata enumeration..."
mata: enumerate_vd1992(`MA',`MB',`MC',`MD',`N', ///
    `a_AB_min',`a_AB_max', `a_AC_min',`a_AC_max', ///
    `a_AD_min',`a_AD_max', `a_BC_min',`a_BC_max', ///
    `a_BD_min',`a_BD_max', `a_CD_min',`a_CD_max')

// ================================================================
// STEP 6: Load into Stata and name cell variables
// ================================================================

clear
svmat __res__

rename __res__1  n0000
rename __res__2  n0001
rename __res__3  n0010
rename __res__4  n0011
rename __res__5  n0100
rename __res__6  n0101
rename __res__7  n0110
rename __res__8  n0111
rename __res__9  n1000
rename __res__10 n1001
rename __res__11 n1010
rename __res__12 n1011
rename __res__13 n1100
rename __res__14 n1101
rename __res__15 n1110
rename __res__16 n1111

di as text "Dataset: " as result _N as text " rows x 16 cell variables."

// ================================================================
// STEP 7: Verify observer marginals (guaranteed by construction)
// ================================================================

gen obs_A_positive = n1000+n1001+n1010+n1011+n1100+n1101+n1110+n1111
gen obs_B_positive = n0100+n0101+n0110+n0111+n1100+n1101+n1110+n1111
gen obs_C_positive = n0010+n0011+n0110+n0111+n1010+n1011+n1110+n1111
gen obs_D_positive = n0001+n0011+n0101+n0111+n1001+n1011+n1101+n1111

gen check_total = n0000+n0001+n0010+n0011+n0100+n0101+n0110+n0111 ///
                + n1000+n1001+n1010+n1011+n1100+n1101+n1110+n1111

assert obs_A_positive == `MA'
assert obs_B_positive == `MB'
assert obs_C_positive == `MC'
assert obs_D_positive == `MD'
assert check_total    == `N'
di as text _newline "Marginal assertions passed: A=10, B=13, C=17, D=20, total=50."

// ================================================================
// STEP 8: Agreement-count variables (k = number of raters saying yes)
// ================================================================

gen perf_agree = n0000 + n1111
label var perf_agree "EEGs where all 4 raters agreed (both n0000 and n1111)"

gen n_k0 = n0000
gen n_k1 = n1000+n0100+n0010+n0001
gen n_k2 = n1100+n1010+n1001+n0110+n0101+n0011
gen n_k3 = n1110+n1101+n1011+n0111
gen n_k4 = n1111

assert n_k0+n_k1+n_k2+n_k3+n_k4 == 50

// ================================================================
// STEP 9: Apply thesis-table constraints to the FULL enumerated set
//
// Van Donselaar provided Table 4.1 from his PhD thesis, giving
// the exact distribution of EEGs by number of observers agreeing
// on epileptiform discharges (EPI row):
//
//   All 4 yes  (n1111)                     = 6
//   All 4 no   (n0000)                     = 25
//   Exactly 3 yes, 1 no (n_k3)             = 5
//   Exactly 1 yes, 3 no (n_k1)             = 7
//   Exactly 2 yes, 2 no (n_k2) = 50-6-25-5-7 = 7
//
// NO OTHER FILTER IS APPLIED. In particular, no filter on the
// mean pairwise kappa: the published kappa=0.50 is Schouten's
// group kappa, and the constraints above reproduce it exactly
// (verified in Step 10), so any extra kappa filter would be
// stricter than the published data warrant.
// ================================================================

di as text _newline "Rows in full enumerated set: " as result _N

keep if n1111 == 6
keep if n0000 == 25
keep if n_k3  == 5
keep if n_k1  == 7
keep if n_k2  == 7

di as text "Rows after thesis table constraints (unfiltered path): " ///
   as result _N

// ================================================================
// STEP 10: Validation -- the surviving set reproduces the
// PUBLISHED unweighted statistics exactly, for every row:
//
//   mean pairwise Po = 472/600 = 0.7867  (published: 0.79)
//   Schouten group kappa = (Po_mean - Pe_mean)/(1 - Pe_mean)
//                        = (0.78667 - 0.57613)/0.42387 = 0.4967
//                        (published: 0.50)
// ================================================================

gen Po_pairs_numerator = 12*n_k0 + 6*n_k1 + 4*n_k2 + 6*n_k3 + 12*n_k4
gen Po_mean_unw        = Po_pairs_numerator / 600
gen k_schouten_unw     = (Po_mean_unw - `Pe_mean') / (1 - `Pe_mean')

assert Po_pairs_numerator == 472
summarize Po_mean_unw k_schouten_unw, format
assert abs(k_schouten_unw - 0.4967) < 0.001
di as text "Validation passed: every surviving distribution reproduces" ///
   " Po=0.79 and Schouten group kappa=0.50 as published."

// ================================================================
// STEP 11: Pairwise 2x2 cells and unweighted pairwise kappas
// Convention: XY_a=both yes  XY_b=X yes Y no
//             XY_c=X no Y yes  XY_d=both no
// ================================================================

gen ab_a = n1100+n1101+n1110+n1111
gen ab_b = n1000+n1001+n1010+n1011
gen ab_c = n0100+n0101+n0110+n0111
gen ab_d = n0000+n0001+n0010+n0011

gen ac_a = n1010+n1011+n1110+n1111
gen ac_b = n1000+n1001+n1100+n1101
gen ac_c = n0010+n0011+n0110+n0111
gen ac_d = n0000+n0001+n0100+n0101

gen ad_a = n1001+n1011+n1101+n1111
gen ad_b = n1000+n1010+n1100+n1110
gen ad_c = n0001+n0011+n0101+n0111
gen ad_d = n0000+n0010+n0100+n0110

gen bc_a = n0110+n0111+n1110+n1111
gen bc_b = n0100+n0101+n1100+n1101
gen bc_c = n0010+n0011+n1010+n1011
gen bc_d = n0000+n0001+n1000+n1001

gen bd_a = n0101+n0111+n1101+n1111
gen bd_b = n0100+n0110+n1100+n1110
gen bd_c = n0001+n0011+n1001+n1011
gen bd_d = n0000+n0010+n1000+n1010

gen cd_a = n0011+n0111+n1011+n1111
gen cd_b = n0010+n0110+n1010+n1110
gen cd_c = n0001+n0101+n1001+n1101
gen cd_d = n0000+n0100+n1000+n1100

gen kappa_AB = ((ab_a+ab_d)/50 - `Pe_AB') / (1 - `Pe_AB')
gen kappa_AC = ((ac_a+ac_d)/50 - `Pe_AC') / (1 - `Pe_AC')
gen kappa_AD = ((ad_a+ad_d)/50 - `Pe_AD') / (1 - `Pe_AD')
gen kappa_BC = ((bc_a+bc_d)/50 - `Pe_BC') / (1 - `Pe_BC')
gen kappa_BD = ((bd_a+bd_d)/50 - `Pe_BD') / (1 - `Pe_BD')
gen kappa_CD = ((cd_a+cd_d)/50 - `Pe_CD') / (1 - `Pe_CD')

di as text _newline "=== UNWEIGHTED PAIRWISE KAPPAS (surviving set) ==="
summarize kappa_AB kappa_AC kappa_AD kappa_BC kappa_BD kappa_CD, format

save "97-donselaar\vd1992_unfiltered_thesis.dta", replace
di as text "Saved: vd1992_unfiltered_thesis.dta (" as result _N ///
   as text " rows)"

// ================================================================
// STEP 12: Horvitz-Thompson weighted kappa (exact, no gamma)
//
// The sample was stratified on epileptiform discharges as coded
// by observer B (R.-J.S.), who coded all EEGs blinded to clinical
// information; his categories defined the strata, so B=1 in the
// 16-cell pattern identifies the EPI stratum exactly.
//
// Exact sampling weights (target: per-patient prevalence on the
// standard EEG in the unselected first-seizure population,
// 19/157 epileptiform):
//   w_epi = (19/157) / (13/50)   [EPI stratum, oversampled]
//   w_neg = (138/157) / (37/50)  [non-EPI stratum, undersampled]
//
// For each pairwise 2x2, weight each EEG by its stratum weight.
// W_total = w_epi*13 + w_neg*37 is constant across all rows.
// ================================================================

scalar w_epi = (19/157) / (13/50)
scalar w_neg = (138/157) / (37/50)
di as text "w_epi = " as result w_epi
di as text "w_neg = " as result w_neg

// Sanity: total weighted N should be constant (~50)
gen W_check = w_epi*13 + w_neg*37
assert abs(W_check - w_epi*13 - w_neg*37) < 1e-10
drop W_check

// ------------------------------------------------------------------
// Pair A-B  (digits 1,2)
// (A=1,B=1) and (A=0,B=1) cells all have B=1 -> w_epi
// (A=1,B=0) and (A=0,B=0) cells all have B=0 -> w_neg
// ------------------------------------------------------------------
gen w_AB_11 = w_epi * (n1100+n1101+n1110+n1111)
gen w_AB_10 = w_neg * (n1000+n1001+n1010+n1011)
gen w_AB_01 = w_epi * (n0100+n0101+n0110+n0111)
gen w_AB_00 = w_neg * (n0000+n0001+n0010+n0011)
gen W_AB    = w_AB_11 + w_AB_10 + w_AB_01 + w_AB_00
gen Po_AB   = (w_AB_11 + w_AB_00) / W_AB
gen pA_AB   = (w_AB_11 + w_AB_10) / W_AB
gen pB_AB   = (w_AB_11 + w_AB_01) / W_AB
gen Pe_AB   = pA_AB*pB_AB + (1-pA_AB)*(1-pB_AB)
gen kw_AB   = (Po_AB - Pe_AB) / (1 - Pe_AB)

// ------------------------------------------------------------------
// Pair A-C  (digits 1,3)
// Mixed: each cell has B=0 or B=1 depending on digit 2
// ------------------------------------------------------------------
gen w_AC_11 = w_neg*(n1010+n1011) + w_epi*(n1110+n1111)
gen w_AC_10 = w_neg*(n1000+n1001) + w_epi*(n1100+n1101)
gen w_AC_01 = w_neg*(n0010+n0011) + w_epi*(n0110+n0111)
gen w_AC_00 = w_neg*(n0000+n0001) + w_epi*(n0100+n0101)
gen W_AC    = w_AC_11 + w_AC_10 + w_AC_01 + w_AC_00
gen Po_AC   = (w_AC_11 + w_AC_00) / W_AC
gen pA_AC   = (w_AC_11 + w_AC_10) / W_AC
gen pC_AC   = (w_AC_11 + w_AC_01) / W_AC
gen Pe_AC   = pA_AC*pC_AC + (1-pA_AC)*(1-pC_AC)
gen kw_AC   = (Po_AC - Pe_AC) / (1 - Pe_AC)

// ------------------------------------------------------------------
// Pair A-D  (digits 1,4)
// ------------------------------------------------------------------
gen w_AD_11 = w_neg*(n1001+n1011) + w_epi*(n1101+n1111)
gen w_AD_10 = w_neg*(n1000+n1010) + w_epi*(n1100+n1110)
gen w_AD_01 = w_neg*(n0001+n0011) + w_epi*(n0101+n0111)
gen w_AD_00 = w_neg*(n0000+n0010) + w_epi*(n0100+n0110)
gen W_AD    = w_AD_11 + w_AD_10 + w_AD_01 + w_AD_00
gen Po_AD   = (w_AD_11 + w_AD_00) / W_AD
gen pA_AD   = (w_AD_11 + w_AD_10) / W_AD
gen pD_AD   = (w_AD_11 + w_AD_01) / W_AD
gen Pe_AD   = pA_AD*pD_AD + (1-pA_AD)*(1-pD_AD)
gen kw_AD   = (Po_AD - Pe_AD) / (1 - Pe_AD)

// ------------------------------------------------------------------
// Pair B-C  (digits 2,3)
// (B=1,*) cells all have B=1 -> w_epi; (B=0,*) -> w_neg
// ------------------------------------------------------------------
gen w_BC_11 = w_epi * (n0110+n0111+n1110+n1111)
gen w_BC_10 = w_epi * (n0100+n0101+n1100+n1101)
gen w_BC_01 = w_neg * (n0010+n0011+n1010+n1011)
gen w_BC_00 = w_neg * (n0000+n0001+n1000+n1001)
gen W_BC    = w_BC_11 + w_BC_10 + w_BC_01 + w_BC_00
gen Po_BC   = (w_BC_11 + w_BC_00) / W_BC
gen pB_BC   = (w_BC_11 + w_BC_10) / W_BC
gen pC_BC   = (w_BC_11 + w_BC_01) / W_BC
gen Pe_BC   = pB_BC*pC_BC + (1-pB_BC)*(1-pC_BC)
gen kw_BC   = (Po_BC - Pe_BC) / (1 - Pe_BC)

// ------------------------------------------------------------------
// Pair B-D  (digits 2,4)
// ------------------------------------------------------------------
gen w_BD_11 = w_epi * (n0101+n0111+n1101+n1111)
gen w_BD_10 = w_epi * (n0100+n0110+n1100+n1110)
gen w_BD_01 = w_neg * (n0001+n0011+n1001+n1011)
gen w_BD_00 = w_neg * (n0000+n0010+n1000+n1010)
gen W_BD    = w_BD_11 + w_BD_10 + w_BD_01 + w_BD_00
gen Po_BD   = (w_BD_11 + w_BD_00) / W_BD
gen pB_BD   = (w_BD_11 + w_BD_10) / W_BD
gen pD_BD   = (w_BD_11 + w_BD_01) / W_BD
gen Pe_BD   = pB_BD*pD_BD + (1-pB_BD)*(1-pD_BD)
gen kw_BD   = (Po_BD - Pe_BD) / (1 - Pe_BD)

// ------------------------------------------------------------------
// Pair C-D  (digits 3,4)
// ------------------------------------------------------------------
gen w_CD_11 = w_neg*(n0011+n1011) + w_epi*(n0111+n1111)
gen w_CD_10 = w_neg*(n0010+n1010) + w_epi*(n0110+n1110)
gen w_CD_01 = w_neg*(n0001+n1001) + w_epi*(n0101+n1101)
gen w_CD_00 = w_neg*(n0000+n1000) + w_epi*(n0100+n1100)
gen W_CD    = w_CD_11 + w_CD_10 + w_CD_01 + w_CD_00
gen Po_CD   = (w_CD_11 + w_CD_00) / W_CD
gen pC_CD   = (w_CD_11 + w_CD_10) / W_CD
gen pD_CD   = (w_CD_11 + w_CD_01) / W_CD
gen Pe_CD   = pC_CD*pD_CD + (1-pC_CD)*(1-pD_CD)
gen kw_CD   = (Po_CD - Pe_CD) / (1 - Pe_CD)

// ================================================================
// STEP 13: Weighted group kappa -- SCHOUTEN CONVENTION (primary)
//
// Schouten's group kappa is the ratio of means:
//   k_group = (mean Po - mean Pe) / (1 - mean Pe)
// This matches the convention behind the published unweighted
// 0.50, so the corrected estimate is directly comparable.
//
// The mean of the six pairwise weighted kappas (mean of ratios,
// as in the original script) is kept as a secondary comparison.
// ================================================================

gen Po_group_w = (Po_AB + Po_AC + Po_AD + Po_BC + Po_BD + Po_CD) / 6
gen Pe_group_w = (Pe_AB + Pe_AC + Pe_AD + Pe_BC + Pe_BD + Pe_CD) / 6

gen kw_group_schouten = (Po_group_w - Pe_group_w) / (1 - Pe_group_w)
label var kw_group_schouten ///
    "Weighted group kappa, Schouten convention (ratio of means) -- PRIMARY"

gen kw_group_meanpairs = (kw_AB + kw_AC + kw_AD + kw_BC + kw_BD + kw_CD) / 6
label var kw_group_meanpairs ///
    "Weighted group kappa, mean of pairwise kappas -- secondary comparison"

di as text _newline "=== WEIGHTED PAIRWISE KAPPAS ==="
summarize kw_AB kw_AC kw_AD kw_BC kw_BD kw_CD, format

di as text _newline "=== WEIGHTED GROUP KAPPA, SCHOUTEN (PRIMARY RESULT) ==="
summarize kw_group_schouten, detail format

di as text _newline "=== WEIGHTED GROUP KAPPA, MEAN OF PAIRWISE (comparison) ==="
summarize kw_group_meanpairs, format

di as text _newline "=== WEIGHTED MEAN Po AND Pe ==="
summarize Po_group_w Pe_group_w, format

// ================================================================
// STEP 14: Headline numbers for the manuscript
// ================================================================

quietly summarize kw_group_schouten
di as text _newline "==============================================="
di as text "DESIGN-CORRECTED GROUP KAPPA (Schouten, unfiltered feasible set)"
di as text "  min    = " as result %6.4f r(min)
di as text "  max    = " as result %6.4f r(max)
di as text "  mean   = " as result %6.4f r(mean)
di as text "  median : see detail above"
di as text "  n distributions = " as result r(N)
di as text "==============================================="

save "97-donselaar\vd1992_weighted_kappa_schouten.dta", replace

cap log close
cap translate "`logfile'.smcl" "`logfile'.pdf"
