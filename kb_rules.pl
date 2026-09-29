% ===========================================================================
%  CreditWise Expert System
%  kb_rules.pl  -  Knowledge base: RULES
%
%  Every rule is declared once, as data, in the form
%
%      rule(Id, Stratum, Conclusion, [Condition, ...], Description).
%
%  Declaring rules as data rather than as ordinary Prolog clauses lets the
%  SAME rule base be executed by BOTH inference engines:
%      - the forward chaining engine (data driven, engine.pl)
%      - the backward chaining meta interpreter (goal driven, engine.pl)
%  This is what allows the system to demonstrate both mechanisms on one
%  knowledge base, as required by the assignment.
%
%  Stratum controls the order in which the forward chainer saturates, so
%  that a rule using absent/1 (negation as failure) is never evaluated
%  before the facts it negates have finished being derived.
%      Stratum 1 : eligibility sub-goals            (pure positive rules)
%      Stratum 2 : overall eligibility, rejections, individual risk factors
%      Stratum 3 : overall risk grade               (worst factor wins)
%      Stratum 4 : final decision, conditions, requirements
%
%  SOURCE: all rules derive from the expert interview recorded in
%  kb_facts.pl. The rule_source/2 clause under each rule names the exact
%  question on the Knowledge Acquisition Form it came from.
% ===========================================================================

:- discontiguous rule/5.
:- discontiguous rule_source/2.

% ---------------------------------------------------------------------------
% PRIMITIVE (directly evaluable) CONDITIONS
% Anything listed here is called straight away instead of being proved
% against the rule base.
% ---------------------------------------------------------------------------

primitive(af(_, _)).
primitive(threshold(_, _)).
primitive(maturity_age(_)).
primitive(monthly_instalment(_)).
primitive(dti_ratio(_)).
primitive(salaried(_)).
primitive(non_salaried(_)).
primitive(ge(_, _)).
primitive(le(_, _)).
primitive(gt(_, _)).
primitive(lt(_, _)).
primitive(neq(_, _)).

ge(A, B)  :- A >= B.
le(A, B)  :- A =< B.
gt(A, B)  :- A >  B.
lt(A, B)  :- A <  B.
neq(A, B) :- A \== B.

% ===========================================================================
% STRATUM 1  -  ELIGIBILITY SUB-GOALS
% ===========================================================================

% --- R1 : minimum age -------------------------------------------------------
rule(r1, 1, age_eligible,
     [ af(age, Age), threshold(min_age, Min), ge(Age, Min) ],
     'The applicant is at least 18 years old.').
rule_source(r1, 'Interview Part 1, Q1').

% --- R2 : age at maturity, general ------------------------------------------
rule(r2, 1, maturity_eligible,
     [ af(employment, E), neq(E, pensioner),
       maturity_age(M), threshold(max_age_at_maturity, Max), le(M, Max) ],
     'The applicant will be 60 or younger when the loan matures.').
rule_source(r2, 'Interview Part 1, Q2').

% --- R3 : age at maturity, pensioner concession -----------------------------
rule(r3, 1, maturity_eligible,
     [ af(employment, pensioner),
       maturity_age(M), threshold(max_age_at_maturity_pensioner, Max),
       le(M, Max) ],
     'A pensioner may be up to 75 when the loan matures.').
rule_source(r3, 'Interview Part 1, Q2 free text: "75 - for pensioner"').

% --- R4 : minimum income ----------------------------------------------------
rule(r4, 1, income_eligible,
     [ af(gross_income, I), threshold(min_monthly_income, Min), ge(I, Min) ],
     'Gross monthly income is at least Rs. 30,000.').
rule_source(r4, 'Interview Part 1, Q3: "other" selected, "30,000" entered').

% --- R5 : government service exemption --------------------------------------
rule(r5, 1, service_eligible,
     [ af(employment, government_permanent) ],
     'A government permanent employee has no minimum service requirement.').
