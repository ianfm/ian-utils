#!/bin/bash
# This remaps the three-finger touchpad click or mouse middle click (untested) 
# to "physical button 9", whatever that is. This might be undesirable on some mice
# but is a godsend for touchpads
# based on "https://bbs.archlinux.org/viewtopic.php?pid=762554"

xmodmap -e "pointer = 1 9 3 4 5 6 7 8 2"
