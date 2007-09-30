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

def find_file(file, paths)
	paths.each do |path|
		p = path + "/" + file
		return p if File.exist?(p)
	end
	raise "#{file} not found"
end

Mkrf::Generator.new( 'glfw' ) do |g|
    case RUBY_PLATFORM
    when /darwin/
#        g.ldshared << ' -framework OpenGL'
#		TODO: test on darwin/mac
    when /mswin32/
        g.cflags << ' -DWIN32'
        g.include_library( 'opengl32.lib', 'glVertex3d')
#        g.include_library( 'user32.lib', '') # is this needed ?
#		TODO: add glfw.lib/dll dependency
    else # unix
				# the GLFW library is installed static-only by default, so link it statically
				g.objects << find_file("libglfw.a",["/lib","/usr/lib","/usr/local/lib","/usr/X11R6/lib"])
        g.cflags << ' -Wall `pkg-config --cflags libglfw`'
				g.ldshared << ' `pkg-config --libs libglfw`'
    end
end
