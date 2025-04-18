package core

import        "core:fmt"
import        "core:log"
import        "core:math"
import        "core:mem"
import vmem   "core:mem/virtual"
import linalg "core:math/linalg/glsl"
import gl     "vendor:OpenGL"


Debug_Draw_Call_Type :: enum
{
  SPHERE,
  MESH,
  LINE,
  AABB,
  TILES,
  COMBO_ICON,
  PATH,
  PATH_ICONS,
  CURVE,
}
debug_draw_call_t :: struct
{
  type  : Debug_Draw_Call_Type,
  pos   : vec3,
  rot   : vec3,
  scl   : vec3,
  color : vec3,
  width : f32,

  start : waypoint_t,
  en    : waypoint_t,
  
  combo_type : Combo_Type,
  assetm_idx : int,

  path: [dynamic]waypoint_t, // @TODO: find better solution to carry over path

}

// @NOTE: idk wanted to use arena for some reason
// DEBUG_DRAW_CALLS_ARENA_MAX :: size_of(debug_draw_call_t) * 100 
// debug_draw_arena : vmem.Arena
// debug_draw_alloc : mem.Allocator
// DEBUG_DRAW_CALLS_ARENA_MAX :: 100 
// debug_draw_calls : [dynamic]debug_draw_call_t // @NOTE: alloced with context.temp_allocator exclusively
DEBUG_DRAW_CALLS_MAX :: 100 
// debug_draw_calls     :  [DEBUG_DRAW_CALLS_MAX]debug_draw_call_t 
// debug_draw_calls_pos :  int = 0
debug_draw_calls     :  [dynamic]debug_draw_call_t 

debug_draw_init :: proc()
{
  // @NOTE: idk wanted to use arena for some reason
  // if vmem.arena_init_static( &debug_draw_arena, DEBUG_DRAW_CALLS_ARENA_MAX ) != mem.Allocator_Error.None
  // { log.panic( "failed to init arena alloc" ) }
  // debug_draw_alloc = vmem.arena_allocator( &debug_draw_arena )

  // set dynamic array to use context.temp_allocator
  // (^mem.Raw_Dynamic_Array)(&debug_draw_calls).allocator = context.temp_allocator
  // raw_soa_footer_dynamic_array(&debug_draw_calls).allocator = context.temp_allocator
  // debug_draw_calls = make( []debug_draw_call_t, 100, context.temp_allocator )

  debug_draw_calls = make( [dynamic]debug_draw_call_t, DEBUG_DRAW_CALLS_MAX, DEBUG_DRAW_CALLS_MAX, context.temp_allocator )
}
debug_draw_update :: proc()
{
  // @NOTE: idk wanted to use arena for some reason
  // log.debug( "size_of(debug_draw_arena):", size_of(debug_draw_arena) )
  // log.debug( "len(debug_draw_arena):", len(debug_draw_arena) )
  // log.debug( "size_of(debug_draw_alloc):", size_of(debug_draw_alloc) )
  // free_all( debug_draw_alloc )
  // log.debug( "size_of(debug_draw_arena):", size_of(debug_draw_arena) )
  // log.debug( "len(debug_draw_arena):", len(debug_draw_arena) )
  // log.debug( "size_of(debug_draw_alloc):", size_of(debug_draw_alloc) )

  // for i in 0 ..< debug_draw_calls_pos 
  for call in debug_draw_calls
  {
    // call := debug_draw_calls[i]
    switch call.type
    {
      case Debug_Draw_Call_Type.MESH:
      {
        debug_render_mesh( call.assetm_idx, call.pos, call.rot, call.scl, call.color )
      }
      case Debug_Draw_Call_Type.SPHERE:
      {
        debug_render_sphere( call.pos, call.scl, call.color )
      }
      case Debug_Draw_Call_Type.LINE:
      {
        debug_render_line( call.pos, call.rot, call.color, call.width )
      }
      case Debug_Draw_Call_Type.AABB:
      {
        debug_render_aabb( call.pos, call.rot, call.color, call.width )
      }
      case Debug_Draw_Call_Type.TILES:
      {
        debug_render_tiles()
      }
      case Debug_Draw_Call_Type.PATH:
      {
        assert( len(call.path) > 0 )
        debug_render_path( call.path, call.color, call.pos )
      }
      case Debug_Draw_Call_Type.COMBO_ICON:
      {
        debug_render_combo_icon( call.combo_type, call.pos, call.color )
      }
      case Debug_Draw_Call_Type.PATH_ICONS:
      {
        assert( len(call.path) > 0 )
        debug_render_path_icons( call.path, call.color )
      }
      case Debug_Draw_Call_Type.CURVE:
      {
        debug_render_curve_path( call.pos, call.rot, call.assetm_idx, call.color )
      }
    }
  }
  // debug_draw_calls_pos = 0
  debug_draw_calls = make( [dynamic]debug_draw_call_t, DEBUG_DRAW_CALLS_MAX, DEBUG_DRAW_CALLS_MAX, context.temp_allocator )
}
debug_draw_cleanup :: proc()
{
  // @NOTE: idk wanted to use arena for some reason
  // vmem.arena_destroy( &debug_draw_arena )
}

