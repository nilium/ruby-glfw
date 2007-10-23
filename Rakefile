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
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'mkrf/rakehelper'

CLEAN.include("ext/glfw/Rakefile", "ext/glfw/mkrf.log", "ext/glfw/*.so",
              "ext/glfw/*.bundle", "lib/*.so", "lib/*.bundle", "ext/glfw/*.o{,bj}", 
              "ext/glfw/*.lib", "ext/glfw/*.exp", "ext/glfw/*.pdb",
              "pkg","html")

setup_extension('glfw', 'glfw')

# setup building and cleaning the bundled GLFW library
case RUBY_PLATFORM
when /(:?mswin|mingw)/ # windows, MSVC 6
	lib_build = "nmake.exe win32-msvc"
	lib_clean = "nmake.exe win32-clean"
when /darwin/ # mac
	lib_build = "make macosx-gcc"
	lib_clean = "make macosx-clean"
else # general posix-x11
	lib_build = "make x11"
	lib_clean = "make x11-clean"
end

desc 'Compiles the bundled GLFW library'
task :glfwlib do
	Dir.chdir("glfw-src") do
		sh lib_build
	end
end

# full cleanup
desc 'Cleanup, includes cleaup of the bunded GLFW library'
task :distclean => [:clean] do
	Dir.chdir("glfw-src") do
		sh lib_clean
	end
end

# setup the build
case RUBY_PLATFORM
when /(:?mswin|mingw)/
	# rake on windows doesn't work properly for subdirectories
	# so iterate manually
	begin
		Dir.mkdir("lib")
	rescue
	end
	task :default => [:glfwlib] do
		Dir.chdir("ext\\glfw") do
			sh "ruby mkrf_conf.rb"
			sh "call rake --nosearch"
			sh "copy glfw.so ..\\..\\lib"
		end
	end
else
	# other systems
	task :default => [:glfwlib,:glfw]
end

# for gem building
task :extension => :default

# build documentation
rd = Rake::RDocTask.new do |rdoc|
  rdoc.main = "README.API"
  rdoc.title    = "GLFW bindings for Ruby"
  rdoc.rdoc_files.include('README.API', 'ext/glfw/glfw.c')
end

# Define the files that will go into the gem
gem_files = FileList["{lib,ext,examples,glfw-src,website}/**/*","README"]
gem_files = gem_files.exclude("**/*.so", "**/*.o{,bj}", "ext/glfw/*.log","ext/glfw/Rakefile")

spec = Gem::Specification.new do |s|
	s.name              = "ruby-glfw"
	s.version           = "0.9"
	s.author            = "Jan Dvorak"
	s.email             = "jan.dvorak@kraxnet.cz"
	s.homepage          = "http://ruby-glfw.rubyforge.org"
	s.platform          = Gem::Platform::RUBY
	s.summary           = "GLFW library bindings for Ruby"
	s.rubyforge_project = "ruby-glfw"
	s.files             = gem_files
	s.extensions        << 'Rakefile'
	s.require_path      = "lib"
	s.has_rdoc          = true
	s.rdoc_options 			<< '--main' << rd.main << '--title' << rd.title
  s.extra_rdoc_files = rd.rdoc_files
	s.add_dependency("mkrf", ">=0.2.0")
	s.add_dependency("rake")
end

# Create a task for creating a ruby gem
Rake::GemPackageTask.new(spec) do |pkg|
    pkg.gem_spec = spec
    pkg.need_tar = true
end
