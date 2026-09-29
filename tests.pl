% ===========================================================================
%  CreditWise Expert System
%  tests.pl  -  TEST CASES
%
%  TC1 to TC4 are EXPERT VERIFIED: the expected results are the expert's
%  own answers to Part 4 of the Knowledge Acquisition Form.
%  TC5 to TC16 are SYSTEM VERIFICATION: rules Part 4 did not reach.
% ===========================================================================

% test_case(Id, Origin, Description, Facts, ExpectedDecision, ExpectedGrade).

test_case(tc1, expert,
  'Age 32, permanent private, 5 yrs service, income 120,000, commitments \c
   20,000, clean CRIB, wants 800,000 over 48 months',
  [ age-32, employment-private_permanent, service_years-5,
    gross_income-120000, existing_commitments-20000, salary_remitted-yes,
    crib-clean, amount-800000, period_months-48 ],
  approve, low).

test_case(tc2, expert,
  'Age 26, contract with 8 months left, income 45,000, no commitments, \c
   clean CRIB, wants 500,000 over 36 months',
  [ age-26, employment-contract, contract_months_remaining-8,
    contract_type-local, service_years-1, gross_income-45000,
    existing_commitments-0, salary_remitted-yes, crib-clean,
    amount-500000, period_months-36 ],
  reject, not_applicable).

test_case(tc3, expert,
  'Age 45, self employed 6 yrs, income 200,000, commitments 50,000, one \c
   late payment, wants 2,000,000 over 60 months',
  [ age-45, employment-self_employed, service_years-6,
    gross_income-200000, existing_commitments-50000, crib-late_1,
    amount-2000000, period_months-60 ],
  approve_with_conditions, high).

test_case(tc4, expert,
  'Age 38, permanent private, 10 yrs service, income 90,000, commitments \c
   45,000, clean CRIB, wants 1,000,000 over 60 months',
  [ age-38, employment-private_permanent, service_years-10,
    gross_income-90000, existing_commitments-45000, salary_remitted-yes,
    crib-clean, amount-1000000, period_months-60 ],
  reject, not_applicable).

test_case(tc5, system,
  'Pensioner aged 62 wanting 500,000 over 120 months, tests the age 75 \c
   concession for pensioners',
  [ age-62, employment-pensioner, service_years-2, gross_income-60000,
    existing_commitments-0, crib-clean, amount-500000, period_months-120 ],
  approve, low).

test_case(tc6, system,
  'Applicant currently in arrears, tests the CRIB arrears rejection',
  [ age-35, employment-private_permanent, service_years-4,
    gross_income-100000, existing_commitments-10000, salary_remitted-yes,
    crib-arrears, amount-500000, period_months-48 ],
  reject, not_applicable).

test_case(tc7, system,
  'Applicant on probation, tests the accepted with conditions rule',
  [ age-28, employment-probation, service_years-0, gross_income-80000,
    existing_commitments-0, salary_remitted-yes, crib-clean,
    amount-400000, period_months-36 ],
  approve_with_conditions, medium).

test_case(tc8, system,
  'CRIB shows a write off, tests the legal action rejection trigger',
  [ age-40, employment-government_permanent, service_years-12,
    gross_income-150000, existing_commitments-0, salary_remitted-yes,
    crib-writeoff_legal, amount-600000, period_months-48 ],
  reject, not_applicable).

test_case(tc9, system,
  'Foreign renewable contract with only 6 months to run, tests the foreign \c
   contract exemption',
  [ age-30, employment-contract, contract_months_remaining-6,
    contract_type-foreign_renewable, service_years-3, gross_income-150000,
    existing_commitments-0, salary_remitted-yes, crib-clean,
    amount-1000000, period_months-60 ],
  approve, medium).

test_case(tc10, system,
  'Unsettled past default on a small loan, tests the NSB position that an \c
   unsettled default is not an automatic rejection',
  [ age-40, employment-private_permanent, service_years-8,
    gross_income-100000, existing_commitments-5000, salary_remitted-yes,
    crib-default_unsettled, amount-500000, period_months-48 ],
  approve, medium).

test_case(tc11, system,
  'Request above the 20 million product ceiling',
  [ age-40, employment-private_permanent, service_years-8,
    gross_income-3000000, existing_commitments-0, salary_remitted-yes,
    crib-clean, amount-25000000, period_months-120 ],
  reject, not_applicable).

