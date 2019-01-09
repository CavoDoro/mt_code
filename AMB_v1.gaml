/***
* Name: AMB
* Author: Lina Stanzel
* Description:	„Ambitious/Green“(AMB) = most sustainable scenario for energy networks in Gleisdorf
* Tags: #gleisdorf #energynetworks
***/

model AMB

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//THE GLOBAL SPECIES
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
global {
	//characteristics of the model world
    // definition of global attributes actions, behaviours
    
    //built in attributes are world, cycle(number of executions), step(intervall between two circles), time (circle*step), ....
    //...agents(returns a list of all agents with behaviours(no places)
          
    //file load
    //border 
    file border_gleisdorf <-file("../includes/4700_gleisdorf_border.shp");
    //building polygons
    file building_polygons <-file("../includes/1200_building_polygons_dec_18.shp");
        
    //dh-network
    file dh_network_gleisdorf <-file("../includes/2100_dh_network.shp");
    //gas-network    
    file gas_network_gleisdorf <-file("../includes/2200_gas_network.shp");
    
    //dh-potential zone
    file dh_potential_gleisdorf <-file("../includes/3100_dh_potential_zone.shp");
    //gas-potential zone
    file gas_potential_gleisdorf <-file("../includes/3300_gas_potential_zone.shp");
    //HP-depending potential zones:
    //noise restriction for air hp potential
    file pv_potential_gleisdorf <- file("../includes/3900_solarpv_building.shp");
    file sole_hp_potential_gleisdorf <- file("../includes/3220_geology_sole_hp.shp");
    file water_hp_potential_gleisdorf <- file ("../includes/3230_hydrogeology_water_hp.shp");
    file air_hp_potential_gleisdorf <-file("../includes/3210_noise_restriction_air_hp.shp");
   
    //biomass-potential
    file biomass_potential_gleisdorf <-file("../includes/3400_biomass_potential.shp");
    //oil-potential
    file oil_potential_gleisdorf <-file("../includes/3500_oil_potential.shp");
    //electric-potential
    file electric_potential_gleisdorf <-file("../includes/3700_electricity_potential.shp");
    //coal-potential
    file coal_potential_gleisdorf <- file("../includes/3600_coal_potential.shp");
  
    //deomgraphic_raster_2011
    file demograpghic_2011_gleisdorf <-file("../includes/5100_dem_11.shp");
    //demographic_raster_2016
    file demograpghic_2016_gleisdorf <-file("../includes/5200_dem_16.shp");
    //demographic_polygon_2011
    file demographic_polygon_2011_gleisdorf <- file("../includes/5100_dem_11_polygon.shp");
	//demographic_polygon_2016
    file demographic_polygon_2016_gleisdorf <- file("../includes/5200_dem_16_polygon.shp");
    
    //initialisation once at the beginning
    //init of environment = geometry (world agent), size = border of Gleisdorf
    geometry shape <- envelope(border_gleisdorf);
    
    geometry building_shape <- envelope(building_polygons); 
    
	geometry dh_pot <- geometry(dh_potential_gleisdorf);
    geometry air_pot <- geometry(air_hp_potential_gleisdorf);	
    
    geometry demographic_raster <- envelope(envelope(demograpghic_2011_gleisdorf) + envelope(demograpghic_2016_gleisdorf));
    
    geometry dh_net	<- geometry(dh_network_gleisdorf);
    geometry gas_net	<- geometry(gas_network_gleisdorf);
    
   	//initialisation of scheduling
    date starting_date <- date([2018]);
    int starting_int <- 2018;
	float step <- 1 #year; //time steps of one year
	
	int building_age;
	int hwb_initial;
	
    //counting number of buildings according to specific attributes    
    int building_count_total_init -> {length (buildings)};
    int building_count_not_renovated_init -> {length (buildings where(each.renovation_status_input = "not renovated"))};
    int building_count_normal_renovated_init -> {length (buildings where(each.renovation_status_input = "normal renovation standard"))};
    int building_count_advanced_renovated_init -> {length (buildings where(each.renovation_status_input = "klimaaktiv renovation standard"))};
    	 	 
	int no_need_count -> {length (buildings where(each.renovation_status_actual = "no need for renovation"))};
	int renovation_need_count -> {length (buildings where(each.renovation_status_actual = "RENOVATION NEEDED"))};
	int renovation_sim_count -> {length (buildings where(each.renovation_status_actual = "renovation at simulation time"))};
	int industrial_count -> {length (buildings where(each.type = "industrial"))};
	int res_count -> {length (buildings where(each.residential_type = "res"))};
	int nores_count -> {length (buildings where(each.residential_type = "nonres"))}; 
	
    //creation=init of all other agents = regular species = members of the world
    init {
    	create border from: border_gleisdorf;

    	create buildings from: building_polygons with:[type::string(read("b_use")),year_construction::int(read("c_year")),
    		tabula_start::int(read("start_p")), gfa::int(read("gross_area")), heating_system_initial::string(read("heat_type")),
    		renovation_status_input::string(read("ren_status")),hwb_initial::int(read("hwb_m2_a")),hwb_usual::int(read("usual_hwb"))
    		,hwb_advanced::int(read("klima_hwb")), total_wwwb_initial::float(read("wwwb_kwh")), total_hteb_initial::float(read("hteb_kwh")),
    		total_heb_initial::float(read("heb_kwh"))];
    		
    	create dem_buildings from: demographic_polygon_2016_gleisdorf with: [age_19_m::float(read("r_m_0to19")), age_39_m::float(read("r_m_20to39")),
    		age_64_m::float(read("r_m_40to64")), age_100_m::float(read("r_m_65to100")), age_19_w::float(read("r_w_0to19")), age_39_w::float(read("r_w_20to39")),
    		age_64_w::float(read("r_w_40to64")), age_100_w::float(read("r_w_65to100")), nat_aut::float(read("r_aut_nat")), nat_notaut::float(read("r_noaut_nat")),
    		job_yes_m::float(read("r_job_m_yes")), job_no_m::float(read("r_job_m_no")),job_yes_w::float(read("r_job_w_yes")),job_no_w::float(read("r_job_w_no")),
    		edu_pfl::float(read("r_edu_pfl")),edu_nomat::float(read("r_edu_no_mat")),edu_mat::float(read("r_edu_mat")),edu_uni::float(read("r_edu_high"))];

    	create sole_hp_potential from: sole_hp_potential_gleisdorf with:[potential::int(read("potential"))];
    	create water_hp_potential from: water_hp_potential_gleisdorf with:[potential::int(read("atypid"))];
    	create pv_potential from: pv_potential_gleisdorf with:[ability::string(read("EIGNUNG")),area::float(read("SOLARFL"))];
		
		// for the subdivision between different testruns
    	save  ("-------------------------------------------------------------------------")  to: "../results/results_AMB.txt" rewrite: false;
    		}	
   		   		
   	reflex global_debug {
 		
   				write "----------------------------------------------------------------";
   				write "number of  buildings total: " + building_count_total_init ;
				write "number of not renovated buildings init: " + building_count_not_renovated_init;
				write "number of normal renovated buildings init: " + building_count_normal_renovated_init;
				write "number of advanced renovated buildings init: " + building_count_advanced_renovated_init;
				write "renovated total init: " 	+ (building_count_normal_renovated_init	+ building_count_advanced_renovated_init);   	
			
				write "no need for renovation: " +no_need_count;
				write "need for renovation: " + renovation_need_count;
				write "renovated at simulation time: " + renovation_sim_count;					
	}
		
	//safe statistics in .txt file
    	reflex save_result when: every (1#cycles) {
			save 
			("cycle : "+ (cycle) + " no need for renovation : " + (no_need_count)
				+ " need for renovation : " + renovation_need_count + " renovated at simulation time : " + renovation_sim_count)
	   		to: "../results/results_AMB.txt" rewrite: false;
		}

	//safe total heb statistics as csv	
		reflex save_heb_development when: every (1#cycles) {			
			save("cycle : "+ (cycle) + " heb-list: ") to: "../results/total_heb_development_AMB.csv" type:"csv" rewrite: false;
				ask buildings {
					save [total_heb_actual] to: "../results/total_heb_development_AMB.csv" type:"csv" rewrite: false;
				}
			save("--------------------------------------------------------" ) to: "../results/total_heb_development_AMB.csv" type:"csv" rewrite: false;
		}
		
		
	reflex save_buildings_2035 when: cycle = 18{
//		ask buildings {
//			// save the values of the variables name, speed and size to the csv file; the rewrite facet is set to false to continue to write in the same file
//			save [name,type,hwb_actual] to: "../results/building_hwb_2035.csv" type:"csv" rewrite: false;
//			// save all the attributes values of the bug agents in a file. The file is overwritten at every save
//			save buildings to: "../results/building_AMB_2035.csv" type:"csv" rewrite: true;
//			//Shapefile for Display 
//			//save buildings to: "../results/building_AMB_2035_.shp" type:"shp" attributes: ["ID"::int(self)];
//		}
		//Pause the model as the data are saved
		//do pause;
	}
	reflex save_buildings_2050 when: cycle = 33{ 
		ask buildings {
			// save the values of the variables name, speed and size to the csv file; the rewrite facet is set to false to continue to write in the same file
			//save [name,type,hwb_actual] to: "../results/building_hwb_2050.csv" type:"csv" rewrite: false;
			// save all the attributes values of the bug agents in a file. The file is overwritten at every save
			//save buildings to: "../results/building_AMB_2050.csv" type:"csv" rewrite: true;
		}		
		do pause;
		//End the modelling process as the data are saved with one extra click
		//do halt;
	}	
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//REGULAR SPECIES
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//define the species that populate the city of Gleisdorf
//regular species are composed of attributes, actions, reflex, aspect etc...
//available built-in attributes: name(string), location(point), shape(geometry), host(agent)=agent as a part of an other agent

//border = specie only for display -> no scheduling
species border schedules: [] {
	
	aspect default {
		draw shape color: #red width: (2.5);
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//PARENT SPECIES FOR ALL POTENTIAL ZONES
species potentials {
	rgb color <- #aqua;
		int dist <- 0;
		aspect pot {
			draw shape color: color;
		}		
	}
	
//PV POTENTIAL ZONE -> child of potentials
	species pv_potential parent:potentials {
				string ability;
				float area;
				rgb color <- #crimson;
				init pv_pot_check{
			ask buildings at_distance dist  {
				self.inside_pvp <- true;
					if (myself.ability = "sehr gut") and (myself.area > 50.0) {
					self.inside_pvp_1 <- true;
					}
				}
			}	
			
			//aspect for pv potential
			aspect pv_pot{		
				if (ability = "sehr gut") and (area > 50.0) {
					color <- #blue;
				}
				else if ability = "gut" {
					color <- #skyblue;			
				}
				else {
				color <- #gray;
			}	
		draw shape color: color;	
		}							
	}
	
//DH POTENTIAL ZONE -> child of potentials
	species dh_potential parent:potentials topology: topology(dh_potential_gleisdorf) {
		rgb color <- #aqua;						
		//check for buildings if they are inside the potentialzone
		reflex dh_pot_check{
			ask buildings at_distance dist {
				self.inside_dhp <- true;
			}		
		}							
	}	
	species sole_hp_potential parent:potentials topology: topology(sole_hp_potential_gleisdorf){
				int potential;		
				rgb color <- #powderblue;							
	}	
	species water_hp_potential parent:potentials topology: topology(water_hp_potential_gleisdorf){		
				int potential;
				rgb color <- #mediumblue;				
	}		
	species air_hp_potential parent:potentials topology: topology(air_hp_potential_gleisdorf){		
				rgb color <- #darkblue;
				reflex ahp_pot_check{
			ask buildings at_distance dist {
				if (self.inside_pvp_1 = true){								
					self.inside_airp <- true;
				} 
			}		
		}				
	}	
//GAS POTENTIAL ZONE -> child of potentials
	species gas_potential parent:potentials topology: topology(gas_potential_gleisdorf){	
		rgb color <- #salmon;						
	}
	
	species biomass_potential parent:potentials topology: topology(biomass_potential_gleisdorf){
				rgb color <- #olivedrab;	
	}
	
	species oil_potential parent:potentials topology: topology(oil_potential_gleisdorf){
				rgb color <- #dimgrey;
	}
	
	species electric_potential parent:potentials topology: topology(electric_potential_gleisdorf){
				rgb color <- #khaki;
	}
	
	species coal_potential parent:potentials topology: topology(coal_potential_gleisdorf){
				rgb color <- #black;
				reflex coal_pot_check{
			ask buildings at_distance dist {
				self.inside_coalp <- true;
			}		
		}					
	}	
///BUILDINGS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
species buildings {	
// definition of attributes///////////////////////////////////////////////////////////////////////////////////////////////////////
    int starting_int <- 2018; 
   	int time_duration <- (building_age-building_age_start);    
       
    //predefined in-beteween the shape
    string type; 
   	int year_construction;
   	int tabula_start;
   	int gfa;
   	string renovation_status_input;
   	string renovation_status_actual;
   	int renovation_year; //year of renovation
   	
   	//actual (2018) 
   	string heating_system_initial;
   	string heating_system_actual;
   	int hwb_initial;
   	int total_hwb_init;
   	float total_wwwb_initial;
   	float total_hteb_initial;
   	float total_heb_initial;
   	//lt TABULA
   	int hwb_usual;
   	int hwb_advanced;
   	int hwb_actual;
   	
   	//defined in GAMA
   	string residential_type;
    int building_age_start; 
    int renovation_age; //age of the building at the time of renovation
    int building_age;  
    
    int total_hwb_actual;
    float total_heb_actual; 
 
    bool is_renovated;
    
    //potential zone check variables
    bool inside_dhp;    
    bool inside_solep;
    bool inside_waterp;
    bool inside_airp;
    bool inside_gasp;
    bool inside_biomassp;
    bool inside_oilp;
    bool inside_electricp;
    bool inside_coalp;
    bool inside_pvp;
    bool inside_pvp_1; //bool for very good suitability (where abilitiy is "sehr good" and area is bigger than 50qm?)
      
    rgb color <- #gray; //defaultcolor for buildings without specific aspect
   
//INIT//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	init building_type {
		//residential type init
		if type = "single-family home"  {
			residential_type <- "res";
		}
		if type = "multi-family home"  {
			residential_type <- "res";
			}
		if type = "apartment-block"  {
			residential_type <- "res";
		}
		if type = "agricultural"  {
			residential_type <- "res";
			}
//		if type = "industrial"  {
//			residential_type <- "nonres";
//		}
		if type = "business"  {
			residential_type <- "nonres";
			}
		if type = "public"  {
			residential_type <- "nonres";
		}
		if type = "hospitality"  {
			residential_type <- "nonres";
			}
		if type = "non-residential"	  {
			residential_type <- "nonres";
			}
		if type = "other"	  {
			residential_type <- "nonres";
			}
		}
			
	init building_status {	
		//renovation status
		if renovation_status_input = "not renovated"{
			is_renovated <- false;
			renovation_status_actual <- "not renovated";
		}
		else if renovation_status_input = "normal renovation standard" {
			is_renovated <- true;
			renovation_status_actual <- "normal renovation standard";
		}
		else if renovation_status_input = "klimaaktiv renovation standard" {
			is_renovated <- true;
			renovation_status_actual <- "advanced renovation standard";
		}
		else {
			is_renovated <- false;
			renovation_status_actual <- "not renovated";
		}
		
		//heating system
		heating_system_actual <- heating_system_initial;
		
		//init hwb
		hwb_actual <- hwb_initial;
		//total hwb
		total_hwb_init <- (hwb_initial*gfa);
		total_hwb_actual <- total_hwb_init;
		total_heb_actual <- total_heb_initial;
	}
	
	init potential_check{
		ask gas_potential at_distance 0 {
					myself.inside_gasp <- true;
				}
		ask dh_potential at_distance 0 {
					myself.inside_dhp <- true;
				}
		ask biomass_potential at_distance 0 {
					myself.inside_biomassp <- true;
				}
		ask oil_potential at_distance 0 {
					myself.inside_oilp <- true;
				}
		ask electric_potential at_distance 0 {
					myself.inside_electricp <- true;
				}
		ask coal_potential at_distance 0 {
					myself.inside_coalp <- true;
				}										
	}
	
// definition of actions(=do) do something (individual for every agent), behaviours(=reflex) be something (every time step)	
//BEHAVIOURS//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//potentialzone check -> comunication building polygon and potential zone: the species buildings asks the potential zones
	reflex hp_pot_check {
				if (inside_pvp = true) {
					ask sole_hp_potential at_distance 0 {				
						if (self.potential = 1) {
						myself.inside_solep <- true;
							}		
					}
					ask water_hp_potential at_distance 0 {				
						if (self.potential = 1) {
						myself.inside_waterp <- true;
							}		
					}				
				}
				if (inside_pvp_1 = true) {
					ask air_hp_potential at_distance 0 {									
						myself.inside_airp <- true;									
					} 		
				}							
			}		

	//Age of a building at the start of the simulation
	reflex age_cont_start {
		if year_construction != 0 {
		building_age_start <- (starting_int -year_construction);
		}
		else { building_age_start <- nil; }
	}
	
	//Age of a building at current time
    reflex age_count {    	
    	building_age <- (building_age_start + cycle);
    }
    	
	reflex renovation_behaviour when: is_renovated = false{
		
		if residential_type = "res" {
	
			if building_age<42{	
				renovation_status_actual <- "no need for renovation";	
				}	
			else if building_age>=42{
		
				do renovation_action;						
				}
			else {
				write #current_error;
				}
			}	
		if residential_type = "nonres" {
	
			if building_age<30{		
				renovation_status_actual <- "no need for renovation";
				}	
			else if building_age>=30{		
				do renovation_action;
				}
			else {
				write #current_error;
				}
			}		
	}	
	
	reflex heating_system_update{

		if is_renovated = true {			
			if inside_dhp = true {			
				heating_system_actual <- "dh";
			}
			else if (inside_solep = true) {		
				heating_system_actual <- "sole_hp";
				}
			else if (inside_waterp = true) {			
				heating_system_actual <- "water_hp";
				}
			else if (inside_airp = true) {		
				heating_system_actual <- "air_hp";		
			}
			else if inside_biomassp = true{
				heating_system_actual <- "biomass";
			}	
			else if inside_gasp = true{
				heating_system_actual <- "gas";					
			}
		else {			
				heating_system_actual <- "unknown";
				} 
			}
		}
	
//ACTIONS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
//action of building renovation		
	action renovation_action{
		
		renovation_status_actual <- "RENOVATION NEEDED";
		//renovation rate randomly between 6 and 19 percent of all buildings which need a renovation (init = 628)
		//these are estimated 2,2 percent of all buildings in Gleisdorf
		is_renovated <- flip(rnd(0.06, 0.19));
		
		if is_renovated=true{
			//age
			renovation_age <- building_age;
			renovation_year <- (starting_int + renovation_age - building_age_start);
			//hwb update for usual renovation
			if (hwb_usual < hwb_actual) {
				hwb_actual <- hwb_usual;
				}
			//status update
			renovation_status_actual <- "renovation at simulation time";
			//total hwb update
			total_hwb_actual <- (hwb_actual*gfa);
			total_heb_actual <- (total_hwb_actual + total_wwwb_initial + total_hteb_initial);	
			}		
		}

    //Debugger
    reflex writeDebug {
//   			write "construction date: " + year_construction;
//	   			write "cycle count/time passed by: " + cycle;
//	   			write "type: " + type;
//   			write "restype: " + residential_type;
//   			write "heating system: " + heating_system_initial; 
//   			write res_buildings; 			
//   			write "current age: " + building_age;
//	   			write "renovation status: " + is_renovated;
//   			write "hwb-init: " + hwb_initial;
//   			write "hwb-usual: " + hwb_usual;
//   			write "hwb-actual: " +hwb_actual;
//   			write "system: " + heating_system; 
//   			write "gfa: " + gfa;

//				write "SYSTEM: " + testtyp + "!!!";

//				write "total hwb: " + total_hwb_init;every(1#cycles)
//				write "res: " + res_count;
//				write "nores: " + nores_count;
//   			write "-------------------------------";
    }  

//ASPECTS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
    //Ansicht: to represent the geometry of the Agent
    aspect default {
		//draw shape color: (is_renovated) ? #green : #grey;
		draw shape color: color;
		}	
				
	aspect renovation_aspect{
		if is_renovated = true {
    			color <- #green;
    		}
    	if is_renovated = false {
    			color <- #black;
    		}
    	draw shape color: color;
		}
			
	aspect actual_renovation_status{
		if renovation_status_actual = "normal renovation standard" {
    			color <- #orchid;  			
    			}			
    	if renovation_status_actual = "klimaaktiv renovation" {
    			color <- #purple;		
    			}   			
    	if renovation_status_actual = "not renovated" {
    			color <- #yellow;		
    			}		
		if renovation_status_actual = "no need for renovation" {
    			color <- #darkgreen;
    		}
    	if renovation_status_actual = "RENOVATION NEEDED" {
    			color <- #red;
    			}
    	if renovation_status_actual = "renovation at simulation time" {
    			color <- #lime;
    			} 	
    	draw shape color: color;
		}
					
	aspect type_aspect{
		if type = "industrial" {
    			color <- #black;
    		}
    	if type = "single-family home" {
    			color <- #yellow;
    		}
    	if type = "multi-family home" {
    			color <- #orange;
    		}    
    	draw shape color: color;
		}
				
	aspect heat_type{
		if heating_system_initial = "district_heat" {
    			color <- #blue;
    		}
    	if heating_system_initial = "gas" {
    			color <- #red;
    		}
    	if heating_system_initial = "biomass" {
    			color <- #green;
    		}
    	if heating_system_initial = "heat_pump" {
    			color <- #blueviolet;
    		}
    	if heating_system_initial = "electricity" {
    			color <- #yellow;
    		} 
    	if heating_system_initial = "oil" {
    			color <- #saddlebrown;
    		}  
    	if heating_system_initial = "coal" {
    			color <- #black;
    		} 
    	if heating_system_initial = "unknown" {
    			color <- #darkkhaki;
    		}   
    	if heating_system_initial = "no_heating" {
    			color <- #cyan;
    		}                  
    	if heating_system_initial = "other" {
    			color <- #lime;
    		}       
    	draw shape color: color;
		}
				
	aspect pv_positive {
		if inside_pvp = true {
			color <- #yellow;
		}
		draw shape color: color;
	}
		
aspect age_aspect {			
		if building_age < 1 {
			color <- #black;
			}
		else if building_age < 30 {
			color <- #green;			
			}
		else if (building_age >= 30) {
			color <- #red;
			}
		else {
			color <- #gray;
			}	
		draw shape color: color;	
		}	
	}
		
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	species energy_networks{	
		//parent species	
	}
	species dh_network parent:energy_networks {
		
		rgb color <- #blue;
		
		aspect default {
			draw shape color: color;
		}	
	}
	
	species gas_network parent:energy_networks {
		
		rgb color <- #red;
		
		aspect default {
			draw shape color: color;
		}	
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	species dem_buildings {
		rgb color <- #magenta;
		float age_19_m;
		float age_39_m;
		float age_64_m;
		float age_100_m;
		float age_19_w;
		float age_39_w;
		float age_64_w;
		float age_100_w;
		float nat_aut;
		float nat_notaut;
		float job_yes_m;
		float job_no_m;
		float job_yes_w;
		float job_no_w;
		float edu_pfl;
		float edu_nomat;
		float edu_mat;
		float edu_uni;
		
		
//		reflex debug_dem {
//			ask buildings{
//				write "type: " + self.name;
//				write "age19m: " + myself.age_19_m;
//			}
//			
//		}
		aspect dem_building {
			draw shape color: color;
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	species my_people /*skills:[moving] */{
		
		bool debug; 
		int dist <- 0;
		
		rgb color <- #fuchsia ;
		aspect base {
			draw circle(5) color: color border: #black;
		}
		aspect extended {
			draw circle(20) color: #yellow border: #black;
		}
	}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//EXPERIMENTS
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

experiment renovation type:gui /* + specify the type : "type:gui" or "type:batch" */

{
    // here the definition of your experiment, with...
    // ... your inputs
    output {	
        // ... and your outputs
        display gleisdorf type: opengl {
        	species border aspect: default refresh: false;
        	    	
        	//species air_hp_potential aspect: pot;
        	
        	species gas_potential aspect: pot;
  	     	species dh_potential aspect: pot;
  	     	
        	species dem_buildings aspect: dem_building;	
        	species buildings aspect: actual_renovation_status;//pv_positive;//type_aspect; //renovation_aspect;//heat_type;
        	species pv_potential aspect: pv_pot;
        	
//        	species dh_network;
//        	species gas_network;
            	
			graphics "networks" {
        		draw world.gas_net color: #darkred;
        		draw world.dh_net color:  #mediumblue;    	
        	}  	        
        }
        
        display building_information refresh: every(1#cycles) {
        	
			chart " Renovation status time series" type: series size: {1200,1} position: {0, 0} {
				
				data "no need of renovation" value: no_need_count color: #blue ;
				data "renovation needed" value: renovation_need_count color: #red ;
				data "renovation at simulation time" value: renovation_sim_count color: #green ;			
			}
        	
        }     
    }  
//STORE the simulation    
//        reflex store when: cycle = 18 and 33{		
//			write "================ START SAVE + self " + " - " + cycle ;		
//			write "Save of simulation : " + saveSimulation('saveSimu.gsim');
//			write "================ END SAVE + self " + " - " + cycle ;	
//     	}      
}


