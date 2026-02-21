/****************************************************************************************
 Master's thesis   : Governance and Renewable Energy Production in WAEMU
 Author    : Brun-Urick TCHOUKOU
 Institution: University of Abomey-Calavi
 Software  : Stata 16
****************************************************************************************/

version 16.0
clear all
set more off
set linesize 255

/****************************************************************************************
 1. Project directories
****************************************************************************************/

* Define project root directory 
global project_dir "C:\Users\LENOVO\Documents\PLAN II\Mémoire"

* Define data file
global data_file "$project_dir\Classeur2.xlsx"

* Set working directory
cd "$project_dir"

* Start log file
capture log close
log using "analysis_log.smcl", replace

/****************************************************************************************
 2. Data import and panel declaration
****************************************************************************************/

display "---- Importing data ----"

import excel "$data_file", sheet("Feuil4") firstrow clear

* To ensure country variable is string before encoding
capture confirm string variable country
if _rc == 0 {
    encode country, gen(country_id)
}
else {
    rename country country_id
}

* Declare panel structure
xtset country_id year

/****************************************************************************************
 3. Descriptive statistics
****************************************************************************************/

display "---- Descriptive statistics ----"

* Define list of raw variables
global rawvars REP CC GE PV RL RQ VA FDI EG GFCF OPEN GDPC DF EYS POP CO2 ICT IND

* Check variable existence before summary
foreach var of global rawvars {
    capture confirm variable `var'
    if _rc != 0 {
        display as error "`var' not found in dataset"
    }
}

summarize $rawvars, detail

/****************************************************************************************
 4. Variable transformations
****************************************************************************************/

display "---- Variable transformations ----"

*-----------------------------
* 4.1 Log transformations
*-----------------------------

global logvars GFCF POP IND DF EYS ICT GDPC REP CO2 OPEN

foreach var of global logvars {

    capture confirm variable `var'
    if _rc == 0 {
        gen ln`var' = log(`var') if `var' > 0
        label variable ln`var' "Log of `var'"
    }
}

*-----------------------------
* 4.2 Inverse hyperbolic sine
*-----------------------------

capture confirm variable FDI
if _rc == 0 {
    gen ihs_FDI = asinh(FDI)
    label variable ihs_FDI "Inverse hyperbolic sine of FDI"
}

*-----------------------------
* 4.3 Time trend
*-----------------------------

gen ttrend = year
label variable ttrend "Linear time trend"

*-----------------------------
* 4.4 Check transformed vars
*-----------------------------

summarize lnGFCF lnPOP lnIND lnDF lnEYS lnICT lnGDPC lnREP lnCO2 lnOPEN ihs_FDI

/****************************************************************************************
 5. First Differences (ΔX_it = X_it − X_it−1)
****************************************************************************************/

display "---- Generating first differences ----"

* Ensure panel structure is declared
xtset

* Define variables for first differencing
global diffvars REP CC GE PV RL RQ VA FDI EG GFCF OPEN GDPC DF EYS POP CO2 ICT IND ///
               lnREP ihs_FDI lnGFCF lnOPEN lnGDPC lnDF lnEYS lnPOP lnCO2 lnICT lnIND

foreach var of global diffvars {

    capture confirm variable `var'
    
    if _rc == 0 {
        gen d_`var' = D.`var'
        label variable d_`var' "First difference of `var'"
    }
    else {
        display as error "`var' not found — differencing skipped."
    }
}

/****************************************************************************************
 6. Cross-Sectional Dependence and Panel Unit Root Tests
    Methodology:
    - Pesaran (2007) CIPS test
    - Pesaran CADF test
****************************************************************************************/

display "============================================================"
display "SECTION 6: Cross-sectional dependence & Unit root tests"
display "============================================================"

*--------------------------------------------------------------*
* 6.0 Ensure required packages are installed
*--------------------------------------------------------------*

capture which xtcips
if _rc ssc install xtcips, replace

capture which pescadf
if _rc ssc install pescadf, replace

* Ensure panel structure
xtset

*--------------------------------------------------------------*
* 6.1 Variables to test
*--------------------------------------------------------------*

