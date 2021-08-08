// Parametultimate Drawer System - Box
// by Chris Jones <cmsj@tenshu.net
// Licensed as GPL v2
//
// Inspired by Marc Elbichon's "Ultimate Drawer System"
// https://www.prusaprinters.org/prints/17862-ultimate-drawer-system


/* [Part selection] */
// The part to print
PART = "B"; // [B:Box, D:Drawer]

/* [Box: Common Parameters] */
// Number of U in the Box
uNum = 8;
// Outer width of the Box (mm)
boxOuterWidth = 130;
// Outer depth of the Box (mm)
boxOuterDepth = 130;
// Mounting bolt shaft diameter (mm)
mountingBoltShaftDiameter = 4;
// Mounting bolt head diameter (mm)
mountingBoltHeadDiameter = 8;
// Mounting bolt head height (mm)
mountingBoltHeadHeight = 2;
// Mounting nut diameter (mm)
mountingNutDiameter = 7.5;
// Mounting nut thickness (mm)
mountingNutThickness = 3;
// Mounting screw countersink depth (mm)
mountingScrewCountersinkDepth = 3;

/* [Box: Advanced Parameters] */
// Height of a single drawer (mm)
uHeight = 19;
// Thickness of the Box's frame (mm)
boxFrameThickness = 5;
// Number of rear braces
boxBraceCount = 2;
// Rail thickness (mm)
railThickness = 1.7;
// Rail inset into Box side walls (mm)
railSideInset = 3.6;
// Rail offset from Box rear (mm)
railRearOffset = 8;
// Mounting screw diameter tolerance (mm)
mountingBoltShaftDiameterTolerance = 0.2;
// Mounting hole corner offset (mm)
boxMountingCornerOffset = 12;
// Mounting hole edge offset (mm)
boxMountingEdgeOffset = 14;

/* [Box: Mounting Parameters] */
// Mounting holes for the top of the Box
boxTopMounting = "N"; // [B:Bolt, S:Screw, N:Nut, Z:Nothing]
// Mounting holes for the left of the Box
boxLeftMounting = "S"; // [B:Bolt, S:Screw, N:Nut, Z:Nothing]
// Mounting holes for the right of the Box
boxRightMounting = "N"; // [B:Bolt, S:Screw, N:Nut, Z:Nothing]
// Mounting holes for the bottom of the Box
boxBottomMounting = "S"; // [B:Bolt, S:Screw, N:Nut, Z:Nothing]
// Rear mounting tabs
boxRearMounting = true;
// Depth of rear mounting tabs and braces (mm)
boxRearMountingDepth = 2.3;

/* [Drawer: Common Parameters] */
// Height of the drawer (U)
drawerUHeight = 1;
// Rows of compartments
drawerRows = 4;
// Columns of compartments
drawerColumns = 3;
// Width if interior/exterior drawer walls (mm)
drawerWallWidth = 1;
// Width of drawer handle (mm)
drawerHandleWidth = 2;
// Length of drawer handle (mm)
drawerHandleLength = 15;

/* [Hidden] */
fudge = 0.1; // This is necessary to avoid Z-fighting when performing boolean operations on objects that share exactly aligned faces.

// Derived parameters
boxInnerWidth = boxOuterWidth - (boxFrameThickness * 2);
boxInnerHeight = uHeight * uNum;
boxOuterHeight = uHeight * uNum + (boxFrameThickness * 2);
boxBraceSpacing = boxInnerHeight / (boxBraceCount + 1);
mountingHoleDiameter = mountingBoltShaftDiameter + mountingBoltShaftDiameterTolerance;
mountingHoleRadius = mountingHoleDiameter / 2;
drawerOuterWidth = boxInnerWidth - 1;
drawerOuterHeight = drawerUHeight * uHeight;
drawerOuterDepth = boxOuterDepth - railRearOffset;
drawerInnerWidth = drawerOuterWidth - (1 * drawerWallWidth); // FIXME: Why is this 1*drawerWallWidth, it should be 2*, but that produces the wrong output
drawerInnerDepth = drawerOuterDepth - (1 * drawerWallWidth); // FIXME: Why is this 1*drawerWallWidth, it should be 2*, but that produces the wrong output
drawerSkirtWidth = railSideInset - 1;
drawerSkirtHeight = railThickness - 1;
drawerMidWidth = ((2 * drawerSkirtWidth) + drawerOuterWidth) / 2 - (drawerHandleWidth / 2);
drawerOuterSkirtWidth = drawerOuterWidth + (2 * drawerSkirtWidth);
drawerCompartmentWidth = (drawerInnerWidth / drawerColumns) - drawerWallWidth;
drawerCompartmentDepth = (drawerInnerDepth / drawerRows) - drawerWallWidth;

