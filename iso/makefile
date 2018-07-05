.PHONY : image run

image:
	docker build -t preseediso .

run: image
	docker run --rm -it \
		-v $(PWD)/debian-9.4.0-amd64-netinst.iso:/data/debian-stretch.iso preseediso
