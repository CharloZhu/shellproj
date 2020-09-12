#ifndef shell_hh
#define shell_hh

#include "command.hh"

extern char * shell;
extern int status;

struct Shell {

  static void prompt();
  static Command _currentCommand;
  static bool srccmd;
};

#endif
