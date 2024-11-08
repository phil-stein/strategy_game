package core

import        "core:fmt"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "core:os"
import        "vendor:glfw"
import gl     "vendor:OpenGL"
import        "core:image"
import        "core:image/png"



main :: proc() 
{
  // ---- init ----

  if ( !window_create( 1500, 1075, "title", Window_Type.MINIMIZED, vsync=true ) ) // /* 1000, 750, */
  {
    fmt.print( "ERROR: failed to create window\n" )
    return;
  }
  input_init()
  // // hide cursor
  // input_center_cursor()
  // input_set_cursor_visibile( false )

  // ---- setup ----

  data_init()

  assetm_init()

  data.brdf_lut = make_brdf_lut()
  cubemap_data := #load( "../assets/textures/gothic_manor_01_2k.hdr" )
  data.cubemap = cubemap_load( &cubemap_data[0], len(cubemap_data) )
  data.cubemap.intensity = 1.9


  
  // -- add entities --

  data.player_chars[0].tile = waypoint_t{ level_idx=0, x=5, z=5 }
  player_char_00_pos := util_tile_to_pos( data.player_chars[0].tile )
  data.player_chars[0].entity_idx = len(data.entity_arr)
  append( &data.entity_arr, entity_t{ pos = player_char_00_pos + linalg.vec3{ -2, 2, -2 }, 
                                      rot = { 0, 180, 0 }, scl = { 1, 1, 1 },
                                      mesh_idx = data.mesh_idxs.suzanne, 
                                      mat_idx  = data.material_idxs.metal_01
                                    } )
  fmt.println( "player[0].pos: ", data.entity_arr[data.player_chars[0].entity_idx].pos )
  fmt.println( "player.tile: ", data.player_chars[0].tile )
  fmt.println( "player.tile -> pos: ", player_char_00_pos )
  fmt.println( "data.player_chars[0].entity_idx: ", data.player_chars[0].entity_idx )


  // --- create map ---

  data_create_map()

  
  // -- set opengl state --
  renderer_init()

  ui_init()
	

  // ---- main loop ----
  for !window_should_close()
  {
    glfw.PollEvents();
      
    data_pre_updated()
      

    if input.mouse_button_states[Mouse_Button.RIGHT].down
    {
      camera_rotate_by_mouse()
      camera_move_by_keys()

      input_set_cursor_visibile( false )
      input_center_cursor()
    }
    else
    {
      input_set_cursor_visibile( true )
      // input_center_cursor()
    }

    if ( input.key_states[Key.ESCAPE].pressed )
    { break }

    if ( input.key_states[Key.TAB].pressed )
    { data.wireframe_mode_enabled  = !data.wireframe_mode_enabled }

    // wireframe mode
    if ( data.wireframe_mode_enabled == true )
	  { gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE) }
	  else
	  { gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL) }

    if ( input.key_states[Key.ENTER].pressed )
    {
      fmt.println( "data.cam.pos:   ", data.cam.pos )
      fmt.println( "data.cam.pitch: ", data.cam.pitch_rad )
      fmt.println( "data.cam.yaw:   ", data.cam.yaw_rad )
    }
    
    renderer_update()
    // debug_draw_tiles()

    cam_hit_tile, has_cam_hit_tile := game_find_tile_hit_by_camera()
    if has_cam_hit_tile
    {
      // start := waypoint_t{ level_idx=0, x=5, z=5 } 
      start := data.player_chars[0].tile
      // start_pos := linalg.vec3{ 
      //               f32(start.x)         * 2 - f32(TILE_ARR_X_MAX) +1,
      //               f32(start.level_idx) * 2, 
      //               f32(start.z)         * 2 - f32(TILE_ARR_Z_MAX) +1
      //              }
      start_pos := util_tile_to_pos(data.player_chars[0].tile )
      // fmt.println( "start -> pos: ", start_pos )
      debug_draw_sphere( start_pos, linalg.vec3{ 0.35, 0.35, 0.35 }, linalg.vec3{ 0, 1, 0 } )
      path, path_found := game_a_star_pathfind( start, cam_hit_tile )
      // for i in 0 ..< len(path) -1
      // {
      //
      //   p00 := linalg.vec3{ 
      //           f32(path[i].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
      //           f32(path[i].level_idx) * 2, 
      //           f32(path[i].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
      //          }
      //   p01 := linalg.vec3{ 
      //           f32(path[i +1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
      //           f32(path[i +1].level_idx) * 2, 
      //           f32(path[i +1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
      //          }
      //   debug_draw_line( p00, p01, path_found ? linalg.vec3{ 0, 1, 0 } : linalg.vec3{ 1, 0, 0 }, 25 ) 
      //
      // }
      debug_draw_path( path, path_found ? linalg.vec3{ 0, 1, 0 } : linalg.vec3{ 1, 0, 0 } )
      // debug_draw_sphere( util_tile_to_pos( path[len(path) -1] ), linalg.vec3{ 0.35, 0.35, 0.35 }, linalg.vec3{ 0, 1, 0 } )

      // data.player_chars[0]

      // pos := util_tile_to_pos( path[len(path) -1] )
      pos := util_tile_to_pos( cam_hit_tile )

      min := pos + linalg.vec3{ -1, -1, -1 }
      max := pos + linalg.vec3{  1,  1,  1 }
      debug_draw_aabb( min, max, linalg.vec3{ 0, 1, 0 }, 15)

      if input.mouse_button_states[Mouse_Button.LEFT].pressed && path_found
      { 
        // fmt.println( "mouse01 pressed ) 

        if data.player_chars[0].has_path
        {
          delete(data.player_chars[0].path)
        }

        data.player_chars[0].has_path = true
        data.player_chars[0].path = make( [dynamic]waypoint_t, len(path), cap(path) )
        copy( data.player_chars[0].path[:], path[:] )

      }

      delete( path )
    }


    for char in data.player_chars
    {
      if char.has_path
      {
        debug_draw_path( char.path, linalg.vec3{ 0, 1, 1 } )

        pos := util_tile_to_pos( char.path[len(char.path) -1] )
        pos +=  linalg.vec3{ 0, 2, 0 }
        // pos +=  linalg.vec3{ -2, 2, -2 } 
        rot := data.entity_arr[char.entity_idx].rot
        // rot.xz *= -1
        rot.y = 0
        debug_draw_mesh( data.mesh_idxs.suzanne, 
                         pos, 
                         // data.entity_arr[char.entity_idx].rot, 
                         rot,
                         data.entity_arr[char.entity_idx].scl, 
                         linalg.vec3{ 0, 1, 1 } )
        // fmt.println( "data.entity_arr[char.entity_idx]: ", data.entity_arr[char.entity_idx] )
        // os.exit(1)
      }
    }

    // // draw the gbuffer and lighting buffer onto screen as quads
    // quad_size :: linalg.vec2{ 0.25, -0.25 }
    // renderer_draw_quad( linalg.vec2{ -0.75,  0.75 }, quad_size, data.fb_deferred.buffer01 )
    // renderer_draw_quad( linalg.vec2{ -0.75,  0.25 }, quad_size, data.fb_deferred.buffer02 )
    // renderer_draw_quad( linalg.vec2{ -0.75, -0.25 }, quad_size, data.fb_deferred.buffer03 )
    // renderer_draw_quad( linalg.vec2{ -0.75, -0.75 }, quad_size, data.fb_deferred.buffer04 )
    // renderer_draw_quad( linalg.vec2{ -0.25,  0.75 }, quad_size, data.fb_lighting.buffer01 )

    ui_update()

    glfw.SwapBuffers( data.window )
    
    input_update()
  }
  
  ui_cleanup()

  glfw.DestroyWindow( data.window )
  glfw.Terminate()
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
make_texture :: proc( path: string, srgb: bool ) -> ( handle: u32 )
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

  if ( err != nil )
  {
      fmt.println("ERROR: Image failed to load.")
  }

  // Copy bytes from icon buffer into slice.
  pixels := make( []u8, len(image_ptr.pixels.buf) )
  for b, i in image_ptr.pixels.buf 
  {
      pixels[i] = b
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

