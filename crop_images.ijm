 /* 
 *  This macro performs the same function as crop_images.sav
 *  
 *  __author__			=	'Alireza Panna'
 *  __status__          =   "stable"
 *  __date__            =   "03/01/15"
 *  __version__         =   "1.0"
 *  __to-do__			=	make it faster. 
 *  __update-log__		= 	3/12/15: code clean-up
 *  						3/14/15: added functionality to remember last crop setting
 *  						4/18/15: Fixed off by one issue in crop
 *  						8/07/15: Fixed issue of not working when delimiter is tiff instead of tif, Removed dependency of selecting 
 *  								 _0 image.
 *  						8/14/15: Completely re-worked, to increase processing speed.
 */
 
macro "crop_images" {
	// Select the image and get the directory
    image_0 = File.openDialog("Pick an image *_");
    temp = split(File.nameWithoutExtension, "_");
    image_0_noext = "";
    for(i = 0; i < lengthOf(temp) - 1; i++) {
    	image_0_noext = image_0_noext + temp[i]; 
    }
    var image_dir =  File.directory;
    setBatchMode(true);
	// Get all files in that directory. 
	fileList = getFileList(image_dir); 
    var image_names = newArray();
    dark_field = "";
	flat_field = "";
	
	// Open images in  a virtual stack using regex i.e. if file name contains _[counter]
	run("Image Sequence...", "open=[&image_0]"+"file=(^" + image_0_noext + "_[0-9]) sort use");
	// Remove scaling
	run("Set Scale...", "distance=0 global");
	rename("Stack");
	num_images = nSlices;
	// Save all file names into an array
	for (i = 1; i <= num_images; i++) {
		setSlice(i);
		image_names = Array.concat(image_names,  getInfo("slice.label"));
	}
	// Ask for correction
	Dialog.create("");
	Dialog.addNumber("Set DF correction setting (0-none, 1-dark only, 2-dark & flat):", 0);
	Dialog.show();
	df_corr = Dialog.getNumber();
	// Create Crop roi based on co-ordinates
	Dialog.create("");
	Dialog.addMessage("Set upperleft X, Y and lowerright X, Y (0 for previous setting):")
	Dialog.addNumber("upperleft X:", 0);
	Dialog.addNumber("upperleft Y:", 0);
	Dialog.addNumber("lowerright X:", 0);
	Dialog.addNumber("lowerright Y:", 0);
	Dialog.show();

	upper_left_x = Dialog.getNumber();
	upper_left_y = Dialog.getNumber();
	lower_right_x = Dialog.getNumber();
	lower_right_y = Dialog.getNumber();
	
	dir = getDirectory("macros");
	// First do exception case i.e. no crop area + no crop restore file. Create dummy file for next run and exit
	if (upper_left_x == 0 && upper_left_y == 0 && lower_right_x == 0 && lower_right_y == 0 && File.exists(dir + "cropcorners" + ".txt") == 0) {
		File.saveString(toString(0) + " " + toString(0) + " " + toString(0) + " " + toString(0), dir + "cropcorners" + ".txt");
		exit("Area selection is required");
	}
	else if (File.exists(dir + "cropcorners" + ".txt")) {
		coords = File.openAsString(dir + "cropcorners" + ".txt");
		// Restore last crop settings from file if crop co-ordinates are 0.
		if (upper_left_x == 0 && upper_left_y == 0 && lower_right_x == 0 && lower_right_y == 0) {
			all_coords = split(coords, " ");
			// If crop restore file is 0 then exit with error message
			if (parseInt(all_coords[0]) == 0 && parseInt(all_coords[1]) == 0 && parseInt(all_coords[2]) == 0 && parseInt(all_coords[3]) == 0) {
				exit("Area selection is required");
			}
			else {
				upper_left_x = parseInt(all_coords[0]);
				upper_left_y = parseInt(all_coords[1]);
				lower_right_x = parseInt(all_coords[2]);
				lower_right_y = parseInt(all_coords[3]);
			}
		}	
	}
	// Write to file if crop co-ordinates are not 0
	if (upper_left_x != 0 && upper_left_y != 0 && lower_right_x != 0 && lower_right_y != 0) {
		File.saveString(toString(upper_left_x) + " " + toString(upper_left_y) + " " + toString(lower_right_x) + " " + toString(lower_right_y), dir + "cropcorners" + ".txt");
	}
		if (df_corr == 1) {
			// Check for dark field image in source directory
			for (i = 0; i < fileList.length; i++) {
				id = fileList[i];
				// Check if dark field is in the source directory. If exists save.
				if (startsWith(id, "DARK") || startsWith(id, "dark")) {
					dark_field = id;
				}
			}
			if (dark_field == "") {
				// Dark field image not found, Ask user to select dark field image.
    			File.openDialog("Select Dark-field image");
    			dark_field = File.name;
			}
			open(dark_field);
			imageCalculator("Subtract create 32-bit stack", "Stack", dark_field);
			runCrop(upper_left_x, upper_left_y, lower_right_x, lower_right_y);
			run("Stack to Images");
			close(dark_field);
			saveTiff(num_images, df_corr);
			close("Stack");
		}
		else if (df_corr == 0) {
			// No correction
			runCrop(upper_left_x, upper_left_y, lower_right_x, lower_right_y);
			run("Stack to Images");
			saveTiff(num_images, df_corr);
		}
		else if (df_corr == 2) {
			// Check for flat and dark field images in source directory
			for (i = 0; i < fileList.length; i++) {
				id = fileList[i];
				// Check if dark field is in the source directory. If exists save.
				if (startsWith(id, "DARK") || startsWith(id, "dark")) {
					dark_field = id;
				}
				// Check if flat field is in the source directory. If exists save. 
				else if (startsWith(id, "FLAT") || startsWith(id, "flat")) {
					flat_field = id;
				}
			}
			if (flat_field != "" && dark_field != "") {
				// flat field image not found, Ask user to select dark field image.
    			flat_field = File.openDialog("Select Flat-field image");
    			dark_field = File.openDialog("Select Dark-field image");
			}
			// Perform dark-flat correction (I-D/F-D)
			den = imageCalculator("Subtract create 32-bit", dark_field, flat_field);
			num = imageCalculator("Subtract create 32-bit", dark_field, image_n[tiffc]);
			imageCalculator("Divide create 32-bit", num, den);
			runCrop(upper_left_x, upper_left_y, lower_right_x, lower_right_y);
			saveAs("Tiff", image_dir + "CRP" + image_n[tiffc]);
			close();
		}
}
function runCrop (ulx, uly, lrx, lry) {
	makeRectangle(ulx, uly, lrx - ulx + 1, lry - uly + 1); 
	run("Crop");
}

function saveTiff (num_tiff, flag) {
	for (tiffc = 1; tiffc <= num_tiff; tiffc++) {
		if (flag == 0) {
			saveAs("Tiff", image_dir + "CRP" + image_names[num_tiff-tiffc]);
			close();
		}
		else if(flag == 1) {
			saveAs("Tiff", image_dir + "CRPDFCOR" + image_names[num_tiff-tiffc]);
			close();
		}
		else if (flag == 2) {
			saveAs("Tiff", image_dir + "CRPFFCOR" + File.name);
			close();
		}
		else {
			saveAs("Tiff", image_dir + "CRP" + File.name);
			close();
		}	
	} 
}



