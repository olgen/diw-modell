
 // *******************************************************************************************
 // 2_Output_hh_.do
 // stsm Output auf Konzept Haushalte bringen
 // ******************************************************************************************* 
 
#delimit;
clear;
use "${MY_PROJECT_PATH}1_Simulation/1_Simulation_.dta"; //Laden der Simulation
global dezil = 1; /*0= Perzentilausgabe, 1 Dezilausgabe*/


/* Es wird das Haushaltsgewicht für alle Haushalte verwendet. */
gen gewicht = hhrfk;



replace uhalthh = uhalthh*12;


/*********************************************************************************************/
/* Erwerbsstatus*/
/*********************************************************************************************/
gen erwerbsd	= 0;
replace erwerbsd= 1 if V03023!=7 & V03023!=.;



/*********************************************************************************************/
/*Aequivalenzgewicht*/
/*********************************************************************************************/

/* in Anlehnung an neue OECD-Skala:*/
/* HHVorstand Gewicht 1, weitere Erwachsene und Kinder >= 14 Jahre Gewicht*/
/* 0.5; Kinder <14 Gewicht von 0.3*/
gen erwachs = 0;
replace erwachs = pershh - kindu14;
tab erwachs;
gen equivsc3 = 0;
replace equivsc3 = 1 + 0.5*(erwachs-1) + kindu14 * 0.3;
tab equivsc3;

/*********************************************************************************************/
/*Einkommen auf Haushaltsebene Generieren*/
/*********************************************************************************************/
sort hhnrakt V10002;

 // folgende gibts bereits:
