EMCC_OPTS=-s USE_LIBPNG=1 -s WASM=1 -s EXIT_RUNTIME=1 -s MODULARIZE=1 -s 'EXTRA_EXPORTED_RUNTIME_METHODS=["FS"]'

all: rgbds cc65 nasm hello crossconsola.tar.gz

.PHONY: docker-image rgbds cc65 nasm hello crossconsola.tar.gz

crossconsola.tar.gz:
	tar -cvf crossconsola.tar.gz --strip-components=1 dist/*.js dist/*.wasm

rgbds:
	mkdir -p dist cache
	docker run --rm -v $(shell pwd)/rgbds:/src/ crossconsola "emmake" make CC="emcc $(EMCC_OPTS)"
	cp ./rgbds/rgbasm ./dist/rgbasm.o
	cp ./rgbds/rgblink ./dist/rgblink.o
	docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "rgbasm.o" "-o" "rgbasm.js" $(EMCC_OPTS) -s EXPORT_NAME='"rgbasm"'
	docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "rgblink.o" "-o" "rgblink.js" $(EMCC_OPTS) -s EXPORT_NAME='"rgblink"'

cc65:
	mkdir -p dist cache
	docker run --rm -v $(shell pwd)/cc65:/src/ crossconsola "emmake" make CC="emcc $(EMCC_OPTS)" || true
	cp ./cc65/bin/ca65.exe ./dist/ca65.o
	docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "ca65.o" "-o" "ca65.js" $(EMCC_OPTS) -s EXPORT_NAME='"ca65"'
	
nasm:
	mkdir -p dist cache
	[ -e ./nasm/configure ] || docker run --rm -v $(shell pwd)/nasm:/src/ crossconsola "emconfigure" ./autogen.sh
	[ -e ./nasm/Makefile ] || docker run --rm -v $(shell pwd)/nasm:/src/ crossconsola "emconfigure" ./configure
	rm nasm/a.out* || true
	docker run --rm -v $(shell pwd)/nasm:/src/ crossconsola "emmake" make CC="emcc $(EMCC_OPTS)"
	cp ./nasm/nasm ./dist/nasm.o
	docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "nasm.o" "-o" "nasm.js" $(EMCC_OPTS) -s EXPORT_NAME='"nasm"'
	
hello:
	mkdir -p dist cache
	docker run --rm -v $(shell pwd)/hello:/src/ crossconsola "emcc" "helloworld.cpp" "-o" helloworld.o $(EMCC_OPTS)
	cp ./hello/helloworld.o ./dist/helloworld.o
	docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "helloworld.o" "-o" "helloworld.js" $(EMCC_OPTS) -s EXPORT_NAME='"helloworld"'
	
clean:
	rm -rf dist cache || true
	cd rgbds; make clean || true
	cd cc65; make clean || true
	cd nasm; make distclean || true

docker-image:
	docker build . -t crossconsola
