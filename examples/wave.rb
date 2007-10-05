# *****************************************************************************
# * Wave Simulation in OpenGL
# * (C) 2002 Jakob Thomsen
# * http://home.in.tum.de/~thomsen
# * Modified for GLFW by Sylvain Hellegouarch - sh@programmationworld.com
# * Modified for variable frame rate by Marcus Geelnard
# * 2003-Jan-31: Minor cleanups and speedups / MG
# *****************************************************************************/
# Converted to ruby from GLFW example wave.c
# Changed parameters to accomodate for ruby slowness

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw,Math

# Maximum delta T to allow for differential calculations
MAX_DELTA_T = 0.5

# Animation speed (10.0 looks good)
ANIMATION_SPEED = 10.0

$alpha = 210.0
$beta = -70.0
$zoom = 2.0

$running = true

class Vertex
	attr_accessor :x,:y,:z,:r,:g,:b
end

GRIDW = 50
GRIDH = 50
VERTEXNUM = GRIDW * GRIDH

QUADW = GRIDW - 1
QUADH = GRIDH - 1
QUADNUM = QUADW * QUADH

$quad = Array.new(4*QUADNUM,0)
$vertex = Array.new(VERTEXNUM).collect {Vertex.new}

# The grid will look like this:
#
#      3   4   5
#      *---*---*
#      |   |   |
#      | 0 | 1 |
#      |   |   |
#      *---*---*
#      0   1   2
#

def initVertices
  # place the vertices in a grid
	GRIDH.times do |y|
		GRIDW.times do |x|
			p = y*GRIDW + x
			$vertex[p].x = (x-GRIDW/2).to_f/(GRIDW/2).to_f
			$vertex[p].y = (y-GRIDH/2).to_f/(GRIDH/2).to_f
			$vertex[p].z = 0

      if((x%4<2)^(y%4<2))
				$vertex[p].r = 0.0
			else
				$vertex[p].r = 1.0
			end
			$vertex[p].g = y.to_f / GRIDH.to_f
      $vertex[p].b = 1.0 -(x.to_f/GRIDW.to_f + y.to_f/GRIDH.to_f)/2.0
		end
	end
	
	QUADH.times do |y|
		QUADW.times do |x|
			p = 4*(y*QUADW + x)

      # first quad
			$quad[p+0] = y     * GRIDW+x   # some point
			$quad[p+1] = y     * GRIDW+x+1 # neighbor at the right side
			$quad[p+2] = (y+1) * GRIDW+x+1 # upper right neighbor
			$quad[p+3] = (y+1) * GRIDW+x   # upper neighbor
		end
	end
end

$dt = 0
$p = Array.new(GRIDW).collect {Array.new(GRIDH,0.0)} # 2d array
$vx = Array.new(GRIDW).collect {Array.new(GRIDH,0.0)} 
$vy = Array.new(GRIDW).collect {Array.new(GRIDH,0.0)} 
$ax = Array.new(GRIDW).collect {Array.new(GRIDH,0.0)} 
$ay = Array.new(GRIDW).collect {Array.new(GRIDH,0.0)} 

def initSurface
	GRIDH.times do |y|
		GRIDW.times do |x|
			dx = (x-GRIDW/2).to_f
			dy = (y-GRIDH/2).to_f
			d = sqrt(dx*dx + dy*dy)
			if (d < 0.1 * (GRIDW/2).to_f)
				d = d * 10.0
				$p[x][y] = -cos(d * (PI / (GRIDW * 4).to_f)) * 100.0
			else
				$p[x][y] = 0.0
			end
			$vx[x][y] = 0.0
			$vy[x][y] = 0.0
		end
	end
end

# Draw view
def draw_screen
	# Clear the color and depth buffers.
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
	
	# We don't want to modify the projection matrix.
	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()
	
	# Move back.
	glTranslatef(0.0, 0.0, -$zoom)
	# Rotate the view
	glRotatef($beta, 1.0, 0.0, 0.0)
	glRotatef($alpha, 0.0, 0.0, 1.0)

	glBegin(GL_QUADS)
	$quad.each do |q|
		v = $vertex[q]
		glColor3f(v.r,v.g,v.b)
		glVertex3f(v.x,v.y,v.z)
	end
	glEnd()
	
	glfwSwapBuffers()
