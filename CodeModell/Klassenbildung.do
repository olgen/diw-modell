#delimit;
/*Ausgeben der Einkommensklassen vorbereiten*/
/* Untergrenze Jahreslohn */
scalar ugrenz = 500;

/* Bildung Lohnklassen */


gen lohnkeink = 0;
capture program drop lohnklassen;
program lohnklassen;
gen lohnklass = 0;
  replace lohnklass =  0 if lohnkeink <  ugrenz;
  replace lohnklass =  1 if lohnkeink >= ugrenz;
  replace lohnklass =  2 if lohnkeink >=   5000;
  replace lohnklass =  3 if lohnkeink >=   9000;
  replace lohnklass =  4 if lohnkeink >=  15000;
  replace lohnklass =  5 if lohnkeink >=  21000;
  replace lohnklass =  6 if lohnkeink >=  25000;
  replace lohnklass =  7 if lohnkeink >=  31000;
  replace lohnklass =  8 if lohnkeink >=  35000;
  replace lohnklass =  9 if lohnkeink >=  41000;
  replace lohnklass = 10 if lohnkeink >=  45000;
  replace lohnklass = 11 if lohnkeink >=  51000;
  replace lohnklass = 12 if lohnkeink >=  61000;
  replace lohnklass = 13 if lohnkeink >=  71000;
  replace lohnklass = 14 if lohnkeink >=  85000;
  replace lohnklass = 15 if lohnkeink >= 101000;
  replace lohnklass = 16 if lohnkeink >= 121000;
  replace lohnklass = 17 if lohnkeink >= 121000;

end;

/* Loehne Mann */
gen lohn = ekuenfflohn;
replace lohn = 0 if lohn <= ugrenz;
gen d_lohn = 0;
replace d_lohn = 1 if lohn > 0;
bys V05001: egen d_lohn_hh=sum(d_lohn);
replace lohnkeink = lohn;
lohnklassen;
rename lohnklass lohnklass_ind;

gen lohn_hh = ekuenfflohn_hh;
replace lohn_hh = 0 if lohn <= ugrenz;
replace lohnkeink = lohn_hh;
lohnklassen;
rename lohnklass lohnklass_hh;

scalar ugrenzgesich = 1;
gen gsichklass = 0;
gen gsicherung = 0;
capture program drop gsichklassen;
program gsichklassen;

  replace gsichklass =  0 if gsicherung <  ugrenzgesich;
  replace gsichklass =  1 if gsicherung >= ugrenzgesich;
  replace gsichklass =  2 if gsicherung >=   20;
  replace gsichklass =  3 if gsicherung >=   50;
  replace gsichklass =  4 if gsicherung >=  100;
  replace gsichklass =  5 if gsicherung >=  200;
  replace gsichklass =  6 if gsicherung >=  300;
  replace gsichklass =  7 if gsicherung >=  400;
  replace gsichklass = 8 if gsicherung >=  500;
  replace gsichklass = 9 if gsicherung >=  600;
  replace gsichklass = 10 if gsicherung >=  700;
  replace gsichklass = 11 if gsicherung >=  800;
  replace gsichklass = 12 if gsicherung >=  900;
  replace gsichklass = 13 if gsicherung >= 1000;
  replace gsichklass = 14 if gsicherung >= 2000;
  replace gsichklass = 15 if gsicherung >= 3000;
  replace gsichklass = 16 if gsicherung >= 4000;
  replace gsichklass = 17 if gsicherung >= 5000;
  replace gsichklass = 18 if gsicherung >= 6000;
  replace gsichklass = 19 if gsicherung >= 7000;
  replace gsichklass = 20 if gsicherung >= 8000;
  replace gsichklass = 21 if gsicherung >= 9000;
 

end;

generate shtransg=shtrans*12;
generate uhalthhg=uhalthh*12;
generate wohngldg=wohngld*12;

gen gsich = algII+shtransg+kizu+uhalthhg+wohngldg;
replace gsich = 0 if gsich <= ugrenzgesich;
gen d_gsich = 0;
replace d_gsich = 1 if gsich > 0;
replace gsicherung = gsich;
gsichklassen;

