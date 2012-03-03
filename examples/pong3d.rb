#========================================================================
# This is a small test application for GLFW.
# This is an OpenGL port of the famous "PONG" game (the first computer
# game ever?). It is very simple, and could be improved alot. It was
# created in order to show off the gaming capabilities of GLFW.
#========================================================================
# Converted to ruby from GLFW example pong3d.c

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw,Math

#========================================================================
# Constants
#========================================================================

# Screen resolution
WIDTH  = 640
HEIGHT = 480

# Player size (units)
PLAYER_XSIZE = 0.05
PLAYER_YSIZE = 0.15

# Ball size (units)
BALL_SIZE = 0.02

# Maximum player movement speed (units / second)
MAX_SPEED   = 1.5

# Player movement acceleration (units / seconds^2)
ACCELERATION = 4.0

# Player movement deceleration (units / seconds^2)
DECELERATION = 2.0

# Ball movement speed (units / second)
BALL_SPEED  = 0.4

# Menu options
MENU_NONE  = 0
MENU_PLAY  = 1
MENU_QUIT  = 2

# Game events
NOBODY_WINS  = 0
PLAYER1_WINS = 1
PLAYER2_WINS = 2

# Winner ID
NOBODY      = 0
PLAYER1     = 1
PLAYER2     = 2

# Camera positions
CAMERA_CLASSIC   = 0
CAMERA_ABOVE     = 1
CAMERA_SPECTATOR = 2
CAMERA_DEFAULT   = CAMERA_CLASSIC

#========================================================================
# Textures
#========================================================================

TEX_TITLE    = 0
TEX_MENU     = 1
TEX_INSTR    = 2
TEX_WINNER1  = 3
TEX_WINNER2  = 4
TEX_FIELD    = 5
NUM_TEXTURES = 6

# Texture names
$tex_name = [
    "pong3d_title.tga",
    "pong3d_menu.tga",
    "pong3d_instr.tga",
    "pong3d_winner1.tga",
    "pong3d_winner2.tga",
    "pong3d_field.tga"
]

# OpenGL texture object IDs
$tex_id = []

#========================================================================
# Global variables
#========================================================================

# Display information
$width = $height = 0

# Frame information
$thistime = $oldtime = $dt = $starttime = 0.0

# Camera information
$camerapos = 0

# Player information
class Player
	attr_accessor :ypos,:yspeed
end

$player1 = Player.new
$player2 = Player.new

# Ball information
class Ball
	attr_accessor :xpos,:ypos
	attr_accessor :xspeed,:yspeed
end
$ball = Ball.new

# And the winner is...
$winner = 0

# Lighting configuration
$env_ambient     = [1.0,1.0,1.0,1.0]
$light1_position = [-3.0,3.0,2.0,1.0]
$light1_diffuse  = [1.0,1.0,1.0,0.0]
$light1_ambient  = [0.0,0.0,0.0,0.0]

# Object material properties
$player1_diffuse = [1.0,0.3,0.3,1.0]
$player1_ambient = [0.3,0.1,0.0,1.0]
$player2_diffuse = [0.3,1.0,0.3,1.0]
$player2_ambient = [0.1,0.3,0.1,1.0]
$ball_diffuse    = [1.0,1.0,0.5,1.0]
$ball_ambient    = [0.3,0.3,0.1,1.0]
$border_diffuse  = [0.3,0.3,1.0,1.0]
$border_ambient  = [0.1,0.1,0.3,1.0]
$floor_diffuse   = [1.0,1.0,1.0,1.0]
$floor_ambient   = [0.3,0.3,0.3,1.0]

#========================================================================
# LoadTextures() - Load textures from disk and upload to OpenGL card
#========================================================================

def LoadTextures
	# Generate texture objects
	$tex_id = glGenTextures( NUM_TEXTURES )
	
	# Load textures
	NUM_TEXTURES.times do |i|
		# Select texture object
		glBindTexture( GL_TEXTURE_2D, $tex_id[ i ] )
		
		# Set texture parameters
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT )
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT )
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR )
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR )
		
		# Upload texture from file to texture memory
		glfwLoadTexture2D( $tex_name[ i ], 0 )
	end
end


#========================================================================
# DrawImage() - Draw a 2D image as a texture
#========================================================================

