#*****************************************************************************
# Title:   GLBoing
# Desc:    Tribute to Amiga Boing.
# Author:  Jim Brooks  <gfx@jimbrooks.org>
#          Original Amiga authors were R.J. Mical and Dale Luck.
#          GLFW conversion by Marcus Geelnard
# Notes:   - 360' = 2*PI [radian]
#
#          - Distances between objects are created by doing a relative
#            Z translations.
#
#          - Although OpenGL enticingly supports alpha-blending,
#            the shadow of the original Boing didn't affect the color
#            of the grid.
#
#          - [Marcus] Changed timing scheme from interval driven to frame-
#            time based animation steps (which results in much smoother
#            movement)
#
# History of Amiga Boing:
#
# Boing was demonstrated on the prototype Amiga (codenamed "Lorraine") in
# 1985. According to legend, it was written ad-hoc in one night by
# R. J. Mical and Dale Luck. Because the bouncing ball animation was so fast
# and smooth, attendees did not believe the Amiga prototype was really doing
# the rendering. Suspecting a trick, they began looking around the booth for
# a hidden computer or VCR.
#****************************************************************************
# Converted to ruby from GLFW example boing.c

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw,Math

RADIUS          = 70.0
STEP_LONGITUDE  = 22.5 # 22.5 makes 8 bands like original Boing
STEP_LATITUDE   = 22.5

DIST_BALL       = (RADIUS * 2.0 + RADIUS * 0.1)

VIEW_SCENE_DIST = (DIST_BALL * 3.0+ 200.0) # distance from viewer to middle of boing area
GRID_SIZE       = (RADIUS * 4.5) # length (width) of grid
BOUNCE_HEIGHT   = (RADIUS * 2.1)
BOUNCE_WIDTH    = (RADIUS * 2.1)

SHADOW_OFFSET_X = -20.0
SHADOW_OFFSET_Y = 10.0
SHADOW_OFFSET_Z = 0.0

WALL_L_OFFSET   = 0.0
WALL_R_OFFSET   = 5.0

# Animation speed (50.0 mimics the original GLUT demo speed)
ANIMATION_SPEED = 50.0

# Maximum allowed delta time per physics iteration */
MAX_DELTA_T = 0.02


# Vertex type 
class Vertex
	attr_accessor :x,:y,:z
	def initialize
		@x = @y = @z = 0.0
	end
end

# Global vars
$deg_rot_y       = 0.0
$deg_rot_y_inc   = 2.0
$ball_x          = -RADIUS
$ball_y          = -RADIUS
$ball_x_inc      = 1.0
$ball_y_inc      = 2.0
# Draw ball, or its shadow
$drawBallHow = :DRAW_BALL
$t = 0.0
$t_old = 0.0
$dt = 0.0

#*****************************************************************************
#* Truncate a degree.
#*****************************************************************************
def TruncateDeg(deg)
	if ( deg >= 360.0 )
		return (deg - 360.0)
	else
		return deg
	end
end


#*****************************************************************************
#* Convert a degree (360-based) into a radian.
#* 360' = 2 * PI
#*****************************************************************************
def deg2rad( deg )
	deg / 360 * (2 * PI)
end

#*****************************************************************************
#* 360' sin().
#*****************************************************************************
def sin_deg( deg )
	sin( deg2rad( deg ) )
end

#*****************************************************************************
#* 360' cos().
#*****************************************************************************
def cos_deg( deg )
	cos( deg2rad( deg ) )
end

#*****************************************************************************
#* Compute a cross product (for a normal vector).
#*
#* c = a x b
#*****************************************************************************
def CrossProduct( a,b,c,n )
	u1 = b.x - a.x;
	u2 = b.y - a.y;
	u3 = b.y - a.z;
	
	v1 = c.x - a.x;
	v2 = c.y - a.y;
	v3 = c.z - a.z;
	
	n.x = u2 * v3 - v2 * v3;
	n.y = u3 * v1 - v3 * u1;
	n.z = u1 * v2 - v1 * u2;
end

#*****************************************************************************
#* Calculate the angle to be passed to gluPerspective() so that a scene
#* is visible.  This function originates from the OpenGL Red Book.
#*
#* Parms   : size
#*           The size of the segment when the angle is intersected at "dist"
#*           (ie at the outermost edge of the angle of vision).
#*
#*           dist
#*           Distance from viewpoint to scene.
#*****************************************************************************
def PerspectiveAngle( size,dist )
	radTheta = 2.0 * atan2( size / 2.0, dist )
	degTheta = (180.0 * radTheta) / PI
