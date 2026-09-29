% ===========================================================================
%  CreditWise Expert System
%  engine.pl  -  INFERENCE ENGINE and EXPLANATION FACILITY
%
%  Holds no banking knowledge. Runs the rule base in kb_rules.pl.
% ===========================================================================

:- dynamic derived/3.        % derived(Fact, RuleId, Sequence)
:- dynamic derive_counter/1.

derive_counter(0).

% ===========================================================================
% PART 1  -  FORWARD CHAINING ENGINE
% ===========================================================================

% Saturating one stratum at a time is what keeps absent/1 sound.
forward_chain :-
    retractall(derived(_, _, _)),
    retractall(derive_counter(_)),
    assertz(derive_counter(0)),
    forall(between(1, 4, Stratum), saturate(Stratum)).

saturate(Stratum) :-
    (   rule(Id, Stratum, Conclusion, Conditions, _Description),
        holds_all(Conditions),
        \+ derived(Conclusion, _, _)
    ->  next_sequence(Seq),
        assertz(derived(Conclusion, Id, Seq)),
        saturate(Stratum)
    ;   true
    ).

next_sequence(Seq) :-
    retract(derive_counter(N)),
    Seq is N + 1,
    assertz(derive_counter(Seq)).

holds_all([]).
holds_all([Condition | Rest]) :-
    holds(Condition),
    holds_all(Rest).

holds(absent(Goal)) :-
    !,
    \+ holds(Goal).
holds(Goal) :-
    primitive(Goal),
    !,
    call(Goal).
holds(Goal) :-
    derived(Goal, _, _).

% ---------------------------------------------------------------------------
% Reading the result of a forward chaining run
% ---------------------------------------------------------------------------

conclusion(decision, Decision) :-
    derived(decision(Decision), _, _).

conclusion(risk, Grade) :-
    ( derived(risk(Grade), _, _) -> true ; Grade = not_applicable ).

% The expert left the grade blank for both rejected cases in Part 4.
final_grade(Grade) :-
    (   derived(decision(reject), _, _)
    ->  Grade = not_applicable
    ;   conclusion(risk, Grade)
    ).

rejection_reasons(Reasons) :-
    findall(Reason, derived(rejected(Reason), _, _), Reasons).

attached_conditions(Conditions) :-
    findall(C, derived(condition(C), _, _), Conditions).

standing_requirements(Requirements) :-
    findall(R, derived(requirement(R), _, _), Requirements).

fired_rules(Ids) :-
    findall(Seq-Id, derived(_, Id, Seq), Pairs),
    keysort(Pairs, Sorted),
    findall(Id, member(_-Id, Sorted), Ids).

% ===========================================================================
% PART 2  -  BACKWARD CHAINING META INTERPRETER
% ===========================================================================

% prove(+Goal, -Proof), where Proof is a tree of
%     fact(Goal) | node(Goal, RuleId, SubProofs) | negation(Goal)

prove(absent(Goal), negation(Goal)) :-
    !,
    \+ prove(Goal, _).
prove(Goal, fact(Goal)) :-
    primitive(Goal),
    !,
    call(Goal).
prove(Goal, node(Goal, RuleId, SubProofs)) :-
    rule(RuleId, _Stratum, Goal, Conditions, _Description),
    prove_all(Conditions, SubProofs).

prove_all([], []).
prove_all([Condition | Rest], [Proof | Proofs]) :-
    prove(Condition, Proof),
    prove_all(Rest, Proofs).

can_prove(Goal) :-
    prove(Goal, _),
    !.

% ===========================================================================
% PART 3  -  EXPLANATION FACILITY
% ===========================================================================

% Replays the last run in the order the conclusions were derived.
explain_forward :-
    nl,
    writeln('REASONING TRAIL  (forward chaining, in derivation order)'),
    writeln('---------------------------------------------------------------'),
    findall(Seq-fact(Fact, Id), derived(Fact, Id, Seq), Pairs),
    keysort(Pairs, Sorted),
    forall(member(_-fact(Fact, Id), Sorted), explain_step(Fact, Id)),
    nl.

explain_step(Fact, Id) :-
    ( rule(Id, _, _, _, Description) -> true ; Description = '(no description)' ),
    upcase_atom(Id, Upper),
    format('  ~w  ~w~n', [Upper, Description]),
    format('        derived: ~q~n', [Fact]),
    (   rule_source(Id, Source)
    ->  format('        source : ~w~n', [Source])
    ;   true
    ),
    nl.

explain_backward(Goal) :-
    nl,
    format('PROOF OF ~q  (backward chaining)~n', [Goal]),
    writeln('---------------------------------------------------------------'),
    (   prove(Goal, Proof)
    ->  print_proof(Proof, 2)
    ;   writeln('  This goal cannot be proved from the current facts.')
    ),
    nl.

print_proof(fact(Goal), Indent) :-
    tab(Indent),
    format('fact: ~q~n', [Goal]).
print_proof(negation(Goal), Indent) :-
    tab(Indent),
    format('not provable (so the condition holds): ~q~n', [Goal]).
print_proof(node(Goal, RuleId, Subs), Indent) :-
    tab(Indent),
    upcase_atom(RuleId, Upper),
    format('~q  <-  by ~w~n', [Goal, Upper]),
    (   rule(RuleId, _, _, _, Description)
    ->  Inner is Indent + 4,
        tab(Inner),
        format('% ~w~n', [Description])
    ;   true
    ),
    Next is Indent + 4,
    forall(member(Sub, Subs), print_proof(Sub, Next)).

why(Conclusion) :-
    explain_backward(Conclusion).

% ===========================================================================
% PART 4  -  NATIVE PROLOG CLAUSES
%
%  A rule/5 term is strictly a fact. This compiles the same terms into
%  ordinary clauses, so the knowledge can also be run by SWI-Prolog's own
%  resolution. Load an applicant first, then:
%
%      ?- test_case(tc1, _, _, Facts, _, _), load_case(Facts).
%      ?- eligible.
%      ?- decision(D).
% ===========================================================================

:- dynamic native_rules_compiled/0.

conditions_to_body([], true).
conditions_to_body([C], Goal) :-
    !,
    condition_goal(C, Goal).
conditions_to_body([C | Rest], (Goal, RestBody)) :-
    condition_goal(C, Goal),
    conditions_to_body(Rest, RestBody).

condition_goal(absent(Goal), \+ Goal) :- !.
condition_goal(Goal, Goal).

% The cut stops this succeeding once per fact, which would multiply
% every solution.
applicant_loaded :-
    af(_, _),
    !.

% To negation as failure an empty working memory looks like a failed test,
% so a rule using absent/1 would answer decision(reject) with no applicant
% present. Those rules are guarded; a positive condition needs no guard.
guarded_body(Conditions, Body) :-
    (   memberchk(absent(_), Conditions)
    ->  conditions_to_body(Conditions, Inner),
        Body = (applicant_loaded, Inner)
    ;   conditions_to_body(Conditions, Body)
    ).

compile_native_rules :-
    (   native_rules_compiled
    ->  true
    ;   forall(rule(_Id, _Stratum, Conclusion, Conditions, _Description),
               (   guarded_body(Conditions, Body),
                   assertz((Conclusion :- Body))
               )),
        assertz(native_rules_compiled)
    ).

show_native_clause(Id) :-
    rule(Id, _, Conclusion, Conditions, _),
    guarded_body(Conditions, Body),
    copy_term(Conclusion-Body, C-B),
    numbervars(C-B, 0, _),
    format('~q :-~n    ~q.~n', [C, B]).

:- initialization(compile_native_rules).