def DrawImage(texnum,x1,x2,y1,y2)
	glEnable( GL_TEXTURE_2D )
	glBindTexture( GL_TEXTURE_2D, $tex_id[ texnum ] )
	glBegin( GL_QUADS )
		glTexCoord2f( 0.0, 1.0 )
		glVertex2f( x1, y1 )
		glTexCoord2f( 1.0, 1.0 )
		glVertex2f( x2, y1 )
		glTexCoord2f( 1.0, 0.0 )
		glVertex2f( x2, y2 )
		glTexCoord2f( 0.0, 0.0 )
		glVertex2f( x1, y2 )
	glEnd()
	glDisable( GL_TEXTURE_2D )
end

#========================================================================
# GameMenu() - Game menu (returns menu option)
#========================================================================

def GameMenu
	option = MENU_NONE

	# Enable sticky keys
	glfwEnable( GLFW_STICKY_KEYS );
	
	# Wait for a game menu key to be pressed
	while option == MENU_NONE
		# Get window size
		$width,$height = glfwGetWindowSize()

		# Set viewport
		glViewport( 0, 0, $width, $height )
		
		# Clear display
		glClearColor( 0.0, 0.0, 0.0, 0.0 )
		glClear( GL_COLOR_BUFFER_BIT )
		
		# Setup projection matrix
		glMatrixMode( GL_PROJECTION )
		glLoadIdentity()
		glOrtho( 0.0, 1.0, 1.0, 0.0, -1.0, 1.0 )
		
		# Setup modelview matrix
		glMatrixMode( GL_MODELVIEW )
		glLoadIdentity()
		
		# Display title
		glColor3f( 1.0, 1.0, 1.0 )
		DrawImage( TEX_TITLE, 0.1, 0.9, 0.0, 0.3 )
		
		# Display menu
		glColor3f( 1.0, 1.0, 0.0 )
		DrawImage( TEX_MENU, 0.38, 0.62, 0.35, 0.5 )
		
		# Display instructions
		glColor3f( 0.0, 1.0, 1.0 )
		DrawImage( TEX_INSTR, 0.32, 0.68, 0.65, 0.85 )
		
		# Swap buffers
		glfwSwapBuffers()

		# Check for keys
		if( glfwGetKey( ?Q ) == GLFW_PRESS || glfwGetWindowParam( GLFW_OPENED ) == false )
			option = MENU_QUIT
		elsif( glfwGetKey( GLFW_KEY_F1 ) == GLFW_PRESS )
			option = MENU_PLAY
		else
			option = MENU_NONE
		end
		
		# To avoid horrible busy waiting, sleep for at least 20 ms
		glfwSleep( 0.02 )
	end

	# Disable sticky keys
	glfwDisable( GLFW_STICKY_KEYS )
	
	return option
end
		
#========================================================================
# NewGame() - Initialize a new game
#========================================================================

def NewGame
    # Frame information
    $starttime = $thistime = glfwGetTime()

    # Camera information
    $camerapos = CAMERA_DEFAULT

    # Player 1 information
    $player1.ypos   = 0.0
    $player1.yspeed = 0.0

    # Player 2 information
    $player2.ypos   = 0.0
    $player2.yspeed = 0.0

    # Ball information
    $ball.xpos = -1.0 + PLAYER_XSIZE
    $ball.ypos = $player1.ypos
    $ball.xspeed = 1.0;
    $ball.yspeed = 1.0;
end

#========================================================================
# PlayerControl() - Player control
#========================================================================

