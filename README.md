example-parser
==============

This is an example parser written in flex and bison

Layout
======

The main method is located in `parser.y` and starts the whole thing. It uses gnu get opts to parser command line switches, and then sets up the input and output files. Then the parser is called on `line 379` which begins looking for the first rule.

The first rule is on `line 85` and defines an entire input set. Lower case indicates a rule, curly brackets is c code to run at the specified point during matching, and upper case is a token.

Each time it needs a new token, yylex is called, and it uses the rules defined in scanner.l to determine what token is next. Since an unknown amount of input had to be stored for this job, I'm doing some string buffer manipulation that is unneccessary for most projects.

Any c code can be run inside the curly brackets, so whatever needs to be done at a given point is possible. 
