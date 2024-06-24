# Standard Makefile for auto detecting C++ source and header files
TARGET = prog
LIBS = -lm
CC = g++
CCFLAGS = -g -Wall

.PHONY: default all clean run debug

default: $(TARGET)
all: default

OBJECTS := $(patsubst %.cpp, %.o, $(wildcard *.cpp))
HEADERS := $(wildcard *.h)

%.o: %.cpp $(HEADERS)
	$(CC) $(CCFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	$(CC) $(CCFLAGS) $(OBJECTS) -Wall $(LIBS) -o $@

run: $(TARGET)
	./$(TARGET)

debug: $(TARGET)
	gdb $(TARGET)

clean:
	-rm -f *.o
	-rm -f $(TARGET)

