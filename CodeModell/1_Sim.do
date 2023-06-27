 #delimit;
	/*******************************************************************************
							Höhe des Grundeinkommen festlegen
	*******************************************************************************/
	scalar BG = 1200; 
	scalar steuersatz = 0.5;
	scalar solisatz =0;

	/*******************************************************************************
							Festlegen der Steuervariante
	*******************************************************************************/
	global variante0 = "0";
	global variante2 = "0"; /*Variante 1 läuft durch, wenn beides auf 0 geschaltet ist*/ 
	global tarifEst = 0; /*Progressiv = 1, Flat = 0*/
	global ehegattensplitting = 0;
	global dezil = 1; /*0= Perzentilausgabe, 1 Dezilausgabe*/
	/*Anrechnungssätze, für Variante 0 sind keine vorgesehen.*/
	if "${variante0}" == "0"{;
		scalar te_star = 0.5; /*Anrechnung Erwerbeinkommen*/
		scalar tc_star = 1; /*Anrechnung Vermögenseinkommen*/
		scalar tT_star = 1; /*Anrechnung Transfereinkommen*/
	};

	if "${variante0}" == "1"{;
		scalar te_star = 0;
		scalar tc_star = 0;
		scalar tT_star = 0;
	};
	
	drop if V00001 > 24925;
	/*gen hhnet = 0;
	gen soli_hh_grecht = 0;
	gen fest_est_hh_grecht = 0;
	replace hhnet = hhnek;
	replace soli_hh_grecht = soli_hh;
	replace fest_est_hh_grecht = fest_est_hh;
	drop hhnek soli_hh fest_est_hh;
	replace soli_hh_grecht = 0 if V10002 != 0;
	replace hhnet = 0 if V10002 != 0;
	replace fest_est_hh_grecht = 0 if V10002 != 0;
	*/
	gen BGwohngld = 12*wohngld;
	
	/*******************************************************************************
								Ehegatten und Lebenspartner
	*******************************************************************************/
	/*Ehegatten für Ehegattensplitting*/
	
	preserve;
	sort V05001;
	keep if split1 == 1;
	gen ehe_dummy = 1 if  (V05001 == V05001[_n+1] | V05001 == V05001[_n-1]) & (split1 == split1[_n+1]| split1 == split1[_n-1]) & (split1 ==1) &(famstat == 1);
	sort V05001 V10002;
	egen verheiratet = seq(), f(1) b(2) by(ehe_dummy);
	replace verheiratet = . if verheiratet != 0 & ehe_dummy !=1;
	save ehegruppierung, replace; 
	restore; 
	merge 1:1 persnr using ehegruppierung;
	drop _merge;
	
	/*Lebenspartnerschaften*/
	
	preserve;
	sort V05001;
	gen lp_dummy = 1 if  (V05001 == V05001[_n+1] | V05001 == V05001[_n-1]) &(famstat == 2) & V10002 != 1;
	sort V05001 V10002;
	egen lebenspartner = seq(), f(1) b(2) by(lp_dummy);
	replace lebenspartner = . if lebenspartner != 0 & lp_dummy !=1;
	save lpgruppierung, replace; 
	restore; 
	merge 1:1 persnr using lpgruppierung;
	drop _merge;
	
	
	/******************************************************************************
	
				1. Ermittlung des Bürgergelds der Haushalte 

	*******************************************************************************/
	
	/*Im Folgenden wird das Bürgergeld der Haushalte ermittelt. Hierbei wird ermittelt, 
	wer im Haushalt eine Bedarfsgemeinschaft formt und wer nicht. */
	gen bürgergeld = scalar(BG)*12;
	replace bürgergeld = (bürgergeld + scalar(BG)*0.5*12* kindu18) if ehe_dummy !=1 & lp_dummy != 1; //Personen, die in einem HH leben, aber nicht Eherpartner/Lebenspartner sind kriegen Das volle BG + die Hälfte für jedes Kind
	replace bürgergeld = (bürgergeld + scalar(BG)*0.5*12*0.5* kindu18) if ehe_dummy ==1 | lp_dummy == 1;
	//Personen, die zusammenleben kriegen BG zur Hälfte anteilig
	replace bürgergeld = 0 if alter <=17; //Nur Personen über 18 erhalten BG, 
	egen bürgergeld_hh_hh = sum(bürgergeld), by (V05001);
	
	/******************************************************************************

				2. Ermittlung der Terme in der Steuerfunktion 

	*******************************************************************************/
	/*Werbekostenpauschale aus*/
	replace spwerba = 0;
	
	
	
	/****Erwerbseinkommen*************1. Term der Steuerfunktion */
	gen erwerbek = eklohn + ekselb + eklohn_zu + ekneben + eksndr + ekkurz + ekwintr /*+ ekabfind */ + ekahh  ;
	gen svbeiträge = vorsorg ;
	gen abzügeek = sbhp + /*sasumeinzel+ */ spwerba if erwerbek > 0  ;
	replace abzügeek = 0 if erwerbek == 0;
	replace abzügeek = erwerbek if erwerbek <=spwerba;
	gen ekrentner = ekwitw + ekrent + vbzueg;
	
	/****Vermögenseinkommen************ 2. Term der Stuerfunktion */
	gen vermögek = ekzins + ekmietbel ;
	
	
	
	/****Transfereinkommen************3. Term der Steuerfunktion*/
	gen transferek = algeld + elternghh + ekrentner;
	gen transferersetzt = algII + BGwohngld + grusialter + uhalthh*12 + stipend + kizu + kgeld; //Transfers werden ersetzt
	
	gen uhalthh12 = uhalthh*12;
	
	foreach v in algII BGwohngld  grusialter  uhalthh12  stipend  kizu  kgeld{;
	    egen `v'_hhhh = sum(`v'), by(V05001);
		replace `v'_hhhh = 0 if V10002 != 0;
		
	};
	
	/******************************************************************************

			3. Sonderbehandlung der Sozialbeiträge für arbeitende Rentner 
	
	*******************************************************************************/

	/*Für Rentner die Arbeiten werden jetzt Sozialbeiträge aus Arbeit und Sozialbeiträge
	aus Rente geschätzt (ungenau und eigentlich sollte man die getrennt simulieren) */

	gen rvbf = ekrentner/(ekrentner + erwerbek) if rentner == 1 ; /*Rentner Vorsorgebeitrags Faktor */
	/*Diesen Prozentsatz von der Vorsorge zahlen Rentner von ihrer Rente (gechätzt) */
	gen rvorsorgrente = rvbf * vorsorg if erwerbek > 0 & rentner == 1 ;
	gen rvorsorgarbeit = (1-rvbf)*vorsorg if erwerbek > 0 & rentner == 1 ;

	replace rvorsorgrente = 0 if rvorsorgrente ==.  ;
	replace rvorsorgarbeit = 0 if rvorsorgarbeit ==. ;
	/******************************************************************************

			4. Ermittlung der Steuerlast

	*******************************************************************************/
	
	
		/*******************************************************************************
						Schritt 1: Günstigerprüfung Bürgergeld
		*******************************************************************************/


		/*Wenn vom Haushalt ALGII_hh+Grusi_hh > BG_hh, dann BG_hh = ALGII_hh+Grusi_hh. 
		Das ALGII oder die Grundsicherung ist immer beim Haushaltsvorstand angesiedelt. 
		Die ganze Berechnung läuft auch über den Haushaltsvorstand oder sein Partner. 
		Dementsprechend müssen wir das Bürgergeld der Bedarfsgemeinschaft summieren (eben
		der Haushaltsvorstand und sein Partner [und eventuell Kinder]) und dieses Bürger-
		geld mit ALGII + Grusi vergleichen. Das Bürgergeld des gesamten Haushalts summieren
		wäre falsch, da dort der Betrag des Bürgergelds zu hoch wäre. */
		
		gen mindestbedarf = algII + grusialter;
		local günstigerprüfungBG = 1;
		if `günstigerprüfungBG' == 1{;
			replace bürgergeld = mindestbedarf if mindestbedarf > bürgergeld;
		};
		
		/*******************************************************************************
					Schritt 2: Ermittlung der relevanten Terme für die Transfergrenze
		*******************************************************************************/
		
		
		gen bruttoeinkommen = erwerbek + vermögek + transferek;
		
		save Grundeink_aggr.dta, replace;
		preserve;
		do Grundeink.do;
		
		restore;
		merge 1:1 V00001 using Grundeinkommen_durchgelaufen.dta;
		drop _merge;
		
		
		if "${variante0}" == "0"{;
			scalar te_star = 0.5; /*Anrechnung Erwerbeinkommen*/
			scalar tc_star = 1; /*Anrechnung Vermögenseinkommen*/
			scalar tT_star = 1; /*Anrechnung Transfereinkommen*/
		};

		if "${variante0}" == "1"{;
			scalar te_star = 0;
			scalar tc_star = 0;
			scalar tT_star = 0;
		};
		
		scalar steuersatz = 0.5;
		scalar solisatz = 0;
		
		
		gen gewichtetesEK = scalar(te_star)*erwerbek + (tc_star)*vermögek + (tT_star)*transferek;
		
		gen erwerbekanteil = (erwerbek-abzügeek)/(erwerbek-abzügeek+vermögek+transferek);
		
		foreach var in vermögek transferek{;
			gen `var'anteil = `var'/(erwerbek-abzügeek+vermögek+transferek); 
		};		
		
		
		gen transfergrenze = bürgergeld/(te_star*erwerbekanteil+tc_star*vermögekanteil+tT_star*transferekanteil);
		
		replace transfergrenze = bürgergeld if transfergrenze <0;
		replace transfergrenze = bürgergeld if transfergrenze ==.;
		
		/*******************************************************************************
					Schritt 3: Ehegattensplitting
		*******************************************************************************/
		replace split1 = 1 if V10002 == 1 | V10002 == 0;
		foreach var in bürgergeld abzügeek bruttoeinkommen gewichtetesEK erwerbek vermögek transferek svbeiträge{;
		    egen `var'_ehe = sum(`var') if split1==1, by(verheiratet);
			replace `var'_ehe = 0 if V10002;
			replace `var'_ehe = . if verheiratet ==.;
		};
		
		gen erwerbek_eheanteil = (erwerbek_ehe-abzügeek_ehe)/(erwerbek_ehe-abzügeek_ehe+vermögek_ehe+transferek_ehe);
		
		foreach var in vermögek_ehe transferek_ehe{;
			gen `var'anteil = `var'/(erwerbek_ehe-abzügeek_ehe+vermögek_ehe+transferek_ehe) if V10002 == 0 & split1 == 1; 
		};	
		
		gen transfergrenze_ehe = (bürgergeld_ehe)/(te_star*erwerbek_eheanteil+tc_star*vermögek_eheanteil+tT_star*transferek_eheanteil) if split1 == 1 & V10002 ==0;
		replace transfergrenze_ehe = 0 if V10002 == 1;
		replace transfergrenze_ehe = bürgergeld_ehe if transfergrenze_ehe <0 & split1 == 1 & V10002 == 0;
		replace transfergrenze_ehe = bürgergeld_ehe if transfergrenze_ehe == . & split1==1 & V10002 == 0;
		browse transfergrenze  transfergrenze_ehe V10002 V05001;
		
		
		/*******************************************************************************
					Schritt 4: Ermittlung Steuerschuld und SPE
		*******************************************************************************/
		gen steuerschuld = scalar(te_star)*(erwerbek-abzügeek-svbeiträge) + (tc_star)*vermögek + (tT_star)*transferek;
		gen spe = (erwerbek-abzügeek-svbeiträge) + vermögek + transferek;
		
			/*Ehegattensplitting*/
			gen steuerschuld_ehe = scalar(te_star)*(erwerbek_ehe-abzügeek_ehe-svbeiträge_ehe) + (tc_star)*vermögek_ehe + (tT_star)*transferek_ehe if V10002 == 0 & split1==1;
			gen spe_ehe = (erwerbek_ehe-abzügeek_ehe-svbeiträge_ehe) + vermögek_ehe + transferek_ehe if V10002 == 0 & split1==1;
		
		/*******************************************************************************
					Schritt 5: Ermittlung Steuer
		*******************************************************************************/
		gen zve = spe-transfergrenze;
		gen negsteuer = steuerschuld-bürgergeld;
		replace negsteuer = 0 if negsteuer >= 0;
		
			/*Ehegattensplitting*/
			gen zve_ehe = spe_ehe-transfergrenze_ehe if V10002 == 0 & split1==1;
			gen negsteuer_ehe = steuerschuld_ehe - bürgergeld_ehe if V10002 == 0 & split1==1;
			replace negsteuer_ehe = 0 if negsteuer_ehe >= 0 & split1==1;
		
		
		if "${variante0}" == "1" | "${variante2}" == "1"{;
			replace zve = spe;
			replace zve_ehe = spe_ehe if V10002 == 0 & split1==1;
		};
		
		if "${variante2}" == "1"{;
			gen steuer_transfer = 0;
			gen steuer_transfer_ehe = 0;
		};
		if "${tarifEst}" == "1"{;
		
			preserve;

			import excel using Parameter_BGKS.xlsx, sheet(Sheet1) clear firstrow cellrange(A1:D18) ;

			scalar     tp_g1_bgks = sz_Bürgergeld[1]; 
			scalar     tp_g2_bgks = sz_Bürgergeld[2];	
			scalar     tp_g3_bgks = sz_Bürgergeld[3];
			scalar     tp_g4_bgks = sz_Bürgergeld[4];
			scalar     tp_a2_bgks = sz_Bürgergeld[6];
			scalar     tp_a3_bgks = sz_Bürgergeld[7];
			scalar     tp_b2_bgks = sz_Bürgergeld[9];
			scalar     tp_b3_bgks = sz_Bürgergeld[10];
			scalar     tp_b4_bgks = sz_Bürgergeld[11];
			scalar     tp_b5_bgks = sz_Bürgergeld[12];
			scalar     tp_c3_bgks = sz_Bürgergeld[14];
			scalar     tp_c4_bgks = sz_Bürgergeld[15];
			scalar     tp_c5_bgks = sz_Bürgergeld[16];

			restore;

		
		

			gen steuer = 0;
			replace steuer = (tp_b2_bgks + (zve-tp_g1_bgks)*tp_a2_bgks*10^(-8))*(zve-tp_g1_bgks) 			if zve>tp_g1_bgks & zve<= tp_g2_bgks;
			replace steuer = (tp_b3_bgks + (zve-tp_g2_bgks)*tp_a3_bgks*10^(-8))*(zve-tp_g2_bgks)+tp_c3_bgks if zve >tp_g2_bgks & zve <=tp_g3_bgks;
			replace steuer =tp_b4_bgks*zve-tp_c4_bgks 														if zve >tp_g3_bgks & zve <=tp_g4_bgks;
			replace steuer = tp_b5_bgks*zve - tp_c5_bgks													if zve >tp_g4_bgks;

			/*Ehegattensplitting*/ replace zve_ehe = 0.5*zve_ehe if split1 == 1;
			gen steuer_ehe = 0 if V10002 == 0 & split1 == 1;
			replace steuer_ehe = (tp_b2_bgks + (zve_ehe-tp_g1_bgks)*tp_a2_bgks*10^(-8))*(zve_ehe-tp_g1_bgks) if zve_ehe>tp_g1_bgks & zve_ehe<= tp_g2_bgks & V10002 == 0 & split1 == 1;
			replace steuer_ehe = (tp_b3_bgks + (zve_ehe-tp_g2_bgks)*tp_a3_bgks*10^(-8))*(zve_ehe-tp_g2_bgks)+tp_c3_bgks if zve_ehe >tp_g2_bgks & zve_ehe <=tp_g3_bgks & V10002 == 0 & split1 == 1;
			replace steuer_ehe = tp_b4_bgks*zve_ehe-tp_c4_bgks 	 if zve_ehe >tp_g3_bgks & zve_ehe <=tp_g4_bgks & V10002 == 0 & split1 == 1;
			replace steuer_ehe = tp_b5_bgks*zve_ehe - tp_c5_bgks if zve_ehe >tp_g4_bgks & V10002 == 0 & split1 == 1; 
			replace steuer_ehe = 2*steuer_ehe if V10002 == 0 & split1 == 1;

			if "${variante2}" == "1"{;

				replace steuer_transfer = (tp_b2_bgks + (transfergrenze-tp_g1_bgks)*tp_a2_bgks*10^(-8))*(transfergrenze-tp_g1_bgks) 					if transfergrenze>tp_g1_bgks & transfergrenze<= tp_g2_bgks;
				replace steuer_transfer = (tp_b3_bgks + (transfergrenze-tp_g2_bgks)*tp_a3_bgks*10^(-8))*(transfergrenze-tp_g2_bgks)+tp_c3_bgks 		if transfergrenze >tp_g2_bgks & transfergrenze <=tp_g3_bgks;
				replace steuer_transfer = tp_b4_bgks*transfergrenze-tp_c4_bgks 																		if transfergrenze >tp_g3_bgks & transfergrenze <=tp_g4_bgks;
				replace steuer_transfer = tp_b5_bgks*transfergrenze - tp_c5_bgks																		if transfergrenze >tp_g4_bgks;
				
				/*Ehegattensplitting*/
				replace steuer_transfer_ehe = (tp_b2_bgks + (transfergrenze_ehe-tp_g1_bgks)*tp_a2_bgks*10^(-8))*(transfergrenze_ehe-tp_g1_bgks) 					if transfergrenze_ehe>tp_g1_bgks & transfergrenze_ehe<= tp_g2_bgks & V10002 == 0 & split1 == 1;
				replace steuer_transfer_ehe = (tp_b3_bgks + (transfergrenze_ehe-tp_g2_bgks)*tp_a3_bgks*10^(-8))*(transfergrenze_ehe-tp_g2_bgks)+tp_c3_bgks 		if transfergrenze_ehe >tp_g2_bgks & transfergrenze_ehe <=tp_g3_bgks & V10002 == 0 & split1 == 1;
				replace steuer_transfer_ehe = tp_b4_bgks*transfergrenze_ehe-tp_c4_bgks 																		if transfergrenze_ehe >tp_g3_bgks & transfergrenze_ehe <=tp_g4_bgks & V10002 == 0 & split1 == 1;
				replace steuer_transfer_ehe = tp_b5_bgks*transfergrenze_ehe - tp_c5_bgks																		if transfergrenze_ehe >tp_g4_bgks & V10002 == 0 & split1 == 1;
	
	
				replace steuer = max(steuer-steuer_transfer,0);
				replace steuer_ehe = max(steuer_ehe-steuer_transfer_ehe,0) if V10002 == 0 & split1 == 1;
			};



			if "${variante0}" == "1"{;
				gen pos_steuer = steuer if steuer >= 0;
				gen soli_ks = 0 ;
				replace soli_ks = steuer*(solisatz) if steuer > 0;
				replace steuer = steuer + negsteuer if negsteuer <0; /*Aufgestockten Einkomme*/
				
				gen pos_steuer_ehe = steuer_ehe if steuer_ehe >= 0 & V10002 == 0 & split1 == 1;
				gen soli_ks_ehe = 0 if V10002 == 0 & split1 == 1;
				replace soli_ks_ehe = steuer_ehe*(solisatz) if steuer_ehe > 0;
				replace steuer_ehe = steuer_ehe + negsteuer_ehe if negsteuer<0 & V10002 == 0 & split1 == 1;
			};
			else{;
				replace steuer = 0 if steuer == .;
				replace steuer = max(steuer,0);
				gen pos_steuer = steuer if steuer >= 0;
				replace steuer = negsteuer if negsteuer <0 & steuer == 0;
				gen soli_ks = 0 ;
				replace soli_ks = steuer*(solisatz) if steuer > 0;
				
				replace steuer_ehe = 0 if steuer_ehe ==.  & V10002 == 0 & split1 == 1;
				gen pos_steuer_ehe = steuer_ehe if steuer_ehe >= 0 & V10002 == 0 & split1 == 1;
				replace steuer_ehe = negsteuer_ehe if negsteuer_ehe < 0 & steuer_ehe == 0 & V10002 == 0 & split1 == 1;
				gen soli_ks_ehe = 0 if V10002 == 0 & split1 == 1;
				replace soli_ks_ehe = steuer_ehe*(solisatz) if steuer_ehe > 0 & V10002 == 0 & split1 == 1;
			};
			
			if ${ehegattensplitting} == 1{;
					replace steuer = steuer_ehe if verheiratet != .;
					replace steuer = 0 if V10002 == 1;
					
					
					replace pos_steuer = pos_steuer_ehe if verheiratet != .;
					replace pos_steuer = 0 if V10002 ==1;
					
					replace negsteuer = negsteuer_ehe if  verheiratet != .;
					replace negsteuer = 0 if V10002 ==1;
					
				};

			replace steuer = 0 if steuer ==.;

			gen fest_est = 0;
			gen fest_est_EST = 0;
			replace fest_est_EST = steuer + soli_ks;

			replace fest_est_EST = 0 if fest_est_EST == .;

			gen neg_steuer = negsteuer;

			gen pos_steuer_fest = fest_est_EST if fest_est_EST >=0;
			gen neg_steuer_fest = fest_est_EST if fest_est_EST < 0;

			gen pos_steuer_hh_ = fest_est_EST if fest_est_EST >=0;
			gen neg_steuer_hh_ = fest_est_EST if fest_est_EST < 0 ;

			sum steuer soli_ks fest_est_EST pos_steuer neg_steuer;
		};
		
		if "${tarifEst}" == "0"{;
				/*Ehegattensplitting*/
				replace zve_ehe = 0.5*zve_ehe if V10002 == 0 & split1==1;
				gen steuer_ehe = scalar(steuersatz)*zve_ehe if zve_ehe >= 0 & V10002 == 0 & split1==1;
				replace steuer_ehe = 2*steuer_ehe if V10002 == 0 & split1==1;
				gen steuer = scalar(steuersatz)*zve if zve >= 0;
			
			if "${variante0}" == "1"{;
				replace steuer = 0 if steuer ==.;
				gen pos_steuer = steuer if steuer >= 0;
				gen soli_ks = 0 ;
				replace soli_ks = steuer*(solisatz) if steuer > 0;
				replace steuer = steuer + negsteuer if negsteuer <0; /*Aufgestockten Einkommen*/
				
				/*Ehegattensplitting*/
				replace steuer_ehe = 0 if steuer_ehe ==. & V10002 == 0 & split1==1;
				gen pos_steuer_ehe = steuer_ehe if steuer_ehe >= 0 & V10002 == 0 & split1==1;
				gen soli_ks_ehe = 0 if V10002 == 0;
				replace soli_ks_ehe = steuer_ehe*(solisatz) if steuer_ehe > 0 & V10002 == 0 & split1==1;
				replace steuer_ehe = steuer_ehe + negsteuer_ehe if negsteuer_ehe <0 & V10002 == 0 & split1==1;
			};
			else{;
				replace steuer = 0 if steuer == .;
				gen pos_steuer = steuer if steuer > 0;
				replace pos_steuer = 0  if pos_steuer == .;
				replace steuer = negsteuer if negsteuer <=0 & steuer == 0;
				gen soli_ks = 0 ;
				replace soli_ks = steuer*(solisatz) if steuer > 0;
				
				/*Ehegattensplitting*/
				replace steuer_ehe = 0 if steuer_ehe == . & V10002 == 0 & split1==1;
				gen pos_steuer_ehe = steuer_ehe if steuer_ehe > 0 & V10002 == 0 & split1==1;
				replace pos_steuer_ehe = 0  if pos_steuer_ehe == . & V10002 == 0 & split1==1;
				replace steuer_ehe = negsteuer_ehe if negsteuer_ehe <=0 & steuer_ehe == 0 & V10002 == 0 & split1==1;
				gen soli_ks_ehe = 0 if V10002 == 0 & split1==1;
				replace soli_ks_ehe = steuer_ehe*(solisatz) if steuer_ehe > 0 & V10002 == 0 & split1==1;
				
				
				browse steuer steuer_ehe V05001 V10002;
				
				if ${ehegattensplitting} == 1{;
					replace steuer = steuer_ehe if verheiratet != .;
					replace steuer = 0 if V10002 == 1;
					
					
					replace pos_steuer = pos_steuer_ehe if verheiratet != .;
					replace pos_steuer = 0 if V10002 ==1;
					
					replace negsteuer = negsteuer_ehe if  verheiratet != .;
					replace negsteuer = 0 if V10002 ==1;
					
				};
				
			};
		
		gen fest_est_EST = 0;
		replace fest_est_EST = steuer + soli_ks;
		replace fest_est_EST = 0 if fest_est_EST == .;
		gen neg_steuer = negsteuer;
		gen pos_steuer_fest = fest_est_EST if fest_est_EST >=0;
		gen neg_steuer_fest = fest_est_EST if fest_est_EST < 0;
		
		gen pos_steuer_hh_ = fest_est_EST if fest_est_EST >=0;
		gen neg_steuer_hh_ = fest_est_EST if fest_est_EST < 0 ;
		sum steuer soli_ks fest_est_EST pos_steuer neg_steuer;
		
		
		};
		
		/*******************************************************************************
					Schritt 6: Berechnung der Nettoeinkommen
		*******************************************************************************/
		gen eknetto_bedarfsgemeinschaften = bruttoeinkommen - fest_est_EST  - svbeiträge;
		
		foreach var in transferersetzt transferek steuer bürgergeld{;
			egen `var'_hh = sum(`var'), by(V05001);
			replace `var'_hh = 0 if V10002 != 0;
		};
		
		
		egen eknetto_hh = sum(eknetto_bedarfsgemeinschaften), by(V05001);	
		replace eknetto_hh = 0 if V10002 != 0;
		egen eknetto_hh_hh = sum(eknetto_bedarfsgemeinschaften), by(V05001);
		replace eknetto_hh_hh = 0 if V10002 != 0;
		
		

	/*******************************************************************************

				5. Sozialleistungen abschaffen

	*******************************************************************************/
	
		
	foreach var in algeld  kgeld  kizu wohngld elternghh grusialter {;
		replace `var' = 0;
	};
	replace algII = 0 if HV == 1;
	

