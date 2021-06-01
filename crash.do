set i 0;
while {$i<220} {
run 1ms
set addr [expr {round(rand()*16383)}]
set w [mem display -noaddress -dataradix binary sim:/sim_top/mb0/ram/ham0($addr)]
set r  [expr {round(rand()*11)}]
set bit [expr round(rand())]
set w_new [string replace $w $r $r $bit]
mem load -filldata $w_new -fillradix binary sim:/sim_top/mb0/ram/ham0($addr)
incr i
}


