/*====================================================================*
 | Project: Framingham Stroke Analysis
 | File: 01_frmgham_stroke_analysis.sas
 | Purpose:
 |   1) Identify baseline risk factors for incident stroke within 10 years
 |      separately for men and women
 |   2) Describe how blood pressure and diabetes change across exam
 |      periods 1, 2, and 3
 |
 | Reproducibility notes:
 |   - Uses project-level folder macros instead of hard-coded personal paths
 |   - Assumes raw data are stored in DataRaw/
 |   - Saves outputs to Results/
 |   - Can be rerun from top to bottom by another analyst
 *====================================================================*/
 
/*==============================*
 | 1. folder folder and read raw file
 *==============================*/
%let project_root = /home/u58995405/BIOS 6624;

/* Derived folders */
%let raw_dir       = &project_root./DataRaw;
%let processed_dir = &project_root./DataProcessed;
%let code_dir      = &project_root./Code;
%let results_dir   = &project_root./Results;

/* Raw data file */
%let raw_file      = &raw_dir./frmgham2.xls;

options nodate nonumber formdlim='-' mprint mlogic symbolgen dlcreatedir;

/* Create directories if needed */
libname procdir "&processed_dir";
libname resdir  "&results_dir";
libname procdir clear;
libname resdir  clear;

proc import datafile="&raw_file"
    dbms=xls
    out=work.import_raw
    replace;
    getnames=yes;
run;

/* Create working copy */
data work.frmgham;
    set work.import_raw;
run;

/*==============================*
 | 2. FORMATS
 *==============================*/
proc format;
    value sexfmt
        1 = 'Men'
        2 = 'Women';

    value periodfmt
        1 = 'Period 1'
        2 = 'Period 2'
        3 = 'Period 3';

    value yesnofmt
        0 = 'No'
        1 = 'Yes';

    value $proffmt
        'High_BP_only'          = 'High BP only'
        'Diabetes_only'         = 'Diabetes only'
        'High_BP_plus_Diabetes' = 'High BP + Diabetes'
        'Current_smoker_only'   = 'Current smoker only';
run;
/*==============================*
 | 3. LABEL VARIABLES
 *==============================*/
data work.frmgham;
    set work.frmgham;

    label
        randid   = 'Unique participant ID'
        sex      = 'Sex'
        totchol  = 'Total cholesterol (mg/dL)'
        age      = 'Age at exam (years)'
        sysbp    = 'Systolic blood pressure (mmHg)'
        diabp    = 'Diastolic blood pressure (mmHg)'
        cursmoke = 'Current smoker'
        cigpday  = 'Cigarettes per day'
        bmi      = 'Body mass index (kg/m^2)'
        diabetes = 'Diabetes'
        bpmeds   = 'Antihypertensive medication use'
        heartrte = 'Heart rate (beats/min)'
        glucose  = 'Casual glucose (mg/dL)'
        prevchd  = 'Prevalent CHD'
        prevap   = 'Prevalent angina'
        prevmi   = 'Prevalent MI'
        prevstrk = 'Prevalent stroke'
        prevhyp  = 'Prevalent hypertension'
        time     = 'Days since baseline exam'
        period   = 'Examination cycle'
        hdlc     = 'HDL cholesterol (mg/dL)'
        ldlc     = 'LDL cholesterol (mg/dL)'
        death    = 'Death during follow-up'
        angina   = 'Incident angina'
        hospmi   = 'Incident hospitalized MI'
        mi_fchd  = 'Incident hospitalized MI or fatal CHD'
        anychd   = 'Incident any CHD'
        stroke   = 'Incident stroke'
        cvd      = 'Incident CVD'
        hyperten = 'Incident hypertension'
        timeap   = 'Days from baseline to angina/censor'
        timemi   = 'Days from baseline to hospitalized MI/censor'
        timemifc = 'Days from baseline to MI/fatal CHD/censor'
        timechd  = 'Days from baseline to any CHD/censor'
        timestrk = 'Days from baseline to stroke/censor'
        timecvd  = 'Days from baseline to CVD/censor'
        timedth  = 'Days from baseline to death/censor'
        timehyp  = 'Days from baseline to hypertension/censor';

    format
        sex sexfmt.
        period periodfmt.
        cursmoke diabetes bpmeds
        prevchd prevap prevmi prevstrk prevhyp
        death angina hospmi mi_fchd anychd stroke cvd hyperten
        yesnofmt.;
