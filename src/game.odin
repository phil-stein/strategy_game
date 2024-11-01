package core 

import        "core:fmt"
import        "core:math"
import linalg "core:math/linalg/glsl"



Nav_Type :: enum
{
  EMPTY,
  BLOCKED,
  TRAVERSABLE,
  // ...
}
nav_type_level_arr :: [TILE_ARR_X_MAX][TILE_ARR_Z_MAX]Nav_Type

game_build_nav_struct :: proc( /* num_levels: int, levels: []string */ ) -> ( nav: [len(data.tile_str_arr)]nav_type_level_arr )
{
  // nav : [len(data.tile_str_arr)]nav_type_level_arr

  for level, level_idx in data.tile_str_arr
  {

    // for z := TILE_ARR_Z_MAX -1; z >= 0; z -= 1    // reversed so the str aligns with the created map
    // {
    //   for x := TILE_ARR_X_MAX -1; x >= 0; x -= 1  // reversed so the str aligns with the created map
    for x := 0; x < TILE_ARR_X_MAX; x += 1 
    {
      for z := 0; z < TILE_ARR_Z_MAX; z += 1 
      {
        tile_str_idx := ( TILE_ARR_X_MAX * TILE_ARR_Z_MAX ) - ( x + (z*TILE_ARR_X_MAX) +1 ) // reversed idx so the str aligns with the created map
        // fmt.println( "level[ x + z ]: ", level[ x + z ], ", rune: ", rune(level[ x + z ]) )
        // fmt.println( "level[ tile_str_idx ]: ", level[ tile_str_idx ], ", rune: ", rune(level[ tile_str_idx ]) )
        // switch level[ x + z ] 
        switch level[ tile_str_idx ] 
        {
          case '.':
            nav[level_idx][x][z] = Nav_Type.EMPTY
          case 'X':
            nav[level_idx][x][z] = Nav_Type.TRAVERSABLE
            if level_idx > 0
            {
              nav[level_idx -1][x][z] = Nav_Type.BLOCKED
            }
          case:
            nav[level_idx][x][z] = Nav_Type.EMPTY
        }
      }
    }
  }

  return nav
}

game_a_star_pathfind :: proc()
{
  // @TODO:
}

game_find_tile_hit_by_camera :: proc()
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
  any_hits    := false
  closest_hit := linalg.vec3{ 10000000, 1000000, 1000000 }
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
          hit := ray_intersect_aabb( ray, min, max )
          if hit.hit
          {
            any_hits = true
            if linalg.distance( data.cam.pos, pos ) < linalg.distance( data.cam.pos, closest_hit )
            {
              closest_hit = pos
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
    debug_draw_line( closest_hit + linalg.vec3{ 0, 0.5, 0 }, closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 1, 0, 0 }, 25 ) 
    // draw blue line from character
    debug_draw_line( data.entity_arr[0].pos + linalg.vec3{ 0, 0, 0 }, closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 0.6, 0.8, 1 }, 15 )
    
    debug_draw_sphere( closest_hit + linalg.vec3{ 0, 1.5, 0 }, linalg.vec3{ 0.2, 0.2, 0.2 }, linalg.vec3{ 0.6, 0.8, 1 } )
  }
}
