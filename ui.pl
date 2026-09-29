% ===========================================================================
%  CreditWise Expert System
%  ui.pl  -  USER INTERFACE  (command line)
% ===========================================================================

% ---------------------------------------------------------------------------
% BANNER AND MENU
% ---------------------------------------------------------------------------

banner :-
    nl,
    writeln('==============================================================='),
    writeln('  CreditWise'),
    writeln('  A Prolog Expert System for Personal Loan Eligibility'),
    writeln('  Assessment and Risk Classification'),
    writeln(''),
    writeln('  Knowledge source: Deputy Manager,'),
    writeln('  National Savings Bank, Wadduwa Branch, 28 September 2026.'),
    writeln(''),
    writeln('  G.G.R.M. Jayawardhana (214093E)'),
    writeln('==============================================================='),
    nl.

start :-
    banner,
    menu_loop.

menu_loop :-
    nl,
    writeln('---------------------------- MENU -----------------------------'),
    writeln('  1. Assess a new loan application'),
    writeln('  2. Explain the last decision (forward chaining trail)'),
    writeln('  3. Prove a goal (backward chaining)'),
    writeln('  4. Run the built in test cases'),
    writeln('  5. Show the knowledge base (facts and rules)'),
    writeln('  6. Show the facts currently in working memory'),
    writeln('  0. Exit'),
    writeln('---------------------------------------------------------------'),
    ask_line('Choose an option: ', Choice),
    handle_choice(Choice).

handle_choice("1") :- !, assess,        menu_loop.
handle_choice("2") :- !, show_trail,    menu_loop.
handle_choice("3") :- !, prove_menu,    menu_loop.
handle_choice("4") :- !, run_tests,     menu_loop.
handle_choice("5") :- !, show_kb,       menu_loop.
handle_choice("6") :- !, show_memory,   menu_loop.
handle_choice("0") :- !, nl, writeln('Goodbye.'), nl.
handle_choice(_)   :- writeln('  Please enter a number from the menu.'),
                      menu_loop.

% ---------------------------------------------------------------------------
% INPUT HELPERS
% ---------------------------------------------------------------------------

ask_line(Prompt, Line) :-
    write(Prompt),
    flush_output,
    read_line_to_string(user_input, Raw),
    (   Raw == end_of_file
    ->  Line = "0"
    ;   normalize_space(string(Line), Raw)
    ).

ask_number(Prompt, Value) :-
    ask_line(Prompt, Line),
    (   number_string(Value, Line)
    ->  true
    ;   writeln('  That is not a number. Please try again.'),
        ask_number(Prompt, Value)
    ).

ask_number(Prompt, Min, Max, Value) :-
    ask_number(Prompt, Raw),
    (   Raw >= Min, Raw =< Max
    ->  Value = Raw
    ;   format('  Please enter a value between ~w and ~w.~n', [Min, Max]),
        ask_number(Prompt, Min, Max, Value)
    ).

% ask_choice(+Prompt, +Options, -Value)
%   Options is a list of Label-Value pairs.
ask_choice(Prompt, Options, Value) :-
    nl,
    writeln(Prompt),
    print_options(Options, 1),
    length(Options, N),
    ask_number('  Enter a number: ', 1, N, Index),
    nth1(Index, Options, _Label-Value).

print_options([], _).
print_options([Label-_ | Rest], N) :-
    format('   ~w) ~w~n', [N, Label]),
    Next is N + 1,
    print_options(Rest, Next).

ask_yes_no(Prompt, Value) :-
    ask_choice(Prompt, ['Yes'-yes, 'No'-no], Value).

% ---------------------------------------------------------------------------
% THE CONSULTATION
% ---------------------------------------------------------------------------

assess :-
    clear_facts,
    nl,
    writeln('==============  NEW LOAN APPLICATION  ========================='),
    collect_applicant,
    forward_chain,
    print_decision_report.

collect_applicant :-
    ask_number('  Applicant age (years): ', 15, 90, Age),
    set_fact(age, Age),

    findall(Label-Type,
            ( employment_type(Type), employment_label(Type, Label) ),
            EmploymentOptions),
    ask_choice('  Employment type:', EmploymentOptions, Employment),
    set_fact(employment, Employment),

    collect_employment_detail(Employment),

    ask_number('  Gross monthly income (Rs.): ', 0, 100000000, Income),
    set_fact(gross_income, Income),

    ask_number('  Existing monthly loan instalments (Rs.): ',
               0, 100000000, Commitments),
    set_fact(existing_commitments, Commitments),

    ask_number('  Loan amount requested (Rs.): ', 1, 1000000000, Amount),
    set_fact(amount, Amount),

    ask_number('  Repayment period (months): ', 1, 600, Period),
    set_fact(period_months, Period),

    findall(Label-Status,
            ( crib_status(Status), crib_label(Status, Label) ),
            CribOptions),
    ask_choice('  CRIB credit report finding:', CribOptions, Crib),
    set_fact(crib, Crib).

