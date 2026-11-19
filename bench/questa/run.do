do compile.do
vsim -voptargs=+acc work.tb_apb_spi
add wave -position insertpoint sim:/tb_apb_spi/i_vip/*
add wave -position insertpoint sim:/tb_apb_spi/i_sd_card/*
add wave -position insertpoint sim:/tb_apb_spi/i_dut/*
onfinish stop
run -all