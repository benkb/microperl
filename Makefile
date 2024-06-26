.PHONY: clean all

all:
	sh ./build.sh '5.10.0'


clean:
	rm -rf temp
	rm -rf build
