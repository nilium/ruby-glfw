#========================================================================
# This is a small test application for GLFW.
# The program uses a "split window" view, rendering four views of the
# same scene in one window (e.g. uesful for 3D modelling software). This
# demo uses scissors to separete the four different rendering areas from
# each other.
#
# (If the code seems a little bit strange here and there, it may be
#  because I am not a friend of orthogonal projections)
#========================================================================
# Converted to ruby from GLFW example splitview.c

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw,Math

#========================================================================
# Global variables
#========================================================================

# Mouse position
$xpos,$ypos = 0,0

# Window size
$width,$height = 0,0

# Active view: 0 = none, 1 = upper left, 2 = upper right, 3 = lower left,
# 4 = lower right
$active_view = 0

# Rotation around each axis
$rot_x,$rot_y,$rot_z = 0,0,0

# Do redraw?
$do_redraw = 1

#========================================================================
# DrawTorus() - Draw a solid torus (use a display list for the model)
#========================================================================

TORUS_MAJOR     = 1.5
TORUS_MINOR     =  0.5
TORUS_MAJOR_RES = 32
TORUS_MINOR_RES = 32

def DrawTorus
	$torus_list ||= 0 # static(class) variable, initialize or no-op if already initialized
	if ($torus_list==0)
		# Start recording displaylist
		$torus_list = glGenLists( 1 )
		glNewList( $torus_list, GL_COMPILE_AND_EXECUTE )
		
		# Draw torus
		twopi = 2.0 * PI;
		TORUS_MINOR_RES.times do |i|
			glBegin(GL_QUAD_STRIP)
			0.upto(TORUS_MAJOR_RES) do |j|
				1.downto(0) do |k|  # inclusive row
					s = (i + k) % TORUS_MINOR_RES + 0.5
					t = j % TORUS_MAJOR_RES

					# Calculate point on surface
					x = (TORUS_MAJOR+TORUS_MINOR*cos(s*twopi/TORUS_MINOR_RES))*cos(t*twopi/TORUS_MAJOR_RES)
					y = TORUS_MINOR * sin(s * twopi / TORUS_MINOR_RES);
					z = (TORUS_MAJOR+TORUS_MINOR*cos(s*twopi/TORUS_MINOR_RES))*sin(t*twopi/TORUS_MAJOR_RES)
					
					# Calculate surface normal
					nx = x - TORUS_MAJOR*cos(t*twopi/TORUS_MAJOR_RES)
					ny = y
					nz = z - TORUS_MAJOR*sin(t*twopi/TORUS_MAJOR_RES)
					scale = 1.0 / sqrt( nx*nx + ny*ny + nz*nz )
					nx *= scale
					ny *= scale
					nz *= scale
					
					glNormal3f( nx, ny, nz )
					glVertex3f( x, y, z )
				end
			end
			glEnd()
		end
		# Stop recording displaylist
		glEndList()
	else
		# Playback displaylist
		glCallList( $torus_list )
	end
end

#========================================================================
# DrawScene() - Draw the scene (a rotating torus)
#========================================================================
def DrawScene
	model_diffuse  = [1.0, 0.8, 0.8, 1.0]
	model_specular = [0.6, 0.6, 0.6, 1.0]
	model_shininess = 20.0
	
	glPushMatrix()
	
	# Rotate the object
	glRotatef( $rot_x*0.5, 1.0, 0.0, 0.0 )
	glRotatef( $rot_y*0.5, 0.0, 1.0, 0.0 )
	glRotatef( $rot_z*0.5, 0.0, 0.0, 1.0 )
	
	# Set model color (used for orthogonal views, lighting disabled)
	glColor4fv( model_diffuse )
	
	# Set model material (used for perspective view, lighting enabled)
	glMaterialfv( GL_FRONT, GL_DIFFUSE, model_diffuse )
	glMaterialfv( GL_FRONT, GL_SPECULAR, model_specular )
	glMaterialf(  GL_FRONT, GL_SHININESS, model_shininess )
	
	# Draw torus
	DrawTorus()
	
	glPopMatrix()
end

