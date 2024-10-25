package core 

import "core:fmt"
import "core:c"
// import "core:c/libc"
import "vendor:glfw"
import gl "vendor:OpenGL"



// intis glfw & glad, also creates the window
// returns: <stddef.h> return_code
window_create :: proc( width, height: int, title: cstring, type: WINDOW_TYPE, vsync: bool ) -> bool
{
	// enable error logging for glfw
  glfw.SetErrorCallback( cast(glfw.ErrorProc)error_callback )
  

  // Initialise GLFW
	if (glfw.Init() == glfw.FALSE)
	{
		fmt.printf( "Failed to initialize GLFW !!!\n" )
		return false
	}
	glfw.WindowHint( glfw.CONTEXT_VERSION_MAJOR, 4 )
	glfw.WindowHint( glfw.CONTEXT_VERSION_MINOR, 6 )
	glfw.WindowHint( glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE )
	// glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, true); // @TODO: implement this, page 439 in learnopengl

// #ifdef __APPLE__
// 	glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
// #endif

  monitor   := glfw.GetPrimaryMonitor()
  mode      := glfw.GetVideoMode( monitor )
  data.monitor_width  = int(mode.width)
  data.monitor_height = int(mode.height)
 
  glfw.WindowHint_int( glfw.RED_BITS,     mode.red_bits )
  glfw.WindowHint_int( glfw.GREEN_BITS,   mode.green_bits )
  glfw.WindowHint_int( glfw.BLUE_BITS,    mode.blue_bits )
  glfw.WindowHint_int( glfw.REFRESH_RATE, mode.refresh_rate )

  // open a window and create its opengl context
	if type == WINDOW_TYPE.FULLSCREEN
  {
    data.window = glfw.CreateWindow( mode.width, mode.height, title, monitor, nil )
    data.window_width  = int(mode.width)
    data.window_height = int(mode.height)
  }
  else
  {
    data.window = glfw.CreateWindow( cast(c.int)width, cast(c.int)height, title, nil, nil )
    data.window_width  = width
    data.window_height = height
  }

	if data.window == nil
	{
		fmt.printf( "Failed to open GLFW window.\n" )
		glfw.Terminate()
		return false
	}

	// make the window's context current
	glfw.MakeContextCurrent( data.window )

  glfw.SwapInterval( vsync ? 1 : 0 )  // disable vsync
  data.vsync_enabled = vsync

  // gl.load_up_to( 3, 3, glfw.gl_set_proc_address )
  gl.load_up_to( 4, 6, glfw.gl_set_proc_address )

	// tell opengl the size of our window
  w, h := glfw.GetFramebufferSize( data.window )
	gl.Viewport( 0, 0, w, h )

	// maximize window
	if ( type == WINDOW_TYPE.MAXIMIZED )
	{
		glfw.MaximizeWindow( data.window )
	}

	// set the resize callback
	glfw.SetFramebufferSizeCallback( data.window, cast(glfw.FramebufferSizeProc)resize_callback )
  // @NOTE: causes inability to restore maximized after fullscreen, also framebuffers crash when minimizing to system tray
  // glfwSetWindowMaximizeCallback(core_data->window,  (GLFWwindowmaximizefun)maximize_callback); 

	glfw.SetWindowAttrib( data.window, glfw.FOCUS_ON_SHOW, 1 )  // 1: true
	// glfwSetWindowAttrib(window, GLFW_AUTO_ICONIFY, true);
	glfw.RequestWindowAttention( data.window )


  // During init, enable debug output
  gl.Enable( gl.DEBUG_OUTPUT )
  gl.DebugMessageCallback( gl.debug_proc_t(opengl_debug_callback), nil )
  gl.Enable( gl.DEBUG_OUTPUT_SYNCHRONOUS )
  
  camera_set_pers_mat( f32(data.window_width), f32(data.window_height) )

	return true
}

// glfw error callback func
@(private)
error_callback :: proc( error: c.int, description: cstring )
{
	fmt.printf( "GLFW-Error: %s\n", description );
}

// window resize callback
// resizes the "glViewport" according to the resized window
// window is type GLFWwindow*
@(private)
resize_callback :: proc( window: glfw.WindowHandle, width, height: c.int )
{
	gl.Viewport( 0, 0, width, height );
  camera_set_pers_mat( f32(width), f32(height) )
  data.window_width  = int(width)
  data.window_height = int(height)

  framebuffer_delete( &data.fb_deferred )
  framebuffer_delete( &data.fb_lighting )

  data.fb_deferred = framebuffer_create_gbuffer( 1 ) 
  data.fb_lighting = framebuffer_create_hdr()
}