end

BOING_DEBUG = 0

#*****************************************************************************
#* init()
#*****************************************************************************
def init
	#
	# Clear background.
	#
	glClearColor( 0.55, 0.55, 0.55, 0.0 )
	
	glShadeModel( GL_FLAT )
end

#*****************************************************************************
#* display()
#*****************************************************************************
def display
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
	glPushMatrix()
	
	$drawBallHow = :DRAW_BALL_SHADOW
	DrawBoingBall()
	
	DrawGrid()
	
	$drawBallHow = :DRAW_BALL;
	DrawBoingBall()
	
	glPopMatrix()
	glFlush()
end


#*****************************************************************************
#* reshape()
#*****************************************************************************
reshape = lambda do |w,h|
	glViewport( 0, 0, w, h )
	
	glMatrixMode( GL_PROJECTION )
	glLoadIdentity()
	
	gluPerspective( PerspectiveAngle( RADIUS * 2, 200 ),
									w.to_f / h.to_f,
									1.0,
									VIEW_SCENE_DIST )
	
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	
	gluLookAt( 0.0, 0.0, VIEW_SCENE_DIST,#* eye
						 0.0, 0.0, 0.0,            #* center of vision
						 0.0, -1.0, 0.0 )         #* up vector
end

#*****************************************************************************
#* Draw the Boing ball.
#*
#* The Boing ball is sphere in which each facet is a rectangle.
#* Facet colors alternate between red and white.
#* The ball is built by stacking latitudinal circles.  Each circle is composed
#* of a widely-separated set of points, so that each facet is noticably large.
#*****************************************************************************
def DrawBoingBall
	glPushMatrix()
	glMatrixMode( GL_MODELVIEW )
	
	#
	# Another relative Z translation to separate objects.
	#
	glTranslatef( 0.0, 0.0, DIST_BALL )
	
	# Update ball position and rotation (iterate if necessary)
	dt_total = $dt
	while( dt_total > 0.0 )
		dt2 = dt_total > MAX_DELTA_T ? MAX_DELTA_T : dt_total
		dt_total -= dt2
		BounceBall( dt2 )
		$deg_rot_y = TruncateDeg( $deg_rot_y + $deg_rot_y_inc*(dt2*ANIMATION_SPEED) )
	end
	
	# Set ball position
	glTranslatef( $ball_x, $ball_y, 0.0 )
	
	#
	# Offset the shadow.
	#
	if ( $drawBallHow == :DRAW_BALL_SHADOW )
		glTranslatef( SHADOW_OFFSET_X,
				SHADOW_OFFSET_Y,
				SHADOW_OFFSET_Z )
	end

	#
	# Tilt the ball.
	#
	glRotatef( -20.0, 0.0, 0.0, 1.0 )
	
	#
	# Continually rotate ball around Y axis.
	#
	glRotatef( $deg_rot_y, 0.0, 1.0, 0.0 )

	#
	# Set OpenGL state for Boing ball.
	#
	glCullFace( GL_FRONT )
	glEnable( GL_CULL_FACE )
	glEnable( GL_NORMALIZE )
	
	#
	# Build a faceted latitude slice of the Boing ball,
	# stepping same-sized vertical bands of the sphere.
	#
	0.step(180-1,STEP_LONGITUDE) do |lon_deg|
		#
		# Draw a latitude circle at this longitude.
		#
		DrawBoingBallBand( lon_deg, lon_deg + STEP_LONGITUDE )
	end
	
	glPopMatrix()
end
	
