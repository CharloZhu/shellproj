#include <cstdio>
#include <unistd.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/wait.h>
#include <sys/types.h>

#include "shell.hh"

#define YY_BUF_SIZE 32768

#ifndef YY_TYPEDEF_YY_BUFFER_STATE
#define YY_TYPEDEF_YY_BUFFER_STATE
typedef struct yy_buffer_state *YY_BUFFER_STATE;
#endif

int status;
void yypush_buffer_state(YY_BUFFER_STATE buffer);
void yypop_buffer_state();
void yyrestart(FILE * file);
int yyparse(void);
YY_BUFFER_STATE yy_create_buffer(FILE * fp, int size);

bool Shell::srccmd;
char * shell;

using namespace std;

extern "C" void disp( int sig )
{
	//fprintf( stderr, "\nsig:%d      Ouch!\n", sig);
  if (Shell::_currentCommand._simpleCommandsArray.size() == 0) {
    if (isatty(0)) {
      printf("\n");
      Shell::prompt();
    }
  }
}

extern "C" void zombie_handler(int sig) {
  int pid = wait3(0, 0, NULL);
  while (waitpid(-1, NULL, WNOHANG) > 0) {
    //printf("\n[%d] exited.", pid);
  }
}

void Shell::prompt() {
  if (status && getenv("ON_ERROR")) {
    printf("%s\n", getenv("ON_ERROR"));
  }
  if (!srccmd) {
    printf("%s ", getenv("PROMPT"));
    fflush(stdout);    
  }

}

int main(int argc, char ** argv) {

  struct sigaction sa;
  sa.sa_handler = disp;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;

  if(sigaction(SIGINT, &sa, NULL)){
    perror("sigaction");
    exit(-1);
  }

  struct sigaction zombie;
  zombie.sa_handler = zombie_handler;
  sigemptyset(&zombie.sa_mask);
  zombie.sa_flags = SA_RESTART;

  if(sigaction(SIGCHLD, &zombie, NULL)){
    perror("sigaction");
    exit(-1);
  }  

  FILE * fp = fopen(".shellrc", "r");

  if (fp) {

    yypush_buffer_state(yy_create_buffer(fp, YY_BUF_SIZE));
    Shell::srccmd = 1;
    yyparse();
  
    yypop_buffer_state();

    fclose(fp);
    Shell::srccmd = 0;
  } else if (isatty(0)) {

    char path[PATH_MAX];
    realpath(argv[0], path);
    
    shell = strdup(path);

    setenv("PROMPT", "myshell>", 1);
    Shell::srccmd = 0;
    Shell::prompt();
  }
  yyrestart(stdin);
  yyparse();
}

Command Shell::_currentCommand;
