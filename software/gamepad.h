#ifndef _PACMAN_GAMEPAD_H
#define _PACMAN_GAMEPAD_H

#include <stdint.h>

struct gamepad_packet {
  uint8_t reserved0;
  uint8_t reserved1;
  uint8_t reserved2;
  uint8_t dir_x;
  uint8_t dir_y;
  uint8_t primary;
  uint8_t secondary;
};

typedef uint16_t gamepad_button_t;
#define GAMEPAD_LEFT (((gamepad_button_t)1) << 0)
#define GAMEPAD_RIGHT (((gamepad_button_t)1) << 1)
#define GAMEPAD_UP (((gamepad_button_t)1) << 2)
#define GAMEPAD_DOWN (((gamepad_button_t)1) << 3)
#define GAMEPAD_X (((gamepad_button_t)1) << 4)
#define GAMEPAD_Y (((gamepad_button_t)1) << 5)
#define GAMEPAD_A (((gamepad_button_t)1) << 6)
#define GAMEPAD_B (((gamepad_button_t)1) << 7)
#define GAMEPAD_L (((gamepad_button_t)1) << 8)
#define GAMEPAD_R (((gamepad_button_t)1) << 9)
#define GAMEPAD_SELECT (((gamepad_button_t)1) << 10)
#define GAMEPAD_START (((gamepad_button_t)1) << 11)

#define GAMEPAD_DEFAULT ((gamepad_button_t)0)

typedef enum { GAMEPAD_KEY_DOWN, GAMEPAD_KEY_UP } gamepad_button_event_t;

void gamepad_init();
void gamepad_destroy();
void gamepad_set_listener(void (*listener)(gamepad_button_event_t,
                                           gamepad_button_t));

#endif
