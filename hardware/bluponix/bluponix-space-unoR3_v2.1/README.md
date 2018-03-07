# BluPonix Space v2.1 (no wifi)

Bluponix Space v2.1 is part of an open hardware IO platform initiative to enable anyone to easily create a variety of useful personal plant watering and garden cultivation systems.

The Space v2.1 IO board is designed to be pin compatible with the popular open hardware Arduino Uno R3 microcomputer controller boards, commonly used for prototyping and hobby builds.


# Supported Hardware:

- Submersible DC Water Pumps - AND/OR - Solenoids - 12V/5W (x2 mix and match)

- Water level sensor switch (x1)

- Digital IO / external relay control (x2)

- Analog input / soil moisture sensor (x1)

- RGB LED (x1)

- Supply voltage headers - x2 each: Vin / 3.3V / 5V / GND



# Operating Modes (set using jumpers):

- Mode 1:  Hydroponics Parallel Watering

- Mode 2:  Hydroponics Alternate Watering

- Mode 3:  Soil Grow - Personal Garden

- Mode 3:  Soil Grow - Personal Garden

- Self-Watering Pot - Soil-Moisture Sensing



# Mode 1:  Hydroponics Parallel Watering:

- x2 water pumps (or solenoids) trigger in parallel on water cycle

- each pump water cycle is set to water 90 seconds on / 270 seconds off

- digital IO 1 triggers external relay 1 for the duration of both pump cycles

- digital IO 2 triggers external relay 2 when water level low is detected, in 90s increments, until water low is no longer detected

- to enable Mode 1, place a jumper connecting the analog input of the soil moisture sensor directly with the adjacent 5V power pin

<img src='./images/space_2.1_modeA.png' />
jumper connector placement shown in red
________________________________________________________________________________________________________________________________


# Mode 2:  Hydroponics Alternate Watering:

- x2 water pumps (or solenoids) alternate watering cycles

- each pump water cycle is set to water 90 seconds on / 270 seconds off

- digital IO 1 triggers external relay 1 for the duration of both pump cycles

- digital IO 2 triggers external relay 2 when water level low is detected, in 90s increments, until water low is no longer detected

- to enable Mode 2, short a jumper wire to connecting the analog input of the soil moisture sensor directly with any GND pin

<img src='./images/space_2.1_modeB.png' />
jumper wire short connection shown in red
________________________________________________________________________________________________________________________________


# Mode 3:  Soil Grow - Personal Garden:

- x2 water pumps (or solenoids) execute sequential watering cycles on soil moisture low

- each water pump is set to water for 90 seconds each before rechecking soil moisture to determine if watering cycle is sufficient

- digital IO 1 triggers external relay 1 for the duration of both pump cycles

- digital IO 2 triggers external relay 2 when water level low is detected, in 90s increments, until water low is no longer detected

- to enable Mode 3:  connect the moisture sensor (represented in blue below) and remove all jumpers

<img src='./images/space_2.1_modeC.png' />
moisture sensor connection shown in blue
________________________________________________________________________________________________________________________________


# Mode 4: Soil Grow - Self-Watering Pot / Small Grow:

- water pump 1 (or solenoid 1) triggers watering cycle in 10 seconds increments on sensing soil moisture low, repeating until moisture level reads good

- water pump 2 (or solenoid 2) triggers when low water level is detected, in 60s increments, until water low is no longer detected

- to enable Mode 4, connect the moisture sensor (blue) and place jumpers (represented in red below) on both digital IO input pins as shown below

<img src='./images/space_2.1_modeD.png' />
jumper wire connector placements shown in red - moisture sensor connection shown in blue
________________________________________________________________________________________________________________________________
