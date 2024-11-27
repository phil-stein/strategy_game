package core 

import        "core:fmt"
import        "core:math"
import linalg "core:math/linalg/glsl"




game_a_star_pathfind :: proc( start, end: waypoint_t ) -> ( path: [dynamic]waypoint_t, ok: bool  )
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

game_find_tile_hit_by_camera :: proc() -> ( hit_tile: waypoint_t, has_hit_tile: bool )
{

  // {
  //   min := linalg.vec3{ -1, -1, -1 }
  //   max := linalg.vec3{  1,  1,  1 }
  //   ray : ray_t
  //   ray.pos    = data.cam.pos
  //   ray.dir = camera_get_front()
  //   hit := ray_intersect_aabb( ray, min, max )
  //   debug_draw_aabb( min, max, hit.hit ? linalg.vec3{ 1, 0, 1 } : linalg.vec3{ 1, 1, 1 }, 15 )
  // }
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