#========================================================================
# DrawGrid() - Draw a 2D grid (used for orthogonal views)
#========================================================================
def DrawGrid(scale,steps)
	glPushMatrix()
	
	# Set background to some dark bluish grey
	glClearColor( 0.05, 0.05, 0.2, 0.0)
	glClear( GL_COLOR_BUFFER_BIT )
	
	# Setup modelview matrix (flat XY view)
	glLoadIdentity()
	gluLookAt( 0.0, 0.0, 1.0,
						 0.0, 0.0, 0.0,
						 0.0, 1.0, 0.0 )
	
	# We don't want to update the Z-buffer
	glDepthMask( GL_FALSE )
	
	# Set grid color
	glColor3f( 0.0, 0.5, 0.5 )
	
	glBegin( GL_LINES )

	# Horizontal lines
	x = scale * 0.5 * (steps-1)
	y = -scale * 0.5 * (steps-1)
	steps.times do |i|
		glVertex3f( -x, y, 0.0 )
		glVertex3f( x, y, 0.0 )
		y += scale
	end
	
	# Vertical lines
	x = -scale * 0.5 * (steps-1)
	y = scale * 0.5 * (steps-1)
	steps.times do |i|
		glVertex3f( x, -y, 0.0 )
		glVertex3f( x, y, 0.0 )
		x += scale
	end	
	glEnd();
	
	# Enable Z-buffer writing again
	glDepthMask( GL_TRUE )
	
	glPopMatrix()
end

#========================================================================
# DrawAllViews()
#========================================================================
def DrawAllViews
	light_position = [0.0, 8.0, 8.0, 1.0]
	light_diffuse  = [1.0, 1.0, 1.0, 1.0]
	light_specular = [1.0, 1.0, 1.0, 1.0]
	light_ambient  = [0.2, 0.2, 0.3, 1.0]
	
	# Calculate aspect of window
	if( $height > 0 )
			aspect = $width.to_f / $height.to_f
	else
			aspect = 1.0
	end
	
	# Clear screen
	glClearColor( 0.0, 0.0, 0.0, 0.0)
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
	
	# Enable scissor test
	glEnable( GL_SCISSOR_TEST )
	
	# Enable depth test
	glEnable( GL_DEPTH_TEST )
	glDepthFunc( GL_LEQUAL )
	
	
	# ** ORTHOGONAL VIEWS **

	# For orthogonal views, use wireframe rendering
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )
	
	# Enable line anti-aliasing
	glEnable( GL_LINE_SMOOTH )
	glEnable( GL_BLEND )
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA )
	
	# Setup orthogonal projection matrix
	glMatrixMode( GL_PROJECTION )
	glLoadIdentity()
	glOrtho( -3.0*aspect, 3.0*aspect, -3.0, 3.0, 1.0, 50.0 )
	
	# Upper left view (TOP VIEW)
	glViewport( 0, $height/2, $width/2, $height/2 )
	glScissor( 0, $height/2, $width/2, $height/2 )
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	gluLookAt( 0.0, 10.0, 1e-3, # Eye-position (above)
						 0.0, 0.0, 0.0,   # View-point
						 0.0, 1.0, 0.0 )  # Up-vector
	DrawGrid( 0.5, 12 )
	DrawScene()

	# Lower left view (FRONT VIEW)
	glViewport( 0, 0, $width/2, $height/2 )
	glScissor( 0, 0, $width/2, $height/2 )
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	gluLookAt( 0.0, 0.0, 10.0, # Eye-position (in front of)
						 0.0, 0.0, 0.0,  # View-point
						 0.0, 1.0, 0.0 ) # Up-vector
	DrawGrid( 0.5, 12 )
	DrawScene()
	
	# Lower right view (SIDE VIEW)
	glViewport( $width/2, 0, $width/2, $height/2 )
	glScissor( $width/2, 0, $width/2, $height/2 )
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	gluLookAt( 10.0, 0.0, 0.0,    # Eye-position (to the right)
						 0.0, 0.0, 0.0,     # View-point
						 0.0, 1.0, 0.0 )    # Up-vector
	DrawGrid( 0.5, 12 )
	DrawScene()

	# Disable line anti-aliasing
	glDisable( GL_LINE_SMOOTH )
	glDisable( GL_BLEND )

	# ** PERSPECTIVE VIEW **
	
	# For perspective view, use solid rendering
	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL )
	
	# Enable face culling (faster rendering)
	glEnable( GL_CULL_FACE )
	glCullFace( GL_BACK )
	glFrontFace( GL_CW )
	
	# Setup perspective projection matrix
	glMatrixMode( GL_PROJECTION )
	glLoadIdentity()
	gluPerspective( 65.0, aspect, 1.0, 50.0 )
	
	# Upper right view (PERSPECTIVE VIEW)
	glViewport( $width/2, $height/2, $width/2, $height/2 )
	glScissor( $width/2, $height/2, $width/2, $height/2 )
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	gluLookAt( 3.0, 1.5, 3.0,  # Eye-position
						0.0, 0.0, 0.0,   # View-point
						0.0, 1.0, 0.0 )  # Up-vector
	
	# Configure and enable light source 1
	glLightfv( GL_LIGHT1, GL_POSITION, light_position )
	glLightfv( GL_LIGHT1, GL_AMBIENT, light_ambient )
	glLightfv( GL_LIGHT1, GL_DIFFUSE, light_diffuse )
	glLightfv( GL_LIGHT1, GL_SPECULAR, light_specular )
	glEnable( GL_LIGHT1 )
	glEnable( GL_LIGHTING )

	# Draw scene
	DrawScene()
	
	# Disable lighting
	glDisable( GL_LIGHTING )
	
	# Disable face culling
	glDisable( GL_CULL_FACE )
	
	# Disable depth test
	glDisable( GL_DEPTH_TEST )
	
	# Disable scissor test
	glDisable( GL_SCISSOR_TEST )

	# Draw a border around the active view
	if( $active_view > 0 && $active_view != 2 )
		glViewport( 0, 0, $width, $height )
		glMatrixMode( GL_PROJECTION )
		glLoadIdentity()
		glOrtho( 0.0, 2.0, 0.0, 2.0, 0.0, 1.0 )
		glMatrixMode( GL_MODELVIEW )
		glLoadIdentity()
		glColor3f( 1.0, 1.0, 0.6 )
		glTranslatef( ($active_view-1)&1, 1-($active_view-1)/2, 0.0 )
		glBegin( GL_LINE_STRIP )
			glVertex2i( 0, 0 )
			glVertex2i( 1, 0 )
			glVertex2i( 1, 1 )
			glVertex2i( 0, 1 )
			glVertex2i( 0, 0 )
		glEnd()
	end
