/*0_START*/
#delimit;
clear all;
cap log close;
set matsize 800;
set more 1;
/*set varabbrev off */
global starttime 		"$S_TIME";

if c(username) == "mhamburg" {;
	global MY_IN_PATH   	"J:\SOEP35\";
	global MY_TEMP_PATH 	"K:\sbach\mhamburg\Übergabe2\temp\";
	global MY_PROJECT_PATH	"K:\sbach\mhamburg\Übergabe2\"; //Wo die Sachen gespeichert werden
	global MY_PROGRAM_PATH	"K:\sbach\mhamburg\Übergabe2\"; // Wo die DoFils hergeholt werden
	global MY_PATH			"K:\sbach\mhamburg\Übergabe2";
	global MY_SUBPATH		"K:\";
	cd ${MY_PROJECT_PATH};
	
};

if c(username) == "sbach" {;
	global MY_IN_PATH   	"J:\SOEP35\";
	global MY_TEMP_PATH 	"K:\sbach\mhamburg\Übergabe2\temp\";
	global MY_PROJECT_PATH	"K:\sbach\mhamburg\Übergabe2\"; //Wo die Sachen gespeichert werden
	global MY_PROGRAM_PATH	"K:\sbach\mhamburg\Übergabe2\"; // Wo die DoFils hergeholt werden
	global MY_PATH			"K:\sbach\mhamburg\Übergabe2";
	global MY_SUBPATH		"K:\";
	cd ${MY_PROJECT_PATH};
	
};



use datensatz_aggr2.dta; /*Einlesen des Datensatzes*/
/********************************************************************************************/
/* 1) Simulation*/
/********************************************************************************************/


foreach run in 0 {; // über die Varianten (siehe Liste der Varianten im Kopf dieses Do-Files)

	global mergegr grM;
	global alt      = `run';
	global alternat = `run';

	noisily: di in r "Run: " `run';

	// *******************************************************************************************
	// Das Simulationsprogramm (statisch und/oder dynamisch) wird von diesem Do-File gesteuert:
			
	#delimit;
	version 7.0;
	set logtype text;
	set matsize 800;
		
	do 1_Sim.do;
	
	save "${MY_PROJECT_PATH}1_Simulation/1_Simulation_.dta", replace;
	
	// *******************************************************************************************
	// 2) Output
	// *******************************************************************************************
			
	do 2_Output.do;
			
}; 
 // 3) Ende
 // *******************************************************************************************

 // Gesamtlaufzeit des Programms:
global endtime "$S_TIME";
display "total duration:  from " in red "${starttime}" in y " to " in red "${endtime}";
