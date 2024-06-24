# Run valgrind's callgrind tool against the rotating counter

Valgrind contains multiple tools. In this case, `callgrind` seems to track function calls throughout the program's execution.

run callgrind on prog with some added timestamps

```bash
valgrind --tool=callgrind --collect-systime=usec --time-stamp=yes ./prog
```

Review the output file at [callgrind.out.%p] where %p is the PID of the process traced. In my case, %p was 122191

```bash
nano callgrind.out.122191
```

## Dependencies

```bash
sudo apt install gcc make gdb valgrind
```
