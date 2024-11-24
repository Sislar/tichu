/* [Global] */

// Wall Thickness
gWT = 2.0;

// Box Length
TotalX = 58*2+3*gWT;
// Box Width
TotalY = 89+2*gWT;
// Box Height
TotalZ = 22;  // (Including Lid)

// What to Model
Render = "Lid";   // "Both", "Box", "Lid"



// Type of lid pattern
gPattern = "Fish"; //  [Hex, Web, Solid, Diamond, Fancy]

/* [Spider Web] */

// Amount of space from one ring or webs to the next
WebSpacing = 10;
// How many rings of webs, best of more than needed
WebStrands = 5;
// Thickness of the strands
WedThickness = 1.8;
// How many segments of web
WebWedges = 12;

/* [Hidden] */
gLidHeight = 7;   // Total height is gLigHeight + gBoxHeigth

//  The height of the box without the lid
AdjBoxHeight = TotalZ - gLidHeight;

$fn=30;

 module regular_polygon(order, r=1)
 {
        angles=[ for (i = [0:order-1]) i*(360/order) ];
        coords=[ for (th=angles) [r*cos(th), r*sin(th)] ];
        polygon(coords);
 }

module circle_lattice(ipX, ipY, Spacing=10, Walls=1.2)  {


   intersection() {
      square([ipX,ipY]); 
      union() {
        for (x=[-Spacing:Spacing:ipX+Spacing]) {
          for (y=[-Spacing:Spacing:ipY+Spacing]){
             difference()  {
                   translate([x+Spacing/2, y+Spacing/2]) circle(r=Spacing*0.75);
                   translate([x+Spacing/2, y+Spacing/2]) circle(r=(Spacing*0.75)-Walls);
                }
            }   // end for y        
        }  // end for x
       } // Union
   }
}


module hex_lattice(ipX, ipY, DSize, WSize)  {
    lXOffset = DSize + WSize;
    lYOffset = (DSize+WSize)/cos(30) * 1.5;

	difference()  {
		square([ipX, ipY]);
		for (x=[0:lXOffset:ipX]) {
            for (y=[0:lYOffset:ipY]){
  			   translate([x, y]) rotate([0,0,30]) regular_polygon(6, r=DSize/cos(30)/2);
			   translate([x+lXOffset/2, y+lYOffset/2]) rotate([0,0,30]) regular_polygon(6, r=DSize/cos(30)/2);
		    }
        }  
	}
}

module diamond_lattice(ipX, ipY, DSize, WSize)  {

    lOffset = DSize + WSize;

	difference()  {
		square([ipX, ipY]);
		for (x=[0:lOffset:ipX]) {
            for (y=[0:lOffset:ipY]){
  			   translate([x, y])  regular_polygon(4, r=DSize/2);
			   translate([x+lOffset/2, y+lOffset/2]) regular_polygon(4, r=DSize/2);
		    }
        }        
	}
}

module half_circle(ipRadius,width){
    difference(){
        circle(ipRadius);
        circle(ipRadius-width);
        translate([-ipRadius*2,0])square(ipRadius*4, center = true);
    }
}
   

module scale_lattice(ipX, ipY, DSize, WSize)  {

    lOffset = DSize-(WSize/2);

    intersection()  
    {
	  square([ipX, ipY]);
      union() {
        for (x=[0:lOffset:ipX]) {
          for (y=[0:lOffset:ipY]){
             translate([x, y]) half_circle (DSize/2,WSize) ;
             translate([x+lOffset/2, y+lOffset/2]) half_circle (DSize/2,WSize) ;
          }
        }  
      }
   }      
}


// Make a star with X points
module star(radius, wedges)
{
	angle = 360 / wedges;
	difference() {
		circle(radius, $fn = wedges);
		for(i = [0:wedges - 1]) {
			rotate(angle / 2 + angle * i) translate([radius, 0, 0]) 
			    scale([0.8, 1, 1]) 
				    circle(radius * sin(angle / 2), $fn = 24);
		}
	}
}

module spider_web(ipWebSpacing, strands, ipThickness, wedges) 
{
	for(i = [0:strands - 1]) 
    {
        difference() {
            star(ipWebSpacing * i, wedges);
            offset(r = -ipThickness) star(ipWebSpacing * i, wedges);
        }
	}

	angle = 360 / wedges;
	for(i = [0:wedges - 1])
    {
		rotate(angle * i) translate([0, -ipThickness / 2, 0]) 
			square([ipWebSpacing * strands, ipThickness]);
	}    
}



