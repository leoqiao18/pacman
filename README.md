# pacman

## Test software
Remember to use `sudo`.
```shell
gcc -o pacman -lusb-1.0 gamepad.c pacman.c
sudo ./pacman
```

## Gamepad USB protocol
- 24 bits: (constant)
  - default: 0x017f7f
- 8 bits: (left/right)
  - default: 0x7f
  - left: 0x00
  - right: 0xff
- 8 bits: (up/down)
  - default: 0x7f
  - up: 0x00
  - down: 0xff
- 8 bits: (X Y A B)
  - bit 7: Y
  - bit 6: B
  - bit 5: A
  - bit 4: X
  - bit 3: 1 (constant)
  - bit 2: 1 (constant)
  - bit 1: 1 (constant)
  - bit 0: 1 (constant)
- 8 bits: (SELECT/START/L/R)
  - bit 7: 0 (constant)
  - bit 6: 0 (constant)
  - bit 5: START
  - bit 4: SELECT
  - bit 3: 0 (constant)
  - bit 2: 0 (constant)
  - bit 1: R
  - bit 0: L
