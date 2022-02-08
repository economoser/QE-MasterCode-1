Log of Changes 
First version April,  19, 2019
This  version January 26, 2022
Serdar Ozkan (serdar.ozkan@toronto.ca)
Sergio Salgado (ssalgado@wharton.upenn.edu)
----------------

January 26, 2022

Updated codes and added file 7. Here is a list of major changes 
	- Added two new global variables to 0_initialize.do. These define, the name of the country and the type of education variable Ava
	- Added 6_Insheeting_datasets.do that takes the CSV results and creates a CVS file that will be uploaded in the website. Notice this file must satisfy the disclosure requirements for each team. 
	- Erased 6_Core_Figs.do file. Renamed 6_Paper_Figs.do as the main file for plots, now called 7_Paper_Figs.do
	- Fixed bug in 3_Inequality.do that saved incorrectly the gender as 1/3 indexes
	- Erased the concretion measures calculated as in Gomez (2018) from 3_Inequality.do
	- Added a new section in the inequality code that calculates the autocorrelation of the residual earnings


January 10, 2022

Updated figure codes 6_Core_Figs.do 7_Paper_Figs.do adding 
global Tcommon = ${yrlast} - 20 + 1	 
To define the minimum year used for the heterogeneity plots. 

December 18, 2020 

The code 7_Paper_Figs.do has been updated to fix a problem in the calculation of the Kelley Skewness. We have also removed the mobility section from 6_Core_Figs.do. This code is obsolete--all core plots are done in 7_Paper_Figs.do. We will remove 6_Core_Figs.do from the GitHub page in a future update of the code. 

December 7, 2020 

Updates the 1_Gen_Base_Sample.do, 3_Inequality.do, and 5_Mobility.do codes. In 1_Gen_Base_Sample.do we change the definition of alternative permanent income, created a new version of residual earnings controlling for education dummies and age, and fixed a bug for the calculation of arc-percent changes. In 3_Inequality.do we added time series statistics for the new residual earnings measure (with education and age). The code 5_Mobility.do has been streamlined and we changed the selection of the sample used to calculate the mobility plots. 

We also added an entire new file, 7_Paper_Figs.do, that produces the main core figures for the draft. See Figures_Paper.pdf for additional details and an example of each figure using the Norwegian data. 

November 6, 2020

Fixes the volatility code. The in previous version, the moments conditional on permanent earnings were calculated after dropping all observations that did not have researnXF and arcearnXF with X \in {1 5}. 

August 6, 2020

Fixes a bug in the construction of permalt income in 1_Gen_Sample.do (not it is constructed between years $yrfirst+2 and $yrlast and age > begin_age + 2
Fixed also a small big in the transition matrices in 5_Mobility.do

July 21, 2020

Relative to March 03, 2020, this version updated all do-files, from sample creation to the generation of the plots.

March 03, 2020

Updated 1_Gen_Sample.do, 6_Core_Figs.do, and (very minor) changes in myplots.do and 3_Inequality.do. Below the important changes

- On 1_Gen line 158 that was incorrectly dropping observations with little earnings dropping all observations with 0 earnings. Dropped that line. We also added a condition on arc-percent that only kicks in if labor earnings in t and in t+k are below the min income. 

- On 6_Core, adjusted some of the figures to put the figures of 5-year changes centered in the moving window. That is, if the moment is calculated as t+5, the plot is centered in t+2. Also, added a new version of figure 5a to have two axis. 



January, 18, 2019

Updated the codes to the version 2.0; This new version of the code contains several major changes relative to the original version of April 2019. Among others 

- Adds a new set of results for the arc-percent change in income
- Modifies the change income growth measure to allow for declines below the min value in t+k. 
- Adds new features to the plots such as recession bars and differential color schemes.
- Adds several new plots: density plots, cohort plots, etc. 


August, 14, 2019

We have modified 1_Gen_Sample.do so now it records the gender for which the profiles are calculated. These changes are made between lines 210 and 236


July, 05, 2019 

We have modified some of the calculations in the gen_base and mobility codes. In the first, we have added 

	bys male: egen avgall = mean(totearn)
	gen permearnalt`yr' = avgall*totearn/avg	// This is because we want to control for age effects
	
In lines 388 to have permearnalt in the correct scale. This does not change the results. 
The mobility code has more changes. In particular, we have modified the transition matrix calculation to account for 0. Individuals with 0 permanent earnings are now grouped in one category only, whereas the rest of individuals (with positive permearnalt earnings, are separated in 10 groups, to a total of 11 rows in the transition matrix). See lines 240 to 266. We have also saved some summary stats within each cell (see line 248 for instance).  



April, 19, 2019

The folder contains the first version of the code for the Global Income Dynamics Database project. The code was developed in Stata 13 by Serdar Ozkan and Sergio Salgado. 
The original set of do files is the following 

0_Initialize
1_Gen_Base_Sample.do
2_DescriptiveStats
3_Inequality
4_Volatility
5_Mobility
6_Core_Figs
GenData
myplots
myprogs

See the file Code_Guidelines_April2019.pdf for additional details. 
