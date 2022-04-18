#include "gamepad.h"
#include <libusb-1.0/libusb.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---------- Gamepad USB info ---------- */
#define GAMEPAD_ID_VENDOR 0x79
#define GAMEPAD_ID_PRODUCT 0x11

/* Private function declarations */
void *gamepad_worker(void *arg);
void gamepad_generate_events(gamepad_button_t prev, gamepad_button_t next);
void gamepad_set_buttons(gamepad_button_t buttons);
struct libusb_device_handle *gamepad_open(uint8_t *endpoint_address);
gamepad_button_t gamepad_decode_packet(struct gamepad_packet packet);

/* ---------- States ---------- */
typedef struct {
  /* control */
  pthread_mutex_t mu;
  pthread_t tid;
  bool dead;

  /* current button state */
  gamepad_button_t buttons;

  /* usb */
  uint8_t endpoint;
  struct libusb_device_handle *handle;

  /* called by gamepad_worker() */
  void (*listener)(gamepad_button_event_t e, gamepad_button_t bs);
} gamepad_state_t;

static gamepad_state_t gp;

/* ---------- Implementations ---------- */
void gamepad_init() {
  int error;

  pthread_mutex_init(&gp.mu, NULL);
  pthread_mutex_lock(&gp.mu);

  gp.dead = false;
  gp.buttons = GAMEPAD_DEFAULT;

  if ((gp.handle = gamepad_open(&gp.endpoint)) == NULL) {
    fprintf(stderr, "Did not find a gamepad\n");
    exit(1);
  }

  if ((error = pthread_create(&gp.tid, NULL, &gamepad_worker, NULL)) != 0) {
    fprintf(stderr, "Gamepad worker could not be created: %s\n",
            strerror(error));
    exit(1);
  }

  pthread_mutex_unlock(&gp.mu);

  printf("Gamepad initialized\n");
}

void gamepad_destroy() {
  pthread_mutex_lock(&gp.mu);
  gp.dead = true;
  pthread_mutex_unlock(&gp.mu);

  pthread_join(gp.tid, NULL);
  pthread_mutex_destroy(&gp.mu);

  printf("Gamepad destroyed\n");
}

void gamepad_set_listener(void (*listener)(gamepad_button_event_t,
                                           gamepad_button_t)) {
  pthread_mutex_lock(&gp.mu);
  gp.listener = listener;
  pthread_mutex_unlock(&gp.mu);

  printf("Set gamepad listener\n");
}

void *gamepad_worker(void *arg) {
  struct gamepad_packet packet;
  gamepad_button_t buttons;
  int transferred;

  /* Handle button data */
  while (true) {
    pthread_mutex_lock(&gp.mu);

    /* exit worker if dead */
    if (gp.dead) {
      pthread_mutex_unlock(&gp.mu);
      break;
    }

    /* retrieve */
    libusb_interrupt_transfer(gp.handle, gp.endpoint, (unsigned char *)&packet,
                              sizeof(packet), &transferred, 0);
    buttons = gamepad_decode_packet(packet);

    /* process */
    gamepad_generate_events(gp.buttons, buttons);
    gp.buttons = buttons;

    pthread_mutex_unlock(&gp.mu);
  }

  printf("Gamepad worker exited\n");
  return NULL;
}

void gamepad_generate_events(gamepad_button_t prev, gamepad_button_t next) {
  /* no need to generate event if no one cares */
  if (gp.listener == NULL)
    return;

  /* 1. KEY_DOWN */
  if (next & GAMEPAD_LEFT)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_LEFT);
  if (next & GAMEPAD_RIGHT)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_RIGHT);
  if (next & GAMEPAD_UP)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_UP);
  if (next & GAMEPAD_DOWN)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_DOWN);
  if (next & GAMEPAD_X)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_X);
  if (next & GAMEPAD_Y)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_LEFT);
  if (next & GAMEPAD_A)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_A);
  if (next & GAMEPAD_B)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_B);
  if (next & GAMEPAD_L)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_L);
  if (next & GAMEPAD_R)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_R);
  if (next & GAMEPAD_SELECT)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_SELECT);
  if (next & GAMEPAD_START)
    gp.listener(GAMEPAD_KEY_DOWN, GAMEPAD_START);

  /* 2. KEY_UP */
  if (!(next & GAMEPAD_LEFT) && (prev & GAMEPAD_LEFT))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_LEFT);
  if (!(next & GAMEPAD_RIGHT) && (prev & GAMEPAD_RIGHT))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_RIGHT);
  if (!(next & GAMEPAD_UP) && (prev & GAMEPAD_UP))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_UP);
  if (!(next & GAMEPAD_DOWN) && (prev & GAMEPAD_DOWN))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_DOWN);
  if (!(next & GAMEPAD_X) && (prev & GAMEPAD_X))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_X);
  if (!(next & GAMEPAD_Y) && (prev & GAMEPAD_Y))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_LEFT);
  if (!(next & GAMEPAD_A) && (prev & GAMEPAD_A))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_A);
  if (!(next & GAMEPAD_B) && (prev & GAMEPAD_B))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_B);
  if (!(next & GAMEPAD_L) && (prev & GAMEPAD_L))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_L);
  if (!(next & GAMEPAD_R) && (prev & GAMEPAD_R))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_R);
  if (!(next & GAMEPAD_SELECT) && (prev & GAMEPAD_SELECT))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_SELECT);
  if (!(next & GAMEPAD_START) && (prev & GAMEPAD_START))
    gp.listener(GAMEPAD_KEY_UP, GAMEPAD_START);
}

