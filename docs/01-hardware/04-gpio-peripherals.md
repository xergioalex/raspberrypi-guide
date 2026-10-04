# GPIO & peripherals

The 40-pin header, cameras, displays, and the Bookworm-era software stacks that drive them.

> **Applies to:** Pi 3B+/4/5 (40-pin populated header); Zero 2 W (unpopulated)
> **Related:** [Models](01-models.md)

## The 40-pin header

All current full-size Pis share the same 40-pin layout:

- **GPIOxx** — general-purpose pins, numbered by Broadcom (BCM) numbering — always specify BCM numbering in code; physical pin numbers differ.
- 2× **3.3 V**, 2× **5 V**, 8× **GND**, plus fixed-function pins: `GPIO2/3` (I²C SDA/SCL + have onboard pull-ups), `GPIO14/15` (UART TX/RX), and standard SPI/I²C positions.
- **Logic level is 3.3 V, not 5 V.** Feeding 5 V into a GPIO can destroy the pin or the SoC. 3.3 V-tolerant only.
- Max ~16 mA per pin, ~50 mA total across 3.3 V pins by default. Drive relays/motors/LED strips through a transistor, H-bridge, or dedicated driver board — never directly.
- 5 V pins are input-only power taps; they are not GPIO.

Interactive reference on the Pi itself:

```bash
pinout          # from python3-gpiozero; prints the full pin map + board info
pinout -x       # launch the web version (pinout.xyz)
```

[pinout.xyz](https://pinout.xyz) is the canonical visual reference.

## Software: use gpiozero (Python)

On Bookworm, the old C `wiringPi` is dead and `RPi.GPIO` doesn't work on the Pi 5. The supported stack is **gpiozero** (friendly API) over **lgpio** (kernel interface):

```bash
sudo apt install python3-gpiozero python3-lgpio
```

```python
from gpiozero import LED, Button
from signal import pause

led = LED(17)          # BCM numbering
btn = Button(2)        # uses internal pull-up by default

btn.when_pressed = led.on
btn.when_released = led.off
pause()
```

Command-line pin access without Python:

```bash
gpioset gpiochip0 17=1        # set GPIO17 high (libgpiod)
gpioget gpiochip0 2           # read
gpiomon gpiochip0 2           # watch edges
ls /dev/gpiochip*             # Pi 5 exposes gpiochip0 (header) and gpiochip4
```

## Camera (Bookworm = libcamera / rpicam-apps)

The legacy MMAL stack is gone. Use `rpicam-*` tools:

```bash
rpicam-hello --list-cameras          # detect cameras
rpicam-still -o test.jpg             # still photo
rpicam-vid -t 10000 -o clip.h264     # 10 s video
rpicam-hello --tune-file low-light   # low-light tuning
```

- Camera modules v1/v2/v3 and the HQ camera are supported; v3 needs `libcamera`-aware software only.
- **Pi 5**: MIPI connectors are 22-pin; older 15-pin camera cables need the official adapter cable. Two cameras can run simultaneously.
- In Python use `picamera2` (`sudo apt install python3-picamera2`) — it's the Bookworm-native API.

## Displays

- Official 7" Touchscreen: works out of the box over DSI; on Pi 5 it needs the firmware workaround (see raspberrypi/documentation) or use the DSI/CSI adapter cable.
- Any HDMI monitor works; for small SPI/HDMI hat displays (Waveshare etc.) follow the vendor script — they usually install a fake framebuffer or Wayland overlay.
- Desktop rotation (Wayland on Bookworm): `wlr-randr` or Screen Configuration GUI; `display_rotate` in `config.txt` is the legacy/firmware-KMS path.

## Serial (UART), I²C, SPI, 1-Wire

Enable interfaces via `sudo raspi-config` → Interfacing Options (or `raspi-config nonint do_i2c 0`, `do_spi 0`, `do_serial 0` — `0` means *enable*). Verify:

```bash
ls /dev/i2c-* /dev/spidev* /dev/serial*
i2cdetect -y 1            # scan I²C bus 1 (arm requires i2c-tools)
```

Bluetooth claims the PL011 UART by default; for a serious serial device add `dtoverlay=disable-bt` to `/boot/firmware/config.txt` and use `/dev/ttyAMA0`.

## USB gadgets (Zero 2 W)

The Zero 2 W's data μUSB port is OTG: it can act as a keyboard, Ethernet gadget (usb0), or serial console to a host PC. Enable `dtoverlay=dwc2` in `config.txt` + `modules-load=dwc2,g_ether` in `cmdline.txt` for Ethernet gadget mode. Handy for headless Zero setup without Wi-Fi.
