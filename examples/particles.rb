#========================================================================
# This is a simple, but cool particle engine (buzz-word meaning many
# small objects that are treated as points and drawn as textures
# projected on simple geometry).
#
# This demonstration generates a colorful fountain-like animation. It
# uses several advanced OpenGL teqhniques:
#
#  1) Lighting (per vertex)
#  2) Alpha blending
#  3) Fog
#  4) Texturing
#  5) Display lists (for drawing the static environment geometry)
#  6) OpenGL 2.0 point sprites (for particle drawing if available)
#  7) GL_EXT_separate_specular_color is used (if available)
#
# To run a fixed length benchmark (60 s), use the command line switch -b.
#
# One more thing: Press 'w' during the demo to toggle wireframe mode.
#========================================================================
#
# Converted to ruby from GLFW example particles.c
#
# Ruby version notes:
#
# Number of particles had to be decreased 10-fold to accomodate for ruby
# speed (or lack of thereof) - interpreted languages are not exactly suited
# for realtime processing of large amounts of data, and ruby is no exception.
#
# Using point sprites and immediate mode, the ruby version is about 60x
# slower then the C version (assuming equal number of particles). If
# you need large-scale particle system, better solution would be to
# either offload as much as possible to the GPU or write it in C as
# ruby extension/module.
#
# Also I didn't use vertex arrays/buffers, because converting between ruby
# and C representation of variables each frame is actually slower then the
# function call overhead of OpenGL immediate mode.

require 'opengl'
require 'glfw'
include Gl,Glu,Glfw,Math

# Desired fullscreen resolution
WIDTH = 640
HEIGHT = 480

#========================================================================
# Type definitions
#========================================================================

class Vec
	attr_accessor :x,:y,:z
end

#========================================================================
# Program control global variables
#========================================================================

# "Running" flag (true if program shall continue to run)
$running = true

# Window dimensions
$width = 0
$height = 0

# "wireframe" flag (true if we use wireframe view)
$wireframe = false

#========================================================================
# Texture declarations (we hard-code them into the source code, since
# they are so simple)
#========================================================================

P_TEX_WIDTH  = 8    # Particle texture dimensions
P_TEX_HEIGHT = 8
F_TEX_WIDTH  = 16   # Floor texture dimensions
F_TEX_HEIGHT = 16

# Texture object IDs
$particle_tex_id = 0
$floor_tex_id = 0

# Particle texture (a simple spot)
$particle_texture = [
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x11, 0x22, 0x22, 0x11, 0x00, 0x00,
    0x00, 0x11, 0x33, 0x88, 0x77, 0x33, 0x11, 0x00,
    0x00, 0x22, 0x88, 0xff, 0xee, 0x77, 0x22, 0x00,
    0x00, 0x22, 0x77, 0xee, 0xff, 0x88, 0x22, 0x00,
    0x00, 0x11, 0x33, 0x77, 0x88, 0x33, 0x11, 0x00,
    0x00, 0x00, 0x11, 0x33, 0x22, 0x11, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
]

# Floor texture (your basic checkered floor)
$floor_texture = [
    0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0xff, 0xf0, 0xcc, 0xf0, 0xf0, 0xf0, 0xff, 0xf0, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0xf0, 0xcc, 0xee, 0xff, 0xf0, 0xf0, 0xf0, 0xf0, 0x30, 0x66, 0x30, 0x30, 0x30, 0x20, 0x30, 0x30,
    0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xee, 0xf0, 0xf0, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0xf0, 0xf0, 0xf0, 0xf0, 0xcc, 0xf0, 0xf0, 0xf0, 0x30, 0x30, 0x55, 0x30, 0x30, 0x44, 0x30, 0x30,
    0xf0, 0xdd, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0x33, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xff, 0xf0, 0xf0, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x60, 0x30,
    0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0x33, 0x33, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x33, 0x30, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x30, 0x30, 0xf0, 0xff, 0xf0, 0xf0, 0xdd, 0xf0, 0xf0, 0xff,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x55, 0x33, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xff, 0xf0, 0xf0,
    0x30, 0x44, 0x66, 0x30, 0x30, 0x30, 0x30, 0x30, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0xf0, 0xf0, 0xf0, 0xaa, 0xf0, 0xf0, 0xcc, 0xf0,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0xff, 0xf0, 0xf0, 0xf0, 0xff, 0xf0, 0xdd, 0xf0,
    0x30, 0x30, 0x30, 0x77, 0x30, 0x30, 0x30, 0x30, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0
]

