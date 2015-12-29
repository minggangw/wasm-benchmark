POLYFILL=third_party/polyfill-prototype-1
SRCDIR = $(POLYFILL)/demos
PACKER = $(POLYFILL)/tools/pack-asmjs-v8
SRC=$(wildcard $(SRCDIR)/*.cpp)

# FIXME: raytrace cause crash in v8
SRC:=$(filter-out %raytrace.cpp, $(SRC))

vpath %.cpp $(SRCDIR)

WASM = $(addprefix www/, $(notdir $(SRC:.cpp=.wasm)))

all: $(PACKER) $(WASM) www/main.js

www/main.js: gen_main.sh $(SRC)
	./gen_main.sh $(notdir $(SRC:.cpp=)) > $@

$(PACKER): $(POLYFILL)/Makefile
	make -C $(POLYFILL) tools/pack-asmjs-v8

.SUFFIXES: .wasm .js .c .cpp

www/%.wasm www/%.js : %.c
	./build.sh -o $(basename $@).html $<
www/%.wasm www/%.js: %.cpp
	./build.sh -o $(basename $@).html $<

clean:
	rm -f www/main.js $(WASM) $(WASM:.wasm=.html) $(WASM:.wasm=.html.mem) $(WASM:.wasm=.js) $(WASM:.wasm=.asm.js)
