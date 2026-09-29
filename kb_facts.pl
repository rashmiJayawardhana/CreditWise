% ===========================================================================
%  CreditWise Expert System
%  kb_facts.pl  -  Knowledge base: FACTS
%
%  Every threshold below was obtained from a structured interview with a
%  domain expert. No value in this file was invented by the developer.
%
%  SOURCE OF ALL FACTS:
%    Expert   : Ms. Dilshara Sewwandi, Deputy Manager
%    Institute: National Savings Bank (NSB), Wadduwa Branch
%    Date     : 28 September 2026
%    Instrument: "Knowledge Acquisition Form: Personal Loan Assessment"
%                (signed original attached as Annex A of the report)
% ===========================================================================

:- dynamic af/2.          % af(Attribute, Value) - facts about the current applicant
:- discontiguous threshold/2.
:- discontiguous threshold_source/2.

% ---------------------------------------------------------------------------
% F1 - F20 : THRESHOLD FACTS ACQUIRED FROM THE EXPERT
% ---------------------------------------------------------------------------
% threshold(Name, Value).
% threshold_source(Name, 'where the expert stated it').

threshold(min_age, 18).
threshold_source(min_age,
    'Interview Part 1, Q1: minimum age of applicant = 18').

threshold(max_age_at_maturity, 60).
threshold_source(max_age_at_maturity,
    'Interview Part 1, Q2: maximum age when the loan matures = 60').

threshold(max_age_at_maturity_pensioner, 75).
threshold_source(max_age_at_maturity_pensioner,
    'Interview Part 1, Q2 free text: "75 - for pensioner"').

