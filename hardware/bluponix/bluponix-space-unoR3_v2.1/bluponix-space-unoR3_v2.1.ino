#define USE_SERIAL Serial

int loop_delay = 30000;       // wait 30 seconds between executing each loop
int water_time = 30;          // time pump will turn on for each watering cycle increment
int digIO2_ontime = 60;       // time io2 will turn on when water low is detected (resevoir refill feature)
int wait_time = 1;            // how long to wait (in minutes) before sampling soil moisture again

// moisture senseor calibration data
const int ms_AIR = 750;                           // REPLACE with calibration Value_1  (value reading: open-air)
const int ms_H2O = 300;                           // REPLACE with calibration Value_2  (value reading: water-submerged)

int sensor_down_low = 0;                          // disconnected wire when below 20 or so
int sensor_down_high = 0;

int iv = (ms_AIR - ms_H2O)/10;                    // system defined variable for moisture level granularity
int current_soil_status = 0;

int soil_status_target = 6;                       // user-defined variable - default status soil moisture should be after watering
int soil_status_water = 4;                        // user-defined variable - default status soil moisture needs to decrease to before watering can start again

int soil_moisture_valA1 = 0;
int last_moisture_valA1 = 0;
int last_moisture_delta = 0;


int lastwatercheck = 0;
int lastwatercycle = 0;
int nowatercycle = 0;
int lowDeltaCount = 0;
int lowDeltaReset = 0;


int analogPin = A0;       // map to pin Arduino A0 for dual operation on Wemos D1 ver R1 + R2

int pumpPin1 = 2;        // B0
int pumpPin2 = 3;        // B1
int digIO1 = 4;          // B2
int levSwitch = 5;       // B3 Level Switch
int tempSens = 6;        // B4 Temp Sensor
int digIO2 = 7;          // B5
int LEDb = 8;            // B6 blue led output
int LEDg = 9;            // B7 green led outpu
int LEDr = 10;           // B8 red led output

int levVal = 0;          // variable to store water level value
int opmode = 0;          // set the default operating mode to 
int relay1_mode = 0;
int relay2_mode = 0;
int cycle = 0;
bool level_good = false;
bool reading;            // debug var


void led_display_moisture() {

  //USE_SERIAL.print("Soil Status: ");
  //USE_SERIAL.println(current_soil_status);
  
  switch (current_soil_status) {
    
    case 1:
      // very dry (yellow white)
      led_set(115,100,0);
      break;

    case 2:
      // dry (light yellow green)
      led_set(128,120,0);
      break;

    case 3:
      // semi moist (yellow green)
      led_set(255,255,0);
      break;

    case 4:
      // 
      led_set(150,255,0);
      break;

    case 5:
      // 
      led_set(100,255,0);
      break;

    case 6 :
      // 
      led_set(50,255,0);
      break;

    case 7:
      // moist (green)
      led_set(0,255,0);
      break;

    case 8:
      // very moist (green blue)
      led_set(0,255,25);
      break;

    case 9:
      // wet (teal)
      led_set(5,255,85);
      break;

    case 10:
      // super wet (teal blue)
      led_set(25,255,150);
      break;

    default: 
      // if nothing else matches, do the default
      // default is optional
      // error value (red)
      led_set(255,0,0);
      
    break;
  }
  
}

void read_soil_moisture(int sensorPin) {   

  last_moisture_valA1 = soil_moisture_valA1;    
  
  USE_SERIAL.print("Moisture: ");
  // read twice
  soil_moisture_valA1 = analogRead(sensorPin);
  delay(100);
  soil_moisture_valA1 = analogRead(sensorPin);
  
  USE_SERIAL.print(soil_moisture_valA1);
  last_moisture_delta = last_moisture_valA1 - soil_moisture_valA1;
  USE_SERIAL.print(" (");
  USE_SERIAL.print(last_moisture_delta);
  USE_SERIAL.println(" delta)");

  // set current soil status
  current_soil_status = get_soil_status(soil_moisture_valA1);
  
}