#========================================================================
# These are fixed constants that control the particle engine. In a
# modular world, these values should be variables...
#========================================================================

# Maximum number of particles
MAX_PARTICLES = 300

# Life span of a particle (in seconds)
LIFE_SPAN = 8.0

# A new particle is born every [BIRTH_INTERVAL] second
BIRTH_INTERVAL = (LIFE_SPAN/MAX_PARTICLES.to_f)

# Particle size (meters)
PARTICLE_SIZE = 0.7

# Gravitational constant (m/s^2)
GRAVITY = 9.8

# Base initial velocity (m/s)
VELOCITY = 8.0

# Bounce friction (1.0 = no friction, 0.0 = maximum friction)
FRICTION = 0.75

# "Fountain" height (m)
FOUNTAIN_HEIGHT = 3.0

# Fountain radius (m)
FOUNTAIN_RADIUS = 1.6

# Minimum delta-time for particle phisics (s)
MIN_DELTA_T = (BIRTH_INTERVAL*1.0)

#========================================================================
# Particle system global variables
#========================================================================

# This structure holds all state for a single particle
class Particle
	attr_accessor :x,:y,:z    # Position in space
	attr_accessor :vx,:vy,:vz # Velocity vector
	attr_accessor :r,:g,:b    # Color of particle
	attr_accessor :life       # Life of particle (1.0 = newborn, < 0.0 = dead)
	attr_accessor :active     # Tells if this particle is active
end

# Global vectors holding all particles. We use two vectors for double
# buffering.
$particles = Array.new(MAX_PARTICLES).collect {Particle.new}

# Global variable holding the age of the youngest particle
$min_age = 0

# Color of latest born particle (used for fountain lighting)
$glow_color = []

# Position of latest born particle (used for fountain lighting)
$glow_pos = []

#========================================================================
# Object material and fog configuration constants
#========================================================================

$fountain_diffuse  = [0.7,1.0,1.0,1.0]
$fountain_specular = [1.0,1.0,1.0,1.0]
$fountain_shininess   = 12.0
$floor_diffuse     = [1.0,0.6,0.6,1.0]
$floor_specular    = [0.6,0.6,0.6,1.0]
$floor_shininess      = 18.0
$fog_color = [0.1, 0.1, 0.1, 1.0]

#========================================================================
# InitParticle() - Initialize a new particle
#========================================================================

def InitParticle( p, t )
	# Start position of particle is at the fountain blow-out
	p.x = 0.0
	p.y = 0.0
	p.z = FOUNTAIN_HEIGHT
	
	# Start velocity is up (Z)...
	p.vz = 0.7 + 0.3 * rand()
	
	# ...and a randomly chosen X/Y direction
	xy_angle = (2.0*PI) * rand()
	p.vx = 0.4 * cos( xy_angle )
	p.vy = 0.4 * sin( xy_angle )
	
	# Scale velocity vector according to a time-varying velocity
	velocity = VELOCITY*(0.8 + 0.1* (sin( 0.5*t )+sin( 1.31*t )))
	p.vx *= velocity
	p.vy *= velocity
	p.vz *= velocity
	
	# Color is time-varying
	p.r = 0.7 + 0.3 * sin( 0.34*t + 0.1 )
	p.g = 0.6 + 0.4 * sin( 0.63*t + 1.1 )
	p.b = 0.6 + 0.4 * sin( 0.91*t + 2.1 )
	
	# Store settings for fountain glow lighting
	$glow_pos[0] = 0.4 * sin( 1.34*t )
	$glow_pos[1] = 0.4 * sin( 3.11*t )
	$glow_pos[2] = FOUNTAIN_HEIGHT + 1.0
	$glow_pos[3] = 1.0
	$glow_color[0] = p.r
	$glow_color[1] = p.g
	$glow_color[2] = p.b
	$glow_color[3] = 1.0
	
	# The particle is new-born and active
	p.life = 1.0
	p.active = true
end

#========================================================================
# UpdateParticle() - Update a particle
#========================================================================

FOUNTAIN_R2 = (FOUNTAIN_RADIUS+PARTICLE_SIZE/2)*(FOUNTAIN_RADIUS+PARTICLE_SIZE/2)