/* Bildung Grundsicherungsklassen */
/* Untergrenze Jahreslohn */
scalar ugrenzgesich1 = 1;
gen gsichklass1 = 0;
gen gsicherung1 = 0;
capture program drop gsichklassen1;
program gsichklassen1;

  replace gsichklass1 =  0 if gsicherung1 <  ugrenzgesich1;
  replace gsichklass1 =  1 if gsicherung1 >= ugrenzgesich1;
  replace gsichklass1 =  2 if gsicherung1 >=   20;
  replace gsichklass1 =  3 if gsicherung1 >=   50;
  replace gsichklass1 =  4 if gsicherung1>=  100;
  replace gsichklass1 =  5 if gsicherung1 >=  200;
  replace gsichklass1 =  6 if gsicherung1 >=  300;
  replace gsichklass1 =  7 if gsicherung1 >=  400;
  replace gsichklass1 = 8 if gsicherung1>=  500;
  replace gsichklass1 = 9 if gsicherung1 >=  600;
  replace gsichklass1 = 10 if gsicherung1 >=  700;
  replace gsichklass1 = 11 if gsicherung1 >=  800;
    replace gsichklass1 = 12 if gsicherung1 >=  900;
  replace gsichklass1 = 13 if gsicherung1 >= 1000;
  replace gsichklass1 = 14 if gsicherung1 >= 2000;
   replace gsichklass1 = 15 if gsicherung1 >= 3000;
 replace gsichklass1 = 16 if gsicherung1 >= 4000;
  replace gsichklass1 = 17 if gsicherung1 >= 5000;
   replace gsichklass1 = 18 if gsicherung1 >= 6000;
    replace gsichklass1 = 19 if gsicherung1 >= 7000;
	 replace gsichklass1 = 20 if gsicherung1 >= 8000;
	  replace gsichklass1 = 21 if gsicherung1 >= 9000;

end;


foreach var in algII shtransg kizu uhalthhg wohngldg {;
/* Bildung Grundsicherungsklassen */
/* Untergrenze Jahreslohn */
scalar ugrenzgesich = 1;
gen `var'klass = 0;

/* Loehne Mann */

gen d_`var' = 0;
replace d_`var' = 1 if `var' > 0;
  replace `var'klass =  0 if `var' <  ugrenzgesich;
  replace `var'klass =  1 if `var' >= ugrenzgesich;
  replace `var'klass =  2 if `var' >=   20;
  replace `var'klass =  3 if `var' >=   50;
  replace `var'klass =  4 if `var' >=  100;
  replace `var'klass =  5 if `var' >=  200;
  replace `var'klass =  6 if `var' >=  300;
  replace `var'klass =  7 if `var' >=  400;
  replace `var'klass = 8 if `var' >=  500;
  replace `var'klass = 9 if `var' >=  600;
  replace `var'klass = 10 if `var' >=  700;
  replace `var'klass = 11 if `var' >=  800;
  replace `var'klass = 12 if `var' >=  900;
  replace `var'klass = 13 if `var' >= 1000;
  replace `var'klass = 14 if `var' >= 2000;
  replace `var'klass = 15 if `var' >= 3000;
  replace `var'klass = 16 if `var' >= 4000;
  replace `var'klass = 17 if `var' >= 5000;
  replace `var'klass = 18 if `var' >= 6000;
  replace `var'klass = 19 if `var' >= 7000;
  replace `var'klass = 20 if `var' >= 8000;
  replace `var'klass = 21 if `var' >= 9000;


};
/* Bildung Grundsicherungsklassen */
/* Untergrenze Jahreslohn */
bys V05001: egen altermin=min(alter) if famstat==1;
scalar ugrenzgealter = 16;
gen alterklass = 0;
gen altererung = 0;
capture program drop alterklassen;
program alterklassen;

  replace alterklass =  0 if altermin <  ugrenzgealter;
  replace alterklass =  1 if altermin >= ugrenzgealter;
  replace alterklass =  2 if altermin >=   36;
  replace alterklass =  3 if altermin >=   46;
  replace alterklass =  4 if altermin>=  56;
  replace alterklass =  5 if altermin >=  66;
  replace alterklass =  6 if altermin >=  76;


end;

/* Loehne Mann */

replace altermin = 0 if altermin <= ugrenzgesich1;
gen d_alter = 0;
replace d_alter = 1 if alter > 0;

alterklassen;


bys V05001: egen eink_stpfl = sum(zveokfb) if famstat==1 & HVPa==1&(V05001==V05001[_n+1]|V05001==V05001[_n-1] );
replace eink_stpfl=0 if V10002==1;

gen     ek_klass = 0;
replace ek_klass = 1 if eink_stpfl <    8652*2; /*Grundfreibetrag */
replace ek_klass = 2 if eink_stpfl >=   8652*2; /* bis 25 Prozent Grenzbelast. */
replace ek_klass = 3 if eink_stpfl >=  16000*2; /* bis 30 Prozent Grenzbelast. */
replace ek_klass = 4 if eink_stpfl >=  27000*2; /* bis 35 Prozent Grenzbelast. */
replace ek_klass = 5 if eink_stpfl >=  38200*2; /* bis 42 Prozent Grenzbelast. */
replace ek_klass = 6 if eink_stpfl >=  53665*2; /* bis 45 Prozent Grenzbelast. */
 /* 45 Prozent Grenzbelast. (Reichenst.) */
