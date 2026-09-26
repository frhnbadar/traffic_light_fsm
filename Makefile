# Simulator
VLOG = vlog
VSIM = vsim

# Files
RTL = rtl/traffic_light_fsm.sv
TB  = tb/traffic_light_fsm_tb.sv

# Top module
TOP = traffic_light_fsm_tb


# Compile
compile:
	$(VLOG) -sv $(RTL)
	$(VLOG) -sv $(TB)


# Run simulation
run: compile
	$(VSIM) -c -voptargs=+acc $(TOP) -do "run -all; quit"


# Clean generated Questa files
clean:
	rm -rf work
	rm -f transcript
	rm -f vsim.wlf