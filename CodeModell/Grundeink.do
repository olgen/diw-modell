/* *********************************************************************** */
/* *********************************************************************** */
/* *********************************************************************** */
/*  Stata Do-file taxinc_soepeq.do                                         */
/*  Editing database SOEP - Cross-national equivalent files                */
/*  sbach  21.08.06                                                        */
/*  updated: 04.12.19                                                      */
/* *********************************************************************** */
/* *********************************************************************** */
/* *********************************************************************** */

#delimit;
/*MWSTreform Steuersaätz*/
global MWSTreform = 1;
global USTreform = 1;

/*
version 15.1;
clear;


set more off;
set varabbrev off;
set matsize 150;

program drop _all;
macro drop _all;
capture log close;

display "$S_DATE";
display "$S_TIME";

/* Path directory */

local pathdata "J:\SOEP37\raw";
if c(username) == "sbach"
local path1 "T:\sbach\gsoep_match";
if c(username) == "bfischer"
local path1 "T:\sbach\gsoep_match";
if c(username) == "nisaak"
local path1 "T:\sbach\gsoep_match";
if c(username) == "mhamburg"
local path1 "K:\sbach\mhamburg\SonstSt";

/* *********************************************************************** */
/* ********************************************************************* */
/* Select year and wave                                                  */
/* ********************************************************************* */
/* *********************************************************************** */
 
scalar waveyear = 2020; 

if waveyear == 2020 {;
    local wave = "bk";
};
if waveyear == 2019 {;
    local wave = "bj";
};
if waveyear == 2018 {;
    local wave = "bi";
};
if waveyear == 2017 {;
    local wave = "bh";
};

di "`wave'";


/* Welle SOEP */
local j1    = string(waveyear);
local year = substr("`j1'",3,4);

di "`year'";



/* log-file */
capture log close;
/*log using `path1'\log\Grundeink`year', replace t;*/


/* Einlesen Steuern */

/* Mehrwertsteuer */
clear;
import excel using K:\sbach\mhamburg\SonstSt\Steuerlast22.xlsx, sheet(MWSt) firstrow cellrange(K8:M108) clear;
capture destring, replace float dpcomma;
mkmat regsatz ermsatz spar;
*matrix list regsatz;

/* Unternehmensteuern */

import excel using K:\sbach\mhamburg\SonstSt\Steuerlast22.xlsx, sheet(UntSt) firstrow cellrange(E8:E108) clear;
capture destring, replace float dpcomma;
mkmat untst;
*matrix list untst;


/* Grundsteuern */

import excel using K:\sbach\mhamburg\SonstSt\Steuerlast22.xlsx, sheet(GrundSt) firstrow cellrange(F8:F108) clear;
capture destring, replace float dpcomma;
mkmat grundst;
*matrix list grund;
*/

/* ************************************************************************* */
/* ************************************************************************* */
/* Tabellen fuer Vergleich mit STSM ausgeben                                 */
/* ************************************************************************* */
/* ************************************************************************* */

use Grundeink_aggr.dta, clear;
scalar regstsatz = scalar(22);
scalar ermstsatz = 7;

/* Aequivalenzgewicht in Anlehnung an neue OECD-Skala */
/* HHVorstand Gewicht 1, weitere Erwachsene und Kinder >= 15 Jahre Gewicht */
/* 0.5; Kinder <15 Gewicht von 0.3 */


rename V04005pequiv imprenth;

gen numpersh = 0;
replace numpersh = pershh - kindu14;
gen h11101 = kindu14;


gen equivschh3 = (1.0 + 0.5 *(numpersh-h11101-1) + 0.3*h11101); //???

/* Brutto- und Nettoeinkommen 
gen ekbruth = (grossinch + imprenth + sstaxh);

gen ekneth = (postgovinch + imprenth);*/


gen ekbruth = (bruttoeinkommen + vorsorg + imprenth);
gen ekneth = (hhnet*12 + imprenth);


/* Nettoaequivalenzeinkommen */
gen eknetequiv = (ekneth) / equivschh3;

/* Bruttoaequivalenzeinkommen */
gen ekbrutequiv = (ekbruth) / equivschh3;

/*Erzeugen des BruttoaequivalenzeinkommenHH*/
foreach var in eknetequiv ekbrutequiv{;
	egen `var'_hh =  sum(`var'), by(V05001);
	replace `var' = `var'_hh;
};
gen whh = hhrfk;
gen wind2 = whh*numpersh;

gen persgewicht1 = V06003 * hhrfk;
keep if V10002 == 0; /* hh level! */



/* ************************************************************************* */
/* Dezile Bruttoaequivalenzeinkommen H                                        */
/* ************************************************************************* */

_pctile ekbrutequiv [aw = persgewicht1], p(10,20,30,40,50,60,70,80,90);

gen quant2 = -99; 
gen fract2 = -99;

replace quant2 = r(r1) if ekbrutequiv <= r(r1); 
replace fract2 = 1      if ekbrutequiv <= r(r1); 

forvalues i = 2/9 {; 
  local j = `i' - 1;
  replace quant2 = r(r`i') if ekbrutequiv >  r(r`j') & ekbrutequiv <= r(r`i');
  replace fract2  = `i'    if ekbrutequiv >  r(r`j') & ekbrutequiv <= r(r`i');
};

replace quant2 = 1000000000  if ekbrutequiv > r(r9); 
replace fract2 = 10 if ekbrutequiv > r(r9); 

tab quant2 [iw = persgewicht1];
tab fract2 [iw = persgewicht1];


/* Exkurs: 100 Perzentile */

_pctile ekbrutequiv [aw = whh], nquantiles(100);

gen quant22 = -99; 
gen fract22 = -99;

replace quant22 = r(r1) if ekbrutequiv <= r(r1); 
replace fract22 = 1      if ekbrutequiv <= r(r1); 

qui forvalues i = 2/99 {; 
  local j = `i' - 1;
  replace quant22 = r(r`i') if ekbrutequiv >  r(r`j') & ekbrutequiv <= r(r`i');
  replace fract22  = `i'    if ekbrutequiv >  r(r`j') & ekbrutequiv <= r(r`i');
};