threshold(min_monthly_income, 30000).
threshold_source(min_monthly_income,
    'Interview Part 1, Q3: the expert took none of the printed options, \c
     marked "other" and entered "30,000"').

threshold(min_service_years_private, 2).
threshold_source(min_service_years_private,
    'Interview Part 1, Q4: minimum service, permanent employee = 2 years').

threshold(business_trading_history_years, 1).
threshold_source(business_trading_history_years,
    'Interview Part 1, Q5: one year of trading history. This is the length \c
     at which a self employed applicant can be assessed on trading history \c
     alone. It is NOT a minimum barrier, see min_business_years_applied').

threshold(min_business_years_applied, no).
threshold_source(min_business_years_applied,
    'Interview Part 1, Q5 free text: "loan gives at start of the business \c
     also, after evaluating of business proposal", confirmed by the expert. \c
     A business with no trading history qualifies once its proposal has been \c
     evaluated, so NSB applies no minimum years in business requirement').

threshold(max_dti_ratio, 0.60).
threshold_source(max_dti_ratio,
    'Interview Part 1, Q8: maximum debt to income ratio = 60%').

threshold(dti_income_basis, gross).
threshold_source(dti_income_basis,
    'Interview Part 1, Q9: the ratio is based on gross income').

threshold(max_loan_amount, 20000000).
threshold_source(max_loan_amount,
    'Interview Part 1, Q10: the expert took none of the printed options, \c
     marked "other" and entered "20 million"').

threshold(salary_multiple_used, no).
threshold_source(salary_multiple_used,
    'Interview Part 1, Q11: multiple of monthly salary = not used').

threshold(max_period_months, 144).
threshold_source(max_period_months,
    'Interview Part 1, Q12: the expert took none of the printed options, \c
     marked "other" and entered "12 years" = 144 months').

threshold(salary_remittance_required, yes).
threshold_source(salary_remittance_required,
    'Interview Part 1, Q13: salary must be remitted to this bank = Yes, always').

threshold(guarantor_policy, always).
threshold_source(guarantor_policy,
    'Interview Part 1, Q14: a guarantor is required = Always').

threshold(guarantors_required, 2).
threshold_source(guarantors_required,
    'Interview Part 1, Q15: number of guarantors needed = 2').

threshold(low_risk_service_years, 5).
threshold_source(low_risk_service_years,
    'Interview Part 3, Q5: service length counting as low risk = above 5 years').

threshold(dti_used_in_risk_grading, no).
threshold_source(dti_used_in_risk_grading,
    'Interview Part 3, Q1 and Q2: on both bands the expert took none of the \c
     printed options, marked "other" and entered "not consider"').

threshold(lowest_risk_employment, pensioner).
threshold_source(lowest_risk_employment,
    'Interview Part 3, Q3: lowest risk employment type = Pensioner').

threshold(highest_risk_employment, self_employed).
threshold_source(highest_risk_employment,
    'Interview Part 3, Q4: highest risk employment type = Self employed').

threshold(blemish_grade_basis, loan_amount).
threshold_source(blemish_grade_basis,
    'Interview Part 3, Q6: any CRIB blemish grade = depends on the amount').

threshold(conflict_resolution, worse_factor).
threshold_source(conflict_resolution,
    'Interview Part 3, Q7: if two factors disagree, follow the worse factor').

threshold(grade_affects, conditions_attached).
threshold_source(grade_affects,
    'Interview Part 3, Q8: the risk grade changes the conditions attached').

% ---------------------------------------------------------------------------
% DOCUMENTED ASSUMPTIONS
%
% The interview did not fix these three values. They are marked clearly so
% they are engineering defaults, not expert rules.
% Each is stated in Section 3.4 (Assumptions) of the report.
% ---------------------------------------------------------------------------

threshold(min_contract_months, 12).
threshold_source(min_contract_months,
    'ASSUMPTION: the expert said "only if enough of the contract remains" \c
     but did not fix a number. 12 months adopted as a conservative default').

threshold(large_loan_amount, 1000000).
threshold_source(large_loan_amount,
    'ASSUMPTION: the expert said a CRIB blemish grade "depends on the \c
     amount" but did not fix the cut off. Rs. 1,000,000 adopted').

threshold(annual_interest_rate, 0.15).
threshold_source(annual_interest_rate,
    'ASSUMPTION: needed to estimate the instalment for the debt ratio test. \c
     15% p.a. reducing balance. The user may override it at run time').

% ---------------------------------------------------------------------------
% DOMAIN VALUE SETS
% ---------------------------------------------------------------------------

employment_type(government_permanent).
employment_type(private_permanent).
employment_type(probation).
employment_type(contract).
employment_type(self_employed).
employment_type(pensioner).

employment_label(government_permanent, 'Permanent, government').
employment_label(private_permanent,    'Permanent, private sector').
employment_label(probation,            'On probation').
employment_label(contract,             'Contract employee').
employment_label(self_employed,        'Self employed').
employment_label(pensioner,            'Pensioner').

% Salary remittance can only be required of someone who receives a salary.
salaried(government_permanent).
salaried(private_permanent).
salaried(probation).
salaried(contract).

non_salaried(self_employed).
non_salaried(pensioner).

crib_status(clean).
crib_status(late_1).
crib_status(late_2plus).
crib_status(arrears).
crib_status(default_settled).
crib_status(default_unsettled).
crib_status(writeoff_legal).
crib_status(no_history).

crib_label(clean,             'Clean record').
crib_label(late_1,            'One late payment in the last 12 months').
crib_label(late_2plus,        'Two or more late payments in 12 months').
crib_label(arrears,           'Currently in arrears').
crib_label(default_settled,   'Past default, now settled').
crib_label(default_unsettled, 'Past default, unsettled').
crib_label(writeoff_legal,    'Write off or legal action recorded').
crib_label(no_history,        'No credit history at all').

% ---------------------------------------------------------------------------
% WORKING MEMORY HANDLING
% ---------------------------------------------------------------------------

set_fact(Attribute, Value) :-
    retractall(af(Attribute, _)),
    assertz(af(Attribute, Value)).

clear_facts :-
    retractall(af(_, _)).

% ---------------------------------------------------------------------------
% DERIVED NUMERIC VALUES
% ---------------------------------------------------------------------------

% Age of the applicant on the day the last instalment falls due.
maturity_age(MaturityAge) :-
    af(age, Age),
    af(period_months, Months),
    MaturityAge is Age + ceiling(Months / 12.0).

% Equated monthly instalment, reducing balance method.
%   I = P * r / (1 - (1 + r)^-n)
monthly_instalment(Instalment) :-
    af(amount, Principal),
    af(period_months, N),
    N > 0,
    ( af(annual_rate, R) -> true ; threshold(annual_interest_rate, R) ),
    MonthlyRate is R / 12.0,
    (   MonthlyRate =:= 0
    ->  Instalment is Principal / N
    ;   Instalment is Principal * MonthlyRate /
                      (1 - (1 + MonthlyRate) ** (-N))
    ).

% Total monthly debt service divided by gross monthly income.
dti_ratio(Ratio) :-
    monthly_instalment(Instalment),
    af(existing_commitments, Existing),
    af(gross_income, Income),
    Income > 0,
    Ratio is (Existing + Instalment) / Income.

dti_percent(Percent) :-
    dti_ratio(Ratio),
    Percent is Ratio * 100.