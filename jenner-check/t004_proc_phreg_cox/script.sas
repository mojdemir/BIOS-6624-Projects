/*====================================================================*
 | Bundle t004 - PROC PHREG Cox proportional hazards model
 | Source: Project3/Code/1. Descriptive, PH, and Predictive Analysis.sas
 |         (section 8 - Cox PH model for 10-year incident stroke)
 |
 | work.frmgham is built in autoexec.sas in place of the author's
 | PROC IMPORT. The outcome definition follow10*stroke10(0), the
 | RL (risk-limit) option, and the HAZARDRATIO ... / units=10
 | statements are the author's. The model here uses the continuous
 | risk factors (age, systolic BP) so the fit is well conditioned on
 | the small illustrative cohort shipped with this bundle.
 *====================================================================*/

/* Baseline analytic + complete-case dataset */
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

data work.complete_case;
    set work.baseline;
    if nmiss(age, sysbp, diabetes, cursmoke, bpmeds,
             totchol, bmi, prevchd) = 0;
run;

/* Cox PH model for 10-year incident stroke */
title "Cox PH Model for 10-Year Incident Stroke: Age and Systolic BP";
proc phreg data=work.complete_case;
    model follow10*stroke10(0) = age sysbp / rl;

    hazardratio age   / units=10;
    hazardratio sysbp / units=10;
run;

title;