def PlayerControl
	# Get joystick X & Y axis positions
	joy1pos = glfwGetJoystickPos( GLFW_JOYSTICK_1 )
	joy2pos = glfwGetJoystickPos( GLFW_JOYSTICK_2 )
	if (joy1pos == nil)
		joy1pos = [0.0,0.0]
	end
	if (joy2pos == nil)
		joy2pos = [0.0,0.0]
	end
	
	# Player 1 control
	if( glfwGetKey( ?A ) == GLFW_PRESS || joy1pos[ 1 ] > 0.2 )
		$player1.yspeed += $dt * ACCELERATION
		if( $player1.yspeed > MAX_SPEED )
			$player1.yspeed = MAX_SPEED
		end
	elsif( glfwGetKey( ?Z ) == GLFW_PRESS || joy1pos[ 1 ] < -0.2 )
		$player1.yspeed -= $dt * ACCELERATION
		if( $player1.yspeed < -MAX_SPEED )
			$player1.yspeed = -MAX_SPEED
		end
	else
		$player1.yspeed /= exp( DECELERATION * $dt )
	end
	
	# Player 2 control
	if( glfwGetKey( ?K ) == GLFW_PRESS || joy2pos[ 1 ] > 0.2 )
		$player2.yspeed += $dt * ACCELERATION
		if( $player2.yspeed > MAX_SPEED )
			$player2.yspeed = MAX_SPEED
		end
	elsif( glfwGetKey( ?M ) == GLFW_PRESS || joy2pos[ 1 ] < -0.2 )
		$player2.yspeed -= $dt * ACCELERATION
		if( $player2.yspeed < -MAX_SPEED )
			$player2.yspeed = -MAX_SPEED
		end
	else
		$player2.yspeed /= exp( DECELERATION * $dt )
	end	

	# Update player 1 position
	$player1.ypos += $dt * $player1.yspeed
	if( $player1.ypos > 1.0 - PLAYER_YSIZE )
		$player1.ypos = 1.0 - PLAYER_YSIZE
		$player1.yspeed = 0.0
	elsif ( $player1.ypos < -1.0 + PLAYER_YSIZE )
		$player1.ypos = -1.0 + PLAYER_YSIZE;
		$player1.yspeed = 0.0
	end
	
	# Update player 2 position
	$player2.ypos += $dt * $player2.yspeed
	if( $player2.ypos > 1.0 - PLAYER_YSIZE )
		$player2.ypos = 1.0 - PLAYER_YSIZE;
		$player2.yspeed = 0.0
	elsif( $player2.ypos < -1.0 + PLAYER_YSIZE )
		$player2.ypos = -1.0 + PLAYER_YSIZE;
		$player2.yspeed = 0.0
	end
end

#========================================================================
# BallControl() - Ball control
#========================================================================

def BallControl
	# Calculate new ball speed
	ballspeed = BALL_SPEED * (1.0 + 0.02*($thistime-$starttime))
	$ball.xspeed = $ball.xspeed > 0 ? ballspeed : -ballspeed
	$ball.yspeed = $ball.yspeed > 0 ? ballspeed : -ballspeed
	$ball.yspeed *= 0.74321
	
	# Update ball position
	$ball.xpos += $dt * $ball.xspeed
	$ball.ypos += $dt * $ball.yspeed
	
	# Did the ball hit a top/bottom wall?
	if( $ball.ypos >= 1.0 )
		$ball.ypos = 2.0 - $ball.ypos
		$ball.yspeed = -$ball.yspeed
	elsif( $ball.ypos <= -1.0 )
		$ball.ypos = -2.0 - $ball.ypos
		$ball.yspeed = -$ball.yspeed
	end

	# Did the ball hit/miss a player?
	event = NOBODY_WINS
	
	# Is the ball entering the player 1 goal?
	if( $ball.xpos < -1.0 + PLAYER_XSIZE )
		# Did player 1 catch the ball?
		if( $ball.ypos > ($player1.ypos-PLAYER_YSIZE) &&
		    $ball.ypos < ($player1.ypos+PLAYER_YSIZE) )
			$ball.xpos = -2.0 + 2.0*PLAYER_XSIZE - $ball.xpos
			$ball.xspeed = -$ball.xspeed
		else
			event = PLAYER2_WINS
		end
	end

	# Is the ball entering the player 2 goal?
	if( $ball.xpos > 1.0 - PLAYER_XSIZE )
		# Did player 2 catch the ball?
		if( $ball.ypos > ($player2.ypos-PLAYER_YSIZE) &&
		    $ball.ypos < ($player2.ypos+PLAYER_YSIZE) )
			$ball.xpos = 2.0 - 2.0*PLAYER_XSIZE - $ball.xpos
			$ball.xspeed = -$ball.xspeed;
		else
			event = PLAYER1_WINS;
		end
	end
	
	return event
end

#========================================================================
# DrawBox() - Draw a 3D box
#========================================================================

TEX_SCALE = 4.0

