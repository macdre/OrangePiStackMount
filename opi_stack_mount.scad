/**************************************************************************** 
Title: Orange Pi Zero Plus Stack Mounting System

Description: This script is intended to generate a stackable mounting system for the Orange Pi Zero Plus.

Author: Ross MacDonald
Created In: 2018-05-09 

License: Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
License Link: https://creativecommons.org/licenses/by-nc-sa/4.0/

/***************************************************************************/

// ##########################################################################
// Modify these variables to define what to generate

// What part to generate: Values: "wall", "top", "bottom", "demo"
generateType = "demo";

// Wall notch characteristics: 0, 1, or 2
number_of_wall_notches = 1;

// Horizontal Unit Count: This affects only the top and bottom generation
// If set to 1, then the top and bottom will generate at one board unit wide
// If, instead, the user would like to place more that one board beside one another,
// then set to a number equal to the number of horizontally adjacent boards desired
number_of_horizontal_units = 4;
// ##########################################################################

// The following board variables could be adjusted to suit other board types
board_depth = 48;
board_width = 46;
board_thickness = 10;
board_headroom = 20;

// These variables configure the wall characteristics
wall_thickness = 10;
wall_depthroom = 10;
wall_depth = board_depth + (wall_depthroom * 2);
wall_height = board_thickness + (board_headroom * 2);

// These variables define the interlocking dovetail dimensons
interlock_i_depth = wall_depth;
interlock_i_width = (wall_thickness / 2);
interlock_i_thickness = 5;

// Some slack is needed to ensure there is some play in fitting parts
// If the dovetail slides are too tight, increase the interlock slack
// If the dovetail slides are too loose, decrease the interlock slack
interlock_i_slack = 0.4;
overlap_fudge = 0.1;

// This defines how much of a notch is created in the wall for the board to rest on
// The logic below is simple, do not make the notch too large, otherwise the wall 
// will fall apart!
board_notch_offset = wall_thickness * 2/3;

// These variables define the top and bottom characteristics
bridge_depth = wall_depth;
bridge_width = board_width + (2 * board_notch_offset) + (2 * overlap_fudge);
bridge_thickness = 5;

overall_bridge_width = bridge_width + ((number_of_horizontal_units-1) * (bridge_width - (wall_depthroom + overlap_fudge)));

function getInterlockTranslation(i) =
    ((bridge_width * i) - (wall_thickness * 3/4) - ((i-1) * (wall_depthroom + overlap_fudge)));

// This is a module used to generate a dovetail interlocking segment
module generateDovetail(depth, width, thickness) {
    dovetailIndent = width / 4;
    linear_extrude(height = depth) {
        polygon([[0, dovetailIndent], [0, width-dovetailIndent], 
            [thickness, width], [thickness,0]]);
    }    
}

module generateInterlock(type) {
    if(type == "innie") {
        generateDovetail(interlock_i_depth, 
            interlock_i_width + (interlock_i_slack * 2), 
            interlock_i_thickness + interlock_i_slack / 2);
    }
    else if(type == "outtie") {
        generateDovetail(interlock_i_depth, 
            interlock_i_width, 
            interlock_i_thickness);
    }
}
    
// This module generates a wall
module generateWall(numberOfNotches) {
    difference() {
        difference() {
            union() {
                cube([wall_depth, wall_thickness, wall_height]);
                
                rotate([0,-90,0]){
                    translate([wall_height - overlap_fudge,
                    (wall_thickness/4),-interlock_i_depth]){    
                        generateInterlock("outtie");
                    }
                }    
            }

            union(){
                if(numberOfNotches > 0.5) {
                    translate([wall_depthroom,
                    board_notch_offset+overlap_fudge,
                    board_headroom]){
                        cube([board_depth,
                            wall_thickness-board_notch_offset,
                            board_thickness]);
                    }
                    
                    translate([0,
                    board_notch_offset+overlap_fudge,
                    (board_headroom + (board_thickness / 4))]) {
                        cube([wall_depth,
                            wall_thickness-board_notch_offset,
                            (board_thickness / 2)]);
                    }
                }
                
                if(numberOfNotches > 1.5) {
                    translate([wall_depthroom, 0,
                    board_headroom]){
                        cube([board_depth,
                            wall_thickness-board_notch_offset,
                            board_thickness]);
                    }
                    
                    translate([0, 0,
                    (board_headroom + (board_thickness / 4))]) {
                        cube([wall_depth,
                            wall_thickness-board_notch_offset,
                            (board_thickness / 2)]);
                    }
                }
                
            }                
        }

        rotate([0,-90,0]){
            translate([0,(wall_thickness/4) - interlock_i_slack,
            -interlock_i_depth]){    
                generateInterlock("innie");
            }
        }
    }
}  

// Create a basic bridge
module generateBridge(thickness) {
    cube([bridge_depth, overall_bridge_width, thickness]);    
}

// This module generates the bottom for the unit
module generateBottomBridge() {
    union() {
        generateBridge(bridge_thickness);
        
        rotate([0,-90,0]){
            translate([(bridge_thickness - overlap_fudge),
            (wall_thickness/4),-interlock_i_depth]){    
                generateInterlock("outtie");
            }
        }
        
        for(i = [1:number_of_horizontal_units]){
            rotate([0,-90,0]){
                translate([(bridge_thickness - overlap_fudge),
                    getInterlockTranslation(i),
                    -interlock_i_depth]){    
                    generateInterlock("outtie");
                }
            }
        }
    }
}

// This module generates the top for the unit
module generateTopBridge() {
    difference() {
        generateBridge(2 * bridge_thickness);
        
        union() {
            rotate([0,-90,0]){
                translate([0, 
                    ((wall_thickness/4) - interlock_i_slack), 
                    -interlock_i_depth]){    
                    generateInterlock("innie");
                }
            }
            
            for(i = [1:number_of_horizontal_units]){
                rotate([0,-90,0]){
                    translate([0,
                        getInterlockTranslation(i) - interlock_i_slack,
                        -interlock_i_depth]){    
                        generateInterlock("innie");
                    }
                }
            }
        }        
    }
}

// This generates a demonstration of constructed system
module demo() {
    translate([0,0,-bridge_thickness])generateBottomBridge();
    translate([0,0,50])generateTopBridge();
    generateWall(1);
    for(i = [1:(number_of_horizontal_units)]){
        translate([0,
            (bridge_width * i) - ((i-1) * (wall_depthroom+overlap_fudge)),
            0])mirror([0,1,0]){
                generateWall(i == number_of_horizontal_units ? 1 : 2);
            }
            
        color("powderblue",0.5)translate([wall_depthroom, 
            board_notch_offset + overlap_fudge + (i-1) * (wall_thickness - board_notch_offset + overlap_fudge + board_width),
            board_headroom])cube([board_depth,board_width,board_thickness]);
    }
}

if (generateType == "demo"){
    demo();
}
else if(generateType == "wall") {
    rotate([0,-90,0]){
        generateWall(number_of_wall_notches);
    }
}
else if(generateType == "top") {
    rotate([0,-90,0]){
        generateTopBridge();
    }
}
else if(generateType == "bottom") {
    rotate([0,-90,0]){
        generateBottomBridge();
    }   
}
