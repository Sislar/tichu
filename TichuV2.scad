$fn=50;

/* [Global] */

// Render
Objects = "Lid"; //  [Both, Box, Lid]

// use the following syntax to add 1 or more internal x compartment lengths (mm)
x_sizes = [90];
// use the following syntax to add 1 or more internal y compartment widths (mm)
y_sizes = [59,59];
// Total height including Lid
z_size = 20+4.2;

// Add Cylinder to each bucket for access
StdAccess = 1;
BinRounding = 1;

// Type of lid pattern
gPattern = "Tichu"; //  [Hex, Diamond, Web, Solid, Fancy, Leaf]
// Tolerance
gTol = 0.2;
// Wall Thickness
gWT = 2.0;

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
/* Private variables */

// Box Height
RailGrip = 2.0;
RailOpeningX = 2.2;
RailWidth = RailGrip+RailOpeningX;
LidH = 2.2;
NubWidth = 1.2;
NubSize = 1.4;
NubPos = 6;
SpringOpening = 1.6;
SpringLength = 16;

function SumList(list, start, end) = (start == end) ? 0 : list[start] + SumList(list, start+1, end);
// Box Length
TotalX = SumList(x_sizes,0,len(x_sizes)) + gWT*(len(x_sizes)+1);
// Box Width 
TotalY = SumList(y_sizes,0,len(y_sizes)) + RailWidth*2 + gWT*(len(y_sizes)-1);
TotalZ = z_size;

echo("Size: ",TotalX,TotalY);
   
// Height not counting the lid
AdjBoxHeight = TotalZ - LidH;

 module regular_polygon(order, r=1){
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
      } // End union
   }
}

module football() {
    scale([0.7,0.7])
    intersection(){
        translate([-4,0]) circle(6);
        translate([4,0]) circle(6);
    }
}

module leaf_lattice(ipX, ipY, DSize, WSize)  {
    lXOffset = 4;
    lYOffset = 22;

