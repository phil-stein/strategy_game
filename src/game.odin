package core 

import        "core:fmt"
import        "core:log"
import        "core:time"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "core:slice"


node_t :: struct
{
  // using 
  wp: waypoint_t,
  // a*
  f_cost     : f32,
  parent     : waypoint_t,
  // parent_idx : int,
  ramp_connector: union{ Dir }, // nil means not connected to ramp
}
Dir :: enum
{
  FORWARD,  // = Tile_Nav_Type.RAMP_UP,   // @NOTE: this technically is forward
  BACKWARDS,// = Tile_Nav_Type.RAMP_DOWN, // @NOTE: this technically is backward
  LEFT,     // = Tile_Nav_Type.RAMP_LEFT,
  RIGHT,    // = Tile_Nav_Type.RAMP_RIGHT,
}

game_update :: proc()
{
  cam_hit_tile     : waypoint_t
  has_cam_hit_tile : bool = false
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
    
    m_x := ( input.mouse_x / f32(data.window_width)  ) * 2 -1
    m_y := ( 1- ( input.mouse_y / f32(data.window_height ) ) ) * 2 -1
    // log.debug( "m_x:", m_x, ", m_y:", m_y )
    debug_timer_start( "game_find_tile_hit_by_camera_space_pos" ) 
    cam_hit_tile, has_cam_hit_tile = game_find_tile_hit_by_camera_space_pos( vec2{ m_x, m_y } )
    debug_timer_stop() // "game_find_tile_hit_by_camera_space_pos"
  }
  if input.key_states[Key.UP].pressed
  { 
    data.player_chars_current += 1
    data.player_chars_current = data.player_chars_current >= len(data.player_chars) ? -1 : data.player_chars_current
  }
  if input.key_states[Key.DOWN].pressed
  { 
    data.player_chars_current -= 1
    data.player_chars_current = data.player_chars_current < -1 ? len(data.player_chars) -1 : data.player_chars_current
  }

  // @TODO: 
  // mouse_pick_id := renderer_mouse_position_mouse_pick_id()
  // if !input.mouse_over_ui && !input.mouse_button_states[Mouse_Button.RIGHT].down &&
  //    input.mouse_button_states[Mouse_Button.LEFT].pressed
  // {
  //   if mouse_pick_id >= 0 && mouse_pick_id < len(data.player_chars) && 
  //      mouse_pick_id != data.player_chars_current
  //   {
  //     data.player_chars_current = mouse_pick_id
  //   }
  //   else { data.player_chars_current = -1 }
  //   // else { log.panic( "id invalid: ", id ) }
  //   log.debug( "mouse_pick_id:", mouse_pick_id )
  //   log.debug( "data.player_chars_current:", data.player_chars_current )
  // }
  mouse_pick_id := renderer_mouse_position_mouse_pick_id()
  if !input.mouse_over_ui && !input.mouse_button_states[Mouse_Button.RIGHT].down &&
     input.mouse_button_states[Mouse_Button.LEFT].pressed && 
     mouse_pick_id >= 0 && mouse_pick_id < len(data.player_chars)
  {
    if mouse_pick_id >= 0 && mouse_pick_id < len(data.player_chars) && 
       mouse_pick_id != data.player_chars_current
    {
      data.player_chars_current = mouse_pick_id
    }
    else { data.player_chars_current = -1 }
    // else { log.panic( "id invalid: ", id ) }
    log.debug( "mouse_pick_id:", mouse_pick_id )
    log.debug( "data.player_chars_current:", data.player_chars_current )
  }


  // @NOTE: @TMP: false && just temp
  if has_cam_hit_tile && data.player_chars_current >= 0 /* && false */
  {
    new_turn := true
    start := data.player_chars[data.player_chars_current].tile

    if data.player_chars[data.player_chars_current].left_turns > 0 &&
       len(data.player_chars[data.player_chars_current].paths_arr) > 0
    {
      new_turn = false
      idx00 := len(data.player_chars[data.player_chars_current].paths_arr) -1
      idx01 := len(data.player_chars[data.player_chars_current].paths_arr[idx00]) -1
      start = data.player_chars[data.player_chars_current].paths_arr[idx00][idx01]
    }

    
    path           : [dynamic]waypoint_t = nil
    path_found     := false
    path_found_err := Pathfind_Error.NONE
    path_type      := Combo_Type.NONE

    switch data.player_chars[data.player_chars_current].path_current_combo
    {
      case Combo_Type.PUSH:   fallthrough 
      case Combo_Type.ATTACK: fallthrough // { log.panic( "should never get triggerred" ) } // ignore
      case Combo_Type.NONE:
      {
        // path, path_found = game_a_star_pathfind_levels( start, cam_hit_tile )
        path, path_found_err, path_found = game_a_star_02_pathfind( start, cam_hit_tile )
        // path, path_found_err, path_found = game_a_star_02_pathfind_old( start, cam_hit_tile )
        // fmt.println( "path_found:", path_found, "len(path):", len(path) )
        if !path_found 
        { path_found_err = Pathfind_Error.NOT_FOUND }
        else if len(path) > data.player_chars[data.player_chars_current].max_walk_dist
        { path_found_err = Pathfind_Error.TOO_LONG; path_found = false }
        if start.level_idx == cam_hit_tile.level_idx &&
           start.x         == cam_hit_tile.x && 
           start.z         == cam_hit_tile.z 
        { path_found_err = Pathfind_Error.START_END_SAME_TILE; path_found = false }
        // @TODO: @BUGG: game_a_star_02_pathfind() returns path reversed, cant do it in the proc leads to buggs for some reason
        if path_found_err == Pathfind_Error.PATH_NEEDS_TO_BE_REVERSED
        { slice.reverse( path[:] ) }
        // fmt.println( "len(path):", len(path), ", max_walk_dist:", data.player_chars[data.player_chars_current].max_walk_dist, ", path_found_err:", path_found_err )

        path_type = Combo_Type.NONE
      }
      case Combo_Type.JUMP:
      {
        path, path_found_err = game_check_jump_valid( data.player_chars[data.player_chars_current], start, cam_hit_tile )
        // fmt.println( "path_found:", path_found, "len(path):", len(path) )
        if path_found_err != Pathfind_Error.NONE { path_found = false }
        else { path_found = true }
        path_type = Combo_Type.JUMP
        // data.player_chars[data.player_chars_current].path_current_combo = Combo_Type.NONE // set for next turn
      }
    }
    
    if path_found // && mouse_pick_id < 0
    { 
      intersecting_path       := false
      intersecting_char_idx   := -1
      intersecting_combo_type := Combo_Type.NONE

      // debug_draw_aabb_wp( path[len(path) -1], vec3{ 1, 1, 1 }, 20 )
      // if path_type != Combo_Type.JUMP   // only need to check interections for paths along the floor 
      // {
        for &char, i in data.player_chars
        {
          if i == data.player_chars_current { continue }

          if len(char.paths_arr) > 0
          {
            for p in char.paths_arr
            {
              for w, wp_idx in p
              {
                // end of path intersects with other chars path
                if w.level_idx == path[len(path) -1].level_idx &&
                   w.x         == path[len(path) -1].x &&
                   w.z         == path[len(path) -1].z   
                {
                  intersecting_path     = true 
                  intersecting_char_idx = i
                  // @TODO: add more types, like landing on enemy head and tackling them
                  intersecting_combo_type = Combo_Type.JUMP
                  // debug_draw_sphere( util_tile_to_pos( w ) + linalg.vec3{ 0, 1, 0 }, linalg.vec3{ 0.35, 0.35, 0.35 }, char.color )
                  debug_draw_combo_icon( intersecting_combo_type, util_tile_to_pos( w ), char.color )
                }
              }
            }
          }
        }
        // end of path intersects with interactables 
        if path[len(path) -1].level_idx < TILE_LEVELS_MAX -1
        {
          switch data.tile_type_arr[path[len(path) -1].level_idx +1][path[len(path) -1].x][path[len(path) -1].z]
          {
            // these arent part of this switch statement but not doing #partial_switch makes the compiler remiond me 
            case Tile_Nav_Type.EMPTY: {}
            case Tile_Nav_Type.BLOCKED: {}
            case Tile_Nav_Type.TRAVERSABLE: {}
            case Tile_Nav_Type.RAMP_FORWARD: {}
            case Tile_Nav_Type.RAMP_BACKWARD: {}
            case Tile_Nav_Type.RAMP_LEFT: {}
            case Tile_Nav_Type.RAMP_RIGHT: {}

            case Tile_Nav_Type.SPRING:
            {
              intersecting_path       = true 
              intersecting_char_idx   = data.player_chars_current
              intersecting_combo_type = Combo_Type.JUMP
              debug_draw_combo_icon( intersecting_combo_type, 
                                     util_tile_to_pos( path[len(path) -1] ), 
                                     data.player_chars[data.player_chars_current].color )
            }
            case Tile_Nav_Type.BOX: 
            {
              intersecting_path       = true 
              intersecting_char_idx   = data.player_chars_current
              intersecting_combo_type = Combo_Type.PUSH
              debug_draw_combo_icon( intersecting_combo_type, 
                                     util_tile_to_pos( path[len(path) -1] ), 
                                     data.player_chars[data.player_chars_current].color )
            }
          }
        }
        for enemy, i in data.enemy_chars
        {
          if enemy.tile.level_idx == path[len(path) -1].level_idx &&
             enemy.tile.x         == path[len(path) -1].x &&
             enemy.tile.z         == path[len(path) -1].z   
          {
            intersecting_path     = true 
            intersecting_char_idx = i
            // @TODO: add more types, like landing on enemy head and tackling them
            intersecting_combo_type = Combo_Type.ATTACK
            
            debug_draw_combo_icon( intersecting_combo_type, util_tile_to_pos( enemy.tile ), enemy.color )
          }
        }
      // }

      // if input.mouse_button_states[Mouse_Button.LEFT].pressed && input.mouse_button_states[Mouse_Button.RIGHT].down && path_found
      if input.mouse_button_states[Mouse_Button.LEFT].pressed && path_found // && mouse_pick_id < 0
      { 
        if intersecting_path && data.player_chars[data.player_chars_current].left_turns < 1 
        { 
          data.player_chars[data.player_chars_current].left_turns += 1; 
          // fmt.println( "intersecting added 1" ) 
        } 

        // clear all the old paths when its a new turn
        if new_turn 
        {
          if len(data.player_chars[data.player_chars_current].paths_arr) > 0
          {
            for p in data.player_chars[data.player_chars_current].paths_arr
            { delete( p ) }
            clear( &data.player_chars[data.player_chars_current].paths_arr )
            // fmt.println( "paths_arr len:", len(data.player_chars[data.player_chars_current].paths_arr) )
          }
        }

        // if last turn, resize to 1 path in char.paths_arr
        if data.player_chars[data.player_chars_current].left_turns <= 0  
        {
          data.player_chars[data.player_chars_current].left_turns = 0

          // free all paths
          if len(data.player_chars[data.player_chars_current].paths_arr) > 0
          {
            for p in data.player_chars[data.player_chars_current].paths_arr
            { delete( p ) }
            clear( &data.player_chars[data.player_chars_current].paths_arr )
          }

          resize( &data.player_chars[data.player_chars_current].paths_arr, 1 ) 
          data.player_chars[data.player_chars_current].paths_arr[0] = make( [dynamic]waypoint_t, len(path), cap(path) )
          copy( data.player_chars[data.player_chars_current].paths_arr[0][:], path[:] )
        }
        else // if still have more turns, append next turn
        {
          data.player_chars[data.player_chars_current].left_turns -= 0 if intersecting_path else 1

          if intersecting_path
          {
            path[len(path) -1].combo_type = intersecting_combo_type // Combo_Type.JUMP 
            data.player_chars[data.player_chars_current].path_current_combo = intersecting_combo_type // Combo_Type.JUMP
          }
          else { data.player_chars[data.player_chars_current].path_current_combo = Combo_Type.NONE } // set for next turn

          append( &data.player_chars[data.player_chars_current].paths_arr, make( [dynamic]waypoint_t, len(path), cap(path) ) )
          idx := len(data.player_chars[data.player_chars_current].paths_arr) -1
          copy( data.player_chars[data.player_chars_current].paths_arr[idx][:], path[:] )
          // fmt.println( "paths_arr:", len(data.player_chars[data.player_chars_current].paths_arr) )
        }

        if intersecting_combo_type == Combo_Type.PUSH
        { 
          log.debug( "cock" ) 
        }

      }
    }
    // draw the path we pathfound(?), in character_t.color or red if failed 
    if path_found_err != Pathfind_Error.NOT_FOUND
    {
      switch path_type
      {
        case Combo_Type.NONE:
        { 
          assert( len( path ) >= 1 )
          debug_draw_path( path, path_found ? data.player_chars[data.player_chars_current].color : linalg.vec3{ 1, 0, 0 } ) 
        }
        case Combo_Type.JUMP:
        { 
          assert( len( path ) == 2 )
          debug_draw_curve_path( path[0], path[1], 15, path_found ? data.player_chars[data.player_chars_current].color : linalg.vec3{ 1, 0, 0 } ) 
        }
        case Combo_Type.PUSH:   fallthrough
        case Combo_Type.ATTACK: { log.panic( "should never get triggerred" ) } // ignore
      }
      // fmt.println( "found path len:", len(path)
    }
    // path was copied into character_t.paths_arr
    delete( path )

    // draw the tile hit by camera that we pathfound(?) to
    // debug_draw_aabb_wp( cam_hit_tile, path_found ? linalg.vec3{ 0, 1, 0 } : linalg.vec3{ 1, 0, 0 }, 15)
    debug_draw_aabb_wp( cam_hit_tile, path_found ? data.player_chars[data.player_chars_current].color : linalg.vec3{ 1, 0, 0 }, 15)
  }

  // @TMP: 
  // debug_draw_sphere( util_tile_to_pos( waypoint_t{ 1, 2, 2, Combo_Type.NONE } ), linalg.vec3{ 0.3, 0.3, 0.3 }, linalg.vec3{ 0, 1, 1 } )
  // debug_draw_sphere( util_tile_to_pos( waypoint_t{ 0, 2, 2, Combo_Type.NONE } ), linalg.vec3{ 0.3, 0.3, 0.3 }, linalg.vec3{ 1, 0, 0 } )
  // debug_draw_curve_path( data.player_chars[0].tile, waypoint_t{ 1, 2, 2, Combo_Type.NONE }, 20, linalg.vec3{ 1, 1, 1 } )

  for char, i in data.player_chars
  {
    data.entity_arr[char.entity_idx].rot.y += 15 * data.delta_t
    if i == data.player_chars_current
    {
      // debug_draw_sphere( util_tile_to_pos( char.tile ), linalg.vec3{ 0.5, 0.5, 0.5 }, linalg.vec3{ 0, 1, 1 } ) 
      // debug_draw_sphere( util_tile_to_pos( char.tile ) + linalg.vec3{ 0, 1, 0 }, linalg.vec3{ 0.35, 0.35, 0.35 }, linalg.vec3{ 0, 1, 0 } ) 
      debug_draw_sphere( util_tile_to_pos( char.tile ) + linalg.vec3{ 0, 1, 0 }, linalg.vec3{ 0.35, 0.35, 0.35 }, char.color ) 
    }
    // if char.has_path
    if len(char.paths_arr) > 0
    {
      // debug_draw_path( char.path, linalg.vec3{ 0, 1, 1 } )
      for p in char.paths_arr 
      { 
        switch p[0].combo_type
        {
          case Combo_Type.PUSH:
          {
            debug_draw_path( p, vec3{ 1, 1, 1 }, vec3{ 0, 1, 1 } ) 
            fallthrough
          }
          case Combo_Type.ATTACK: fallthrough // { log.panic( "should never get triggerred" ) } // ignore
          case Combo_Type.NONE:
          {
            debug_draw_path( p, char.color ) 
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

  for enemy, i in data.enemy_chars
  {
    // debug_draw_mesh( data.mesh_idxs.icon_attack, 
    //                  util_tile_to_pos( enemy.tile ) + linalg.vec3{ 0, 1, 0 },  // pos 
    //                  vec3{ 0, 0, 0 },        // rot
    //                  vec3{ 1, 1, 1 },  // scl
    //                  vec3{ 1, 0, 0 } )       // color
    // // debug_draw_sphere( util_tile_to_pos( enemy.tile ) + vec3{ 0, 1, 0 }, vec3{ 0.35, 0.35, 0.35 }, vec3{ 1, 0, 0 } )
  }
}

// game_check_jump_valid :: proc( char: character_t, start, end: waypoint_t ) -> ( path_arr: [dynamic]waypoint_t, ok: bool )
game_check_jump_valid :: proc( char: character_t, start, end: waypoint_t ) -> ( path_arr: [dynamic]waypoint_t, err: Pathfind_Error )
{
  ok := int(linalg.distance_vec2( linalg.vec2{ f32(start.x), f32(start.z) }, linalg.vec2{ f32(end.x), f32(end.z) } )) <= char.max_jump_dist
  // fmt.println( "len jump:", int(linalg.distance_vec2( linalg.vec2{ f32(start.x), f32(start.z) }, linalg.vec2{ f32(end.x), f32(end.z) } )), "max_jump_dist:", char.max_jump_dist )
  // { return nil, false }

  append( &path_arr, start )
  append( &path_arr, end)

  if start.level_idx == end.level_idx &&
     start.x         == end.x && 
     start.z         == end.z 
  { 
    return path_arr, Pathfind_Error.START_END_SAME_TILE
  }
  
  if !ok
  { 
    return path_arr, Pathfind_Error.TOO_LONG 
  }
  // return path_arr, true 
  return path_arr, Pathfind_Error.NONE
}

@(private="file") a_star_current_end : waypoint_t
@(private="file")
sort_proc :: proc( i, j: waypoint_t ) -> bool
{
  i_dist := linalg.distance( util_tile_to_pos( i ), util_tile_to_pos( a_star_current_end ) )
  j_dist := linalg.distance( util_tile_to_pos( j ), util_tile_to_pos( a_star_current_end ) )
  return i_dist < j_dist
}
@(private="file")
game_find_ramp_top :: proc( ramp: waypoint_t, ramp_type: Tile_Nav_Type ) -> ( ramp_top: waypoint_t, ok: bool )
{
  ok = true

  // find the tile the ramp spits u out on
  //    [0]
  // [1] X [2]
  //    [3]
  if ramp.z > 0 && 
     ramp_type == Tile_Nav_Type.RAMP_BACKWARD &&
     data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z -1] == Tile_Nav_Type.TRAVERSABLE
  { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x, z = ramp.z -1 } }
  else if ramp.x > 0 && 
          ramp_type == Tile_Nav_Type.RAMP_RIGHT &&
          data.tile_type_arr[ramp.level_idx][ramp.x -1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
  { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x -1, z = ramp.z } }
  else if ramp.x < TILE_ARR_X_MAX -1 && 
          ramp_type == Tile_Nav_Type.RAMP_LEFT &&
          data.tile_type_arr[ramp.level_idx][ramp.x +1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
  { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x +1, z = ramp.z } }
  else if ramp.z < TILE_ARR_Z_MAX -1 && 
          ramp_type == Tile_Nav_Type.RAMP_FORWARD &&
          data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z +1] == Tile_Nav_Type.TRAVERSABLE
  { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x, z = ramp.z +1 } }
  else if ramp.level_idx < TILE_LEVELS_MAX -1 
  { 
    /* fmt.eprintln( "[ERROR] didnt find ramp_top", i ); */ 
    ok = false 

    RAMP_SET :: bit_set[Tile_Nav_Type]{ Tile_Nav_Type.RAMP_FORWARD, Tile_Nav_Type.RAMP_BACKWARD, Tile_Nav_Type.RAMP_RIGHT, Tile_Nav_Type.RAMP_LEFT }

    if ramp.z > 0 && 
       ramp_type == Tile_Nav_Type.RAMP_BACKWARD &&
       data.tile_type_arr[ramp.level_idx +1][ramp.x][ramp.z -1] in RAMP_SET
    { 
      ramp_top = waypoint_t{ level_idx = ramp.level_idx +1, x = ramp.x, z = ramp.z -1 }
      return game_find_ramp_top( ramp_top, ramp_type )
    }
    else if ramp.x > 0 && 
            ramp_type == Tile_Nav_Type.RAMP_RIGHT &&
            data.tile_type_arr[ramp.level_idx +1][ramp.x -1][ramp.z] in RAMP_SET
    { 
      ramp_top = waypoint_t{ level_idx = ramp.level_idx +1, x = ramp.x -1, z = ramp.z } 
      return game_find_ramp_top( ramp_top, ramp_type )
    }
    else if ramp.x < TILE_ARR_X_MAX -1 && 
            ramp_type == Tile_Nav_Type.RAMP_LEFT &&
            data.tile_type_arr[ramp.level_idx +1][ramp.x +1][ramp.z] in RAMP_SET
    { 
      ramp_top = waypoint_t{ level_idx = ramp.level_idx +1, x = ramp.x +1, z = ramp.z } 
      return game_find_ramp_top( ramp_top, ramp_type )
    }
    else if ramp.z < TILE_ARR_Z_MAX -1 && 
            ramp_type == Tile_Nav_Type.RAMP_FORWARD &&
            data.tile_type_arr[ramp.level_idx +1][ramp.x][ramp.z +1] in RAMP_SET
    { 
      ramp_top = waypoint_t{ level_idx = ramp.level_idx +1, x = ramp.x, z = ramp.z +1 } 
      return game_find_ramp_top( ramp_top, ramp_type )
    }
  }
  else { ok = false }

  return ramp_top, ok
}
@(private="file")
game_find_ramp_bottom :: proc( ramp: waypoint_t, ramp_type: Tile_Nav_Type ) -> ( ramp_bottom: waypoint_t, ok: bool )
{
  ok = true

  // find the tile at the foot of the ramp
  //    [0]
  // [1] X [2]
  //    [3]
  if ramp.z > 0 && 
     ramp_type == Tile_Nav_Type.RAMP_FORWARD &&
     data.tile_type_arr[ramp.level_idx -1][ramp.x][ramp.z -1] == Tile_Nav_Type.TRAVERSABLE
  { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x, z = ramp.z -1 } }
  else if ramp.x > 0 && 
          ramp_type == Tile_Nav_Type.RAMP_LEFT &&
          data.tile_type_arr[ramp.level_idx -1][ramp.x -1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
  { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x -1, z = ramp.z } }
  else if ramp.x < TILE_ARR_X_MAX -1 && 
          ramp_type == Tile_Nav_Type.RAMP_RIGHT &&
          data.tile_type_arr[ramp.level_idx -1][ramp.x +1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
  { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x +1, z = ramp.z } }
  else if ramp.z < TILE_ARR_Z_MAX -1 && 
          ramp_type == Tile_Nav_Type.RAMP_BACKWARD &&
          data.tile_type_arr[ramp.level_idx -1][ramp.x][ramp.z +1] == Tile_Nav_Type.TRAVERSABLE
  { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x, z = ramp.z +1 } }
  else if ramp.level_idx > 0 
  { 
    ok = false 

    RAMP_SET :: bit_set[Tile_Nav_Type]{ Tile_Nav_Type.RAMP_FORWARD, Tile_Nav_Type.RAMP_BACKWARD, Tile_Nav_Type.RAMP_RIGHT, Tile_Nav_Type.RAMP_LEFT }

    if ramp.z > 0 && 
       ramp_type == Tile_Nav_Type.RAMP_FORWARD &&
       data.tile_type_arr[ramp.level_idx -1][ramp.x][ramp.z -1] in RAMP_SET
    { 
      ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x, z = ramp.z -1 }
      return game_find_ramp_bottom( ramp_bottom, ramp_type )
    }
    else if ramp.x > 0 && 
            ramp_type == Tile_Nav_Type.RAMP_LEFT &&
            data.tile_type_arr[ramp.level_idx -1][ramp.x -1][ramp.z] in RAMP_SET
    { 
      ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x -1, z = ramp.z } 
      return game_find_ramp_bottom( ramp_bottom, ramp_type )
    }
    else if ramp.x < TILE_ARR_X_MAX -1 && 
            ramp_type == Tile_Nav_Type.RAMP_RIGHT &&
            data.tile_type_arr[ramp.level_idx -1][ramp.x +1][ramp.z] in RAMP_SET
    { 
      ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x +1, z = ramp.z } 
      return game_find_ramp_bottom( ramp_bottom, ramp_type )
    }
    else if ramp.z < TILE_ARR_Z_MAX -1 && 
            ramp_type == Tile_Nav_Type.RAMP_BACKWARD &&
            data.tile_type_arr[ramp.level_idx -1][ramp.x][ramp.z +1] in RAMP_SET
    { 
      ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x, z = ramp.z +1 } 
      return game_find_ramp_bottom( ramp_bottom, ramp_type )
    }
  }
  else { /* fmt.eprintln( "[ERROR] didnt find ramp_bottom", i ); */ ok = false }

  return ramp_bottom, ok
}