debug_draw_mesh :: proc( assetm_mesh_idx: int, pos, rot, scl, color: linalg.vec3 )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )

  // fmt.println( "debug_draw_calls_pos:", debug_draw_calls_pos )
  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.MESH,
    pos        = pos,
    rot        = rot,
    scl        = scl,
    color      = color,
    assetm_idx = assetm_mesh_idx,
  })
  // debug_draw_calls_pos += 1
}
debug_render_mesh :: proc( assetm_mesh_idx: int, pos, rot, scl, color: linalg.vec3 )
{
  mesh := assetm_get_mesh( assetm_mesh_idx )
	// w, h := window_get_size()

  model := util_make_model( pos, rot, scl )
  
  gl.Disable( gl.DEPTH_TEST )
  gl.Disable( gl.CULL_FACE )
	
  shader_use( data.basic_shader )
	gl.ActiveTexture( gl.TEXTURE0 )
	gl.BindTexture(gl.TEXTURE_2D, assetm_get_texture( data.texture_idxs.blank ).handle )
	shader_set_i32( data.basic_shader,  "tex", 0 )
	shader_set_vec3( data.basic_shader, "tint", color )
	
	shader_set_mat4(data.basic_shader, "model", &model[0][0] )
	shader_set_mat4(data.basic_shader, "view",  &data.cam.view_mat[0][0] )
	shader_set_mat4(data.basic_shader, "proj",  &data.cam.pers_mat[0][0] )
  
  gl.BindVertexArray( mesh.vao )
  gl.DrawElements( gl.TRIANGLES,           // Draw triangles.
                   i32(mesh.indices_len),  // indices length
                   gl.UNSIGNED_INT,        // Data type of the indices.
                   rawptr(uintptr(0)) )    // Pointer to indices. (Not needed.)

  gl.Enable( gl.DEPTH_TEST )
  gl.Enable( gl.CULL_FACE )
}

debug_draw_sphere :: proc( pos, scl, color: linalg.vec3 )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )

  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.SPHERE,
    pos        = pos,
    // rot        = rot,
    scl        = scl,
    color      = color,
    // assetm_idx = assetm_mesh_idx,
  })
  // debug_draw_calls_pos += 1
}
debug_render_sphere :: proc( pos, scl, color: linalg.vec3 )
{
  mesh := assetm_get_mesh(data.mesh_idxs.sphere)
	// w, h := window_get_size()

  model := util_make_model( pos, linalg.vec3{ 0, 0, 0 }, scl )
  
  gl.Disable( gl.DEPTH_TEST )
  gl.Disable( gl.CULL_FACE )
	
  shader_use( data.basic_shader )
	gl.ActiveTexture( gl.TEXTURE0 )
	gl.BindTexture(gl.TEXTURE_2D, assetm_get_texture( data.texture_idxs.blank ).handle )
	shader_set_i32( data.basic_shader,  "tex", 0 )
	shader_set_vec3( data.basic_shader, "tint", color )
	
	shader_set_mat4(data.basic_shader, "model", &model[0][0] )
	shader_set_mat4(data.basic_shader, "view",  &data.cam.view_mat[0][0] )
	shader_set_mat4(data.basic_shader, "proj",  &data.cam.pers_mat[0][0] )
  
  gl.BindVertexArray( mesh.vao )
  gl.DrawElements( gl.TRIANGLES,           // Draw triangles.
                   i32(mesh.indices_len),  // indices length
                   gl.UNSIGNED_INT,        // Data type of the indices.
                   rawptr(uintptr(0)) )    // Pointer to indices. (Not needed.)

  gl.Enable( gl.DEPTH_TEST )
  gl.Enable( gl.CULL_FACE )
}

