# shellproj
A Shell 
Lab 3 Shell Implementation- README
Charlo Zhu, 
zhu761@purdue.edu, 
PUID: 0030751819

The goal of this project is to build a shell interpreter similar to bash and csh under Linux system. 

Part 1: Parsing and Executing Commands (All complete)
-	1A: Accepting complex commands COMPLETE
-	1B.1: Simple command process creation and execution COMPLETE
-	1B.2: File redirection COMPLETE
-	1B.3: Pipes COMPLETE
-	1B.4: isatty() COMPLETE
-	p.s. the tests for redirecting error files sometimes would fail with no specific reason. The interpreter works fine for most of the time.

Part 2: Signal Handling, More Parsing, and Subshells
-	2.1: Ctrl-C COMPLETE
-	2.2: Zombie Elimination COMPLETE
-	2.3: Exit COMPLETE
-	2.4: Quotes COMPLETE
-	2.5 Escaping COMPLETE
-	2.6 Built-in Functions:
	printenv COMPLETE
	setenv A B COMPLETE
	unsetenv A COMPLETE
	source A INCOMPLETE (the source function cannot execute environment variable manipulation correctly)
	cd A COMPLETE
-	2.7: Creating a Default Source File “.shellrc” COMPLETE
-	2.8: Subshells COMPLETE

Part 3: Expansions, Wildcards, and Line Editing
-	3.1: Environment Variable Expansion: Normal environment variables COMPLETE
	${$} COMPLETE
	${?} COMPLETE
	${!} COMPLETE
	${_} COMPLETE
	${SHELL} COMPLETE (but fails the automatic testcase while manually testing runs okay)
-	3.2: Tilde Expansion COMPLETE
-	3.3: Wildcarding COMPLETE
-	3.4: Edit Mode COMPLETE
-	3.5: History COMPLETE
-	3.7: Variable Prompt COMPLETE (both setenv PROMPT and setenv ON_ERROR)
