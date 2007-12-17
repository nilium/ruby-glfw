/*
 Copyright (C) 2007 Jan Dvorak <jan.dvorak@kraxnet.cz>

 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.

 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software
	in a product, an acknowledgment in the product documentation would be
	appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and must not be
	misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

#include <ruby.h>
#include <GL/glfw.h>

#ifdef WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT
#endif

#define MAGIC	256

static VALUE module;
static int call_id; /* internal ruby id for method 'call' */

#define GLFW_SET_CALLBACK_FUNC(_name_) \
static VALUE glfw_Set##_name_##Callback(VALUE obj,VALUE arg1) \
{ \
	if (!rb_obj_is_kind_of(arg1,rb_cProc) && !NIL_P(arg1)) \
		rb_raise(rb_eTypeError, "need Proc object as argument"); \
\
	if (NIL_P(arg1)) { \
		_name_##_cb_ruby_func = Qnil; \
		glfwSet##_name_##Callback(NULL); \
	} else { \
		_name_##_cb_ruby_func = arg1; \
		glfwSet##_name_##Callback(_name_##_cb); \
	} \
\
	return Qnil; \
}

#define GL_BOOL_TO_RUBY_BOOL(x) x == GL_TRUE ? Qtrue : Qfalse 
#define RUBY_BOOL_TO_GL_BOOL_INT(x) x == Qtrue ? GL_TRUE : (x == Qfalse ? GL_FALSE : NUM2INT(x))

/* API ref section 3.1 */

/* Initializes GLFW library. This function is called automatically on module load */
 
static VALUE glfw_Init(VALUE obj)
{
	/* no-op, initialized at module load */
	return Qtrue;
}

/* Terminates GLFW library. This function is called automatically on program exit */

static VALUE glfw_Terminate(VALUE obj)
{
	glfwTerminate();
	return Qnil;
}

/*
 * call-seq:
 *  glfwGetVersion() => [major,minor,revision]
 *
 * Returns GLFW library version
 */
static VALUE glfw_GetVersion(VALUE obj)
{
	int major = 0;
	int minor = 0;
	int rev = 0;
	glfwGetVersion(&major,&minor,&rev);
	return rb_ary_new3(3,INT2NUM(major),INT2NUM(minor),INT2NUM(rev));
}

/* API ref section 3.2 */

/*
 * call-seq:
 *  glfwOpenWindow(width,height,redbits,greenbits,bluebits,alphabits,depthbits,stencilbits,mode) => true/false
 *
 * Opens GLFW window, returns true on success
 */
static VALUE glfw_OpenWindow(obj,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)
VALUE obj,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9;
{
	int ret;
	
	ret = glfwOpenWindow(NUM2INT(arg1),NUM2INT(arg2),NUM2INT(arg3),NUM2INT(arg4),NUM2INT(arg5),
											 NUM2INT(arg6),NUM2INT(arg7),NUM2INT(arg8),NUM2INT(arg9));
	return GL_BOOL_TO_RUBY_BOOL(ret);
}

/*
 * call-seq:
 *  glfwOpenWindowHint(target,hint)
 *
 * Sets additional properties for yet to be opened window
 */
static VALUE glfw_OpenWindowHint(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	glfwOpenWindowHint(NUM2INT(arg1),RUBY_BOOL_TO_GL_BOOL_INT(arg2));
	return Qnil;
}

/* Closes window */
static VALUE glfw_CloseWindow(VALUE obj)
{
	glfwCloseWindow();
	return Qnil;
}

static VALUE WindowClose_cb_ruby_func = Qnil;
int GLFWCALL WindowClose_cb(void)
{
	int ret;
	ret = rb_funcall(WindowClose_cb_ruby_func,call_id,0);
	return RUBY_BOOL_TO_GL_BOOL_INT(ret);
}
GLFW_SET_CALLBACK_FUNC(WindowClose)

/*
 * call-seq:
 *  glfwSetWindowTitle(title)
 *
 * Sets window title
 */
static VALUE glfw_SetWindowTitle(obj,arg1)
VALUE obj,arg1;
{
	Check_Type(arg1,T_STRING);
	glfwSetWindowTitle(RSTRING_PTR(arg1));
	return Qnil;
}

/*
 * call-seq:
 *  glfwSetWindowSize(width,height)
 *
 * Sets window size
 */
static VALUE glfw_SetWindowSize(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	glfwSetWindowSize(NUM2INT(arg1),NUM2INT(arg2));
	return Qnil;
}

/*
 * call-seq:
 *  glfwSetWindowPos(x,y)
 *
 * Sets window position
 */
static VALUE glfw_SetWindowPos(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	glfwSetWindowPos(NUM2INT(arg1),NUM2INT(arg2));
	return Qnil;
}

/*
 * call-seq:
 *  glfwGetWindowSize() => [width, height]
 *
 * Returns current window size
 */
static VALUE glfw_GetWindowSize(VALUE obj)
{
	int width=0;
	int height=0;
	glfwGetWindowSize(&width,&height);
	return rb_ary_new3(2,INT2NUM(width),INT2NUM(height));
}

static VALUE WindowSize_cb_ruby_func = Qnil;
void GLFWCALL WindowSize_cb(int width, int height)
{
	rb_funcall(WindowSize_cb_ruby_func,call_id,2,INT2NUM(width),INT2NUM(height));
}
GLFW_SET_CALLBACK_FUNC(WindowSize)

/* Iconifies window */
static VALUE glfw_IconifyWindow(VALUE obj)
{
	glfwIconifyWindow();
	return Qnil;
}

/* Restores window */
static VALUE glfw_RestoreWindow(VALUE obj)
{
	glfwRestoreWindow();
	return Qnil;
}

/*
 * call-seq:
 *  glfwGetWindowParam(param) => Fixnum or true/false
 *
 * Returns value of window parameter 'param' , either as integer or boolean
 */
