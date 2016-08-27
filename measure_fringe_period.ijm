/* 
 *  Finds the fringe period in a given direction. Only works for stack of images with similar fringe periods.
 *  Requires the user to enter an estimate of peak seperation. Very naive implementation using Array.findMaxima()
 *   If a stack is open then the macro prints average fringe period for the stack. 
 *  
 *  __author__			=	Alireza Panna
 *  __status__          =   stable
 *  __date__            =   8/10/15
 *  __version__         =   1.0
 *  __to-do__			=				   
 *  __update-log__		= 	8/11/2016: displays the profile plots with the peak selections as well.
 *  					=   8/25/2016: fix minor bug in handling of stacks vs single image.
 */
var 
    tolerance = 3,
;
requires("1.49i");
macro "measure_fringe_period" {
	imgname = getTitle(); 
	// remove extension
	imgname_split = split(imgname,".");
    dir = getDirectory("image");
    // get input argument if any
	args = getArgument();
	freq_dim = newArray("Horizontal", "Vertical");
  	Dialog.create("Main Menu");
	Dialog.addNumber("Pixel Size:", 1, 3, 6, "mm");
	Dialog.addChoice("Profile Direction:", freq_dim, "Horizontal");
	Dialog.addNumber("Tolerance:", 3, 3, 6, "");
  	Dialog.show();
  	pixel_size = Dialog.getNumber();
  	dim_choice  = Dialog.getChoice();
  	tolerance = Dialog.getNumber();
  	fringe_period = 0;
  	profile_stack = 0;
	for (i = 1; i <= nSlices; i++) {
		// Remove scaling
		max_loc = newArray();
		setSlice(i);
		run("Set Scale...", "distance=0 global");
		type = selectionType();
		// If none, no line or no rectangle ROI selected then make one for full image.
		if (type != 0 && type != 5 && type == -1) {
			makeRectangle(0, 0, getWidth(), getHeight());
		}
    	// Plot x profile, get values and close profile
		if (dim_choice == "Horizontal") {
			setKeyDown("ctrl");
		}
		else if (dim_choice == "Vertical") {
    		setKeyDown("alt"); 
		}
		run("Plot Profile");
		Plot.getValues(x, y);
  	 	w = getWidth;
  	 	h = getHeight;
		close();
		// return location of maximum
		max_loc = Array.findMaxima(y, tolerance);
		Array.sort(max_loc);
		yOfmax = newArray(max_loc.length);
		for (j=0; j < max_loc.length; j++) {
			yOfmax[j] = y[max_loc[j]];
		}
		temp_period = max_loc[lengthOf(max_loc) - 1] - max_loc[0];
		period = temp_period /(lengthOf(max_loc) - 1);
		fringe_period += period * pixel_size;
		Plot.create("Plot", "Distance (pixels)", "Gray Value", x, y);
		Plot.setColor("blue");
		Plot.add("circles",max_loc, yOfmax);
		Plot.setColor("red");
		Plot.show();
		if (nSlices > 1 || imgname == "Stack") {
			selectImage("Plot");
			run("Copy");
			close();	
			if (profile_stack == 0 ) {
            	newImage("Profile Plots", "RGB", w, h, 1);
            	profile_stack = getTitle();
            	selectImage(profile_stack);
            	run("Paste");
            	selectImage(imgname);
        	} 
        	else {
            	selectImage(profile_stack);
            	run("Add Slice");
            	run("Paste");
            	selectImage(imgname);
        	}
        	selectImage(imgname);
        	print(getInfo("slice.label") + " Fringe Period:" + d2s(fringe_period, 6));
		}
		else {
			print(imgname + " Fringe Period:" + d2s(fringe_period, 6));
		}
	}
	fringe_period = fringe_period/nSlices;
	print("-----------------------------------------------");
	print("Average fringe Period:" + d2s(fringe_period, 6));
}