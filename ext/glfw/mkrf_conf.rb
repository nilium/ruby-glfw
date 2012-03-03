# Copyright (C) 2007 Jan Dvorak <jan.dvorak@kraxnet.cz>
#
# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#  claim that you wrote the original software. If you use this software
#  in a product, an acknowledgment in the product documentation would be
#  appreciated but is not required.
#
#  2. Altered source versions must be plainly marked as such, and must not be
#  misrepresented as being the original software.
#
#  3. This notice may not be removed or altered from any source distribution.

require 'rubygems'
require 'mkrf'
require 'rbconfig'

# where are the GLFW sources, relative to build directory
$glfw_dir = "../../glfw-src"
$glfw_dir_lib = $glfw_dir + "/lib"
$glfw_dir_inc = $glfw_dir + "/include"

# parses options for compiler and linker from will-be-pkgconfig file
# created after compiling the bundled GLFW library itself
def parse_libglfwpcin(path)
	libs = cflags = ""
	f = File.open(path)
	f.each do |line|
		case line
		when /Libs/
			tmp = line.chop.split("-lglfw")
			if tmp and tmp.size>=2
				libs = tmp[1]
			end
		when /Cflags/
			tmp = line.chop.split("}")
			if tmp and tmp.size>=2
				cflags = tmp[1]
			end
		end
	end
	[cflags,libs]	
end

RUBYVER = " -DRUBY_VERSION=" + RUBY_VERSION.split(".").join

Mkrf::Generator.new( 'glfw' ) do |g|
	case RUBY_PLATFORM
	when /darwin/
		cf,lib = parse_libglfwpcin($glfw_dir_lib + "/cocoa/libglfw.pc.in")
		g.objects << $glfw_dir_lib + "/cocoa/libglfw.a"
		g.cflags << ' -Wall -I' + $glfw_dir_inc + ' ' + cf << RUBYVER
		g.ldshared << ' -L' + $glfw_dir_lib + '/cocoa/ ' + lib
	when /mswin32/	
		g.objects << $glfw_dir_lib + "/win32/glfw.lib"
		g.cflags << ' -DWIN32 -I' + $glfw_dir_inc + ' ' << RUBYVER
		g.ldshared << ' /NODEFAULTLIB:LIBC '
		g.include_library( 'glu32.lib', '')
		g.include_library( 'opengl32.lib', '')
	else # general posix-x11
		cf,lib = parse_libglfwpcin($glfw_dir_lib + "/x11/libglfw.pc.in")
		g.objects << $glfw_dir_lib + "/x11/libglfw.a"
		g.cflags << ' -Wall -I' + $glfw_dir_inc + ' ' + cf << RUBYVER
		g.ldshared << ' -L' + $glfw_dir_lib + '/x11/ ' + lib
	end
end