static VALUE glfw_GetWindowParam(VALUE obj,VALUE arg1)
{
	int param;
	int ret;
	param = NUM2INT(arg1);
	ret = glfwGetWindowParam(param);

	switch(param) {
		case GLFW_OPENED:
		case GLFW_ACTIVE:
		case GLFW_ICONIFIED:
		case GLFW_ACCELERATED:
		case GLFW_STEREO:
		case GLFW_WINDOW_NO_RESIZE:
			return GL_BOOL_TO_RUBY_BOOL(ret);
		default:
			return INT2NUM(ret);
	}
	/* not reached */
}

/* Swaps OpenGL buffers in double-buffering mode */
static VALUE glfw_SwapBuffers(VALUE obj)
{
	glfwSwapBuffers();
	return Qnil;
}

/*
 * call-seq:
 *  glfwSwapInterval(interval)
 *
 * Sets minimal number of monitor frame retraces before buffers can be swapped (a.k.a Vertical sync), 0 = off
 */
static VALUE glfw_SwapInterval(VALUE obj,VALUE arg1)
{
	glfwSwapInterval(NUM2INT(arg1));
	return Qnil;
}

static VALUE WindowRefresh_cb_ruby_func = Qnil;
void GLFWCALL WindowRefresh_cb(void)
{
	rb_funcall(WindowRefresh_cb_ruby_func,call_id,0);
}
GLFW_SET_CALLBACK_FUNC(WindowRefresh)

/* API ref section 3.3 */

static VALUE Vidmode_class = Qnil;

VALUE vidmode_to_ruby(GLFWvidmode vm)
{
		VALUE vm_r;

		if (Vidmode_class==Qnil)
			Vidmode_class = rb_eval_string("Struct.new('Vidmode', :Width,:Height,:RedBits,:GreenBits,:BlueBits)");

		vm_r = rb_funcall(Vidmode_class,rb_intern("new"),5,
											INT2NUM(vm.Width),INT2NUM(vm.Height),
											INT2NUM(vm.RedBits),INT2NUM(vm.GreenBits),INT2NUM(vm.BlueBits) );
		return vm_r;
}

/*
 * call-seq:
 *  glfwGetVideoModes() => [Vidmode,...]
 *
 * Returns all supported video modes in form of array of instances of Vidmode class
 * 
 * Vidmode class has following attributes:
 * * Width - screen width
 * * Height - screen height
 * * Redbits - number of bits per red channel
 * * GreenBits - number of bits per green channel
 * * BlueBits - number of bits per blue channel
 * 
 * BPP = Redbits + GreenBits + BlueBits
 */
static VALUE glfw_GetVideoModes(VALUE obj)
{
	GLFWvidmode modes[MAGIC];
	int count;
	int i;
	VALUE ret;

	count = glfwGetVideoModes(modes,MAGIC);
	ret = rb_ary_new2(count);
	for(i=0;i<count;++i)
		rb_ary_push(ret,vidmode_to_ruby(modes[i]));

	return ret;
}

/*
 * call-seq:
 *  glfwGetDesktopMode() => Vidmode
 *
 * Returns current desktop mode in form of instance of Vidmode class - see glfwGetVideoModes for details.
 */
static VALUE glfw_GetDesktopMode(VALUE obj)
{
	GLFWvidmode vm;
	glfwGetDesktopMode(&vm);
	return vidmode_to_ruby(vm);	
}

/* API ref section 3.4 */

/* Polls events */
static VALUE glfw_PollEvents(VALUE obj)
{
	glfwPollEvents();
	return Qnil;
}

/* Waits for events */
static VALUE glfw_WaitEvents(VALUE obj)
{
	glfwWaitEvents();
	return Qnil;
}

/*
 * call-seq:
 *  glfwGetKey(key) => GLFW_PRESS/GLFW_RELEASE
 *
 * Queries status of key 'key'
 */
static VALUE glfw_GetKey(VALUE obj,VALUE arg1)
{
	int ret;
	ret = glfwGetKey(NUM2INT(arg1));
	return INT2NUM(ret);
}


/*
 * call-seq:
 *  glfwGetMouseButton(button) => GLFW_PRESS/GLFW_RELEASE
 *
 * Queries status of mouse button 'button'
 */
static VALUE glfw_GetMouseButton(VALUE obj,VALUE arg1)
{
	int ret;
	ret = glfwGetMouseButton(NUM2INT(arg1));
	return INT2NUM(ret);
}

/*
 * call-seq:
 *  glfwGetMousePos() => [xpos,ypos]
 *
 * Returns current mouse position
 */
static VALUE glfw_GetMousePos(VALUE obj)
{
	int xpos=0;
	int ypos=0;
	glfwGetMousePos(&xpos,&ypos);
	return rb_ary_new3(2,INT2NUM(xpos),INT2NUM(ypos));
}

/*
 * call-seq:
 *  glfwSetMousePos(xpos,ypos)
 *
 * Sets mouse position
 */
static VALUE glfw_SetMousePos(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	glfwSetMousePos(NUM2INT(arg1),NUM2INT(arg2));
	return Qnil;
}

/*
 * call-seq:
 *  glfwGetMouseWheel() => wheelpos
 *
 * Returns current mouse wheel position
 */
static VALUE glfw_GetMouseWheel(VALUE obj)
{
	int ret;
	ret = glfwGetMouseWheel();
	return INT2NUM(ret);
}

/*
 * call-seq:
 *  glfwSetMouseWheelPos(wheelpos)
 *
 * Sets mouse wheel position
 */
static VALUE glfw_SetMouseWheel(VALUE obj,VALUE arg1)
{
	glfwSetMouseWheel(NUM2INT(arg1));
	return Qnil;
}

/*
 * call-seq:
 *  glfwGetJoystickPos(joystick) => [axis_0_pos, axis_1_pos, ...]
 *
 * Returns joystick axes positions or nil if given joystick is not present
 */
