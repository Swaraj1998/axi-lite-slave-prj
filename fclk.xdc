
create_clock -name fclk0 -period 20.0 [get_pins ps7_stub_inst/PS7_inst/FCLKCLK[0]]
create_clock -name fclk1 -period 100.0 [get_pins ps7_stub_inst/PS7_inst/FCLKCLK[1]]
create_clock -name fclk2 -period 100.0 [get_pins ps7_stub_inst/PS7_inst/FCLKCLK[2]]
create_clock -name fclk3 -period 8.0 [get_pins ps7_stub_inst/PS7_inst/FCLKCLK[3]]
