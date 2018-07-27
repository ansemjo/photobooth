# photobooth

**this is a work in progress. use at your own risk.**

scripts and configurations intended to enable a photobooth-like
operation with a laptop, a camera, gphoto2 and tethered captures.

early versions used seperate shell scripts, installed with the
included makefile.

the current version uses an ansible playbook to completely configure
a clean laptop. this means that it will overwrite many of your
settings. **DO NOT POINT THIS AT YOUR LAPTOP** .. unless it really is
what you want to do. the playbook is self-executing via a shebang:

```shell
./fotobox.yml -i inventory
```

the file `preseed.cfg` is an example of a preseeded debian installation
on which the ansible playbook shall then be executed.
