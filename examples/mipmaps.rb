#========================================================================
# This is a small test application for GLFW.
# The program shows texture loading with mipmap generation and trilienar
# filtering.
# Note: For OpenGL 1.0 compability, we do not use texture objects (this
# is no issue, since we only have one texture).
#========================================================================
# Converted to ruby from GLFW example mipmaps.c

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw

# Open OpenGL window
if( glfwOpenWindow( 640, 480, 0,0,0,0, 0,0, GLFW_WINDOW ) == false )
	exit
end

# Enable sticky keys
glfwEnable( GLFW_STICKY_KEYS )

# Disable vertical sync (on cards that support it)
glfwSwapInterval( 0 )

# Load texture from file, and build all mipmap levels. The
# texture is automatically uploaded to texture memory.
if( glfwLoadTexture2D( "mipmaps.tga", GLFW_BUILD_MIPMAPS_BIT ) == false )
	exit
end


# Use trilinear interpolation (GL_LINEAR_MIPMAP_LINEAR)
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                 GL_LINEAR_MIPMAP_LINEAR )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
								 GL_LINEAR )

# Enable texturing
glEnable( GL_TEXTURE_2D )

# Main loop
running = true
frames = 0
t0 = glfwGetTime()

while running
	# Get time and mouse position
	t = glfwGetTime()
	x,y = glfwGetMousePos()

	# Calculate and display FPS (frames per second)
	if( (t-t0) > 1.0 || frames == 0 )
		fps = frames.to_f / (t-t0)
		titlestr = sprintf("Trilinear interpolation (%.1f FPS)", fps )
		glfwSetWindowTitle( titlestr )
		t0 = t
		frames = 0
	end
	frames += 1

	# Get window size (may be different than the requested size)
	width,height = glfwGetWindowSize()
	height = height > 0 ? height : 1

	# Set viewport
	glViewport( 0, 0, width, height )

	# Clear color buffer
	glClearColor( 0.0, 0.0, 0.0, 0.0 )
	glClear( GL_COLOR_BUFFER_BIT )

	# Select and setup the projection matrix
	glMatrixMode( GL_PROJECTION )
	glLoadIdentity()
	gluPerspective( 65.0, width.to_f/height.to_f, 1.0, 50.0 )

	# Select and setup the modelview matrix
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	gluLookAt( 0.0,  3.0, -20.0,  # Eye-position
 						 0.0, -4.0, -11.0,  # View-point
						 0.0,  1.0,   0.0 ) # Up-vector

	# Draw a textured quad
	glRotatef( 0.05*x.to_f + t.to_f*5.0, 0.0, 1.0, 0.0 )
	glBegin( GL_QUADS )
		glTexCoord2f( -20.0,  20.0 )
		glVertex3f( -50.0, 0.0, -50.0 )
		glTexCoord2f(  20.0,  20.0 )
		glVertex3f(  50.0, 0.0, -50.0 )
		glTexCoord2f(  20.0, -20.0 )
		glVertex3f(  50.0, 0.0,  50.0 )
		glTexCoord2f( -20.0, -20.0 )
		glVertex3f( -50.0, 0.0,  50.0 )
	glEnd()
	
	# Swap buffers
	glfwSwapBuffers()
	
	# Check if the ESC key was pressed or the window was closed
	running = ( glfwGetKey( GLFW_KEY_ESC ) == GLFW_RELEASE &&
						  glfwGetWindowParam( GLFW_OPENED ) == true )
end
    