debug_draw_line :: proc( pos0, pos1, tint: linalg.vec3, width: f32 )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )

  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.LINE,
    pos        = pos0,
    rot        = pos1,
    // scl        = scl,
    color      = tint,
    width      = width,
    // assetm_idx = assetm_mesh_idx,
  })
  // debug_draw_calls_pos += 1
}
debug_render_line :: proc( pos0, pos1, tint: linalg.vec3, width: f32 )
{
	// ---- mvp ----
  model := util_make_model( linalg.vec3{ 0, 0, 0 }, linalg.vec3{ 0, 0, 0 }, linalg.vec3{ 1, 1, 1 } )

  // @UNSURE: if i shoulf call this
  // camera_set_view_mat()
  // camera_set_pers_mat()

  // framebuffer_unbind()
  gl.Disable( gl.DEPTH_TEST )
  gl.Disable( gl.CULL_FACE )
	
	w, h := window_get_size()

  gl.LineWidth( width )

  // ---- vbo sub data ----

  _pos0 := [3]f32{ pos0.x, pos0.y, pos0.z }
  _pos1 := [3]f32{ pos1.x, pos1.y, pos1.z }
  gl.BindBuffer(gl.ARRAY_BUFFER, data.line_mesh.vbo);
  gl.BufferSubData(gl.ARRAY_BUFFER, 0            * size_of(f32), 3 * size_of(f32), &_pos0[0] )
  gl.BufferSubData(gl.ARRAY_BUFFER, F32_PER_VERT * size_of(f32), 3 * size_of(f32), &_pos1[0] )

	// ---- shader & draw call -----	

	shader_use( data.basic_shader )
	gl.ActiveTexture( gl.TEXTURE0 )
	gl.BindTexture(gl.TEXTURE_2D, assetm_get_texture( data.texture_idxs.blank ).handle )
	shader_set_i32( data.basic_shader,  "tex", 0 )
	shader_set_vec3( data.basic_shader, "tint", tint )
	
	shader_set_mat4(data.basic_shader, "model", &model[0][0] )
	shader_set_mat4(data.basic_shader, "view",  &data.cam.view_mat[0][0] )
	shader_set_mat4(data.basic_shader, "proj",  &data.cam.pers_mat[0][0] )

	gl.BindVertexArray(data.line_mesh.vao);
  gl.DrawArrays(gl.LINES, 0, 2);

  gl.Enable( gl.DEPTH_TEST )
  gl.Enable( gl.CULL_FACE )
}

debug_draw_aabb :: proc( min, max, color: linalg.vec3, width: f32 )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )

  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.AABB,
    pos        = min,
    rot        = max,
    // scl        = scl,
    color      = color,
    width      = width,
    // assetm_idx = assetm_mesh_idx,
  })
  // debug_draw_calls_pos += 1
}
debug_draw_aabb_wp :: #force_inline proc( wp: waypoint_t, color: linalg.vec3, width: f32, loc := #caller_location )
{
  pos := util_tile_to_pos( wp )
  min := pos + linalg.vec3{ -1, -1, -1 }
  max := pos + linalg.vec3{  1,  1,  1 }
  debug_draw_aabb( min, max, color, width )
}
debug_render_aabb :: proc( min, max, color: linalg.vec3, width: f32 )
{
  top0 := linalg.vec3{ max[0], max[1], max[2] }
  top1 := linalg.vec3{ max[0], max[1], min[2] } 
  top2 := linalg.vec3{ min[0], max[1], min[2] } 
  top3 := linalg.vec3{ min[0], max[1], max[2] } 
  
  bot0 := linalg.vec3{ max[0], min[1], max[2] }
  bot1 := linalg.vec3{ max[0], min[1], min[2] }
  bot2 := linalg.vec3{ min[0], min[1], min[2] }
  bot3 := linalg.vec3{ min[0], min[1], max[2] }
  
  debug_draw_line( top0, top1, color, width ) 
  debug_draw_line( top1, top2, color, width ) 
  debug_draw_line( top2, top3, color, width ) 
  debug_draw_line( top3, top0, color, width ) 
  
  debug_draw_line( bot0, bot1, color, width ) 
  debug_draw_line( bot1, bot2, color, width ) 
  debug_draw_line( bot2, bot3, color, width ) 
  debug_draw_line( bot3, bot0, color, width ) 
  
  debug_draw_line( bot0, top0, color, width ) 
  debug_draw_line( bot1, top1, color, width ) 
  debug_draw_line( bot2, top2, color, width ) 
  debug_draw_line( bot3, top3, color, width ) 
}