def DrawBox(x1,y1,z1,x2,y2,z2)
	# Draw six sides of a cube
	glBegin( GL_QUADS )
		# Side 1 (down)
		glNormal3f( 0.0, 0.0, -1.0 )
		glTexCoord2f( 0.0, 0.0 )
		glVertex3f( x1,y2,z1 )
		glTexCoord2f( TEX_SCALE, 0.0 )
		glVertex3f( x2,y2,z1 )
		glTexCoord2f( TEX_SCALE, TEX_SCALE )
		glVertex3f( x2,y1,z1 )
		glTexCoord2f( 0.0, TEX_SCALE )
		glVertex3f( x1,y1,z1 )
		# Side 2 (up)
		glNormal3f( 0.0, 0.0, 1.0 )
		glTexCoord2f( 0.0, 0.0 )
		glVertex3f( x1,y1,z2 )
		glTexCoord2f( TEX_SCALE, 0.0 )
		glVertex3f( x2,y1,z2 )
		glTexCoord2f( TEX_SCALE, TEX_SCALE )
		glVertex3f( x2,y2,z2 )
		glTexCoord2f( 0.0, TEX_SCALE )
		glVertex3f( x1,y2,z2 )
		# Side 3 (backward)
		glNormal3f( 0.0, -1.0, 0.0 )
		glTexCoord2f( 0.0, 0.0 )
		glVertex3f( x1,y1,z1 )
		glTexCoord2f( TEX_SCALE, 0.0 )
		glVertex3f( x2,y1,z1 )
		glTexCoord2f( TEX_SCALE, TEX_SCALE )
		glVertex3f( x2,y1,z2 )
		glTexCoord2f( 0.0, TEX_SCALE )
		glVertex3f( x1,y1,z2 )
		# Side 4 (forward)
		glNormal3f( 0.0, 1.0, 0.0 )
		glTexCoord2f( 0.0, 0.0 )
		glVertex3f( x1,y2,z2 )
		glTexCoord2f( TEX_SCALE, 0.0 )
		glVertex3f( x2,y2,z2 )
		glTexCoord2f( TEX_SCALE, TEX_SCALE )
		glVertex3f( x2,y2,z1 )
		glTexCoord2f( 0.0, TEX_SCALE )
		glVertex3f( x1,y2,z1 )
		# Side 5 (left)
		glNormal3f( -1.0, 0.0, 0.0 )
		glTexCoord2f( 0.0, 0.0 )
		glVertex3f( x1,y1,z2 )
		glTexCoord2f( TEX_SCALE, 0.0 )
		glVertex3f( x1,y2,z2 )
		glTexCoord2f( TEX_SCALE, TEX_SCALE )
		glVertex3f( x1,y2,z1 )
		glTexCoord2f( 0.0, TEX_SCALE )
		glVertex3f( x1,y1,z1 )
		# Side 6 (right)
		glNormal3f( 1.0, 0.0, 0.0 )
		glTexCoord2f( 0.0, 0.0 )
		glVertex3f( x2,y1,z1 )
		glTexCoord2f( TEX_SCALE, 0.0 )
		glVertex3f( x2,y2,z1 )
		glTexCoord2f( TEX_SCALE, TEX_SCALE )
		glVertex3f( x2,y2,z2 )
		glTexCoord2f( 0.0, TEX_SCALE )
		glVertex3f( x2,y1,z2 )
	glEnd()
end

#========================================================================
# UpdateDisplay() - Draw graphics (all game related OpenGL stuff goes
# here)
#========================================================================

