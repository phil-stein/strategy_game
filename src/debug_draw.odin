package core

import        "core:fmt"
import        "core:log"
import        "core:math"
import linalg "core:math/linalg/glsl"
import gl     "vendor:OpenGL"


debug_draw_mesh :: proc( assetm_mesh_idx: int, pos, rot, scl, color: linalg.vec3 )
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

debug_draw_line :: proc(pos0, pos1, tint: linalg.vec3, width: f32)
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
  // gl.DrawElements(gl.LINES, 2, gl.UNSIGNED_INT, rawptr(uintptr(0)) );

  gl.Enable( gl.DEPTH_TEST )
  gl.Enable( gl.CULL_FACE )
}

debug_draw_aabb_wp :: proc( wp: waypoint_t, color: linalg.vec3, width: f32, loc := #caller_location )
{
  // log.debug( loc )
  pos := util_tile_to_pos( wp )

  min := pos + linalg.vec3{ -1, -1, -1 }
  max := pos + linalg.vec3{  1,  1,  1 }
  debug_draw_aabb( min, max, color, width )
}
debug_draw_aabb :: proc( min, max, color: linalg.vec3, width: f32 )
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

debug_draw_tiles :: proc()
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

debug_draw_combo_icon :: #force_inline proc( combo_type: Combo_Type, pos, color: vec3 )
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
          debug_draw_curve_path( p[0], p[len(p) -1], 20, char.color )
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
debug_draw_path :: proc( path: [dynamic]waypoint_t, color: vec3, offset := vec3{ 0, 0, 0 }, loc := #caller_location )
{
  // log.debug( loc )

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
    debug_draw_line( p00, p01, col, 25 )  
    
    // // @TMP:
    // debug_draw_sphere( p00, linalg.vec3{ 0.15, 0.15, 0.15 }, color )
  }
  p_sphere := linalg.vec3{ 
          f32(path[len(path) -1].x)         * 2 - f32(TILE_ARR_X_MAX) +1,
          f32(path[len(path) -1].level_idx) * 2 + 1.0, 
          f32(path[len(path) -1].z)         * 2 - f32(TILE_ARR_Z_MAX) +1
         }
  // debug_draw_sphere( p_sphere, linalg.vec3{ 0.35, 0.35, 0.35 }, color )
}

// @TODO: @NOTE: not super accurate, wrote this while drunk, but mostly kinda works 😉👍
debug_draw_curve_path :: proc( start, end: waypoint_t, divisions: int, color: linalg.vec3 )
{
  start_pos := util_tile_to_pos( start ) + linalg.vec3{ 0, 1, 0 }
  end_pos   := util_tile_to_pos( end )   + linalg.vec3{ 0, 1, 0 }
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
    debug_draw_line( p00, p01, col, 25 ) 

    p00 = p01
  }
}
