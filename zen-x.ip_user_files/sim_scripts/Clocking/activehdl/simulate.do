onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+Clocking  -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.Clocking xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {Clocking.udo}

run

endsim

quit -force