test_case(tc12, system,
  'Salaried applicant who does not remit salary to NSB',
  [ age-33, employment-private_permanent, service_years-6,
    gross_income-200000, existing_commitments-0, salary_remitted-no,
    crib-clean, amount-800000, period_months-48 ],
  reject, not_applicable).

test_case(tc13, system,
  'Brand new business with no trading history but an evaluated and \c
   approved business proposal, tests that NSB applies no minimum years in \c
   business requirement',
  [ age-34, employment-self_employed, service_years-0,
    business_proposal_approved-yes, gross_income-120000,
    existing_commitments-0, crib-clean, amount-800000, period_months-48 ],
  approve_with_conditions, high).

test_case(tc14, system,
  'Brand new business whose proposal has not yet been evaluated, tests \c
   that the proposal evaluation is the actual gate for a start up',
  [ age-34, employment-self_employed, service_years-0,
    business_proposal_approved-no, gross_income-120000,
    existing_commitments-0, crib-clean, amount-800000, period_months-48 ],
  reject, not_applicable).

test_case(tc15, system,
  'Income of Rs. 35,000, comfortably above the Rs. 30,000 minimum',
  [ age-35, employment-private_permanent, service_years-6,
    gross_income-35000, existing_commitments-0, salary_remitted-yes,
    crib-clean, amount-300000, period_months-48 ],
  approve, low).

test_case(tc16, system,
  'Income of Rs. 25,000, below the Rs. 30,000 minimum',
  [ age-35, employment-private_permanent, service_years-6,
    gross_income-25000, existing_commitments-0, salary_remitted-yes,
    crib-clean, amount-200000, period_months-48 ],
  reject, not_applicable).

% ---------------------------------------------------------------------------
% RUNNING THE TESTS
% ---------------------------------------------------------------------------

load_case(Facts) :-
    clear_facts,
    forall(member(Attribute-Value, Facts), set_fact(Attribute, Value)).

run_case(Id, Decision, Grade) :-
    test_case(Id, _, _, Facts, _, _),
    load_case(Facts),
    forward_chain,
    ( conclusion(decision, Decision) -> true ; Decision = none ),
    final_grade(Grade).

run_tests :-
    nl,
    writeln('==============  TEST RESULTS  ================================='),
    forall(test_case(Id, _, _, _, _, _), run_and_report(Id)),
    summarise_tests,
    nl,
    writeln('  The facts of the last test case remain in working memory,'),
    writeln('  so menu options 2, 3 and 6 can be used to inspect it.'),
    writeln('===============================================================').

run_and_report(Id) :-
    test_case(Id, Origin, Description, _, ExpectedDecision, ExpectedGrade),
    run_case(Id, ActualDecision, ActualGrade),
    (   ActualDecision == ExpectedDecision,
        ActualGrade == ExpectedGrade
    ->  Verdict = 'PASS'
    ;   Verdict = 'FAIL'
    ),
    origin_label(Origin, OriginLabel),
    nl,
    upcase_atom(Id, Upper),
    format('  ~w  [~w]  ~w~n', [Verdict, Upper, OriginLabel]),
    format('        ~w~n', [Description]),
    format('        expected: ~w / ~w~n', [ExpectedDecision, ExpectedGrade]),
    format('        actual  : ~w / ~w~n', [ActualDecision, ActualGrade]),
    fired_rules(Fired),
    format('        rules fired: ~w~n', [Fired]).

origin_label(expert, 'expert verified, Interview Part 4').
origin_label(system, 'system verification').

summarise_tests :-
    aggregate_all(count, test_case(_, _, _, _, _, _), Total),
    aggregate_all(count, failing_case(_), Failed),
    Passed is Total - Failed,
    nl,
    writeln('---------------------------------------------------------------'),
    format('  ~w of ~w test cases passed.~n', [Passed, Total]).

failing_case(Id) :-
    test_case(Id, _, _, _, ExpectedDecision, ExpectedGrade),
    run_case(Id, ActualDecision, ActualGrade),
    \+ ( ActualDecision == ExpectedDecision, ActualGrade == ExpectedGrade ).