run;

/*==============================*
 | 4. BASELINE STROKE COUNT
 *==============================*/
/* Count prevalent stroke at baseline BEFORE excluding from analysis */
title "Number of Participants with Prevalent Stroke at Baseline (Period 1)";
proc freq data=work.frmgham;
    where period = 1;
    tables prevstrk / missing;
    format prevstrk yesnofmt.;
run;

/*==============================*
 | 5. CREATE BASELINE ANALYTIC DATASET
 *==============================*/
/*
Main project analysis:
- Baseline only: period = 1
- Exclude prevalent stroke at baseline
- Restrict follow-up to first 10 years = 3650 days
*/
data work.baseline;
    set work.frmgham;
    where period = 1;

    if prevstrk = 1 then delete;

    /* Administrative censoring at 10 years */
    follow10 = min(timestrk, 3650);

    /* Event indicator for stroke within 10 years */
    if stroke = 1 and timestrk <= 3650 then stroke10 = 1;
    else stroke10 = 0;

    label
        follow10 = 'Follow-up time truncated at 10 years (days)'
        stroke10 = 'Incident stroke within 10 years';
run;

/* Save processed dataset for reuse */
libname proj "&processed_dir";

data proj.baseline;
    set work.baseline;
run;
/*==============================*
 | 6. BASELINE DESCRIPTIVES
 *==============================*/
title "Table 1. Outcome: 10-Year Incident Stroke by Sex";
proc freq data=work.baseline;
    tables sex*stroke10;
    format sex sexfmt. stroke10 yesnofmt.;
run;

data work.baseline;
    set work.baseline;
    follow10_yrs = follow10 / 365.25;
    label follow10_yrs = 'Follow-up time truncated at 10 years (years)';
run;

title "Mean Follow-up Time by Sex";
proc means data=work.baseline mean std maxdec=2;
    class sex;
    var follow10_yrs;
    format sex sexfmt.;
run;

title "Table 1. Factors by Sex: Age, Systolic BP, and Diabetes";
proc means data=work.baseline n nmiss mean std maxdec=2;
    class sex;
    var age sysbp bmi totchol;
    format sex sexfmt.;
run;


proc freq data=work.baseline;
    tables sex*(diabetes cursmoke bpmeds prevchd);
    format sex sexfmt.
    	   diabetes yesnofmt.
           cursmoke yesnofmt.
           bpmeds yesnofmt.
           prevchd yesnofmt.;
run;

title "Missingness by Sex";
proc means data=work.baseline n nmiss;
    class sex;
    var age sysbp diabetes cursmoke bmi bpmeds prevchd;
    format sex sexfmt.;
run;

/* Complete-case data for primary analysis */
data work.complete_case;
    set work.baseline;
    if nmiss(age, sysbp, diabetes, cursmoke, bpmeds,
             totchol, bmi, prevchd) = 0;
run;

/* Save complete-case dataset */
data proj.complete_case;
    set work.complete_case;
run;

/*==============================*
 | 7. KAPLAN-MEIER CURVES
 *==============================*/
ods graphics on; 
ods listing gpath="&results_dir.";

ods graphics / reset
    width=8in
    height=6in
    imagename='KM_stroke_men'
    imagefmt=png
    image_dpi=300;

title "Kaplan-Meier Survival Curve: Men";
proc lifetest data=work.baseline
    plots=survival(atrisk=0 to 3650 by 730);
    where sex = 1;
    time follow10*stroke10(0);
    format sex sexfmt.;
