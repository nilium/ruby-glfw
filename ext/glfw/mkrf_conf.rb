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

# parses options for compiler and linker from will-be-pkgconfig file
# created after compiling the glfw library itself
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

Mkrf::Generator.new( 'glfw' ) do |g|
	case RUBY_PLATFORM
	when /darwin/
		cf,lib = parse_libglfwpcin("../../glfw-src/lib/macosx/libglfw.pc.in")
		g.objects << "../../glfw-src/lib/macosx/libglfw.a"
		g.cflags << ' -Wall -I../../glfw-src/include ' + cf
		g.ldshared << ' -L../../glfw-src/lib/macosx/ ' + lib
	when /mswin32/	
		g.cflags << ' -DWIN32'
		g.include_library( 'opengl32.lib', 'glVertex3d')
		#        g.include_library( 'user32.lib', '') # is this needed ?
		#		TODO: add glfw.lib/dll dependency
	else # general posix-x11
		cf,lib = parse_libglfwpcin("../../glfw-src/lib/x11/libglfw.pc.in")
		g.objects << "../../glfw-src/lib/x11/libglfw.a"
		g.cflags << ' -Wall -I../../glfw-src/include ' + cf
		g.ldshared << ' -L../../glfw-src/lib/x11/ ' + lib
	end
end
