package core 

import        "core:fmt"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "core:slice"



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
  f_cost    : f32,
  parent    : waypoint_t,
}
// @TODO: use all levels
// based on: https://www.youtube.com/watch?v=-L-WgKMFuhE&list=PLFt_AvWsXl0cq5Umv3pMC9SPnKjfp9eGW&index=2
game_a_star_f_cost :: #force_inline proc( wp, end: waypoint_t ) -> ( f_cost: f32 )
{
  // @TODO: isnt f_cost more complext than dist ???
  return linalg.distance( util_tile_to_pos( wp ), util_tile_to_pos( end ) )
}
game_a_star_pathfind :: proc( _start, _end: waypoint_t ) -> ( path_arr: [dynamic]waypoint_t, ok: bool  )
{
  ok = false

  open_arr   : [dynamic]node_t
  closed_arr : [dynamic]node_t
  defer delete( open_arr )
  defer delete( closed_arr )
  
  start := node_t{ wp=_start, f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
  end   := node_t{ wp=_end,   f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }

  // start == end
  if start.wp.level_idx == end.wp.level_idx &&
     start.wp.z         == end.wp.z         &&
     start.wp.x         == end.wp.x
  { 
    append( &path_arr, _start )
    return path_arr, true 
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
  for tries < TILE_ARR_Z_MAX * TILE_ARR_X_MAX // 1000
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
    if current_idx >= len(open_arr) { return path_arr, false }
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

      // neighbour := node_t{ wp=waypoint_t{ level_idx=0, x=0, z=0 }, f_cost=0.0, parent=waypoint_t{ level_idx=0, x=0, z=0 } }
      neighbour := node_t{ wp=next_points[i], 
                           f_cost=game_a_star_f_cost( next_points[i], end.wp ), 
                           parent=current.wp 
                         }
      append( &open_arr, neighbour )

      // at_least_one_viable = true
    }

    tries += 1
  }

  if !ok { return nil, false }

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
    // @TODO: this scuffed as hell
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
  
  return path_arr, true

}
// use mutliple levels:
//  1. find nearest ramp to goal
//    - need to know if player can even reach it
//    - floodfill ?
//    - brute-force all of them ?
//  2. a* to that ramp
// reverse: XXX
//  1. a* to ramps (prob in order of dist to goal)
//  2. a* to goal
//  3. repeat for all ramps until one works both tims
//  -> stich together the two paths

@private a_star_current_end : waypoint_t
@private 
sort_proc :: proc( i, j: waypoint_t ) -> bool
{
  i_dist := linalg.distance( util_tile_to_pos( i ), util_tile_to_pos( a_star_current_end ) )
  j_dist := linalg.distance( util_tile_to_pos( j ), util_tile_to_pos( a_star_current_end ) )
  return i_dist < j_dist
}

