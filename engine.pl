% ===========================================================================
%  CreditWise Expert System
%  engine.pl  -  INFERENCE ENGINE and EXPLANATION FACILITY
%
%  Two independent inference mechanisms run over the same rule base:
%
%  1. FORWARD CHAINING (data driven)
%     Starts from the facts in working memory and repeatedly fires every
%     rule whose conditions are satisfied, asserting each new conclusion,
%     until no further conclusion can be added (a fixpoint). Used to reach
%     the recommendation and to build the reasoning trail.
%
%  2. BACKWARD CHAINING (goal driven)
%     A meta interpreter that takes a goal such as decision(approve) and
%     works backwards, proving each condition of each candidate rule, until
%     it reaches facts in working memory. Used to answer "why" and to prove
%     one specific conclusion without deriving everything else.
% ===========================================================================

:- dynamic derived/3.        % derived(Fact, RuleId, Sequence)
:- dynamic derive_counter/1.

derive_counter(0).

% ===========================================================================
% PART 1  -  FORWARD CHAINING ENGINE
% ===========================================================================

% forward_chain/0
% Clears any previous run, then saturates each stratum in order.
% Stratification guarantees that a rule using absent/1 is only evaluated
% after every fact it could negate has already been derived.
forward_chain :-
    retractall(derived(_, _, _)),
    retractall(derive_counter(_)),
    assertz(derive_counter(0)),
    forall(between(1, 4, Stratum), saturate(Stratum)).

% saturate(+Stratum)
% Fires rules of this stratum until nothing new can be derived.
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

% holds_all(+Conditions)
holds_all([]).
holds_all([Condition | Rest]) :-
    holds(Condition),
    holds_all(Rest).

% holds(+Condition)
% absent/1 is negation as failure. It is safe here only because the rule
% base is stratified.
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

% final_grade(-Grade)
% The expert left the risk grade blank for both rejected cases in Part 4 of
% the interview, so a rejected application reports no grade.
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

% prove(+Goal, -Proof)
% Proof is a tree:
%     fact(Goal)                 a primitive satisfied from working memory
%     node(Goal, RuleId, Subs)   Goal proved by RuleId from Subs
%     negation(Goal)             absent(Goal) held because Goal is unprovable

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

% can_prove(+Goal)  -  succeeds at most once
can_prove(Goal) :-
    prove(Goal, _),
    !.

% ===========================================================================
% PART 3  -  EXPLANATION FACILITY
% ===========================================================================

% explain_forward/0
% Prints the reasoning trail produced by the last forward chaining run, in
% the order the conclusions were actually derived.
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

% explain_backward(+Goal)
% Prints a proof tree for one goal, showing how it follows from the facts.
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

% why(+Conclusion)
% Convenience wrapper used by the menu.
why(Conclusion) :-
    explain_backward(Conclusion).