// game_find_tile_hit_by_camera :: proc() -> ( hit_tile: waypoint_t, has_hit_tile: bool )
game_find_tile_hit_by_camera_space_pos :: proc( _pos: vec2 ) -> ( hit_tile: waypoint_t, has_hit_tile: bool )
{
  has_hit_tile = false
  hit_tile     = waypoint_t{ level_idx = 0, x = 0, z = 0, combo_type=Combo_Type.NONE }

  any_hits    := false
  closest_hit := linalg.vec3{ 10000000, 1000000, 1000000 }
  closest_hit_tile := waypoint_t{ 0, 0, 0, Combo_Type.NONE }
  for y := 0; y < len(data.tile_str_arr); y += 1
  {
    tile_str := data.tile_str_arr[y]
    for z := TILE_ARR_Z_MAX -1; z >= 0; z -= 1    // reversed so the str aligns with the created map
    {
      for x := TILE_ARR_X_MAX -1; x >= 0; x -= 1  // reversed so the str aligns with the created map
      {
        tile_str_idx := ( TILE_ARR_X_MAX * TILE_ARR_Z_MAX ) - ( x + (z*TILE_ARR_X_MAX) +1 ) // reversed idx so the str aligns with the created map

        if tile_str[tile_str_idx] == 'X'
        {
          pos := linalg.vec3{ 
                  f32(x) * 2 - f32(TILE_ARR_X_MAX) +1,
                  f32(y) * 2, 
                  f32(z) * 2 - f32(TILE_ARR_Z_MAX) +1
                 }

          min := pos + linalg.vec3{ -1, -1, -1 }
          max := pos + linalg.vec3{  1,  1,  1 }
          ray : ray_t
          ray.pos  = util_screen_to_world( data.cam.view_mat, data.cam.pers_mat, _pos, 0.0 )
          ray_end := util_screen_to_world( data.cam.view_mat, data.cam.pers_mat, _pos, 1.0 )
          // ray.dir = camera_get_front()
          // dir has to be skewed by cam fov
          ray.dir = ray_end - ray.pos
          // debug_draw_sphere( ray.pos + ray.dir, vec3{ 0.1, 0.1, 0.1 }, vec3{ 1, 0, 1 } )
          hit := util_ray_intersect_aabb( ray, min, max )
          if hit.hit
          {
            any_hits = true
            if linalg.distance( data.cam.pos, pos ) < linalg.distance( data.cam.pos, closest_hit )
            {
              closest_hit = pos
              closest_hit_tile = waypoint_t{ y, x, z, Combo_Type.NONE }
            }
            // debug_draw_aabb( min, max, 
            //                  hit.hit ? linalg.vec3{ 1, 0, 1 } : linalg.vec3{ 1, 1, 1 }, 
            //                  hit.hit ? 15 : 5 )
          }
        }
      }
    }
  }
  if any_hits
  { 
    // // draw red target indicator line
    // debug_draw_line( closest_hit + linalg.vec3{ 0, 0.5, 0 }, closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 1, 0, 0 }, 10 ) 
    // // // draw blue line from character
    // // debug_draw_line( data.entity_arr[0].pos + linalg.vec3{ 0, 0, 0 }, closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 0.6, 0.8, 1 }, 10 )
    // 
    // debug_draw_sphere( closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 0.2, 0.2, 0.2 }, linalg.vec3{ 0.6, 0.8, 1 } )

    hit_tile     = closest_hit_tile
    has_hit_tile = true
  }
  
  return hit_tile, has_hit_tile
}

