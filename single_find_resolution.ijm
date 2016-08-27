/* 
 *  Finds resolution from edge or pinhole profiles. Offers a choice for either Gaussian (normal)
 *  , Lorentzian (cauchy), or Pseudo Voigt fit. Return the FWHM of the selected profile. Extended from macro 
 *  single_edge_horizontal.ijm and single_fit_edge. Asks for profile direction. 
 *  Works when image is open and roi is selected.
 *  
 *  __author__			=	Alireza Panna
 *  __status__          =   stable
 *  __date__            =   2/27/15
 *  __version__         =   2.0
 *  __to-do__			=	cauchy and pseudo voigt fits are computationally expensive in this iteration. Need to find a way			   
 *  						to make these fits faster.
 *  __update-log__		= 	3/08/15: Now returns contrast information (edge response height) as area under gaussian LSF curve
 *  						3/10/15: added mtf capability, edge step height evaluation in terms of Lorentzian LSF fit area.
 *  						3/13/15: prints contrast count as well.
 *  						3/18/15: Decided not to normalize mtf for now. (Dr. Wens suggestion)
 *  						3/19/15: Added function makeFancy to make the mtf plots look nicer
 *  						3/25/15: Fixed normalization issue of mtf. Raw mtf should give proper contrast values now.
 *  						3/30/15: Added method for % roi selected in image to be printed in log
 *  						3/31/15: MTF is normalized now. 
 *  						5/05/15: Moved MTF algorithm to py script. Removed from here. 
 *  						5/29/15: Renamed return variables for better code reading. Macro also returns peak position now. 
 *  						8/10/16: Added pseudo voigt fit function as an option for fitting. This macro also fits generic profiles.
 *  						         and is not limited to derivative of edge profile fitting i.e. LSF fitting anymore Update version
 *  						         to 2.0 single_fit_edge is now deprecated.
 *  					    8/11/16: Changed Lorentzian and Pseudo-Voigt fit function equation to accomodate for y offset. Lorentzian 
 *  					    		 guess parameters are not estimated from the gaussian fit anymore, so that the gaussian fit is not 	
 *  					    		 performed everytime the user selects Lorentzian fitting. 
 */
 
requires("1.49i");
/* Lorentzian fit function: a = Offset b = Peak c = Mean d = FWHM */ 
var Lorentzian = "y=a+(b-a)*(d*d/4)*(1/((x-c)*(x-c)+(d/2)*(d/2)))";