replace quant22 = 1000000000  if ekbrutequiv > r(r99); 
replace fract22 = 100 if ekbrutequiv > r(r99); 

tab quant22 [iw = persgewicht1];
tab fract22 [iw = persgewicht1];

/* Ende Exkurs 100 Perzentile */



/* Ermittlung imputierte Steuern */

local steuerlist "regsatz ermsatz spar grundst untst";
/*
foreach steuer in `steuerlist' {;

gen `steuer'q = 0; /* Quote */
gen `steuer'st = 0; /* Steuer */
forvalues i = 1/100 {; 
	replace `steuer'q = `steuer'[`i',1] if fract22 == `i';
};
	replace `steuer'st = ekneth * `steuer'q/100;
	replace `steuer'st = ekbruth * `steuer'q/100 if "`steuer'" == "untst"; 
};

rename regsatzst MWStreg;
rename ermsatzst MWSterm;
*/
if ${MWSTreform} == 1{;
	gen MWStreg_ref = MWStreg*regstsatz/19;
	gen MWSterm_ref = MWSterm*ermstsatz/7;
	gen MWSt_reg_änd = MWStreg_ref - MWStreg;
	gen MWSt_erm_änd = MWSterm_ref - MWSterm;
};

if ${USTreform} == 1{;
	scalar UST_satz_ref = 30;
	gen UST_ref = UST_satz_ref*UntSt/30;
	gen UST_ref_änd = UST_ref - UntSt;
};
/*Regelsatz für unternehmssteuersatz =30%*/

gen MWSt = MWStreg + MWSterm;

sum MWSt [iw= persgewicht1];
di r(sum)/1e9;

/*
rename untstst UntSt;
*/
sum UntSt [iw= persgewicht1];
di r(sum)/1e9;
/*
rename grundstst GrundSt;
*/
sum GrundSt [iw= persgewicht1];
di r(sum)/1e9;
/*
rename sparst Sparen;
*/
drop quant22 fract22 quant2 fract2;
keep V00001 regsatzq	MWStreg	ermsatzq	MWSterm	sparq	Sparen	grundstq	GrundSt	untstq	UntSt	MWSt imprenth MWStreg_ref MWSterm_ref MWSt_reg_änd MWSt_erm_änd;
save Grundeinkommen_durchgelaufen.dta, replace;
/*

/* ************************************************************************* */
/* Anzahl Haushalte und Personen je Haushalt                                 */
/* ************************************************************************* */

replace whh = 0.0000000001 if whh == 0;
gen numh = 1 / whh;
gen nump = numpersh / whh;


/* ************************************************************************* */
/* Tabellen ausgeben H                                                         */
/* ************************************************************************* */

/* Variablen Tabellen  */

local tabvar1 
"numpersh eknetequiv  ekbrutequiv ekneth ekbruth MWSt MWStreg MWSterm UntSt GrundSt grossinch postgovinch
businch wageinch capinch rentleasinc1h transfinch otransfinch childbenh soztransh imprenth
estsolih sstaxh 
algIh alhilfh statpenstotalh civpenstotalh comppenstotalh othpenstotalh maternbenh studgranth miltservh privtransh
housebenh ownhousebenh nurseh sozass1h sozass2h sozass3h alg2h addchildbenh iachmh edupackh asylbenh hchildbenh
";

    
gen double N = 1 / whh; /* Auszaehlen N */

/* 1. Dezile Nettoaequivalenzeinkommen */
preserve;
    collapse (mean) fract1 (count) whh (sum) `tabvar1' (sum) N [iw = whh], by(quant1) fast;
    rename quant1 quant;
    rename fract1 break;
    save `path1'/outputtab/dezileGE1.dta, replace;
restore;

/* 2. Dezile Bruttoaequivalenzeinkommen */
preserve;
    collapse (mean) fract2 (count) whh (sum) `tabvar1' (sum) N [iw = whh], by(quant2) fast;
    rename quant2 quant;
    rename fract2 break;
    save `path1'/outputtab/dezileGE2.dta, replace;
restore;

/* 3. Perzentile Bruttoaequivalenzeinkommen */
preserve;
    collapse (mean) fract22 (count) whh (sum) `tabvar1' (sum) N [iw = whh], by(quant22) fast;
    rename quant22 quant;
    rename fract22 break;
    save `path1'/outputtab/perzentileGE.dta, replace;
restore;


/* Tabellen zusammenfuegen und Wegschreiben */
preserve;
    use `path1'/outputtab/dezileGE1.dta, replace;
    /*1 Zwischenzeile:*/ local zeilen = _N + 1; set obs `zeilen';
    append using `path1'/outputtab/dezileGE2.dta;
    /*1 Zwischenzeile:*/ local zeilen = _N + 1; set obs `zeilen';
    append using `path1'/outputtab/perzentileGE.dta;
	
    export excel using `path1'/outputtab/OutputGE_`year'.xlsx, firstrow(variables) replace;
    
    erase `path1'/outputtab/dezileGE1.dta;
    erase `path1'/outputtab/dezileGE2.dta;
	erase `path1'/outputtab/perzentileGE.dta;

restore;




capture log close;
clear;

display "$S_DATE";
display "$S_TIME";
*/