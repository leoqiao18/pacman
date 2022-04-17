#include <stdio.h>
#include "gamepad.h"

void gamepad_handler(gamepad_buttons_t buttons) {
  if (buttons & GAMEPAD_LEFT) printf("LEFT\n");
  if (buttons & GAMEPAD_RIGHT) printf("RIGHT\n");
  if (buttons & GAMEPAD_UP) printf("UP\n");
  if (buttons & GAMEPAD_DOWN) printf("DOWN\n");
  if (buttons & GAMEPAD_X) printf("X\n");
  if (buttons & GAMEPAD_Y) printf("Y\n");
  if (buttons & GAMEPAD_A) printf("A\n");
  if (buttons & GAMEPAD_B) printf("B\n");
  if (buttons & GAMEPAD_L) printf("L\n");
  if (buttons & GAMEPAD_R) printf("R\n");
  if (buttons & GAMEPAD_SELECT) printf("SELECT\n");
  if (buttons & GAMEPAD_START) printf("START\n");
}

int main() {
  gamepad_start(gamepad_handler);
  return 1;
}
