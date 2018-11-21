/* cursor test for terminal emulator  */
/*
  NOTE: This escape sequences come from vt100
  So it is very likey that this program doesn't work
  on non vt100 compliant terminal emulator
 */
#include <stdio.h>
#include <unistd.h>
#include <termios.h>

int main(int argc, char *argv[])
{
  int c;
  struct termios tty, tty_back;

  tcgetattr(STDIN_FILENO,&tty);

  tty_back = tty;
  tty.c_lflag &= ~ICANON;
  tty.c_lflag &= ~ECHO;

  tcsetattr(STDIN_FILENO,TCSANOW,&tty);
  
  while(1)
  {
    c = getchar();
    switch(c)
    {
      case 'h':
          printf("[1D");
          break;
      case 'j':
          printf("[1B");
          break;
      case 'k':
          printf("[1A");
          break;
      case 'l':
          printf("[1C");
          break;
      case 'q':
          goto out;
          break;
      default:
              /* do nothing */
          break;
    }
    fflush(stdout);
  }
  out:
  tcsetattr(STDIN_FILENO,TCSANOW,&tty_back);

  printf("[1;1H");
  printf("[2J");
  fflush(stdout);
  return 0;
}