debug_draw_tiles :: proc( )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )

  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.TILES,
    // pos        = min,
    // rot        = max,
    // scl        = scl,
    // color      = tint,
    // width      = width,
    // assetm_idx = assetm_mesh_idx,
  })
  // debug_draw_calls_pos += 1
}
debug_render_tiles :: proc()
{
  level_idx := 0
  // for level_idx in 0 ..< len(data.tile_str_arr)
  {
  
    // for z := TILE_ARR_Z_MAX -1; z >= 0; z -= 1    // reversed so the str aligns with the created map
    // {
    //   for x := TILE_ARR_X_MAX -1; x >= 0; x -= 1  // reversed so the str aligns with the created map
    for z := 0; z < TILE_ARR_Z_MAX; z += 1
    {
      for x := 0; x < TILE_ARR_X_MAX; x += 1
      {
        nav_type := data.tile_type_arr[level_idx][x][z]
  
        pos := linalg.vec3{ 
                f32(x) * 2 - f32(TILE_ARR_X_MAX) +1,
                f32(level_idx) * 2, 
                f32(z) * 2 - f32(TILE_ARR_Z_MAX) +1
               }
        min := pos + linalg.vec3{ -1, -1, -1 }
        max := pos + linalg.vec3{  1,  1,  1 }
        switch nav_type
        {
          case Tile_Nav_Type.EMPTY:
          {
            debug_draw_sphere( pos, linalg.vec3{ 0.25, 0.25, 0.25 },
                             linalg.vec3{ 1, 1, 1 } )
          }
          case Tile_Nav_Type.BLOCKED:
          {
            debug_draw_sphere( pos, linalg.vec3{ 0.25, 0.25, 0.25 },
                             linalg.vec3{ 1, 0, 0 } ) 
          }
          case Tile_Nav_Type.TRAVERSABLE:
          {
            debug_draw_sphere( pos, linalg.vec3{ 0.25, 0.25, 0.25 },
                             linalg.vec3{ 0, 1, 0 } ) 
          }
          case Tile_Nav_Type.BOX:    fallthrough 
          case Tile_Nav_Type.SPRING:
          {
            debug_draw_sphere( pos, linalg.vec3{ 0.25, 0.25, 0.25 },
                             linalg.vec3{ 1, 1, 0 } )
          }
          case Tile_Nav_Type.RAMP_FORWARD:  fallthrough
          case Tile_Nav_Type.RAMP_BACKWARD: fallthrough
          case Tile_Nav_Type.RAMP_LEFT:     fallthrough
          case Tile_Nav_Type.RAMP_RIGHT: 
          {
            debug_draw_sphere( pos, linalg.vec3{ 0.25, 0.25, 0.25 },
                             linalg.vec3{ 0, 1, 0 } ) 
          }
  
        }
      }
    }
  }
}

debug_draw_combo_icon:: proc( combo_type: Combo_Type, pos, color: vec3 )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )

  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.COMBO_ICON,
    pos        = pos,
    // rot        = max,
    // scl        = scl,
    color      = color,
    // width      = width,
    // assetm_idx = assetm_mesh_idx,
    combo_type = combo_type,
  })
  // debug_draw_calls_pos += 1
}
debug_render_combo_icon :: #force_inline proc( combo_type: Combo_Type, pos, color: vec3 )
{
  // draw combo-actions
  switch combo_type
  { 
    case Combo_Type.NONE: {} 
    case Combo_Type.PUSH: fallthrough
    case Combo_Type.JUMP:
    {
      debug_draw_mesh( data.mesh_idxs.icon_jump, 
                       pos + linalg.vec3{ 0, 1, 0 },  // pos 
                       linalg.vec3{ 0, 0, 0 },        // rot
                       linalg.vec3{ 0.5, 0.5, 0.5 },  // scl
                       color )                        // color
    }
    case Combo_Type.ATTACK:
    {
      debug_draw_mesh( data.mesh_idxs.icon_attack, 
                       pos + linalg.vec3{ 0, 1, 0 },  // pos 
                       linalg.vec3{ 0, 0, 0 },        // rot
                       linalg.vec3{ 0.5, 0.5, 0.5 },  // scl
                       color )                        // color
    }
  }
}

