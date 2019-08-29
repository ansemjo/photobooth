#!/usr/bin/env python3

import gphoto2
import argparse
import subprocess
from datetime import datetime
import os, sys, time

# commandline parser
args = argparse.ArgumentParser()
args.add_argument("--directory", "-d", help="target directory", required=True)
args.add_argument("--name", "-n", help="filename element", default="capture")
args.add_argument("--slide-delay", help="background slideshow delay", default=5, type=int)
args.add_argument("--popup-delay", help="delay for new pictures", default=3, type=int)
args = args.parse_args()
print(args)

# start a feh subprocess
def feh(args):
  return subprocess.Popen(["feh", "--hide-pointer", "--fullscreen", "--zoom", "fill"] + args,
      stdin=subprocess.DEVNULL)

# return filename with current date and incrementing counter
class filename:
  datefmt = "%Y-%m-%dT%H%M%S"
  def __init__(self, name="capture"):
    self.counter = 0
    self.name = name
  def next(self, ext="jpg"):
    n = self.counter
    self.counter += 1
    return "%s_%s_%04d.%s" % (datetime.now().strftime(self.datefmt), self.name, n, ext)
fn = filename(args.name)

# initialize camera
camera = gphoto2.Camera()
camera.init()

# start slideshow in background
slideshow = feh(["--slideshow-delay", str(args.slide_delay), "--reload", str(args.slide_delay), "--randomize", args.directory])

# main tethering loop
while True:
  event, data = camera.wait_for_event(100)
  if event is gphoto2.GP_EVENT_FILE_ADDED:
    photo = camera.file_get(data.folder, data.name, gphoto2.GP_FILE_TYPE_NORMAL)
    print(data)
    path = os.path.join(args.directory, fn.next())
    photo.save(path)
    popup = feh([path])
    print("saved new image: %s" % path)
    time.sleep(args.popup_delay)
    popup.kill()

