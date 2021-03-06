# Thea2 Cookbook

Here are some recipes for doing common tasks in Thea2.

## Querying Ontologies

```
thea testfiles/Hydrology.owl --query select "s(C,D)" where "labelAnnotation_value(Ob,'Topographic Object'),subClassOf(C,Ob),subClassOf(C,D)" --use-labels
```

### Querying plus reasoning

```
thea-jpl testfiles/pets.owl --reasoner pellet --query select "s(C,D)" where "reasoner_ask(subClassOf(C,D))" --use-labels
```


## Manipulating Ontologies

(many of these examples can now be achieved even more easily with the
owl2_popl.pl module)

In most of these examples, there are 3 steps:

* load the ontology using load_axioms/2
* manipulate the ontology in a forall goal or a failure-driven-loop, called assert_axiom/1
* save the ontology using save_axioms/2

Another way to manipulate ontologies is via the OPPL language. See:

* See http://www.cs.man.ac.uk/~iannonel/oppl/documentation.html

One advantage of prolog over OPPL is its expressivity

### Asserting all subclasses are mutually disjoint


```
subClassOf(X,gender),
subClassOf(Y,gender),
X\=Y,
assert_axiom(disjointClasses([X,Y])),
fail.
```



### Replacing simple assertions with complex descriptions

See http://www.cs.man.ac.uk/~iannonel/oppl/documentation.html

This examples requires JPL as the OWLAPI is used (it may be possible
to plug in owllink or prolog reasoners in future).

Prolog has to be started with the correct classpath. The easiest way
to do this is via the thea-jpl wrapper script:

```
thea-jpl --prolog
```

This starts thea with a prolog shell, from which further prolog goals
can be executed (see also `cookbook/countries.pl`):

```
load_axioms('testfiles/country.owl').

% find all (inferred) adjacent countries and make a classAssertion
initialize_reasoner(pellet,Reasoner),
   reasoner_ask(Reasoner,propertyAssertion('http://www.co-ode.org/roberts/country.owl#adjacentTo',C1,C2)),
   retract_axiom(propertyAssertion(C1,'c:adjacentTo',C2)),
   Desc = someValuesFrom('c:hasLandBoundry',intersectionOf('c:LandBoundryFragment',
            hasValue('c:boundaryOf',C2))),
   assert_axiom(classAssertion(Desc,C2)),
   fail.

% then save:
save_axioms('countries2.owl',owl).
```

## Working with other LP systems

### Converting prolog to OWL

A certain subset of pure prolog programs can be converted to OWL and
reasoner over using OWL reasoners. This is currently a two-step
process.

* prolog to SWRL
* SWRL to OWL

For the first step, only binary and unary predicates are
converted. For the second step, certain rule patterns can be
translated to OWL axioms.

```
:- use_module(library('thea2/owl2_io')).
:- use_module(library('thea2/swrl')).

demo :-
   load_axioms('testfiles/dlptest.pro',pl_swrl_owl,[]),
   save_axioms(_,owlpl). % TODO - change to owl once we have rdf writing
```

For example, the following piece of prolog:

```
r(X,Y):-
     s(X,Z),t(Y,Z).
```

is first translated to a SWRL rule and then to an OWL subPropertyOf/2 axiom:

```
subPropertyOf(r, propertyChain([s, inverseOf(t)]))
```

Currently this process is incomplete, more patterns can potentially be
matched. In the future there will also be the option of defining hooks
to deal with n-ary predicates.

For more, see

* http://blipkit.wordpress.com/2009/06/19/translating-between-logic-programs-and-owlswrl/

### Converting OWL to Logic Programs

The DLP subset of OWL2-DL can be translated to logic programs using a
transormation defined by Grosof. See `owl2_to_prolog_dlp.pl`

The resulting programs can be used with Prolog systems that implement
tabling. There are also hooks for answer set programming and disjunctive
datalog systems such as DLV. The same programs can also be used in
inductive logic programming systems such as ProGol. Possibly also
probabilistic systems such as PRISM, but this has yet to be tested.

The following program will convert an OWL ontology suitable for use in
Prolog (see also `cookbook/wine.pl`):

```
:- use_module(library('thea2/owl2_io')).
:- use_module(library('thea2/owl2_to_prolog_dlp')).

demo :-
   load_axioms('testfiles/wine.owl'),
   save_axioms('wine.pl',dlp,
	       [ no_base(_),
		 write_directives(table),
		 write_directives(discontiguous),
		 write_directives(dummy_fact)
	       ]).
```

(You can also use ``bin/thea-owl-to-dlp-yap testfiles/wine.owl > wine.pl``)

Yap and SWI-Prolog need explicit tabling directives (for XSB can you use
``:- table_all.``), which is specified in the options list for
save_axioms/3

Once you have generated the above DLP you can query the ABox using SWI-Prolog:

```
swipl wine.pl
   ?- 'DessertWine'(Wine),locatedIn(Wine,'USRegion'),hasBody(Wine,'Light').
Wine = 'WhitehallLanePrimavera' ? ;
false
```

Prolog DLPs can not have disjunctions in the head of
rules. Disjunctive datalog systems such as DLV can.

The follow will translate an OWL ontology into DLV syntax:

```
:- use_module(library('thea2/owl2_io')).
:- use_module(library('thea2/owl2_to_prolog_dlp')).

demo :-
   load_axioms('testfiles/cell.owlpl'),
   save_axioms('cell.dlv',dlp,
	       [ disjunctive_datalog(true),
		 head_disjunction_symbol(v),
		 no_base(_),
		 suppress_literals(true)
	       ]).
```

(You can also use bin/thea-owl-to-dlv)

DLV uses 'v' as a disjunction symbol rather than ';'

DLV tells us that the above 'cell' ontology has two stable models:

```
dlv cell.dlv

{nuc(n1), chromosome(chr1), cell(c1), cell(c2), n_cell(c1), has_part(c1,chr1), has_part(c1,n1), has_part(n1,chr1), part_of(chr1,c1), part_of(chr1,n1), part_of(n1,c1), n_cell(c2)}
{nuc(n1), chromosome(chr1), cell(c1), cell(c2), n_cell(c1), has_part(c1,chr1), has_part(c1,n1), has_part(n1,chr1), part_of(chr1,c1), part_of(chr1,n1), part_of(n1,c1), e_cell(c2)}
```

This is because of the OWL following axiom:

```
subClassOf(cell,unionOf([e_cell,n_cell])).
```

In the abox we state `cell(c2)` but not the specific subtype.