def UpdateParticle( p, dt )
	# If the particle is not active, we need not do anything
	return if( !p.active )
	
	# The particle is getting older...
	p.life = p.life - dt * (1.0 / LIFE_SPAN)
	
	# Did the particle die?
	if( p.life <= 0.0 )
		p.active = false
		return
	end
	
	# Update particle velocity (apply gravity)
	p.vz = p.vz - GRAVITY * dt
	
	# Update particle position
	p.x = p.x + p.vx * dt;
	p.y = p.y + p.vy * dt;
	p.z = p.z + p.vz * dt;
	
	# Simple collision detection + response
	if( p.vz < 0.0 )
		# Particles should bounce on the fountain (with friction)
		if( (p.x*p.x + p.y*p.y) < FOUNTAIN_R2 &&
		     p.z < (FOUNTAIN_HEIGHT + PARTICLE_SIZE/2) )
			p.vz = -FRICTION * p.vz
			p.z  = FOUNTAIN_HEIGHT + PARTICLE_SIZE/2 +
						FRICTION * (FOUNTAIN_HEIGHT +
						PARTICLE_SIZE/2 - p.z)
	
		# Particles should bounce on the floor (with friction)
		elsif( p.z < PARTICLE_SIZE/2 )
			p.vz = -FRICTION * p.vz
			p.z  = PARTICLE_SIZE/2 +
						FRICTION * (PARTICLE_SIZE/2 - p.z)
		end
	end
end

#========================================================================
# ParticleEngine() - The main frame for the particle engine. Called once
# per frame.
#========================================================================

def ParticleEngine( t, dt)
	# Update particles (iterated several times per frame if dt is too
	# large)
	while( dt > 0.0 )
		# Calculate delta time for this iteration
		dt2 = dt < MIN_DELTA_T ? dt : MIN_DELTA_T
		
		# Update particles
		MAX_PARTICLES.times do |i|
			UpdateParticle( $particles[ i ], dt2 )
		end

		# Increase minimum age
		$min_age += dt2
		
		# Should we create any new particle(s)?
		while( $min_age >= BIRTH_INTERVAL )
			$min_age -= BIRTH_INTERVAL
			
			# Find a dead particle to replace with a new one
			MAX_PARTICLES.times do |i|
				if( !$particles[ i ].active )
					InitParticle( $particles[ i ], t + $min_age )
					UpdateParticle( $particles[ i ], $min_age )
					break
				end
			end
		end
		
		# Decrease frame delta time
		dt -= dt2
	end
end

#========================================================================
# DrawParticles() - Draw all active particles. We use OpenGL 1.1 vertex
# arrays for this in order to accelerate the drawing.
#========================================================================

BATCH_PARTICLES = 70 # Number of particles to draw in each batch
                     # (70 corresponds to 7.5 KB = will not blow
                     # the L1 data cache on most CPUs)
PARTICLE_VERTS = 4   # Number of vertices per particle