// Useful for debugging changes to the screw/nut holes
//bottomMountingHole(0, -80, 0);
//topMountingHole(0, -100, 0);
//rightMountingHole(0, -120, 0);
//leftMountingHole(0, -140, 0);

// Create the chosen part
if (PART == "B") {
    box();
}
if (PART == "D") {
    drawer();
}

// Model generators
module box() {
    // Create the Box
    difference() {
        // Outer box
        cube([boxOuterWidth, boxOuterDepth, boxOuterHeight]);
    
        // Hollow the box
        translate([boxFrameThickness, -fudge, boxFrameThickness])
            cube([boxInnerWidth, (boxOuterDepth + (2*fudge)), boxInnerHeight]);
        
        // Shelf rails
        for (u = [0:uNum - 1]) {
            translate([(boxFrameThickness - railSideInset),  -fudge, (boxFrameThickness + (uHeight * u))])
                cube([boxInnerWidth + (railSideInset * 2), ((boxOuterDepth + fudge) - railRearOffset), railThickness]);
        }
        // Scoop rail entries
        for (u = [0:uNum - 1]) {
            translate([(boxFrameThickness - railSideInset), -fudge, (boxFrameThickness + (uHeight * u))])
                rotate([0, 90, 0]) {
                    linear_extrude(boxInnerWidth + (2 * railSideInset + fudge)) {
                        // Special case the lowest rail scoop so it doesn't clip the bottom of the box
                        if (u == 0) {
                            polygon(points = [[0, 12], [-5, 0], [0, 0]]);
                        } else {
                            polygon(points = [[0, 12], [-5, 0], [5, 0]]);
                        }
                        
                    }
                }
        }

        // Top/bottom structural non-rails
        // (These look like rails, but they are just to stiffen the top/bottom
        structAreaWidth = boxOuterWidth - (4 * boxMountingCornerOffset);
        numStructures = ceil(structAreaWidth / (uHeight + railThickness));
        structSeparation = structAreaWidth / numStructures;
        for (s = [0:numStructures - 1]) {
            translate([2*boxMountingCornerOffset + (structSeparation / numStructures) + (s * structSeparation) + (s * railThickness), boxRearMountingDepth, boxFrameThickness - railSideInset]) {
                // Bottom wall inset
                cube([railThickness, boxOuterDepth - (2 * boxRearMountingDepth), railSideInset + fudge]);
                // Top wall inset
                translate([0, 0, boxInnerHeight + railSideInset - fudge])
                    cube([railThickness, boxOuterDepth - (2 * boxRearMountingDepth), railSideInset + fudge]);
            }
        }
        
        // Top mounting holes
        // Front left
        topMountingHole(boxMountingCornerOffset, boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness);
        // Rear left
        topMountingHole(boxMountingCornerOffset, boxOuterDepth - boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness);
        // Front right
        topMountingHole(boxOuterWidth - boxMountingCornerOffset, boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness);
        // Rear right
        topMountingHole(boxOuterWidth - boxMountingCornerOffset, boxOuterDepth - boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness);
    
        // Left mounting holes
        // Front bottom
        leftMountingHole(boxFrameThickness, boxMountingEdgeOffset, boxMountingCornerOffset);
        // Rear bottom
        leftMountingHole(boxFrameThickness, boxOuterDepth - boxMountingEdgeOffset, boxMountingCornerOffset);
        // Front top
        leftMountingHole(boxFrameThickness, boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness - boxMountingCornerOffset);
        // Rear top
        leftMountingHole(boxFrameThickness, boxOuterDepth - boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness - boxMountingCornerOffset);
        
        // Right mounting holes
        // Front bottom
        rightMountingHole(boxOuterWidth - boxFrameThickness, boxMountingEdgeOffset, boxMountingCornerOffset);
        // Rear bottom
        rightMountingHole(boxOuterWidth - boxFrameThickness, boxOuterDepth - boxMountingEdgeOffset, boxMountingCornerOffset);
        // Front top
        rightMountingHole(boxOuterWidth - boxFrameThickness, boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness - boxMountingCornerOffset);
        // Rear top
        rightMountingHole(boxOuterWidth - boxFrameThickness, boxOuterDepth - boxMountingEdgeOffset, boxOuterHeight - boxFrameThickness - boxMountingCornerOffset);
        
        // Bottom mounting holes, if chosen
        // Front left
        bottomMountingHole(boxMountingCornerOffset, boxMountingEdgeOffset, -fudge);
        // Rear left
        bottomMountingHole(boxMountingCornerOffset, boxOuterDepth - boxMountingEdgeOffset, -fudge);
        // Front right
        bottomMountingHole(boxOuterWidth - boxMountingCornerOffset, boxMountingEdgeOffset, -fudge);
        // Rear right
        bottomMountingHole(boxOuterWidth - boxMountingCornerOffset, boxOuterDepth - boxMountingEdgeOffset, -fudge);
    }
    
