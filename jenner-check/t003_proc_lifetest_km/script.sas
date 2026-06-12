/*====================================================================*
 | Bundle t003 - PROC LIFETEST Kaplan-Meier survival curves
 | Source: Project3/Code/1. Descriptive, PH, and Predictive Analysis.sas
 |         (section 7 - sex-specific KM curves for 10-year stroke-free
 |          survival)
 |
 | work.frmgham is built in autoexec.sas in place of the author's
 | PROC IMPORT; the complete-case construction, TIME statement, and
 | PLOTS=SURVIVAL options are the author's.
 *====================================================================*/

proc format;
    value sexfmt
        1 = 'Men'
        2 = 'Women';
run;

/* Baseline analytic + complete-case dataset */
data work.baseline;
    set work.frmgham;
    where period = 1;
    if prevstrk = 1 then delete;

    follow10 = min(timestrk, 3650);

    if stroke = 1 and timestrk <= 3650 then stroke10 = 1;
    else stroke10 = 0;
run;

data work.complete_case;
    set work.baseline;
    if nmiss(age, sysbp, diabetes, cursmoke, bpmeds,
             totchol, bmi, prevchd) = 0;
run;

ods graphics on;

/*------------------------------*
 | KM Curve: Men
 *------------------------------*/
ods graphics / reset
    width=8in
    height=6in
    imagename='KM_stroke_men'
    outputfmt=png;

title "Kaplan-Meier Survival Curve for 10-Year Stroke-Free Survival: Men";

proc lifetest data=work.complete_case
    plots=survival(atrisk=0 to 3650 by 730 cl);
    where sex = 1;
    time follow10*stroke10(0);
    format sex sexfmt.;
run;

/*------------------------------*
 | KM Curve: Women
 *------------------------------*/
ods graphics / reset
    width=8in
    height=6in
    imagename='KM_stroke_women'
    outputfmt=png;

title "Kaplan-Meier Survival Curve for 10-Year Stroke-Free Survival: Women";

proc lifetest data=work.complete_case
    plots=survival(atrisk=0 to 3650 by 730 cl);
    where sex = 2;
    time follow10*stroke10(0);
    format sex sexfmt.;
run;

title;