def DrawParticles(t,dt)
	# Don't update z-buffer, since all particles are transparent!
	glDepthMask( GL_FALSE )
	
	# Enable blending
	glEnable( GL_BLEND )
	glBlendFunc( GL_SRC_ALPHA, GL_ONE )
	
	# Select particle texture
	if( !$wireframe )
		glEnable( GL_TEXTURE_2D )
		glBindTexture( GL_TEXTURE_2D, $particle_tex_id )
	end
	
	# Perform particle physics in this thread
	ParticleEngine( t, dt )

	if (Gl.is_available?(2.0)) # use point sprites if available
		glPointParameterfv( GL_POINT_DISTANCE_ATTENUATION, [1.0,0.0,0.01] )
		glPointParameterf( GL_POINT_FADE_THRESHOLD_SIZE, 60.0 )
		glPointParameterf( GL_POINT_SIZE_MIN, 1.0 )
		glPointParameterf( GL_POINT_SIZE_MAX, 1024.0 )
	
		glTexEnvf( GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE )
	
	
		glEnable( GL_POINT_SPRITE)
	
		glPointSize( $height/14.0 )
	
		glBegin( GL_POINTS );
		$particles.each do |p|
			next if !p.active
	
			alpha = 4.0 * p.life
			alpha = 1.0 if alpha > 1.0
	
			glColor4f(p.r,p.g,p.b,alpha)
			glVertex3f(p.x,p.y,p.z)
		end
		glEnd()
	
		glDisable( GL_POINT_SPRITE )
	else  
		quad_lower_left = Vec.new
		quad_lower_right = Vec.new
		
		mat = glGetFloatv( GL_MODELVIEW_MATRIX )
		mat.flatten!
		quad_lower_left.x = (-PARTICLE_SIZE/2) * (mat[0] + mat[1])
		quad_lower_left.y = (-PARTICLE_SIZE/2) * (mat[4] + mat[5])
		quad_lower_left.z = (-PARTICLE_SIZE/2) * (mat[8] + mat[9])
		quad_lower_right.x = (PARTICLE_SIZE/2) * (mat[0] - mat[1])
		quad_lower_right.y = (PARTICLE_SIZE/2) * (mat[4] - mat[5])
		quad_lower_right.z = (PARTICLE_SIZE/2) * (mat[8] - mat[9])

		glBegin(GL_QUADS)
		$particles.each do |p|
			next if !p.active
			# Calculate particle intensity (we set it to max during 75%
	    # of its life, then it fades out)
	    alpha = 4.0 * p.life
	    alpha = 1.0 if alpha > 1.0
		
			glColor4f(p.r,p.g,p.b,alpha)
			glTexCoord2f(0.0,0.0)
			glVertex3f(p.x + quad_lower_left.x,
								 p.y + quad_lower_left.y,
								 p.z + quad_lower_left.z)

			glTexCoord2f(1.0,0.0)
			glVertex3f(p.x + quad_lower_right.x,
								 p.y + quad_lower_right.y,
								 p.z + quad_lower_right.z)


			glTexCoord2f(1.0,1.0)
			glVertex3f(p.x - quad_lower_left.x,
								 p.y - quad_lower_left.y,
								 p.z - quad_lower_left.z)

			glTexCoord2f(0.0,1.0)
			glVertex3f(p.x - quad_lower_right.x,
								 p.y - quad_lower_right.y,
								 p.z - quad_lower_right.z)
		end
		glEnd()
	end

	# Disable texturing and blending
	glDisable( GL_TEXTURE_2D )
	glDisable( GL_BLEND )
	
	# Allow Z-buffer updates again
	glDepthMask( GL_TRUE )
end

#========================================================================
# Fountain geometry specification
#========================================================================

FOUNTAIN_SIDE_POINTS = 14
FOUNTAIN_SWEEP_STEPS = 32

$fountain_side = [
    1.2, 0.0,  1.0,  0.2,  0.41, 0.3, 0.4, 0.35,
    0.4, 1.95, 0.41, 2.0, 0.8, 2.2,  1.2, 2.4,
    1.5, 2.7,  1.55, 2.95, 1.6, 3.0,  1.0, 3.0,
    0.5, 3.0,  0.0, 3.0
]

$fountain_normal = [
    1.0000, 0.0000,  0.6428, 0.7660,  0.3420, 0.9397,  1.0000, 0.0000,
    1.0000, 0.0000,  0.3420,-0.9397,  0.4226,-0.9063,  0.5000,-0.8660,
    0.7660,-0.6428,  0.9063,-0.4226,  0.0000,1.00000,  0.0000,1.00000,
    0.0000,1.00000,  0.0000,1.00000
]

#========================================================================
# DrawFountain() - Draw a fountain
#========================================================================