global testvars lnREP CC GE PV EG lnDF lnGFCF lnCO2 lnOPEN lnGDPC ICT lnEYS lnPOP lnIND ihs_FDI

/****************************************************************************************
 6.2 Pesaran (2007) CIPS test – Level (I(0))
****************************************************************************************/

display "---- CIPS test at levels ----"

foreach var of global testvars {

    capture confirm variable `var'
    if _rc == 0 {
        di "--------------------------------------------------"
        di "CIPS test (level) for `var'"
        xtcips `var', maxlags(1) bglags(1)
    }
}

/****************************************************************************************
 6.3 Pesaran (2007) CIPS test – First difference (I(1))
****************************************************************************************/

display "---- CIPS test at first differences ----"

foreach var of global testvars {

    capture confirm variable `var'
    if _rc == 0 {
        di "--------------------------------------------------"
        di "CIPS test (first difference) for `var'"
        xtcips D.`var', maxlags(2) bglags(1)
    }
}

/****************************************************************************************
 6.4 Pesaran CADF test – Level (I(0))
****************************************************************************************/

display "---- CADF test at levels ----"

foreach var of global testvars {

    capture confirm variable `var'
    if _rc == 0 {
        di "--------------------------------------------------"
        di "CADF test (level) for `var'"
        pescadf `var', lags(1)
    }
}

/****************************************************************************************
 6.5 Pesaran CADF test – First difference (I(1))
****************************************************************************************/

display "---- CADF test at first differences ----"

foreach var of global testvars {

    capture confirm variable `var'
    if _rc == 0 {
        di "--------------------------------------------------"
        di "CADF test (first difference) for `var'"
        pescadf D.`var', lags(1)
    }
}

/****************************************************************************************
 7. Panel Cointegration Tests
     - Pedroni (1999, 2004)
     - Kao (1999)
     - Westerlund (2007)
****************************************************************************************/

display "============================================================"
display "SECTION 7: Panel Cointegration Tests"
display "============================================================"

*--------------------------------------------------------------*
* 7.0 Ensure panel structure
*--------------------------------------------------------------*

xtset country_id year

*--------------------------------------------------------------*
* 7.1 Define model specifications
*--------------------------------------------------------------*

/*
Model A: Institutional quality + macro controls
Model B: Institutional quality + structural controls
*/

global model_CC_A  lnREP CC lnDF lnGFCF lnCO2 lnOPEN lnGDPC
global model_CC_B  lnREP CC ICT lnGFCF lnCO2 ihs_FDI lnIND

global model_GE_A  lnREP GE lnDF lnGFCF lnCO2 lnOPEN lnGDPC
global model_GE_B  lnREP GE ICT lnGFCF lnCO2 ihs_FDI lnIND

global model_PV_A  lnREP PV lnDF lnGFCF lnCO2 lnOPEN lnGDPC
global model_PV_B  lnREP PV ICT lnGFCF lnCO2 ihs_FDI lnIND

global allmodels model_CC_A model_CC_B ///
                 model_GE_A model_GE_B ///
                 model_PV_A model_PV_B

/****************************************************************************************
 7.2 Pedroni Cointegration Test
****************************************************************************************/

display "---- Pedroni Cointegration Test ----"

foreach m of global allmodels {

    di "--------------------------------------------------"
    di "Pedroni test for specification: `m'"
    
    xtcointtest pedroni ${`m'}, trend lags(3)
}

/****************************************************************************************
 7.3 Kao Cointegration Test
****************************************************************************************/

display "---- Kao Cointegration Test ----"

foreach m of global allmodels {

    di "--------------------------------------------------"
    di "Kao test for specification: `m'"
    
    xtcointtest kao ${`m'}
}

/****************************************************************************************
 7.4 Westerlund (2007) Error-Correction-Based Test
****************************************************************************************/

* Install if needed
capture which xtwest
if _rc ssc install xtwest, replace

display "---- Westerlund Cointegration Test ----"

foreach m of global allmodels {

    foreach w in 1 2 3 {

        di "--------------------------------------------------"
        di "Westerlund test for `m' | lrwindow(`w')"
        
        xtwest ${`m'}, constant lags(1 1) lrwindow(`w')
    }
}

/****************************************************************************************
 8. Panel Cointegration Estimation – PMG / DFE (ARDL-ECM)
     Estimator : Pooled Mean Group (Pesaran, Shin & Smith, 1999)
****************************************************************************************/

display "============================================================"
display "SECTION 8: Panel ARDL – PMG Estimation"
display "============================================================"

* To ensure panel is declared
xtset country_id year

* Install xtpmg if needed
capture which xtpmg
if _rc ssc install xtpmg, replace

*--------------------------------------------------------------*
* 8.0 Define common short-run controls
*--------------------------------------------------------------*

global SR_controls d.EG d.lnDF d.lnGFCF d.CO2 d.OPEN d.lnGDPC d.lnICT ttrend
global LR_controls EG lnDF lnGFCF CO2 OPEN lnGDPC lnICT

/****************************************************************************************
 8.1 OBJECTIVE 1 – Control of Corruption (CC)
****************************************************************************************/

display "---- Objective 1: Control of Corruption (CC) ----"

* DFE estimation
xtpmg d.lnREP d.CC $SR_controls, ///
      lr(L.lnREP CC $LR_controls) ///
      ec(ec_CC) replace dfe
estimates store DFE_CC

* PMG estimation
xtpmg d.lnREP d.CC $SR_controls, ///
      lr(L.lnREP CC $LR_controls) ///
      ec(ec_CC) replace
estimates store PMG_CC

* Hausman test
hausman DFE_CC PMG_CC, sigmamore

/****************************************************************************************
 8.2 OBJECTIVE 2 – Government Effectiveness (GE)
****************************************************************************************/

display "---- Objective 2: Government Effectiveness (GE) ----"

* DFE
xtpmg d.lnREP d.GE $SR_controls, ///
      lr(L.lnREP GE $LR_controls) ///
      ec(ec_GE) replace dfe
estimates store DFE_GE

* PMG
xtpmg d.lnREP d.GE $SR_controls, ///
      lr(L.lnREP GE $LR_controls) ///
      ec(ec_GE) replace
estimates store PMG_GE

* Hausman
hausman DFE_GE PMG_GE, sigmamore

/****************************************************************************************
 8.3 OBJECTIVE 3 – Political Stability (PV)
****************************************************************************************/

display "---- Objective 3: Political Stability (PV) ----"

* DFE
xtpmg d.lnREP d.PV $SR_controls, ///
      lr(L.lnREP PV $LR_controls) ///
      ec(ec_PV) replace dfe
estimates store DFE_PV

* PMG
xtpmg d.lnREP d.PV $SR_controls, ///
      lr(L.lnREP PV $LR_controls) ///
      ec(ec_PV) replace
estimates store PMG_PV

* Hausman
hausman DFE_PV PMG_PV, sigmamore

/****************************************************************************************
 9. Fully Modified OLS (FMOLS) and Dynamic OLS (DOLS) Panel Estimates
****************************************************************************************/

display "============================================================"
display "SECTION 9: FMOLS / DOLS Estimation"
display "============================================================"

* Ensure panel
xtset country_id year

* Install required packages if missing
capture which xtcointreg
if _rc ssc install xtcointreg, replace

capture which esttab
if _rc ssc install estout, replace

capture which xtgcause
if _rc ssc install xtgcause, replace

*--------------------------------------------------------------*
* 9.0 Define governance variables and controls
*--------------------------------------------------------------*

global gov_vars CC GE PV
global controls EG lnDF lnGFCF lnCO2 lnOPEN lnGDPC ICT lnEYS lnIND ihs_FDI

*--------------------------------------------------------------*
* 9.1 FMOLS & DOLS estimation
*--------------------------------------------------------------*

foreach gvar of global gov_vars {

    display "--------------------------------------------------"
    display "FMOLS & DOLS estimation with `gvar'"
    
    * FMOLS
    xtcointreg lnREP `gvar' $controls, est(fmols) full
    estimates store fmols_`gvar'
    
    * DOLS
    xtcointreg lnREP `gvar' $controls, est(dols) full
    estimates store dols_`gvar'
}

*--------------------------------------------------------------*
* 9.2 Tables with p-values
*--------------------------------------------------------------*

foreach gvar of global gov_vars {

    esttab fmols_`gvar' dols_`gvar', ///
        b(2) p(2) star(* 0.10 ** 0.05 *** 0.01) ///
        stats(N r2 r2_a, fmt(0 2 2)) ///
        mtitle("FMOLS-`gvar'" "DOLS-`gvar'") ///
        title("Comparaison FMOLS/DOLS - `gvar'")
}

* Combined table synthèse
esttab fmols_CC fmols_GE fmols_PV dols_CC dols_GE dols_PV, ///
    b(2) p(2) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CC GE PV) ///
    stats(N r2 r2_a, fmt(0 2 2)) ///
    mtitle("FMOLS-CC" "FMOLS-GE" "FMOLS-PV" "DOLS-CC" "DOLS-GE" "DOLS-PV") ///
    title("Synthèse des effets des variables de gouvernance")

* Export RTF publication-ready
esttab fmols_CC fmols_GE fmols_PV using "resultats_fmols_pvalues.rtf", ///
    replace b(2) p(2) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, fmt(0 2 2)) ///
    title("Résultats FMOLS avec p-values")

esttab dols_CC dols_GE dols_PV using "resultats_dols_pvalues.rtf", ///
    replace b(2) p(2) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, fmt(0 2 2)) ///
    title("Résultats DOLS avec p-values")

*--------------------------------------------------------------*
* 9.3 Panel Granger causality tests
*--------------------------------------------------------------*

foreach gvar of global gov_vars {

    display "==================================================="
    display "Causality of `gvar' vers lnREP"
    display "==================================================="

    forvalues lag = 1/3 {
        xtgcause lnREP `gvar', lags(`lag')
    }
    
    display "Causalité inverse: lnREP vers `gvar'"
    forvalues lag = 1/3 {
        xtgcause `gvar' lnREP, lags(`lag')
    }
}

/****************************************************************************************
 10. Dumitrescu & Hurlin (2012) Panel Causality Tests
****************************************************************************************/

display "============================================================"
display "SECTION 10: Dumitrescu & Hurlin Causality Tests"
display "============================================================"

* To ensure panel is declared
xtset country_id year

* Install xtgcause if missing
capture which xtgcause
if _rc ssc install xtgcause, replace

*--------------------------------------------------------------*
* 10.1 Governance variables -> lnREP
*--------------------------------------------------------------*

local governance_vars CC GE PV RL RQ VA

display "---- Causality: Governance variables with lnREP ----"

foreach gvar of local governance_vars {

    display "==================================================="
    display "Dumitrescu-Hurlin causality: `gvar' with lnREP"
    display "==================================================="

    forvalues lag = 1/3 {
        xtgcause lnREP `gvar', lags(`lag')
    }

    display "Dumitrescu-Hurlin causality: lnREP with `gvar'"
    forvalues lag = 1/3 {
        xtgcause `gvar' lnREP, lags(`lag')
    }

    display "---------------------------------------------------"
}

*--------------------------------------------------------------*
* 10.2 Control variables with lnREP
*--------------------------------------------------------------*

local control_vars lnIND lnGDPC lnPOP OPEN EG ihs_FDI lnGFCF lnEYS CO2 lnDF ICT

display "---- Causality: Control variables with lnREP ----"

foreach cvar of local control_vars {

    display "---------------------------------------------------"
    display "Dumitrescu-Hurlin causality: `cvar' with lnREP"
    xtgcause lnREP `cvar', lags(1)
}

*--------------------------------------------------------------*
* 10.3 Create a results table
*--------------------------------------------------------------*
estimates clear

foreach gov in CC GE PV RL RQ VA {
    quietly xtgcause lnREP `gov', lags(1)
    estimates store `gov'_to_rep
    quietly xtgcause `gov' lnREP, lags(1)
    estimates store rep_to_`gov'
}

*--------------------------------------------------------------*
* 10.4 Export the results
*--------------------------------------------------------------*
esttab *_to_rep using "causalite_governance_rep.rtf", ///
cells("b(fmt(4)) p(fmt(4))") replace title("Governance Causality with REP")

esttab rep_to_* using "causalite_rep_governance.rtf", ///
cells("b(fmt(4)) p(fmt(4))") replace title("REP causality with Governance")

log close