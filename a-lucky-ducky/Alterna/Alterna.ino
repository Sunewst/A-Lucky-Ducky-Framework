void setup() {
	Serial.begin(115200);
Serial.println("$4");
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
Serial.println("$9");
  digitalWrite(LED_BUILTIN, HIGH);  // turn the LED on (HIGH is the voltage level)
Serial.println("$11");
  delay(1000);                      // wait for a second
Serial.println("$13");
  digitalWrite(LED_BUILTIN, LOW);   // turn the LED off by making the voltage LOW
Serial.println("$15");
  delay(1000);                      // wait for a second
}
