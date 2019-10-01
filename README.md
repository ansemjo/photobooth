# photobooth

This is a Python script, which uses the `gphoto2` API to capture tethered
pictures with a compatible camera and show them in a continious slideshow.

Each time a picture is taken, it is displayed for some amount of time before
the normal slideshow resumes. The captures are controlled by the camera, the
script only waits for capture events! I.e. you might want to use either the
camera's self-timer or some Arduino-powered trigger to control the camera.

## INSTALLATION

TODO. Basically have Python 3 installed, add the gphoto library and start
tethering with `./photobooth`.

## USAGE

You can control the storage directory and slideshow delays with commandline
flags. Check `./photobooth --help` for a list of options.

| option | description |
|--------|-------------|
|`--directory DIR`| Store captured pictures in this directory. |
|`--name NAME`| Captured photos are named with a timestamp and a consecutive counter. Use `NAME` to customize the part before the counter. |
|`--slide-delay N`| Delay between pictures in the background slideshow. |
|`--hold-time N`| Display new pictures in foreground for `N` seconds. |
|`--overlap F`| There is some overlap between `feh` processes displaying the slideshow and current capture to prevent flickering. Increase this value if you're running on slow hardware. |
