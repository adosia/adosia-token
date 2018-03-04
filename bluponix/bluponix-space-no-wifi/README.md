# BluPonix Space v2.1 (no wifi)

Bluponix Space v2.1 is an open hardware platform enabling anyone to easily create a variety of useful personal plant watering and cultivation systems. 


# Supported Hardware:

- 12V 5W Submersible DC water pump (x2)

- water level sensor switch (x1)

- digital IO / external relay (x2)

- temperature sensor (x1)

- analog input (x1)

- RGB LED (x1)

- supply voltage headers - x2 each: Vin - 3.3V - 5V - GND



# Operating Modes (set using jumpers)

- Personal Hydroponics

- Personal Garden - mini-pumps + external relay* both trigger when soil moisture low

- Self-Watering Pot - Soil-Moisture Sensing

* external relay could be any arbitrary digital IO output



# Personal Hydroponics Mode A

- x2 mini-pumps + external digital IO #1 trigger on cycle

- water cycle is set to 30 seconds on / 90 seconds off

- digital IO #1 triggers HIGH when water level low is detected (useful for relay water reservoir refill)

- to enable Personal Hydroponics A, place a jumper connecting the analog input with the 5V power supply



# Personal Hydroponics Mode B

- x2 mini-pumps + external digital IO #1 trigger on cycle

- water cycle is set to 60 seconds on / 180 seconds off

- digital IO #1 triggers HIGH when water level low is detected (useful for relay water reservoir refill)

- to enable Personal Hydroponics B, short a jumper wire connecting the analog input with the GND pin