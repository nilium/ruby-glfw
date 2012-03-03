# ruby-glfw

## What is ruby-glfw?

ruby-glfw contains Ruby bindings for the [GLFW library].  This currently
includes the GLFW 2.7.3 source code in the package.  This particular fork is my
attempt to fix some build issues in ruby-glfw, and is based on the old
[ruby-glfw gem][deathtrap] (unmaintained since 2008-ish) by Jan Dvorak.


## What's GLFW?

A convenient quote from [glfw.org][GLFW library]:

> GLFW is a free, Open Source, multi-platform library for opening a window,
> creating an OpenGL context and managing input. It is easy to integrate into
> existing applications and does not lay claim to the main loop.

Yeah, that about sums it up. It handles the things that aren't exciting so you
can write the cool stuff.


## What platforms are supported?

Though the original ruby-glfw gem claimed support for the three major OSes,
Linux, Windows, and OS X, I cannot say the same since I haven't tested my fork
on anything other than OS X.

So, OS X is the only supported platform.  If you do test this on another OS, do
let me know.

-------------------------------------------------------------------------------

Because you might be looking for a list and skipping what I wrote above:

* OS X: Works
* Windows: Untested
* Any variety of Linux: Untested
* Obscure OSes only three people use: Untested


## Installation

I am only using ruby-glfw under Ruby 1.9.3, so it will _probably_ work under
1.9.x, but consider yourself warned.  Chances are nothing in use requires
1.9 and up, however, and ruby-glfw originally supported 1.8.5, so just give
it a shot if you're still on 1.8.5 or higher.

Run `rake package` and install the gem (under _pkg/_) and you should be fine.

    $ rake package
    $ cd pkg
    $ sudo gem install ruby-glfw-0.9.2.gem

Substitute 0.9.2 for whatever version number you've packages, of course.

#### Support Notes

Some additional notes from Jan Dvorak's HTML readme thing that accompanied
ruby-glfw (why it was an HTML file is beyond me), most of which I've edited for
some correctness:

* _Windows notes:_ Originally, ruby-glfw required MSVC 6.0 -- shame on Jan for
  this. You need MinGW to build from this particular fork of ruby-glfw. I don't
  know if it works, but requiring MSVC 6.0 is cruel and unusual.

  There was also a binary gem available, this is still true for the [old gem].
  I take no responsibility for whether that works.

* _Mac OS X notes:_ You may need a version of Ruby from someplace other than
  Apple, though this is not required under Mac OS 10.7 (Lion). Consider using
  [rbenv] and [ruby-build] to handle this cleanly. Avoid RVM if you can help
  it -- RVM wreaks havoc on your shell.

* _Linux notes:_ On some distributions you may need aditional development
  packages, like xorg-dev or ruby1.8-dev.

[rbenv]: https://github.com/sstephenson/rbenv
[ruby-build]: https://github.com/sstephenson/ruby-build
[old gem]: http://rubyforge.org/frs/?group_id=4539


## Links

* Project page: https://github.com/nilium/ruby-glfw
* The old ruby-glfw: http://ruby-glfw.rubyforge.org/
* GLFW: http://www.glfw.org


[GLFW library]: http://www.glfw.org
[deathtrap]: http://ruby-glfw.rubyforge.org/