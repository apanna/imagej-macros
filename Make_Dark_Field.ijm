/* 
 *  A handy dark-field maker.
 *
 *  __author__			=	'Alireza Panna'
 *  __status__          =   "stable"
 *  __date__            =   "3/13/15"
 *  __version__         =   "1.0"
 *  __to-do__			=	1. Find a better way to get image meta-data
 *  __update-log__		=   3/13/15: First version.
 *  						3/18/15: Added completed notification.
 */
macro "Make_Dark_Field" {
	// Get File Directory and file names
	dirSrc = getDirectory("Select Dark-fields Directory");
	fileList = getFileList(dirSrc);
	// Enter meta-data required to build final dark field image name.
	Dialog.create("Enter dark-field meta-data");
	Dialog.addString("Camera:", "D700");
	Dialog.addString("Exposure time (sec) :", "10");
	Dialog.addString("Bin:" "2");
	Dialog.addString("Gain:", "ISO800");
	Dialog.show();

	cam = Dialog.getString();
	time = Dialog.getString() + "s";
	bin = "Bin" + Dialog.getString();
	gain = Dialog.getString();
	
	// Count number of dark field tiff files in source directory
	numTiff = 0;
	filenum = 0;
	while(filenum < fileList.length) {
    	id = fileList[filenum++];
    	if(endsWith(dirSrc + id, ".tiff") || endsWith(dirSrc + id, ".tif")) {
        	numTiff++;
    	}
	}
	setBatchMode(true);
	fileList = getFileList(dirSrc);
	// Open all the files in the src directory. 
	for (tiffc = 0; tiffc < numTiff; tiffc++) {
		if (startsWith(fileList[tiffc],  "dark")) {
			open(fileList[tiffc]);
		}
		else {
			open(fileList[tiffc]);
		}
	}
	dirDest = getDirectory("Select Average Dark-field Output Directory");
	File.makeDirectory(dirDest);
	run("Images to Stack", "name=Stack title=[] use");
	run("Z Project...", "projection=[Sum Slices]");
	run("Divide...", "value=" + numTiff);
	saveAs("Tiff", dirDest + "dark" + time + bin + cam + gain + "_avrg" + toString(numTiff));
	// Cleanup
    run("Close All");
    print("--Completed");
}	    
