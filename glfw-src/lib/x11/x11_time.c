//========================================================================
// GLFW - An OpenGL framework
// Platform:    X11/GLX
// API version: 2.7
// WWW:         http://www.glfw.org/
//------------------------------------------------------------------------
// Copyright (c) 2002-2006 Marcus Geelnard
// Copyright (c) 2006-2010 Camilla Berglund <elmindreda@elmindreda.org>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================

#include "internal.h"

#include <time.h>


//========================================================================
// Return raw time
//========================================================================

static uint64_t getRawTime(void)
{
#if defined( _POSIX_TIMERS ) && defined( _POSIX_MONOTONIC_CLOCK )
    if( _glfwLibrary.Timer.monotonic )
    {
        struct timespec ts;

        clock_gettime( CLOCK_MONOTONIC, &ts );
        return (uint64_t) ts.tv_sec * (uint64_t) 1000000000 + (uint64_t) ts.tv_nsec;
    }
    else
#endif
    {
        struct timeval tv;

        gettimeofday( &tv, NULL );
        return (uint64_t) tv.tv_sec * (uint64_t) 1000000 + (uint64_t) tv.tv_usec;
    }
}


//========================================================================
// Initialise timer
//========================================================================

void _glfwInitTimer( void )
{
#if defined( _POSIX_TIMERS ) && defined( _POSIX_MONOTONIC_CLOCK )
    struct timespec ts;

    if( clock_gettime( CLOCK_MONOTONIC, &ts ) == 0 )
    {
        _glfwLibrary.Timer.monotonic = GL_TRUE;
        _glfwLibrary.Timer.resolution = 1e-9;
    }
    else
#endif
    {
        _glfwLibrary.Timer.resolution = 1e-6;
    }

    _glfwLibrary.Timer.base = getRawTime();
}


//************************************************************************
//****               Platform implementation functions                ****
//************************************************************************

//========================================================================
// Return timer value in seconds
//========================================================================

double _glfwPlatformGetTime( void )
{
    return (double) (getRawTime() - _glfwLibrary.Timer.base) *
        _glfwLibrary.Timer.resolution;
}


//========================================================================
// Set timer value in seconds
//========================================================================

void _glfwPlatformSetTime( double time )
{
    _glfwLibrary.Timer.base = getRawTime() -
        (uint64_t) (time / _glfwLibrary.Timer.resolution);
}


//========================================================================
// Put a thread to sleep for a specified amount of time
//========================================================================

void _glfwPlatformSleep( double time )
{
#ifdef _GLFW_HAS_PTHREAD

    if( time == 0.0 )
    {
#ifdef _GLFW_HAS_SCHED_YIELD
	sched_yield();
#endif
	return;
    }

    struct timeval  currenttime;
    struct timespec wait;
    pthread_mutex_t mutex;
    pthread_cond_t  cond;
    long dt_sec, dt_usec;

    // Not all pthread implementations have a pthread_sleep() function. We
    // do it the portable way, using a timed wait for a condition that we
    // will never signal. NOTE: The unistd functions sleep/usleep suspends
    // the entire PROCESS, not a signle thread, which is why we can not
    // use them to implement glfwSleep.

    // Set timeout time, relatvie to current time
    gettimeofday( &currenttime, NULL );
    dt_sec  = (long) time;
    dt_usec = (long) ((time - (double)dt_sec) * 1000000.0);
    wait.tv_nsec = (currenttime.tv_usec + dt_usec) * 1000L;
    if( wait.tv_nsec > 1000000000L )
    {
        wait.tv_nsec -= 1000000000L;
        dt_sec++;
    }
    wait.tv_sec  = currenttime.tv_sec + dt_sec;

    // Initialize condition and mutex objects
    pthread_mutex_init( &mutex, NULL );
    pthread_cond_init( &cond, NULL );

    // Do a timed wait
    pthread_mutex_lock( &mutex );
    pthread_cond_timedwait( &cond, &mutex, &wait );
    pthread_mutex_unlock( &mutex );

    // Destroy condition and mutex objects
    pthread_mutex_destroy( &mutex );
    pthread_cond_destroy( &cond );

#else

    // For systems without PTHREAD, use unistd usleep
    if( time > 0 )
    {
        usleep( (unsigned int) (time*1000000) );
    }

#endif // _GLFW_HAS_PTHREAD
}

