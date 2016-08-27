/*
 * adapted from Martin Höhne macro code Ortho_view_movie
 * 
 * __author_		=	'Alireza Panna'
 * __version__		=	'1.0'
 * __status__   	=   "development"
 * __date__			=	05/27/2015
 * __to-do__		=
 * __update-log__	=	
 */

// define z-color globally. Needs to be available in the macro and in the function 
var colZ_arr = newArray(255, 255, 255); // same color as colZ in RGB 

macro "ortho_view" { 
	view_choice = newArray("Single Slice", "All slices");
	Dialog.create("Select view");
	Dialog.addChoice("Choose the view:", view_choice, "Single Slice");
	Dialog.show();
	view = Dialog.getChoice();
	
	// color for XZ view 
	colX = "red"; 
	colX_arr = newArray(255, 0, 0);
	// color for YZ view 
	colY = "blue"; 
	colY_arr = newArray(0, 0, 255); 
	// color for XY view 
	colZ = "white"; 
	colZ_arr = newArray(255, 255, 255); 
	// color for background canvas 
	colCanvas_arr = newArray(0, 0, 0); // black 
	
	// No images should be previously open in imageJ 
	// The following method will close all opened images before proceeding.
	if (nImages() != 0) {
		showMessageWithCancel("Warning", "Press OK to close currently open images");
		run("Close All");
	}
	// Make a stack of the recon images
	dir = make_init_stack(); // see function make_init_stack()
	setBatchMode(false);
	
	//open stack file. This is the XY view
	open(dir + "Stack.tif");
	imgID = getImageID(); 
	getDimensions(width, height, channels, slices, frames); 
	getVoxelSize(voxwidth, voxheight, depth, unit); 
	if(view ==  "Single Slice") {
		run("Orthogonal Views"); 
		msg1 = "\nPostion the crosshair in the xy window."+ 
        	   "\n(original stack)"+ 
           	   "\n \nWhen done, continue with OK"; 
		waitForUser(msg1); 
		setBatchMode(true);
		// get the position where the user has put the yellow cross-hair in the xy-stack. The position is read from the titles 
		// of the YZ and XZ images using the function "ccord" --> see below 
		for (i = 1; i <= 3; i++) { 
        	img = getTitle(); 
        
        	if (substring(img, 0, 2) == "YZ") { 
                	yzID = getImageID(); 
                	x = coord(img); 
                	rename("YZ_" + x); // no space in title allowed to combine stacks later in macro 
                	yztitle = getTitle(); 
        	} 
        	if (substring(img, 0, 2) == "XZ") { 
                	xzID = getImageID(); 
                	y=coord(img); 
                	rename("XZ_" + y); // no space in title allowed to combine stacks later in macro 
                	xztitle = getTitle(); 
        	} 
        	close(); 
        	// in the first round the original image is still selected and closed 
        	// in the next two round the YZ and XZ views are selected, resp. 
        	// I could not find another way of getting hold of the titles of the 
        	// XZ and YZ windows 
	} 
		// image has to be reopened 
		open(dir + "Stack.tif"); 
		imgID = getImageID();
		selectImage(imgID); 
		// reslice YZ 
		// produce a single y-slice at the x-position chosen by the user in the xy view by placing the crosshair 
    	makeLine(x, 0, x, height); 
    	run("Add Selection...", "stroke=" + colY + " width=1"); // add the vertical crosshair line to the selection 
    	run("Reslice [/]...", "output=" + depth + " slice_count=1 rotate"); 
    	getDimensions(w, h, c, s, f); // dimensions are dependent on depth, i.e. slice thickness 
    	run("Canvas Size...","width=" + w + 4 + " height=" + h + 4 + " position=Center"); 
    	rename("YZ"); 
    	orthoYZ = getImageID(); 
    	makestack(orthoYZ, slices, width, height, voxwidth, voxheight, depth, 1); // makestack function see below 
    	selectImage(imgID); 
		// reslice XZ 
		// produce a single x-slice at the y-position chosen by the user in the xy view by placing the crosshair 
    	makeLine(0, y, width, y); 
    	run("Add Selection...", "stroke=" + colX + " width=1"); // add the horizontal crosshair line to the selection 
    	run("Reslice [/]...", "output=" + depth +" slice_count=1"); 
   		getDimensions(w, h, c, s, f); // dimensions are dependent on depth, i.e. slice thickness 
    	rename("XZ");
    	orthoXZ = getImageID(); 
    	makestack(orthoXZ, slices, width, height, voxwidth, voxheight, depth, 2); //makestack function see below  
		selectImage(imgID); 
    	run("Canvas Size...", "width=" + width + 4 + " height=" + height + 4 + " position=Center"); 
	}

	else if (view == "All Slices") {
		setBatchMode(true);
		// XY view
		selectImage(imgID); 
    	run("Canvas Size...", "width=" + width + 4 + " height=" + height + 4 + " position=Center"); 
		// YZ view
		run("Reslice [/]...", "output=1.000 start=Left rotate avoid");
		rename("YZ");
		getDimensions(w,h,c,s,f); //dimensions are dependent on depth, i.e. slice thickness 
    	run("Canvas Size...","width="+w+4+" height="+h+4+" position=Center"); 
		selectImage(imgID);
		// XZ view
		run("Reslice [/]...", "output=1.000 start=Top avoid");
		rename("XZ");
   		getDimensions(w,h,c,s,f); //dimensions are dependent on depth, i.e. slice thickness 
    	run("Canvas Size...","width="+w+4+" height="+h+" position=Center");       
    	//3D view
    	selectImage(imgID);
    	run("3D Project...", "projection=[Brightest Point] axis=Y-Axis slice=1 initial=0 total=360 rotation=0 lower=1 upper=65536 opacity=0 surface=100 interior=50");
    	run("32-bit");
    	run("16-bit");
    	rename("XYZ");
    	getDimensions(w,h,c,s,f); //dimensions are dependent on depth, i.e. slice thickness
    	run("Canvas Size...", "width=" + width + 4 + " height=" + height + 4 + " position=Center"); 
    	// run and save MIPs of all ortho views. 
    	selectImage(imgID);
    	run("Z Project...", "projection=[Max Intensity]");
    	saveAs("Tiff", dir + "MIP_XY");
    	selectImage("YZ");
    	run("Z Project...", "projection=[Max Intensity]");
    	saveAs("Tiff", dir + "MIP_YZ");
    	selectImage("XZ");
    	run("Z Project...", "projection=[Max Intensity]");
    	saveAs("Tiff", dir + "MIP_XZ");
	}
    run("Combine...", "stack1=[Stack.tif] stack2=[YZ]"); 
    rename("XY_YZ"); 
    run("Combine...", "stack1=[XY_YZ] stack2=[XZ] combine");
    rename("XY_YZ_XZ");
    
    if (view == "Single Slice") {
    makeLine(x, 0, x, height);
	run("Add Selection...", "stroke=" + colY + " width=0.1"); // add the vertical crosshair line to the selection 
    makeLine(0, y, width, y);
	run("Add Selection...", "stroke=" + colX + " width=0.1"); // add the horizontal crosshair line to the selection 
    } 
    else {
    	run("Combine...", "stack1=[XY_YZ_XZ] stack2=[XYZ]");
    	rename("all_views");
    }
    setBatchMode(false); 
} 
        
