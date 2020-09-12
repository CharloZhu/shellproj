
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 * NOTICE: This lab is property of Purdue University. You should not for any reason make this code public.
 */


%{

#include <cstring>
#include <string.h>
#include <stdlib.h>

#include "shell.hh"
#include "y.tab.hh"

extern "C" char * read_line();

int mygetc(FILE * f) {
  static char *p;
  char ch;

  if (!isatty(0)) {
  /* stdin is not a tty. Call real getc */
    return getc(f);
  }

  /* stdin is a tty. Call our read_line. */
  if (p==NULL || *p == 0) {
    char * s = read_line();
    p = s;
  }

  ch = *p;
  p++;

  return ch;
}

#undef getc
#define getc(f) mygetc(f)

#define MAX_INCLUDE_DEPTH 10
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int stack_ptr = 0;

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

extern "C" char * read_line();

%}

%option noyywrap

%%

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

"<" {
  return LESS;
}

"2>" {
  return TWOGREAT;
}

">>" {
  return GREATGREAT;
}

"|" {
  return PIPE;
}

"&" {
  return AMPERSAND;
}

">>&" {
  return GREATGREATAMPERSAND;
}

">&" {
  return GREATAMPERSAND;
}



\"[^\n\"]*\" {
  /* quotes */

  char * text = strdup(yytext + 1);
  text[strlen(yytext) - 2] = '\0';
  yylval.cpp_string = new std::string(text);
  return WORD;
}

[^ \t\n|><&]*\\[^ \t\n]* {
  /* escaping */
  char * buff = new char[100];
  char * text = yytext;
  int i = 0;

  if (strlen(yytext) > 1) {
    while (*text) {
      if (*text == '\\') {
        if (*(text + 1) == '\\') {
          text += 2;
          buff[i++] = '\\';

        } else {
          buff[i] = *(++text);
          i++;

        }
        
      } else {
        buff[i] = *text;
        i++;
      }
      text++;

    }
    buff[i] = '\0';
  } else {
    buff = strdup(yytext);
    buff[1] = '\0';
  }

 
  //printf("buff=%s\n", buff);
  yylval.cpp_string = new std::string(buff);
  return WORD;
}



\$\([^\n]*\) {
  /* Subshell Generation */
  char * command = yytext;
  strncpy(command, yytext + 2, strlen(yytext) - 3);
  command[strlen(yytext) - 3] = '\0';

  /* io redirection */
  int tmpin = dup(0); 
  int tmpout = dup (1);

  /* parent pipes for reading and writing */
  int pipein[2];
  int pipeout[2];

  pipe(pipein);
  pipe(pipeout);

  /* writing command into the subshell */
  write(pipein[1], command, strlen(command)); //writing the command line
  write(pipein[1], "\n", 1);                  //add new line
  write(pipein[1], "exit\n", 5);                //exit the subshell
  close(pipein[1]);

  dup2(pipein[0], 0);
  dup2(pipeout[1], 1);

  close(pipein[0]);
  close(pipeout[1]);

  /* forking the process */
  int ret = fork();

  if (ret == 0) {
    /* executing the process from /proc/self/exe */
    execvp("/proc/self/exe", NULL);
    _exit(1);
  } else if (ret < 0) {
    perror("fork\n");
    exit(1);
  }

  /* restoring io default */
  dup2(tmpin, 0);
  dup2(tmpout, 1);
  close(tmpin);
  close(tmpout);

  /* reding from the subshell output */
  char curr;
  char * buff = new char[1024];

  int i = 0;

  while (read(pipeout[0], &curr, 1)) {
    if (curr == '\n') {
      buff[i++] = ' ';
    } else {
      buff[i++] = curr;
    }
  }

  buff[i] = '\0'; //null terminator
  close(pipeout[0]);

  for (int j = i - 1; j >= 0; j--) {
    myunputc(buff[j]);
  }

}

[^ \t\n|><&]+  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}

 {
   return NOTOKEN;
}
