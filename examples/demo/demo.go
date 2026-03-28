package main

import (
	"machine"
	"time"

	"github.com/HattoriHanzo031/gotto/buzzer"
	"github.com/HattoriHanzo031/gotto/ninja"
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
	rollThrottle        = 55
	turnSpeed           = 40
	obstacleThresholdMm = 150
	turnDuration        = 700 * time.Millisecond
	sensorPollInterval  = 50 * time.Millisecond
)

func main() {
	time.Sleep(3 * time.Second)

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

	us := hcsr04.New(usTrigPin, usEchoPin)
	us.Configure()

	if err := n.Mode(ninja.ModeRoll); err != nil {
		panic(err)
	}

	for {
		if err := n.Roll(rollThrottle, 0); err != nil {
			panic(err)
		}

		for {
			dist := us.ReadDistance()
			if dist != 0 && dist < obstacleThresholdMm {
				if err := n.RollStop(); err != nil {
					panic(err)
				}

				_ = n.BuzzerTone(buzzer.Note{
					Period:   buzzer.A4,
					Duration: time.Second,
				})

				time.Sleep(100 * time.Millisecond)

				if err := n.Roll(0, turnSpeed); err != nil {
					panic(err)
				}

				time.Sleep(turnDuration)

				if err := n.RollStop(); err != nil {
					panic(err)
				}

				time.Sleep(200 * time.Millisecond)

				break
			}

			time.Sleep(sensorPollInterval)
		}
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