    // Add Rear mounting tabs
    if (boxRearMounting == true) {
        // rearMountingTab() forces a tab radius of 19mm, and we're hard coding the screw hole offset at 8.5mm
        screwHoleOffset = 8.5;
        // Bottom left
        rearMountingTab(0, 90, boxFrameThickness, boxFrameThickness, screwHoleOffset, screwHoleOffset);
        // Bottom right
        rearMountingTab(90, 180, boxOuterWidth - boxFrameThickness, boxFrameThickness, -screwHoleOffset, screwHoleOffset);
        // Top left
        rearMountingTab(270, 360, boxFrameThickness, boxOuterHeight - boxFrameThickness, screwHoleOffset, -screwHoleOffset);
        // Top right
        rearMountingTab(180, 270, boxOuterWidth - boxFrameThickness, boxOuterHeight - boxFrameThickness, -screwHoleOffset, -screwHoleOffset);
    }
    
    // Add Rear braces
    if (boxBraceCount > 0) {
        for (b = [1:boxBraceCount]) {
            translate([boxFrameThickness - fudge, boxOuterDepth - boxRearMountingDepth, boxFrameThickness + (b * boxBraceSpacing)])
                cube([boxInnerWidth + (2 * fudge), boxRearMountingDepth, 5]);
        }
    }
}


module drawer() {
    difference() {
        union() {
            // Draw the skirt and base of the drawer
            cube([drawerOuterSkirtWidth, drawerOuterDepth, drawerSkirtHeight]);
            // Draw the outer box of the drawer
            translate([drawerSkirtWidth, 0, 0])
                cube([drawerOuterWidth, drawerOuterDepth, drawerOuterHeight]);
            // Draw the handle
            intersection() {
                translate([drawerMidWidth, -drawerHandleLength, 0]) {
                    cube([drawerHandleWidth, drawerHandleLength, uHeight - 2]);
                }
                translate([drawerMidWidth, -0, min(drawerHandleLength, (uHeight - 2)/2)]) {
                    rotate([0, 90, 0]) {
                        linear_extrude(drawerHandleWidth)
                            circle(r = drawerHandleLength);
                    }
                }
            }
            // FIXME: Add optional label holder
        }
        
        // Subtract the compartments
        for(r = [0:drawerRows - 1]) {
            for(c = [0:drawerColumns - 1]) {
                translate([drawerSkirtWidth + drawerWallWidth + (drawerCompartmentWidth * c) + (drawerWallWidth * c), drawerWallWidth + (drawerCompartmentDepth * r) + (drawerWallWidth * r), drawerWallWidth])
                    cube([drawerCompartmentWidth, drawerCompartmentDepth, drawerOuterHeight]);
            }
        }
    }
}

