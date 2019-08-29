#!/usr/bin/env python3

import gphoto2
import argparse
import subprocess
from datetime import datetime
import os, sys, time
import queue, threading

# commandline parser
args = argparse.ArgumentParser()
args.add_argument("--directory", "-d", help="target directory", required=True)
args.add_argument("--name", "-n", help="filename element", default="capture")
args.add_argument("--slide-delay", help="background slideshow delay", default=5, type=int)
args.add_argument("--popup-delay", help="delay for new pictures", default=3, type=int)
args = args.parse_args()

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

# start slideshow in background
slideshow = feh(["--slideshow-delay", str(args.slide_delay), "--reload", str(args.slide_delay), "--randomize", args.directory])

# background worker to display queued popups
def popup_worker():
  new, old = None, None
  while True:
    try:
      newpath = q.get(timeout=0.5)

      # otherwise display next with overlap
      new = feh([newpath])
      time.sleep(0.5)
      if old:
        old.kill()
      old = new
      time.sleep(args.popup_delay)

    except queue.Empty:
      # no new picture
      if old:
        old.kill()
        old = None


# initialize an empty queue and start popup worker
q = queue.SimpleQueue()
t = threading.Thread(target=popup_worker)
t.start()

# main tethering loop
camera = None
while True:
  try:

    if camera is None:
      camera = gphoto2.Camera()
      camera.init()

    event, data = camera.wait_for_event(100)
    if event is gphoto2.GP_EVENT_FILE_ADDED:
      photo = camera.file_get(data.folder, data.name, gphoto2.GP_FILE_TYPE_NORMAL)
      print(data)
      path = os.path.join(args.directory, fn.next())
      photo.save(path)
      print("saved new image: %s" % path)
      q.put(path)

  except gphoto2.GPhoto2Error:
    # probably lost connection, try re-init
    if camera:
      camera.exit()
      camera = None
    time.sleep(1)

# should never be here
q.join()
t.join()
