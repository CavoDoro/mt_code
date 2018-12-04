/***
* Name: mtv2
* Author: Lina
* Description: 
* Tags: Tag1, Tag2, TagN
***/

//next steps: implement timesteps that every year gets a name then calculate the current age of a building at every timestep
//				when a building is 30 years old change the renovation status and calculate a new hwb

model mtv1

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
    file building_polygons <-file("../includes/1200_building_polygnons_abm.shp");
        
    //dh-network
    file dh_network_gleisdorf <-file("../includes/2100_dh_network.shp");
    //gas-network    
    file gas_network_gleisdorf <-file("../includes/2200_gas_network.shp");
    
    //dh-potential zone
    file dh_potential_gleisdorf <-file("../includes/3100_dh_potential_zone.shp");
    //gas-potential zone
    file gas_potential_gleisdorf <-file("../includes/3300_gas_potential_zone.shp");
    //noise restriction for air hp potential
    file air_hp_potential_gleisdorf <-file("../includes/3210_noise_restriction_air_hp.shp");
    //biomass-potential
    file biomass_potential_gleisdorf <-file("../includes/3400_biomass_potential.shp");
    //oil-potential
    file oil_potential_gleisdorf <-file("../includes/3500_oil_potential.shp");
    //electric-potential
    file electric_potential_gleisdorf <-file("../includes/3700_electricity_potential.shp");
        
    //!!coal, sole-hp, water-hp potential zones are still missing!!!
  
    //deomgraphic_raster_2011
    file demograpghic_2011_gleisdorf <-file("../includes/5100_dem_11.shp");
    //demographic_raster_2016
    file demograpghic_2016_gleisdorf <-file("../includes/5200_dem_16.shp");
    
    //initialisation once at the beginning
    //init of environment = geometry (world agent), size = border of Gleisdorf
    geometry shape <- envelope(border_gleisdorf);
    
    geometry building_shape <- envelope(building_polygons) /*+ envelope(dh_network_gleisdorf) + envelope(gas_network_gleisdorf)
    	 + envelope(dh_potential_gleisdorf) + envelope(gas_potential_gleisdorf) + envelope(air_hp_potential_gleisdorf) + envelope(biomass_potential_gleisdorf)
    	+ envelope(oil_potential_gleisdorf) + envelope(electric_potential_gleisdorf) + */;
 
//     geometry potential_shape <- envelope (electric_potential_gleisdorf)+ envelope(dh_potential_gleisdorf) + envelope(gas_potential_gleisdorf) + envelope(air_hp_potential_gleisdorf) + envelope(biomass_potential_gleisdorf)
//    	+ envelope(oil_potential_gleisdorf);    

	geometry dh_pot <- geometry(dh_potential_gleisdorf);
    geometry air_pot <- geometry(air_hp_potential_gleisdorf);	
    geometry demographic_raster <- envelope(envelope(demograpghic_2011_gleisdorf) + envelope(demograpghic_2016_gleisdorf));
    
    
    geometry debug_b <- geometry(building_polygons);
    geometry debug_dh <- geometry(dh_potential_gleisdorf); 
    
    
    int debug_dimensions min: 10 <- 500;
    geometry debug_r <- square(debug_dimensions);   
    
    geometry dh_net	<- geometry(dh_network_gleisdorf);
    geometry gas_net	<- geometry(gas_network_gleisdorf);
    
    //time step of one year
    
   	//initialisation of scheduling
    date starting_date <- date([2018]);
    date end_date <- date([2050]);
    int starting_int <- 2018;
	float step <- 1 #year; //# for all constant variables
	int cycle;
	int building_age;
	int hwb_initial;
	 
    //creation=init of all other agents = regular species = members of the world
    init {
    	create border from: border_gleisdorf;
    	
    	//create dh_network from: dh_network_gleisdorf;
    	//create gas_network from: gas_network_gleisdorf;
    	
     	
    	create buildings from: building_polygons with:[type::string(read("b_use")),year_construction::int(read("c_year")),
    		tabula_start::int(read("start_p")), gfa::int(read("gross_area")), heating_system::string(read("heat_type")),
    		renovation_status_input::string(read("ren_status")),hwb_initial::int(read("hwb_m2_a")),hwb_usual::int(read("usual_hwb"))
    		,hwb_advanced::int(read("klima_hwb"))] {	
    	}
    	
    	list<buildings> res_buildings <- buildings where (each.type="single-family home");
    	
    	//create dh_potential from: 
    	
//    	create gas_potential from: gas_potential_gleisdorf;
//    	 	
//    	create dh_potential from: dh_potential_gleisdorf;
//    	
//    	create air_hp_potential from: air_hp_potential_gleisdorf; 
    	
    	
    	
    	
    	create species:my_people number: 100 {
    		location <- (point(one_of(buildings)));
    	}	   	
   	} 
   	//end of simulation