run;

ods graphics / reset
    width=8in
    height=6in
    imagename='KM_stroke_women'
    imagefmt=png
    image_dpi=300;

title "Kaplan-Meier Survival Curve: Women";
proc lifetest data=work.baseline
    plots=survival(atrisk=0 to 3650 by 730);
    where sex = 2;
    time follow10*stroke10(0);
    format sex sexfmt.;
run;

title;

/*==============================*
 | 11. SEX-SPECIFIC COX MODELS
 *==============================*/
/*
Backward selection approach:
- Force AGE, SYSBP, and DIABETES to remain in all models
- Allow CURSMOKE, BPMEDS, TOTCHOL, BMI, PREVCHD to be removed
*/

title "Cox PH Model for 10-Year Incident Stroke: Men";
proc phreg data=work.complete_case plots(overlay)=survival;
    where sex = 1;

    class diabetes(ref='No')
          cursmoke(ref='No')
          bpmeds(ref='No')
          prevchd(ref='No') / param=ref;

    model follow10*stroke10(0) =
        age
        sysbp
        diabetes
        cursmoke
        bpmeds
        totchol
        bmi
        prevchd
    / rl
      selection=backward
      include=3
      slstay=0.10;

    hazardratio age   / units=10;
    hazardratio sysbp / units=10;

    assess ph / resample;

    format diabetes yesnofmt.
           cursmoke yesnofmt.
           bpmeds yesnofmt.
           prevchd yesnofmt.;
run;

title "Cox PH Model for 10-Year Incident Stroke: Women";
proc phreg data=work.complete_case plots(overlay)=survival;
    where sex = 2;

    class diabetes(ref='No')
          cursmoke(ref='No')
          bpmeds(ref='No')
          prevchd(ref='No') / param=ref;

    model follow10*stroke10(0) =
        age
        sysbp
        diabetes
        cursmoke
        bpmeds
        totchol
        bmi
        prevchd
    / rl
      selection=backward
      include=3
      slstay=0.10;

    hazardratio age   / units=10;
    hazardratio sysbp / units=10;

    assess ph / resample;

    format diabetes yesnofmt.
           cursmoke yesnofmt.
           bpmeds yesnofmt.
           prevchd yesnofmt.;
run;

 /*==============================*
 | 12. 10-YEAR PREDICTED RISKS
 *==============================*/
/*
Predicted 10-year stroke risk for illustrative profiles.

Ages of interest:
- 40, 50, 60 years

Illustrative risk profiles:
- High BP only              : sysbp=160, diabetes=0, cursmoke=0
- Diabetes only             : sysbp=120, diabetes=1, cursmoke=0
- High BP + diabetes        : sysbp=160, diabetes=1, cursmoke=0
- Current smoker only       : sysbp=120, diabetes=0, cursmoke=1

Predictions are based on the final sex-specific Cox models:
- Men   : age + sysbp + diabetes + cursmoke
- Women : age + sysbp + diabetes
*/

/* Men profiles */
data work.men_profiles;
    length risk_profile $30;
    input age risk_profile $ 1-30 sysbp diabetes cursmoke;
    format diabetes yesnofmt. cursmoke yesnofmt.;
    datalines;
40 High_BP_only                  160 0 0
40 Diabetes_only                 120 1 0
40 High_BP_plus_Diabetes         160 1 0
40 Current_smoker_only           120 0 1
50 High_BP_only                  160 0 0
50 Diabetes_only                 120 1 0
50 High_BP_plus_Diabetes         160 1 0
50 Current_smoker_only           120 0 1
60 High_BP_only                  160 0 0
60 Diabetes_only                 120 1 0
60 High_BP_plus_Diabetes         160 1 0
60 Current_smoker_only           120 0 1
;
run;

