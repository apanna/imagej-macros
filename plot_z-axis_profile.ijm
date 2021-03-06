/*
 * Enhanced version of Plot Z-Axis profile. 
 * Allows plotting for mean, stdDev, normalized stdDev, min, and max of all images in the stack
 * 
 * __author_      = Alireza Panna
 * __version__    = 1.0
 * __status__     = stable
 * __date__       = 08/10/2016
 * __to-do__      = 
 * __update-log__ = 11/24/16: Add ROI translate feature
 * 					11/29/16: (HW) Change ROI translate so that it is no longer relative	
 * 						           to previous image in stack. This fixes a rounding error bug. 
 */
 
requires("1.49t");
macro "plot_z-axis_profile" {
      if (nSlices==1) {
      	exit("This macro requires a stack");
      }
      y_choice = newArray("Mean", "StdDev", "Norm StdDev", "Min", "Max");
      Dialog.create("Menu");
	  Dialog.addChoice("Plot Y metric:", y_choice, "Mean");
	  Dialog.addNumber("ROI translate X", 0, 0, 5, "pixels");
      Dialog.addNumber("ROI translate Y", 0, 0, 5, "pixels");
	  Dialog.show();
   	  y_metric = Dialog.getChoice();
   	  roi_x = Dialog.getNumber();
 	  roi_y = Dialog.getNumber();
      n = getSliceNumber();
      means = newArray(nSlices);
      stdDevs = newArray(nSlices);
      norm_stdDevs = newArray(nSlices);
      mins = newArray(nSlices);
      maxs = newArray(nSlices);
      Roi.getBounds(upper_left_x, upper_left_y, width_roi, height_roi);
      for (i=1; i<=nSlices; i++) {
          setSlice(i);
          // translate roi
		  Roi.move(upper_left_x + roi_x * (i-1), upper_left_y + roi_y * (i-1));
          getStatistics(area, mean, min, max, std);
          means[i-1] = mean;
          stdDevs[i-1] = std;
          norm_stdDevs[i-1] = std/mean;
          mins[i-1] = min;
          maxs[i-1] = max;
      }
      setSlice(n);
      if (y_metric == "Mean") {
      	Plot.create("Z-Axis Mean", "Slice No. ", "Mean (A.U.)", means);
      	Plot.add("circles", means);
      	makeFancy();
      }
      else if (y_metric == "StdDev") {
      	Plot.create("Z-Axis StdDev", "Slice No.", "StdDev (A.U.)", stdDevs);
      	Plot.add("circles", stdDevs);
      	makeFancy();
      }
      else if (y_metric == "Norm StdDev") {
      	Plot.create("Z-Axis Norm StdDev", "Slice No.", "Norm StdDev (A.U.)", norm_stdDevs);
      	Plot.add("circles", norm_stdDevs);
      	makeFancy();
      }
      else if (y_metric == "Min") {
      	Plot.create("Z-Axis Min", "Slice No.", "Min (A.U.)", mins);
      	Plot.add("circles", mins);
      	makeFancy();
      }
      else if (y_metric == "Max") {
      	Plot.create("Z-Axis Max", "Slice No.", "Min (A.U.)", maxs);
      	Plot.add("circles", maxs);
      	makeFancy();
      }
}

function makeFancy() {
    	Plot.setLineWidth(1);
    	Plot.setColor("lightGray");
}
