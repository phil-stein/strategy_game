package core 

import        "core:fmt"
import        "core:log"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "core:slice"


game_update :: proc()
{

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


  cam_hit_tile, has_cam_hit_tile := game_find_tile_hit_by_camera()
  if has_cam_hit_tile && data.player_chars_current >= 0
  {
    new_turn := true
    start := data.player_chars[data.player_chars_current].tile
    // if !data.player_chars[data.player_chars_current].path_finished &&
    //    len(data.player_chars[data.player_chars_current].paths_arr) > 0
    if data.player_chars[data.player_chars_current].left_turns > 0 &&
       len(data.player_chars[data.player_chars_current].paths_arr) > 0
    {
      new_turn = false
      idx00 := len(data.player_chars[data.player_chars_current].paths_arr) -1
      idx01 := len(data.player_chars[data.player_chars_current].paths_arr[idx00]) -1
      start = data.player_chars[data.player_chars_current].paths_arr[idx00][idx01]
    }

    // start_pos := util_tile_to_pos(data.player_chars[data.player_chars_current].tile )
    // start_pos.y += 1.0
    // debug_draw_sphere( start_pos, linalg.vec3{ 0.35, 0.35, 0.35 }, linalg.vec3{ 0, 1, 0 } )
    
    path           : [dynamic]waypoint_t = nil
    path_found     := false
    path_found_err := Pathfind_Error.NONE
    path_type      := Combo_Type.NONE

    switch data.player_chars[data.player_chars_current].path_current_combo
    {
      case Combo_Type.NONE:
      {
        // path, path_found = game_a_star_pathfind_levels( start, cam_hit_tile )
        path, path_found_err, path_found = game_a_star_02_pathfind( start, cam_hit_tile )
        // fmt.println( "path_found:", path_found, "len(path):", len(path) )
        if !path_found 
        { path_found_err = Pathfind_Error.NOT_FOUND }
        else if len(path) > data.player_chars[data.player_chars_current].max_walk_dist
        { path_found_err = Pathfind_Error.TOO_LONG; path_found = false }
        if start.level_idx == cam_hit_tile.level_idx &&
           start.x         == cam_hit_tile.x && 
           start.z         == cam_hit_tile.z 
        { path_found_err = Pathfind_Error.START_END_SAME_TILE; path_found = false }

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
    


    if path_found
    { 
      intersecting_path       := false
      intersecting_char_idx   := -1
      intersecting_wp_idx     := -1
      intersecting_combo_type := Combo_Type.NONE
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
                  intersecting_wp_idx   = wp_idx
                  // @TODO: add more types, like landing on enemy head and tackling them
                  intersecting_combo_type = Combo_Type.JUMP
                  // @TODO: make like a debug_draw_debug_icon() proc
                  debug_draw_sphere( util_tile_to_pos( w ) + linalg.vec3{ 0, 1, 0 }, linalg.vec3{ 0.35, 0.35, 0.35 }, char.color )
                }
              }
            }
          }
        }
      // }

      if input.mouse_button_states[Mouse_Button.LEFT].pressed && input.mouse_button_states[Mouse_Button.RIGHT].down && path_found
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
          data.player_chars[data.player_chars_current].left_turns    = 0

          // free all paths
          if len(data.player_chars[data.player_chars_current].paths_arr) > 0
          {
            for p in data.player_chars[data.player_chars_current].paths_arr
            { delete( p ) }
            clear( &data.player_chars[data.player_chars_current].paths_arr )
            // fmt.println( "paths_arr len:", len(data.player_chars[data.player_chars_current].paths_arr) )
          }

          resize( &data.player_chars[data.player_chars_current].paths_arr, 1 ) 
          // fmt.println( "paths_arr len:", len(data.player_chars[data.player_chars_current].paths_arr) )
          data.player_chars[data.player_chars_current].paths_arr[0] = make( [dynamic]waypoint_t, len(path), cap(path) )
          copy( data.player_chars[data.player_chars_current].paths_arr[0][:], path[:] )

          // // delete( data.player_chars[data.player_chars_current].paths_arr )
          // // data.player_chars[data.player_chars_current].paths_arr = make( [dynamic][dynamic]waypoint_t, 1 )
          // clear( &data.player_chars[data.player_chars_current].paths_arr )
          // append( &data.player_chars[data.player_chars_current].paths_arr, path )

          // fmt.println( "old path:", len(data.player_chars[data.player_chars_current].path), len(path) )
        }
        else // if still have more turns, append next turn
        {
          data.player_chars[data.player_chars_current].left_turns -= 0 if intersecting_path else 1

          if intersecting_path
          {
            path[len(path) -1].combo_type = Combo_Type.JUMP 
            data.player_chars[data.player_chars_current].path_current_combo = Combo_Type.JUMP
          }
          else { data.player_chars[data.player_chars_current].path_current_combo = Combo_Type.NONE } // set for next turn

          append( &data.player_chars[data.player_chars_current].paths_arr, make( [dynamic]waypoint_t, len(path), cap(path) ) )
          idx := len(data.player_chars[data.player_chars_current].paths_arr) -1
          copy( data.player_chars[data.player_chars_current].paths_arr[idx][:], path[:] )
          // fmt.println( "paths_arr:", len(data.player_chars[data.player_chars_current].paths_arr) )
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
          // debug_draw_path( path, path_found ? linalg.vec3{ 0, 1, 0 } : linalg.vec3{ 1, 0, 0 } ) 
          debug_draw_path( path, path_found ? data.player_chars[data.player_chars_current].color : linalg.vec3{ 1, 0, 0 } ) 
        }
        case Combo_Type.JUMP:
        { 
          assert( len( path ) == 2 )
          debug_draw_curve_path( path[0], path[1], 15, path_found ? data.player_chars[data.player_chars_current].color : linalg.vec3{ 1, 0, 0 } ) 
        }
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
          case Combo_Type.NONE:
          {
            // debug_draw_path( p, linalg.vec3{ 0, 1, 1 } ) 
            debug_draw_path( p, char.color ) 
          }
          case Combo_Type.JUMP:
          {
            // debug_draw_curve_path( p[0], p[len(p) -1], 20, linalg.vec3{ 1, 1, 1 } )
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

@(deprecated="use game_a_star_pathfind() or game_a_start_pathfind_levels() instead")
game_simple_pathfind :: proc( start, end: waypoint_t ) -> ( path: [dynamic]waypoint_t, ok: bool  )
{
  current : waypoint_t = start
  append( &path, start )

  next_points        : [4]waypoint_t
  next_points_viable : [4]bool

  tries := 0

  for current != end && tries < 100
  {
    next_points_viable = { true, true, true, true }

    //    [0]
    // [1] X [2]
    //    [3]

    if current.z > 0 && data.tile_type_arr[0][current.x][current.z -1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[0]  = waypoint_t{ level_idx = 0, x = current.x, z = current.z -1 } }
    else
    { next_points_viable[0] = false }

    if current.x > 0 && data.tile_type_arr[0][current.x -1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[1]  = waypoint_t{ level_idx = 0, x = current.x -1, z = current.z } }
    else
    { next_points_viable[1] = false }

    if current.x < TILE_ARR_X_MAX -1 && data.tile_type_arr[0][current.x +1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[2]  = waypoint_t{ level_idx = 0, x = current.x +1, z = current.z } }
    else
    { next_points_viable[2] = false }

    if current.z < TILE_ARR_Z_MAX -1 && data.tile_type_arr[0][current.x][current.z +1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[3]  = waypoint_t{ level_idx = 0, x = current.x, z = current.z +1 } }
    else
    { next_points_viable[3] = false }

    end_point := linalg.vec2{ f32(end.x), f32(end.z) }
    shortest_next_point : int = 0
    last_dist           : f32 = 999999999999999999999999.0
    for i in 0 ..< len(next_points)
    {
      if !next_points_viable[i] { continue }

      point := linalg.vec2{ f32(next_points[i].x), f32(next_points[i].z) }
      dist  := linalg.distance( point, end_point )
      if dist < last_dist
      {
        shortest_next_point = i
        last_dist           = dist
      }
    }

    one_viable := false
    for i in 0 ..< len(next_points_viable)
    { one_viable |= next_points_viable[i] } 
    if one_viable
    {
      assert( shortest_next_point < len(next_points) && shortest_next_point >= 0 )
      current = next_points[shortest_next_point]
      append( &path, next_points[shortest_next_point] )
    }
    else { return path, false }


    tries += 1
  }
  
  return path, current == end
}

node_t :: struct
{
  using wp: waypoint_t,
  // wp        : waypoint_t,

  // a*
  f_cost     : f32,
  parent     : waypoint_t,
  parent_idx : int,
}
// @TODO: use all levels
// based on: https://www.youtube.com/watch?v=-L-WgKMFuhE&list=PLFt_AvWsXl0cq5Umv3pMC9SPnKjfp9eGW&index=2
// @(deprecated="use game_a_star_02_f_cost() instead")
game_a_star_f_cost :: #force_inline proc( wp, end: waypoint_t, loc:=#caller_location ) -> ( f_cost: f32 )
{
  log.warn( "use game_a_star_02_f_cost() instead, called from:", loc )
  // @TODO: isnt f_cost more complext than dist ???
  return linalg.distance( util_tile_to_pos( wp ), util_tile_to_pos( end ) )
}
// game_a_star_pathfind :: proc( _start, _end: waypoint_t ) -> ( path_arr: [dynamic]waypoint_t, ok: bool  )
// @(deprecated="use game_a_star_02_pathfind() instead")
game_a_star_pathfind :: proc( _start, _end: waypoint_t, loc:=#caller_location ) -> ( path_arr: [dynamic]waypoint_t, err: Pathfind_Error, ok: bool  )
{
  log.warn( "use game_a_star_02_pathfind() instead, called from:", loc )
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
      w_pos := util_tile_to_pos( w.wp )
      w.f_cost = game_a_star_f_cost( w.wp, end.wp )
      if w.f_cost < current_f_cost
      {
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
    if current.z > 0 && data.tile_type_arr[current.level_idx][current.x][current.z -1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[0]  = waypoint_t{ level_idx = current.level_idx, x = current.x, z = current.z -1 } }
    else
    { next_points_viable[0] = false }
    // left
    if current.x > 0 && data.tile_type_arr[current.level_idx][current.x -1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[1]  = waypoint_t{ level_idx = current.level_idx, x = current.x -1, z = current.z } }
    else
    { next_points_viable[1] = false }
    // right
    if current.x < TILE_ARR_X_MAX -1 && data.tile_type_arr[current.level_idx][current.x +1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[2]  = waypoint_t{ level_idx = current.level_idx, x = current.x +1, z = current.z } }
    else
    { next_points_viable[2] = false }
    // back 
    if current.z < TILE_ARR_Z_MAX -1 && data.tile_type_arr[current.level_idx][current.x][current.z +1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[3]  = waypoint_t{ level_idx = current.level_idx, x = current.x, z = current.z +1 } }
    else
    { next_points_viable[3] = false }

    // at_least_one_viable := false
    for i in 0 ..< len( next_points )
    {
      if !next_points_viable[i] { continue }

      // check if in closed_arr
      is_in_arr := false
      for n in  closed_arr
      {
        if n.wp == next_points[i]
        { is_in_arr = true; break }
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
                           f_cost=game_a_star_f_cost( next_points[i], end.wp ), 
                           parent=current.wp 
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
    return nil, Pathfind_Error.NOT_REACHABLE_VIA_GAME_A_STAR_PATHFIND, false 
  }
  // if err != Pathfind_Error.NONE { return nil, err }

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
    append( &path_arr, current.wp )
  }
  // reverse path_arr
  slice.reverse( path_arr[:] )
  
  delete( open_arr )
  delete( closed_arr )

  return path_arr, Pathfind_Error.NONE, true

}
// use mutliple levels:
//  1. a* to ramps (in order of dist to goal)
//  2. a* to goal
//  3. repeat for all ramps until one works both tims
//  4. stich together the two paths

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
  else { /* fmt.eprintln( "[ERROR] didnt find ramp_top", i ); */ ok = false }

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
  else { /* fmt.eprintln( "[ERROR] didnt find ramp_bottom", i ); */ ok = false }

  return ramp_bottom, ok
}
@(deprecated="use game_a_star_02_pathfind() instead")
game_a_star_pathfind_levels :: proc( start, end: waypoint_t, loc:=#caller_location ) -> ( path_arr: [dynamic]waypoint_t, ok: bool  )
{
  log.warn( "use game_a_star_02_pathfind() instead, called from:", loc )
  err : Pathfind_Error
  // floodfill to check if same level and can be reached without going on ramps
  if start.level_idx == end.level_idx 
  { 
    path_arr, err, ok = game_a_star_pathfind( start, end ) 
    return path_arr, ok
    // path_arr, err, ok = game_a_star_pathfind( start, end ) 
    // if ok
    // { return path_arr, ok }
    // else if err != Pathfind_Error.NOT_REACHABLE_VIA_GAME_A_STAR_PATHFIND
    // { return nil, false }
  }
  

  // sort ramps by dist to goal
  // sorted_ramp_idx_arr := make( []int, len( data.tile_ramp_entity_id_arr[end.level_idx] ) )
  // defer delete( sorted_ramp_idx_arr )
  // for ramp_idx in data.tile_ramp_entity_id_arr
  // {
  // }
  a_star_current_end = end
  sorted_ramp_arr : []waypoint_t
  if start.level_idx < end.level_idx
  { sorted_ramp_arr = data.tile_ramp_wp_arr[end.level_idx][:] }
  else
  { sorted_ramp_arr = data.tile_ramp_wp_arr[start.level_idx][:] }
  // fmt.println( "data.tile_ramp_wp_arr[end.level_idx] len ->", len(data.tile_ramp_wp_arr[end.level_idx]) )
  // fmt.println( "data.tile_ramp_wp_arr[end.level_idx][:] len ->", len(data.tile_ramp_wp_arr[end.level_idx][:]) )
  // fmt.println( "sorted_ramp_arr len ->", len(sorted_ramp_arr) )
  slice.sort_by( sorted_ramp_arr, sort_proc )

  // // @TMP:
  // for w, i in sorted_ramp_arr
  // {
  //   // fmt.println( w )
  //   c : f32 = f32(i +1) / f32( len( sorted_ramp_arr ) )
  //   // debug_draw_aabb_wp( w, linalg.vec3{ 1, 1, 1 }, 10 )
  //   // debug_draw_aabb_wp( w, linalg.vec3{ c, c, c }, 10 )

  //   ramp := w
  //   ramp_type := data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z]
  //   ramp_top : waypoint_t
  //   ramp_bottom : waypoint_t
  // }
  // // if 1 == 1 { return nil, false }

  end_path : [dynamic]waypoint_t
  defer delete( end_path )
  start_path : [dynamic]waypoint_t
  defer delete( start_path )
  ramp_top    : waypoint_t
  ramp_bottom : waypoint_t
  ramp_path_found := false
  for ramp, i in sorted_ramp_arr 
  {
    ramp_type := data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z]
    // fmt.println( i, " -> ", ramp_type )
    // find the tile the ramp spits u out on
    //    [0]
    // [1] X [2]
    //    [3]
    found_top : bool
    if start.level_idx < end.level_idx
    { ramp_top, found_top = game_find_ramp_top( ramp, ramp_type ) }
    else
    { ramp_top, found_top = game_find_ramp_bottom( ramp, ramp_type ) }
    if !found_top { continue }
    // debug_draw_aabb_wp( ramp_top, linalg.vec3{ 1, 1, 1 }, 20 )

    // fmt.println( "found ramp_top:", ramp_top )
    // debug_draw_aabb_wp( ramp_top, linalg.vec3{ 1, 1, 0 }, 10 )

    // a* from ramps to goal 
    end_path, err, ok = game_a_star_pathfind( ramp_top, end )
    if !ok { /* fmt.eprintln( "[ERROR] didnt find end_path", i ); */ continue }
    // debug_draw_path( end_path, linalg.vec3{ 1, 1, 1 } )

    // find the tile at the foot of the ramp
    //    [0]
    // [1] X [2]
    //    [3]
    found_bottom : bool
    if start.level_idx < end.level_idx
    { ramp_bottom, found_bottom = game_find_ramp_bottom( ramp, ramp_type ) }
    else 
    { ramp_bottom, found_bottom = game_find_ramp_top( ramp, ramp_type ) }
    if !found_bottom { continue }
    // debug_draw_aabb_wp( ramp_top, linalg.vec3{ 0, 0, 0 }, 10 )

    // fmt.println( "found ramp_bottom:", ramp_bottom )
    // debug_draw_aabb_wp( ramp_bottom, linalg.vec3{ 1, 0, 1 }, 10 )
    
    // a* from start to ramp
    start_path, err, ok = game_a_star_pathfind( start, ramp_bottom )

    if !ok { /* fmt.eprintln( "[ERROR] didnt find start_path", i ); */ continue }
    // debug_draw_path( start_path, linalg.vec3{ 0, 0, 0 } )
    if ok { ramp_path_found = true; break }
  }
  if !ramp_path_found { /* fmt.eprintln( "[ERROR] no ramp path found" ); */ return nil, false }

  // stich start_path and end_path into path_arr
  // path_arr, ok = slice.concatenate( start_path, end_path )
  // if !ok { return nil, false }
  append( &path_arr, ..start_path[:] )
  append( &path_arr, ..end_path[:] )

  // fmt.println( "COCK" )
  // debug_draw_path( start_path, linalg.vec3{ 1, 1, 1 } )

  for wp, i in path_arr
  {
    assert( wp.level_idx >= 0 && wp.level_idx <= TILE_LEVELS_MAX, fmt.tprint( "path_arr[", i, "].level_idx: ", i, wp.level_idx ) )
  }

  return path_arr, true
}


game_find_tile_hit_by_camera :: proc() -> ( hit_tile: waypoint_t, has_hit_tile: bool )
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
          ray.pos    = data.cam.pos
          ray.dir = camera_get_front()
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

Dir :: enum
{
  FORWARD,  // = Tile_Nav_Type.RAMP_UP,   // @NOTE: this technically is forward
  BACKWARDS,// = Tile_Nav_Type.RAMP_DOWN, // @NOTE: this technically is backward
  LEFT,     // = Tile_Nav_Type.RAMP_LEFT,
  RIGHT,    // = Tile_Nav_Type.RAMP_RIGHT,
}

// checks for a ramp up or down in the given Dir from waypoint current
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

  if ok 
  { 
    debug_draw_aabb_wp( current,    linalg.vec3{ 1, 1, 1 }, 30 ) 
    debug_draw_aabb_wp( next_point, linalg.vec3{ 1, 1, 1 }, 30 ) 
  }
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
    if current.z > 0 && data.tile_type_arr[current.level_idx][current.x][current.z -1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[0]  = waypoint_t{ level_idx = current.level_idx, x = current.x, z = current.z -1 } }
    else
    { 
      next_points[0], next_points_viable[0] = game_a_star_02_check_for_ramp( current, Dir.BACKWARDS )
    }
    // left
    if current.x > 0 && data.tile_type_arr[current.level_idx][current.x -1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[1]  = waypoint_t{ level_idx = current.level_idx, x = current.x -1, z = current.z } }
    else
    { 
      next_points[1], next_points_viable[1] = game_a_star_02_check_for_ramp( current, Dir.RIGHT )
    }
    // right
    if current.x < TILE_ARR_X_MAX -1 && data.tile_type_arr[current.level_idx][current.x +1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[2]  = waypoint_t{ level_idx = current.level_idx, x = current.x +1, z = current.z } }
    else
    { 
      next_points[2], next_points_viable[2] = game_a_star_02_check_for_ramp( current, Dir.LEFT )
    }
    // back 
    if current.z < TILE_ARR_Z_MAX -1 && data.tile_type_arr[current.level_idx][current.x][current.z +1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[3]  = waypoint_t{ level_idx = current.level_idx, x = current.x, z = current.z +1 } }
    else
    { 
      next_points[3], next_points_viable[3] = game_a_star_02_check_for_ramp( current, Dir.FORWARD )
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
                           parent_idx=closed_arr_idx 
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
    return nil, Pathfind_Error.NOT_REACHABLE_VIA_GAME_A_STAR_PATHFIND, false 
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
    log.info( "idx:", current.parent_idx, ", current.parent:", current.parent )
    append( &path_arr, current.wp )
  }
  // assert( 0 == 1 )
  // reverse path_arr
  slice.reverse( path_arr[:] )
  
  delete( open_arr )
  delete( closed_arr )

  return path_arr, Pathfind_Error.NONE, true
}
