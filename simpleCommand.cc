#include <cstdio>
#include <cstdlib>
#include <sys/types.h>
#include <sys/wait.h>
#include <pwd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <limits.h>
#include <unistd.h>

#include "shell.hh"

using namespace std;

SimpleCommand::SimpleCommand() {
  _argumentsArray = std::vector<std::string *>();
  _numargs = 0;
}

//check for '~'
std::string * SimpleCommand::checkTilde(std::string * argument) {
  char * arg = argument->data();

  if (arg[0] == '~') {
    if (strlen(arg) == 1) {
      return new std::string(getenv("HOME"));
    } else {
      if (arg[1] == '/') {
        char * dir = strdup(getenv("HOME"));
        arg++;
        arg = strcat(dir, arg);
        return new std::string(arg);
      }

      char * args = new char[strlen(arg) + 20];
      char * usr = new char[20];
      char * buff = arg;
      buff++;

      int i = 0;
      while (*buff != '/' && *buff) {
        usr[i++] = *buff;
        buff++;
      }

      usr[i] = '\0';
      args = strdup(getpwnam(usr)->pw_dir);
      if (*buff) {
        strcat(args, buff);
      }
      return new std::string(args);

    }
  }
  return NULL;
}

std::string * SimpleCommand::checkExpan(std::string * argument) {
  
  char * arg = argument->data();

  char * complete = new char[1024];
  int i = 0;
  bool dollar = 0;

  while (*arg) {
    if (dollar == 0) {
      if (*arg == '$' && *(arg + 1) == '{' && strchr(arg, '}')){
        dollar = 1;
        arg += 2;
      } else {
        complete[i++] = *arg;
        arg++;
      }
    } else {

      char * replace = new char[1024];
      char * temp = replace;
      while (*arg != '}') {
        *temp = *arg;
        temp++;
        arg++;
      }
      arg++;
      dollar = 0;
      *temp = '\0';
      char * env = new char[512];
      if (strcmp(replace, "$") == 0) {
        env = to_string(getpid()).data();

      } else if (strcmp(replace, "SHELL") == 0) {
        //printf("SHELL: %s\n", shell);
        //realpath(shell, env);
        env = shell;
      } else {
        env = getenv(replace);
      }
      //printf("env: %s\n", env);

      if (!complete) {
        complete = strdup(env);
      } else {
        strcat(complete, env);
      }
      
      i = i + strlen(env);

    }

  }
  return new std::string(complete);
}


SimpleCommand::~SimpleCommand() {
  // iterate over all the arguments and delete them
  for (auto & arg : _argumentsArray) {
    delete arg;
  }
}

void SimpleCommand::insertArgument( std::string * argument ) {
  // simply add the argument to the vector
  char * arg = argument->data();


  if (strchr(arg, '$') && strchr(arg, '{') && strchr(arg, '}')) {
    argument = checkExpan(argument);
  }


  std::string * tilde = checkTilde(argument);
  if (tilde) {
    argument = tilde;
  }

  _argumentsArray.push_back(argument);
  _numargs++;
}

// Print out the simple command
void SimpleCommand::print() {
  for (auto & arg : _argumentsArray) {
    std::cout << "\"" << *arg << "\" \t";
  }
  // effectively the same as printf("\n\n");
  std::cout << std::endl;
}

std::vector<char *> SimpleCommand::convert() {
  std::vector<char *> charVec(_argumentsArray.size() + 1);
  for (unsigned int i = 0; i < _argumentsArray.size(); i++) {
    charVec[i]= _argumentsArray[i]->data();
  }

  charVec[_argumentsArray.size()] = NULL;

  return charVec;
}