proc phreg data=work.complete_case;
    where sex = 1;

    class diabetes(ref='No')
          cursmoke(ref='No') / param=ref;

    model follow10*stroke10(0) = age sysbp diabetes cursmoke;

    baseline covariates=work.men_profiles
             out=work.men_pred
             survival=surv
             timelist=3650;
run;
data work.men_pred_10yr;
    set work.men_pred;
    sex_label = 'Men';
    prob_pct = (1 - surv) * 100;
    keep age risk_profile sex_label prob_pct;
run;

proc sort data=work.men_pred_10yr;
    by age risk_profile;
run;

proc transpose data=work.men_pred_10yr
    out=work.men_pred_table(drop=_name_);
    by age;
    id risk_profile;
    var prob_pct;
run;

title "Predicted 10-Year Stroke Risk for Illustrative Male Profiles";
proc print data=work.men_pred_table label noobs;
    format _numeric_ 6.2;
run;

/* Women profiles */
data work.women_profiles;
    length risk_profile $30;
    input age risk_profile $ 1-30 sysbp diabetes;
    format diabetes yesnofmt.;
    datalines;
40 High_BP_only                  160 0
40 Diabetes_only                 120 1
40 High_BP_plus_Diabetes         160 1
40 Current_smoker_only           120 0
50 High_BP_only                  160 0
50 Diabetes_only                 120 1
50 High_BP_plus_Diabetes         160 1
50 Current_smoker_only           120 0
60 High_BP_only                  160 0
60 Diabetes_only                 120 1
60 High_BP_plus_Diabetes         160 1
60 Current_smoker_only           120 0
;
run;

proc phreg data=work.complete_case;
    where sex = 2;

    class diabetes(ref='No') / param=ref;

    model follow10*stroke10(0) = age sysbp diabetes;

    baseline covariates=work.women_profiles
             out=work.women_pred
             survival=surv
             timelist=3650;
run;

data work.women_pred_10yr;
    set work.women_pred;
    sex_label = 'Women';
    prob_pct = (1 - surv) * 100;
    keep age risk_profile sex_label prob_pct;
run;

proc sort data=work.women_pred_10yr;
    by age risk_profile;
run;

proc transpose data=work.women_pred_10yr
    out=work.women_pred_table(drop=_name_);
    by age;
    id risk_profile;
    var prob_pct;
run;

title "Predicted 10-Year Stroke Risk for Illustrative Female Profiles";
proc print data=work.women_pred_table label noobs;
    format _numeric_ 6.2;
run;


/*==============================*
 | 13. FIGURE FROM MODEL OUTPUTS
 *==============================*/
/* Build the figure directly from model outputs instead of hard-coding values */
data work.table3_plot;
    set work.men_pred_10yr work.women_pred_10yr;
    length sex $6 profile $25 prob_label $8;
    sex = sex_label;

    select (risk_profile);
        when ('High_BP_only')          profile = 'HighBP';
        when ('Diabetes_only')         profile = 'Diabetes';
        when ('High_BP_plus_Diabetes') profile = 'HighBP_Diabetes';
        when ('Current_smoker_only')   profile = 'Smoker';
        otherwise                      profile = risk_profile;
    end;

    if age = 60 then prob_label = strip(put(round(prob_pct, 0.1), 5.1));
run;

proc format;
    value $plotproffmt
        'HighBP'           = 'High BP only'
        'Diabetes'         = 'Diabetes only'
        'HighBP_Diabetes'  = 'High BP + Diabetes'
        'Smoker'           = 'Current smoker only';
run;

ods listing gpath="&results_dir.";
ods graphics / reset width=10in height=5in imagename='Figure_Table3' outputfmt=png;

