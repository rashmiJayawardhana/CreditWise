% ===========================================================================
%  CreditWise Expert System
%  creditwise.pl  -  MAIN LOADER
%
%  A Prolog Based Expert System for Personal Loan Eligibility Assessment
%  and Risk Classification
%
%  Author : G.G.R.M. Jayawardhana (214093E)
%
%  HOW TO RUN
%      swipl creditwise.pl
%      ?- start.
% ===========================================================================

:- set_prolog_flag(verbose, silent).

:- ensure_loaded('kb_facts').
:- ensure_loaded('kb_rules').
:- ensure_loaded('engine').
:- ensure_loaded('tests').
:- ensure_loaded('ui').

:- initialization(greet).

greet :-
    nl,
    writeln('CreditWise loaded.  Type   start.   to begin.'),
    nl.
