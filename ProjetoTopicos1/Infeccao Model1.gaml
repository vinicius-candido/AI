/**
* Name: Infeccao Model 1
* Author: Vinicius, Matheus, Marcella
* Description: 
* 
*/

model si

global { 
	int ciclo <- 1 #cycle;
	float step <- 1 #day;
	//Numero de agentes suscetiveis
    int numSuscetiveis <- 495;
    //Numero de agentes infectados
    int numInfectados <- 5 ;
    //Numero de agentes vacinados
    int numVacinados <- 0 ;

	//Dias duracao infeccao
	int periodoInfeccao <- 9;
	//Periodo de transmissao no qual o agente estara transmitindo o virus
	int periodoTransmissao <- 5;

	//Mortality rate for the host
	float nu <- 0.001 ;
	//Rate for resistance 
	float delta <- 0.7;
	//Number total of hosts
	int numberHosts <- numSuscetiveis+numInfectados+numVacinados;
	//Boolean to represent if the infection is computed locally
	bool local_infection <- true parameter: "Is the infection is computed locally?";
	//Range of the cells considered as neighbours for a cell
	int neighbours_size <- 2 min:1 max: 5 parameter:"Size of the neighbours";
	
	float R0 ;
	geometry shape <- square(70#m);
	
	init {
		//Creation of all the susceptible Host
		create Agente number: numSuscetiveis {
        	estaInfectado <-  false;
            estaVacinado <-  false; 
            color <-  #green;
        }
        //Criacao dos agentes infectados
        create Agente number: numInfectados {
            estaInfectado <-  true;
            estaVacinado <-  false; 
            color <-  #red; 
       }
       //Criacao dos agentes vacinados
       create Agente number: numVacinados {
            estaInfectado <-  false;
            estaVacinado <-  true; 
            color <-  #blue; 
       }
       
       //R0 <- beta/(delta+nu);
		write "Basic Reproduction Number: "+ R0;
   }
   
   //Reflex to update the number of infected
   reflex compute_nb_infected {
   		numInfectados <- Agente count (each.estaInfectado);
   }       
}

//Definicao do grid 
grid sir_grid width: 50 height: 50 use_individual_shapes: false use_regular_agents: false frequency: 0{
	rgb color <- #black;
	list<sir_grid> neighbours <- (self neighbors_at neighbours_size) ;       
}


species Agente  {
	//Booleans que representam o estado atual do agente
	bool estaInfectado <- false;
    bool estaVacinado <- false;
    bool bonsHabitosHigiene <- flip(0.2);
    int diasInfectado;
    //Interacao entre agentes (de 0.0 a 1.0)
		/**0.0 - 0.1: Conversa
		0.1 - 0.3: Aperto de mão
		0.3 - 0.8: Abraço
		0.8 - 1.0: Beijo*/    
	float fatorInteracao <- 0.01 ;
    rgb color <- #green;
    sir_grid myPlace;
    
    init {
    	//Place the agent randomly among the grid
    	myPlace <- one_of (sir_grid as list);
    	location <- myPlace.location;
    }     
    //Reflex to make the agent move   
    reflex basic_move {
    	myPlace <- one_of (myPlace.neighbours) ;
        location <- myPlace.location;
    }	
    
    reflex conta_dias_infeccao {
    	if(estaInfectado){
    		if(diasInfectado > periodoInfeccao){
    			estaInfectado <- false;
    		} else{
    		diasInfectado <- diasInfectado + 1;
    		}
    	}
	}
    
    //Reflexo que torna o agente infectado
    reflex tornar_infectado when: !estaVacinado {
    	ask Agente at_distance 1#m {
    		if(self.fatorInteracao + myself.fatorInteracao >= 1.5){
    			if(self.estaInfectado or myself.estaInfectado){
    				self.estaInfectado <- true;
    				myself.estaInfectado <- true;
    			} 
    		} else if(between(0.5,self.fatorInteracao + myself.fatorInteracao,1.5)){
    			if(self.estaInfectado or myself.estaInfectado){
    				if !(self.estaVacinado){
    					if!(self.bonsHabitosHigiene or myself.bonsHabitosHigiene){
    						if(flip(delta)){
    							self.estaInfectado <- true; myself.estaInfectado <- true;
    						}
    					}
    				}
    			}
    		} else{
	    		if(self.estaInfectado and myself.estaInfectado){
	    			if (self.estaVacinado){
	    				estaInfectado <- flip(delta);
	    			}
	    		}
	    	}
	    }
    	
    		
    		
      	float rate  <- 0.0;
    	//computation of the infection according to the possibility of the disease to spread locally or not
    	if(local_infection) {
    		int nb_hosts  <- 0;
    		int nb_hosts_infected  <- 0;
    		loop hst over: ((myPlace.neighbours + myPlace) accumulate (Agente overlapping each)) {
    			nb_hosts <- nb_hosts + 1;
    			if (hst.estaInfectado) {nb_hosts_infected <- nb_hosts_infected + 1;}
    		}
    		rate <- nb_hosts_infected / nb_hosts;
    	} else {
    		rate <- numInfectados / numberHosts;
    	}
    }
    

//    	if (flip(beta * rate)) {
//        	is_susceptible <-  false;
//            is_infected <-  true;
//            is_immune <-  false;
//            color <-  #red;    
//        }
	

    //Reflex to make the agent recovered if it is infected and if it success the probability
    reflex become_immune when: (estaInfectado and flip(delta)) {
    	estaInfectado <- false;
        color <- #blue;
    }
    //Reflex to kill the agent according to the probability of dying
    reflex shallDie when: flip(nu) {
    	//Create another agent
		create species(self)  {
			myPlace <- myself.myPlace ;
			location <- myself.location ; 
		}
       	do die;
    }
            
    aspect basic {
        draw circle(1) color: (estaInfectado and !estaVacinado) ? #red : #green;
    }
  } 


experiment Simulation type: gui { 
 	parameter "Número de agentes suscetíveis ao vírus" var: numSuscetiveis ;
    parameter "Número inicial de agentes infectados" var: numInfectados ;
    parameter "Número inicial de agentes vacinados" var:numVacinados ;	
    parameter "Percentual de pessoas com com hábitos de higiene" var:delta ;
	//parameter "Beta (S->I)" var:beta; 	// The parameter Beta
	parameter "Mortality" var:nu ;	// The parameter Nu
	parameter "Delta (I->R)" var: delta; // The parameter Delta
	//parameter "Is the infection is computed locally?" var:local_infection ;
	//parameter "Size of the neighbours" var:neighbours_size ;
 	output { 
	    display sir_display {
	        grid sir_grid lines: #black;
	        species Agente aspect: basic;
	    }
	        
	    display chart refresh: every(10#cycles) {
			chart "Susceptible" type: series background: #lightgray style: exploded {
				data "infected" value: Agente count (each.estaInfectado) color: #red;
				data "immune" value: Agente count (each.estaVacinado) color: #blue;
			}
		}
			
	}
}