#*****************************************************************************
#* Bounce the ball.
#*****************************************************************************
def BounceBall(dt)
	# Bounce on walls
	if ( $ball_x >  (BOUNCE_WIDTH/2 + WALL_R_OFFSET ) )
		 $ball_x_inc = -0.5 - 0.75 * rand()
		 $deg_rot_y_inc = -$deg_rot_y_inc
	end
	if ( $ball_x < -(BOUNCE_HEIGHT/2 + WALL_L_OFFSET) )
		 $ball_x_inc =  0.5 + 0.75 * rand()
		 $deg_rot_y_inc = -$deg_rot_y_inc
	end

	# Bounce on floor / roof
	if ( $ball_y >  BOUNCE_HEIGHT/2 )
		 $ball_y_inc = -0.75 - 1.0 * rand()
	end
	if ( $ball_y < -(BOUNCE_HEIGHT/2)*0.85 )
		 $ball_y_inc =  0.75 + 1.0 * rand()
	end
	
	# Update ball position
	$ball_x += $ball_x_inc * (dt*ANIMATION_SPEED)
	$ball_y += $ball_y_inc * (dt*ANIMATION_SPEED)

	#
	# Simulate the effects of gravity on Y movement.
	#
	if ( $ball_y_inc < 0 )
		sign = -1.0
	else
		sign = 1.0
	end
	
	deg = ($ball_y + BOUNCE_HEIGHT/2) * 90 / BOUNCE_HEIGHT
	deg = 80 if ( deg > 80 )
	deg = 10 if ( deg < 10 )

	$ball_y_inc = sign * 4.0 * sin_deg( deg.to_f )
end

#*****************************************************************************
#* Draw a faceted latitude band of the Boing ball.
#*
#* Parms:   long_lo, long_hi
#*          Low and high longitudes of slice, resp.
#*****************************************************************************
def DrawBoingBallBand( long_lo, long_hi )
	vert_ne = Vertex.new() # "ne" means south-east, so on
	vert_nw = Vertex.new() #
	vert_sw = Vertex.new() #
	vert_se = Vertex.new() #
	vert_norm = Vertex.new()

  @@colorToggle ||= false

	#
	# Iterate thru the points of a latitude circle.
	# A latitude circle is a 2D set of X,Z points.
	#
	0.step(360-STEP_LATITUDE, STEP_LATITUDE) do |lat_deg|
		#
		# Color this polygon with red or white.
		#
		if ( @@colorToggle )
			glColor3f( 0.8, 0.1, 0.1 )
		else
			glColor3f( 0.95, 0.95, 0.95 )
		end

		@@colorToggle = ! @@colorToggle
		
		#
		# Change color if drawing shadow.
		#
		if ( $drawBallHow == :DRAW_BALL_SHADOW )
			glColor3f( 0.35, 0.35, 0.35 )
		end
		
		#
		# Assign each Y.
		#
		vert_ne.y = vert_nw.y = cos_deg(long_hi) * RADIUS
		vert_sw.y = vert_se.y = cos_deg(long_lo) * RADIUS

		#
		# Assign each X,Z with sin,cos values scaled by latitude radius indexed by longitude.
		# Eg, long=0 and long=180 are at the poles, so zero scale is sin(longitude),
		# while long=90 (sin(90)=1) is at equator.
		#
		vert_ne.x = cos_deg( lat_deg                 ) * (RADIUS * sin_deg( long_lo + STEP_LONGITUDE ))
		vert_se.x = cos_deg( lat_deg                 ) * (RADIUS * sin_deg( long_lo                  ))
		vert_nw.x = cos_deg( lat_deg + STEP_LATITUDE ) * (RADIUS * sin_deg( long_lo + STEP_LONGITUDE ))
		vert_sw.x = cos_deg( lat_deg + STEP_LATITUDE ) * (RADIUS * sin_deg( long_lo                  ))
		
		vert_ne.z = sin_deg( lat_deg                 ) * (RADIUS * sin_deg( long_lo + STEP_LONGITUDE ))
		vert_se.z = sin_deg( lat_deg                 ) * (RADIUS * sin_deg( long_lo                  ))
		vert_nw.z = sin_deg( lat_deg + STEP_LATITUDE ) * (RADIUS * sin_deg( long_lo + STEP_LONGITUDE ))
		vert_sw.z = sin_deg( lat_deg + STEP_LATITUDE ) * (RADIUS * sin_deg( long_lo                  ))
		
		#
		# Draw the facet.
		#
		glBegin( GL_POLYGON )
		
		CrossProduct( vert_ne, vert_nw, vert_sw, vert_norm )
		glNormal3f( vert_norm.x, vert_norm.y, vert_norm.z )
		
		glVertex3f( vert_ne.x, vert_ne.y, vert_ne.z )
		glVertex3f( vert_nw.x, vert_nw.y, vert_nw.z )
		glVertex3f( vert_sw.x, vert_sw.y, vert_sw.z )
		glVertex3f( vert_se.x, vert_se.y, vert_se.z )
		
		glEnd()

		if BOING_DEBUG==1
			printf( "----------------------------------------------------------- \n" );
			printf( "lat = %f  long_lo = %f  long_hi = %f \n", lat_deg, long_lo, long_hi );
			printf( "vert_ne  x = %.8f  y = %.8f  z = %.8f \n", vert_ne.x, vert_ne.y, vert_ne.z );
			printf( "vert_nw  x = %.8f  y = %.8f  z = %.8f \n", vert_nw.x, vert_nw.y, vert_nw.z );
			printf( "vert_se  x = %.8f  y = %.8f  z = %.8f \n", vert_se.x, vert_se.y, vert_se.z );
			printf( "vert_sw  x = %.8f  y = %.8f  z = %.8f \n", vert_sw.x, vert_sw.y, vert_sw.z );
		end
	end
	
	#
	# Toggle color so that next band will opposite red/white colors than this one.
	#
	@@colorToggle = ! @@colorToggle
	
	#
	# This circular band is done.
	#
