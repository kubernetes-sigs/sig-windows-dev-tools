
all: build-binaries vagrant-up

build-binaries:
	chmod +x build.sh
	./build.sh

vagrant-up:
	vagrant destroy -f && vagrant up
 