// The Lid
module Lid() {
    difference() 
    {
        translate ([0,0,gLidHeight/2]) cube([TotalX, TotalY, gLidHeight], center = true);
        // remove the main part
        cube([TotalX-2*gWT, TotalY-2*gWT, gLidHeight*3],center=true);
        //Create the lip 1.5 mm lip deep and 1 mm wide
        translate([0, 0, gLidHeight+1-1.5]) cube ([TotalX-1.8, TotalY-1.8, 2], center = true);
        
        //Create the indent for the latch
        hull() 
        {
            translate ([-5.5,TotalY/2-gWT,3]) rotate([0, 90, 0])  {cylinder(h=11, r1 = 1.1, r2 = 1.1, $fn=30);}
            translate ([-5.5,TotalY/2-gWT,3.2]) rotate([0, 90, 0])  {cylinder(h=11, r1 = 1.1, r2 = 1.1, $fn=30);}
        }
        hull() 
        {
            translate ([-5.5,-TotalY/2+gWT,3]) rotate([0, 90, 0])  {cylinder(h=11, r1 = 1.1, r2 = 1.1, $fn=30);}
            translate ([-5.5,-TotalY/2+gWT,3.2]) rotate([0, 90, 0])  {cylinder(h=11, r1 = 1.1, r2 = 1.1, $fn=30);}
       }
    }

    // Spiderweb top
    if (gPattern == "Web")
    {
        intersection () 
        {    
            translate ([TotalX/2, TotalY/2,0]) linear_extrude(height = 1.5) 
            spider_web(WebSpacing, WebStrands, WedThickness, WebWedges);  
            
            cube([TotalX, TotalY, gLidHeight*2]); 
        }
    }

    // Hex top
    if (gPattern == "Hex")
    {
     translate([-TotalX/2,-TotalY/2,0]) linear_extrude(height = 1.5) {hex_lattice(TotalX,TotalY,6,2);}
    }

    // Diamond top
    if (gPattern == "Diamond")
    {
     translate([-TotalX/2,-TotalY/2,0]) linear_extrude(height = 1.5) {diamond_lattice(TotalX,TotalY,7,2);}
    }

    // Solid top
    if (gPattern == "Solid")
    {
     translate([0,0,1.5/2]) cube ([TotalX, TotalY, 1.5],center=true);
    }

    // fancy top
    if (gPattern == "Fish") 
    {
     translate([-TotalX/2,-TotalY/2,0]) linear_extrude(height = 1.5) {scale_lattice(TotalX,TotalY,7,1);}
    }
    
    // fancy top
    if (gPattern == "Fancy") 
    {
      translate([-TotalX/2,-TotalY/2,0]) linear_extrude(height = 1.5) circle_lattice(TotalX,TotalY);
    }
}

//  Main Box
module Box() {

    // create shell
    difference() {    
       translate([0,0,AdjBoxHeight/2]) cube([TotalX,TotalY,AdjBoxHeight],center=true);
       translate([0,0,AdjBoxHeight/2+gWT]) cube([TotalX-2*gWT,TotalY-2*gWT,AdjBoxHeight],center=true);
    } 

    // lip of box
    difference () {
        translate([0,0, AdjBoxHeight+1.5/2]) cube([TotalX-gWT,TotalY-gWT,1.5],center=true);
        translate([0,0, AdjBoxHeight+2/2]) cube([TotalX-gWT*2,TotalY-gWT*2,2],center=true);
    }

    //tab 1
    difference() 
    {
        translate([0, -TotalY/2+gWT+2/2, AdjBoxHeight + 11/2 - 6])  cube([10, 2, 11],center=true); 
        //slot for edge of lid
        translate([0, -TotalY/2+gWT+0.5/2, AdjBoxHeight + 2/2 + 1.5]) cube([10, 0.5, 2],center=true);
        translate ([-6, -TotalY/2+gWT, AdjBoxHeight - 6])rotate ([0,90,0]) linear_extrude(12) polygon([[0,0],[0,2],[-3,2]]);
    }
    translate ([-5,-TotalY/2+gWT,AdjBoxHeight+4]) rotate([0, 90, 0])  {cylinder(h=10, r1 = 1, r2 = 1,, $fn=30);}

    //tab 2
    difference() 
    {
        translate([0, TotalY/2-gWT-2/2, AdjBoxHeight+ 11/2 - 6]) cube([10, 2, 11],center=true); 
        translate([0, TotalY/2-gWT-0.5/2, AdjBoxHeight+2/2+1.5]) cube([10, 0.5, 2],center=true);
        translate ([-6, TotalY/2-gWT-2, AdjBoxHeight - 6])rotate ([0,90,0]) linear_extrude(12) polygon([[0,0],[-3,0],[0,2]]);
    }
    translate ([-5,TotalY/2-gWT,AdjBoxHeight+4]) rotate([0, 90, 0])  {cylinder(h=10, r1 = 1, r2 = 1, $fn=30);}
}




if((Render=="Both") || (Render == "Box")) {Box();}

if((Render=="Both") || (Render == "Lid")) {translate ([0,TotalY+10,0])  Lid();}

