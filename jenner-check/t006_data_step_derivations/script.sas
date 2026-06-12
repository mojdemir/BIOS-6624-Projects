/*====================================================================*
 | Bundle t006 - DATA step derivations, FORMAT, and LABEL
 | Source: Project3/Code/1. Descriptive, PH, and Predictive Analysis.sas
 |         (sections 2, 3, 5 - formats, variable labels, baseline and
 |          complete-case analytic datasets)
 |
 | This bundle exercises the data-management core the rest of the
 | analysis is built on: PROC FORMAT value definitions, a LABEL
 | statement covering the Framingham variables, the period-1
 | baseline construction with administrative censoring, the 10-year
 | stroke event indicator, and the complete-case subset via NMISS.
 | work.frmgham is built in autoexec.sas in place of the author's
 | PROC IMPORT.
 *====================================================================*/

/*==============================*
 | FORMATS
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
run;

/*==============================*
 | LABEL VARIABLES
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
        prevstrk = 'Prevalent stroke'
        period   = 'Examination cycle'
        stroke   = 'Incident stroke'
        timestrk = 'Days from baseline to stroke/censor';

    format
        sex    sexfmt.
        period periodfmt.
        cursmoke diabetes bpmeds prevstrk stroke yesnofmt.;
run;

/*==============================*
 | BASELINE ANALYTIC DATASET
 *==============================*/
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

/*==============================*
 | COMPLETE-CASE SUBSET
 *==============================*/
data work.complete_case;
    set work.baseline;
    if nmiss(age, sysbp, diabetes, cursmoke, bpmeds,
             totchol, bmi, prevchd) = 0;
run;

/* Show the derived analytic variables for the first few participants */
title "Derived Baseline Analytic Variables (First 10 Participants)";
proc print data=work.complete_case(obs=10) label;
    var randid sex age sysbp diabetes stroke10 follow10;
    format sex sexfmt. diabetes yesnofmt. stroke10 yesnofmt.;
run;

title;
