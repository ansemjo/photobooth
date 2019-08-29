#!/usr/bin/env python3

from signal import signal, SIGTERM, SIGINT
from time import sleep
from os.path import join
from sys import exit
from argparse import ArgumentParser
from threading import Thread, Event
from queue import SimpleQueue, Empty
from datetime import datetime
from subprocess import Popen, DEVNULL
from gphoto2 import Camera, GPhoto2Error, GP_EVENT_FILE_ADDED, GP_FILE_TYPE_NORMAL

# commandline parser
args = ArgumentParser()
args.add_argument("--directory", "-d", help="target directory", required=True)
args.add_argument("--name", "-n", help="filename element", default="capture")
args.add_argument("--slide-delay", help="background slideshow delay", default=5, type=int)
args.add_argument("--popup-delay", help="delay for new pictures", default=3, type=int)
args = args.parse_args()

# start a feh subprocess with additional arguments
def feh(args):
  return Popen(["feh", "--hide-pointer", "--fullscreen", "--zoom", "fill"] + args, stdin=DEVNULL)

# return filename with current date and incrementing counter
class filename:
  def __init__(self, name="capture"):
    self.ctr, self.name = 0, name
  def next(self, ext="jpg"):
    ctr = self.ctr = self.ctr + 1
    return f"{datetime.now():%Y-%m-%dT%H%M%S}_{self.name}_{ctr:04d}.{ext}"


# a random background slideshow with feh
def slideshow(quit, directory, delay = 5):
  
  while True:
    # start process
    proc = feh(["--slideshow-delay", str(delay), "--reload", str(delay), "--randomize", directory])
    
    # poll and wait for quit event
    while proc.poll() is None:
      if quit.is_set():
        proc.kill()
        return
      sleep(5)


# background worker to display queued pictures on top
def worker(quit, queue, delay = 3, overlap = 0.5):
  
  # structs to hold feh process references
  last, next = None, None
  
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


# main tethering loop
def tethering(quit, queue, directory, name, camera = None):

  # initialize filename counter
  fn = filename(name)

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
        path = join(directory, fn.next())
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


# initialize an empty queue
queue = SimpleQueue()
event = Event()

# create and start threads
for t in [
  Thread(target=slideshow, args=[event, args.directory, args.slide_delay]), # background slideshow
  Thread(target=tethering, args=[event, queue, args.directory, args.name]), # tethering loop
  Thread(target=worker, args=[event, queue, args.popup_delay]), # popup worker
]: t.start()

# signal handler to quit cleanly
def quit(sig, frame):
  print("\rquitting ...")
  signal(sig, lambda s, f: exit(9))
  event.set()
signal(SIGINT, quit)
signal(SIGTERM, quit)