foreach ek in ekselb soli 	{;
sum `ek'_hh [w=gewicht] if hhnrakt[_n]!=hhnrakt[_n-1];
										};
										

 // diese noch nicht:
foreach ek in sbhp soli_ks pos_steuer neg_steuer fest_est_EST spe   {;
bys hhnrakt: egen `ek'_hh = total(`ek');
sum `ek'_hh [w=gewicht] if hhnrakt[_n]!=hhnrakt[_n-1];
															};
					

/* ********************************************************************************************/
/* Festgesetzte Einkommensteuer (ohne Solidaritaetszuschlag)*/
/* ********************************************************************************************/

gen     festgest = 0;
replace festgest = fest_est_EST_hh;


label variable festgest "Festgesetzte Einkommensteuer (ohne Soli), auf Haushalte aggregiert";

/* ********************************************************************************************/
/* Kindergeld*/
/* ********************************************************************************************/
/*für alle kgkinder (mit und ohne KFB):*/
gen     kindergeld_alle = 0;


/*********************************************************************************************/
/* Haushaltsnettoeinkommen*/
/*********************************************************************************************/

/*Haushaltsnettoeinkommen:*/
gen     hhnek    = 0;
replace hhnek    = eknetto_hh; // eknetto_hh beim HV ausgewiesen

/* Haushaltsnettoäquivalenzeinkommen:*/
gen     hhnek_eq = 0;
replace hhnek_eq = eknetto_hh / equivsc3; // eknetto_hh beim HV ausgewiesen


/* ************************************************************************** */ 
*******************************************************************************
/* 					Variablen auf Haushaltsebene bringen       */
*******************************************************************************


#d;
foreach v in  erwerbsd vorsorg stipend  kizu bruttoeinkommen {;
    egen `v'_hh  = sum(`v'), by(V05001);
    sum `v'_hh [iw=gewicht] ; 
};

#delimit;
/*
label variable rente_hh "gesetzliche Rente, jährlich, aggregiert für HH";*/

egen stipendj_hh = sum(stipend), by(V05001);
/*egen selbststaendig_hh = sum(selbst), by(V05001);
label variable selbststaendig_hh "Anzahl Selbstständige im Haushalt";*/

/* steuerrelevante Renten und Pensionen insgesamt */
gen renteni_hh = ekrent_hh + ekwitw_hh;
/* steuerpflichtiger Teil der Renten und Pensionen */


/* Beduerftigkeitsgepruefte Sozialtransfers zusammenfassen */
foreach v in  wohngld algII kizu {;
    sum `v' [iw=gewicht] if `v' != 0 & `v' != .;
};

gen kgeld_hh = 0;
sort hhnrakt V10002;

 /* Partner raus: Hier bleiben also nur die Haushaltsvorstände übrig. Es ist wichtig, 
 dass die Variablen, die einen interesieren, VORHER alle beim Haushaltsvorstand summiert wurden
 */
drop if hhnrakt[_n]==hhnrakt[_n-1];

sort hhnrakt V10002;
count if V10002 == 0; /*Die Anzahl der Haushaltsvorstände gleicht der Anzahl der Beobachtungen im Datensatz */
count if V10002 != 0; /*Wenn hier nicht 0 rauskommt, stimmt was nicht */


/* ************************************************************************* */
/* Gewichtung: Personengewichte                                              */
/* ************************************************************************* */

gen pers_hh = V06003; 
label variable pers_hh "Zahl der Personen im Haushalt" ;

gen persgewicht = gewicht * pers_hh;


/* ************************************************************************* */
/* Nettoeinkommen auf Jahreswerte bringen                                    */
/* ************************************************************************* */

/*hhnek ist dieselbe Variable wie eknetto_hh */
	gen jhhnek = hhnek;
	gen jhhnek_eq = hhnek_eq;
	merge 1:1 V05001 using Input/jhhnek_eq_grecht.dta;
	drop _merge;

/* Dummy Abweichungen */

gen abweichung = .;
replace abweichung = (jhhnek_eq-jhhnek_eq_grecht)/jhhnek_eq_grecht;

gen gewinner0 = .;
gen gewinner1 = .;
gen gewinner2 = .;
gen gewinner3 = .;
gen gewinner4 = .;

replace gewinner0 = 1 if abweichung > 0.02;
replace gewinner1 = 1 if abweichung > 0.005 & abweichung <= 0.02;
replace gewinner2 = 1 if abweichung >= -0.005 & abweichung <= 0.005;
replace gewinner3 = 1 if abweichung >= -0.02 & abweichung < -0.005;
replace gewinner4 = 1 if abweichung < -0.02;

drop hhnek hhnek_eq;

/*2_Output_hh.do; 
stop; Hier schauen, wie es weitergeht. Insbesondere herausfinden, warum im 
Außerdem schauen, wie die Dezile berechnet werden! */
/* ************************************************************************* */
/* Bruttoeinkommen                                                           */
/* ************************************************************************* */
gen jhhbruek =   bruttoeinkommen_hh;
gen jhhbrek_eq = jhhbruek / equivsc3; // jhhbruek beim HV ausgewiesen

/* ************************************************************************* */
/* Armutsgrenze                                                              */
/* ************************************************************************* */

/* Medianeinkommen */
_pctile jhhnek_eq [aw = persgewicht], p(50);
di r(r1);

/* Armutsgrenze: 60 Prozent Medianeinkommen */
scalar armutsgrenze = 0.6*r(r1);
gen armutsgrenze = 0.6*r(r1);

preserve; 
keep V05001 armutsgrenze;
save ${MY_PROJECT_PATH}2_Output/armutsgrenze_grecht.dta, replace ;
restore;

/* Dummy für armutsgefährdete Haushalte */
gen armutsgef = jhhnek_eq < armutsgrenze;
tab armutsgef;


/*Verscheidene Ausgaben für das Mindestlohnprojekt */

/* Haushalte unter Armutsgrenze mit Personen im Erwerbsfähigen Alter */
gen erwerbsfarmut = 0;
replace erwerbsfarmut = 1 if armutsgef==1 & erwerbsd_hh>0;
tab erwerbsfarmut [iw=gewicht];

/* Haushalte unter Armutsgrenze mit erwerbstätigen Personen */
gen erwerbstarmut = 0;
replace erwerbstarmut = 1 if armutsgef==1 & erwerbsd_hh>0;
tab erwerbstarmut [iw=gewicht];



/* ********************************************************************************************/
/* Weitere Einkommensvariablen*/
/* *******************************************************************************************/

/* Mieteinkommen ohne Tilgungen */
gen mieteink_hh = ekmietbel; 


gen algI_hh = 0;
replace alghh = alghh*12;

/* Elterngeld */
gen elterngeld_hh = elternghh;
/* Beduerftigkeitsgepruefte Sozialtransfers */
gen algII_hh = algII;
gen kinderzuschl_hh = kizu; 
gen unterhgeld_hh = uhalthh*12;
gen wohngeld_hh = wohngld;
gen tranfser=wohngeld_hh+unterhgeld_hh+kinderzuschl_hh+algII_hh;

  // private Unterhaltszahlungen
gen unterhalt_hh = uhalthh;


/*******************************************************************************

							Generiere DEZILEBENE
							
*******************************************************************************/
/* ************************************************************************* */
/* Perzentile Nettoaequivalenzeinkommen                                      */
/* ************************************************************************* */
if ${dezil} == 0{;
	
	_pctile jhhnek_eq [aw = persgewicht], nquantiles(100);

	gen quant2 = -99; 
	gen fract2 = -99;

	replace quant2 = r(r1) if jhhnek_eq <= r(r1); 
	replace fract2 = 1      if jhhnek_eq <= r(r1); 

	qui forvalues i = 2/99 {; 
		local j = `i' - 1;
		replace quant2 = r(r`i') if jhhnek_eq >  r(r`j') & jhhnek_eq <= r(r`i');
		replace fract2  = `i'    if jhhnek_eq >  r(r`j') & jhhnek_eq <= r(r`i');
	};

	replace quant2 = 1000000000 if jhhnek_eq > r(r99); 
	replace fract2 = 100 if jhhnek_eq > r(r99); 

	/*10. Dezilobergrenze ist maximales jhhnek_eq im SOEP */
	quietly sum jhhnek_eq;
	replace quant2 = r(max) if quant2 ==1000000000;

	tab quant2 [iw = persgewicht];
	tab fract2 [iw = persgewicht];

	
	_pctile jhhnek_eq [aw = persgewicht], nquantiles(100);;

	gen quant5 = -99; 
	gen fract5 = -99;

	replace quant5 = r(r1) if jhhnek_eq <= r(r1); 
	replace fract5 = 1      if jhhnek_eq <= r(r1); 
	


	forvalues i = 2/99 {; 
		local j = `i' - 1;
		replace quant5 = r(r`i') if jhhbrek_eq >  r(r`j') & jhhbrek_eq <= r(r`i');
		replace fract5  = `i'    if jhhbrek_eq >  r(r`j') & jhhbrek_eq <= r(r`i');
	};

	replace quant5 = 1000000000  if jhhbrek_eq > r(r10); 
	replace fract5 = 100 if jhhbrek_eq > r(r10); 

	tab quant5 [iw = persgewicht];
	tab fract5 [iw = persgewicht];

	
};

#delimit;

/* ************************************************************************* */
/* Dezile Nettoaequivalenzeinkommen                                          */
/* ************************************************************************* */
if ${dezil} == 1{;

_pctile jhhnek_eq [aw = persgewicht], p(10,20,30,40,50,60,70,80,90);

gen quant2 = -99; 
gen fract2 = -99;

replace quant2 = r(r1) if jhhnek_eq <= r(r1); 
replace fract2 = 1      if jhhnek_eq <= r(r1); 

forvalues i = 2/9 {; 
  local j = `i' - 1;
  replace quant2 = r(r`i') if jhhnek_eq >  r(r`j') & jhhnek_eq <= r(r`i');
  replace fract2  = `i'    if jhhnek_eq >  r(r`j') & jhhnek_eq <= r(r`i');
};

