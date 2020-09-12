
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 * NOTICE: This lab is property of Purdue University. You should not for any reason make this code public.
 */

%code requires 
{
#include <string>
#include <unistd.h>

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NOTOKEN GREAT NEWLINE GREATGREAT AMPERSAND LESS TWOGREAT PIPE GREATAMPERSAND GREATGREATAMPERSAND

%{
//#define yylex yylex
#include <cstdio>
#include <cstring>
#include <string>
#include <string.h>
#include <stdlib.h>
#include <dirent.h>
#include <regex.h>
#include <algorithm>
#include <vector>
#include "shell.hh"

#define MAXFILENAME 1024

std::vector<std::string *> array;
int entries;

void expandWildcardIfNecessary(char * arg);
void expandWildcard(char * prefix, char * suffix);
void yyerror(const char * s);
int yylex();

using namespace std;

%}

%%

goal:
  commands
  ;

argument_list:
  argument_list argument 
  | /* can be empty */
  ;

command_and_args:
  command_word argument_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currSimpleCommand );
  }
  ;

pipe_list:
  pipe_list PIPE command_and_args
  | command_and_args
  ;

io_modifier:
   GREATGREAT output {
     Shell::_currentCommand._append = true;
     /* >> the command appends stdout to  the specified file */
   }
  | GREAT output /* > */
  | TWOGREAT WORD {
    //printf("   Yacc: insert error \"%s\"\n", $2->c_str());
    Shell::_currentCommand._errFileName = new std::string($2->c_str());
    Shell::_currentCommand._errcount++;
    /* 2> the command redirects stderr to the specified file */
  }
  | GREATGREATAMPERSAND WORD {
    //printf("   Yacc: insert input and error \"%s\"\n", $2->c_str());
    Shell::_currentCommand._errFileName = new std::string($2->c_str());
    Shell::_currentCommand._outFileName = new std::string($2->c_str());
    Shell::_currentCommand._outcount++;
    Shell::_currentCommand._errcount++;
    Shell::_currentCommand._append = true;
    Shell::_currentCommand._backgnd = true;
    /*>>& the command appends both stdout and stderr to  the specified file */
  } 
  | GREATAMPERSAND WORD {
    //printf("   Yacc: insert input and error \"%s\"\n", $2->c_str());
    
    Shell::_currentCommand._errFileName = new std::string($2->c_str());
    Shell::_currentCommand._outFileName = new std::string($2->c_str());
    Shell::_currentCommand._outcount++;
    Shell::_currentCommand._errcount++;
    Shell::_currentCommand._backgnd = true;
    /* >& the command redirects both stdout and stderr to  the specified file */
  }  
  | LESS WORD {
    //printf("   Yacc: insert input \"%s\"\n", $2->c_str());
    Shell::_currentCommand._inFileName = new std::string($2->c_str());
    Shell::_currentCommand._incount++;
    /* < */
  }
  ;

io_modifier_list:
  io_modifier_list io_modifier
  | /*empty*/
  ;

background_opt:
  AMPERSAND {
    Shell::_currentCommand._backgnd = true;
  }
  | /*empty*/
  ;

command:	
  pipe_list io_modifier_list background_opt NEWLINE {
    //printf("   Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE { 
    if (isatty(0)) {
      Shell::prompt();
    } 
  }
  | error NEWLINE { yyerrok; }
  ;

commands:
  command
  | commands command
  ; /* command loop */


argument:
  WORD {
    //printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    if (strchr($1->c_str(), '?') && !strcmp((Command::_currSimpleCommand->convert())[0], "echo")) {
      Command::_currSimpleCommand->insertArgument($1);
    } else if (strchr($1->c_str(), '*') || strchr($1->c_str(), '?')) {
      // printf("Got * or ? in %s\n", strdup($1->c_str()));
      expandWildcardIfNecessary($1->data());
    } else {
      Command::_currSimpleCommand->insertArgument($1);
    }
    
  }
  ;

command_word:
  WORD {
    //printf("   Yacc: insert command \"%s\"\n", $1->c_str());
    Command::_currSimpleCommand = new SimpleCommand();
    Command::_currSimpleCommand->insertArgument( $1 );
  }
  ;

output:
  WORD {
    //printf("   Yacc: insert output \"%s\"\n", $1->c_str());
    Shell::_currentCommand._outFileName = new std::string($1->c_str());
    Shell::_currentCommand._outcount++;
  }
  ;

%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