def DrawFountain
	@@fountain_list ||= 0  # static variable
	
	# The first time, we build the fountain display list
	if( @@fountain_list == 0)
		# Start recording of a new display list
		@@fountain_list = glGenLists( 1 )
		glNewList( @@fountain_list, GL_COMPILE_AND_EXECUTE )
		
		# Set fountain material
		glMaterialfv( GL_FRONT, GL_DIFFUSE,   $fountain_diffuse )
		glMaterialfv( GL_FRONT, GL_SPECULAR,  $fountain_specular )
		glMaterialf(  GL_FRONT, GL_SHININESS, $fountain_shininess )
		
		# Build fountain using triangle strips
		0.upto(FOUNTAIN_SIDE_POINTS-1-1) do |n|
			glBegin( GL_TRIANGLE_STRIP );
			0.upto(FOUNTAIN_SWEEP_STEPS) do |m|
				angle = m * (2.0*PI/FOUNTAIN_SWEEP_STEPS.to_f)
				x = cos( angle )
				y = sin( angle )
				
				# Draw triangle strip
				glNormal3f( x * $fountain_normal[ n*2+2 ],
										y * $fountain_normal[ n*2+2 ],
										$fountain_normal[ n*2+3 ] )
				glVertex3f( x * $fountain_side[ n*2+2 ],
										y * $fountain_side[ n*2+2 ],
										$fountain_side[ n*2+3 ] )
				glNormal3f( x * $fountain_normal[ n*2 ],
										y * $fountain_normal[ n*2 ],
										$fountain_normal[ n*2+1 ] )
				glVertex3f( x * $fountain_side[ n*2 ],
										y * $fountain_side[ n*2 ],
										$fountain_side[ n*2+1 ] )
			end
			glEnd()
		end
		
		# End recording of display list
		glEndList()
	else
		# Playback display list
		glCallList( @@fountain_list )
	end
end

#========================================================================
# TesselateFloor() - Recursive function for building variable tesselated
# floor
#========================================================================

def TesselateFloor( x1,y1,x2,y2,recursion )
	# Last recursion?
	if( recursion >= 5 )
		delta = 999999.0
	else
		x = x1.abs < x2.abs ? x1.abs : x2.abs
		y = y1.abs < y2.abs ? y1.abs : y2.abs
		delta = x*x + y*y
	end
	
	# Recurse further?
	if( delta < 0.1 )
		x = (x1+x2) * 0.5;
		y = (y1+y2) * 0.5;
		TesselateFloor( x1,y1,  x, y, recursion + 1 )
		TesselateFloor(  x,y1, x2, y, recursion + 1 )
		TesselateFloor( x1, y,  x,y2, recursion + 1 )
		TesselateFloor(  x, y, x2,y2, recursion + 1 )
	else
		glTexCoord2f( x1*30.0, y1*30.0 )
		glVertex3f( x1*80.0, y1*80.0 , 0.0 )
		glTexCoord2f( x2*30.0, y1*30.0 )
		glVertex3f( x2*80.0, y1*80.0 , 0.0 )
		glTexCoord2f( x2*30.0, y2*30.0 )
		glVertex3f( x2*80.0, y2*80.0 , 0.0 )
		glTexCoord2f( x1*30.0, y2*30.0 )
		glVertex3f( x1*80.0, y2*80.0 , 0.0 )
	end
end

#========================================================================
# DrawFloor() - Draw floor. We builde the floor recursively, and let the
# tesselation in the centre (near x,y=0,0) be high, while the selleation
# around the edges be low.
#========================================================================

def DrawFloor
	@@floor_list ||= 0
	
	# Select floor texture
	if( !$wireframe )
		glEnable( GL_TEXTURE_2D )
		glBindTexture( GL_TEXTURE_2D, $floor_tex_id )
	end
	
	# The first time, we build the floor display list
	if( @@floor_list == 0)
		# Start recording of a new display list
		@@floor_list = glGenLists( 1 )
		glNewList( @@floor_list, GL_COMPILE_AND_EXECUTE )
		
		# Set floor material
		glMaterialfv( GL_FRONT, GL_DIFFUSE, $floor_diffuse )
		glMaterialfv( GL_FRONT, GL_SPECULAR, $floor_specular )
		glMaterialf(  GL_FRONT, GL_SHININESS, $floor_shininess )
		
		# Draw floor as a bunch of triangle strips (high tesselation
		# improves lighting)
		glNormal3f( 0.0, 0.0, 1.0 )
		glBegin( GL_QUADS )
		TesselateFloor( -1.0,-1.0, 0.0,0.0, 0 )
		TesselateFloor(  0.0,-1.0, 1.0,0.0, 0 )
		TesselateFloor(  0.0, 0.0, 1.0,1.0, 0 )
		TesselateFloor( -1.0, 0.0, 0.0,1.0, 0 )
		glEnd()
		
		# End recording of display list
		glEndList()
	else
		# Playback display list
		glCallList( @@floor_list )
	end
	
	glDisable( GL_TEXTURE_2D )
end

#========================================================================
# SetupLights() - Position and configure light sources
#========================================================================

