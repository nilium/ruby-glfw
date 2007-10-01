#========================================================================
# This is a small test application for GLFW.
# The program lists all available fullscreen video modes.
#========================================================================
# Converted to ruby from GLFW example listmodes.c

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw

dtmode = glfwGetDesktopMode()
puts "Desktop mode: #{dtmode.Width} x #{dtmode.Height} x #{dtmode.RedBits+dtmode.GreenBits+dtmode.BlueBits}\n\n"

modes = glfwGetVideoModes()
puts "Available modes:"
(modes.size).times do |i|
  printf( "%3d: %d x %d x %d\n", i,
				 modes[i].Width, modes[i].Height,
				 modes[i].RedBits+modes[i].GreenBits+modes[i].BlueBits)
end
