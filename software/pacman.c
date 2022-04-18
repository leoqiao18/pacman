#include "gamepad.h"
#include <stdio.h>

void listener(gamepad_button_event_t e, gamepad_button_t b) {
  static int count = 0;
  if (e == GAMEPAD_KEY_UP && b == GAMEPAD_A) {
    count++;
    printf("%d\n", count);
  }
}

int main() {
  gamepad_init();
  gamepad_set_listener(&listener);
  while (1)
    ;
  return 1;
}
