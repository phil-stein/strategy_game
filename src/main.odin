package core

import        "base:runtime"
import        "core:fmt"
import str    "core:strings"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "core:os"
import        "vendor:glfw"
import gl     "vendor:OpenGL"
import        "core:image"
import        "core:image/png"
import        "core:log"
import        "core:mem"
import        "core:time"
import        "core:debug/trace"
import        "core:encoding/ansi"

EDITOR :: #config(EDITOR, false)


// setup debug/trace
global_trace_ctx: trace.Context
debug_trace_assertion_failure_proc :: proc(prefix, message: string, loc := #caller_location) -> ! 
{
	runtime.print_caller_location( loc )
	runtime.print_string( " " )
	runtime.print_string( prefix )
	if len(message) > 0 
  {
		runtime.print_string( ": " )
		runtime.print_string( message )
	}
	runtime.print_byte( '\n' )

	// ctx := &trace_ctx
	ctx := &global_trace_ctx
	if !trace.in_resolve( ctx ) 
  {
		buf: [64]trace.Frame
		runtime.print_string( "Debug Trace:\n" )
		frames := trace.frames( ctx, 1, buf[:] )
		for f, i in frames 
    {
			fl := trace.resolve( ctx, f, context.temp_allocator )
			if fl.loc.file_path == "" && fl.loc.line == 0 
      {
				continue
			}
			runtime.print_caller_location( fl.loc )
			runtime.print_string( " - frame " )
			runtime.print_int( i )
			runtime.print_byte( '\n' )
		}
	}
	runtime.trap()
}

@(private="file")
Default_Console_Logger_Opts :: log.Options {
	.Level,
	.Terminal_Color,
	.Short_File_Path,
	.Line,
	.Procedure,
} 
@(private="file")
create_console_logger :: proc(lowest := log.Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> log.Logger 
{
	data := new(log.File_Console_Logger_Data)
	data.file_handle = os.INVALID_HANDLE
	data.ident = ident
	return log.Logger{file_console_logger_proc, data, lowest, opt}
}

@(private="file")
destroy_console_logger :: proc(log: log.Logger) 
{
	free(log.data)
}

level_headers := [?]string{
	 0..<10 = "[DEBUG] ",
	10..<20 = "[INFO ] ",
	20..<30 = "[WARN ] ",
	30..<40 = "[ERROR] ",
	40..<50 = "[FATAL] ",
}
@(private="file")
file_console_logger_proc :: proc(logger_data: rawptr, level: log.Level, text: string, options: log.Options, location := #caller_location) {
	data := cast(^log.File_Console_Logger_Data)logger_data
	h: os.Handle = os.stdout if level <= log.Level.Error else os.stderr
	if data.file_handle != os.INVALID_HANDLE 
  {
		h = data.file_handle
	}
	backing: [1024]byte //NOTE(Hoej): 1024 might be too much for a header backing, unless somebody has really long paths.
	buf := str.builder_from_bytes(backing[:])


	do_level_header( options, &buf, level )
	do_location_header( options, &buf, location )
  do_progress_header( options, &buf )
	
  fmt.sbprint(&buf, "| ")

	// when time.IS_SUPPORTED {
	// 	do_time_header(options, &buf, time.now())
	// }


	if .Thread_Id in options {
		// NOTE(Oskar): not using context.thread_id here since that could be
		// incorrect when replacing context for a thread.
		fmt.sbprintf(&buf, "[{}] ", os.current_thread_id())
	}

	if data.ident != "" {
		fmt.sbprintf(&buf, "[%s] ", data.ident)
	}
	//TODO(Hoej): When we have better atomics and such, make this thread-safe
	fmt.fprintf(h, "%s%s\n", str.to_string(buf), text)

}

@(private="file")
do_level_header :: proc(opts: log.Options, str: ^str.Builder, level: log.Level) 
{
	RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
	RED       :: ansi.CSI + ansi.FG_RED          + ansi.SGR
	YELLOW    :: ansi.CSI + ansi.FG_YELLOW       + ansi.SGR
	DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR
	CYAN      :: ansi.CSI + ansi.FG_CYAN         + ansi.SGR

	col := RESET
	switch level 
  {
	  case log.Level.Debug:         col = DARK_GREY
	  case log.Level.Info:          col = CYAN // RESET
	  case log.Level.Warning:       col = YELLOW
	  case log.Level.Error, .Fatal: col = RED
	}

	if log.Options.Level in opts 
  {
		if log.Options.Terminal_Color in opts 
    {
			fmt.sbprint(str, col)
		}
		fmt.sbprint(str, level_headers[level])
		if log.Options.Terminal_Color in opts 
    {
			fmt.sbprint(str, RESET)
		}
	}
}

@(private="file")
do_time_header :: proc(opts: log.Options, buf: ^str.Builder, t: time.Time) {
	when time.IS_SUPPORTED {
		if log.Full_Timestamp_Opts & opts != nil {
			fmt.sbprint(buf, "[")
			y, m, d := time.date(t)
			h, min, s := time.clock(t)
			if .Date in opts {
				fmt.sbprintf(buf, "%d-%02d-%02d", y, m, d)
				if .Time in opts {
					fmt.sbprint(buf, " ")
				}
			}
			if .Time in opts { fmt.sbprintf(buf, "%02d:%02d:%02d", h, min, s) }
			fmt.sbprint(buf, "] ")
		}
	}
}
@(private="file")
log_progress    := [?]rune{ '|', '/', '-', '\\' } 
@(private="file")
log_process_idx : int
@(private="file")
do_progress_header :: proc(opts: log.Options, buf: ^str.Builder ) 
{
	RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
	DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR

	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, DARK_GREY)
	}

	fmt.sbprintf(buf, "[%v]", log_progress[log_process_idx] )

  log_process_idx = log_process_idx +1 if log_process_idx+1 < len(log_progress) else 0

	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, RESET)
	}
}

