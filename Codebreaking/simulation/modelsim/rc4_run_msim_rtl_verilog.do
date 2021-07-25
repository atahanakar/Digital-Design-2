transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking {C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking/s_memory.v}
vlog -sv -work work +incdir+C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking {C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking/sseg_controller.sv}
vlog -sv -work work +incdir+C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking {C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking/ksa.sv}
vlog -sv -work work +incdir+C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking {C:/Users/ATAHAN/Documents/GitHub/Digital-Design-2/Codebreaking/fsm.sv}

