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
game_a_star_f_cost :: proc( wp, end: waypoint_t ) -> ( f_cost: f32 )
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
    if current.z > 0 && data.tile_type_arr[0][current.x][current.z -1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[0]  = waypoint_t{ level_idx = 0, x = current.x, z = current.z -1 } }
    else
    { next_points_viable[0] = false }
    // left
    if current.x > 0 && data.tile_type_arr[0][current.x -1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[1]  = waypoint_t{ level_idx = 0, x = current.x -1, z = current.z } }
    else
    { next_points_viable[1] = false }
    // right
    if current.x < TILE_ARR_X_MAX -1 && data.tile_type_arr[0][current.x +1][current.z] == Tile_Nav_Type.TRAVERSABLE
    { next_points[2]  = waypoint_t{ level_idx = 0, x = current.x +1, z = current.z } }
    else
    { next_points_viable[2] = false }
    // back 
    if current.z < TILE_ARR_Z_MAX -1 && data.tile_type_arr[0][current.x][current.z +1] == Tile_Nav_Type.TRAVERSABLE
    { next_points[3]  = waypoint_t{ level_idx = 0, x = current.x, z = current.z +1 } }
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

  if !ok
  {
    return nil, false
  }


  // // current is the end node
  // append( &path_arr, current.wp )
  //
  // // go backwards from end to start
  // for 
  // {
  //   
  // }
  // 
  // // @TODO: reverse path_arr

  // // current is the end node
  // // append( &path_arr, current.wp )
  // append( &closed_arr, node_t{ wp=current.wp, parent=current.wp } )
  // for i := len(closed_arr) -1; i >= 0; i -= 1
  // {
  //   append( &path_arr, closed_arr[i].parent )
  //
  //   // debug_draw_sphere( linalg.vec3{  } )
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
  // @TODO: reverse path_arr
  slice.reverse( path_arr[:] )
  
  return path_arr, true

}

game_find_tile_hit_by_camera :: proc() -> ( hit_tile: waypoint_t, has_hit_tile: bool )
{
  has_hit_tile = false
  hit_tile     = waypoint_t{ level_idx = 0, x = 0, z = 0 }

  any_hits    := false
  closest_hit := linalg.vec3{ 10000000, 1000000, 1000000 }
  closest_hit_tile := waypoint_t{ 0, 0, 0 }
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
              closest_hit_tile = waypoint_t{ y, x, z }
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
    // draw red target indicator line
    debug_draw_line( closest_hit + linalg.vec3{ 0, 0.5, 0 }, closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 1, 0, 0 }, 10 ) 
    // // draw blue line from character
    // debug_draw_line( data.entity_arr[0].pos + linalg.vec3{ 0, 0, 0 }, closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 0.6, 0.8, 1 }, 10 )
    
    debug_draw_sphere( closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 0.2, 0.2, 0.2 }, linalg.vec3{ 0.6, 0.8, 1 } )


  

    hit_tile     = closest_hit_tile
    has_hit_tile = true
  }
  
  return hit_tile, has_hit_tile
}