@(private="file")
do_location_header :: proc(opts: log.Options, buf: ^str.Builder, location := #caller_location) 
{
	RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
	DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR

	if log.Location_Header_Opts & opts == nil 
  {
		return
	}

	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, DARK_GREY)
	}

	fmt.sbprint(buf, "[")

	file := location.file_path
	if .Short_File_Path in opts 
  {
		last := 0
		for r, i in location.file_path 
    {
			if r == '/' {
				last = i+1
			}
		}
		file = location.file_path[last:]
	}

	if log.Location_File_Opts & opts != nil 
  {
		fmt.sbprint(buf, file)
	}
	if .Line in opts 
  {
		if log.Location_File_Opts & opts != nil 
    {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprint(buf, location.line)
	}

	if .Procedure in opts 
  {
		if (log.Location_File_Opts | {.Line}) & opts != nil 
    {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprintf(buf, "%s()", location.procedure)
	}

	fmt.sbprint(buf, "] ")

	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, RESET)
	}
}

main :: proc() 
{
  // ---- init odin stuff ----

  when ODIN_DEBUG 
  {
    // setup tracking allocator
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer 
    {
			if len(track.allocation_map) > 0 
      {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map 
        {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 
      {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array 
        {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}

    // init stack trace
	  trace.init(&global_trace_ctx)
	  defer trace.destroy(&global_trace_ctx)
	  context.assertion_failure_proc = debug_trace_assertion_failure_proc
	}
  // setup log
  // context.logger = log.create_console_logger()
  context.logger = create_console_logger()
  when ODIN_DEBUG // no need to as windows does it automatically
  { defer destroy_console_logger( context.logger ) }
  // { defer free( context.logger.data ) }

  // @TMP:
  var := 123
  log.log( log.Level.Debug, "log" )
  log.debug( "debug", "debug", var )
  log.info( "info" )
  log.warn( "warn" )
  log.error( "error" )
  log.fatal( "fatal" )
  // if 0 == 0 { log.panic( "panic" ) }
  
  
  // ---- init ----

  debug_timer_static_start( "init()" )

  when EDITOR
  { 
    if ( !window_create( 1500, 1075, "title", Window_Type.MINIMIZED, vsync=true ) ) 
    { fmt.print( "ERROR: failed to create window\n" ); return }
  } 
  else 
  { 
    if ( !window_create( 1, 1, "title", Window_Type.FULLSCREEN, vsync=true ) ) 
    { fmt.print( "ERROR: failed to create window\n" ); return }
  }
  debug_timer_static_start( "input_init()" )
  input_init()
  debug_timer_stop() // input_init()
  // // hide cursor
  // input_center_cursor()
  // input_set_cursor_visibile( false )

  // ---- setup ----

  debug_timer_static_start( "data_init" )
  data_init()
  debug_timer_stop() // data_init()

  debug_timer_static_start( "assetm_init()" )
  assetm_init()
  debug_timer_stop()  // assetm_init()

  debug_timer_static_start( "load hdri" )
  data.brdf_lut = make_brdf_lut()
  cubemap_data := #load( "../assets/textures/gothic_manor_01_2k.hdr" )
  data.cubemap = cubemap_load( &cubemap_data[0], len(cubemap_data) )
  data.cubemap.intensity = 4.0 // 1.9 // 1.0 // 1.9
  debug_timer_stop() // load hdri

  
  // -- add entities --
  // entity_arr[0] is invalid entity
  // @TODO: less hacky solution
  append( &data.entity_arr, entity_t{} ) 

  data.player_chars[0].tile = waypoint_t{ level_idx=0, x=5, z=5 }
  player_char_00_pos := util_tile_to_pos( data.player_chars[0].tile )
  data.player_chars[0].entity_idx = len(data.entity_arr)
  data_entity_add( entity_t{ pos = player_char_00_pos + linalg.vec3{ 0, 1, 0 }, 
                             rot = { 0, 180, 0 }, scl = { 1, 1, 1 },
                             mesh_idx = data.mesh_idxs.robot_char, // data.mesh_idxs.suzanne, 
                             mat_idx  = data.material_idxs.robot
                           } )
  // fmt.println( "player[0].pos: ", data.entity_arr[data.player_chars[0].entity_idx].pos )
  // fmt.println( "player.tile: ", data.player_chars[0].tile )
  // fmt.println( "player.tile -> pos: ", player_char_00_pos )
  // fmt.println( "data.player_chars[0].entity_idx: ", data.player_chars[0].entity_idx )

  data.player_chars[1].tile = waypoint_t{ level_idx=0, x=4, z=3 }
  data.player_chars[1].tile = waypoint_t{ level_idx=2, x=6, z=9 }
  data.player_chars[1].tile = waypoint_t{ level_idx=1, x=5, z=9 }
  player_char_01_pos := util_tile_to_pos( data.player_chars[1].tile )
  data.player_chars[1].entity_idx = len(data.entity_arr)
  data_entity_add( entity_t{ pos = player_char_01_pos + linalg.vec3{ 0, 1, 0 }, 
                             rot = { 0, 180, 0 }, scl = { 1, 1, 1 },
                             mesh_idx = data.mesh_idxs.female_char, // data.mesh_idxs.suzanne, 
                             mat_idx  = data.material_idxs.female
                           } )

  data.player_chars[2].tile = waypoint_t{ level_idx=2, x=0, z=5 }
  player_char_02_pos := util_tile_to_pos( data.player_chars[2].tile )
  data.player_chars[2].entity_idx = len(data.entity_arr)
  data_entity_add( entity_t{ pos = player_char_02_pos + linalg.vec3{ 0, 2, 0 }, 
                             rot = { 0, 180, 0 }, scl = { 1, 1, 1 },
                             mesh_idx = data.mesh_idxs.suzanne, 
                             mat_idx  = data.material_idxs.default
                           } )

  // sphere_pos := util_tile_to_pos( waypoint_t{ level_idx=1, x=0, z=6 } )
  // data_entity_add( entity_t{ pos = sphere_pos + linalg.vec3{ 0, 2, 0 }, 
  //                            rot = { 0, 180, 0 }, scl = { 1, 1, 1 },
  //                            mesh_idx = data.mesh_idxs.suzanne, 
  //                            mat_idx  = data.material_idxs.water
  //                          } )
 
  data_entity_add( entity_t{ pos = linalg.vec3{ 0, -1, 0 }, 
                             rot = linalg.vec3{ 0, 0, 0 }, 
                             scl = linalg.vec3{ 50, 50, 50 },
                             mesh_idx = data.mesh_idxs.quad, 
                             mat_idx  = data.material_idxs.water
                           } )



  // --- create map ---

  debug_timer_static_start( "data_create_map()" ) 
  data_create_map()
  debug_timer_stop() // data_create_map()


  
  // -- set opengl state --
  debug_timer_static_start( "renderer_init()" ) 
  renderer_init()
  debug_timer_stop()  // renderer_init()

  debug_timer_static_start( "ui_init()" ) 
  ui_init()
  debug_timer_stop()  // ui_init()
	
  debug_timer_stop() // init

  // ---- main loop ----
  for !window_should_close()
  {
    debug_timer_start( "update()" )

    glfw.PollEvents();
      
    debug_timer_start( "data_pre_updated()" )
    data_pre_updated()
    debug_timer_stop() // data_pre_updated()

    if ( input.key_states[Key.ESCAPE].pressed )
    { break }

    if ( input.key_states[Key.TAB].pressed )
    { data.wireframe_mode_enabled  = !data.wireframe_mode_enabled }

    if ( input.key_states[Key.F11].pressed )
    { 
      window_set_type( Window_Type.MAXIMIZED if data.window_type != Window_Type.MAXIMIZED else Window_Type.MINIMIZED )
    }

    if ( input.key_states[Key.ENTER].pressed )
    {
      fmt.println( "camera ------------------------------")
      fmt.println( "data.cam.pos:   ", data.cam.pos )
      fmt.println( "data.cam.pitch: ", data.cam.pitch_rad )
      fmt.println( "data.cam.yaw:   ", data.cam.yaw_rad )
    }
    
    debug_timer_start( "renderer_update()" )
    renderer_update()
    renderer_draw_scene_mouse_pick()
    debug_timer_stop() // renderer_update()
    // debug_draw_tiles()

    game_update()

    // move the water
    @static offs : f32 = 0.0
    offs  += data.delta_t
    speed_x := math.max( 0.2, 1 + math.sin( data.total_t * 0.5 ) )
    speed_x += offs  * 0.5
    speed_x *= 0.5
    speed_y := 0.1 * speed_x * ( 1 + math.cos( data.total_t * 0.3 ) )
    data.material_arr[data.material_idxs.water].uv_offs = linalg.vec2{ speed_x, speed_y }

    // // draw the gbuffer and lighting buffer onto screen as quads
    // quad_size :: linalg.vec2{ 0.25, -0.25 }
    // renderer_draw_quad( linalg.vec2{ -0.75,  0.75 }, quad_size, data.fb_deferred.buffer01 )
    // renderer_draw_quad( linalg.vec2{ -0.75,  0.25 }, quad_size, data.fb_deferred.buffer02 )
    // renderer_draw_quad( linalg.vec2{ -0.75, -0.25 }, quad_size, data.fb_deferred.buffer03 )
    // renderer_draw_quad( linalg.vec2{ -0.75, -0.75 }, quad_size, data.fb_deferred.buffer04 )
    // renderer_draw_quad( linalg.vec2{ -0.25,  0.75 }, quad_size, data.fb_lighting.buffer01 )

    when EDITOR
    {
      // --- editor ui ---
      debug_timer_start( "ui_update()" )
      if input.key_states[Key.BACKSPACE].pressed && input.key_states[Key.LEFT_CONTROL].down
      { data.editor_ui.active = !data.editor_ui.active }
      if data.editor_ui.active { ui_update() }
      debug_timer_stop() // ui_update()
    }

    glfw.SwapBuffers( data.window )
    
    input_update()

    debug_timer_stop()  // update()
    debug_timer_update()

    // fmt.println( size_of(context.temp_allocator) )
    free_all( context.temp_allocator )
  }

  // @NOTE: no real need to do this windows does it automatically,
  //        but the tracking allocator complains otherwise
  when ODIN_DEBUG
  {
    debug_timer_cleanup()
    ui_cleanup()
    assetm_cleanup()

    glfw.DestroyWindow( data.window )
    glfw.Terminate()

    data_cleanup()
    free_all( context.temp_allocator )
  }
}



gl_format_str :: proc( format: i32 ) -> string
{
  return format == gl.R8         ? "R8"         :
         format == gl.SRGB8      ? "SRGB8"      :
         format == gl.RED        ? "RED"        :
         format == gl.RGB        ? "RGB"        :
         format == gl.SRGB       ? "SRGB"       :
         format == gl.RGBA       ? "RGBA"       :
         format == gl.SRGB_ALPHA ? "SRGB_ALPHA" :
         "unknown" 
}
make_texture :: proc( path: string, srgb: bool, tint:= [3]f32{ 1, 1, 1 } ) -> ( handle: u32 )
{
  // Load image at compile time
  // image_file_bytes := #load( "../assets/texture_01.png" )
  image_file_bytes, ok := os.read_entire_file( path, context.allocator )
  if( !ok ) 
  {
    // Print error to stderr and exit with errorcode
    fmt.eprintln("could not read texture file: ", path)
    os.exit(1)
  }
  defer delete( image_file_bytes, context.allocator )

  // Load image  Odin's core:image library.
  image_ptr :  ^image.Image
  err       :   image.Error
  // options   :=  image.Options { .alpha_add_if_missing }
  options   :=  image.Options { }

  image_ptr, err =  png.load_from_bytes( image_file_bytes, options )
  defer png.destroy( image_ptr )
  image_w := i32( image_ptr.width )
  image_h := i32( image_ptr.height )

  if err != nil
  {
      fmt.println("ERROR: Image failed to load.")
  }

  // Copy bytes from icon buffer into slice.
  pixels := make( []u8, len(image_ptr.pixels.buf) )
  tint_idx := 0
  for b, i in image_ptr.pixels.buf 
  {
      pixels[i] = byte( f32(b) * tint[tint_idx] )
      tint_idx += 1
      if tint_idx >= 3 { tint_idx = 0 }
  }
  gl.GenTextures( 1, &handle )
  gl.BindTexture( gl.TEXTURE_2D, handle )

  // Texture wrapping options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  
  // Texture filtering options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)


  gl_internal_format : i32 = srgb ? gl.SRGB_ALPHA : gl.RGBA
  gl_format          : u32 = gl.RGBA
  switch image_ptr.channels
  {
    case 1:
      gl_internal_format = srgb ? gl.SRGB8 : gl.R8
      gl_format = gl.RED
      break;
    // case 2:
    //   gl_internal_format = gl.RG8
    //   gl_format = gl.RG
    //   // P_INFO("gl.RGB");
    //   break;
    case 3:
      gl_internal_format = srgb ? gl.SRGB : gl.RGB
      gl_format = gl.RGB
      break;
    case 4:
      gl_internal_format = srgb ? gl.SRGB_ALPHA : gl.RGBA
      gl_format = gl.RGBA
      break;
    case:
      fmt.eprintln( "texture has incorrect channel amount: ", image_ptr.channels )
      os.exit( 1 )
  }
  assert( image_ptr.channels >= 1 && image_ptr.channels <= 4, "texture has incorrect channel amount" )

  // Describe texture.
  gl.TexImage2D(
      gl.TEXTURE_2D,      // texture type
      0,                  // level of detail number (default = 0)
      gl_internal_format, // gl.RGBA, // texture format
      image_w,            // width
      image_h,            // height
      0,                  // border, must be 0
      gl_format,          // gl.RGBA, // pixel data format
      gl.UNSIGNED_BYTE,   // data type of pixel data
      &pixels[0],         // image data
  )

  // must be called after glTexImage2D
  gl.GenerateMipmap(gl.TEXTURE_2D);

  delete( pixels )

  return handle
}

texture_free_handle :: proc( _handle: u32 )
{
  handle := _handle
  if handle == 0 { return }
	gl.DeleteTextures( 1, &handle )
  handle = 0;
}

make_brdf_lut :: proc () -> ( handle: u32 )
{
  width  :: 512
  height :: 512

  // gen framebuffer ---------------------------------------------------------------------

  capture_fbo, capture_rbo : u32
  gl.GenFramebuffers( 1, &capture_fbo )
  gl.GenRenderbuffers( 1, &capture_rbo )

  gl.BindFramebuffer( gl.FRAMEBUFFER, capture_fbo )
  gl.BindRenderbuffer( gl.RENDERBUFFER, capture_rbo )
  gl.RenderbufferStorage( gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, width, height )
  gl.FramebufferRenderbuffer( gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, capture_fbo )

  // gen brdf lut ------------------------------------------------------------------------
  
  brdf_lut : u32 
  gl.GenTextures( 1, &brdf_lut )

  gl.BindTexture( gl.TEXTURE_2D, brdf_lut )
  gl.TexImage2D( gl.TEXTURE_2D, 0, gl.RG16F, width, height, 0, gl.RG, gl.FLOAT, nil )
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

  gl.BindFramebuffer( gl.FRAMEBUFFER, capture_fbo )
  gl.BindRenderbuffer( gl.RENDERBUFFER, capture_rbo )
  gl.RenderbufferStorage( gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, width, height )
  gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, brdf_lut, 0 )

  gl.Viewport( 0, 0, width, height )
  gl.UseProgram( data.brdf_lut_shader )
  gl.Clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
  
	gl.BindVertexArray( data.quad_vao )
	gl.DrawArrays( gl.TRIANGLES, 0, 6 )
  gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )

  gl.DeleteFramebuffers( 1, &capture_fbo )
  gl.DeleteRenderbuffers( 1, &capture_rbo )

  // @TODO: need to save this as float instead of 8bit

  // const int channel_nr = 2;
  // u32 pixels_len = 0;
  // texture_t t;
  // t.handle     = brdf_lut;
  // t.width      = width;
  // t.height     = height;
  // t.channel_nr = channel_nr;
  // #ifdef EDITOR
  // int t_path_len = (int)strlen(path);
  // char* tex_name = (char*)&path[t_path_len - 1];
  // for (int i = t_path_len - 1; i >= 0; --i)
  // {
  //   if (path[i] == '\\' || path[i] == '/') { break; }
  //   tex_name = (char*)&path[i];
  // }
  // ASSERT(strlen(tex_name) < TEXTURE_T_NAME_MAX);
  // STRCPY(t.name, tex_name);
  // #endif // EDITOR
  // asset_io_texture_write_pixels_to_file(&t,  GL_RG, path);

  // pixels_len++; // so gcc doesnt complain about unused variable

    
  return brdf_lut
}