def UpdateDisplay
	# Get window size
	$width,$height = glfwGetWindowSize()

	# Set viewport
	glViewport( 0, 0, $width, $height )
	
	# Clear display
	glClearColor( 0.02, 0.02, 0.02, 0.0 )
	glClearDepth( 1.0 )
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
	
	# Setup projection matrix
	glMatrixMode( GL_PROJECTION )
	glLoadIdentity()
	gluPerspective(
		55.0,                            # Angle of view
		$width.to_f/$height.to_f,          # Aspect
		1.0,                             # Near Z
		100.0                            # Far Z
	)

	# Setup modelview matrix
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	case ( $camerapos )
	when CAMERA_ABOVE
		gluLookAt(
			0.0, 0.0, 2.5,
			$ball.xpos, $ball.ypos, 0.0,
			0.0, 1.0, 0.0
		)
	when CAMERA_SPECTATOR
		gluLookAt(
			0.0, -2.0, 1.2,
			$ball.xpos, $ball.ypos, 0.0,
			0.0, 0.0, 1.0
		)
	when CAMERA_CLASSIC
		gluLookAt(
			0.0, 0.0, 2.5,
			0.0, 0.0, 0.0,
			0.0, 1.0, 0.0
		)
	else
	end

	# Enable depth testing
	glEnable( GL_DEPTH_TEST )
	glDepthFunc( GL_LEQUAL )
	
	# Enable lighting
	glEnable( GL_LIGHTING )
	glLightModelfv( GL_LIGHT_MODEL_AMBIENT, $env_ambient )
	glLightModeli( GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE )
	glLightModeli( GL_LIGHT_MODEL_TWO_SIDE, GL_FALSE )
	glLightfv( GL_LIGHT1, GL_POSITION, $light1_position )
	glLightfv( GL_LIGHT1, GL_DIFFUSE,  $light1_diffuse )
	glLightfv( GL_LIGHT1, GL_AMBIENT,  $light1_ambient )
	glEnable( GL_LIGHT1 )

	# Front face is counter-clock-wise
	glFrontFace( GL_CCW )
	
	# Enable face culling (not necessary, but speeds up rendering)
	glCullFace( GL_BACK )
	glEnable( GL_CULL_FACE )
	
	# Draw Player 1
	glMaterialfv( GL_FRONT, GL_DIFFUSE, $player1_diffuse )
	glMaterialfv( GL_FRONT, GL_AMBIENT, $player1_ambient )
	DrawBox( -1.0, $player1.ypos-PLAYER_YSIZE, 0.0,
			     -1.0+PLAYER_XSIZE, $player1.ypos+PLAYER_YSIZE, 0.1 )

	# Draw Player 2
	glMaterialfv( GL_FRONT, GL_DIFFUSE, $player2_diffuse )
	glMaterialfv( GL_FRONT, GL_AMBIENT, $player2_ambient )
	DrawBox( 1.0-PLAYER_XSIZE, $player2.ypos-PLAYER_YSIZE, 0.0,
	         1.0, $player2.ypos+PLAYER_YSIZE, 0.1 )


	# Draw Ball
	glMaterialfv( GL_FRONT, GL_DIFFUSE, $ball_diffuse )
	glMaterialfv( GL_FRONT, GL_AMBIENT, $ball_ambient )
	DrawBox( $ball.xpos-BALL_SIZE, $ball.ypos-BALL_SIZE, 0.0,
		       $ball.xpos+BALL_SIZE, $ball.ypos+BALL_SIZE, BALL_SIZE*2 )
	
	# Top game field border
	glMaterialfv( GL_FRONT, GL_DIFFUSE, $border_diffuse )
	glMaterialfv( GL_FRONT, GL_AMBIENT, $border_ambient )
	DrawBox( -1.1, 1.0, 0.0,  1.1, 1.1, 0.1 )
	# Bottom game field border
	glColor3f( 0.0, 0.0, 0.7 )
	DrawBox( -1.1, -1.1, 0.0,  1.1, -1.0, 0.1 )
	# Left game field border
	DrawBox( -1.1, -1.0, 0.0,  -1.0, 1.0, 0.1 )
	# Left game field border
	DrawBox( 1.0, -1.0, 0.0,  1.1, 1.0, 0.1 )

	# Enable texturing
	glEnable( GL_TEXTURE_2D )
	glBindTexture( GL_TEXTURE_2D, $tex_id[ TEX_FIELD ] )
	
	# Game field floor
	glMaterialfv( GL_FRONT, GL_DIFFUSE, $floor_diffuse )
	glMaterialfv( GL_FRONT, GL_AMBIENT, $floor_ambient )
	DrawBox( -1.01, -1.01, -0.01,  1.01, 1.01, 0.0 )
	
	# Disable texturing
	glDisable( GL_TEXTURE_2D )
	
	# Disable face culling
	glDisable( GL_CULL_FACE )
	
	# Disable lighting
	glDisable( GL_LIGHTING )
	
	# Disable depth testing
	glDisable( GL_DEPTH_TEST )
end

#========================================================================
# GameOver()
#========================================================================

