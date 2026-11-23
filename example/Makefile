MAIN = main
BUILD = build
ROOT := $(shell git rev-parse --show-toplevel)

.PHONY: all clean

all:
	TEXINPUTS=".:$(ROOT)//:" latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error -outdir=$(BUILD) $(MAIN).tex

clean:
	rm -rf $(BUILD)
