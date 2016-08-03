EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:relays
LIBS:crystal_s
LIBS:input-cache
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 5
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Sheet
S 4600 3450 950  200 
U 57A1EDDA
F0 "Input Filter" 60
F1 "input_filter.sch" 60
F2 "Out" I R 5550 3550 60 
F3 "Threshold" I L 4600 3550 60 
$EndSheet
$Sheet
S 4600 3850 950  200 
U 57A244CC
F0 "Input Filter" 60
F1 "input_filter.sch" 60
F2 "Out" I R 5550 3950 60 
F3 "Threshold" I L 4600 3950 60 
$EndSheet
$Sheet
S 4600 4250 950  200 
U 57A248BB
F0 "Input Filter" 60
F1 "input_filter.sch" 60
F2 "Out" I R 5550 4350 60 
F3 "Threshold" I L 4600 4350 60 
$EndSheet
$Sheet
S 4600 4650 950  200 
U 57A248BE
F0 "Input Filter" 60
F1 "input_filter.sch" 60
F2 "Out" I R 5550 4750 60 
F3 "Threshold" I L 4600 4750 60 
$EndSheet
$Comp
L CONN_02X04 P?
U 1 1 57A21F32
P 6450 4150
F 0 "P?" H 6450 4515 50  0000 C CNN
F 1 "TO_MAIN" H 6450 4424 50  0000 C CNN
F 2 "" H 6450 2950 60  0000 C CNN
F 3 "" H 6450 2950 60  0000 C CNN
	1    6450 4150
	1    0    0    -1  
$EndComp
Wire Wire Line
	6200 4000 6000 4000
Wire Wire Line
	6000 4000 6000 3550
Wire Wire Line
	6000 3550 5550 3550
Wire Wire Line
	5550 3950 5900 3950
Wire Wire Line
	5900 3950 5900 4100
Wire Wire Line
	5900 4100 6200 4100
Wire Wire Line
	5550 4350 5900 4350
Wire Wire Line
	5900 4350 5900 4200
Wire Wire Line
	5900 4200 6200 4200
Wire Wire Line
	6200 4300 6000 4300
Wire Wire Line
	6000 4300 6000 4750
Wire Wire Line
	6000 4750 5550 4750
Wire Wire Line
	6700 4000 6800 4000
Wire Wire Line
	6800 3900 6800 4100
Wire Wire Line
	6800 4100 6700 4100
Wire Wire Line
	6700 4200 6800 4200
Wire Wire Line
	6800 4200 6800 4400
Wire Wire Line
	6800 4300 6700 4300
$Comp
L +5V #PWR?
U 1 1 57A223CE
P 6800 3900
F 0 "#PWR?" H 6800 3750 60  0001 C CNN
F 1 "+5V" H 6815 4081 60  0000 C CNN
F 2 "" H 6800 3900 60  0000 C CNN
F 3 "" H 6800 3900 60  0000 C CNN
	1    6800 3900
	1    0    0    -1  
$EndComp
Connection ~ 6800 4000
$Comp
L GND #PWR?
U 1 1 57A22442
P 6800 4400
F 0 "#PWR?" H 6800 4150 60  0001 C CNN
F 1 "GND" H 6805 4219 60  0001 C CNN
F 2 "" H 6800 4400 60  0000 C CNN
F 3 "" H 6800 4400 60  0000 C CNN
	1    6800 4400
	1    0    0    -1  
$EndComp
Connection ~ 6800 4300
$Comp
L C C?
U 1 1 57A22FA2
P 7200 4150
F 0 "C?" H 7315 4188 40  0000 L CNN
F 1 "100n" H 7315 4112 40  0000 L CNN
F 2 "" H 7238 4000 30  0000 C CNN
F 3 "" H 7200 4150 60  0000 C CNN
	1    7200 4150
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR?
U 1 1 57A23080
P 7200 3850
F 0 "#PWR?" H 7200 3700 60  0001 C CNN
F 1 "+5V" H 7215 4031 60  0000 C CNN
F 2 "" H 7200 3850 60  0000 C CNN
F 3 "" H 7200 3850 60  0000 C CNN
	1    7200 3850
	1    0    0    -1  
$EndComp
Wire Wire Line
	7200 3850 7200 3950
$Comp
L GND #PWR?
U 1 1 57A230F1
P 7200 4450
F 0 "#PWR?" H 7200 4200 60  0001 C CNN
F 1 "GND" H 7205 4269 60  0001 C CNN
F 2 "" H 7200 4450 60  0000 C CNN
F 3 "" H 7200 4450 60  0000 C CNN
	1    7200 4450
	1    0    0    -1  
$EndComp
Wire Wire Line
	7200 4450 7200 4350
$Comp
L CP1 C?
U 1 1 57A24EBA
P 7650 4150
F 0 "C?" H 7783 4196 50  0000 L CNN
F 1 "100u" H 7783 4105 50  0000 L CNN
F 2 "" H 7650 4150 60  0000 C CNN
F 3 "" H 7650 4150 60  0000 C CNN
	1    7650 4150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR?
U 1 1 57A24F19
P 7650 4450
F 0 "#PWR?" H 7650 4200 60  0001 C CNN
F 1 "GND" H 7655 4269 60  0001 C CNN
F 2 "" H 7650 4450 60  0000 C CNN
F 3 "" H 7650 4450 60  0000 C CNN
	1    7650 4450
	1    0    0    -1  
$EndComp
Wire Wire Line
	7650 4450 7650 4350
$Comp
L +5V #PWR?
U 1 1 57A24F90
P 7650 3850
F 0 "#PWR?" H 7650 3700 60  0001 C CNN
F 1 "+5V" H 7665 4031 60  0000 C CNN
F 2 "" H 7650 3850 60  0000 C CNN
F 3 "" H 7650 3850 60  0000 C CNN
	1    7650 3850
	1    0    0    -1  
$EndComp
Wire Wire Line
	7650 3850 7650 3950
$EndSCHEMATC