static VALUE glfw_GetJoystickPos(VALUE obj,VALUE arg1)
{
	float *pos;
	int numaxes;
	int count;
	int i;
	VALUE ret;

	numaxes = glfwGetJoystickParam(NUM2INT(arg1),GLFW_AXES);
	if (numaxes<=0)
		return Qnil;

	pos = ALLOC_N(float,numaxes);
	count = glfwGetJoystickPos(NUM2INT(arg1),pos,numaxes);
	ret = rb_ary_new2(count);
	for(i=0;i<count;++i)
		rb_ary_push(ret,rb_float_new(pos[i]));
	xfree(pos);
	return ret;
}

/*
 * call-seq:
 *  glfwGetJoystickButtons(joystick) => [button_0_state, button_1_state, ...]
 *
 * Returns joystick button states (which are either GLFW_PRESS or GLFW_RELEASE) or nil if given joystick is not present
 */
static VALUE glfw_GetJoystickButtons(VALUE obj,VALUE arg1)
{
	unsigned char *buttons;
	int numbuttons;
	int count;
	int i;
	VALUE ret;

	numbuttons = glfwGetJoystickParam(NUM2INT(arg1),GLFW_BUTTONS);
	if (numbuttons<=0)
		return Qnil;

	buttons = ALLOC_N(unsigned char,numbuttons);
	count = glfwGetJoystickButtons(NUM2INT(arg1),buttons,numbuttons);
	ret = rb_ary_new2(count);
	for(i=0;i<count;++i)
		rb_ary_push(ret,INT2NUM(buttons[i]));
	xfree(buttons);
	return ret;
}

static VALUE Key_cb_ruby_func = Qnil;
void GLFWCALL Key_cb(int key, int action)
{
	rb_funcall(Key_cb_ruby_func,call_id,2,INT2NUM(key),INT2NUM(action));
}
GLFW_SET_CALLBACK_FUNC(Key)

static VALUE Char_cb_ruby_func = Qnil;
void GLFWCALL Char_cb(int character, int action)
{
	rb_funcall(Char_cb_ruby_func,call_id,2,INT2NUM(character),INT2NUM(action));
}
GLFW_SET_CALLBACK_FUNC(Char)

static VALUE MouseButton_cb_ruby_func = Qnil;
void GLFWCALL MouseButton_cb(int button, int action)
{
	rb_funcall(MouseButton_cb_ruby_func,call_id,2,INT2NUM(button),INT2NUM(action));
}
GLFW_SET_CALLBACK_FUNC(MouseButton)

static VALUE MousePos_cb_ruby_func = Qnil;
void GLFWCALL MousePos_cb(int x, int y)
{
	rb_funcall(MousePos_cb_ruby_func,call_id,2,INT2NUM(x),INT2NUM(y));
}
GLFW_SET_CALLBACK_FUNC(MousePos)

static VALUE MouseWheel_cb_ruby_func = Qnil;
void GLFWCALL MouseWheel_cb(int pos)
{
	rb_funcall(MouseWheel_cb_ruby_func,call_id,1,INT2NUM(pos));
}
GLFW_SET_CALLBACK_FUNC(MouseWheel)


/*
 * call-seq:
 *  glfwGetJoystickParam(joystick,param) => value or true/false
 * 
 * Queries joystick parameters
 */
static VALUE glfw_GetJoystickParam(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	int param;
	int ret;
	param = NUM2INT(arg2);
	ret = glfwGetJoystickParam(NUM2INT(arg1),NUM2INT(arg2));
	if (param==GLFW_PRESENT)
		return GL_BOOL_TO_RUBY_BOOL(ret);
	else
		return INT2NUM(ret);
}

/* API ref section 3.5 */

/*
 * call-seq:
 *  glfwGetTime() => Float
 *
 *  Returns time (as Float) passed since last call to glfwInit or glfwSetTime 
 */
static VALUE glfw_GetTime(VALUE obj)
{
	double time;
	time = glfwGetTime();
	return rb_float_new(time);
}

/*
 * call-seq:
 *  glfwSetTime(time)
 *
 * Sets timer to given time (Float)
 */
static VALUE glfw_SetTime(VALUE obj,VALUE arg1)
{
	glfwSetTime(NUM2DBL(arg1));
	return Qnil;
}

/*
 * call-seq:
 *  glfwSleep(time)
 *
 * Sleeps for given amount of time (Float)
 */
static VALUE glfw_Sleep(VALUE obj,VALUE arg1)
{
	glfwSleep(NUM2DBL(arg1));
	return Qnil;
}

/* API ref section 3.6 */

VALUE GLFWimage_class; /* GLFWimage class */

void GLFWimage_free(void *p)
{
	if (p) {
		glfwFreeImage((GLFWimage *)p);
		xfree(p);
	}
}

/* Returns width of the image */  
static VALUE GLFWimage_width(VALUE obj)
{
	GLFWimage *img;
	Data_Get_Struct(obj,GLFWimage,img);
	return INT2NUM(img->Width);
}

/* Returns height of the image */  
static VALUE GLFWimage_height(VALUE obj)
{
	GLFWimage *img;
	Data_Get_Struct(obj,GLFWimage,img);
	return INT2NUM(img->Height);
}

/* Returns OpenGL format of the image (GL_RGB, GL_LUMINANCE etc.) */  
static VALUE GLFWimage_format(VALUE obj)
{
	GLFWimage *img;
	Data_Get_Struct(obj,GLFWimage,img);
	return INT2NUM(img->Format);
}

/* Returns number of bytes per pixel for the image */  
static VALUE GLFWimage_BPP(VALUE obj)
{
	GLFWimage *img;
	Data_Get_Struct(obj,GLFWimage,img);
	return INT2NUM(img->BytesPerPixel);
}

/*
 * call-seq:
 *  glfwReadImage(filename, flags) => GLFWimage or nil
 *
 * Reads image from file and stores it as GLFWimage object
 */
static VALUE glfw_ReadImage(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	GLFWimage *img;
	int ret;

	Check_Type(arg1,T_STRING);
	img = ALLOC(GLFWimage);
	ret = glfwReadImage(RSTRING_PTR(arg1),img,NUM2INT(arg2));
	if (ret==GL_FALSE) {
		xfree(img);
		return Qnil;
	}
	return Data_Wrap_Struct(GLFWimage_class,0,GLFWimage_free,img);
}

