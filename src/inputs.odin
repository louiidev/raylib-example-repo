package main
import rl "vendor:raylib"

MouseButton :: rl.MouseButton
GamepadButton :: rl.GamepadButton
KeyboardKey :: rl.KeyboardKey

Inputs :: struct {
	// consumed this frame
	mouse_down_consumed, mouse_pressed_consumed, mouse_released_consumed, mouse_up_consumed: [MouseButton]bool,
	key_down_consumed, key_pressed_consumed, key_released_consumed, key_up_consumed:         [MouseButton]bool,
}
inputs: Inputs

// IsKeyPressed   	   :: proc(key: KeyboardKey) -> bool 
// IsKeyPressedRepeat :: proc(key: KeyboardKey) -> bool --- // Check if a key has been pressed again
// IsKeyDown      	   :: proc(key: KeyboardKey) -> bool --- // Detect if a key is being pressed
// IsKeyReleased  	   :: proc(key: KeyboardKey) -> bool --- // Detect if a key has been released once
// IsKeyUp        	   :: proc(key: KeyboardKey) -> bool --- // Detect if a key is NOT being pressed
// GetKeyPressed  	   :: proc() -> KeyboardKey ---          // Get key pressed (keycode), call it multiple times for keys queued
// GetCharPressed 	   :: proc() -> rune ---                 // Get char pressed (unicode), call it multiple times for chars queued
// SetExitKey     	   :: proc(key: KeyboardKey) ---         // Set a custom key to exit program (default is ESC)

// Input-related functions: gamepads

// IsGamepadAvailable :: proc(gamepad: c.int) -> bool --- // Check if a gamepad is available
// GetGamepadName :: proc(gamepad: c.int) -> cstring --- // Get gamepad internal name id
// IsGamepadButtonPressed :: proc(gamepad: c.int, button: GamepadButton) -> bool --- // Check if a gamepad button has been pressed once
// IsGamepadButtonDown :: proc(gamepad: c.int, button: GamepadButton) -> bool --- // Check if a gamepad button is being pressed
// IsGamepadButtonReleased :: proc(gamepad: c.int, button: GamepadButton) -> bool --- // Check if a gamepad button has been released once
// IsGamepadButtonUp :: proc(gamepad: c.int, button: GamepadButton) -> bool --- // Check if a gamepad button is NOT being pressed
// GetGamepadButtonPressed :: proc() -> GamepadButton --- // Get the last gamepad button pressed
// GetGamepadAxisCount :: proc(gamepad: c.int) -> c.int --- // Get gamepad axis count for a gamepad
// GetGamepadAxisMovement :: proc(gamepad: c.int, axis: GamepadAxis) -> f32 --- // Get axis movement value for a gamepad axis
// SetGamepadMappings :: proc(mappings: cstring) -> c.int --- // Set internal gamepad mappings (SDL_GameControllerDB)
// SetGamepadVibration :: proc(gamepad: c.int, leftMotor: f32, rightMotor: f32, duration: f32) --- // Set gamepad vibration for both motors (duration in seconds)


// Input-related functions: mouse

IsMouseButtonPressed :: proc(button: MouseButton) -> bool {
	if inputs.mouse_pressed_consumed[button] {
		return false
	}

	return rl.IsMouseButtonPressed(button)
}
IsMouseButtonDown :: proc(button: MouseButton) -> bool {
	if inputs.mouse_down_consumed[button] {
		return false
	}

	return rl.IsMouseButtonDown(button)
}
IsMouseButtonReleased :: proc(button: MouseButton) -> bool {
	if inputs.mouse_released_consumed[button] {
		return false
	}

	return rl.IsMouseButtonReleased(button)
}
IsMouseButtonUp :: proc(button: MouseButton) -> bool {
	if inputs.mouse_up_consumed[button] {
		return false
	}

	return rl.IsMouseButtonUp(button)
}


capture_mouse_pressed :: proc(button: MouseButton) {
	inputs.mouse_pressed_consumed[button] = true
}

capture_mouse_down :: proc(button: MouseButton) {
	inputs.mouse_down_consumed[button] = true
}


capture_mouse_released :: proc(button: MouseButton) {
	inputs.mouse_released_consumed[button] = true
}


capture_mouse_up :: proc(button: MouseButton) {
	inputs.mouse_up_consumed[button] = true
}


// IsKeyPressed :: proc(key: KeyboardKey) -> bool
// IsKeyPressedRepeat :: proc(key: KeyboardKey) -> bool --- // Check if a key has been pressed again
// IsKeyDown :: proc(key: KeyboardKey) -> bool --- // Detect if a key is being pressed
// IsKeyReleased :: proc(key: KeyboardKey) -> bool --- // Detect if a key has been released once
// IsKeyUp :: proc(key: KeyboardKey) -> bool --- // Detect if a key is NOT being pressed
