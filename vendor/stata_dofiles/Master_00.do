/*==================================================
Project:       The effects of expanding worker rights to children
Authors:       Leah K. Lakdawala
               Diana Martínez Heredia        
               Diego Vera-Cossio
----------------------------------------------------
Creation Date:    Apr 2025
Written on Stata 17 MP / MacOS 15.0 (24A335)
References:          
==================================================*/

/* This is a master Do file */

/*
	Sample do file to harmonize demographic data for all the survey waves.
	Set Up: We first define globals which we treat as parameters of the script.
	Make sure to change all the paths where relevant in the program set section.
    Make sure you keep the folder structure of the replication package when running 
	to avoid errors.

*/

/*==================================================
            0: Setting the directories
==================================================*/

// Additional packages
*ssc install nsplit
*ssc install winsor
*ssc install ihstrans
*findit grc1leg // By Vince Wiggins

// Set up
set more off
clear all
version 17
set processors 1
set seed 794758
set sortseed 794758
set sortrngstate 794758

// Define directories

global maindir "D:/BID/Replication Package"

// Paths

*---------- Localizing rawdata (this global will work in each of the do files run by this script.)
global raw_data "$maindir/1.RawData/Household Survey"
global raw_dataCS "$maindir/1.RawData/Child Labor Survey"

*---------- Localizing do files
global dodir "$maindir/2.DoFiles"
global dodir_cleanHS "$dodir/data_cleaning/Household Survey"
global dodir_cleanHS_harm "$dodir/data_cleaning/Household Survey/1. Harmonizing"
global dodir_cleanCS "$dodir/data_cleaning/Child Labor Survey"
global dodir_mainFig "$dodir/main_figures"
global dodir_mainTable "$dodir/main_tables"
global dodir_appxFig "$dodir/appendix_figures"
global dodir_appxTable "$dodir/appendix_tables"

*---------- Storing dta files after harmonizing:
global relabeled_data "$maindir/3.CleanData/1. Household Survey"
global relabeled_dataCS "$maindir/3.CleanData/2. Child Labor Survey"

*---------- Other dta files:
global other_raw "$maindir/1.RawData/auxiliar"
global other_relabeled "$maindir/3.CleanData/auxiliar"

*---------- Output for Figures and Tables:
global tabledir "$maindir/4.Output/Tables"
global figuredir "$maindir/4.Output/Figures"

/*==================================================
        2. Run do-files for Household Surveys
==================================================*/

**** Execute: Note that all the do-files should be independent.

*----------  2.1 EH2012_Persona - EH2019_Persona clean database

forvalues y=2012(1)2019 {
	do "${dodir_cleanHS_harm}/Persona/EH_Persona_`y'.do" 
}

*----------  2.2 EH2012_Income - EH2017_Income clean database

forvalues y=2012(1)2017 {
	do "${dodir_cleanHS_harm}/Income/EH_Income_`y'.do" 
}

*----------  2.3 EH2012_Expenses - EH2019_Expenses clean database

forvalues y=2012(1)2019 {
	do "${dodir_cleanHS_harm}/Expenses/EH_Expenses_`y'.do" 
}

*----------  2.4 Compiling HS Persona database

do "${dodir_cleanHS}/2. Compiling/2.1.EH_Persona_compiling.do"

*----------  2.5 Cleaning final HS Persona database

do "${dodir_cleanHS}/2. Compiling/2.2.EH_Persona_cleaned.do"

*----------  2.6 Compiling HS Income database

do "${dodir_cleanHS}/2. Compiling/2.3.EH_Income_compiling.do"

*----------  2.7 Cleaning final HS Income database

do "${dodir_cleanHS}/2. Compiling/2.4.EH_Income_cleaned.do"

*----------  2.8 Compiling HS Expenses database

do "${dodir_cleanHS}/2. Compiling/2.5.EH_Expenses_compiling.do"

*----------  2.9 Cleaning final HS Expenses database

do "${dodir_cleanHS}/2. Compiling/2.6.EH_Expenses_cleaned.do"

*----------  2.10 Merging all HS cleaned databases and making a final clean

do "${dodir_cleanHS}/3. Preparing for analysis.do"

/*==================================================
        3. Run do-files for Child Labor Survey
==================================================*/

**** Execute: Note that all the do-files should be independent.