rule_source(r5, 'Interview Part 1, Q4 free text: "not consider for \c
                 government employees"').

% --- R6 : private permanent service -----------------------------------------
rule(r6, 1, service_eligible,
     [ af(employment, private_permanent), af(service_years, Y),
       threshold(min_service_years_private, Min), ge(Y, Min) ],
     'A private sector permanent employee has at least 2 years of service.').
rule_source(r6, 'Interview Part 1, Q4').

% --- R7 : self employed, assessed on trading history ------------------------
% NSB applies NO minimum years in business. This rule is simply the route
% for a business that already has trading history to show. A business with
% no trading history qualifies under R8 instead.
rule(r7, 1, service_eligible,
     [ af(employment, self_employed), af(service_years, Y),
       threshold(business_trading_history_years, T), ge(Y, T) ],
     'A self employed applicant with at least one year of trading history \c
      is assessed on that history.').
rule_source(r7, 'Interview Part 1, Q5, read together with the free text. \c
                 The one year figure selects the assessment route, it is \c
                 not a minimum barrier (see R8)').

% --- R8 : self employed, new business with an evaluated proposal ------------
rule(r8, 1, service_eligible,
     [ af(employment, self_employed), af(business_proposal_approved, yes) ],
     'A business at its start, with no trading history, qualifies once its \c
      business proposal has been evaluated and approved. This is why NSB \c
      applies no minimum years in business requirement.').
rule_source(r8, 'Interview Part 1, Q5 free text: "loan gives at start of the \c
                 business also, after evaluating of business proposal", \c
                 confirmed by the expert').

% --- R9 : probation ---------------------------------------------------------
rule(r9, 1, service_eligible,
     [ af(employment, probation) ],
     'An applicant on probation passes the service test but attracts \c
      conditions (see R33).').
rule_source(r9, 'Interview Part 1, Q6: accepted with conditions').

% --- R10 : contract employee, sufficient unexpired term ---------------------
rule(r10, 1, service_eligible,
     [ af(employment, contract), af(contract_months_remaining, M),
       threshold(min_contract_months, Min), ge(M, Min) ],
     'A contract employee has enough of the contract still to run.').
rule_source(r10, 'Interview Part 1, Q7 (threshold is a documented assumption)').

% --- R11 : renewable foreign contract ---------------------------------------
rule(r11, 1, service_eligible,
     [ af(employment, contract), af(contract_type, foreign_renewable) ],
     'A renewable foreign contract is accepted regardless of unexpired term.').
rule_source(r11, 'Interview Part 1, Q7 free text: "for foreign contracts - \c
                  renewable"').

% --- R12 : pensioner --------------------------------------------------------
rule(r12, 1, service_eligible,
     [ af(employment, pensioner) ],
     'A pensioner has no service period requirement.').
rule_source(r12, 'Interview Part 1, Q4 and Q2, read together').

% --- R13 : salary remittance, salaried applicants ---------------------------
rule(r13, 1, remittance_eligible,
     [ af(employment, E), salaried(E), af(salary_remitted, yes) ],
     'A salaried applicant remits their salary to this bank.').
rule_source(r13, 'Interview Part 1, Q13: Yes, always').

% --- R14 : salary remittance not applicable ---------------------------------
rule(r14, 1, remittance_eligible,
     [ af(employment, E), non_salaried(E) ],
     'Salary remittance cannot be required of a self employed applicant or \c
      a pensioner, neither of whom draws a salary.').
rule_source(r14, 'Derived from Interview Part 4, Case 3, where a self \c
                  employed applicant was approved with conditions').

% --- R15 : debt to income ratio ---------------------------------------------
rule(r15, 1, dti_eligible,
     [ dti_ratio(R), threshold(max_dti_ratio, Max), le(R, Max) ],
     'Total monthly debt service is at most 60% of gross income.').
rule_source(r15, 'Interview Part 1, Q8 and Q9').

% --- R16 : loan amount ceiling ----------------------------------------------
rule(r16, 1, amount_eligible,
     [ af(amount, A), threshold(max_loan_amount, Max), le(A, Max) ],
     'The requested amount does not exceed Rs. 20 million.').
rule_source(r16, 'Interview Part 1, Q10: "other" selected, "20 million" entered').

% --- R17 : repayment period ceiling -----------------------------------------
rule(r17, 1, period_eligible,
     [ af(period_months, P), threshold(max_period_months, Max), le(P, Max) ],
     'The repayment period does not exceed 144 months.').
rule_source(r17, 'Interview Part 1, Q12: "other" selected, "12 years" entered').

% --- R18 to R23 : CRIB findings that do NOT block a loan --------------------
rule(r18, 1, credit_eligible, [ af(crib, clean) ],
     'A clean CRIB record satisfies the credit history test.').
rule_source(r18, 'Interview Part 2, row 1: Approve').

rule(r19, 1, credit_eligible, [ af(crib, late_1) ],
     'One late payment in 12 months does not block the loan.').
rule_source(r19, 'Interview Part 2, row 2: Approve').

rule(r20, 1, credit_eligible, [ af(crib, late_2plus) ],
     'Two or more late payments in 12 months do not block the loan.').
rule_source(r20, 'Interview Part 2, row 3: Approve').

rule(r21, 1, credit_eligible, [ af(crib, default_settled) ],
     'A past default that has been settled does not block the loan.').
rule_source(r21, 'Interview Part 2, row 5: Approve').

rule(r22, 1, credit_eligible, [ af(crib, default_unsettled) ],
     'An unsettled past default does not by itself block the loan at NSB.').
rule_source(r22, 'Interview Part 2, row 6: Approve. Confirmed by Part 5, \c
                  where "unsettled default" was deliberately NOT ticked as \c
                  an immediate rejection trigger').

rule(r23, 1, credit_eligible, [ af(crib, no_history) ],
     'An applicant with no credit history is accepted.').
rule_source(r23, 'Interview Part 2, row 8: Approve').

% ===========================================================================
% STRATUM 2  -  OVERALL ELIGIBILITY, REJECTIONS, INDIVIDUAL RISK FACTORS
% ===========================================================================

% --- R24 : the conjunction of every eligibility test ------------------------
rule(r24, 2, eligible,
     [ age_eligible, maturity_eligible, income_eligible, service_eligible,
       remittance_eligible, dti_eligible, amount_eligible, period_eligible,
       credit_eligible ],
     'Every individual eligibility test has been satisfied.').
rule_source(r24, 'Conjunction of Interview Part 1 and Part 2').

% --- R25 to R32 : immediate rejection triggers ------------------------------
rule(r25, 2, rejected(below_minimum_income),
     [ absent(income_eligible) ],
     'Income below Rs. 30,000 is an immediate rejection.').
rule_source(r25, 'Interview Part 5, rejection triggers: ticked').

rule(r26, 2, rejected(below_minimum_service),
     [ absent(service_eligible) ],
     'Failing the service or employment test is an immediate rejection.').
rule_source(r26, 'Interview Part 5, rejection triggers: ticked').

rule(r27, 2, rejected(over_age_limit),
     [ absent(maturity_eligible) ],
     'Exceeding the age limit at maturity is an immediate rejection.').
rule_source(r27, 'Interview Part 5, rejection triggers: ticked').

rule(r28, 2, rejected(debt_ratio_over_limit),
     [ absent(dti_eligible) ],
     'A debt to income ratio above 60% is an immediate rejection.').
rule_source(r28, 'Interview Part 5, rejection triggers: ticked').

rule(r29, 2, rejected(legal_action_recorded),
     [ af(crib, writeoff_legal) ],
     'A write off or recorded legal action is an immediate rejection.').
rule_source(r29, 'Interview Part 2, row 7: Reject. Also Part 5: ticked').

rule(r30, 2, rejected(currently_in_arrears),
     [ af(crib, arrears) ],
     'An applicant currently in arrears is rejected.').
rule_source(r30, 'Interview Part 2, row 4: Reject').

rule(r31, 2, rejected(under_minimum_age),
     [ absent(age_eligible) ],
     'An applicant under 18 cannot be granted a loan.').
rule_source(r31, 'Interview Part 1, Q1').

rule(r32, 2, rejected(salary_not_remitted),
     [ absent(remittance_eligible) ],
     'A salaried applicant who does not remit salary to NSB is rejected.').
rule_source(r32, 'Interview Part 1, Q13: Yes, always').

rule(r33, 2, rejected(amount_over_maximum),
     [ absent(amount_eligible) ],
     'A request above Rs. 20 million is outside the personal loan product.').
rule_source(r33, 'Interview Part 1, Q10').

rule(r34, 2, rejected(period_over_maximum),
     [ absent(period_eligible) ],
     'A repayment period beyond 144 months is outside the product.').
rule_source(r34, 'Interview Part 1, Q12').

% --- R35 to R39 : risk factor, employment type ------------------------------
% The expert named only the lowest and the highest risk employment types.
% The remaining types are placed between them.
rule(r35, 2, risk_factor(employment, low),
     [ af(employment, pensioner) ],
     'A pensioner is the lowest risk employment type.').
rule_source(r35, 'Interview Part 3, Q3: Pensioner').

rule(r36, 2, risk_factor(employment, high),
     [ af(employment, self_employed) ],
     'A self employed applicant is the highest risk employment type.').
rule_source(r36, 'Interview Part 3, Q4: Self employed').

rule(r37, 2, risk_factor(employment, low),
     [ af(employment, government_permanent) ],
     'Permanent government employment is low risk.').
rule_source(r37, 'Interview Part 3, Q3 and Q4, read together').

rule(r38, 2, risk_factor(employment, low),
     [ af(employment, private_permanent) ],
     'Permanent private sector employment is low risk.').
rule_source(r38, 'Interview Part 4, Case 1, graded Low by the expert').

rule(r39, 2, risk_factor(employment, medium),
     [ af(employment, contract) ],
     'Contract employment sits between the two named extremes.').
rule_source(r39, 'Interview Part 3, Q4, where Contract was offered but \c
                  Self employed was chosen as the highest risk').

rule(r40, 2, risk_factor(employment, medium),
     [ af(employment, probation) ],
     'Probation sits between the two named extremes.').
rule_source(r40, 'Interview Part 1, Q6 and Part 3, Q4').

% --- R41, R42 : risk factor, length of service ------------------------------
% A pensioner has no current service, so the service length factor does not
% apply to them. Their employment factor (R35) governs instead.
rule(r41, 2, risk_factor(service, low),
     [ af(employment, E), neq(E, pensioner),
       af(service_years, Y), threshold(low_risk_service_years, T), ge(Y, T) ],
     'Five or more years of service is low risk.').
rule_source(r41, 'Interview Part 3, Q5: above 5 years').

rule(r42, 2, risk_factor(service, medium),
     [ af(employment, E), neq(E, pensioner),
       af(service_years, Y), threshold(low_risk_service_years, T), lt(Y, T) ],
     'Less than five years of service is medium risk.').
rule_source(r42, 'Interview Part 3, Q5, complement').

% --- R43 to R46 : risk factor, credit history -------------------------------
rule(r43, 2, crib_blemish, [ af(crib, late_1) ],
     'One late payment counts as a CRIB blemish.').
rule_source(r43, 'Interview Part 3, Q6').

rule(r44, 2, crib_blemish, [ af(crib, late_2plus) ],
     'Repeated late payments count as a CRIB blemish.').
rule_source(r44, 'Interview Part 3, Q6').

rule(r45, 2, crib_blemish, [ af(crib, default_settled) ],
     'A settled past default counts as a CRIB blemish.').
rule_source(r45, 'Interview Part 3, Q6').

rule(r46, 2, crib_blemish, [ af(crib, default_unsettled) ],
     'An unsettled past default counts as a CRIB blemish.').
rule_source(r46, 'Interview Part 3, Q6').

% --- R47, R48 : the blemish grade depends on the loan amount ----------------
rule(r47, 2, risk_factor(credit, high),
     [ crib_blemish, af(amount, A), threshold(large_loan_amount, T),
       gt(A, T) ],
     'A CRIB blemish on a large loan is high risk.').
rule_source(r47, 'Interview Part 3, Q6: "depends on the amount"').

rule(r48, 2, risk_factor(credit, medium),
     [ crib_blemish, af(amount, A), threshold(large_loan_amount, T),
       le(A, T) ],
     'A CRIB blemish on a smaller loan is medium risk.').
rule_source(r48, 'Interview Part 3, Q6: "depends on the amount"').

rule(r49, 2, risk_factor(credit, low),
     [ af(crib, clean) ],
     'A clean CRIB record is low risk.').
rule_source(r49, 'Interview Part 3, Q6, complement').

rule(r50, 2, risk_factor(credit, low),
     [ af(crib, no_history) ],
     'No credit history is not a blemish, so it is not a risk factor.').
rule_source(r50, 'Interview Part 3, Q6, complement of "any CRIB blemish"').

% ===========================================================================
% STRATUM 3  -  OVERALL RISK GRADE  (the worst factor decides)
% ===========================================================================

rule(r51, 3, risk(high),
     [ risk_factor(_, high) ],
     'If any single factor is high risk, the overall grade is high, \c
      because the expert resolves conflicts in favour of the worse factor.').
rule_source(r51, 'Interview Part 3, Q7: the worse factor').

rule(r52, 3, risk(medium),
     [ absent(risk_factor(_, high)), risk_factor(_, medium) ],
     'With no high risk factor but at least one medium, the grade is medium.').
rule_source(r52, 'Interview Part 3, Q7: the worse factor').

rule(r53, 3, risk(low),
     [ absent(risk_factor(_, high)), absent(risk_factor(_, medium)) ],
     'With every factor low, the overall grade is low.').
rule_source(r53, 'Interview Part 3, Q7: the worse factor').

% ===========================================================================
% STRATUM 4  -  DECISION, CONDITIONS AND STANDING REQUIREMENTS
% ===========================================================================

rule(r54, 4, decision(reject),
     [ rejected(_) ],
     'Any rejection trigger overrides everything else.').
rule_source(r54, 'Interview Part 5, immediate rejection list').

rule(r55, 4, decision(approve_with_conditions),
     [ absent(rejected(_)), eligible, risk(high) ],
     'An eligible but high risk applicant is approved with conditions, \c
      because the grade governs the conditions attached.').
rule_source(r55, 'Interview Part 3, Q8 and Part 4, Case 3').

rule(r56, 4, decision(approve_with_conditions),
     [ absent(rejected(_)), eligible, af(employment, probation) ],
     'An applicant on probation is approved with conditions.').
rule_source(r56, 'Interview Part 1, Q6: accepted with conditions').

rule(r57, 4, decision(approve),
     [ absent(rejected(_)), eligible, risk(medium),
       absent(af(employment, probation)) ],
     'An eligible medium risk applicant is approved on standard terms.').
rule_source(r57, 'Interview Part 3, Q8').

rule(r58, 4, decision(approve),
     [ absent(rejected(_)), eligible, risk(low),
       absent(af(employment, probation)) ],
     'An eligible low risk applicant is approved on standard terms.').
rule_source(r58, 'Interview Part 4, Case 1: Approve, Low').

% --- R59 to R61 : the conditions the expert attaches ------------------------
rule(r59, 4, condition(shorter_repayment_period),
     [ decision(approve_with_conditions) ],
     'Shorten the repayment period.').
rule_source(r59, 'Interview Part 5, conditions: Shorter period ticked').

rule(r60, 4, condition(higher_interest_rate),
     [ decision(approve_with_conditions) ],
     'Charge a higher interest rate.').
rule_source(r60, 'Interview Part 5, conditions: Higher interest rate ticked').

rule(r61, 4, condition(additional_guarantors),
     [ decision(approve_with_conditions) ],
     'Require guarantors over and above the standard two.').
rule_source(r61, 'Interview Part 5, conditions free text: "Guarantors"').

% --- R62, R63 : standing requirements on any approval -----------------------
rule(r62, 4, requirement(guarantors_two),
     [ decision(approve) ],
     'Two guarantors are required on every approved personal loan.').
rule_source(r62, 'Interview Part 1, Q14 and Q15').

rule(r63, 4, requirement(guarantors_two),
     [ decision(approve_with_conditions) ],
     'Two guarantors are required on every approved personal loan.').
rule_source(r63, 'Interview Part 1, Q14 and Q15').