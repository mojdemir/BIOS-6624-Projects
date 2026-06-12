/*====================================================================*
 | Bundle t001 - PROC FREQ baseline counts and cross-tabulations
 | Source: Project3/Code/1. Descriptive, PH, and Predictive Analysis.sas
 |         (sections 2, 4, 5, 6 - formats, baseline stroke count,
 |          analytic dataset, and outcome by sex)
 |
 | The author's PROC IMPORT of frmgham2.xls is replaced by a small
 | synthetic Framingham cohort built in autoexec.sas (work.frmgham);
 | all PROC FREQ logic, WHERE filters, and formats are the author's.
 *====================================================================*/

/* Display formats */
proc format;
    value sexfmt
        1 = 'Men'
        2 = 'Women';

    value yesnofmt
        0 = 'No'
        1 = 'Yes';
run;

/* Count prevalent stroke at baseline BEFORE excluding from analysis */
title "Number of Participants with Prevalent Stroke at Baseline (Period 1)";
proc freq data=work.frmgham;
    where period = 1;
    tables prevstrk / missing;
    format prevstrk yesnofmt.;
run;

/* Baseline analytic dataset: period 1, exclude prevalent stroke,
   administrative censoring at 10 years (3650 days) */
data work.baseline;
    set work.frmgham;
    where period = 1;

    if prevstrk = 1 then delete;

    follow10 = min(timestrk, 3650);

    if stroke = 1 and timestrk <= 3650 then stroke10 = 1;
    else stroke10 = 0;

    label
        follow10 = 'Follow-up time truncated at 10 years (days)'
        stroke10 = 'Incident stroke within 10 years';
run;

/* Outcome: 10-year incident stroke by sex */
title "Table 1. Outcome: 10-Year Incident Stroke by Sex";
proc freq data=work.baseline;
    tables sex*stroke10;
    format sex sexfmt. stroke10 yesnofmt.;
run;

/* Baseline risk factors by sex (one two-way table per factor) */
title "Baseline Risk Factors by Sex";
proc freq data=work.baseline;
    tables sex*diabetes
           sex*cursmoke
           sex*bpmeds
           sex*prevchd;
    format sex      sexfmt.
           diabetes yesnofmt.
           cursmoke yesnofmt.
           bpmeds   yesnofmt.
           prevchd  yesnofmt.;
run;

title;
