## Basic debugging actions for this program

The counter in rotating_counter.cpp is an 8b int, so it can only count from -128 to 127. 
std::cout doesn't print the numerical value of count, but renders it as a char.
Stop the program just before count gets written to the screen as a non-printable character.

  
Run the program under gdb
```bash
gdb a.out
```

  
In the GDB shell, use the following commands to 
- load the program for execution and begin executing 
- set a breakpoint on the line where count is incremented set it to only triggers if count is about to roll over
- show the value of count whenever the program halts
- continue execution until the next breakpoint triggers

```gdb
(gdb) run
(gdb) break rollover_counter.cpp:8 if count>=127
(gdb) display count
(gdb) display (int)count
(gdb) continue
```

Check out the help commands to see what is available

```gdb
(gdb) help
(gdb) help break
(gdb) help running
(gdb) help display
(gdb) info breakpoints
(gdb) info source
(gdb) info locals
```

After testing this out, you can exit gdb by pressing `q`.