int get_soil_status(int mval) {

  int mlevel;

  if (mval < (ms_H2O - 30) || mval < 200) {
    mlevel = 11;   // error
    sensor_down_low++;
  }
  
  else if (mval > 800) {
    mlevel = 0;
    sensor_down_high++;
  }
  
  else if (mval >= ms_H2O && mval < (ms_H2O + iv))
    mlevel = 10;   // super wet
  
  else if (mval >= (ms_H2O + iv) && mval < (ms_H2O + 2*iv))
    mlevel = 9;   // wet

  else if (mval >= (ms_H2O + 2*iv) && mval < (ms_H2O + 3*iv))
    mlevel = 8;   // very moist

  else if (mval >= (ms_H2O + 3*iv) && mval < (ms_H2O + 4*iv))
    mlevel = 7;   // moderate moist

  else if (mval >= (ms_H2O + 4*iv) && mval < (ms_H2O + 5*iv))
    mlevel = 6;   // moist

  else if (mval >= (ms_H2O + 5*iv) && mval < (ms_H2O + 6*iv))
    mlevel = 5;   // moist

  else if (mval >= (ms_H2O + 6*iv) && mval < (ms_H2O + 7*iv))
    mlevel = 4;   // semi-moist

  else if (mval >= (ms_H2O + 7*iv) && mval < (ms_H2O + 8*iv))
    mlevel = 3;   // semi-dry

  else if (mval >= (ms_H2O + 8*iv) && mval < (ms_H2O + 9*iv))
    mlevel = 2;   // dry
    
  else if (mval < (ms_AIR + 20)  && mval > (ms_AIR  - iv))
    mlevel = 1;   // very dry  

  else
    mlevel = 0;   // error


  return mlevel;
}


void water_now(int targPump, int targPump2, int watertime) {
    
  // turn pump on, water for x seconds and then stop pump
  USE_SERIAL.print(watertime);
  USE_SERIAL.println(" second water started...");
  

  digitalWrite(pumpPin1, HIGH);
  digitalWrite(pumpPin2, HIGH);

  led_set(LOW,LOW,HIGH);
  delay(watertime*1000);


  digitalWrite(pumpPin1, LOW);
  digitalWrite(pumpPin2, LOW);
  

  USE_SERIAL.println("watering stopped...");
}


void delay_function(int dely) {

  USE_SERIAL.print("start ");
  USE_SERIAL.print(dely);
  USE_SERIAL.println(" second delay");
  delay(dely*1000);
}


void led_dark() {
  digitalWrite(LEDr, LOW);
  digitalWrite(LEDg, LOW);
  digitalWrite(LEDb, LOW);
}


void led_set(int lr, int lg, int lb) {
  led_dark();
  digitalWrite(LEDr, lr);
  digitalWrite(LEDg, lg);
  digitalWrite(LEDb, lb);
}


void led_blink(int led, int bdelay, int btimes) {

  led_dark();
  
  for (int i = 0; i < btimes; i += 1) {
    digitalWrite(led, HIGH);
    delay(bdelay);
    digitalWrite(led, LOW);
    delay(bdelay);
  }
  
}


void led_mblink(int rval, int bval, int gval, int bdelay, int btimes) {

  for (int i = 0; i < btimes; i += 1) {
    analogWrite(LEDr, rval);
    analogWrite(LEDg, bval);
    analogWrite(LEDb, gval);
    delay(bdelay);
    analogWrite(LEDr, 0);
    analogWrite(LEDg, 0);
    analogWrite(LEDb, 0);
    delay(bdelay);
  }

}


bool check_water_level() {

  // check if water level is sufficient
  levVal = digitalRead(levSwitch);
  USE_SERIAL.print("Water Level LOW: ");
  USE_SERIAL.println(levVal);

  if (levVal == HIGH)
    return false;
 
  
  else
    return true;
   
}


void init_hydro_watercycle() {
  
  // water level is ok so we can water

  USE_SERIAL.println("------------------------------");
  USE_SERIAL.println("Initiate Water Cycle");

  led_set(LOW,LOW,HIGH);
  digitalWrite(digIO1, LOW);
  water_now(pumpPin1, pumpPin2, water_time);
  digitalWrite(digIO1, HIGH);
  led_set(LOW,HIGH,LOW);
}


