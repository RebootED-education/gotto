package main

import (
	"machine"
	"time"

	"github.com/HattoriHanzo031/gotto/buzzer"
	"github.com/HattoriHanzo031/gotto/servo"
	"tinygo.org/x/drivers/hcsr04"
	tgservo "tinygo.org/x/drivers/servo"
)

var (
	pwmFoot   = machine.PWM2
	pwmLeg    = machine.PWM1
	pwmBuzzer = machine.PWM0

	rLegPin  = machine.P0_24
	lLegPin  = machine.P0_22
	rFootPin = machine.P0_20
	lFootPin = machine.P0_17

	usTrigPin = machine.P1_00
	usEchoPin = machine.P0_11

	buzzerPin = machine.P0_31
)

const (
	obstacleThresholdMm = 150
	sensorPollInterval  = 50 * time.Millisecond
)

func main() {
	time.Sleep(3 * time.Second)
	println("GOtto hardware diagnostic demo starting...")

	legArr := must(tgservo.NewArray(pwmLeg))
	footArr := must(tgservo.NewArray(pwmFoot))

	llServo := servo.New180(must(legArr.Add(lLegPin)), 450, 2550)
	rlServo := servo.New180(must(legArr.Add(rLegPin)), 450, 2550)
	lfServo := servo.New360(must(footArr.Add(lFootPin)), 450, 2550)
	rfServo := servo.New360(must(footArr.Add(rFootPin)), 450, 2550)

	bz := buzzer.New(buzzer.NewPwmChannel(pwmBuzzer, buzzerPin))
	if err := bz.Configure(); err != nil {
		panic(err)
	}

	println("Step 1/3: buzzer self-test")
	buzzerSelfTest(bz)

	println("Step 2/3: ultrasonic + buzzer interaction (bring an object within 15cm)")
	us := hcsr04.New(usTrigPin, usEchoPin)
	us.Configure()
	buzzerUltrasonicTest(bz, &us)

	println("Step 3/3: exercising legs and feet individually")
	testLegServo("Left Leg", llServo)
	testLegServo("Right Leg", rlServo)
	testFootServo("Left Foot", lfServo)
	testFootServo("Right Foot", rfServo)

	println("Diagnostics finished. Restart the board to rerun.")
	for {
		time.Sleep(time.Hour)
	}
}

// Helper to avoid boilerplate error handling in main
// Not recommended for production code
func must[T any](v T, err error) T {
	if err != nil {
		panic(err)
	}
	return v
}

func buzzerSelfTest(bz *buzzer.Buzzer) {
	sequence := []buzzer.Note{
		{Period: buzzer.A4, Duration: 200 * time.Millisecond},
		{Period: buzzer.C5, Duration: 200 * time.Millisecond},
		{Period: buzzer.E5, Duration: 200 * time.Millisecond},
		{Period: buzzer.A5, Duration: 300 * time.Millisecond},
		{Period: buzzer.Silence, Duration: 150 * time.Millisecond},
	}
	for i := 0; i < 2; i++ {
		for _, note := range sequence {
			_ = bz.Tone(note)
		}
		_ = bz.Tone(buzzer.Note{Period: buzzer.Silence, Duration: 250 * time.Millisecond})
	}
}

func buzzerUltrasonicTest(bz *buzzer.Buzzer, us *hcsr04.Device) {
	note := buzzer.Note{Period: buzzer.F4, Duration: 150 * time.Millisecond}
	rest := buzzer.Note{Period: buzzer.Silence, Duration: 100 * time.Millisecond}
	for i := 0; i < 120; i++ {
		if detectedObstacle(us) {
			_ = bz.Tone(note)
		} else {
			_ = bz.Tone(rest)
		}
	}
}

func testLegServo(label string, s servo.Servo180) {
	println(label, "servo sweep")
	angles := [...]int{90, 60, 120, 90}
	for _, angle := range angles {
		if err := s.SetAngle(angle); err != nil {
			println(label, "error:", err.Error())
			return
		}
		time.Sleep(700 * time.Millisecond)
	}
}

func testFootServo(label string, s servo.Servo360) {
	println(label, "speed sweep")
	speeds := [...]int{40, -40, 0}
	for _, speed := range speeds {
		if err := s.SetSpeed(speed); err != nil {
			println(label, "error:", err.Error())
			return
		}
		time.Sleep(800 * time.Millisecond)
	}
	_ = s.SetSpeed(0)
}

func detectedObstacle(us *hcsr04.Device) bool {
	dist := us.ReadDistance()
	return dist != 0 && dist < obstacleThresholdMm
}