end

# Initialize OpenGL
def setup_opengl
  # Our shading model--Gouraud (smooth).
  glShadeModel(GL_SMOOTH)

  # Switch on the z-buffer.
  glEnable(GL_DEPTH_TEST)

  glEnableClientState(GL_VERTEX_ARRAY)
  glEnableClientState(GL_COLOR_ARRAY)
  glPointSize(2.0)

  # Background color is black.
  glClearColor(0, 0, 0, 0)
end

# Modify the height of each vertex according to the pressure.
def adjustGrid
	GRIDH.times do |y|
		GRIDW.times do |x|
			pos = y * GRIDW + x
			$vertex[pos].z = ($p[x][y]*(1.0/50.0)).to_f
		end
	end
end

# Calculate wave propagation 
def calc
	time_step = $dt * ANIMATION_SPEED

  # compute accelerations
	GRIDW.times do |x|
		x2 = (x + 1) % GRIDW
		GRIDH.times do |y|
			$ax[x][y] = $p[x][y] - $p[x2][y]
		end
	end
	
	GRIDH.times do |y|
		y2 = (y + 1) % GRIDH
		GRIDW.times do |x|
			$ay[x][y] = $p[x][y] - $p[x][y2]
		end
	end

  # compute speeds
	GRIDW.times do |x|
		GRIDH.times do |y|
			$vx[x][y] = $vx[x][y] + $ax[x][y] * time_step
			$vy[x][y] = $vy[x][y] + $ay[x][y] * time_step
		end
	end

	# compute pressure
	GRIDW.times do |x|
		x2 = x - 1
		GRIDH.times do |y|
			y2 = y - 1
      $p[x][y] = $p[x][y] + ($vx[x2][y] - $vx[x][y] + $vy[x][y2] - $vy[x][y]) * time_step
		end
	end
end

# Handle key strokes
handle_key_down = lambda do |key,action|
	if (action != GLFW_PRESS)
		next
	end
	
	case key
	when GLFW_KEY_ESC: $running = false
	when GLFW_KEY_SPACE: initSurface()
	when GLFW_KEY_LEFT: $alpha += 5
	when GLFW_KEY_RIGHT: $alpha -= 5
	when GLFW_KEY_UP: $beta -= 5
	when GLFW_KEY_DOWN: $beta += 5
	when GLFW_KEY_PAGEUP: $zoom -= 1 if $zoom > 1
	when GLFW_KEY_PAGEDOWN: $zoom += 1
	end
end

# Callback function for window resize events
handle_resize = lambda do |width,height|
	ratio = 1.0
	
	if ( height > 0 )
			ratio = width.to_f / height.to_f
	end
	
	# Setup viewport (Place where the stuff will appear in the main window).
	glViewport(0, 0, width, height)

	# Change to the projection matrix and set
	# our viewing volume.
	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	gluPerspective(60.0, ratio, 1.0, 1024.0)
end

# Program entry point
width  = 640
height = 480
mode   = GLFW_WINDOW

# Open window */
if( glfwOpenWindow(width,height,0,0,0,0,16,0,mode) == GL_FALSE )
	puts "Could not open window"
	exit
end

# Set title
glfwSetWindowTitle( "Wave Simulation" )

# Keyboard handler
glfwSetKeyCallback( handle_key_down )
glfwEnable( GLFW_KEY_REPEAT )

# Window resize handler
glfwSetWindowSizeCallback( handle_resize )


# Initialize OpenGL
setup_opengl()

# Initialize simulation
initVertices()
initSurface()
adjustGrid()
	
# Initialize timer
t_old = glfwGetTime() - 0.01

# Main loop
while $running
	# Timing
	t = glfwGetTime()
	dt_total = t - t_old
	t_old = t

	# Safety - iterate if dt_total is too large
	while( dt_total > 0.0 )
		# Select iteration time step
		$dt = dt_total > MAX_DELTA_T ? MAX_DELTA_T : dt_total
		dt_total -= $dt

		# Calculate wave propagation
		calc()
	end

	# Compute height of each vertex
	adjustGrid()
	
	# Draw wave grid to OpenGL display
	draw_screen()

	# Still running?
	$running = $running && glfwGetWindowParam( GLFW_OPENED )
end
