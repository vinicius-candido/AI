/**
* Name: firstmodel
* Author: Vinicius Sebba Patto
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model firstModel

/* Insert your model definition here */

global {
	int numbOfPeople <- 50;
	int numbOfMosquitoes <- 20;	
	string test <- 'teste';
	
	geometry shape <- square(90#m); //may be circle, rectangle, etc.
	
	init {
		create people number:numbOfPeople;
		create mosquitoes number:numbOfMosquitoes;
	}
	
	//reflex debug{ //reflex e executado a cada ciclo
	//	write test;
	//}
	
}

species people skills:[moving]{
	bool isInfected <- false;
	init{
	//	location <- {45,45};
	}
	reflex moving{
		do wander;
	}
	aspect base{
		draw cube(2) color: (isInfected) ? #orange : #green;
	}
}

species mosquitoes skills:[moving]{
	init{
	//	location <- {0,30};
	}
	bool isInfected <- flip(0.3);
	int attack_range <- 1;
	
	reflex moving{
		do wander;
	}
	
	reflex attack when: !empty(people at_distance attack_range){
		ask people at_distance attack_range{
			if (self.isInfected){
				myself.isInfected <- true;
			}
			else if (myself.isInfected) {
				self.isInfected <- true;
			}
		}
	}
	
	aspect base{
		draw circle(1) color: (isInfected) ? #red : #blue;
	}
}

grid my_grid width:30 height:30 {
    init {
        //write "my column index is:" + grid_x;
        //write "my row index is:" + grid_y;
    }
    list people_inside -> {people inside self};    
}

experiment myExperiment type:gui{
	output{
		display myDisplay{
			species people aspect:base;
			species mosquitoes aspect:base;
          //  grid my_grid lines: rgb("black") ;
   		}
	}
}