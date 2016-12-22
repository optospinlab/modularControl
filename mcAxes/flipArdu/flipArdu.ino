#include <Servo.h>

#define SERVOPIN    7
#define DUTYUP      750     % (µs)
#define DUTYDOWN    1500    % (µs)

Servo servo;

void setup() {
    Serial.begin(74880);        // Initialize serial (make sure the Baud rates are the same as MATLAB).
}

void loop() {
    if (Serial.available()){        // If MATLAB has something to say...
        typeByte = Serial.read();   // ...read it.
        
        servo.attach(SERVOPIN);                     // Turn on the servo.
        
        if (typeByte == '1'){                       // If that something is a command to move the mirror up...
            servo.writeMicroseconds(DUTYUP);        // ...Set the duty cycle to the appropriate value.
        }
        else if (typeByte == '0'){                  // Otherwise, if that something is a command to move the mirror down...
            servo.writeMicroseconds(DUTYDOWN);      // ...Set the duty cycle to the appropriate value.
        }
        
        delay(1000);                                // Then wait for a second for the servo to reach the desired position.
        
        servo.detach();                             // And turn off the servo so that it can be moved manually.
    }
}