// Part generators
module bottomMountingHole(x=0, y=0, z=0) {
    holeHeight = boxFrameThickness + (3 * fudge);
    if (boxBottomMounting == "S") {
        orientedCountersunkHole(holeHeight, x, y, z + holeHeight - fudge, 0, 180, 0);
    }
    if (boxBottomMounting == "N") {
        orientedHexNutHole(holeHeight, x, y, z + holeHeight - fudge, 0, 180, 0);
    }
    if (boxBottomMounting == "B") {
        orientedBoltHole(holeHeight, x, y, z + holeHeight - fudge, 0, 180, 0);
    }
}
module topMountingHole(x=0, y=0, z=0) {
    holeHeight = boxFrameThickness + (3 * fudge);
    if (boxTopMounting == "S") {
        orientedCountersunkHole(holeHeight, x, y, z - fudge, 0, 0, 0);
    }
    if (boxTopMounting == "N") {
        orientedHexNutHole(holeHeight, x, y, z - fudge, 0, 0, 0);
    }
    if (boxTopMounting == "B") {
        orientedBoltHole(holeHeight, x, y, z - fudge, 0, 0, 0);
    }
}
module rightMountingHole(x=0, y=0, z=0) {
    holeHeight = boxFrameThickness + (3 * fudge);
    if (boxRightMounting == "S") {
        orientedCountersunkHole(holeHeight, x - fudge, y, z + mountingHoleDiameter, 0, 90, 0);
    }
    if (boxRightMounting == "N") {
            orientedHexNutHole(holeHeight, x - fudge, y, z + mountingHoleDiameter, 0, 90, 0);
    }
    if (boxRightMounting == "B") {
        orientedBoltHole(holeHeight, x - fudge, y, z + mountingHoleDiameter, 0, 90, 0);
    }
}
module leftMountingHole(x=0, y=0, z=0) {
    holeHeight = boxFrameThickness + (3 * fudge);
    if (boxLeftMounting == "S") {
        orientedCountersunkHole(holeHeight, x + fudge, y, z + mountingHoleDiameter, 0, -90, 0);
    }
    if (boxLeftMounting == "N") {
        orientedHexNutHole(holeHeight, x + fudge, y, z + mountingHoleDiameter, 0, -90, 0);
    }
    if (boxLeftMounting == "B") {
        orientedBoltHole(holeHeight, x + fudge, y, z + mountingHoleDiameter, 0, -90, 0);
    }
}
module rearMountingTab(angleStart = 0, angleEnd = 90, tab_x = 0, tab_z = 0, hole_x = 8.5, hole_y = 8.5) {
    translate([tab_x, boxOuterDepth, tab_z]) {
        rotate([90, 0, 0]) {
            difference() {
                linear_extrude(boxRearMountingDepth)
                    pie_slice(19, angleStart, angleEnd);
                translate([hole_x, hole_y, -fudge])
                    cylinder(boxRearMountingDepth + (2 * fudge), r = mountingHoleRadius);
            }
        }
    }
}



// Third party helper modules/functions
module hexagon(radius=10, height=20) {
    cylinder(r=radius, h=height, $fn=6);
}
module orientedHexNutHole(holeHeight=0, x=0, y=0, z=0, rx=0, ry=0, rz=0) {
    translate([x, y, z]) {
        rotate([rx, ry, rz]) {
            cylinder(h = holeHeight, d = mountingHoleDiameter, $fn=30);
            translate([0, 0, 0])
                hexagon(radius=mountingNutDiameter/2, height=mountingNutThickness);
        }
    }
}
module orientedBoltHole(holeHeight=0, x=0, y=0, z=0, rx=0, ry=0, rz=0) {
    translate([x, y, z]) {
        rotate([rx, ry, rz]) {
            cylinder(h = holeHeight, d = mountingHoleDiameter, $fn=30);
            translate([0, 0, 0])
                cylinder(d = mountingBoltHeadDiameter, h = mountingBoltHeadHeight, $fn=30);
        }
    }
}
module orientedCountersunkHole(holeHeight=0, x=0, y=0, z=0, rx=0, ry=0, rz=0) {
    translate([x, y, z]) {
        rotate([rx, ry, rz])
            countersunkScrewHole(height=holeHeight);
    }
}
module countersunkScrewHole(height) {
    union() {
        cylinder(h=mountingScrewCountersinkDepth + fudge, r1=mountingBoltHeadDiameter/2, r2=mountingHoleDiameter/2, $fn=30);
        cylinder(h = height, r = mountingHoleDiameter/2, $fn=30);
    }
}
module pie_slice(r, start_angle, end_angle) {
    R = r * sqrt(2) + 1;
    a0 = (4 * start_angle + 0 * end_angle) / 4;
    a1 = (3 * start_angle + 1 * end_angle) / 4;
    a2 = (2 * start_angle + 2 * end_angle) / 4;
    a3 = (1 * start_angle + 3 * end_angle) / 4;
    a4 = (0 * start_angle + 4 * end_angle) / 4;
    if(end_angle > start_angle)
        intersection() {
        circle(r);
        polygon([
            [0,0],
            [R * cos(a0), R * sin(a0)],
            [R * cos(a1), R * sin(a1)],
            [R * cos(a2), R * sin(a2)],
            [R * cos(a3), R * sin(a3)],
            [R * cos(a4), R * sin(a4)],
            [0,0]
       ]);
    }
}