% Employment specific questions.
collect_employment_detail(contract) :-
    !,
    ask_number('  Months still to run on the contract: ', 0, 600, Months),
    set_fact(contract_months_remaining, Months),
    ask_choice('  Contract type:',
               ['Local contract'-local,
                'Foreign contract, renewable'-foreign_renewable],
               Type),
    set_fact(contract_type, Type),
    ask_number('  Years of service so far: ', 0, 60, Years),
    set_fact(service_years, Years),
    ask_salary_remittance.
collect_employment_detail(self_employed) :-
    !,
    ask_number('  Years the business has been trading (0 if it is new): ',
               0, 60, Years),
    set_fact(service_years, Years),
    % Asked of every self employed applicant, because NSB applies no minimum
    % years in business. A new business qualifies on its proposal alone.
    ask_yes_no('  Has the business proposal been evaluated and approved?',
               Approved),
    set_fact(business_proposal_approved, Approved).
collect_employment_detail(pensioner) :-
    !,
    ask_number('  Years since retirement: ', 0, 60, Years),
    set_fact(service_years, Years).
collect_employment_detail(Employment) :-
    ask_number('  Years of service with the current employer: ', 0, 60, Years),
    set_fact(service_years, Years),
    ( Employment == probation -> true ; true ),
    ask_salary_remittance.

ask_salary_remittance :-
    ask_yes_no('  Is the salary remitted to National Savings Bank?', Remitted),
    set_fact(salary_remitted, Remitted).

% ---------------------------------------------------------------------------
% THE DECISION REPORT
% ---------------------------------------------------------------------------

print_decision_report :-
    nl,
    writeln('==============  ASSESSMENT RESULT  ============================'),
    print_computed_figures,
    nl,
    (   conclusion(decision, Decision)
    ->  decision_label(Decision, DecisionLabel),
        format('  DECISION    : ~w~n', [DecisionLabel])
    ;   writeln('  DECISION    : no conclusion could be reached')
    ),
    final_grade(Grade),
    grade_label(Grade, GradeLabel),
    format('  RISK GRADE  : ~w~n', [GradeLabel]),
    nl,
    print_reasons,
    print_conditions,
    print_requirements,
    writeln('---------------------------------------------------------------'),
    writeln('  Choose menu option 2 for the full reasoning trail,'),
    writeln('  or option 3 to prove a single conclusion step by step.'),
    writeln('===============================================================').

print_computed_figures :-
    (   monthly_instalment(Instalment)
    ->  Rounded is round(Instalment),
        format('  Estimated monthly instalment : Rs. ~D~n', [Rounded])
    ;   true
    ),
    (   dti_percent(Percent)
    ->  format('  Debt to income ratio         : ~2f%  (limit 60%)~n',
               [Percent])
    ;   true
    ),
    (   maturity_age(MaturityAge)
    ->  format('  Age when the loan matures    : ~w~n', [MaturityAge])
    ;   true
    ).

print_reasons :-
    rejection_reasons(Reasons),
    (   Reasons == []
    ->  true
    ;   writeln('  REASONS FOR REJECTION'),
        forall(member(Reason, Reasons),
               ( reason_label(Reason, Label),
                 format('    - ~w~n', [Label]) )),
        nl
    ).

print_conditions :-
    attached_conditions(Conditions),
    (   Conditions == []
    ->  true
    ;   writeln('  CONDITIONS TO BE ATTACHED'),
        forall(member(C, Conditions),
               ( condition_label(C, Label),
                 format('    - ~w~n', [Label]) )),
        nl
    ).

print_requirements :-
    standing_requirements(Requirements),
    (   Requirements == []
    ->  true
    ;   writeln('  STANDING REQUIREMENTS'),
        forall(member(R, Requirements),
               ( requirement_label(R, Label),
                 format('    - ~w~n', [Label]) )),
        nl
    ).

% ---------------------------------------------------------------------------
% LABELS
% ---------------------------------------------------------------------------

