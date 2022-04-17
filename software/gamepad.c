#include <stdlib.h>
#include <stdio.h>
#include <libusb-1.0/libusb.h>
#include "gamepad.h"

struct libusb_device_handle *gamepad_open(uint8_t *endpoint_address) {
  libusb_device **devs;
  struct libusb_device_handle *handle = NULL;
  struct libusb_device_descriptor desc;
  ssize_t num_devs, d;
  uint8_t i, k;
  
  /* Start the library */
  if ( libusb_init(NULL) < 0 ) {
    fprintf(stderr, "Error: libusb_init failed\n");
    exit(1);
  }

  /* Enumerate all the attached USB devices */
  if ( (num_devs = libusb_get_device_list(NULL, &devs)) < 0 ) {
    fprintf(stderr, "Error: libusb_get_device_list failed\n");
    exit(1);
  }

  /* Look at each device, remembering the first HID device that speaks
     the keyboard protocol */

  for (d = 0 ; d < num_devs ; d++) {
    libusb_device *dev = devs[d];
    if ( libusb_get_device_descriptor(dev, &desc) < 0 ) {
      fprintf(stderr, "Error: libusb_get_device_descriptor failed\n");
      exit(1);
    }

    if (desc.idVendor == ID_VENDOR && desc.idProduct == ID_PRODUCT) {
      struct libusb_config_descriptor *config;
      libusb_get_config_descriptor(dev, 0, &config);

      for (i = 0 ; i < config->bNumInterfaces ; i++) {
        for (k = 0 ; k < config->interface[i].num_altsetting ; k++) {
          int r;
	  const struct libusb_interface_descriptor *inter = config->interface[i].altsetting + k;
          if ((r = libusb_open(dev, &handle)) != 0) {
            fprintf(stderr, "Error: libusb_open failed: %d\n", r);
            exit(1);
          }
          if (libusb_kernel_driver_active(handle,i)) {
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

gamepad_buttons_t gamepad_decode_packet(struct gamepad_packet packet) {
  gamepad_buttons_t buttons = 0;

  if (packet.dir_x == 0x00) buttons |= GAMEPAD_LEFT;
  if (packet.dir_x == 0xff) buttons |= GAMEPAD_RIGHT;

  if (packet.dir_y == 0x00) buttons |= GAMEPAD_UP;
  if (packet.dir_y == 0xff) buttons |= GAMEPAD_DOWN;

  if (packet.primary & (1 << 7)) buttons |= GAMEPAD_Y;
  if (packet.primary & (1 << 6)) buttons |= GAMEPAD_B;
  if (packet.primary & (1 << 5)) buttons |= GAMEPAD_A;
  if (packet.primary & (1 << 4)) buttons |= GAMEPAD_X;

  if (packet.secondary & (1 << 5)) buttons |= GAMEPAD_START;
  if (packet.secondary & (1 << 4)) buttons |= GAMEPAD_SELECT;
  if (packet.secondary & (1 << 1)) buttons |= GAMEPAD_R;
  if (packet.secondary & (1 << 0)) buttons |= GAMEPAD_L;

  return buttons;
}

void gamepad_start(void (*handler)(gamepad_buttons_t)) {
  uint8_t endpoint_address;
  struct libusb_device_handle *gamepad;
  struct gamepad_packet packet;
  gamepad_buttons_t buttons;
  int transferred;

  if ((gamepad = gamepad_open(&endpoint_address)) == NULL) {
    fprintf(stderr, "Did not find a gamepad\n");
    exit(1);
  }

  /* Handle button data */
  for (;;) {
    libusb_interrupt_transfer(gamepad, endpoint_address,
                              (unsigned char *)&packet, sizeof(packet),
                              &transferred, 0);
    buttons = gamepad_decode_packet(packet);
    handler(buttons);
  }
}
