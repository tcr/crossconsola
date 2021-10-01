EMCC_OPTS=-s USE_LIBPNG=1 -s WASM=1 -s EXIT_RUNTIME=1 -s MODULARIZE=1

all: rgbds cc65 nasm

.PHONY: rgbds cc65 nasm docker-image

rgbds:
	mkdir -p dist
	cd rgbds && docker run --rm -v $(shell pwd)/rgbds:/src/ crossconsola "emmake" make CC="emcc $(EMCC_OPTS)"
	cp ./rgbds/rgbasm ./dist/rgbasm.o
	cd dist && docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "rgbasm.o" "-o" "rgbasm.js" $(EMCC_OPTS) -s EXPORT_NAME='"rgbasm"'

cc65:
	mkdir -p dist
	cd rgbds && docker run --rm -v $(shell pwd)/cc65:/src/ crossconsola "emmake" make CC="emcc $(EMCC_OPTS)" || true
	cp ./cc65/bin/ca65.exe ./dist/ca65.o
	cd dist && docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "ca65.o" "-o" "ca65.js" $(EMCC_OPTS) -s EXPORT_NAME='"ca65"'
	
nasm:
	mkdir -p dist
	cd nasm && docker run --rm -v $(shell pwd)/nasm:/src/ crossconsola "emconfigure" ./configure
	cd nasm && docker run --rm -v $(shell pwd)/nasm:/src/ crossconsola "emmake" make CC="emcc $(EMCC_OPTS)"
	cp ./nasm/nasm ./dist/nasm.o
	cd dist && docker run --rm -v $(shell pwd)/dist:/src crossconsola "emcc" "nasm.o" "-o" "nasm.js" $(EMCC_OPTS) -s EXPORT_NAME='"nasm"'
	
clean:
	mkdir -p dist
	cd rgbds; make clean
	rm dist/rgbasm* || true
	cd cc65; make clean
	rm dist/cc65* dist/ca65* || true
	cd nasm; make clean
	rm dist/nasm* || true

docker-image:
	docker build . -t crossconsola
