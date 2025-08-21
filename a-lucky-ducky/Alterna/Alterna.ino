// constants won't change. They're used here to set pin numbers:
const int buttonPin = 2;  // the number of the pushbutton pin
const int ledPin = 13;    // the number of the LED pin

// variables will change:
int buttonState = 0;  // variable for reading the pushbutton status

void setup() {
Serial.println('$11');
  // initialize the LED pin as an output:
  pinMode(ledPin, OUTPUT);
Serial.println('$14');
  // initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);

}

void loop() {
Serial.println('$21');
  // read the state of the pushbutton value:
  buttonState = digitalRead(buttonPin);

  // check if the pushbutton is pressed. If it is, the buttonState is HIGH:
  if (buttonState == HIGH) {
Serial.println('$27');
    // turn LED on:
    digitalWrite(ledPin, HIGH);
  } else {
Serial.println('$31');
    // turn LED off:
    digitalWrite(ledPin, LOW);
  }
}

