#ifndef _PACMAN_GAMEPAD_H
#define _PACMAN_GAMEPAD_H

#include <stdint.h>

#define ID_VENDOR 0x79
#define ID_PRODUCT 0x11

struct gamepad_packet {
  uint8_t reserved0;
  uint8_t reserved1;
  uint8_t reserved2;
  uint8_t dir_x;
  uint8_t dir_y;
  uint8_t primary;
  uint8_t secondary;
};

typedef uint16_t gamepad_buttons_t;
#define GAMEPAD_LEFT    (((gamepad_buttons_t) 1) << 0)
#define GAMEPAD_RIGHT   (((gamepad_buttons_t) 1) << 1)
#define GAMEPAD_UP      (((gamepad_buttons_t) 1) << 2)
#define GAMEPAD_DOWN    (((gamepad_buttons_t) 1) << 3)
#define GAMEPAD_X       (((gamepad_buttons_t) 1) << 4)
#define GAMEPAD_Y       (((gamepad_buttons_t) 1) << 5)
#define GAMEPAD_A       (((gamepad_buttons_t) 1) << 6)
#define GAMEPAD_B       (((gamepad_buttons_t) 1) << 7)
#define GAMEPAD_L       (((gamepad_buttons_t) 1) << 8)
#define GAMEPAD_R       (((gamepad_buttons_t) 1) << 9)
#define GAMEPAD_SELECT  (((gamepad_buttons_t) 1) << 10)
#define GAMEPAD_START   (((gamepad_buttons_t) 1) << 11)

void gamepad_start(void (*handler)(gamepad_buttons_t));

#endif
