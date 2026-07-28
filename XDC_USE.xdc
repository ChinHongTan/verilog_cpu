## Clock signal (100MHz 主時脈)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches (16 個指撥開關, sw[0] 是最右邊)
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2 [get_ports {sw[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN T3 [get_ports {sw[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN T2 [get_ports {sw[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN R3 [get_ports {sw[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN W2 [get_ports {sw[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN U1 [get_ports {sw[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN T1 [get_ports {sw[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN R2 [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]

## LEDs (16 個 LED 燈, led[0] 是最右邊)
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN V3 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN W3 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN U3 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN P3 [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN N3 [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN P1 [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN L1 [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

## 7-Segment Display (七段顯示器)
## seg[0]~seg[6] 對應 a, b, c, d, e, f, g
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

## dp (小數點)
set_property PACKAGE_PIN V7 [get_ports seg[7]]
set_property IOSTANDARD LVCMOS33 [get_ports seg[7]]

## an[0]~an[3] (四個數字的控制開關，an[0]是最右邊的數字)
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

## Buttons (按鈕)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]
set_property PACKAGE_PIN T18 [get_ports btnU]
set_property IOSTANDARD LVCMOS33 [get_ports btnU]
set_property PACKAGE_PIN W19 [get_ports btnL]
set_property IOSTANDARD LVCMOS33 [get_ports btnL]
set_property PACKAGE_PIN T17 [get_ports btnR]
set_property IOSTANDARD LVCMOS33 [get_ports btnR]
set_property PACKAGE_PIN U17 [get_ports btnD]
set_property IOSTANDARD LVCMOS33 [get_ports btnD]

## Pmod Header JA (Top Right - for Pmod I2S2 Line Out)
#set_property PACKAGE_PIN J1 [get_ports master_out]
#set_property IOSTANDARD LVCMOS33 [get_ports master_out]
#set_property PACKAGE_PIN L2 [get_ports LR_out]
#set_property IOSTANDARD LVCMOS33 [get_ports LR_out]
#set_property PACKAGE_PIN J2 [get_ports sampling_out]
#set_property IOSTANDARD LVCMOS33 [get_ports sampling_out]
#set_property PACKAGE_PIN G2 [get_ports audio_out]
#set_property IOSTANDARD LVCMOS33 [get_ports audio_out]

## Pmod Header JB (Top right - for Pmod I2S2 Line Out)
#set_property PACKAGE_PIN A14 [get_ports master_out]
#set_property IOSTANDARD LVCMOS33 [get_ports master_out]
#set_property PACKAGE_PIN A16 [get_ports LR_out]
#set_property IOSTANDARD LVCMOS33 [get_ports LR_out]
#set_property PACKAGE_PIN B15 [get_ports sampling_out]
#set_property IOSTANDARD LVCMOS33 [get_ports sampling_out]
#set_property PACKAGE_PIN B16 [get_ports audio_out]
#set_property IOSTANDARD LVCMOS33 [get_ports audio_out]

## Pmod Header JC (left left - for Pmod I2S2 Line Out)
#set_property PACKAGE_PIN K17 [get_ports master_out]
#set_property IOSTANDARD LVCMOS33 [get_ports master_out]
#set_property PACKAGE_PIN M18 [get_ports LR_out]
#set_property IOSTANDARD LVCMOS33 [get_ports LR_out]
#set_property PACKAGE_PIN N17 [get_ports sampling_out]
#set_property IOSTANDARD LVCMOS33 [get_ports sampling_out]
#set_property PACKAGE_PIN P18 [get_ports audio_out]
#set_property IOSTANDARD LVCMOS33 [get_ports audio_out]

## Pmod Header JXADC (left down - for Pmod I2S2 Line Out)
#set_property PACKAGE_PIN J3 [get_ports master_out]
#set_property IOSTANDARD LVCMOS33 [get_ports master_out]
#set_property PACKAGE_PIN L3 [get_ports LR_out]
#set_property IOSTANDARD LVCMOS33 [get_ports LR_out]
#set_property PACKAGE_PIN M2 [get_ports sampling_out]
#set_property IOSTANDARD LVCMOS33 [get_ports sampling_out]
#set_property PACKAGE_PIN N2 [get_ports audio_out]
#set_property IOSTANDARD LVCMOS33 [get_ports audio_out]

## PS/2 鍵盤腳位設定
#set_property PACKAGE_PIN C17 [get_ports PS2_CLK]						
#	set_property IOSTANDARD LVCMOS33 [get_ports PS2_CLK]
#	set_property PULLUP TRUE [get_ports PS2_CLK]
#set_property PACKAGE_PIN B17 [get_ports PS2_DATA]					
#	set_property IOSTANDARD LVCMOS33 [get_ports PS2_DATA]	
#	set_property PULLUP TRUE [get_ports PS2_DATA]

## VGA Red
#set_property PACKAGE_PIN G19 [get_ports {vga_red[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[0]}]
#set_property PACKAGE_PIN H19 [get_ports {vga_red[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[1]}]
#set_property PACKAGE_PIN J19 [get_ports {vga_red[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[2]}]
#set_property PACKAGE_PIN N19 [get_ports {vga_red[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[3]}]

## VGA Green
#set_property PACKAGE_PIN J17 [get_ports {vga_green[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[0]}]
#set_property PACKAGE_PIN H17 [get_ports {vga_green[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[1]}]
#set_property PACKAGE_PIN G17 [get_ports {vga_green[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[2]}]
#set_property PACKAGE_PIN D17 [get_ports {vga_green[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[3]}]

## VGA Blue
#set_property PACKAGE_PIN N18 [get_ports {vga_blue[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[0]}]
#set_property PACKAGE_PIN L18 [get_ports {vga_blue[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[1]}]
#set_property PACKAGE_PIN K18 [get_ports {vga_blue[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[2]}]
#set_property PACKAGE_PIN J18 [get_ports {vga_blue[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[3]}]

## VGA Sync Signals
#set_property PACKAGE_PIN P19 [get_ports hsync]
#set_property IOSTANDARD LVCMOS33 [get_ports hsync]
#set_property PACKAGE_PIN R19 [get_ports vsync]
#set_property IOSTANDARD LVCMOS33 [get_ports vsync]



##USB-RS232 Interface
#set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
#set_property PACKAGE_PIN A18 [get_ports RsTx]
#set_property IOSTANDARD LVCMOS33 [get_ports RsTx]


##USB HID (PS/2)
#set_property PACKAGE_PIN C17 [get_ports PS2Clk]
#set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk]
#set_property PULLUP true [get_ports PS2Clk]
#set_property PACKAGE_PIN B17 [get_ports PS2Data]
#set_property IOSTANDARD LVCMOS33 [get_ports PS2Data]
#set_property PULLUP true [get_ports PS2Data]


##Quad SPI Flash
##Note that CCLK_0 cannot be placed in 7 series devices. You can access it using the
##STARTUPE2 primitive.
#set_property PACKAGE_PIN D18 [get_ports {QspiDB[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[0]}]
#set_property PACKAGE_PIN D19 [get_ports {QspiDB[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[1]}]
#set_property PACKAGE_PIN G18 [get_ports {QspiDB[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[2]}]
#set_property PACKAGE_PIN F18 [get_ports {QspiDB[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[3]}]
#set_property PACKAGE_PIN K19 [get_ports QspiCSn]
#set_property IOSTANDARD LVCMOS33 [get_ports QspiCSn]

#set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
#set_property CONFIG_MODE SPIx4 [current_design]

#set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

#set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property CFGBVS VCCO [current_design]