void expandWildcardIfNecessary(char * arg) {
  entries = 0;
  array = std::vector<std::string *>();

  if (*arg == '/') {
    expandWildcard("", arg);
  } else {
    expandWildcard(NULL, arg);
  }
  
  sort(array.begin(), array.end(), [](std::string * a, std::string * b) {
    return *a < *b;
  });
  
  for (int i = 0; i < entries; i++) {
    Command::_currSimpleCommand->insertArgument(array[i]);
  }

  entries = 0;
  array.clear();
}

void expandWildcard(char * prefix, char * suffix) {
  
  if (suffix[0] == 0) {
    // when suffix is empty, put prefix in the argument
    array.push_back(new std::string(prefix));
    entries++;
    return;
  }

  //Obtain the next component in the suffix
  //Also advance suffix
  char component[MAXFILENAME];
  char * s = strchr(suffix, '/');
  
  if (s) {
    strncpy(component, suffix, s - suffix);
    component[strlen(suffix) - strlen(s)] = '\0';
    suffix  = s + 1;
  } else {
    strcpy(component, suffix);
    suffix += strlen(suffix);
  }
  //printf("component: %s\nprefix: %s\nsuffix: %s\n\n", component, prefix, suffix);

  // Expanding the component
  char newPrefix[MAXFILENAME];

  if (!strchr(component, '*') &&  !strchr(component, '?')) {
    // Component does not have wildcards
    if (!prefix && component[0]) {
      sprintf(newPrefix, "%s", component);
    } else if (component[0]) {
      sprintf(newPrefix, "%s/%s", prefix, component);
    }

    if (component[0]) {
      expandWildcard(newPrefix, suffix);
    } else {
      expandWildcard("", suffix);
    }
    return;
  }

  //1. Convert wildcard to regular expression
  // "*" -> ".*"
  // "?" -> "."
  // "." - > "\."
  // Add ^ at the beginning and $ at the end to match
  // the beginning and the end of the word
  // Allocate enough space for regular expression

  char * reg = (char *) malloc(2 * strlen(component) + 10);
  char * a = component;
  char * r = reg;
  *r = '^';
  r++;  //match the beginning of the line.

  while (*a) {
    if (*a == '*') {
      *r = '.';
      r++;
      *r = '*';
      r++;
    } else if (*a == '?') {
      *r = '.';
      r++;
    } else if (*a == '.') {
      *r = '\\';
      r++;
      *r = '.';
      r++;
    } else {
      *r = *a;
      r++;
    }
    a++;
  }
  *r = '$';
  r++;
  *r = '\0';
  //printf("regex: %s\n", reg);

  // 2. compile regular expression
  regex_t expbuf;
  
  if (regcomp(&expbuf, reg, REG_EXTENDED | REG_NOSUB)) {
    perror("compile\n");
    regfree(&expbuf);
    return;
  }
  free(reg);

  char * d = (char *) malloc(10 * sizeof(char));

  // if prefix is empty then list current directory
  if (!prefix) {
    *d = '.';
    *(d + 1) = '\0';
  } else if (strlen(prefix) == 0) {
    *d = '/';
    *(d + 1) = '\0';
  } else {
    strcpy(d, prefix);
  }

  // 3. List directory and add as arguments the entries
  // that match the regular expression

  DIR * dir = opendir(d);
  if (dir == NULL) {
    //perror("opendir\n");
    regfree(&expbuf);
    free(d);
    return;
  }
  free(d);

  struct dirent * ent;
  regmatch_t match;
  while ((ent = readdir(dir)) != NULL) {
    
    //Check if name matches
    if (!regexec(&expbuf, ent->d_name, 1, &match, 0)) {
      //printf("dir: %s\n", ent->d_name);
      if (ent->d_name[0] == '.') {
        if (component[0] == '.') {
          if (!prefix) {
            sprintf(newPrefix, "%s", ent->d_name);
          } else {
            sprintf(newPrefix, "%s/%s", prefix, ent->d_name);
          }
          expandWildcard(newPrefix, suffix);          
        } 
      } else {
        if (!prefix) {
          sprintf(newPrefix, "%s", ent->d_name);
        } else {
          sprintf(newPrefix, "%s/%s", prefix, ent->d_name);
        }
        expandWildcard(newPrefix, suffix);
      }   

      // Add argument
    }
  } 

  closedir(dir);
  regfree(&expbuf);

  return;
}// expandwildcard

#if 0
main()
{
  yyparse();
}
#endif