//   	reflex endsimulation when: date = end_date{
//   		do halt;
//   	}  
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

///BUILDINGS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
species buildings {	
// definition of attributes///////////////////////////////////////////////////////////////////////////////////////////////////////
    int starting_int <- 2018; 
   	int time_duration <- (cycle + starting_int);    
       
    //predefined in-beteween the shape
    string type; 
   	int year_construction;
   	int tabula_start;
   	int gfa;
   	string renovation_status_input;
   	string renovation_status_actual;
   	string heating_system;
   	int hwb_initial;
   	int hwb_usual;
   	int hwb_advanced;
   	int hwb_actual;
   	
   	
   	//defined in GAMA
   	string residential_type;
    int building_age_start; 
    int building_age;  
    int total_hwb_init;
    int total_hwb_actual;
 
    bool is_renovated;
    
    //potential zone check variables
    bool inside_dhp;
    bool inside_gasp;
    
    rgb color <- #gray;

    
//INIT//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//initialisation of renovation status check
	

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
		if type = "industrial"  {
			residential_type <- "nonres";
		}
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
		else if renovation_status_input = "klimaaktiv renovation" {
			is_renovated <- true;
			renovation_status_actual <- "advanced renovation standard";
		}
		else {
			is_renovated <- false;
			renovation_status_actual <- "not renovated";
		}
		

		
		//init hwb
		hwb_actual <- hwb_initial;
		//total hwb
		total_hwb_init <- (hwb_initial*gfa);
		total_hwb_actual <- total_hwb_init;
	}

	
// definition of actions(=do) do something (individual for every agent), behaviours(=reflex) be something (every time step)	
//BEHAVIOURS//////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
	
			if building_age<56{	
				renovation_status_actual <- "no need for renovation";	
				
				write renovation_status_actual;
				}	
			else if building_age>=56{
		
				do renovation_action;			
				}
			else {
				write #current_error;
				}
			}
		
		if residential_type = "nonres" {
	
			if building_age<41{		
				renovation_status_actual <- "no need for renovation";
				write "no need for renovation";
				write renovation_status_actual;
				}	
			else if building_age>=41{
		
				do renovation_action;			
				}
			else {
				write #current_error;
				}
			}		
	}	
	
	

//ACTIONS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//comunication building polygon and potential zone: the species buildings asks the potential zones
	reflex heating_system_update{
//	//   !!!!!!!!!!!!!!!!!!!!!!<Work in Progress>!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!	
//	//
//eventuell mit self: so dass nur einzelne gebäude/agenten angesprochen werden.

//	if building_shape intersects dh_pot{
//		write name;
//		
//	}
//	
	//list<buildings> <- dh_potential at_distance(1);
	
	
//	if debug_b touches debug_dh{
//		debugtest <- true; 
//		
//	}

	//comunication between potential zones and buildings for heating system update
	
	//   !!!!!!!!!!!!!!!!!!!!!!</Work in Progress>!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!	
	}
		
//action of building renovation		
	action renovation_action{
		
		renovation_status_actual <- "RENOVATION NEEDED";
		is_renovated <- flip(0.15);
		
		if is_renovated=true{
			//hwb update for usual renovation
			hwb_actual <- hwb_usual;
			//status update
			renovation_status_actual <- "renovation at simulation time";
			//total hwb update
			total_hwb_actual <- (hwb_actual*gfa);
			//heating system update
			//do heating_system_update;
//			if debug_dh overlaps debug_b{
//			debugtest <- true; 
//			}
			}
		}
		
		
