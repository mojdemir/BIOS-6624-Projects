/*====================================================================*
 | Bundle t005 - PROC SGPANEL longitudinal trends figure
 | Source: Project3/Code/1. Descriptive, PH, and Predictive Analysis.sas
 |         (section 10 - trends in systolic BP, diabetes prevalence,
 |          and smoking across examination periods 1-3)
 |
 | work.frmgham is built in autoexec.sas in place of the author's
 | PROC IMPORT. The summarize-then-stack data preparation, the
 | PANELBY layout, and the SERIES / KEYLEGEND options are the
 | author's.
 *====================================================================*/

proc format;
    value sexfmt
        1 = 'Men'
        2 = 'Women';
run;

/* Restrict to the three examination periods */
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

/* Print the underlying trend summaries */
title "Mean Systolic Blood Pressure by Exam Period and Sex";
proc print data=work.bp_mean_plot noobs;
    format sex sexfmt. value 6.2;
run;

title "Diabetes Prevalence by Exam Period and Sex";
proc print data=work.diab_prev_plot noobs;
    format sex sexfmt. value 6.2;
run;

/* Figure 2: panel of trends across examination periods */
ods graphics on;
ods graphics / reset
    width=11in
    height=4.5in
    imagename='Figure2_Changes_Risk_Factors'
    outputfmt=png;

title "Figure 2. Trends in Systolic Blood Pressure, Diabetes Prevalence, and Smoking by Sex Across Examination Periods 1-3";

proc sgpanel data=work.trend_all;
    panelby outcome / columns=3 onepanel novarname spacing=8;

    series x=period y=value /
        group=sex
        markers
        datalabel=value
        datalabelattrs=(size=7)
        lineattrs=(thickness=2)
        markerattrs=(size=8);

    colaxis label='Examination period' integer values=(1 2 3);
    rowaxis display=(nolabel) grid;
    keylegend / title='Sex' position=bottom;

    format sex sexfmt.;
run;

title;