*----------  3.1 CS 2008 children clean database

do "${dodir_cleanCS}/1-cleaning_database_2008_child.do"

*----------  3.2 CS 2008 household clean database

do "${dodir_cleanCS}/2-cleaning_database_2008_household.do"

*----------  3.3 CS 2008 calculating variables in child and household database

do "${dodir_cleanCS}/3-calculating_variables_2008.do"

*----------  3.4 CS 2008 harmonizing variables in child database

do "${dodir_cleanCS}/4-harmonizedvar_child_2008.do"

*----------  3.5 CS 2016 children clean database

do "${dodir_cleanCS}/5-cleaning_database_2016_child.do"

*----------  3.6 CS 2016 household clean database

do "${dodir_cleanCS}/6-cleaning_database_2016_household.do"

*----------  3.7 CS 2016 calculating variables in child and household database

do "${dodir_cleanCS}/7-calculating_variables_2016.do"

*----------  3.8 CS 2016 harmonizing variables in child database

do "${dodir_cleanCS}/8-harmonizedvar_child_2016.do"

*----------  3.9 Cleaning and merging 2008 and 2016 CS database

do "${dodir_cleanCS}/9-Cleaning child survey data.do"


/*==================================================
        3. Generate Figures
==================================================*/

/* figures are created in the same order as they appear on the paper */

*----------  3.1 Figure 2:  Changes in work probability relative to pre-law periods at the 14-year-old cutoff

do "${dodir_mainFig}/Fig2_DDiscEvtStudy.do" 

*----------  3.2 Figure 3: Work probabilities at the 14-year-old cutoff (Before, During, and After the Law)

do "${dodir_mainFig}/Fig3_RDgraphs_14.do" 

*----------  3.3 Figure 4: Compliance with labor regulations and travel time to inspectors (Pre-Law).

do "${dodir_mainFig}/Fig4_Distance_ContractsInsurance.do" 


/*==================================================
        4. Generate Tables
==================================================*/

/* tables are created in the same order as they appear on the paper */

*----------  4.1 Table 1:  Descriptive statistics (Pre-Law).

do "${dodir_mainTable}/Table_1_Desc_Statistics.do" 

*----------  4.2 Table 2:  Descriptive statistics by employer type.

do "${dodir_mainTable}/Table_2_Desc_Statistics_by_employer_type.do" 

*----------  4.3 Table 3: Difference in discontinuity effects of the law on the work probabilities, hours, and occupation for the 14-Year-Old Cutoff.

do "${dodir_mainTable}/Table_3_DDisc_Work.do" 