void init_soil_watercycle() {
  
  // water level is ok so we can water

  USE_SERIAL.println("------------------------------");
  USE_SERIAL.println("Initiate Water Cycle Algs");
  
  read_soil_moisture(analogPin);
  USE_SERIAL.print("Moisture Level: ");
  USE_SERIAL.println(current_soil_status);
  
  led_display_moisture();
  
  if ( (current_soil_status == 0) || (current_soil_status == 11) ) {

    USE_SERIAL.print("ERROR - invalid moisture sensor reading: ");
    USE_SERIAL.println(soil_moisture_valA1);
    USE_SERIAL.print("ERROR - invalid moisture sensor status: ");
    USE_SERIAL.println(current_soil_status);
    
    // an error has occured with the moisture sensor
    led_blink(LEDr, 250, 20);
    led_set(255, 0, 255);
  }
  

  else {

      USE_SERIAL.print("Current Soil Status: ");
      USE_SERIAL.println(current_soil_status);
      USE_SERIAL.print("Target Soil Status: ");
      USE_SERIAL.println(soil_status_target);

    
      if (current_soil_status > soil_status_water) {
        
        nowatercycle++;
        
        if (nowatercycle > 5) { lastwatercycle = 0; }
        
        lastwatercheck = 0;         // set last watercheck to zero to wait one minute until recheck
      }

      else {
      
        while ( (current_soil_status < soil_status_target) && (lastwatercycle < 5) ) {

          if (last_moisture_delta < 10) { lowDeltaCount++; }
        
          if (lowDeltaCount <= 3) {

            if (opmode == 0) { digitalWrite(digIO1, LOW); }        // only switch digital output if soil mositure sensor is not in self-watering pot mode
            
            water_now(pumpPin1, pumpPin2, water_time);             // water for x seconds (can place any integer in here)
            
            if (opmode == 0) { digitalWrite(digIO1, HIGH); }       // only switch digital output if soil mositure sensor is not in self-watering pot mode
            
            // now wait 15 seconds and check sensor again to repeat watering if needed
            delay_function(15);

            // read now so we can detect delta
            read_soil_moisture(analogPin);
            led_display_moisture();

          }
          
        }

        lowDeltaCount = 0;

      } 

  }
}