gl_debug_enum :: enum
{
  OUTPUT_SYNCHRONOUS           = gl.DEBUG_OUTPUT_SYNCHRONOUS,
  NEXT_LOGGED_MESSAGE_LENGTH   = gl.DEBUG_NEXT_LOGGED_MESSAGE_LENGTH,
  CALLBACK_FUNCTION            = gl.DEBUG_CALLBACK_FUNCTION,
  CALLBACK_USER_PARAM          = gl.DEBUG_CALLBACK_USER_PARAM,
  SOURCE_API                   = gl.DEBUG_SOURCE_API,
  SOURCE_WINDOW_SYSTEM         = gl.DEBUG_SOURCE_WINDOW_SYSTEM,
  SOURCE_SHADER_COMPILER       = gl.DEBUG_SOURCE_SHADER_COMPILER,
  SOURCE_THIRD_PARTY           = gl.DEBUG_SOURCE_THIRD_PARTY,
  SOURCE_APPLICATION           = gl.DEBUG_SOURCE_APPLICATION,
  SOURCE_OTHER                 = gl.DEBUG_SOURCE_OTHER,
  TYPE_ERROR                   = gl.DEBUG_TYPE_ERROR,
  TYPE_DEPRECATED_BEHAVIOR     = gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR,
  TYPE_UNDEFINED_BEHAVIOR      = gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR,
  TYPE_PORTABILITY             = gl.DEBUG_TYPE_PORTABILITY,
  TYPE_PERFORMANCE             = gl.DEBUG_TYPE_PERFORMANCE,
  TYPE_OTHER                   = gl.DEBUG_TYPE_OTHER,
                                
  LOGGED_MESSAGES              = gl.DEBUG_LOGGED_MESSAGES,
  SEVERITY_HIGH                = gl.DEBUG_SEVERITY_HIGH,
  SEVERITY_MEDIUM              = gl.DEBUG_SEVERITY_MEDIUM,
  SEVERITY_LOW                 = gl.DEBUG_SEVERITY_LOW,
  TYPE_MARKER                  = gl.DEBUG_TYPE_MARKER,
  TYPE_PUSH_GROUP              = gl.DEBUG_TYPE_PUSH_GROUP,
  TYPE_POP_GROUP               = gl.DEBUG_TYPE_POP_GROUP,
  SEVERITY_NOTIFICATION        = gl.DEBUG_SEVERITY_NOTIFICATION,
  
   MAX_DEBUG_GROUP_STACK_DEPTH = gl.MAX_DEBUG_GROUP_STACK_DEPTH,
   GROUP_STACK_DEPTH           = gl.DEBUG_GROUP_STACK_DEPTH,


}
// // @TODO: no idea what #sparse does,
// //        cant find docs on odin-lang.org 
// gl_debug_enum_str : #sparse [gl_debug_enum]string

@(private)
opengl_debug_callback :: proc( source, type, id, severity: u32,
                               length: i32,
                               message: cstring,
                               userParam: rawptr/* , loc := #caller_location */ )
{
  // fmt.println( "type: ", gl_debug_enum(type) )
  // fmt.println( "message: ", message )
  // fmt.eprintf( "GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
  //          ( type == gl.DEBUG_TYPE_ERROR ? "** GL ERROR **" : "" ), type, severity, message );

  // @TODO: fix all these messages in the future
  if gl_debug_enum(severity) == .SEVERITY_NOTIFICATION ||
     gl_debug_enum(severity) == .SEVERITY_LOW          ||
     gl_debug_enum(severity) == .SEVERITY_MEDIUM       
  {
    return
  }

  fmt.eprintf( "[GL ERROR]: type: %s, severity: %s\n -> message: %s\n",
               gl_debug_enum(type), gl_debug_enum(severity), message );
  // fmt.println( oc ) // is nil
  // fmt.println( " -> ", loc.file_path, ", proc: ", loc.procedure, ", line: ", loc.line )
}

window_should_close :: proc() -> bool
{
  return glfw.WindowShouldClose( data.window ) == glfw.TRUE;
}

window_set_title :: proc( title: cstring )
{
	glfw.SetWindowTitle(data.window, title)
	// window_title = (char*)title;
  // strcpy(window_title, title);
}

window_set_vsync :: proc( vsync: bool )
{
  glfw.SwapInterval( vsync ? 1 : 0 )  // disable vsync
  data.vsync_enabled = vsync
}
window_get_size :: #force_inline proc() -> ( width, height: int )
{
	w, h := glfw.GetWindowSize( data.window )
  return int(w), int(h)
}

// void maximize_callback(void* window, int maximized)
// {
//   TRACE();
//
//   (void)window;
//   win_type = maximized ? WINDOW_MAX : WINDOW_MIN; // : win_type;
// }