decision_label(approve,                  'APPROVE').
decision_label(approve_with_conditions,  'APPROVE WITH CONDITIONS').
decision_label(reject,                   'REJECT').

grade_label(low,            'Low').
grade_label(medium,         'Medium').
grade_label(high,           'High').
grade_label(not_applicable, 'Not applicable (application rejected)').

reason_label(below_minimum_income,
    'Gross monthly income is below the minimum of Rs. 30,000').
reason_label(below_minimum_service,
    'The employment or service period requirement is not met').
reason_label(over_age_limit,
    'The applicant would be over the age limit when the loan matures').
reason_label(under_minimum_age,
    'The applicant is under 18 years of age').
reason_label(debt_ratio_over_limit,
    'Total monthly debt service would exceed 60% of gross income').
reason_label(legal_action_recorded,
    'The CRIB report shows a write off or recorded legal action').
reason_label(currently_in_arrears,
    'The applicant is currently in arrears on an existing facility').
reason_label(salary_not_remitted,
    'The salary is not remitted to National Savings Bank').
reason_label(amount_over_maximum,
    'The amount requested exceeds the Rs. 20 million product ceiling').
reason_label(period_over_maximum,
    'The repayment period exceeds the 144 month product ceiling').

condition_label(shorter_repayment_period,
    'Shorten the repayment period').
condition_label(higher_interest_rate,
    'Apply a higher interest rate').
condition_label(additional_guarantors,
    'Require guarantors in addition to the standard two').

requirement_label(guarantors_two,
    'Two guarantors are required').

% ---------------------------------------------------------------------------
% MENU ACTIONS
% ---------------------------------------------------------------------------

show_trail :-
    (   derived(_, _, _)
    ->  explain_forward
    ;   nl,
        writeln('  No assessment has been run yet. Choose option 1 first.')
    ).

prove_menu :-
    (   \+ af(_, _)
    ->  nl,
        writeln('  No applicant is loaded. Choose option 1 or 4 first.')
    ;   ask_choice('  Which conclusion would you like proved?',
                   [ 'The applicant is eligible'          - eligible,
                     'The decision is APPROVE'            - decision(approve),
                     'The decision is APPROVE WITH CONDITIONS'
                                             - decision(approve_with_conditions),
                     'The decision is REJECT'             - decision(reject),
                     'The risk grade is Low'              - risk(low),
                     'The risk grade is Medium'           - risk(medium),
                     'The risk grade is High'             - risk(high),
                     'The debt to income test is passed'  - dti_eligible ],
                   Goal),
        explain_backward(Goal)
    ).

show_memory :-
    nl,
    writeln('FACTS CURRENTLY IN WORKING MEMORY'),
    writeln('---------------------------------------------------------------'),
    (   af(_, _)
    ->  forall(af(Attribute, Value),
               format('  ~w = ~w~n', [Attribute, Value]))
    ;   writeln('  (empty)')
    ),
    nl.

show_kb :-
    nl,
    writeln('KNOWLEDGE BASE  -  FACTS ACQUIRED FROM THE EXPERT'),
    writeln('---------------------------------------------------------------'),
    forall(threshold(Name, Value),
           ( format('  ~w = ~w~n', [Name, Value]),
             ( threshold_source(Name, Source)
             -> format('      source: ~w~n', [Source]) ; true ) )),
    nl,
    writeln('KNOWLEDGE BASE  -  RULES'),
    writeln('---------------------------------------------------------------'),
    forall(rule(Id, Stratum, Conclusion, Conditions, Description),
           print_rule(Id, Stratum, Conclusion, Conditions, Description)),
    aggregate_all(count, rule(_, _, _, _, _), RuleCount),
    aggregate_all(count, threshold(_, _), FactCount),
    nl,
    format('  Total: ~w facts and ~w rules.~n', [FactCount, RuleCount]),
    nl.

print_rule(Id, Stratum, Conclusion, Conditions, Description) :-
    upcase_atom(Id, Upper),
    nl,
    format('  ~w  (stratum ~w)  ~w~n', [Upper, Stratum, Description]),
    format('      IF   ', []),
    print_conditions_inline(Conditions),
    format('      THEN ~q~n', [Conclusion]),
    ( rule_source(Id, Source) -> format('      SRC  ~w~n', [Source]) ; true ).

print_conditions_inline([]) :- nl.
print_conditions_inline([C]) :- !, format('~q~n', [C]).
print_conditions_inline([C | Rest]) :-
    format('~q~n', [C]),
    format('      AND  ', []),
    print_conditions_inline(Rest).