/*
 * call-seq:
 *  glfwReadMemoryImage(string, flags) => GLFWimage or nil
 *
 * Reads image from string (containing raw image data) and stores it as GLFWimage object
 */
static VALUE glfw_ReadMemoryImage(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	GLFWimage *img;
	int ret;

	Check_Type(arg1,T_STRING);
	img = ALLOC(GLFWimage);
	ret = glfwReadMemoryImage(RSTRING_PTR(arg1),RSTRING_LEN(arg1),img,NUM2INT(arg2));
	if (ret==GL_FALSE) {
		xfree(img);
		return Qnil;
	}
	return Data_Wrap_Struct(GLFWimage_class,0,GLFWimage_free,img);
}

/*
 * call-seq:
 *  glfwFreeImage(GLFWimage)
 * 
 * Frees data in GLFWimage object and marks it for deletion.
 */
static VALUE glfw_FreeImage(VALUE obj,VALUE arg1)
{
	GLFWimage *img;
	Data_Get_Struct(arg1, GLFWimage, img);
	glfwFreeImage(img);
	return Qnil;
}

/*
 * call-seq:
 *  glfwLoadTexture2D(filename,flags) => true or false
 *
 * Reads image from file and loads it as texture to current texturing unit
 */
static VALUE glfw_LoadTexture2D(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	int ret;
	Check_Type(arg1,T_STRING);
	ret = glfwLoadTexture2D(RSTRING_PTR(arg1),NUM2INT(arg2));
	return GL_BOOL_TO_RUBY_BOOL(ret);
}

/*
 * call-seq:
 *  glfwLoadMemoryTexture2D(string,flags) => true or false
 *
 * Reads raw image data from string and loads it as texture to current texturing unit
 */
static VALUE glfw_LoadMemoryTexture2D(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	int ret;
	Check_Type(arg1,T_STRING);
	ret = glfwLoadMemoryTexture2D(RSTRING_PTR(arg1),RSTRING_LEN(arg1),NUM2INT(arg2));
	return GL_BOOL_TO_RUBY_BOOL(ret);
}

/*
 * call-seq:
 *  glfwLoadTextureImage2D(GLFWimage,flags) => true or false
 *
 * Reads image from GLFWimage object and loads it as texture to current texturing unit
 */
static VALUE glfw_LoadTextureImage2D(obj,arg1,arg2)
VALUE obj,arg1,arg2;
{
	int ret;
	GLFWimage *img;
	Data_Get_Struct(arg1, GLFWimage, img);
	ret = glfwLoadTextureImage2D(img,NUM2INT(arg2));
	return GL_BOOL_TO_RUBY_BOOL(ret);
}

/* API ref section 3.7 */

/*
 * call-seq:
 *  glfwExtensionSupported(extension_name) => true/false
 *
 * Is given OpenGL extension supported ?
 */
static VALUE glfw_ExtensionSupported(VALUE obj,VALUE arg1)
{
	int ret;
	Check_Type(arg1,T_STRING);
	ret = glfwExtensionSupported(RSTRING_PTR(arg1));
	return GL_BOOL_TO_RUBY_BOOL(ret);
}

/* NOTE: glfwGetProcAddress not implemented, use ruby-opengl functions instead */

/*
 * call-seq:
 *  glfwGetGLVersion() => [major,minor,revision]
 *
 * Returns installed OpenGL version
 */
static VALUE glfw_GetGLVersion(VALUE obj)
{
	int major = 0;
	int minor = 0;
	int rev = 0;
	glfwGetGLVersion(&major,&minor,&rev);
	return rb_ary_new3(3,INT2NUM(major),INT2NUM(minor),INT2NUM(rev));
}

/* API ref section 3.8-3.10 
   NOTE: GLFW Threads not implemented as ruby has its own threading */

/* API ref section 3.11 */

/*
 * call-seq:
 *  glfwEnable(feature)
 *
 * Enables certain GLFW feature
 */
static VALUE glfw_Enable(VALUE obj,VALUE arg1)
{
	glfwEnable(NUM2INT(arg1));
	return Qnil;
}

/*
 * call-seq:
 *  glfwDisable(feature)
 *
 * Disables certain GLFW feature
 */
static VALUE glfw_Disable(VALUE obj,VALUE arg1)
{
	glfwDisable(NUM2INT(arg1));
	return Qnil;
}

/* call-seq:
 *  glfwGetNumberOfProcessors() => Fixnum
 *
 * Returns current number of logical processors (or cores)
 */
static VALUE glfw_GetNumberOfProcessors(VALUE obj)
{
	int ret;
	ret = glfwGetNumberOfProcessors();
	return INT2NUM(ret);
}

/* Hack for RDOC */
#if 0
/*
 * call-seq:
 *  glfwSetWindowCloseCallback( Proc() => true/false )
 *
 * Sets function to be executed at window close. The supplied function takes no parameters, and
 * should return either true or false, indicating if the window should be closed.
 */
VALUE glfw_SetWindowCloseCallback()
/*
 * call-seq:
 *  glfwSetWindowSizeCallback( Proc(width,height) )
 *
 * Sets function to be executed at window size change. The supplied function takes two arguments,
 * representing new width and height of the window 
 */
VALUE glfw_SetWindowSizeCallback()
/*
 * call-seq:
 *  glfwSetWindowRefreshCallback( Proc() )
 *
 * Sets function to be executed at window refresh. The supplied function takes no arguments.
 */
VALUE glfw_SetWindowRefreshCallback()
/*
 * call-seq:
 *  glfwSetKeyCallback( Proc(key,action) )
 *
 * Sets function to be executed at key press or release. The supplied function takes two arguments,
 * key and action, where action is either GLFW_PRESS or GLFW_RELEASE
 */