title "Figure 1. Predicted 10-Year Probability of Incident Stroke (%) by Age, Sex, and Risk Profile Derived from Sex-Specific Cox Proportional Hazard Models";
proc sgpanel data=work.table3_plot;
    panelby sex / columns=2 spacing=10 novarname;

    series x=age y=prob_pct / group=profile markers
        datalabel=prob_label
        datalabelpos=right
        datalabelattrs=(size=8)
        lineattrs=(thickness=2)
        markerattrs=(size=9);

    colaxis label='Age (years)' values=(40 50 60);
    rowaxis label='Predicted 10-Year Stroke Probability (%)' grid;
    keylegend / title='Risk Profile' position=bottom;

    format profile $plotproffmt.;
run;

title;

/*==============================*
 | 14. LONGITUDINAL CHANGE
 *==============================*/
data work.long_desc;
    set work.frmgham;
    where period in (1,2,3);
run;

/* Mean systolic BP by sex and exam period */
proc means data=work.long_desc noprint;
    class sex period;
    var sysbp;
    output out=work.bp_mean(drop=_type_ _freq_) mean=mean_value;
run;

/* Sort once for prevalence calculations */
proc sort data=work.long_desc out=work.long_desc_sorted;
    by sex period;
run;

/* Diabetes prevalence by sex and exam period */
proc freq data=work.long_desc_sorted noprint;
    by sex period;
    tables diabetes / out=work.diab_prev;
run;

data work.diab_prev_plot;
    set work.diab_prev;
    where diabetes = 1;
    outcome = 'Diabetes prevalence (%)';
    value = percent;
    keep sex period outcome value;
run;

/* Smoking prevalence by sex and exam period */
proc freq data=work.long_desc_sorted noprint;
    by sex period;
    tables cursmoke / out=work.smok_prev;
run;

data work.smok_prev_plot;
    set work.smok_prev;
    where cursmoke = 1;
    outcome = 'Smoking prevalence (%)';
value = percent;
    keep sex period outcome value;
run;

/* Standardize BP summary for panel plotting */
data work.bp_mean_plot;
    set work.bp_mean;
    where not missing(sex) and not missing(period);
    outcome = 'Mean systolic BP (mmHg)';
    value = mean_value;
    keep sex period outcome value;
run;

/* Combine all trend data */
data work.trend_all;
    set work.bp_mean_plot
        work.diab_prev_plot
        work.smok_prev_plot;
run;

title "Mean systolic blood pressure by exam period and sex";
proc print data=work.bp_mean_plot noobs;
    format sex sexfmt. period periodfmt. value 6.2;
run;

title "Diabetes prevalence by exam period and sex";
proc print data=work.diab_prev_plot noobs;
    format sex sexfmt. period periodfmt. value 6.2;
run;

title "Smoking prevalence by exam period and sex";
proc print data=work.smok_prev_plot noobs;
    format sex sexfmt. period periodfmt. value 6.2;
run;

title "Figure 2. Changes in systolic blood pressure, diabetes, and smoking across exam periods by sex";
proc sgpanel data=work.trend_all;
    panelby outcome / columns=3 onepanel novarname;
    series x=period y=value / group=sex markers datalabel=value lineattrs=(thickness=2);
    colaxis label='Exam period' integer;
    rowaxis grid;
    format sex sexfmt. period periodfmt. value 6.2;
run;
title;

/*==============================*
 | 15. EXPORT KEY TABLES
 *==============================*/
proc export data=work.men_pred_10yr
    outfile="&results_dir./men_predicted_10yr_risk.csv"
    dbms=csv replace;
run;

proc export data=work.women_pred_10yr
    outfile="&results_dir./women_predicted_10yr_risk.csv"
    dbms=csv replace;
run;

proc export data=work.diab_prev
    outfile="&results_dir./diabetes_prevalence_by_period.csv"
    dbms=csv replace;
run;

proc export data=work.smok_prev
    outfile="&results_dir./smoking_prevalence_by_period.csv"
    dbms=csv replace;
run;

/*==============================*
 | 16. CLEAN FINISH
 *==============================*/
title;
footnote;
ods html5 close;
ods listing;