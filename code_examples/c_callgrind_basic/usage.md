# Run valgrind's callgrind tool against the rotating counter

You have to specify which of valgrind's various tools to use when calling it.
In this case, callgrind seems to track function calls throughout the program's execution.

Add 2 options for timestamping and run callgrind on prog

```
valgrind --tool=callgrind --collect-systime=usec --time-stamp=yes ./prog
```

Review the output file at [callgrind.out.%p] where %p is the PID of the process traced.
