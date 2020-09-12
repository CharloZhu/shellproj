#ifndef simplcommand_hh
#define simplecommand_hh

#include <string>
#include <vector>

struct SimpleCommand {

  // Simple command is simply a vector of strings
  std::vector<std::string *> _argumentsArray;
  int _numargs;

  SimpleCommand();
  ~SimpleCommand();
  void insertArgument( std::string * argument );
  void print();
  std::vector<char *> convert();
  std::string * checkExpan(std::string * argument);
  std::string * checkTilde(std::string * argument);
};

#endif