def GameOver
	# Enable sticky keys
	glfwEnable( GLFW_STICKY_KEYS )
	
	# Until the user presses ESC or SPACE
	while( glfwGetKey( GLFW_KEY_ESC ) != GLFW_PRESS && glfwGetKey( GLFW_KEY_SPACE ) != GLFW_PRESS &&
	        glfwGetWindowParam( GLFW_OPENED ) == true )
		# Draw display
		UpdateDisplay()
		
		# Setup projection matrix
		glMatrixMode( GL_PROJECTION )
		glLoadIdentity()
		glOrtho( 0.0, 1.0, 1.0, 0.0, -1.0, 1.0 )
		
		# Setup modelview matrix
		glMatrixMode( GL_MODELVIEW )
		glLoadIdentity()
		
		# Enable blending
		glEnable( GL_BLEND )
		
		# Dim background
		glBlendFunc( GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA )
		glColor4f( 0.3, 0.3, 0.3, 0.3 )
		glBegin( GL_QUADS )
			glVertex2f( 0.0, 0.0 )
			glVertex2f( 1.0, 0.0 )
			glVertex2f( 1.0, 1.0 )
			glVertex2f( 0.0, 1.0 )
		glEnd()
		
		# Display winner text
		glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_COLOR )
		if( $winner == PLAYER1 )
			glColor4f( 1.0, 0.5, 0.5, 1.0 )
			DrawImage( TEX_WINNER1, 0.35, 0.65, 0.46, 0.54 )
		elsif( $winner == PLAYER2 )
			glColor4f( 0.5, 1.0, 0.5, 1.0 )
			DrawImage( TEX_WINNER2, 0.35, 0.65, 0.46, 0.54 )
		end
		
		# Disable blending
		glDisable( GL_BLEND )
		
		# Swap buffers
		glfwSwapBuffers()
	end
	
	# Disable sticky keys
	glfwDisable( GLFW_STICKY_KEYS )
end

#========================================================================
# GameLoop() - Game loop
#========================================================================

def GameLoop
	# Initialize a new game
	NewGame()
	
	# Enable sticky keys
	glfwEnable( GLFW_STICKY_KEYS )

	# Loop until the game ends
	playing = true
	while( playing && glfwGetWindowParam( GLFW_OPENED ) == true )
		# Frame timer
		$oldtime = $thistime
		$thistime = glfwGetTime()
		$dt = $thistime - $oldtime
		
		# Get user input and update player positions
		PlayerControl()
		
		# Move the ball, and check if a player hits/misses the ball
		event = BallControl()
		
		# Did we have a winner?
		case ( event )
		when PLAYER1_WINS
			$winner = PLAYER1
			playing = false
		when PLAYER2_WINS
			$winner = PLAYER2
			playing = false
		else
		end
		
		# Did the user press ESC?
		if( glfwGetKey( GLFW_KEY_ESC ) == GLFW_PRESS)
			playing = false
		end
		
		# Did the user change camera view?
		if( glfwGetKey( ?1 ) == GLFW_PRESS )
			$camerapos = CAMERA_CLASSIC
		elsif( glfwGetKey( ?2 ) == GLFW_PRESS )
			$camerapos = CAMERA_ABOVE
		elsif( glfwGetKey( ?3 ) == GLFW_PRESS )
			$camerapos = CAMERA_SPECTATOR
		end		

		# Draw display
		UpdateDisplay()
		
		# Swap buffers
		glfwSwapBuffers()
	end
	
	# Disable sticky keys
	glfwDisable( GLFW_STICKY_KEYS )
	
	# Show winner
	GameOver()
end

#========================================================================
# main() - Program entry point
#========================================================================

menuoption = MENU_NONE

# Initialize GLFW

# Open OpenGL window
if( glfwOpenWindow( WIDTH, HEIGHT, 0,0,0,0, 16,0, GLFW_WINDOW ) == false )
	exit
end

# Load all textures
LoadTextures()


# Main loop
while( menuoption != MENU_QUIT )
	# Get menu option
	menuoption = GameMenu()
	
	# If the user wants to play, let him...
	if( menuoption == MENU_PLAY )
		GameLoop()
	end
end

# Unload all textures
if( glfwGetWindowParam( GLFW_OPENED ) == true)
	glDeleteTextures( $tex_id )
end
