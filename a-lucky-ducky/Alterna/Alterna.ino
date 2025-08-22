void setup() {
	Serial.begin(115200);
Serial.println("$4$1");
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
Serial.println("$9$2");
  digitalWrite(LED_BUILTIN, HIGH);  // turn the LED on (HIGH is the voltage level)
Serial.println("$11$3");
  delay(3000);                      // wait for a second
Serial.println("$13$4");
  digitalWrite(LED_BUILTIN, LOW);   // turn the LED off by making the voltage LOW
Serial.println("$15$5");
  delay(3000);                      // wait for a second
}