	difference()  {
		square([ipX, ipY]);
		for (x=[0:lXOffset:ipX]) {
            for (y=[0:lYOffset:ipY+lYOffset]){
  			   translate([x, y+(1/8*lYOffset)+0.5]) rotate([0,0,-45]) football();
			   translate([x, y+(3/8*lYOffset)]) rotate([0,0,45]) football();
  			   translate([x, y-(1/8*lYOffset)-0.5]) rotate([0,0,-45]) football();
			   translate([x, y-(3/8*lYOffset)]) rotate([0,0,45]) football();		}
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


module RCube(x,y,z,ipR=2) {
    translate([-x/2,-y/2,0]) hull(){
      translate([ipR,ipR,ipR]) sphere(ipR);
      translate([x-ipR,ipR,ipR]) sphere(ipR);
      translate([ipR,y-ipR,ipR]) sphere(ipR);
      translate([x-ipR,y-ipR,ipR]) sphere(ipR);
      translate([ipR,ipR,z-ipR]) sphere(ipR);
      translate([x-ipR,ipR,z-ipR]) sphere(ipR);
      translate([ipR,y-ipR,z-ipR]) sphere(ipR);
      translate([x-ipR,y-ipR,z-ipR]) sphere(ipR);
      }  
} 


module lid(ipPattern = "Hex", ipTol = 0.3){
  lAdjX = TotalX;
  lAdjY = TotalY-RailWidth*2-ipTol*2;  
  lAdjZ = LidH;
  CutX = lAdjX - 8;
  CutY = lAdjY - 8;
  lFingerX = 15;
  lFingerY = 16;  

    // add lip
    translate([-TotalX/2+1/2,0,-1/2]) cube([1,TotalY-16,1], center=true);
    
  // main square with center removed for a pattern. 0.01 addition is a kludge to avoid a 2d surface remainging when substracting the lid from the box.
  difference() {
      translate([0,0,lAdjZ/2]) cube([lAdjX+0.01, lAdjY+0.01 , lAdjZ], center=true);

      translate([0,0,lAdjZ/2]) cube([CutX, CutY, lAdjZ], center = true);
      translate([TotalX/2-gWT/2,0,LidH/2])cube([gWT+0.01,TotalY-RailWidth,LidH],center=true);

     // make a slot for the latch can flex         
     translate([TotalX/2-SpringLength/2,TotalY/2-RailWidth-SpringOpening/2-1.4,-1]) RCube(SpringLength,SpringOpening,4,0.4);
     translate([TotalX/2-SpringLength/2,-TotalY/2+RailWidth+SpringOpening/2+1.4,-1]) RCube(SpringLength,SpringOpening,4,0.4);
             
  }
  
  // The Side triangles
  difference() {
    intersection () {
      union () {
            translate([-TotalX/2,TotalY/2-RailWidth-gTol,0]) rotate([0,90,0]) 
                  linear_extrude(TotalX-1-gTol) polygon(points=[
                            [0,0],
                            [0,LidH],
                            [-RailOpeningX,0]]);
            translate([-TotalX/2,-TotalY/2+RailWidth+gTol,0]) 
                rotate([0,90,0]) 
                linear_extrude(TotalX-1-gTol) 
                polygon(points=[
                            [0,0],
                            [0,-LidH],
                            [-RailOpeningX,0]]);
              }
    }
       
        // cut notches into the railings
    translate([TotalX/2-(NubWidth+2*NubSize/2)-NubPos,TotalY/2-RailWidth+NubSize+gTol+0.2,0])
        hull(){
            translate([0,0]) cylinder(h=LidH, r = 0.2);
            translate([NubWidth+2*NubSize,0]) cylinder(h=LidH, r = 0.2);
            translate([NubWidth+NubSize,-NubSize]) cylinder(h=LidH, r = 0.2);
            translate([NubSize,-NubSize]) cylinder(h=LidH, r = 0.2);
        }


    translate([TotalX/2-(NubWidth+2*NubSize/2)-NubPos,-TotalY/2+RailWidth-NubSize-gTol-0.2,0])
         hull(){
            translate([0,0]) cylinder(h=LidH, r = 0.2);
            translate([NubWidth+2*NubSize,0]) cylinder(h=LidH, r = 0.2);
            translate([NubWidth+NubSize,NubSize]) cylinder(h=LidH, r = 0.2);
            translate([NubSize,NubSize]) cylinder(h=LidH, r = 0.2);
        }       
        
       // trim a little off the railing past the nub  TODO fix to new vars
        translate([TotalX/2,TotalY/2-LidH/2-ipTol,0]) cube([12,LidH,LidH*2],center=true); 
        translate([TotalX/2,-TotalY/2+LidH/2+ipTol,0]) cube([12,LidH,LidH*2],center=true); 
    
  }
 
  // Finger slot
  difference () {
      translate([-CutX/2,-lFingerY/2,0]) cube([lFingerX, lFingerY, lAdjZ]); 
      translate([-CutX/2+lFingerX/2,0,20+LidH/2])sphere(20);     
  }


  // Solid top
  if (ipPattern == "Solid") 
      {   
       difference (){ 
         translate([-CutX/2,-CutY/2,0]) cube([CutX, CutY,   lAdjZ]);
         translate([-CutX/2,-lFingerY/2,0]) cube([lFingerX, lFingerY, lAdjZ]); 
      }
    }
    

    
      // Tichu top
  if (ipPattern == "Tichu") 
    {   
       difference (){ 
         translate([-CutX/2,-CutY/2,0]) cube([CutX,CutY,LidH]);
         translate([-CutX/2,-lFingerY/2,0]) cube([lFingerX, lFingerY, lAdjZ]); 
         translate([0,(TotalY-2*RailWidth)/4,0]) scale([2,1,1]) cylinder(10,14,14);  
         translate([0,-(TotalY-2*RailWidth)/4,0]) scale([2,1,1]) cylinder(10,14,14);  
        }
    }

  // Leaf top
  if (ipPattern == "Leaf") 
    {   
       difference (){ 
         translate([-CutX/2,-CutY/2,0]) linear_extrude(height = lAdjZ) leaf_lattice(CutX,CutY,4,2);
         translate([-CutX/2,-lFingerY/2,0]) cube([lFingerX, lFingerY, lAdjZ]); 
      }
    }
}


module box () {
//  Main Box
  difference() {    
    translate ([0,0,AdjBoxHeight/2]) cube([TotalX,TotalY,AdjBoxHeight], center = true);

    // Scope out compartment areas
    for(nX=[0:len(x_sizes)-1])
    {
      for(nY=[0:len(y_sizes)-1])
      {
         xOffset = SumList(x_sizes,0,nX) + gWT*(nX+1) + x_sizes[nX]/2 - TotalX/2;
         yOffset = SumList(y_sizes,0,nY) + RailWidth + gWT*nY + y_sizes[nY]/2 - TotalY/2;
          
         translate([xOffset,yOffset,gWT]) RCube(x_sizes[nX], y_sizes[nY] ,AdjBoxHeight+20, BinRounding);
      }
    }
    
    // make room for lip
   translate([-TotalX/2+1/2,0,TotalZ-LidH-1/2]) cube([1.4,TotalY-14,1.4], center=true);

  }

// Left rail
    difference(){
    translate([0,TotalY/2-RailWidth/2,TotalZ-LidH/2])cube([TotalX, RailWidth, LidH], center=true);
    translate([-TotalX/2,TotalY/2-RailWidth,TotalZ-LidH]) rotate([0,90,0]) linear_extrude(TotalX) polygon(points=[
                    [0,0],
                    [0,LidH],
                    [-RailOpeningX,0]]);
    }
     
// right Rail      
    difference(){
    translate([0,-TotalY/2+RailWidth/2,TotalZ-LidH/2])cube([TotalX, RailWidth, LidH], center=true);
    translate([-TotalX/2,-TotalY/2+RailWidth,TotalZ-LidH]) 
        rotate([0,90,0]) 
        linear_extrude(TotalX) 
        polygon(points=[
                    [0,0],
                    [0,-LidH],
                    [-RailOpeningX,0]]);
    }      

    
   // add backstop
    difference(){
   translate([TotalX/2-1/2,0,TotalZ-LidH/2])cube([1,TotalY-RailWidth,LidH],center=true);
//   translate([TotalX/2-1/2,0,TotalZ-LidH/2])cube([1,TotalY-16,LidH],center=true);

    }
  
    // create the latch nubs
    translate([TotalX/2-(NubWidth+2*NubSize/2)-NubPos,+TotalY/2-RailGrip,TotalZ-LidH])
      linear_extrude(LidH) 
         polygon([
                    [0,0],
                    [NubWidth+2*NubSize,0],
                    [NubWidth+NubSize,-NubSize],
                    [NubSize,-NubSize]], paths=[[0,1,2,3]]);

    translate([TotalX/2-(NubWidth+2*NubSize/2)-NubPos,-TotalY/2+RailGrip,TotalZ-LidH])
      linear_extrude(LidH) 
         polygon([
                    [0,0],
                    [NubWidth+2*NubSize,0],
                    [NubWidth+NubSize,NubSize],
                    [NubSize,NubSize]], paths=[[0,1,2,3]]);
} 

// Production Box
if ((Objects == "Both") || (Objects == "Box")){
  intersection() {
     box();
     RCube(TotalX,TotalY,TotalZ,1);
  }
}

// Production Lid
if ((Objects == "Both")  || (Objects == "Lid")){
  translate([-TotalX - 10,0,0]) lid(ipPattern = gPattern, ipTol = gTol);
}