// checks for a ramp up or down in the given Dir from waypoint current
// game_a_star_02_check_for_ramp :: #force_inline proc( current: waypoint_t, type: Dir ) -> ( next_point: waypoint_t, ok: bool )
game_a_star_02_check_for_ramp :: #force_inline proc( current: waypoint_t, type: Dir ) -> ( next_point: waypoint_t, ok: bool )
{

  up_type, down_type : Tile_Nav_Type
  x_offs, z_offs : int
  condition: bool

  switch type
  {
    case Dir.FORWARD:
    {
      up_type   = Tile_Nav_Type.RAMP_FORWARD
      down_type = Tile_Nav_Type.RAMP_BACKWARD
      x_offs    = 0
      z_offs    = 1
      condition = current.z < TILE_ARR_Z_MAX -1
    }
    case Dir.BACKWARDS:
    {
      up_type   = Tile_Nav_Type.RAMP_BACKWARD
      down_type = Tile_Nav_Type.RAMP_FORWARD
      x_offs    = 0
      z_offs    = -1
      condition = current.z > 0
    }
    case Dir.LEFT:
    {
      up_type   = Tile_Nav_Type.RAMP_LEFT
      down_type = Tile_Nav_Type.RAMP_RIGHT
      x_offs    = 1
      z_offs    = 0
      condition = current.x < TILE_ARR_X_MAX -1
    }
    case Dir.RIGHT:
    {
      up_type   = Tile_Nav_Type.RAMP_RIGHT
      down_type = Tile_Nav_Type.RAMP_LEFT
      x_offs    = -1
      z_offs    = 0
      condition = current.x > 0
    }
  }
  if !condition { return waypoint_t{}, false }

  if current.level_idx < TILE_LEVELS_MAX -1 && 
     data.tile_type_arr[current.level_idx +1][current.x + x_offs][current.z + z_offs] == up_type 
  {
    ramp := waypoint_t{ level_idx = current.level_idx +1, x = current.x + x_offs, z = current.z + z_offs }
    next_point, ok = game_find_ramp_top( ramp, data.tile_type_arr[current.level_idx +1][current.x + x_offs][current.z + z_offs] )
  }
  else if data.tile_type_arr[current.level_idx][current.x + x_offs][current.z + z_offs] == down_type
  {
    ramp := waypoint_t{ level_idx = current.level_idx, x = current.x + x_offs, z = current.z + z_offs }
    next_point, ok = game_find_ramp_bottom( ramp, data.tile_type_arr[current.level_idx][current.x + x_offs][current.z + z_offs] )
  }
  else
  { ok = false }

  // if ok 
  // { 
  //   debug_draw_aabb_wp( current,    linalg.vec3{ 1, 1, 1 }, 30 ) 
  //   debug_draw_aabb_wp( next_point, linalg.vec3{ 1, 1, 1 }, 30 ) 
  // }
  return next_point, ok
}
game_a_star_02_f_cost :: #force_inline proc( wp, end: waypoint_t ) -> ( f_cost: f32 )
{
  // @TODO: isnt f_cost more complext than dist ???
  f_cost = linalg.distance( util_tile_to_pos( wp ), util_tile_to_pos( end ) )
  f_cost += 2 if wp.level_idx != end.level_idx else 0
  return f_cost
}
game_a_star_02_pathfind :: proc( _start, _end: waypoint_t ) -> ( path_arr: [dynamic]waypoint_t, err: Pathfind_Error, ok: bool  )
{
  ok = false
  err = Pathfind_Error.NOT_FOUND

  open_arr   : [dynamic]node_t
  closed_arr : [dynamic]node_t

  // @NOTE: idk if this is actually a smart idea 
  start := node_t{ wp=_start, f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  end   := node_t{ wp=_end,   f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  // end   := node_t{ wp=_start, f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  // start := node_t{ wp=_end,   f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  start_cur_path := start

  // start == end
  if start.wp.level_idx == end.wp.level_idx &&
     start.wp.z         == end.wp.z         &&
     start.wp.x         == end.wp.x
  { 
    append( &path_arr, _start )
    return path_arr, Pathfind_Error.NONE, true 
  }

  append( &open_arr, start )

  end_pos := util_tile_to_pos( end.wp )

  current        := node_t{ wp=waypoint_t{ level_idx=0, x=0, z=0 }, f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  current_pos    := util_tile_to_pos( current.wp )
  current_f_cost : f32 = 999999999999999999.9 
  current_idx    := 0

  next_points                : [4]node_t // waypoint_t
  next_points_viable         : [4]bool

  tries := 0
  for tries < TILE_ARR_Z_MAX * TILE_ARR_X_MAX 
  {
    // set current to tile with shortest dist to end
    current_f_cost = 999999999999999999.9 
    for &w, i in open_arr
    {
      w_pos   := util_tile_to_pos( w.wp )
      w.f_cost = game_a_star_02_f_cost( w.wp, end.wp )
      if w.f_cost < current_f_cost
      {
        // w.parent       = current
        // w.parent_idx   = len(closed_arr) -1
        current        = w
        current_pos    = w_pos // util_tile_to_pos( current.wp )
        current_f_cost = w.f_cost // linalg.distance( current_pos, end_pos )
        current_idx    = i
      }
    }
    // remove current from open and add to closed
    if current_idx >= len(open_arr) 
    { delete( open_arr ); delete( closed_arr ); delete( path_arr ); return nil, Pathfind_Error.NOT_FOUND, false }
    assert( current_idx < len(open_arr) )
    ordered_remove( &open_arr, current_idx )
    append( &closed_arr, current )

    // found path
    if current.wp.level_idx == end.wp.level_idx &&
       current.wp.z         == end.wp.z         &&
       current.wp.x         == end.wp.x
    {
      // return path, true 
      ok = true
      err = Pathfind_Error.NONE 
      break
    }

    // go through the neighbouring nodes
    next_points_viable = { true, true, true, true }
    for &p in next_points
    {
        p = node_t{}
    }
    //    [0]
    // [1] X [2]
    //    [3]
    // front
    if current.wp.z > 0 && data.tile_type_arr[current.wp.level_idx][current.wp.x][current.wp.z -1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[0].wp  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x, z = current.wp.z -1 } }
    else
    { 
      next_points[0].wp, next_points_viable[0] = game_a_star_02_check_for_ramp( current.wp, Dir.BACKWARDS )
      next_points[0].ramp_connector = Dir.BACKWARDS
    }
    // left
    if current.wp.x > 0 && data.tile_type_arr[current.wp.level_idx][current.wp.x -1][current.wp.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[1].wp  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x -1, z = current.wp.z } }
    else
    { 
      next_points[1].wp, next_points_viable[1] = game_a_star_02_check_for_ramp( current.wp, Dir.RIGHT )
      next_points[1].ramp_connector = Dir.RIGHT
    }
    // right
    if current.wp.x < TILE_ARR_X_MAX -1 && data.tile_type_arr[current.wp.level_idx][current.wp.x +1][current.wp.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[2].wp  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x +1, z = current.wp.z } }
    else
    { 
      next_points[2].wp, next_points_viable[2] = game_a_star_02_check_for_ramp( current.wp, Dir.LEFT )
      next_points[2].ramp_connector = Dir.LEFT
    }
    // back 
    if current.wp.z < TILE_ARR_Z_MAX -1 && data.tile_type_arr[current.wp.level_idx][current.wp.x][current.wp.z +1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[3].wp  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x, z = current.wp.z +1 } }
    else
    { 
      next_points[3].wp, next_points_viable[3] = game_a_star_02_check_for_ramp( current.wp, Dir.FORWARD )
      next_points[3].ramp_connector = Dir.FORWARD
    }

    for i in 0 ..< len( next_points )
    {
      if !next_points_viable[i] { continue }

      // check if in closed_arr
      is_in_arr := false
      closed_arr_idx := -1
      // @TODO: @OPTIMIZATION: this scuffed as hell
      for n, idx in  closed_arr
      {
        if n.wp == next_points[i].wp
        { is_in_arr = true; closed_arr_idx = idx; break }
      }
      if is_in_arr { continue }

      // check if in open_arr
      is_in_arr = false
      for n in open_arr
      {
        if n.wp == next_points[i].wp
        { is_in_arr = true; break }
      }
      if is_in_arr { continue }

      neighbour       := next_points[i]
      neighbour.f_cost = game_a_star_02_f_cost( next_points[i].wp, end.wp )
      neighbour.parent = current.wp
      neighbour.ramp_connector = next_points[i].ramp_connector
               
      append( &open_arr, neighbour )
    }

    tries += 1
  }

  if !ok 
  { 
    delete( open_arr )
    delete( closed_arr )
    delete( path_arr )
    return nil, Pathfind_Error.NOT_FOUND, false 
  }

  // current is the end node
  append( &path_arr, current.wp )
  // go through parent until hit start node
  for ( current.wp.level_idx != start_cur_path.wp.level_idx || 
        current.wp.z         != start_cur_path.wp.z         || 
        current.wp.x         != start_cur_path.wp.x )
  {
    // log.debug( "for current != start", time.now() )
    // @TODO: @OPTIMIZATION: this scuffed as hell
    // find current.parent
    found := false
    for n in closed_arr
    {
      if n.wp.level_idx == current.parent.level_idx &&
         n.wp.z         == current.parent.z         &&
         n.wp.x         == current.parent.x
      {
        current = n
        found = true
        break
      }
    }
    tries += 1
    // @TMP:
    if !found
    {
      log.error( "didnt find parrent of current" )
      fmt.println( "current:", current.wp, "parent:", current.parent )
      for n, i in closed_arr { fmt.println( "closed_arr[", i ,"]:", n.wp, "parent:", n.parent ) }
      assert( found )
    }

    
    append( &path_arr, current.wp )

    // if ramp_connector do rest again individually
    if current.ramp_connector != nil
    {
      next_path, error, succsess := game_a_star_02_pathfind( current.parent, _start )
      
      if !succsess
      {
        delete( open_arr )
        delete( closed_arr )
        delete( path_arr )
        return nil, error, false
      }

      if error == Pathfind_Error.PATH_NEEDS_TO_BE_REVERSED
      { slice.reverse( next_path[:] ) }

      append( &path_arr, ..next_path[:] )

      // @TODO: @BUGG: game_a_star_02_pathfind() returns path reversed, cant do it in the proc leads to buggs for some reason
      // should reverse here but leads to buggs
      // slice.reverse( path_arr[:] )

      delete( next_path )
      delete( open_arr )
      delete( closed_arr )

      return path_arr, Pathfind_Error.PATH_NEEDS_TO_BE_REVERSED, true
    }
  }

  // @NOTE: technically could just switch start and end
  //        but it gives bad results
  // reverse path_arr
  slice.reverse( path_arr[:] )
  
  delete( open_arr )
  delete( closed_arr )

  return path_arr, Pathfind_Error.NONE, true
}
/* /// @TMP: 
game_a_star_02_pathfind_old :: proc( _start, _end: waypoint_t ) -> ( path_arr: [dynamic]waypoint_t, err: Pathfind_Error, ok: bool  )
{
  ok = false
  err = Pathfind_Error.NOT_FOUND

  open_arr   : [dynamic]node_t
  closed_arr : [dynamic]node_t

  start := node_t{ wp=_start, f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  end   := node_t{ wp=_end,   f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }

  // start == end
  if start.wp.level_idx == end.wp.level_idx &&
     start.wp.z         == end.wp.z         &&
     start.wp.x         == end.wp.x
  { 
    append( &path_arr, _start )
    // return path_arr, Pathfind_Error.NONE 
    return path_arr, Pathfind_Error.NONE, true 
  }

  append( &open_arr, start )

  end_pos := util_tile_to_pos( end.wp )

  current        := node_t{ wp=waypoint_t{ level_idx=0, x=0, z=0 }, f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  current_pos    := util_tile_to_pos( current.wp )
  current_f_cost : f32 = 999999999999999999.9 // game_a_star_f_cost( current.wp, end.wp ) // linalg.distance( current_pos, end_pos )
  current_idx    := 0

  next_points        : [4]waypoint_t
  next_points_viable : [4]bool

  tries := 0
  for tries < TILE_ARR_Z_MAX * TILE_ARR_X_MAX 
  {
    // set current to tile with shortest dist to end
    current_f_cost = 999999999999999999.9 
    for &w, i in open_arr
    {
      w_pos   := util_tile_to_pos( w.wp )
      w.f_cost = game_a_star_02_f_cost( w.wp, end.wp )
      if w.f_cost < current_f_cost
      {
        // w.parent       = current
        // w.parent_idx   = len(closed_arr) -1
        current        = w
        current_pos    = w_pos // util_tile_to_pos( current.wp )
        current_f_cost = w.f_cost // linalg.distance( current_pos, end_pos )
        current_idx    = i
      }
    }
    // remove current from open and add to closed
    // if current_idx >= len(open_arr) { return path_arr, Pathfind_Error.NOT_FOUND }
    if current_idx >= len(open_arr) 
    { delete( open_arr ); delete( closed_arr ); delete( path_arr ); return nil, Pathfind_Error.NOT_FOUND, false }
    assert( current_idx < len(open_arr) )
    ordered_remove( &open_arr, current_idx )
    append( &closed_arr, current )

    // found path
    // if current == end 
    if current.wp.level_idx == end.wp.level_idx &&
       current.wp.z         == end.wp.z         &&
       current.wp.x         == end.wp.x
    {
      // return path, true 
      ok = true
      err = Pathfind_Error.NONE 
      break
    }

    // go through the neighbouring nodes
    next_points_viable = { true, true, true, true }
    //    [0]
    // [1] X [2]
    //    [3]
    // front
    if current.wp.z > 0 && data.tile_type_arr[current.wp.level_idx][current.wp.x][current.wp.z -1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[0]  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x, z = current.wp.z -1 } }
    else
    { 
      next_points[0], next_points_viable[0] = game_a_star_02_check_for_ramp( current.wp, Dir.BACKWARDS )
    }
    // left
    if current.wp.x > 0 && data.tile_type_arr[current.wp.level_idx][current.wp.x -1][current.wp.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[1]  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x -1, z = current.wp.z } }
    else
    { 
      next_points[1], next_points_viable[1] = game_a_star_02_check_for_ramp( current.wp, Dir.RIGHT )
    }
    // right
    if current.wp.x < TILE_ARR_X_MAX -1 && data.tile_type_arr[current.wp.level_idx][current.wp.x +1][current.wp.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[2]  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x +1, z = current.wp.z } }
    else
    { 
      next_points[2], next_points_viable[2] = game_a_star_02_check_for_ramp( current.wp, Dir.LEFT )
    }
    // back 
    if current.wp.z < TILE_ARR_Z_MAX -1 && data.tile_type_arr[current.wp.level_idx][current.wp.x][current.wp.z +1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[3]  = waypoint_t{ level_idx = current.wp.level_idx, x = current.wp.x, z = current.wp.z +1 } }
    else
    { 
      next_points[3], next_points_viable[3] = game_a_star_02_check_for_ramp( current.wp, Dir.FORWARD )
    }

    // at_least_one_viable := false
    for i in 0 ..< len( next_points )
    {
      if !next_points_viable[i] { continue }

      // check if in closed_arr
      is_in_arr := false
      closed_arr_idx := -1
      // @TODO: @OPTIMIZATION: this scuffed as hell
      for n, idx in  closed_arr
      {
        if n.wp == next_points[i]
        { is_in_arr = true; closed_arr_idx = idx; break }
      }
      if is_in_arr { continue }

      // check if in open_arr
      is_in_arr = false
      for n in  open_arr
      {
        if n.wp == next_points[i]
        { is_in_arr = true; break }
      }
      if is_in_arr { continue }

      neighbour := node_t{ wp=next_points[i], 
                           f_cost=game_a_star_02_f_cost( next_points[i], end.wp ), 
                           parent=current.wp, 
                           // parent_idx=closed_arr_idx 
                         }
      append( &open_arr, neighbour )

      // at_least_one_viable = true
    }

    tries += 1
  }

  if !ok 
  { 
    delete( open_arr )
    delete( closed_arr )
    delete( path_arr )
    // return nil, false 
    // return nil, Pathfind_Error.NOT_FOUND, false 
    return nil, Pathfind_Error.NOT_FOUND, false 
  }
  // if err != Pathfind_Error.NONE { return nil, err }

  // for n, i in closed_arr
  // {
  //   // log.info( i, "|", n )
  //   log.info( i, "|", n.wp )
  //   // log.info( i )
  // }

  // current is the end node
  append( &path_arr, current.wp )
  // fmt.println( "start:", start )
  // fmt.println( "end:", end )
  // fmt.println( "current:", current )
  // go through parent until hit start node
  for current.wp.level_idx != start.wp.level_idx || 
      current.wp.z         != start.wp.z         || 
      current.wp.x         != start.wp.x
  {
    // @TODO: @OPTIMIZATION: this scuffed as hell
    // find current.parent
    found := false
    for n in closed_arr
    {
      if n.wp.level_idx == current.parent.level_idx &&
         n.wp.z         == current.parent.z         &&
         n.wp.x         == current.parent.x
      {
        current = n
        found = true
        break
      }
    }
    assert( found )
    // idx := current.parent_idx
    // assert( idx >= 0 )
    // assert( idx < len(closed_arr) )
    // current = closed_arr[idx]
    log.info( "current.parent:", current.parent )
    append( &path_arr, current.wp )
  }
  // assert( 0 == 1 )
  // reverse path_arr
  slice.reverse( path_arr[:] )
  
  delete( open_arr )
  delete( closed_arr )

  return path_arr, Pathfind_Error.NONE, true
}
*/
