# Basic Makefile with Variables
SRC=rollover_counter.cpp
EXE=a.out
CC=g++
CC_FLAGS=-Werror -Wpedantic
DEBUG_FLAGS=-g

all: build run

build: 
	$(CC) $(CC_FLAGS) $(SRC) -o $(EXE)

build-debug:
	$(CC) $(CC_FLAGS) $(DEBUG_FLAGS) $(SRC) -o $(EXE)

exec:
	./$(EXE)

run: build exec

debug: build-debug
	gdb $(EXE)

clean:
	rm $(EXE)

