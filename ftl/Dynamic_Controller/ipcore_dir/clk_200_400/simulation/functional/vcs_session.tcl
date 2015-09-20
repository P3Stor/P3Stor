gui_open_window Wave
gui_sg_create clk_200_400_group
gui_list_add_group -id Wave.1 {clk_200_400_group}
gui_sg_addsignal -group clk_200_400_group {clk_200_400_tb.test_phase}
gui_set_radix -radix {ascii} -signals {clk_200_400_tb.test_phase}
gui_sg_addsignal -group clk_200_400_group {{Input_clocks}} -divider
gui_sg_addsignal -group clk_200_400_group {clk_200_400_tb.CLK_IN1}
gui_sg_addsignal -group clk_200_400_group {{Output_clocks}} -divider
gui_sg_addsignal -group clk_200_400_group {clk_200_400_tb.dut.clk}
gui_list_expand -id Wave.1 clk_200_400_tb.dut.clk
gui_sg_addsignal -group clk_200_400_group {{Status_control}} -divider
gui_sg_addsignal -group clk_200_400_group {clk_200_400_tb.RESET}
gui_sg_addsignal -group clk_200_400_group {clk_200_400_tb.LOCKED}
gui_sg_addsignal -group clk_200_400_group {{Counters}} -divider
gui_sg_addsignal -group clk_200_400_group {clk_200_400_tb.COUNT}
gui_sg_addsignal -group clk_200_400_group {clk_200_400_tb.dut.counter}
gui_list_expand -id Wave.1 clk_200_400_tb.dut.counter
gui_zoom -window Wave.1 -full