macro "single_find_resolution" {
	imgname = getTitle(); 
	// remove .tif
	imgname_split = split(imgname,".");
    dir = getDirectory("image");
    // get input argument if any
	args = getArgument();
	if (args == "") {
		// Display dialog if fit and edge choice are not already pre-defined.
		type_choice = newArray("Profile", "Edge");
		fit_choice = newArray("Gaussian", "Lorentzian", "Pseudo-Voigt");
    	profile_choice = newArray("Horizontal", "Vertical");
  		Dialog.create("Menu");
  		Dialog.addChoice("Fit type:", type_choice, "Profile");
		Dialog.addChoice("Profile Direction:", profile_choice, "Horizontal");
  		Dialog.addChoice("Fit Function:", fit_choice, "Gaussian"); 
  		Dialog.show();
  		fit_type = Dialog.getChoice();
  		prof_dir = Dialog.getChoice();
    	fit_func = Dialog.getChoice();
	}
	else {
		// use the setting from stack_fit_profile.ijm
		arr = split(args, " ");
		fit_type = arr[0];
		prof_dir = arr[1];
    	fit_func = arr[2];
	}
	selectImage(imgname);
	if (!(selectionType() == 0 || selectionType() == 5 || selectionType() == 7)) {
		exit("Selection must be a line or a rectangle");
	}
	// Remove scaling
	run("Set Scale...", "distance=0 global");
	// Find percent roi selected
	getSelectionBounds(upper_left_x, upper_left_y, width_roi, height_roi);
	width_image = getWidth();
	height_image = getHeight();
	area_image = width_image * height_image;
	area_roi = width_roi * height_roi;
	per_area = (area_roi/area_image) * 100;
    // Plot profile, get values and close profile
	if (prof_dir == "Vertical") {
		setKeyDown("alt");
	}
	else {
    	setKeyDown("ctrl"); 
	}
	run("Plot Profile");
	Plot.getValues(x, y);
	close();
	npts = x.length;
	if (fit_type == "Profile") {
		// baseline correction via linear regression
    	x0=(x[0]+x[1]+x[2]+x[3]+x[4])/5;
    	y0=(y[0]+y[1]+y[2]+y[3]+y[4])/5;
    	x1=(x[npts-1]+x[npts-2]+x[npts-3]+x[npts-4]+x[npts-5])/5;
    	y1=(y[npts-1]+y[npts-2]+y[npts-3]+y[npts-4]+y[npts-5])/5;
    	// fitting routine (Always do gaussian fit and use gauss fit parameters to guess lorentzian fit parameters)
    	slope = (y1-y0)/(x1-x0);
    	offset = (y0*x1-y1*x0)/(x1-x0);
    	y_corr = newArray(y.length);
    	ny = newArray(y.length);
   	 	ny_corr = newArray(y.length);
    	for(i = 0; i < npts; i++) {
    		y_corr[i]=y[i]-offset-slope*x[i];
   		 }
    	for(i = 0; i < npts; i++) {
    		ny_corr[i] = -y_corr[i];
    		ny[i] = -y[i];
    	}
	}
	else if (fit_type == "Edge") {
		// Get derivative (raw LSF) (y[i+1]-y[i-1])/2;    
    	deriv = newArray(npts);
    	derivneg = newArray(npts);
    	// force tails of LSF to go to 0 for finite roi
    	deriv[0] = 0;
    	deriv[npts-1] = 0;
    	y_corr = newArray(y.length);
    	ny = newArray(y.length);
   	 	ny_corr = newArray(y.length);
    	for(i = 1; i < npts - 1; i++) {
    		deriv[i] = (parseFloat(y[i+1]) - parseFloat(y[i-1]))/2;
    	}
		// baseline correction via linear regression
    	x0 = (x[1] + x[2] + x[3] + x[4])/4;
    	deriv0 = (deriv[1] + deriv[2] + deriv[3] + deriv[4])/4;
    	x1 = (x[npts - 2] + x[npts - 3] + x[npts - 4] + x[npts - 5])/4;
    	deriv1 = (deriv[npts - 2] + deriv[npts - 3] + deriv[npts - 4] + deriv[npts - 5])/4;
    	slope = (deriv1 - deriv0)/(x1 - x0);
    	offset = (deriv0 * x1 - deriv1 * x0)/(x1 - x0);
    	// Following is baseline corrected LSF
    	for(i = 1; i < npts - 1; i++) {
    		y_corr[i] = deriv[i] - offset - slope * x[i];
    	}
    	for(i = 1; i < npts - 1; i++) {
    		ny_corr[i] = -y_corr[i];
    	}
    	// write lsf results to file
		file_lsf = File.open(dir + "LSF" + imgname_split[0] + ".txt");
		print(file_lsf, "samples (n)" + "\t" + "Raw LSF (d(DN)/dn)"); 
		writeFile(file_lsf, x, y_corr);
	}
	// get guess params
	Array.getStatistics(y_corr, min, max, mean, stdDev);
	max_y = max;
	min_y = min;
	mean_y = mean;
	Array.getStatistics(x, min, max, mean, stdDev);
	min_x = min;
	max_x = max;
	for (i = 0; i < npts; i++) {
		if (y_corr[i] == max_y) {
			xOfmax = x[i];
		}
	}
	width_y = 0.39894*((max_x - min_x)*(mean_y-min_y))/(max_y - min_y + 1e-100);
	// Gaussian fit routine
	if (fit_func == "Gaussian" || fit_func == "Pseudo-Voigt") {
    	Fit.doFit("Gaussian", x, y_corr);
    	rsqpos=Fit.rSquared();
    	Fit.doFit("Gaussian", x, ny_corr);
    	rsqneg=Fit.rSquared();
    	if(rsqpos > rsqneg) {
    		Fit.doFit("Gaussian", x, y_corr);
    	} 
    	else {
    		Fit.doFit("Gaussian", x, ny_corr);
    	}   
    	off_g = Fit.p(0);
    	mean_g = Fit.p(2);
    	peak_g = Fit.p(1) - Fit.p(0);
    	width_g = Fit.p(3);
    	// profile fwhm
    	FWHM_g = 2 * sqrt(2 * log(2)) * width_g;
    	area_g = sqrt(2 * PI) * peak_g * width_g;           
    	if (fit_func == "Gaussian") {
    		Fit.plot();
    		FWHM = FWHM_g;
    		AREA = abs(area_g);
    		MEAN = mean_g;
		}
	}
	// Lorentzian fit routine
	if (fit_func == "Lorentzian" || fit_func == "Pseudo-Voigt") {
		// Calculate initial guesses. Currently getting guess from gaussian fit parameters.
		// Since data is baseline subtracted 0 is a good guess for the offset.
     	initialGuesses = newArray(-5, max_y, xOfmax, 2*sqrt(2*log(2))*width_y);
		Fit.doFit(Lorentzian, x, y_corr, initialGuesses);
		rsqpos = Fit.rSquared();
		Fit.doFit(Lorentzian, x, ny_corr, initialGuesses);
		rsqneg = Fit.rSquared();
    	if(rsqpos > rsqneg) {
    		Fit.doFit(Lorentzian, x, y_corr, initialGuesses);
    	} 
    	else {
    		Fit.doFit(Lorentzian, x, ny_corr, initialGuesses);
    	}
    	off_l = Fit.p(0);
    	peak_l = Fit.p(1) - Fit.p(0);
    	mean_l = Fit.p(2);
    	FWHM_l = Fit.p(3);
    	area_l = (abs(peak_l) * abs(FWHM_l)) * ((PI/2));//-atan(-2*mean_l/abs(FWHM_l)));
    	if (fit_func == "Lorentzian") { 
    		Fit.plot();
    		FWHM = abs(FWHM_l);
    		AREA = abs(area_l);
    		MEAN = mean_l;
    	}
	}
	//Pseudo-Voigt fit routine
	if (fit_func == "Pseudo-Voigt") {
		// Calculate initial guesses. eta is the weight approximation for the combination
		eta =  1.36603*abs(FWHM_l/FWHM_g) - 0.47719*(FWHM_l/FWHM_g)*(FWHM_l/FWHM_g) + 
			   0.11116*abs(FWHM_l/FWHM_g)*abs(FWHM_l/FWHM_g)*abs(FWHM_l/FWHM_g);
		fwhm_v = pow(pow(2*sqrt(2*log(2))*FWHM_g, 5) + 
    			 2.69269*pow(2*sqrt(2*log(2))*FWHM_g, 4)*pow(FWHM_l, 1) + 
    			 2.42843*pow(2*sqrt(2*log(2))*FWHM_g, 3)*pow(FWHM_l, 2) + 
    			 4.47163*pow(2*sqrt(2*log(2))*FWHM_g, 2)*pow(FWHM_l, 3) + 
    			 0.07842*pow(2*sqrt(2*log(2))*FWHM_g, 1)*pow(FWHM_l, 4) + 
    			 pow(FWHM_l , 5), 0.2);
    	var pseudo_voigt = Lorentzian + "*" + d2s(eta, 9) + "+ (1-" + d2s(eta, 9) + ")*((b-a)*exp(-((x-c)*(x-c)*4*log(2))/(d*d)) + a)";
     	initialGuesses = newArray(0, max_y, xOfmax, fwhm_v);
		Fit.doFit(pseudo_voigt, x, y_corr, initialGuesses);
		rsqpos = Fit.rSquared();
		Fit.doFit(pseudo_voigt, x, ny_corr, initialGuesses);
		rsqneg = Fit.rSquared();
    	if(rsqpos > rsqneg) {
    		Fit.doFit(pseudo_voigt, x, y_corr, initialGuesses);
    	} 
    	else {
    		Fit.doFit(pseudo_voigt, x, ny_corr, initialGuesses);
    	}    
    	Fit.plot();
    	peak_v = Fit.p(1) - Fit.p(0);
    	mean_v = Fit.p(2);
    	FWHM_v = Fit.p(3); 
    	area_v = abs(eta*area_l + (1-eta)*area_g);
    	FWHM = abs(FWHM_v);
    	AREA = abs(area_v);
    	MEAN = mean_v; 
		
	}
	rename(fit_func + " Fit");
	print(fit_func + " " + prof_dir + " Profile FWHM" + ":", FWHM + " pixels");
	print("Contrast" + ":", AREA + " DN");
	print("ROI (W x H): " + toString(width_roi) + " x " + toString(height_roi) + " pixels"); 
	print(toString(per_area) + " % " +  "of total image selected!");
	print("---------------------------------------------------------");
	fwhm_str = toString(FWHM, 4);
	contrast_str = toString(AREA, 4);
	mean_str = toString(MEAN, 4);
	// Return fwhm, area under lsf (edge step height) and peak position in pixels
	return fwhm_str + " " + contrast_str + " " + mean_str;		
}
// Seperate write to file routine
function writeFile(f, x, y) {
    xx = "";
    yy = "";
    zz = "";
    z = 0;
    while(z < x.length) {
    	xx = toString(x[z]) + "\t";
    	yy = toString(y[z]) + "\n";
    	zz = xx + yy;
    	z++;
	    print(f, zz);
	}
	File.close(f);
}