end

#=======================================================================
# WindowSizeFun() - Window size callback function
#========================================================================

WindowSizeFun = lambda do |w,h|
    $width  = w
    $height = h > 0 ? h : 1
    $do_redraw = 1
end

#========================================================================
# WindowRefreshFun() - Window refresh callback function
#========================================================================

WindowRefreshFun = lambda do
	$do_redraw = 1
end


#========================================================================
# MousePosFun() - Mouse position callback function
#========================================================================

MousePosFun = lambda do |x,y|
	case $active_view
	when 1
		$rot_x += y - $ypos
		$rot_z += x - $xpos
		$do_redraw = 1
	when 3
		$rot_x += y - $ypos
		$rot_y += x - $xpos
		$do_redraw = 1
	when 4
		$rot_y += x - $xpos
		$rot_z += y - $ypos
		$do_redraw = 1
	else
		# Do nothing for perspective view, or if no view is selected
	end
	$xpos = x
	$ypos = y
end

#========================================================================
# MouseButtonFun() - Mouse button callback function
#========================================================================

MouseButtonFun = lambda do |button,action|
	# Button clicked?
	if( ( button == GLFW_MOUSE_BUTTON_LEFT ) && action == GLFW_PRESS )
		# Detect which of the four views was clicked
		$active_view = 1
		if( $xpos >= $width/2 )
			$active_view += 1
		end
		if( $ypos >= $height/2 )
			$active_view += 2
		end

	# Button released?
	elsif( button == GLFW_MOUSE_BUTTON_LEFT )
		# Deselect any previously selected view
		$active_view = 0
	end
	
	$do_redraw = 1
end

#========================================================================
# main()
#========================================================================

running = true

# Open OpenGL window
if( glfwOpenWindow( 500, 500, 0,0,0,0, 16,0, GLFW_WINDOW ) == false )
	exit
end

# Set window title
glfwSetWindowTitle( "Split view demo" )

# Enable sticky keys
glfwEnable( GLFW_STICKY_KEYS )

# Enable mouse cursor (only needed for fullscreen mode)
glfwEnable( GLFW_MOUSE_CURSOR )

# Disable automatic event polling
glfwDisable( GLFW_AUTO_POLL_EVENTS )

# Set callback functions
glfwSetWindowSizeCallback( WindowSizeFun )
glfwSetWindowRefreshCallback( WindowRefreshFun )
glfwSetMousePosCallback( MousePosFun )
glfwSetMouseButtonCallback( MouseButtonFun )

# Main loop
while running
	# Only redraw if we need to
	if( $do_redraw )
		# Draw all views
		DrawAllViews()
		
		# Swap buffers
		glfwSwapBuffers()
		
		$do_redraw = 0
		end
	
	# Wait for new events
	glfwWaitEvents()

	# Check if the ESC key was pressed or the window was closed
  running = (glfwGetKey( GLFW_KEY_ESC ) == GLFW_RELEASE) &&
             (glfwGetWindowParam( GLFW_OPENED ) == true)
end