def SetupLights
	# Set light source 1 parameters
	l1pos  = [0.0,-9.0, 8.0, 1.0]
	l1amb  = [0.2, 0.2, 0.2, 1.0]
	l1dif  = [0.8, 0.4, 0.2, 1.0]
	l1spec = [1.0, 0.6, 0.2, 0.0]

	# Set light source 2 parameters
	l2pos  = [-15.0,12.0, 1.5, 1.0]
	l2amb  = [0.0, 0.0, 0.0, 1.0]
	l2dif  = [0.2, 0.4, 0.8, 1.0]
	l2spec = [0.2, 0.6, 1.0, 0.0]

	# Configure light sources in OpenGL
	glLightfv( GL_LIGHT1, GL_POSITION, l1pos )
	glLightfv( GL_LIGHT1, GL_AMBIENT, l1amb )
	glLightfv( GL_LIGHT1, GL_DIFFUSE, l1dif )
	glLightfv( GL_LIGHT1, GL_SPECULAR, l1spec )
	glLightfv( GL_LIGHT2, GL_POSITION, l2pos )
	glLightfv( GL_LIGHT2, GL_AMBIENT, l2amb )
	glLightfv( GL_LIGHT2, GL_DIFFUSE, l2dif )
	glLightfv( GL_LIGHT2, GL_SPECULAR, l2spec )
	glLightfv( GL_LIGHT3, GL_POSITION, $glow_pos )
	glLightfv( GL_LIGHT3, GL_DIFFUSE, $glow_color )
	glLightfv( GL_LIGHT3, GL_SPECULAR, $glow_color )
	
	# Enable light sources
	glEnable( GL_LIGHT1 )
	glEnable( GL_LIGHT2 )
	glEnable( GL_LIGHT3 )
end

#========================================================================
# Draw() - Main rendering function
#========================================================================

def Draw( t )
	@@t_old ||= 0.0
	
	# Calculate frame-to-frame delta time
	dt = (t-@@t_old)
	@@t_old = t
	
	# Setup viewport
	glViewport( 0, 0, $width, $height )
	
	# Clear color and Z-buffer
	glClearColor( 0.1, 0.1, 0.1, 1.0 )
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
	
	# Setup projection
	glMatrixMode( GL_PROJECTION )
	glLoadIdentity()
	gluPerspective( 65.0, $width.to_f/$height.to_f, 1.0, 60.0 )
	
	# Setup camera
	glMatrixMode( GL_MODELVIEW )
	glLoadIdentity()
	
	# Rotate camera
	angle_x = 90.0 - 10.0
	angle_y = 10.0 * sin( 0.3 * t )
	angle_z = 10.0 * t
	glRotated( -angle_x, 1.0, 0.0, 0.0 )
	glRotated( -angle_y, 0.0, 1.0, 0.0 )
	glRotated( -angle_z, 0.0, 0.0, 1.0 )
	
	# Translate camera
	xpos =  15.0 * sin( (PI/180.0) * angle_z ) +
					 2.0 * sin( (PI/180.0) * 3.1 * t )
	ypos = -15.0 * cos( (PI/180.0) * angle_z ) +
					 2.0 * cos( (PI/180.0) * 2.9 * t )
	zpos = 4.0 + 2.0 * cos( (PI/180.0) * 4.9 * t )
	glTranslated( -xpos, -ypos, -zpos )
	
	# Enable face culling
	glFrontFace( GL_CCW )
	glCullFace( GL_BACK )
	glEnable( GL_CULL_FACE )
	
	# Enable lighting
	SetupLights()
	glEnable( GL_LIGHTING )
	
	# Enable fog (dim details far away)
	glEnable( GL_FOG )
	glFogi( GL_FOG_MODE, GL_EXP )
	glFogf( GL_FOG_DENSITY, 0.05 )
	glFogfv( GL_FOG_COLOR, $fog_color )
	
	# Draw floor
	DrawFloor()
	
	# Enable Z-buffering
	glEnable( GL_DEPTH_TEST )
	glDepthFunc( GL_LEQUAL )
	glDepthMask( GL_TRUE )
	
	# Draw fountain
	DrawFountain()
	
	# Disable fog & lighting
	glDisable( GL_LIGHTING )
	glDisable( GL_FOG )
	
	# Draw all particles (must be drawn after all solid objects have been
	# drawn!)
	DrawParticles( t, dt )
	
	# Z-buffer not needed anymore
	glDisable( GL_DEPTH_TEST )
