PREFIX        := ~/.local
BINPATH       := $(PREFIX)/bin
APPLICATIONS  := $(PREFIX)/share/applications
DESKTOP       := ~/Desktop
DIRECTORY     := ~/Photobooth

install : $(BINPATH)/photobooth $(DESKTOP)/photobooth.desktop

assets/photobooth.desktop : assets/photobooth.desktop.in
	sed \
	  -e 's;%%BINPATH%%;$(BINPATH)/photobooth;g' \
	  -e 's;%%DIRECTORY%%;$(DIRECTORY);g' \
	  $< > $@

$(DESKTOP)/%.desktop : assets/%.desktop
	install -Dm755 $< $@

$(BINPATH)/photobooth : photobooth
	install -Dm755 $< $@

$(DIRECTORY) :
	install -d $@