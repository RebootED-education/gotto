package main

import (
	"machine"
	"time"

	"github.com/HattoriHanzo031/gotto/buzzer"
	"github.com/HattoriHanzo031/gotto/ninja"
	"github.com/HattoriHanzo031/gotto/servo"
	tgservo "tinygo.org/x/drivers/servo"
)

var (
	pwmFoot   = machine.PWM2
	pwmLeg    = machine.PWM1
	pwmBuzzer = machine.PWM0

	rLeg  = machine.P0_24
	lLeg  = machine.P0_22
	rFoot = machine.P0_20
	lFoot = machine.P0_17

	usTrig = machine.P1_00
	usEcho = machine.P0_11

	buzzerPin = machine.P0_31
)

func main() {
	time.Sleep(3 * time.Second)

	legArr := must(tgservo.NewArray(pwmLeg))
	footArr := must(tgservo.NewArray(pwmFoot))

	llServo := servo.New180(must(legArr.Add(lLeg)), 450, 2550)
	rlServo := servo.New180(must(legArr.Add(rLeg)), 450, 2550)
	lfServo := servo.New360(must(footArr.Add(lFoot)), 450, 2550)
	rfServo := servo.New360(must(footArr.Add(rFoot)), 450, 2550)

	bz := buzzer.New(buzzer.NewPwmChannel(pwmBuzzer, buzzerPin))
	if err := bz.Configure(); err != nil {
		panic(err)
	}

	n := ninja.New(rlServo, llServo, rfServo, lfServo, bz)

	n.Trim(ninja.Trim{
		TiltAngle:         0,
		LeftStepDuration:  0,
		RightStepDuration: 150 * time.Millisecond,
		LfSpeed:           0,
		RfSpeed:           0,
		LlAngle:           20,
		RlAngle:           12,
	})

	for {
		n.Mode(ninja.ModeWalk)
		time.Sleep(time.Second)

		n.Wave()
		time.Sleep(time.Second)

		n.RightLegSpin(30, 3*time.Second)
		time.Sleep(time.Second)

		n.Mode(ninja.ModeRoll)
		n.Roll(50, 100)
		time.Sleep(2 * time.Second)
		n.Roll(0, 0)
		time.Sleep(time.Second)
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
