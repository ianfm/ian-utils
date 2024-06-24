# Running the simplest CMake build

To build the hello world app using CMake, you need to first create a build directory, 
then enter it and run `cmake ..`, pointing CMake at the source directory.
CMake actually only creates the makefiles to build the app, so after running cmake, run `make` to actually build the project.

```
mkdir build
cd build
cmake ..
make
./hello_world
```

## Dependencies

```
sudo apt install gcc gdb make cmake valgrind
```
