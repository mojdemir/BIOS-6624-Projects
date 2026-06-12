/*====================================================================*
 | Bundle t002 - PROC MEANS baseline descriptives by sex
 | Source: Project3/Code/1. Descriptive, PH, and Predictive Analysis.sas
 |         (section 6 - baseline descriptives and missingness)
 |
 | work.frmgham is built in autoexec.sas in place of the author's
 | PROC IMPORT; all PROC MEANS logic and CLASS/VAR choices are the
 | author's.
 *====================================================================*/

proc format;
    value sexfmt
        1 = 'Men'
        2 = 'Women';
run;

/* Baseline analytic dataset (period 1, exclude prevalent stroke) */
data work.baseline;
    set work.frmgham;
    where period = 1;
    if prevstrk = 1 then delete;

    follow10     = min(timestrk, 3650);
    follow10_yrs = follow10 / 365.25;

    if stroke = 1 and timestrk <= 3650 then stroke10 = 1;
    else stroke10 = 0;

    label
        follow10_yrs = 'Follow-up time truncated at 10 years (years)';
run;

/* Mean follow-up time by sex */
title "Mean Follow-up Time by Sex";
proc means data=work.baseline mean std maxdec=2;
    class sex;
    var follow10_yrs;
    format sex sexfmt.;
run;

/* Baseline factors by sex: age, systolic BP, BMI, cholesterol */
title "Table 1. Factors by Sex: Age, Systolic BP, BMI, and Cholesterol";
proc means data=work.baseline n nmiss mean std maxdec=2;
    class sex;
    var age sysbp bmi totchol;
    format sex sexfmt.;
run;

/* Missingness by sex */
title "Missingness by Sex";
proc means data=work.baseline n nmiss;
    class sex;
    var age sysbp diabetes cursmoke bmi bpmeds prevchd;
    format sex sexfmt.;
run;

title;
