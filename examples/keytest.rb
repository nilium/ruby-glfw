#========================================================================
# This is a small test application for GLFW.
# Keyboard input test.
#========================================================================
# Converted to ruby from GLFW example keytest.c

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw

$running = true
$keyrepeat = false
$systemkeys = true

keyfun = lambda do |key,action|
	if action != GLFW_PRESS
		next
	end

	case key
	when GLFW_KEY_ESC
		puts "ESC => quit program"
		$running = false
	when GLFW_KEY_F1..GLFW_KEY_F25
		puts "F#{1 + key - GLFW_KEY_F1}"
  when GLFW_KEY_UP
		puts "UP"
  when GLFW_KEY_DOWN
		puts "DOWN"
  when GLFW_KEY_LEFT
		puts "LEFT"
  when GLFW_KEY_RIGHT
		puts "RIGHT"
  when GLFW_KEY_LSHIFT
		puts "LSHIFT"
  when GLFW_KEY_RSHIFT
		puts "RSHIFT"
  when GLFW_KEY_LCTRL
		puts "LCTRL"
  when GLFW_KEY_RCTRL
		puts "RCTRL"
  when GLFW_KEY_LALT
		puts "LALT"
  when GLFW_KEY_RALT
		puts "RALT"
  when GLFW_KEY_TAB
		puts "TAB"
  when GLFW_KEY_ENTER
		puts "ENTER"
  when GLFW_KEY_BACKSPACE
		puts "BACKSPACE"
  when GLFW_KEY_INSERT
		puts "INSERT"
  when GLFW_KEY_DEL
		puts "DEL"
  when GLFW_KEY_PAGEUP
		puts "PAGEUP"
  when GLFW_KEY_PAGEDOWN
		puts "PAGEDOWN"
  when GLFW_KEY_HOME
		puts "HOME"
  when GLFW_KEY_END
		puts "END"
	when GLFW_KEY_KP_0..GLFW_KEY_KP_9
		puts "KEYPAD #{key - GLFW_KEY_KP_0}"
	when GLFW_KEY_KP_DIVIDE
		puts "KEYPAD DIVIDE"
	when GLFW_KEY_KP_MULTIPLY
		puts "KEYPAD MULTIPLY"
	when GLFW_KEY_KP_SUBTRACT
		puts "KEYPAD SUBTRACT"
	when GLFW_KEY_KP_ADD
		puts "KEYPAD ADD"
	when GLFW_KEY_KP_DECIMAL
		puts "KEYPAD DECIMAL"
	when GLFW_KEY_KP_EQUAL
		puts "KEYPAD ="
	when GLFW_KEY_KP_ENTER
		puts "KEYPAD ENTER"
	when GLFW_KEY_SPACE
		puts "SPACE"
	when ?R
		if ($keyrepeat==false)
			glfwEnable(GLFW_KEY_REPEAT)
		else
			glfwDisable(GLFW_KEY_REPEAT)
		end
		$keyrepeat = !$keyrepeat
		puts "R => Key repeat: #{$keyrepeat ? 'ON' : 'OFF'}"
	when ?S
		if ($systemkeys==false)
			glfwEnable(GLFW_SYSTEM_KEYS)
		else
			glfwDisable(GLFW_SYSTEM_KEYS)
		end
		$systemkeys = !$systemkeys
		puts "S => System keys: #{$systemkeys ? 'ON' : 'OFF'}"
	else
		if (key.class == Fixnum && key>256)
			puts "???"
		else
			puts key.chr
		end
	end
	$stdout.flush
end


# main

# Open OpenGL window
if (glfwOpenWindow( 250,100, 0,0,0,0, 0,0, GLFW_WINDOW ) == false)
	exit
end

# Set key callback function
glfwSetKeyCallback( keyfun )

# Set tile
glfwSetWindowTitle( "Press some keys!" )

# Main loop
$running = true
while $running
	# Get time and mouse position
	t = glfwGetTime()

	# Get window size (may be different than the requested size)
	width,height = glfwGetWindowSize()
	height = height > 0 ? height : 1

	# Set viewport
	glViewport( 0, 0, width, height )

	# Clear color buffer
	glClearColor( 0.5+0.5*Math.sin(3.0*t), 0.0, 0.0, 0.0)
	glClear( GL_COLOR_BUFFER_BIT )

	# Swap buffers
	glfwSwapBuffers()
	
	# Check if the window was closed
	$running = ($running && glfwGetWindowParam( GLFW_OPENED ) == true)
end
