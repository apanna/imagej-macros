/* 
 * Unstacks tiff images.
 *  
 *  __author__			=	'Alireza Panna'
 *  __status__          =   "stable"
 *  __date__            =   "8/28/15"
 *  __version__         =   "1.0"
 *  __to-do__			=   
 *  __update-log__		= 	
 */
macro "Unstack_and_Save" {
	process_stack();
}

function process_stack() { 
	image_stack = File.openDialog("Select Stack");
	path = File.directory;
    if (endsWith(image_stack, ".tif") || endsWith(image_stack, ".tiff")) { 
        setBatchMode(true);
        open(image_stack);
        w = getWidth();
		h = getHeight();
        title = getTitle();  
        for(i = 1; i <= nSlices; i++) { 
          new_file = getInfo("slice.label"); 
          new_title = new_file; 
          run("Select All"); 
          setSlice(i); 
          image_name = getInfo("slice.label");
          run("Copy"); 
          newImage("Untitled", bitDepth() + "Black", w, h, 1); 
          run("Paste"); 
          saveAs("Tiff", path + image_name); 
          close(); 
        }
    }
}