//action of network growth
	//   !!!!!!!!!!!!!!!!!!!!!!<Work in Progress>!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!	
	
	//network growth
	
	//   !!!!!!!!!!!!!!!!!!!!!!</Work in Progress>!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!		


    //Debugger
    reflex writeDebug {
//   			write "construction date: " + year_construction;
//   			write "cycle count/time passed by: " + cycle;
   			write "type: " + type;
   			write "restype: " + residential_type;
   			write "heating system: " + heating_system;  			
//   			write "current age: " + building_age;
//	   			write "renovation status: " + is_renovated;
//   			write "hwb-init: " + hwb_initial;
//   			write "hwb-usual: " + hwb_usual;
//   			write "hwb-actual: " +hwb_actual;
//   			write "system: " + heating_system; 
//   			write "gfa: " + gfa;
//   			write "total hwb: " + total_hwb_init;
   			
   			write "-------------------------------";
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
		if heating_system = "district_heat" {
    			color <- #blue;
    		}
    	if heating_system = "gas" {
    			color <- #red;
    		}
    	if heating_system = "biomass" {
    			color <- #green;
    		}
    	if heating_system = "heat_pump" {
    			color <- #blueviolet;
    		}
    	if heating_system = "electricity" {
    			color <- #yellow;
    		} 
    	if heating_system = "oil" {
    			color <- #saddlebrown;
    		}  
    	if heating_system = "coal" {
    			color <- #black;
    		} 
    	if heating_system = "unknown" {
    			color <- #darkkhaki;
    		}   
    	if heating_system = "no_heating" {
    			color <- #cyan;
    		}                  
    	if heating_system = "other" {
    			color <- #lime;
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	species potentials {

	}
	//species cild parent:potentials
		species dh_potential parent:potentials topology: topology(dh_potential_gleisdorf) {
			
		int dist <- 0;	
		
		//check for buildings if they are inside the potentialzone
		reflex dh_pot_check{
			ask buildings at_distance dist {
				self.inside_dhp <- true;
			}
			
		}
	
		reflex deb{
		ask my_people at_distance dist {
			self.debug <- true;
			}
		}
	
		rgb color <- #aqua;
		
		aspect dh_pot {
			draw shape color: color;
		}			
	}
	
	species gas_potential parent:potentials topology: topology(gas_potential_gleisdorf){
		
		int dist <- 0;	
		
		//check for buildings if they are inside the potentialzone
		reflex gas_pot_check{
			ask buildings at_distance dist {
				self.inside_gasp <- true;
			}		
		}
		
		rgb color <- #salmon;
		
		aspect gas_pot {
			draw shape color: color;
		}	
	}
	species air_hp_potential parent:potentials{
		
				rgb color <- #aquamarine;
		
		aspect air_pot {
			draw shape color: color;	
		}	
	}
	
	species biomass_potential parent:potentials{
				rgb color <- #olivedrab;
		
		aspect biomass_pot {
			draw shape color: color;	
		}	
	}
	
	species oil_potential parent:potentials{
				rgb color <- #olivedrab;
		
		aspect oil_pot {
			draw shape color: color;	
		}	
	}
	
	species electric_potential parent:potentials{
				rgb color <- #khaki;
		
		aspect electric_pot {
			draw shape color: color;	
		}	
	}
	
	species solar_potential parent:potentials{
				rgb color <- #yellow;
		
		aspect solar_pot {
			draw shape color: color;	
		}	
	}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	species energy_networks{
		
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
        	    	
        	species air_hp_potential aspect: air_pot;
        	species gas_potential aspect: gas_pot;
        	species dh_potential aspect: dh_pot;
       	
        	species buildings aspect: actual_renovation_status;//type_aspect; //renovation_aspect;//heat_type;
        	
//        	species dh_network;
//        	species gas_network;
             	
			graphics "networks" {
        		draw world.gas_net color: #darkred;
        		draw world.dh_net color:  #mediumblue;
        	}
     	
        	//species my_people aspect: extended;
        
        }
//        display renovation_stats {
//        	chart "The city of Gleisdorf"{
//        		//data "age" value: buildings(age);
//        	}       	
 //       }
        
    }   
}

experiment network_growth /* + specify the type : "type:gui" or "type:batch" */
{
    // here the definition of your experiment, with...
    // ... your inputs
    output {
        // ... and your outputs
    }
    }