struct libusb_device_handle *gamepad_open(uint8_t *endpoint_address) {
  libusb_device **devs;
  struct libusb_device_handle *handle = NULL;
  struct libusb_device_descriptor desc;
  ssize_t num_devs, d;
  uint8_t i, k;

  /* Start the library */
  if (libusb_init(NULL) < 0) {
    fprintf(stderr, "Error: libusb_init failed\n");
    exit(1);
  }

  /* Enumerate all the attached USB devices */
  if ((num_devs = libusb_get_device_list(NULL, &devs)) < 0) {
    fprintf(stderr, "Error: libusb_get_device_list failed\n");
    exit(1);
  }

  /* Look at each device, remembering the first HID device that speaks
     the keyboard protocol */

  for (d = 0; d < num_devs; d++) {
    libusb_device *dev = devs[d];
    if (libusb_get_device_descriptor(dev, &desc) < 0) {
      fprintf(stderr, "Error: libusb_get_device_descriptor failed\n");
      exit(1);
    }

    if (desc.idVendor == GAMEPAD_ID_VENDOR &&
        desc.idProduct == GAMEPAD_ID_PRODUCT) {
      struct libusb_config_descriptor *config;
      libusb_get_config_descriptor(dev, 0, &config);

      for (i = 0; i < config->bNumInterfaces; i++) {
        for (k = 0; k < config->interface[i].num_altsetting; k++) {
          int r;
          const struct libusb_interface_descriptor *inter =
              config->interface[i].altsetting + k;
          if ((r = libusb_open(dev, &handle)) != 0) {
            fprintf(stderr, "Error: libusb_open failed: %d\n", r);
            exit(1);
          }
          if (libusb_kernel_driver_active(handle, i)) {
            libusb_detach_kernel_driver(handle, i);
          }
          libusb_set_auto_detach_kernel_driver(handle, i);
          if ((r = libusb_claim_interface(handle, i)) != 0) {
            fprintf(stderr, "Error: libusb_claim_interface failed: %d\n", r);
            exit(1);
          }
          *endpoint_address = inter->endpoint[0].bEndpointAddress;
          goto found;
        }
      }
    }
  }

found:
  libusb_free_device_list(devs, 1);

  return handle;
}

gamepad_button_t gamepad_decode_packet(struct gamepad_packet packet) {
  gamepad_button_t buttons = 0;

  if (packet.dir_x == 0x00)
    buttons |= GAMEPAD_LEFT;
  if (packet.dir_x == 0xff)
    buttons |= GAMEPAD_RIGHT;

  if (packet.dir_y == 0x00)
    buttons |= GAMEPAD_UP;
  if (packet.dir_y == 0xff)
    buttons |= GAMEPAD_DOWN;

  if (packet.primary & (1 << 7))
    buttons |= GAMEPAD_Y;
  if (packet.primary & (1 << 6))
    buttons |= GAMEPAD_B;
  if (packet.primary & (1 << 5))
    buttons |= GAMEPAD_A;
  if (packet.primary & (1 << 4))
    buttons |= GAMEPAD_X;

  if (packet.secondary & (1 << 5))
    buttons |= GAMEPAD_START;
  if (packet.secondary & (1 << 4))
    buttons |= GAMEPAD_SELECT;
  if (packet.secondary & (1 << 1))
    buttons |= GAMEPAD_R;
  if (packet.secondary & (1 << 0))
    buttons |= GAMEPAD_L;

  return buttons;
}
