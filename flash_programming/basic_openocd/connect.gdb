# GDB server port is 3333 by default but explicitly set to 2331 in stm32l4_pelagic_flash.cfg
target extended-remote localhost:2331
monitor reset halt

# easy reset & run - press r
define r
  monitor reset
  run
end

# easy quit - press q
define q
  quit
end

# Optional break on main()
b main
