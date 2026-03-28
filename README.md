# GOtto Ninja Robot

A TinyGo port of the Otto ninja robot project, designed to be a fun and educational robotics programming experience.

## Overview

This project brings the beloved Otto ninja robot to the TinyGo ecosystem, allowing developers to program their robot using Go instead of traditional Arduino C++. Perfect for those interested in robotics, embedded programming, and learning TinyGo.

## Features

- Full Otto ninja robot functionality implemented in TinyGo
- Compatible with NiceNano microcontroller
- Modular code structure for easy customization
- Multiple example programs included
- Support for servo control, sensors, and robotic movements

## Hardware Requirements

- Otto ninja robot kit
- NiceNano microcontroller (replaces original Arduino)
- USB cable for programming and power
- Assembled robot following Otto ninja documentation

## Installation

### Prerequisites

#### One-line installer (Linux)

Run the following command to install Go, TinyGo, required build tools, and udev rules in a single step (works on Debian/Ubuntu, Fedora, and Arch-based distributions). You can override versions by prefixing `GO_VERSION=...` or `TINYGO_VERSION=...`.

```bash
curl -fsSL https://raw.githubusercontent.com/RebootED-education/gotto/main/scripts/install_toolchain.sh | bash
```

#### Install the Go toolset (Linux)

1. Install the base build tools and ARM dependencies (Debian/Ubuntu example):
   ```bash
   sudo apt update
   sudo apt install -y build-essential git wget tar clang gcc-arm-none-eabi libnewlib-arm-none-eabi
   ```

2. Download and install the latest Go toolchain (provides `go`, `gofmt`, etc.). Replace the version if a newer release is available:
   ```bash
   export GO_VERSION=1.22.4
   wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
   sudo rm -rf /usr/local/go
   sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
   echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.profile
   source ~/.profile
   go version
   ```

#### Install TinyGo (Linux)

1. Fetch and unpack the TinyGo release archive:
   ```bash
   export TINYGO_VERSION=0.32.0
   wget https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz
   sudo rm -rf /usr/local/tinygo
   sudo tar -C /usr/local -xzf tinygo${TINYGO_VERSION}.linux-amd64.tar.gz
   echo 'export PATH=/usr/local/tinygo/bin:$PATH' >> ~/.profile
   source ~/.profile
   tinygo version
   ```

2. Install the provided udev rules so the NiceNano can be flashed without sudo:
   ```bash
   sudo cp /usr/local/tinygo/udev/99-tinygo.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```
   Unplug and reconnect the board after applying the rules.

#### Clone the repository

1. ```bash
   git clone <repository-url>
   cd gotto
   ```

2. Install the Go + TinyGo toolchain in one step (works on Debian/Ubuntu, Fedora, and Arch families):
   ```bash
   ./scripts/install_toolchain.sh
   ```

### Hardware Setup

1. Assemble your Otto ninja robot according to the [original documentation](https://www.ottodiy.com/)
2. Replace the original microcontroller with a NiceNano board
3. Note the pin configurations for motors, sensors, and other components
4. Connect the robot to your computer via USB cable

## Usage

### Basic Setup

1. Navigate to the examples directory:
   ```bash
   cd examples
   ```

2. Choose an example program (e.g., `demo/demo.go`)

3. Update the pin configuration in the code to match your robot's wiring

4. Flash the code to your robot:
   ```bash
   tinygo flash -target nicenano
   ```

5. Power on the robot and watch it come to life!

## Motor Trimming

Before using your robot for complex movements, it's important to calibrate (trim) the servos for optimal performance. Servo motors can have slight variations in their zero positions and speeds, which can cause the robot to walk unevenly or tilt.

### Using the Trim Tool

1. Flash the trimming program to your robot:
   ```bash
   cd examples/trim
   tinygo flash -target nicenano
   ```

2. Open a serial monitor to communicate with the robot:
   ```bash
   tinygo monitor
   ```

3. Use the following commands to adjust your robot's movement:

#### Leg Angle Adjustments
- `ll+` / `ll-` - Increase/decrease left leg angle trim
- `rl+` / `rl-` - Increase/decrease right leg angle trim

#### Foot Speed Adjustments  
- `lf+` / `lf-` - Increase/decrease left foot speed trim
- `rf+` / `rf-` - Increase/decrease right foot speed trim

#### Balance Adjustments
- `tilt+` / `tilt-` - Increase/decrease tilt angle for balance

#### Testing Commands
- `walk` - Switch to walk mode for testing
- `roll` - Switch to roll mode for testing  
- `demo` - Run a full movement demonstration
- `reset` - Reset all trim values to zero

### Trimming Process

1. Start with the robot in a neutral standing position
2. Test walking and observe any tilting or uneven movement
3. If the robot does not lean enough or leans too much while walking, adjust the tilt angle using `tilt+` or `tilt-`
4. If in walking mode legs don't lay flat on the surface, adjust the leg angles with `ll+`/`ll-` or `rl+`/`rl-`
5. If the robot curves while walking, adjust foot speeds with `lf+`/`lf-` or `rf+`/`rf-`
6. Test frequently using the `walk` command to see your adjustments
7. Once satisfied, note down your trim values for use in other programs

The trim values you determine can be applied to other programs by setting them in the `ninja.Trim` struct before calling `n.Trim(trim)`.

## Examples

The project includes several example programs:

- **`demo/`** - Basic robot demonstration
- **`buzzer/`** - Sound and buzzer control
- **`obstacle_avoidance/`** - Autonomous navigation
- **`remote/`** - Bluetooth remote control functionality
- **`trim/`** - Servo calibration and trimming

## Project Structure

```
├── buzzer/           # Buzzer and sound control
├── examples/         # Example programs
├── ninja/           # Core robot functionality
├── remote/          # Remote control features
├── servo/           # Servo motor control
├── go.mod          # Go module definition
└── README.md       # This file
```

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests to help improve this project.