*----------  4.4 Table 4: Heterogeneous effects of the law by distance from MTEPS offices (Difference-in-Discontinuity

do "${dodir_mainTable}/Table_4_DDisc_HeterogeneityDistanceToInspectors.do" 

*----------  4.5 Table 5: Effects of the law on risk, injuries at work and wages.

do "${dodir_mainTable}/Table_5_DDisc_RiskInjuryWages.do" 

*----------  4.6 Table 6: Effects of the Law on Job Location and Firm Size.

do "${dodir_mainTable}/Table_6_DDisc_JobLocationFirmSize.do" 


//================ Appendix ========================//


/*==================================================
        5. Generate exhibits
==================================================*/

/* figures and tables are created in the same order as they appear on the paper */

*----------  5.1 Figure A2: Articles on the 2014 Law over Time

do "${dodir_appxFig}/Figure_A2_Articles.do" 

*----------  5.2 Figure A3:  Work Probabilities by Age (Pre-law)

do "${dodir_appxFig}/Figure_A3_WorkbyAgeinMonths.do" 

*----------  5.3 Figure A4: Manipulation Test: Histograms

do "${dodir_appxFig}/Figure_A4_Histograms.do" 

*----------  5.4 Table A2: Balance Table: Difference in Discontinuity- Household Survey

do "${dodir_appxTable}/Table_A2_Balance.do" 

*----------  5.5 Figure A5, A6, A7: Differences in densities: 14 year-old cutoff, 12 year-old cutoff, 10 year-old cutoff

do "${dodir_appxFig}/Figure_A5A6A7_DifferenceInDiscontinuities.do" 

*----------  5.6 Figure A8: Dfference in Discontinuity Event Study-style Estimates: Work Probability (12 and 10-Year-Old Cuto s)

do "${dodir_appxFig}/Figure_A8_DDiscEvtStudy_10-12.do" 

*----------  5.7 Figure A9, A10: Work Probabilities at the 12-Year-Old Cutoff (10-Year-Old Cutoff) (Before, During, and After the Law)

do "${dodir_appxFig}/Figure_A9A10_RDgraphs_1012.do" 

*----------  5.8 Table A3: Heterogeneous Effects of the Law by Gender (Difference-in-Discontinuity)

do "${dodir_appxTable}/Table_A3_DDisc_HeterogeneityByGender.do" 

*----------  5.9 Figure A11: Work Probabilities across Age Groups (Before, During, and After the Law)

do "${dodir_appxFig}/Figure_A11_Work over Time by Age Group.do" 

*----------  5.10 Table A4: Examining Potential Substitution to Older Children

do "${dodir_appxTable}/Table_A4_Substitution.do" 

*----------  5.11 Table A5: Effects of the Law on the Work Probabilities, Hours, and Occupation

do "${dodir_appxTable}/Table_A5_DDisc_Work_1012.do" 

*----------  5.12 Table A6: Effect of the Law on Time Allocation and Schooling

do "${dodir_appxTable}/Table_A6_TimeAllocationSchooling.do" 

*----------  5.13 Table A7: Effects on Household Labor Supply at the 14-year-old Cut-off

do "${dodir_appxTable}/Table_A7_HHLaborSupply.do" 

*----------  5.14 Table A8: Effects on Household Expenditure at the 14-Year-Old Cutoff

do "${dodir_appxTable}/Table_A8_HHExpenditure.do" 

*----------  5.15 Table A9: Heterogeneous Effects of the Law by Driving Time from MTEPS Offces (Difference-in-Discontinuity)

do "${dodir_appxTable}/Table_A9_DDisc_HeterogeneityByDrivingTime.do" 

*----------  5.16 Table A10: Heterogeneous Effects by Distance from MTEPS Offces, Allowing for Heterogeneity by Urban and Baseline Child Labor Rates

do "${dodir_appxTable}/Table_A10_DDisc_HeterogeneityByDistance_Robustness.do" 

*----------  5.17 Table A11: Functional Form Robustness Checks: Difference-in-Discontinuity for Work Probability (14-Year-Old Cutoff)

do "${dodir_appxTable}/Table_A11_Work_FunctionalFormRobustness.do" 

*----------  5.18 Table A12: Examining Potential Social Desirability Bias

do "${dodir_appxTable}/Table_A12_SocialDesirability.do" 

*----------  5.19 Table A13: Difference in Difference Specification

do "${dodir_appxTable}/Table_A13_DiffinDiff.do" 

*----------  5.20 Table A14: Reconciling Results with Kamei (2021)

do "${dodir_appxTable}/Table_A14_Kamei.do" 

*----------  5.21 Table A15: Other Robustness Checks: Difference in Discontinuity for Work Probability (14-Year-Old Cutoff)

do "${dodir_appxTable}/Table_A15_Work_OtherRobustness.do" 

*----------  5.22 Table A16, A17: Balance for 30% of Child Labor Survey Data - Balance for Reweighted Child Labor Survey Data - Full sample

do "${dodir_appxTable}/Table_A16A17_Balance_StackedRiskInjury.do" 

*----------  5.23 Figure A12: Job Risks & Work Injuries (Before and During the Law): Stacked Data

do "${dodir_appxFig}/Figure_A12_RDgraphsStackedRiskInjury.do" 

*----------  5.24 Table A18: Effects of the Law on Job Risks, and Work Injuries

do "${dodir_appxTable}/Table_A18_RiskInjury_Robustness.do" 

*----------  5.25 Table A19: Robustness Checks: Difference in Discontinuity for Risk Outcomes

do "${dodir_appxTable}/Table_A19_RiskInjuryByAgeGroup.do" 

*----------  5.26 Figure A13: Work Permits by Household Income and Age Group 

do "${dodir_appxFig}/Figure_A13_Permits by Age & Inc.do" 

*----------  5.27 Table A20: Difference in Discontinuity Effects of the Law on the Work Probabilities by Work Type for the 14-Year-Old Cutoff

do "${dodir_appxTable}/Table_A20_DDisc_InformalWork.do" 