/*==========================================FUNCTIONS=====================================================*/ 
function make_init_stack() {
    setBatchMode(true);
	// Open the first image file in the sequence.
    image_0 = File.openDialog("Pick a 'rec' image *.tif");
    // get image directory only
    image_dir =  File.directory;
    // Seperate the file name and the complete path name
    img_0 = File.name;
    open(img_0);
    // get image size as well
    w = getWidth;
  	h = getHeight;
  	close(img_0);
	// Get all files in that directory. 
	fileList = getFileList(image_dir);
	actual_fileList = newArray();
	temp_width = 0;
	temp_height = 0;
	for (i = 0; i < fileList.length; i++) {
		// first check for .tif extension
		if(endsWith(fileList[i], ".tif")) {
			// now check if rec is in filename
			name_split = split(fileList[i], "_");
    		// find if 'rec' is present in filename
    		for (j = 0; j < name_split.length; j++) {
    			if (startsWith(name_split[j], "rec")) {
    				open(fileList[i]);
    				temp_width = getWidth;
					temp_height = getHeight;	
    				if(temp_width != w && temp_height != h) {
						close(fileList[i]);
					}
				}	
    		}
		}	
	}

	for (i = 0; i < actual_fileList.length; i++) {
		open(actual_fileList[i]);
	}
	run("Images to Stack", "name=Stack title=[] use");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
	saveAs("Tiff", image_dir + "Stack");
	run("Close All");
	return image_dir;
}

function coord(imgname) { 
        // function returns the x or y value of the selected section. Extracted from the image title 
        // (e.g. title = YZ 123) --> 123 is returned 
        string = substring(imgname, 3, lengthOf(imgname)); 
        return parseInt(string); // Converts string to an integer and returns it. Returns NaN if the string cannot be converted into a integer. 
} 

function makestack(imgID, slices, xmax, ymax, voxwidth, voxheight, depth, orient) { 
        // duplicate the YZ or the XZ image resp. z-times (i.e. make a stack with 
        // identical number of slices as the original x-y-z stack. 
        // Draw a line in each of the images indicating a different z-position. If the z-slice 
        // is thicker than 1 pixel (interpolated) the line is drawn in the middle of the slice position 
        // 
        // The last argument of the function (orient) is needed for the orientation. I.e. to differentiate between x and y view 
        
        neuID = getImageID(); 
        titel = getTitle(); 
        run("Select All"); 
        run("Copy"); 
        run("Duplicate...", "title=["+titel+"]"); 
        dup = getImageID(); 
        selectImage(neuID); 
        close(); 
        selectImage(dup); 
        for (i = 0; i < slices; i++) { 
                run("Paste"); 
                // draw line indicating the z-plane 
                        if (orient == 1) { 
                                zspace = depth/voxwidth; // take thickness of z-slices into account 
                        } 
                        if (orient == 2) { 
                                zspace = depth/voxheight; 
                        } 
                run("Add Slice"); 
        } 
        run("Delete Slice"); 
} 
 