end

#========================================================================
# Resize() - GLFW window resize callback function
#========================================================================

Resize = lambda do |x,y|
	$width = x
  $height = y > 0 ? y : 1 # Prevent division by zero in aspect calc.
end

#========================================================================
# Input callback functions
#========================================================================

KeyFun = lambda do |key,action|
	if( action == GLFW_PRESS )
		case ( key )
		when GLFW_KEY_ESC
			$running = false
		when ?W
			$wireframe = !$wireframe
			glPolygonMode( GL_FRONT_AND_BACK,
								$wireframe ? GL_LINE : GL_FILL )
		else
		end
	end
end

#========================================================================
# main()
#========================================================================

benchmark = false

# Check command line arguments
ARGV.each do |arg|
	case arg
	when "-b" 	# Use benchmarking?
		benchmark = true
	when /psn_/
		# With a Finder launch on Mac OS X we get a bogus -psn_0_46268417
		# kind of argument (actual numbers vary). Ignore it.
	else
		puts "Usage: #{$0} [options]"
		puts ""
		puts "Options:"
		puts " -b   Benchmark (run program for 60 s)"
		puts " -s   Run program as single thread (default is to use two threads)"
		puts " -?   Display this text"
		puts ""
		puts "Program runtime controls:"
		puts " w    Toggle wireframe mode"
		puts " ESC  Exit program"
		exit
	end
end

# Open OpenGL fullscreen window
if( glfwOpenWindow( WIDTH, HEIGHT, 5,6,5,0, 16,0, GLFW_FULLSCREEN ) == GL_FALSE)
	exit
end

# Set window title
glfwSetWindowTitle( "Particle engine" )

# Disable VSync (we want to get as high FPS as possible!)
glfwSwapInterval( 0 )

# Window resize callback function
glfwSetWindowSizeCallback( Resize )

# Set keyboard input callback function
glfwSetKeyCallback( KeyFun )

# Upload particle texture
$particle_tex_id,* = glGenTextures( 1 )
glBindTexture( GL_TEXTURE_2D, $particle_tex_id )
glPixelStorei( GL_UNPACK_ALIGNMENT, 1 )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR )
glTexImage2D( GL_TEXTURE_2D, 0, GL_LUMINANCE, P_TEX_WIDTH, P_TEX_HEIGHT,
		0, GL_LUMINANCE, GL_UNSIGNED_BYTE, $particle_texture.pack("C*") )

# Upload floor texture
$floor_tex_id,* = glGenTextures( 1)
glBindTexture( GL_TEXTURE_2D, $floor_tex_id )
glPixelStorei( GL_UNPACK_ALIGNMENT, 1 )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR )
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR )
glTexImage2D( GL_TEXTURE_2D, 0, GL_LUMINANCE, F_TEX_WIDTH, F_TEX_HEIGHT,
		0, GL_LUMINANCE, GL_UNSIGNED_BYTE, $floor_texture.pack("C*") )

# Check if we have GL_EXT_separate_specular_color, and if so use it
# (This extension should ALWAYS be used when OpenGL lighting is used
# together with texturing, since it gives more realistic results)
if( Gl.is_available?( "GL_EXT_separate_specular_color" ) )
		glLightModeli( GL_LIGHT_MODEL_COLOR_CONTROL_EXT,
									 GL_SEPARATE_SPECULAR_COLOR_EXT )
end

# Set filled polygon mode as default (not wireframe)
glPolygonMode( GL_FRONT_AND_BACK, GL_FILL )
$wireframe = false

# Clear particle system
MAX_PARTICLES.times do |i|
	$particles[ i ].active = false
end
$min_age = 0.0

# Main loop
t0 = glfwGetTime()
frames = 0
while( $running )
	# Get frame time
	t = glfwGetTime() - t0
	
	# Draw...
	Draw( t )
	
	# Swap buffers
	glfwSwapBuffers()
	
	# Check if window was closed
	$running = $running && (glfwGetWindowParam( GLFW_OPENED ) == GL_TRUE)
	
	# Increase frame count
	frames += 1
	
	# End of benchmark?
	if( benchmark && t >= 60.0 )
		$running = false
	end
end
t = glfwGetTime() - t0


# Display profiling information
printf( "%d frames in %.2f seconds = %.1f FPS\n\n", frames, t, frames.to_f / t )