end

#*****************************************************************************
#* Draw the purple grid of lines, behind the Boing ball.
#* When the Workbench is dropped to the bottom, Boing shows 12 rows.
#*****************************************************************************
def DrawGrid
	rowTotal  = 12        # must be divisible by 2
	colTotal  = rowTotal  # must be same as rowTotal
	widthLine = 2.0       # should be divisible by 2
	sizeCell    = GRID_SIZE / rowTotal
	z_offset    = -40.0

	glPushMatrix()
	glDisable( GL_CULL_FACE )
	
	#
	# Another relative Z translation to separate objects.
	#
	glTranslatef( 0.0, 0.0, DIST_BALL )

	#
	# Draw vertical lines (as skinny 3D rectangles).
	#
	0.upto(colTotal) do |col|
	#
	# Compute co-ords of line.
	#
		xl = -GRID_SIZE / 2 + col * sizeCell
		xr = xl + widthLine
		
		yt =  GRID_SIZE / 2
		yb = -GRID_SIZE / 2 - widthLine
		
		glBegin( GL_POLYGON )
		
		glColor3f( 0.6, 0.1, 0.6 )               # purple
		
		glVertex3f( xr, yt, z_offset )       # NE
		glVertex3f( xl, yt, z_offset )       # NW
		glVertex3f( xl, yb, z_offset )       # SW
		glVertex3f( xr, yb, z_offset )       # SE
		
		glEnd()
	end

	#
	# Draw horizontal lines (as skinny 3D rectangles).
	#
	0.upto(rowTotal) do |row|
		#
		# Compute co-ords of line.
		#
		yt = GRID_SIZE / 2 - row * sizeCell
		yb = yt - widthLine
		
		xl = -GRID_SIZE / 2
		xr =  GRID_SIZE / 2 + widthLine
		
		glBegin( GL_POLYGON )
		
		glColor3f( 0.6, 0.1, 0.6 )               # purple
		
		glVertex3f( xr, yt, z_offset )       # NE
		glVertex3f( xl, yt, z_offset )       # NW
		glVertex3f( xl, yb, z_offset )       # SW
		glVertex3f( xr, yb, z_offset )       # SE
		
		glEnd()
	end
	
	glPopMatrix()
end


#======================================================================
# main()
#======================================================================

running = true

# Init GLFW
if( glfwOpenWindow( 400,400, 0,0,0,0, 16,0, GLFW_WINDOW ) == GL_FALSE)
	exit
end
glfwSetWindowTitle( "Boing (classic Amiga demo)" )
glfwSetWindowSizeCallback( reshape )
glfwEnable( GLFW_STICKY_KEYS )
glfwSwapInterval( 1 )
glfwSetTime( 0.0 )

init()

# Main loop
while running
	# Timing
	$t = glfwGetTime()
	$dt = $t - $t_old
	$t_old = $t
	
	# Draw one frame
	display()
	
	# Swap buffers
	glfwSwapBuffers()

	# Check if we are still running
	running = (glfwGetKey( GLFW_KEY_ESC ) == GL_FALSE) &&
						(glfwGetWindowParam( GLFW_OPENED ) == GL_TRUE)
	
end
