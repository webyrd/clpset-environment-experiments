# clpset-environment-experiments

Experiments using set constraints, also known as CLP(Set), to
represent environments in relational interpreters and other relational
programs that operate on other programs.

`relational-interp/quines-interp.scm` contains a simple relational
interpreter that uses CLP(Set) constraints to encode the environment.
The interpreter is capable of generating quines and twines, even
though the `clpsmt-miniKanren` version of miniKanren it uses doesn't
support `absento` constraints.

`lib/clpsmt-miniKanren` is Nada Amin's implementation of Dovier et
al.'s set constraints, taken from
https://github.com/namin/clpset-miniKanren

`lib/alternative-run-interface` is Will Byrd's `run-unique` and
`run-unique*` macros, which return only unique reified answers.  These
alternatives to the standard `run` and `run*` miniKanren interfaces
are useful because clpset often produces duplicate answers (when the
same set can be constructed in multiple ways).

All code tested with Chez Scheme 10.0.0.

Thank you to Michael Ballantyne for encouragement to try the CLP(Set)
representation of environments.  Thank you to Nada Amin for the
CLP(Set) code, and to Nada and to Raffi Sanna for discussions and work
on an improved version of the CLP(Set) code, to be based on
faster-miniKanren.