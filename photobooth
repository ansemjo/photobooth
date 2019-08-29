#!/usr/bin/env python3

# misc imports
from argparse import ArgumentParser
from os.path import join, splitext
from datetime import datetime
from time import sleep

# signal handler
from signal import signal, SIGTERM, SIGINT
from sys import exit

# worker threads and sync
from threading import Thread, Event
from queue import SimpleQueue, Empty
from subprocess import Popen, DEVNULL

# gphoto2 interface
from gphoto2 import Camera, GPhoto2Error, GP_EVENT_FILE_ADDED, GP_FILE_TYPE_NORMAL

# ~~~~~~~~~~ commandline parser ~~~~~~~~~~ #

args = ArgumentParser()
args.add_argument("--directory", "-d", help="target directory", required=True)
args.add_argument("--name", "-n", help="filename element for new photos", default="capture")
args.add_argument("--slide-delay", "-s", help="background slideshow delay", default=3.0, type=float)
args.add_argument("--hold-time", "-p", help="hold time for new pictures", default=5.0, type=float)
args.add_argument("--overlap", "-o", help="overlap time for consecutive pictures", default=0.5, type=float)
args = args.parse_args()
print(args)
#exit(0)

# ~~~~~~~~~~ utility funtions ~~~~~~~~~~ #

# start a feh subprocess with additional arguments
def feh(extra):
  return Popen(["feh", "--quiet", "--hide-pointer", "--fullscreen", "--zoom", "fill"] + extra, stdin=DEVNULL)

# return filename with current date and incrementing counter
class filename:
  def __init__(self, name="capture"):
    self.ctr, self.name = 0, name
  def next(self, ext=".jpg"):
    ctr = self.ctr = self.ctr + 1
    return f"{datetime.now():%Y-%m-%dT%H%M%S}_{self.name}_{ctr:04d}{ext}"

# ~~~~~~~~~~ background workers ~~~~~~~~~~ #

# an updating and random slideshow
def slideshow(quit, directory, delay = 5):
  while True:
    # start process
    proc = feh(["--slideshow-delay", str(delay), "--reload", str(delay), "--randomize", directory])
    # poll if process is alive
    while proc.poll() is None:
      # kill and quit on event
      if quit.is_set():
        proc.kill()
        return
      sleep(5)


# display newly queued pictures on top
def worker(quit, queue, delay = 3, overlap = 0.5):
  # feh process references
  last, next = None, None
  # loop until quit event ..
  while not quit.is_set():
    try:

      # wait for new pictures
      new = queue.get(timeout=0.2)
      # display new picture
      next = feh([new])
      # kill last with some overlap if it exists
      sleep(overlap)
      if last: last = last.kill()
      # save process and sleep
      last = next
      sleep(delay - overlap)

    except Empty:
      # no picture in queue
      if last: last = last.kill()
  
  # tidy up before quitting
  if last: last = last.kill()


# main camera tethering loop
def tethering(quit, queue, directory, name, camera = None):
  # initialize filename counter
  fn = filename(name)
  # loop until quit event ..
  while not quit.is_set():
    try:

      # initialize camera
      if camera is None:
        camera = Camera()
        camera.init()

      # wait for any camera events
      event, data = camera.wait_for_event(100)
      # if it is a shutter release
      if event is GP_EVENT_FILE_ADDED:
        # download picture
        photo = camera.file_get(data.folder, data.name, GP_FILE_TYPE_NORMAL)
        # write to capture directory
        path = join(directory, fn.next(splitext(data.name)[1]))
        photo.save(path)
        print("saved new image: %s" % path)
        # enqueue for display
        queue.put(path)

    except GPhoto2Error:
      # attempt to reinitalize camera on errors
      if camera: camera = camera.exit()
      sleep(2)

  # tidy up before quitting
  if camera: camera = camera.exit()


# ~~~~~~~~~~ initialize worker threads ~~~~~~~~~~ #

# initialize an empty queue
queue = SimpleQueue()
event = Event()

# create and start threads
for t in [
  Thread(target=slideshow, args=[event, args.directory, args.slide_delay]), # background slideshow
  Thread(target=tethering, args=[event, queue, args.directory, args.name]), # tethering loop
  Thread(target=worker, args=[event, queue, args.hold_time, args.overlap]), # popup worker
]: t.start()

# ~~~~~~~~~~ register signal handling ~~~~~~~~~~ #

# signal handler to quit cleanly
def quit(sig, frame):
  print("\rquitting ...")
  # force exit on repeated signal
  signal(sig, lambda s, f: exit(9))
  event.set()

# register signal handler
signal(SIGINT, quit)
signal(SIGTERM, quit)