debug_draw_path_icons :: proc( path: [dynamic]waypoint_t, color: linalg.vec3 )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )
  // assert( len(path) <= 100 ) // @TODO: debug_draw_call_t.path is len 100 -> find better solution to carry over path
 
  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.PATH_ICONS,
    // pos        = pos,
    // rot        = max,
    // scl        = scl,
    color      = color,
    // width      = width,
    // assetm_idx = assetm_mesh_idx,
    // combo_type = combo_type,
  })
  // debug_draw_calls[debug_draw_calls_pos].path = make( [dynamic]waypoint_t, len(path), len(path), context.temp_allocator )
  debug_draw_calls[len(debug_draw_calls) -1].path = make( [dynamic]waypoint_t, len(path), len(path), context.temp_allocator )
  // copy( debug_draw_calls[debug_draw_calls_pos].path[:], path[:] )
  copy( debug_draw_calls[len(debug_draw_calls) -1].path[:], path[:] )
  // debug_draw_calls_pos += 1
}
debug_render_path_icons :: proc( path: [dynamic]waypoint_t, color: linalg.vec3 ) 
{
  for i in 0 ..< len(path) -1
  {
    debug_draw_combo_icon( path[i].combo_type, util_tile_to_pos( path[i] ), color )
  }
}
debug_draw_char_path :: proc( char: ^character_t )
{
  if len(char.paths_arr) > 0
  {
    for p in char.paths_arr 
    { 
      switch p[0].combo_type
      {
        case Combo_Type.PUSH:
        {
          debug_draw_path( p, vec3{ 1, 1, 1 }, char.path_offset + vec3{ 0, 1, 0 } ) 
          // get next tile following the path
          // p0-->p1
          // p2 = p1 - p0 + p1
          debug_box_tile := waypoint_t{ level_idx  = p[len(p) -1].level_idx - p[len(p) -2].level_idx + p[len(p) -1].level_idx,
                                        x          = p[len(p) -1].x - p[len(p) -2].x + p[len(p) -1].x, 
                                        z          = p[len(p) -1].z - p[len(p) -2].z + p[len(p) -1].z, 
                                        combo_type = Combo_Type.NONE,
                                      }
          debug_box_pos  := util_tile_to_pos( debug_box_tile ) 
          debug_draw_mesh( data.mesh_idxs.box,
                           debug_box_pos + vec3{ 0, 1, 0 },                 // pos
                           vec3{ 0, 0, 0 }, vec3{ 1, 1, 1 }, char.color )   // rot, scl, color
          fallthrough
        }
        case Combo_Type.ATTACK: fallthrough // { log.panic( "should never get triggerred" ) } // ignore
        case Combo_Type.NONE:
        {
          debug_draw_path( p, char.color, char.path_offset ) 
        }
        case Combo_Type.JUMP:
        {
          debug_draw_curve_path_wp( p[0], p[len(p) -1], 20, char.color )
        }
      }
      // debug_draw_path_icons( p, linalg.vec3{ 1, 1, 0 } )
      debug_draw_path_icons( p, char.color )

      // debug_draw_sphere( util_tile_to_pos( p[len(p) -1] ), linalg.vec3{ 1, 1, 1 }, linalg.vec3{ 0, 1, 1 } ) 
    }
    // debug_draw_sphere( linalg.vec3{ 0, 1, 0 } + util_tile_to_pos( char.paths_arr[0][0] ), linalg.vec3{ 0.35, 0.35, 0.35 }, linalg.vec3{ 0, 1, 1 } )
    // debug_draw_sphere( linalg.vec3{ 0, 1, 0 } + util_tile_to_pos( char.paths_arr[len(char.paths_arr) -1][len(char.paths_arr[len(char.paths_arr) -1]) -1] ), linalg.vec3{ 0.35, 0.35, 0.35 }, linalg.vec3{ 0, 1, 1 } )
    debug_draw_sphere( linalg.vec3{ 0, 1, 0 } + util_tile_to_pos( char.paths_arr[0][0] ), linalg.vec3{ 0.35, 0.35, 0.35 }, char.color )
    debug_draw_sphere( linalg.vec3{ 0, 1, 0 } + util_tile_to_pos( char.paths_arr[len(char.paths_arr) -1][len(char.paths_arr[len(char.paths_arr) -1]) -1] ), linalg.vec3{ 0.35, 0.35, 0.35 }, char.color )

    // pos := util_tile_to_pos( char.path[len(char.path) -1] )
    idx := len(char.paths_arr) -1
    pos := util_tile_to_pos( char.paths_arr[idx][ len(char.paths_arr[idx]) -1 ] )
    pos += linalg.vec3{ 0, 2, 0 }
    rot := data.entity_arr[char.entity_idx].rot
    debug_draw_mesh( data.entity_arr[char.entity_idx].mesh_idx,
                     pos, 
                     rot,
                     data.entity_arr[char.entity_idx].scl, 
                     // linalg.vec3{ 0, 1, 1 } )
                     char.color )
    // fmt.println( "data.entity_arr[char.entity_idx]: ", data.entity_arr[char.entity_idx] )
    // os.exit(1)
  }
  
}

