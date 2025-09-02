/* importing data from Excel; I converted the .xlsx file to a .csv file */
/* setting column names to match Excel file */
data vehicles;
infile 'https://raw.githubusercontent.com/petecht66/MSRP-predictive-model/refs/heads/main/data/Vehicle%20Data.csv'
dlm=',' dsd firstobs=2 missover;
length Vehicle $50 driveWheels $20 vehicleType $20;
input Vehicle :$50. MSRP dealerCost engineSize numCylinders Horsepower 
cityMPG hwyMPG Weight Wheelbase Length Width 
driveWheels :$20. vehicleType :$20.;
run;

/* printing the data set for a visual check */
/*
proc print data=vehicles;
run;


/* transform the driveWheels variable to be a numeric, indicator variable */
/* transform the vehicleType variable to be numeric indicator variables */
data codedVehicles;
    set vehicles;
    if upcase(driveWheels) = 'AWD' then updatedDriveWheels = 1;
    else updatedDriveWheels = 0;
    if upcase(vehicleType) = "SEDAN" then isSedan = 1;
    else isSedan = 0;
    if upcase(vehicleType) = "SPORTS CAR" then isSportsCar = 1;
    else isSportsCar = 0;
    if upcase(vehicleType) = "SUV" then isSUV = 1;
    else isSUV = 0;
    if upcase(vehicleType) = "WAGON" then isWagon = 1;
    else isWagon = 0;
    if upcase(vehicleType) = "MINIVAN" then isMinivan = 1;
    else isMinivan = 0;
run;

/* Base specification model */
proc reg data=codedVehicles plots=none;
model MSRP = engineSize numCylinders Horsepower cityMPG
hwyMPG Weight Wheelbase Length
Width updatedDriveWheels isSedan isSportsCar 
isSUV isWagon isMinivan;
run;

/* Stepwise selection step */
proc reg data=codedVehicles;
model MSRP = engineSize numCylinders Horsepower cityMPG
hwyMPG Weight Wheelbase Length
Width updatedDriveWheels isSedan isSportsCar 
isSUV isWagon isMinivan / selection=stepwise slentry=0.1 slstay=0.1;
run;

/* Multicollinearity check */
proc reg data=codedVehicles;
model MSRP = Horsepower Wheelbase hwyMPG Weight
Width isSUV numCylinders engineSize isSportsCar
/ vif collinoint;
run;

/* Suspected interaction between predictors step */
proc glm data=codedVehicles;
model MSRP = Horsepower Wheelbase hwyMPG Weight
Width isSUV numCylinders engineSize isSportsCar
hwyMPG*Weight isSportsCar*Horsepower; 
run;

/* Final model analysis */
proc glm data=codedVehicles;
model MSRP = Horsepower Wheelbase hwyMPG Weight
Width isSUV numCylinders engineSize isSportsCar isSportsCar*Horsepower; 
output out=residuals predicted=predict residual=res;
run;

/* normality assumption check; normal probability plot of residuals */
proc univariate data=residuals;
    var res;
    probplot res / normal (mu=est sigma=est);
    title "Normal Probability Plot of Residuals";
run;

/* scatter plot of predicted versus residuals for constant variance test */
/* also the model specification test */
proc sgplot data=residuals;
    scatter x=predict y=res;
    refline 0 / axis=y;
    title "Plot of Predicted Values Versus Residuals";
run;

data residuals_time;
   set residuals;
   obs_number + 1;  /* creates a time-like variable starting at 1 */
run;

/* scatter plot of residuals versus the time that they come in */
/* independence of errors test */
proc sgplot data=residuals_time;
    scatter x=obs_number y=res;
    refline 0 / axis=y;
    title "Independence of Errors Test";
run;