VALUE glfw_SetKeyCallback()
/*
 * call-seq:
 *  glfwSetCharCallback( Proc(char,action) )
 *
 * Sets function to be executed every time printable character is generated by the keyboard.
 * The supplied function takes two arguments, char and action, where char is unicode character,
 * and action is either GLFW_PRESS or GLFW_RELEASE
 */
VALUE glfw_SetCharCallback()
/*
 * call-seq:
 *  glfwSetMouseButtonCallback( Proc(button,action) )
 *
 * Sets function to be executed at mouse button press or release. The supplied function takes two
 * arguments, button and action, where action is either GLFW_PRESS or GLFW_RELEASE
 */
VALUE glfw_SetMouseButtonCallback()
/*
 * call-seq:
 *  glfwSetMousePosCallback( Proc(xpos,ypos) )
 *
 * Sets function to be executed at mouse movement. The supplied function takes two arguments,
 * representing the new mouse coordinates x and y
 */
VALUE glfw_SetMousePosCallback()
/*
 * call-seq:
 *  glfwSetMouseWheelCallback( Proc(wheelpos) )
 *
 * Sets function to be executed at mouse wheel movement. The supplied function takes one argument
 * representing the new mouse wheel position
 */
VALUE glfw_SetMouseWheelCallback()
#endif