game_a_star_pathfind_levels :: proc( start, end: waypoint_t ) -> ( path_arr: [dynamic]waypoint_t, ok: bool  )
{
  if start.level_idx == end.level_idx { return game_a_star_pathfind( start, end ) }
  

  // sort ramps by dist to goal
  // sorted_ramp_idx_arr := make( []int, len( data.tile_ramp_entity_id_arr[end.level_idx] ) )
  // defer delete( sorted_ramp_idx_arr )
  // for ramp_idx in data.tile_ramp_entity_id_arr
  // {
  // }
  a_star_current_end = end
  sorted_ramp_arr := data.tile_ramp_wp_arr[end.level_idx][:]
  // fmt.println( "data.tile_ramp_wp_arr[end.level_idx] len ->", len(data.tile_ramp_wp_arr[end.level_idx]) )
  // fmt.println( "data.tile_ramp_wp_arr[end.level_idx][:] len ->", len(data.tile_ramp_wp_arr[end.level_idx][:]) )
  // fmt.println( "sorted_ramp_arr len ->", len(sorted_ramp_arr) )
  slice.sort_by( sorted_ramp_arr, sort_proc )

  // @TMP:
  for w, i in sorted_ramp_arr
  {
    // fmt.println( w )
    c : f32 = f32(i +1) / f32( len( sorted_ramp_arr ) )
    // debug_draw_aabb_wp( w, linalg.vec3{ 1, 1, 1 }, 10 )
    // debug_draw_aabb_wp( w, linalg.vec3{ c, c, c }, 10 )

    ramp := w
    ramp_type := data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z]
    ramp_top : waypoint_t
    ramp_bottom : waypoint_t

    // if ramp.z > 0 && 
    //    ramp_type == Tile_Nav_Type.RAMP_DOWN &&
    //    data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z -1] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x, z = ramp.z -1 } }
    // else if ramp.x > 0 && 
    //         ramp_type == Tile_Nav_Type.RAMP_RIGHT &&
    //         data.tile_type_arr[ramp.level_idx][ramp.x -1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x -1, z = ramp.z } }
    // else if ramp.x < TILE_ARR_X_MAX -1 && 
    //         ramp_type == Tile_Nav_Type.RAMP_LEFT &&
    //         data.tile_type_arr[ramp.level_idx][ramp.x +1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x +1, z = ramp.z } }
    // else if ramp.z < TILE_ARR_Z_MAX -1 && 
    //         ramp_type == Tile_Nav_Type.RAMP_UP &&
    //         data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z +1] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x, z = ramp.z +1 } }
    // else { debug_draw_sphere( util_tile_to_pos( ramp ), linalg.vec3{ 1, 1, 1 }, linalg.vec3{ 1, 0, 0 } ); continue }
    //
    // debug_draw_aabb_wp( ramp_top, linalg.vec3{ 1, 1, 0 }, 10 )

    // if ramp.z > 0 && 
    //    ramp_type == Tile_Nav_Type.RAMP_UP &&
    //    data.tile_type_arr[ramp.level_idx -1][ramp.x][ramp.z -1] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x, z = ramp.z -1 } }
    // else if ramp.x > 0 && 
    //         ramp_type == Tile_Nav_Type.RAMP_LEFT &&
    //         data.tile_type_arr[ramp.level_idx -1][ramp.x -1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x -1, z = ramp.z } }
    // else if ramp.x < TILE_ARR_X_MAX -1 && 
    //         ramp_type == Tile_Nav_Type.RAMP_RIGHT &&
    //         data.tile_type_arr[ramp.level_idx -1][ramp.x +1][ramp.z] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x +1, z = ramp.z } }
    // else if ramp.z < TILE_ARR_Z_MAX -1 && 
    //         ramp_type == Tile_Nav_Type.RAMP_DOWN &&
    //         data.tile_type_arr[ramp.level_idx -1][ramp.x][ramp.z +1] == Tile_Nav_Type.TRAVERSABLE
    // { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x, z = ramp.z +1 } }
    // else { debug_draw_sphere( util_tile_to_pos( ramp ), linalg.vec3{ 1, 1, 1 }, linalg.vec3{ 1, 0, 0 } ); continue }
    // // else { fmt.eprintln( "[ERROR] didnt find ramp_bottom", i ); continue }
    // fmt.println( "found ramp_bottom:", ramp_bottom )
    // debug_draw_aabb_wp( ramp_bottom, linalg.vec3{ 1, 0, 1 }, 10 )
  }
  // if 1 == 1 { return nil, false }

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
    // if ramp.z > 0 && data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z -1] == Tile_Nav_Type.RAMP_UP  
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x, z = ramp.z -1 } }
    // else if ramp.x > 0 && data.tile_type_arr[ramp.level_idx][ramp.x -1][ramp.z] == Tile_Nav_Type.RAMP_LEFT 
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x -1, z = ramp.z } }
    // else if ramp.x < TILE_ARR_X_MAX -1 && data.tile_type_arr[ramp.level_idx][ramp.x +1][ramp.z] == Tile_Nav_Type.RAMP_RIGHT  
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x +1, z = ramp.z } }
    // else if ramp.z < TILE_ARR_Z_MAX -1 && data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z +1] == Tile_Nav_Type.RAMP_DOWN
    // { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x, z = ramp.z +1 } }
    // else { continue }
    if ramp.z > 0 && 
       ramp_type == Tile_Nav_Type.RAMP_DOWN &&
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
            ramp_type == Tile_Nav_Type.RAMP_UP &&
            data.tile_type_arr[ramp.level_idx][ramp.x][ramp.z +1] == Tile_Nav_Type.TRAVERSABLE
    { ramp_top = waypoint_t{ level_idx = ramp.level_idx, x = ramp.x, z = ramp.z +1 } }
    else { /* fmt.eprintln( "[ERROR] didnt find ramp_top", i ); */ continue }

    // fmt.println( "found ramp_top:", ramp_top )
    // debug_draw_aabb_wp( ramp_top, linalg.vec3{ 1, 1, 0 }, 10 )

    // a* from ramps to goal 
    end_path, ok = game_a_star_pathfind( ramp_top, end )
    if !ok { /* fmt.eprintln( "[ERROR] didnt find end_path", i ); */ continue }
    // debug_draw_path( end_path, linalg.vec3{ 1, 1, 1 } )

    // find the tile at the foot of the ramp
    //    [0]
    // [1] X [2]
    //    [3]
    if ramp.z > 0 && 
       ramp_type == Tile_Nav_Type.RAMP_UP &&
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
            ramp_type == Tile_Nav_Type.RAMP_DOWN &&
            data.tile_type_arr[ramp.level_idx -1][ramp.x][ramp.z +1] == Tile_Nav_Type.TRAVERSABLE
    { ramp_bottom = waypoint_t{ level_idx = ramp.level_idx -1, x = ramp.x, z = ramp.z +1 } }
    else { /* fmt.eprintln( "[ERROR] didnt find ramp_bottom", i ); */ continue }

    // fmt.println( "found ramp_bottom:", ramp_bottom )
    // debug_draw_aabb_wp( ramp_bottom, linalg.vec3{ 1, 0, 1 }, 10 )
    
    // a* from start to ramp
    start_path, ok = game_a_star_pathfind( start, ramp_bottom )

    if !ok { /* fmt.eprintln( "[ERROR] didnt find start_path", i ); */ continue }
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