void setup() {

  //WiFi.softAP(ssid, password, 1, 1);

  // initiate serial monitor
  if (!USE_SERIAL) { 
    USE_SERIAL.begin(9600);
    USE_SERIAL.println("Here we go:");
  }
  else {
    USE_SERIAL.begin(9600);
    USE_SERIAL.println("Here we went:");    
  }
  
  // put your setup code here, to run once:
  pinMode(pumpPin1, OUTPUT);
  pinMode(pumpPin2, OUTPUT);
  pinMode(tempSens, INPUT);     // we can't use internal pull-up resistor on tempSens as board won't boot when switch is shorted to ground on boot, we we use Space v
  pinMode(levSwitch, INPUT);    // can't use internal pull-up resistor on levSwitch as board won't boot when switch is shorted to ground on boot
  
  
  // read twice because
  opmode = analogRead(analogPin);
  delay(100);
  opmode = analogRead(analogPin);


  pinMode(digIO1, OUTPUT);
  pinMode(digIO2, OUTPUT);
  pinMode(LEDb, OUTPUT);
  pinMode(LEDg, OUTPUT);
  pinMode(LEDr, OUTPUT);

  digitalWrite(pumpPin1, LOW);
  digitalWrite(pumpPin2, LOW);
  
  digitalWrite(LEDb, HIGH);
  digitalWrite(LEDg, HIGH);
  digitalWrite(LEDr, HIGH);

  
  if (opmode > 1000) {
    // jumper detected shorting 5V to A0, which tells us we will not be operating with a soil moisture sensor
    USE_SERIAL.println("30s cycle hydroponics + relay mode initiated ");
    opmode = 2;
    // digIO1 relay-1 triggers with small 12V pumps on cycle (30 seconds on, 90 seconds off)
    // digIO2 relay-2 triggers on water level switch trigger low - to refill resevoir or perform alert
    // here we can operate two different hydroponic systems - one diven by the small pumps, and one driven by a larger relay
     digitalWrite(digIO1, HIGH);         // set relays in inital disabled position - high is off 
     digitalWrite(digIO2, HIGH);
  }
  else if (opmode < 10) {
    // jumper detected shorting 5V to A0, which tells us we will not be operating with a soil moisture sensor
    USE_SERIAL.println("90s cycle hydroponics + relay mode initiated");
    opmode = 2;
    water_time = 90;
    // digIO1 relay-1 triggers with small 12V pumps on cycle (30 seconds on, 90 seconds off)
    // digIO2 relay-2 triggers on water level switch trigger low - to refill resevoir or perform alert
    // here we can operate two different hydroponic systems - one diven by the small pumps, and one driven by a larger relay
    digitalWrite(digIO1, HIGH);         // set relays in inital disabled position - high is off 
    digitalWrite(digIO2, HIGH);
  }
  else
  {
    // we are using the moisture sensor
    
    // we need to see if we are operating in self-watering pot mode or relay grow mode);
    relay1_mode = digitalRead(digIO1);
    relay2_mode = digitalRead(digIO2);

    if (relay1_mode == HIGH && relay2_mode == HIGH) {
        USE_SERIAL.println("soil moisture self-watering pot mode initiated...");
        opmode = 0;       // self-watering pot mode
        water_time = 10;  // need to reduce watering time
        // digIO1 + digIO2 idle
    }

    else {
        opmode = 1;    // relay grow mode - digIO1 relay-1 triggers with small 12V pumps on soil moisture low detect
        USE_SERIAL.println("soil moisture relay grow mode initiated...");
        // digIO2 relay-2 triggers on water level switch trigger low - to refill resevoir or perform alert
        digitalWrite(digIO1, HIGH);         // set relays in inital disabled position - high is off 
        digitalWrite(digIO2, HIGH);
    }
  
  }



  USE_SERIAL.print("Operating Mode: ");
  USE_SERIAL.println(opmode);

  read_soil_moisture(analogPin);
  
}



void loop() {

  level_good = check_water_level();

  if (level_good) {
 
    if (opmode == 0 || opmode == 1) {

        USE_SERIAL.print("Loop ");
        USE_SERIAL.print(lastwatercheck);
        USE_SERIAL.print(" Start: ");
        USE_SERIAL.println();

        led_display_moisture();

        if (lastwatercheck > wait_time) {
          lastwatercheck = 0;               // set last watercheck to zero
          init_soil_watercycle();           // initiate water cycle algs  
        }

        // end watercheck cycle loop
        lastwatercheck++;
    }
 
    else if (opmode == 2) {

      USE_SERIAL.print("Loop ");
      USE_SERIAL.print(cycle);
      USE_SERIAL.print(" Start - ");
      
      USE_SERIAL.println("hydroponics cycle:");

      // here a cycle parameter is used to determoine a hard-coded cycle of 30 seconds on / 90 seconds off (25% duty on over 2 minute period)
      // TODO - implement a config var for adjusting water on/off cycle / not an issue in WiFi (Space 2.2)
      
      if (cycle == 0) {
         // initiate water cycle algs
        init_hydro_watercycle();
      }
      cycle++;                            
  
      if (cycle == 3) { cycle = 0; }        // reset cycle
      
   }

  }
  else {
    
      led_blink(LEDb, 500, 10);

      if (opmode == 1 || opmode == 2) {

          led_set(HIGH, LOW, HIGH);

          // try refill resevoir
          USE_SERIAL.println("Refilling resevoir...");
          
          digitalWrite(digIO2, LOW);      // enable io2 relay
          delay(digIO2_ontime*1000);
          digitalWrite(digIO2, HIGH);      // disable io2 relay

          if (opmode == 2) // hydro only mode
            led_set(LOW, HIGH, LOW);  

          else
            led_display_moisture();
            
      }
  
  }
  
  // wait 100ms for production
  delay(loop_delay);
}

