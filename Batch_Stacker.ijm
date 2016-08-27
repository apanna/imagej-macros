/* 
 * Makes tiff stacks in batch mode.
 *  
 *  __author__			=	'Alireza Panna'
 *  __status__          =   "stable"
 *  __date__            =   "8/06/15"
 *  __version__         =   "1.0"
 *  __to-do__			=   
 *  __update-log__		= 	8/07/15: Added progress bar  
 *  						8/14/15: Reworked to process faster
 */
macro "Batch_Stacker" {
	open_as_image_sequence();
}

function open_as_image_sequence() {
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
	// Open images in  a virtual stack using regex i.e. if file name contains _[counter]
	run("Image Sequence...", "open=[&image_0]"+"file=(^" + image_0_noext + "_[0-9]) sort use");
	// Remove scaling
	run("Set Scale...", "distance=0 global");
	saveAs("Tiff", image_dir + "STK" + image_0_noext);
	// Cleanup
    run("Close All");
}