debug_draw_path :: proc( path: [dynamic]waypoint_t, color: vec3, offset := vec3{ 0, 0, 0 } )
{
  // assert( debug_draw_calls_pos < len(debug_draw_calls) )
 
  // debug_draw_calls[debug_draw_calls_pos] =  
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.PATH,
    pos        = offset,
    // rot        = max,
    // scl        = scl,
    color      = color,
    // width      = width,
    // assetm_idx = assetm_mesh_idx,
    // combo_type = combo_type,
  })
  // assert( len(path) <= 100 ) // @TODO: debug_draw_call_t.path is len 100 -> find better solution to carry over path
  // debug_draw_calls[debug_draw_calls_pos].path = make( [dynamic]waypoint_t, len(path), len(path), context.temp_allocator )
  debug_draw_calls[len(debug_draw_calls) -1].path = make( [dynamic]waypoint_t, len(path), len(path), context.temp_allocator )
  copy( debug_draw_calls[len(debug_draw_calls) -1].path[:], path[:] )
  // debug_draw_calls_pos += 1
}
debug_render_path :: proc( path: [dynamic]waypoint_t, color: vec3, offset := vec3{ 0, 0, 0 }, loc := #caller_location )
{

  for i in 0 ..< len(path) -1
  {
    c : f32 = f32(i +1) / f32( len( path ) )
    // debug_draw_aabb_wp( w, linalg.vec3{ 1, 1, 1 }, 10 )
    col := linalg.vec3{ c, c, c } * color
  
    p00 := linalg.vec3{ 
            f32(path[i].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
            f32(path[i].level_idx) * 2 + 1.0, 
            f32(path[i].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
           }
    p01 := linalg.vec3{ 
            f32(path[i +1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
            f32(path[i +1].level_idx) * 2 + 1.0, 
            f32(path[i +1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
           }
    p00 += offset
    p01 += offset
    debug_draw_line( p00, p01, col, 550 / data.monitor_ppi_width )  
    
    // // @TMP:
    // debug_draw_sphere( p00, linalg.vec3{ 0.15, 0.15, 0.15 }, color )
  }
  p_sphere := linalg.vec3{ 
          f32(path[len(path) -1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
          f32(path[len(path) -1].level_idx) * 2 + 1.0, 
          f32(path[len(path) -1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
         }
  debug_draw_sphere( p_sphere, linalg.vec3{ 0.35, 0.35, 0.35 }, color )
}
// debug_render_path :: proc( path: [dynamic]waypoint_t, color: vec3, offset := vec3{ 0, 0, 0 }, loc := #caller_location )
// {
//   // log.debug( loc )
// 
// 
//   // @NOTE: using gl.LINE_STRIP 
//   // {
//   //   model := util_make_model( linalg.vec3{ 0, 0, 0 }, linalg.vec3{ 0, 0, 0 }, linalg.vec3{ 1, 1, 1 } )
//   //   gl.Disable( gl.DEPTH_TEST )
//   //   gl.Disable( gl.CULL_FACE )
// 	//   
// 	//   w, h := window_get_size()
//   //   gl.LineWidth( 550 / data.monitor_ppi_width )
//   //   // ---- vbo sub data ----
//   //   pos_arr := make( []f32, len(path) * 3, context.temp_allocator )
//   //   pos_arr_pos := 0
//   //   for i in 0 ..< len(path) -1
//   //   {
//   //     p := util_tile_to_pos( path[i] )
//   //     pos_arr[pos_arr_pos +0] = p.x
//   //     pos_arr[pos_arr_pos +1] = p.y
//   //     pos_arr[pos_arr_pos +2] = p.z
//   //     pos_arr_pos += 3
//   //   }
//   //   gl.BindBuffer(gl.ARRAY_BUFFER, data.line_mesh.vbo);
//   //   // gl.BufferSubData(gl.ARRAY_BUFFER, 0            * size_of(f32), 3 * size_of(f32), &_pos0[0] )
//   //   // gl.BufferSubData(gl.ARRAY_BUFFER, F32_PER_VERT * size_of(f32), 3 * size_of(f32), &_pos1[0] )
//   //   gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(pos_arr) * 3 * size_of(f32), &pos_arr[0] )
// 	//   // ---- shader & draw call -----	
// 	//   shader_use( data.basic_shader )
// 	//   gl.ActiveTexture( gl.TEXTURE0 )
// 	//   gl.BindTexture(gl.TEXTURE_2D, assetm_get_texture( data.texture_idxs.blank ).handle )
// 	//   shader_set_i32( data.basic_shader,  "tex", 0 )
// 	//   shader_set_vec3( data.basic_shader, "tint", color )
// 	//   
// 	//   shader_set_mat4(data.basic_shader, "model", &model[0][0] )
// 	//   shader_set_mat4(data.basic_shader, "view",  &data.cam.view_mat[0][0] )
// 	//   shader_set_mat4(data.basic_shader, "proj",  &data.cam.pers_mat[0][0] )
// 	//   gl.BindVertexArray( data.line_mesh.vao )
//   //   gl.DrawArrays( gl.LINE_STRIP, 0, i32(len(path)) )
//   //   // gl.DrawElements(gl.LINES, 2, gl.UNSIGNED_INT, rawptr(uintptr(0)) );
//   //   gl.Enable( gl.DEPTH_TEST )
//   //   gl.Enable( gl.CULL_FACE )
//   // }
// 
//   // <<<<<<< HEAD
//     for i in 0 ..< len(path) -1
//     {
//       c : f32 = f32(i +1) / f32( len( path ) )
//       // debug_draw_aabb_wp( w, linalg.vec3{ 1, 1, 1 }, 10 )
//       col := linalg.vec3{ c, c, c } * color
//   
//       p00 := linalg.vec3{ 
//               f32(path[i].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
//               f32(path[i].level_idx) * 2 + 1.0, 
//               f32(path[i].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
//              }
//       p01 := linalg.vec3{ 
//               f32(path[i +1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
//               f32(path[i +1].level_idx) * 2 + 1.0, 
//               f32(path[i +1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
//              }
//       p00 += offset
//       p01 += offset
//       debug_draw_line( p00, p01, col, 550 / data.monitor_ppi_width )  
//       
//       // // @TMP:
//       // debug_draw_sphere( p00, linalg.vec3{ 0.15, 0.15, 0.15 }, color )
//     }
//     p_sphere := linalg.vec3{ 
//             f32(path[len(path) -1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
//             f32(path[len(path) -1].level_idx) * 2 + 1.0, 
//             f32(path[len(path) -1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
//            }
//   // =======
//     pos_arr := make( []f32, len(path) * F32_PER_VERT, context.temp_allocator )
//     // defer delete( pos_arr )  // @NOTE: no need cause temp_alloc
//     pos_arr_pos := 0
//     for i in 0 ..< len(path) -1
//     {
//       p := util_tile_to_pos( path[i] )
//       pos_arr[pos_arr_pos +0]  = p.x
//       pos_arr[pos_arr_pos +1]  = p.y
//       pos_arr[pos_arr_pos +2]  = p.z
//       pos_arr[pos_arr_pos +3]  = 0 
//       pos_arr[pos_arr_pos +4]  = 0 
//       pos_arr[pos_arr_pos +5]  = 0 
//       pos_arr[pos_arr_pos +6]  = 0 
//       pos_arr[pos_arr_pos +7]  = 0 
//       pos_arr[pos_arr_pos +8]  = 0 
//       pos_arr[pos_arr_pos +9]  = 0 
//       pos_arr[pos_arr_pos +10] = 0 
//       debug_draw_sphere( vec3{ pos_arr[pos_arr_pos +0],
//                                pos_arr[pos_arr_pos +1],
//                                pos_arr[pos_arr_pos +2] },  
//                          vec3{ 0.2, 0.2, 0.2 },
//                          vec3{ 0, 1, 1 }
//                        )
//       pos_arr_pos += 3
//     }
// 
//     // gl.BindBuffer( gl.ARRAY_BUFFER, data.line_mesh.vbo )
//     // gl.BufferSubData( gl.ARRAY_BUFFER, 0            * size_of(f32), 3 * size_of(f32), &_pos0[0] )
//     // gl.BufferSubData( gl.ARRAY_BUFFER, F32_PER_VERT * size_of(f32), 3 * size_of(f32), &_pos1[0] )
// 
//     // gl.BindBuffer( gl.ARRAY_BUFFER, vbo )
//     // // gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(pos_arr) * 3 * size_of(f32), &pos_arr[0] )
//     // gl.BufferSubData( gl.ARRAY_BUFFER, 0, len(pos_arr) * size_of(f32), &pos_arr[0] )
// 
//     vao, vbo : u32
//     gl.GenVertexArrays( 1, &vao )
//     gl.GenBuffers( 1, &vbo )
//     gl.BindVertexArray( vao )
//     gl.BindBuffer( gl.ARRAY_BUFFER, vbo )
// 	  gl.BufferData( gl.ARRAY_BUFFER, size_of(pos_arr), &pos_arr, gl.STATIC_DRAW )
// 
//     gl.EnableVertexAttribArray( 0 ) // pos
// 	  gl.VertexAttribPointer( 0, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 0 )
// 	  gl.EnableVertexAttribArray( 1 ) // uv
// 	  gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 3 * size_of(f32) )
// 	  gl.EnableVertexAttribArray( 2 ) // normals 
// 	  gl.VertexAttribPointer( 2, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 5 * size_of(f32) )
// 	  gl.EnableVertexAttribArray( 3 ) // tangents 
// 	  gl.VertexAttribPointer( 3, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 8 * size_of(f32) )
// 
// 	  // ---- shader & draw call -----	
// 
// 	  shader_use( data.basic_shader )
// 	  gl.ActiveTexture( gl.TEXTURE0 )
// 	  gl.BindTexture(gl.TEXTURE_2D, assetm_get_texture( data.texture_idxs.blank ).handle )
// 	  shader_set_i32( data.basic_shader,  "tex", 0 )
// 	  shader_set_vec3( data.basic_shader, "tint", color )
// 	  
// 	  shader_set_mat4(data.basic_shader, "model", &model[0][0] )
// 	  shader_set_mat4(data.basic_shader, "view",  &data.cam.view_mat[0][0] )
// 	  shader_set_mat4(data.basic_shader, "proj",  &data.cam.pers_mat[0][0] )
// 
// 	  // gl.BindVertexArray( data.line_mesh.vao )
// 	  gl.BindVertexArray( vao )
//     // gl.DrawArrays( gl.LINE_STRIP, 0, i32(len(path)) )
//     gl.DrawElements( gl.LINE_STRIP, i32(len(path)), gl.FLOAT, nil )
// 
//     gl.Enable( gl.DEPTH_TEST )
//     gl.Enable( gl.CULL_FACE )
//   // }
//   return
// 
//   // for i in 0 ..< len(path) -1
//   // {
//   //   c : f32 = f32(i +1) / f32( len( path ) )
//   //   // debug_draw_aabb_wp( w, linalg.vec3{ 1, 1, 1 }, 10 )
//   //   col := linalg.vec3{ c, c, c } * color
// 
//   //   p00 := linalg.vec3{ 
//   //           f32(path[i].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
//   //           f32(path[i].level_idx) * 2 + 1.0, 
//   //           f32(path[i].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
//   //          }
//   //   p01 := linalg.vec3{ 
//   //           f32(path[i +1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
//   //           f32(path[i +1].level_idx) * 2 + 1.0, 
//   //           f32(path[i +1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
//   //          }
//   //   p00 += offset
//   //   p01 += offset
//   //   debug_draw_line( p00, p01, col, 550 / data.monitor_ppi_width )  
//   //   
//   //   // // @TMP:
//   //   // debug_draw_sphere( p00, linalg.vec3{ 0.15, 0.15, 0.15 }, color )
//   // }
//   // p_sphere := linalg.vec3{ 
//   //         f32(path[len(path) -1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
//   //         f32(path[len(path) -1].level_idx) * 2 + 1.0, 
//   //         f32(path[len(path) -1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
//   //        }
// // >>>>>>> bce03d23340e94d16d3905aa5cac341571593468
//   // debug_draw_sphere( p_sphere, linalg.vec3{ 0.35, 0.35, 0.35 }, color )
// }

debug_draw_curve_path :: proc( start, end: vec3, divisions: int, color: linalg.vec3 )
{
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.CURVE,
    pos        = start,
    rot        = end,
    // scl        = scl,
    color      = color,
    // width      = width,
    assetm_idx = divisions,
    // combo_type = combo_type,
  })
}
debug_draw_curve_path_wp :: proc( start, end: waypoint_t, divisions: int, color: linalg.vec3 )
{
  append( &debug_draw_calls, debug_draw_call_t{
    type       = Debug_Draw_Call_Type.CURVE,
    pos        = util_tile_to_pos( start ),
    rot        = util_tile_to_pos( end ),
    // scl        = scl,
    color      = color,
    // width      = width,
    assetm_idx = divisions,
    // combo_type = combo_type,
  })
}
// @TODO: @NOTE: not super accurate, wrote this while drunk, but mostly kinda works 😉👍
debug_render_curve_path :: proc( start, end: vec3, divisions: int, color: linalg.vec3 )
{
  // start_pos := util_tile_to_pos( start ) + linalg.vec3{ 0, 1, 0 }
  // end_pos   := util_tile_to_pos( end )   + linalg.vec3{ 0, 1, 0 }
  start_pos := start + linalg.vec3{ 0, 1, 0 }
  end_pos   := end   + linalg.vec3{ 0, 1, 0 }
  step := ( end_pos - start_pos ) / f32(divisions)
  p00  := start_pos
  p01  := start_pos

  up := linalg.cross( step, linalg.vec3{ 1, 0, 0 } )
  up  = linalg.normalize( up )

  // for i in 0 ..= divisions
  for i in 0 ..< divisions
  {
    c : f32 = f32(i) / f32(divisions -1)
    col := linalg.vec3{ c, c, c } * color
    // debug_draw_aabb_wp( w, linalg.vec3{ 1, 1, 1 }, 10 )

    p01 = start_pos + ( step * f32(i) )
    y := p01.y

    perc := f32(i) / f32(divisions -1)
    y_offs := math.sin( perc * math.PI )
    y_offs *= 5  // scale height
    
    p01.y += y_offs
    debug_draw_line( p00, p01, col, 550 / data.monitor_ppi_width ) 

    p00 = p01
  }
}