/* gesamtes Bruttoeinkommen, einschl. nicht steuerpflichtiger Einkuenfte */


replace bruttoeinkommen = bruttoeinkommen+			
					stipend 
					+ algeld
					+ altueg 
					+algII
					+grusialter				
					+kgeld
					+ vbzuegb
					+wohngld*12
					+ uhalthh*12;
					
					
					
#delimit;
gen shtrans = 0;
do Klassenbildung.do;
/*Anpassungen*/
replace ekzins   = ekzins*2 if couple==1;
replace ekneben  = ekneben/12;
replace eksndr   = eksndr/12;
replace vorsorg  = vorsorg/12;

/*Aggregation*/
foreach var in ekzins ekselb ekrent ekwitw ekahh vbzuegb eklohn eklohn_zu eksndr ekkurz  ekneben  ekwintr algeld elternghh vbzueg{;
	egen `var'_hh = sum(`var'), by(V05001);
};

egen    est_fest_hh = sum (fest_est_EST), by (V05001);

egen    eknebhh  = sum(ekneben), by(V05001);
label variable eknebhh "Jährliches Nebeneinkommen, Haushalte";
replace eknebhh = eknebhh*12;

/* ********************************************************************************************/
/* Lohnersatzleistungen ALG ALHi Kurzarbeitergeld im HH*/
/* ********************************************************************************************/
replace algeld   = algeld/12;
gen    alghh    = 0;
//gen    algeld_hh= 0;