DLLEXPORT void Init_glfw()
{
	/* Let's initialize the GLFW library at module load */
	if (glfwInit()!=GL_TRUE) {
	  rb_raise(rb_eRuntimeError, "GLFW library initialization failed");
		/* not reached */
	}
	
	/* Glfw module - this module contains all functions and constants in the GLFW bindings */
	module = rb_define_module("Glfw");

	call_id = rb_intern("call");

	/*
	  GLFWimage is class which instances contains image loaded by GLFW imaging API.

	  Image data can be manually freed by calling glfwFreeImage(object)
	*/
	GLFWimage_class = rb_define_class("GLFWimage", rb_cObject);
	rb_define_method(GLFWimage_class, "Width", GLFWimage_width, 0);
	rb_define_method(GLFWimage_class, "Height", GLFWimage_height, 0);
	rb_define_method(GLFWimage_class, "Format", GLFWimage_format, 0);
	rb_define_method(GLFWimage_class, "BytesPerPixel", GLFWimage_BPP, 0);

	/* register Vidmode struct class to garbage collector */
	rb_gc_register_address(&Vidmode_class);

	/* register callback handlers to garbage collector */
	rb_gc_register_address(&WindowClose_cb_ruby_func);
	rb_gc_register_address(&WindowSize_cb_ruby_func);
	rb_gc_register_address(&WindowRefresh_cb_ruby_func);
	rb_gc_register_address(&Key_cb_ruby_func);
	rb_gc_register_address(&Char_cb_ruby_func);
	rb_gc_register_address(&MouseButton_cb_ruby_func);
	rb_gc_register_address(&MousePos_cb_ruby_func);
	rb_gc_register_address(&MouseWheel_cb_ruby_func);

	/* functions */
	rb_define_module_function(module,"glfwInit", glfw_Init, 0);
	rb_define_module_function(module,"glfwTerminate", glfw_Terminate, 0);
	rb_define_module_function(module,"glfwGetVersion", glfw_GetVersion, 0);

	rb_define_module_function(module,"glfwOpenWindow", glfw_OpenWindow, 9);
	rb_define_module_function(module,"glfwOpenWindowHint", glfw_OpenWindowHint, 2);
	rb_define_module_function(module,"glfwCloseWindow", glfw_CloseWindow, 0);
	rb_define_module_function(module,"glfwSetWindowCloseCallback", glfw_SetWindowCloseCallback, 1);
	rb_define_module_function(module,"glfwSetWindowTitle", glfw_SetWindowTitle, 1);
	rb_define_module_function(module,"glfwSetWindowSize", glfw_SetWindowSize, 2);
	rb_define_module_function(module,"glfwSetWindowPos", glfw_SetWindowPos, 2);
	rb_define_module_function(module,"glfwGetWindowSize", glfw_GetWindowSize, 0);
	rb_define_module_function(module,"glfwSetWindowSizeCallback", glfw_SetWindowSizeCallback, 1);
	rb_define_module_function(module,"glfwIconifyWindow", glfw_IconifyWindow, 0);
	rb_define_module_function(module,"glfwRestoreWindow", glfw_RestoreWindow, 0);
	rb_define_module_function(module,"glfwGetWindowParam", glfw_GetWindowParam, 1);
	rb_define_module_function(module,"glfwSwapBuffers", glfw_SwapBuffers, 0);
	rb_define_module_function(module,"glfwSwapInterval", glfw_SwapInterval, 1);
	rb_define_module_function(module,"glfwSetWindowRefreshCallback", glfw_SetWindowRefreshCallback, 1);

	rb_define_module_function(module,"glfwGetVideoModes", glfw_GetVideoModes, 0);
	rb_define_module_function(module,"glfwGetDesktopMode", glfw_GetDesktopMode, 0);

	rb_define_module_function(module,"glfwPollEvents", glfw_PollEvents, 0);
	rb_define_module_function(module,"glfwWaitEvents", glfw_WaitEvents, 0);
	rb_define_module_function(module,"glfwGetKey", glfw_GetKey, 1);
	rb_define_module_function(module,"glfwGetMouseButton", glfw_GetMouseButton, 1);
	rb_define_module_function(module,"glfwGetMousePos", glfw_GetMousePos, 0);
	rb_define_module_function(module,"glfwSetMousePos", glfw_SetMousePos, 2);
	rb_define_module_function(module,"glfwGetMouseWheel", glfw_GetMouseWheel, 0);
	rb_define_module_function(module,"glfwSetMouseWheel", glfw_SetMouseWheel, 1);
	rb_define_module_function(module,"glfwSetKeyCallback", glfw_SetKeyCallback, 1);
	rb_define_module_function(module,"glfwSetCharCallback", glfw_SetCharCallback, 1);
	rb_define_module_function(module,"glfwSetMouseButtonCallback", glfw_SetMouseButtonCallback, 1);
	rb_define_module_function(module,"glfwSetMousePosCallback", glfw_SetMousePosCallback, 1);
	rb_define_module_function(module,"glfwSetMouseWheelCallback", glfw_SetMouseWheelCallback, 1);
	rb_define_module_function(module,"glfwGetJoystickParam", glfw_GetJoystickParam, 2);
	rb_define_module_function(module,"glfwGetJoystickPos", glfw_GetJoystickPos, 1);
	rb_define_module_function(module,"glfwGetJoystickButtons", glfw_GetJoystickButtons, 1);

	rb_define_module_function(module,"glfwGetTime", glfw_GetTime, 0);
	rb_define_module_function(module,"glfwSetTime", glfw_SetTime, 1);
	rb_define_module_function(module,"glfwSleep", glfw_Sleep, 1);

	rb_define_module_function(module,"glfwReadImage", glfw_ReadImage, 2);
	rb_define_module_function(module,"glfwReadMemoryImage", glfw_ReadMemoryImage, 2);
	rb_define_module_function(module,"glfwFreeImage", glfw_FreeImage, 1);
	rb_define_module_function(module,"glfwLoadTexture2D", glfw_LoadTexture2D, 2);
	rb_define_module_function(module,"glfwLoadMemoryTexture2D", glfw_LoadMemoryTexture2D, 2);
	rb_define_module_function(module,"glfwLoadTextureImage2D", glfw_LoadTextureImage2D, 2);

	rb_define_module_function(module,"glfwExtensionSupported", glfw_ExtensionSupported, 1);
	rb_define_module_function(module,"glfwGetGLVersion", glfw_GetGLVersion, 0);
	rb_define_module_function(module,"glfwEnable", glfw_Enable, 1);
	rb_define_module_function(module,"glfwDisable", glfw_Disable, 1);
	rb_define_module_function(module,"glfwGetNumberOfProcessors", glfw_GetNumberOfProcessors, 0);

	/* constants */
	rb_define_const(module, "GLFW_VERSION_MAJOR", INT2NUM(GLFW_VERSION_MAJOR));
	rb_define_const(module, "GLFW_VERSION_MINOR", INT2NUM(GLFW_VERSION_MINOR));
	rb_define_const(module, "GLFW_VERSION_REVISION", INT2NUM(GLFW_VERSION_REVISION));
	rb_define_const(module, "GLFW_RELEASE", INT2NUM(GLFW_RELEASE));
	rb_define_const(module, "GLFW_PRESS", INT2NUM(GLFW_PRESS));
	rb_define_const(module, "GLFW_KEY_UNKNOWN", INT2NUM(GLFW_KEY_UNKNOWN));
	rb_define_const(module, "GLFW_KEY_SPACE", INT2NUM(GLFW_KEY_SPACE));
	rb_define_const(module, "GLFW_KEY_SPECIAL", INT2NUM(GLFW_KEY_SPECIAL));
	rb_define_const(module, "GLFW_KEY_ESC", INT2NUM(GLFW_KEY_ESC));
	rb_define_const(module, "GLFW_KEY_F1", INT2NUM(GLFW_KEY_F1));
	rb_define_const(module, "GLFW_KEY_F2", INT2NUM(GLFW_KEY_F2));
	rb_define_const(module, "GLFW_KEY_F3", INT2NUM(GLFW_KEY_F3));
	rb_define_const(module, "GLFW_KEY_F4", INT2NUM(GLFW_KEY_F4));
	rb_define_const(module, "GLFW_KEY_F5", INT2NUM(GLFW_KEY_F5));
	rb_define_const(module, "GLFW_KEY_F6", INT2NUM(GLFW_KEY_F6));
	rb_define_const(module, "GLFW_KEY_F7", INT2NUM(GLFW_KEY_F7));
	rb_define_const(module, "GLFW_KEY_F8", INT2NUM(GLFW_KEY_F8));
	rb_define_const(module, "GLFW_KEY_F9", INT2NUM(GLFW_KEY_F9));
	rb_define_const(module, "GLFW_KEY_F10", INT2NUM(GLFW_KEY_F10));
	rb_define_const(module, "GLFW_KEY_F11", INT2NUM(GLFW_KEY_F11));
	rb_define_const(module, "GLFW_KEY_F12", INT2NUM(GLFW_KEY_F12));
	rb_define_const(module, "GLFW_KEY_F13", INT2NUM(GLFW_KEY_F13));
	rb_define_const(module, "GLFW_KEY_F14", INT2NUM(GLFW_KEY_F14));
	rb_define_const(module, "GLFW_KEY_F15", INT2NUM(GLFW_KEY_F15));
	rb_define_const(module, "GLFW_KEY_F16", INT2NUM(GLFW_KEY_F16));
	rb_define_const(module, "GLFW_KEY_F17", INT2NUM(GLFW_KEY_F17));
	rb_define_const(module, "GLFW_KEY_F18", INT2NUM(GLFW_KEY_F18));
	rb_define_const(module, "GLFW_KEY_F19", INT2NUM(GLFW_KEY_F19));
	rb_define_const(module, "GLFW_KEY_F20", INT2NUM(GLFW_KEY_F20));
	rb_define_const(module, "GLFW_KEY_F21", INT2NUM(GLFW_KEY_F21));
	rb_define_const(module, "GLFW_KEY_F22", INT2NUM(GLFW_KEY_F22));
	rb_define_const(module, "GLFW_KEY_F23", INT2NUM(GLFW_KEY_F23));
	rb_define_const(module, "GLFW_KEY_F24", INT2NUM(GLFW_KEY_F24));
	rb_define_const(module, "GLFW_KEY_F25", INT2NUM(GLFW_KEY_F25));
	rb_define_const(module, "GLFW_KEY_UP", INT2NUM(GLFW_KEY_UP));
	rb_define_const(module, "GLFW_KEY_DOWN", INT2NUM(GLFW_KEY_DOWN));
	rb_define_const(module, "GLFW_KEY_LEFT", INT2NUM(GLFW_KEY_LEFT));
	rb_define_const(module, "GLFW_KEY_RIGHT", INT2NUM(GLFW_KEY_RIGHT));
	rb_define_const(module, "GLFW_KEY_LSHIFT", INT2NUM(GLFW_KEY_LSHIFT));
	rb_define_const(module, "GLFW_KEY_RSHIFT", INT2NUM(GLFW_KEY_RSHIFT));
	rb_define_const(module, "GLFW_KEY_LCTRL", INT2NUM(GLFW_KEY_LCTRL));
	rb_define_const(module, "GLFW_KEY_RCTRL", INT2NUM(GLFW_KEY_RCTRL));
	rb_define_const(module, "GLFW_KEY_LALT", INT2NUM(GLFW_KEY_LALT));
	rb_define_const(module, "GLFW_KEY_RALT", INT2NUM(GLFW_KEY_RALT));
	rb_define_const(module, "GLFW_KEY_TAB", INT2NUM(GLFW_KEY_TAB));
	rb_define_const(module, "GLFW_KEY_ENTER", INT2NUM(GLFW_KEY_ENTER));
	rb_define_const(module, "GLFW_KEY_BACKSPACE", INT2NUM(GLFW_KEY_BACKSPACE));
	rb_define_const(module, "GLFW_KEY_INSERT", INT2NUM(GLFW_KEY_INSERT));
	rb_define_const(module, "GLFW_KEY_DEL", INT2NUM(GLFW_KEY_DEL));
	rb_define_const(module, "GLFW_KEY_PAGEUP", INT2NUM(GLFW_KEY_PAGEUP));
	rb_define_const(module, "GLFW_KEY_PAGEDOWN", INT2NUM(GLFW_KEY_PAGEDOWN));
	rb_define_const(module, "GLFW_KEY_HOME", INT2NUM(GLFW_KEY_HOME));
	rb_define_const(module, "GLFW_KEY_END", INT2NUM(GLFW_KEY_END));
	rb_define_const(module, "GLFW_KEY_KP_0", INT2NUM(GLFW_KEY_KP_0));
	rb_define_const(module, "GLFW_KEY_KP_1", INT2NUM(GLFW_KEY_KP_1));
	rb_define_const(module, "GLFW_KEY_KP_2", INT2NUM(GLFW_KEY_KP_2));
	rb_define_const(module, "GLFW_KEY_KP_3", INT2NUM(GLFW_KEY_KP_3));
	rb_define_const(module, "GLFW_KEY_KP_4", INT2NUM(GLFW_KEY_KP_4));
	rb_define_const(module, "GLFW_KEY_KP_5", INT2NUM(GLFW_KEY_KP_5));
	rb_define_const(module, "GLFW_KEY_KP_6", INT2NUM(GLFW_KEY_KP_6));
	rb_define_const(module, "GLFW_KEY_KP_7", INT2NUM(GLFW_KEY_KP_7));
	rb_define_const(module, "GLFW_KEY_KP_8", INT2NUM(GLFW_KEY_KP_8));
	rb_define_const(module, "GLFW_KEY_KP_9", INT2NUM(GLFW_KEY_KP_9));
	rb_define_const(module, "GLFW_KEY_KP_DIVIDE", INT2NUM(GLFW_KEY_KP_DIVIDE));
	rb_define_const(module, "GLFW_KEY_KP_MULTIPLY", INT2NUM(GLFW_KEY_KP_MULTIPLY));
	rb_define_const(module, "GLFW_KEY_KP_SUBTRACT", INT2NUM(GLFW_KEY_KP_SUBTRACT));
	rb_define_const(module, "GLFW_KEY_KP_ADD", INT2NUM(GLFW_KEY_KP_ADD));
	rb_define_const(module, "GLFW_KEY_KP_DECIMAL", INT2NUM(GLFW_KEY_KP_DECIMAL));
	rb_define_const(module, "GLFW_KEY_KP_EQUAL", INT2NUM(GLFW_KEY_KP_EQUAL));
	rb_define_const(module, "GLFW_KEY_KP_ENTER", INT2NUM(GLFW_KEY_KP_ENTER));
	rb_define_const(module, "GLFW_KEY_LAST", INT2NUM(GLFW_KEY_LAST));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_1", INT2NUM(GLFW_MOUSE_BUTTON_1));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_2", INT2NUM(GLFW_MOUSE_BUTTON_2));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_3", INT2NUM(GLFW_MOUSE_BUTTON_3));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_4", INT2NUM(GLFW_MOUSE_BUTTON_4));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_5", INT2NUM(GLFW_MOUSE_BUTTON_5));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_6", INT2NUM(GLFW_MOUSE_BUTTON_6));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_7", INT2NUM(GLFW_MOUSE_BUTTON_7));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_8", INT2NUM(GLFW_MOUSE_BUTTON_8));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_LAST", INT2NUM(GLFW_MOUSE_BUTTON_LAST));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_LEFT", INT2NUM(GLFW_MOUSE_BUTTON_LEFT));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_RIGHT", INT2NUM(GLFW_MOUSE_BUTTON_RIGHT));
	rb_define_const(module, "GLFW_MOUSE_BUTTON_MIDDLE", INT2NUM(GLFW_MOUSE_BUTTON_MIDDLE));
	rb_define_const(module, "GLFW_JOYSTICK_1", INT2NUM(GLFW_JOYSTICK_1));
	rb_define_const(module, "GLFW_JOYSTICK_2", INT2NUM(GLFW_JOYSTICK_2));
	rb_define_const(module, "GLFW_JOYSTICK_3", INT2NUM(GLFW_JOYSTICK_3));
	rb_define_const(module, "GLFW_JOYSTICK_4", INT2NUM(GLFW_JOYSTICK_4));
	rb_define_const(module, "GLFW_JOYSTICK_5", INT2NUM(GLFW_JOYSTICK_5));
	rb_define_const(module, "GLFW_JOYSTICK_6", INT2NUM(GLFW_JOYSTICK_6));
	rb_define_const(module, "GLFW_JOYSTICK_7", INT2NUM(GLFW_JOYSTICK_7));
	rb_define_const(module, "GLFW_JOYSTICK_8", INT2NUM(GLFW_JOYSTICK_8));
	rb_define_const(module, "GLFW_JOYSTICK_9", INT2NUM(GLFW_JOYSTICK_9));
	rb_define_const(module, "GLFW_JOYSTICK_10", INT2NUM(GLFW_JOYSTICK_10));
	rb_define_const(module, "GLFW_JOYSTICK_11", INT2NUM(GLFW_JOYSTICK_11));
	rb_define_const(module, "GLFW_JOYSTICK_12", INT2NUM(GLFW_JOYSTICK_12));
	rb_define_const(module, "GLFW_JOYSTICK_13", INT2NUM(GLFW_JOYSTICK_13));
	rb_define_const(module, "GLFW_JOYSTICK_14", INT2NUM(GLFW_JOYSTICK_14));
	rb_define_const(module, "GLFW_JOYSTICK_15", INT2NUM(GLFW_JOYSTICK_15));
	rb_define_const(module, "GLFW_JOYSTICK_16", INT2NUM(GLFW_JOYSTICK_16));
	rb_define_const(module, "GLFW_JOYSTICK_LAST", INT2NUM(GLFW_JOYSTICK_LAST));
	rb_define_const(module, "GLFW_WINDOW", INT2NUM(GLFW_WINDOW));
	rb_define_const(module, "GLFW_FULLSCREEN", INT2NUM(GLFW_FULLSCREEN));
	rb_define_const(module, "GLFW_OPENED", INT2NUM(GLFW_OPENED));
	rb_define_const(module, "GLFW_ACTIVE", INT2NUM(GLFW_ACTIVE));
	rb_define_const(module, "GLFW_ICONIFIED", INT2NUM(GLFW_ICONIFIED));
	rb_define_const(module, "GLFW_ACCELERATED", INT2NUM(GLFW_ACCELERATED));
	rb_define_const(module, "GLFW_RED_BITS", INT2NUM(GLFW_RED_BITS));
	rb_define_const(module, "GLFW_GREEN_BITS", INT2NUM(GLFW_GREEN_BITS));
	rb_define_const(module, "GLFW_BLUE_BITS", INT2NUM(GLFW_BLUE_BITS));
	rb_define_const(module, "GLFW_ALPHA_BITS", INT2NUM(GLFW_ALPHA_BITS));
	rb_define_const(module, "GLFW_DEPTH_BITS", INT2NUM(GLFW_DEPTH_BITS));
	rb_define_const(module, "GLFW_STENCIL_BITS", INT2NUM(GLFW_STENCIL_BITS));
	rb_define_const(module, "GLFW_REFRESH_RATE", INT2NUM(GLFW_REFRESH_RATE));
	rb_define_const(module, "GLFW_ACCUM_RED_BITS", INT2NUM(GLFW_ACCUM_RED_BITS));
	rb_define_const(module, "GLFW_ACCUM_GREEN_BITS", INT2NUM(GLFW_ACCUM_GREEN_BITS));
	rb_define_const(module, "GLFW_ACCUM_BLUE_BITS", INT2NUM(GLFW_ACCUM_BLUE_BITS));
	rb_define_const(module, "GLFW_ACCUM_ALPHA_BITS", INT2NUM(GLFW_ACCUM_ALPHA_BITS));
	rb_define_const(module, "GLFW_AUX_BUFFERS", INT2NUM(GLFW_AUX_BUFFERS));
	rb_define_const(module, "GLFW_STEREO", INT2NUM(GLFW_STEREO));
	rb_define_const(module, "GLFW_WINDOW_NO_RESIZE", INT2NUM(GLFW_WINDOW_NO_RESIZE));
	rb_define_const(module, "GLFW_FSAA_SAMPLES", INT2NUM(GLFW_FSAA_SAMPLES));
	rb_define_const(module, "GLFW_MOUSE_CURSOR", INT2NUM(GLFW_MOUSE_CURSOR));
	rb_define_const(module, "GLFW_STICKY_KEYS", INT2NUM(GLFW_STICKY_KEYS));
	rb_define_const(module, "GLFW_STICKY_MOUSE_BUTTONS", INT2NUM(GLFW_STICKY_MOUSE_BUTTONS));
	rb_define_const(module, "GLFW_SYSTEM_KEYS", INT2NUM(GLFW_SYSTEM_KEYS));
	rb_define_const(module, "GLFW_KEY_REPEAT", INT2NUM(GLFW_KEY_REPEAT));
	rb_define_const(module, "GLFW_AUTO_POLL_EVENTS", INT2NUM(GLFW_AUTO_POLL_EVENTS));
	rb_define_const(module, "GLFW_WAIT", INT2NUM(GLFW_WAIT));
	rb_define_const(module, "GLFW_NOWAIT", INT2NUM(GLFW_NOWAIT));
	rb_define_const(module, "GLFW_PRESENT", INT2NUM(GLFW_PRESENT));
	rb_define_const(module, "GLFW_AXES", INT2NUM(GLFW_AXES));
	rb_define_const(module, "GLFW_BUTTONS", INT2NUM(GLFW_BUTTONS));
	rb_define_const(module, "GLFW_NO_RESCALE_BIT", INT2NUM(GLFW_NO_RESCALE_BIT));
	rb_define_const(module, "GLFW_ORIGIN_UL_BIT", INT2NUM(GLFW_ORIGIN_UL_BIT));
	rb_define_const(module, "GLFW_BUILD_MIPMAPS_BIT", INT2NUM(GLFW_BUILD_MIPMAPS_BIT));
	rb_define_const(module, "GLFW_ALPHA_MAP_BIT", INT2NUM(GLFW_ALPHA_MAP_BIT));
	rb_define_const(module, "GLFW_INFINITY", INT2NUM(GLFW_INFINITY));

	/* calls Glfw.glfwTerminate() at ruby exit */
	rb_eval_string("at_exit do Glfw.glfwTerminate end");
}
