#include <Servo.h>

#define SERVOPIN    10
#define DUTYUP      950     // (µs)
#define DUTYDOWN    1750     // (µs)

//#define VERBOSE

Servo servo;
char typeByte;
int up = 0;

void setup() {
    Serial.begin(74880);                            // Initialize serial (make sure the Baud rates are the same as MATLAB).
}

void loop() {
    if (Serial.available()){                        // If MATLAB has something to say...
        typeByte = Serial.read();                   // ...read it.
        
//        Serial.write(typeByte);
        
        servo.attach(SERVOPIN);                     // Turn on the servo.
        
        if (typeByte == '1'){                       // If that something is a command to move the mirror up...
            servo.writeMicroseconds(DUTYUP);        // ...Set the duty cycle to the appropriate value.
            up = 1;
#ifdef VERBOSE
            Serial.write("Going up!\n");
#endif
        } else if (typeByte == '0'){                // Otherwise, if that something is a command to move the mirror down...
            servo.writeMicroseconds(DUTYDOWN);      // ...Set the duty cycle to the appropriate value.
            up = 0;
#ifdef VERBOSE
            Serial.write("Going down!\n");
#endif
        } 
        else if (typeByte == 'r'){                // If MATLAB wants to read the current position...
#ifdef VERBOSE
            Serial.write("We are currently:");
            if (up){
                Serial.write("    1 - UP\n");
            } else {
                Serial.write("    0 - DOWN\n");
            }
#else
            if (up){
                Serial.write("1");
            } else {
                Serial.write("0");
            }
#endif
        }
        
        if (typeByte != 'r'){
            delay(500);                             // Then wait for a second for the servo to reach the desired position.
        }
        
        servo.detach();                             // And turn off the servo so that it can be moved manually.
    }
}




