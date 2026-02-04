// randomly generate condensate masks that are inside the nucleus but do not overlap with condensates
roiManager("reset"); // clear roi manager

// open original nucleus image
showMessage("Open the image containing the whole nucleus");
run("Open...");
if (nImages==0)
print("No stack is open");
else {
	var c561="image";
	title1= getTitle();
	directory1 = getDirectory("image");
	width1=getWidth();
	height1=getHeight();
	depth1=nSlices();
	getPixelSize(unit1,pw1,ph1);
	}

// open existing condensate mask image
showMessage("Open the binary condensate mask image");
run("Open...");
setAutoThreshold("Default dark 16-bit no-reset");
//run("Threshold...");
run("Create Selection");
roiManager("Add");

// get all points included in the nucleus
selectWindow(title1);
waitForUser("Draw nuclear mask and select in ROI manager");
Roi.getContainedPoints(nuclearPoints_X, nuclearPoints_Y);
Roi.getBounds(nucX, nucY, nucW, nucH);

numROI = roiManager("count");
numMask = numROI-1;

// get all points of condensate masks and compile into one array (last ROI in list is nucleus)
allRoiPoints_X = newArray();
allRoiPoints_Y = newArray();
for (i = 0; i < numMask; i++) {
	roiManager("select", i);
	Roi.getContainedPoints(ogROI_X, ogROI_Y);
	allRoiPoints_X = Array.concat(allRoiPoints_X, ogROI_X);
	allRoiPoints_Y = Array.concat(allRoiPoints_Y, ogROI_Y);
}

// generate new random ROI from existing condensate ROI, check contained points against
// 1) nucleus points and 2) condensate points
// waitForUser("Select ROI to randomize")

for (i = 0; i < numMask; i++) {
	count = 0;
	while(count == 0) {
		roiManager("select", i);
		roiManager("add"); // duplicates original condensate ROI and adds to end of ROI manager list
		roiManager("select", roiManager("count")-1);
		angleMove = random()*360;
		xMove = random()*nucW;
		yMove = random()*nucH;
		Roi.move(xMove, yMove);
		run("Rotate...", "rotate angle=" + angleMove);
		roiManager("update");
		Roi.getContainedPoints(newROI_X, newROI_Y);
		// check if new ROI is in nucleus but does not overlap with old ROI
		nucTracker = 0;
		allRoiTracker = 0;
		for (j = 0; j < newROI_X.length; j++) {
			roi_X = newROI_X[j];
			roi_Y = newROI_Y[j];
			if (containsPoint(nuclearPoints_X, nuclearPoints_Y, roi_X, roi_Y)) {
				nucTracker++;
			}
			if (containsPoint(allRoiPoints_X, allRoiPoints_Y, roi_X, roi_Y)) {
				allRoiTracker++;
			}
		}	
		if(nucTracker==newROI_X.length && allRoiTracker==0) {
			count++;
		}
		else {
			roiManager("select", roiManager("count")-1);
			roiManager("delete");
		}

	}
}

// verify new cluster, create mask on black background, and save
newImage("Mask2Stack", "16-bit black", width1, height1, depth1);
waitForUser("Select randomly generated ROI and combine multiple if necessary");

//selectWindow(title1);
run("Create Mask");
selectWindow("Mask");
run("Copy");
selectWindow("Mask2Stack"); //will populate mask to empty image (Mask2Stack)
run("Paste");
selectWindow("Mask");
run("Close");

//To change the pixel values of the nuclear mask into binary system (0/1)
selectWindow("Mask2Stack");
run("Divide...", "value=255 stack");
setMinAndMax(0, 1);

saveAs("tiff", directory1+"/"+title1+"_NucleusClusterMasked_nonCondensate"+".tif");
run("Close");

//To close all the stacks
selectWindow(title1);
run("Close");
run("Close");

run("Close All");

function containsPoint(x_list, y_list, x_val, y_val) {
	for (i = 0; i < x_list.length; i++) {
	       if (x_list[i] == x_val && y_list[i] == y_val) {
	            return true;
	       }
	}
	return false;
}

