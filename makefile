.PHONY: help udev install gvfs gvfs-permanent gvfs-undo dist

PHOTOBOOTH := photobooth.sh
UDEV_RULE := /etc/udev/rules.d/10-photobooth.rules

help:
	@echo "run 'make install' to stop gvfs services and install udev rule"
	@echo "run 'make gvfs-permanent' to disable gvfs permanently"
	@echo "run 'make gvfs-undo' to reenable gvfs"

udev :
	echo 'SUBSYSTEM=="usb", DRIVERS=="usb", ACTION=="add", ATTRS{idVendor}=="04a9", RUN+="$(PWD)/$(PHOTOBOOTH)"' | sudo tee "$(UDEV_RULE)"

install : udev gvfs

gvfs :
	systemctl --user stop gvfs-gphoto2-volume-monitor
	systemctl --user stop gvfs-mtp-volume-monitor
	systemctl --user stop gvfs-udisks2-volume-monitor

gvfs-permanent : gvfs
	systemctl --user disable gvfs-gphoto2-volume-monitor
	systemctl --user disable gvfs-mtp-volume-monitor
	systemctl --user disable gvfs-udisks2-volume-monitor

gvfs-undo :
	systemctl --user enable gvfs-gphoto2-volume-monitor
	systemctl --user enable gvfs-mtp-volume-monitor
	systemctl --user enable gvfs-udisks2-volume-monitor
	systemctl --user start gvfs-gphoto2-volume-monitor
	systemctl --user start gvfs-mtp-volume-monitor
	systemctl --user start gvfs-udisks2-volume-monitor

dist :
	tar caf photobooth_$$(git rev-parse --short HEAD).tar.xz makefile photobooth.sh start.png
