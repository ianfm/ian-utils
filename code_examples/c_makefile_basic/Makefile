# Basic Makefile

default: build

build: 
	g++ hello_world.cpp

build-debug:
	g++ -g -Werror -Wall -Wpedantic hello_world.cpp

run: build
	./a.out

debug: build-debug
	./a.out

clean:
	rm a.out