replace quant2 = 1000000000 if jhhnek_eq > r(r9); 
replace fract2 = 10 if jhhnek_eq > r(r9); 

/*10. Dezilobergrenze ist maximales jhhnek_eq im SOEP */
quietly sum jhhnek_eq;
replace quant2 = r(max) if quant2 ==1000000000;

tab quant2 [iw = persgewicht];
tab fract2 [iw = persgewicht];

/* ************************************************************************* */
/* Dezile Nettoaequivalenzeinkommen    detailliert                           */
/* ************************************************************************* */

_pctile jhhnek_eq [aw = persgewicht], p(10,20,30,40,50,60,70,80,90,95,99,);

gen quant5 = -99; 
gen fract5 = -99;

replace quant5 = r(r1) if jhhnek_eq <= r(r1); 
replace fract5 = 1      if jhhnek_eq <= r(r1); 

forvalues i = 2/10 {; 
  local j = `i' - 1;
  replace quant5 = r(r`i') if jhhnek_eq >  r(r`j') & jhhnek_eq <= r(r`i');
  replace fract5  = `i'    if jhhnek_eq >  r(r`j') & jhhnek_eq <= r(r`i');
};

replace quant5 = 1000000000  if jhhnek_eq > r(r10); 
replace fract5 = 11 if jhhnek_eq > r(r10); 

tab quant5 [iw = persgewicht];
tab fract5 [iw = persgewicht];


};
/* ************************************************************************* */
/* Dezile Gesamtbetrags d. EinkÃ¼nfte                                         */
/* ************************************************************************* */




#delimit;
/*Speichern der Dezile unter dem geltenden Recht */


if ${dezil} == 1{;
	drop quant* fract*;
	merge 1:1 V05001 using Input/Dezile_grecht.dta;
	drop _merge;
};

if ${dezil} == 0{;
	drop quant* fract*;
	merge 1:1 V05001 using Input/Dezile_grecht_perzentil.dta;
	drop _merge;
};


/* Das Grundeinkommen ist solch ein tiefer Einschnitt, dass es sehr wahrscheinlich ist, 
dass die Dezile nach der Reform aus komplett anderen Haushalten bestehen und die Dezile
nicht mehr vergleichbar sind. Deswegen importieren wir die alten Dezile aus dem geltenden
Recht, damit auch bei der Grundeinkommensreform in jedem Dezil exakt dieselben Haushalte sind. */


gen dhhnÃ¤e = 0;
label variable dhhnÃ¤e "Durchschinttliches HaushaltsnettoÃ¤quivalenzeinkommen";
replace dhhnÃ¤e = sum(jhhnek_eq); 
replace dhhnÃ¤e = r(mean)/12;

/* ************************************************************************* */
/* Tabellen ausgeben                                                         */
/* ************************************************************************* */

/* Variablen Tabellen  */
save "2_Output/outputdata_2023", replace;

gen gewichtzve=0;
gen mtrmean5=0;
gen mtrmean2=0;


/****************************************************************************/
/*       Armuts- und Ungleichheitsmaße                                      */
/****************************************************************************/


/* Anzahl Arme */
quiet sum pers_hh [iw = gewicht] if jhhnek_eq < armutsgrenze;
di r(sum); scalar a1 = r(sum)/1e6;
gen a1 = r(sum)/1e6;

/* Bevoelkerung insgesamt */
quiet sum pers_hh [iw = gewicht];
di r(sum); scalar b1 = r(sum)/1e6;
gen b1 = r(sum)/1e6;

/* Armutsquote */
scalar armutsquote = a1/b1; di armutsquote;
gen armutsquote = a1/b1;

/* Armutslücke */
cap drop armutsabst;
gen armutsabst = .;
replace armutsabst = armutsgrenze - jhhnek_eq if jhhnek_eq < armutsgrenze;
sum armutsabst [iw = gewicht];
gen armutsluecke = r(mean);


ineqdeco jhhnek_eq [aw = persgewicht];
return list;

scalar ginicoeff = r(gini);
scalar ge0 = r(ge0);
scalar ge1 = r(ge1);
scalar ge2 = r(ge2);

gen ginicoeff = r(gini);
gen ge0 = r(ge0);
gen ge1 = r(ge1);
gen ge2 = r(ge2);


save  2_Output/outputdata_${jahr}_${splitting}${splitvar}.dta, replace;
preserve;
keep V00001 jhhbruek jhhbrek_eq quant* fract* ;
rename jhhbruek jhhbruek_${splitvar};
rename jhhbrek_eq jhhbrek_eq_${splitvar};
sort V00001;
	
 
save 2_Output/jhhbruek.dta, replace;
   
restore;

gen fract2_g = fract2;



/* *****************************************************************************
							Generiere Outputvariablen Ausgabe
*******************************************************************************/
#delimit;
local tabvar2 "jhhnek_eq	jhhbrek_eq	jhhbruek	eknetto_hh_hh	 eklohn_hh	ekselb_hh	ekzins_hh	mieteink_hh		 festgest steuer_hh  	stipendj_hh	 kgeld_hh elterngeld_hh	alghh algII_hh	grusialter	wohngld	pers_hh	bürgergeld_hh_hh	 transferek_hh	kindu18	vbzuegb_hh		uhalthh pos_steuer_hh neg_steuer_hh soli_ks_hh kindergeld_alle kgkinder kizu_hh bürgergeld transferersetzt_hh spe zveokfb"; 
	
keep `tabvar2' quant* fract*  gewicht famstat mtrmean2 mtrmean5  kgkinder gini* ge* armutsgrenze armutsquote armutsluecke;

gen double N = 1 / gewicht; /* Gibt die Anzahl der Haushalte im SOEP */

/*******************************************************************************
							Erstelle Outputblöcke 
*******************************************************************************/

/* Hochrechnung */
preserve;
collapse (mean) fract2 (count) gewicht (sum) `tabvar2'  (sum) N [iw = gewicht], by(quant2) fast;
rename quant2 Dezilobergrenze;
rename fract2 Dezilklasse;
save 2_Output/dezilesum.dta, replace;
restore;

/*Änderung der Haushalte und Personen*/

preserve;
collapse (count) gewicht (sum) gewinner0 gewinner1 gewinner2 gewinner3 gewinner4 [iw = gewicht];
save 2_Output/gewinner_hh.dta, replace;
restore;

gen persgewicht = gewicht * pers_hh;
	
preserve;
collapse (count) persgewicht (sum) gewinner0 gewinner1 gewinner2 gewinner3 gewinner4 [iw = 	persgewicht];
save 2_Output/gewinner_pers.dta, replace;
restore;

/* Ungleichheit */
preserve;
gen NN=_n;
keep ginicoeff ge0 ge1 ge2 armutsquote armutsluecke NN;
keep if NN==1;
collapse (mean) ginicoeff ge0 ge1 ge2 armutsquote armutsluecke;
save 2_Output/inequal.dta, replace;
restore;
clear;

/*Anhängen zu einer Datei*/

use 2_Output/dezilesum.dta, replace;
/*1 Zwischenzeile:*/ local zeilen = _N + 1; set obs `zeilen';
append using 2_Output/inequal.dta;
/*1 Zwischenzeile:*/ local zeilen = _N + 1; set obs `zeilen';
append using 2_Output/gewinner_hh.dta;
/*1 Zwischenzeile:*/ local zeilen = _N + 1; set obs `zeilen';
append using 2_Output/gewinner_pers.dta;

/* ****************************************************************************

							Generiere Outputtabellen

*******************************************************************************/
if  "${variante0}" == "1" & "${variante2}" == "0" & "${dezil}" == "1"{;
export excel using 2_Output/2_Output_BG_var0_dezil.xlsx, firstrow(variables) replace;
};

if   "${variante0}" == "1" & "${variante2}" == "0" & "${dezil}" == "0"{;
export excel using 2_Output/2_Output_BG_var0_perzentil.xlsx, firstrow(variables) replace;
};

if  "${variante2}" == "1" & "${variante0}" == "0" & "${dezil}" == "1" {;
export excel using 2_Output/2_Output_BG_var2_dezil.xlsx, firstrow(variables) replace;
};

if  "${variante2}" == "1" & "${variante0}" == "0" & "${dezil}" == "0" {;
export excel using 2_Output/2_Output_BG_var2_perzentil.xlsx, firstrow(variables) replace;
};

if   "${variante2}" == "0" & "${dezil}" == "1"  {;
export excel using 2_Output/2_Output_BG_var1_dezil.xlsx, firstrow(variables) replace;
};

if  "${variante0}" == "0" & "${variante2}" == "0" & "${dezil}" == "0"{;
export excel using 2_Output/2_Output_BG_var1_perzentil.xlsx, firstrow(variables) replace;
};

clear;   
cap log close;
clear all;

