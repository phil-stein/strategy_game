package core

import        "core:fmt"
import        "core:log"
import        "core:time"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "core:slice"


enemy_gen_move :: proc( enemy: ^character_t, loc:= #caller_location )
{
  log.info( "enemy_gen_move():", loc )

  // if len(data.interactables_arr) > 0
  // {
  //   nearest_interactable      : interactable_t 
  //   nearest_interactable_dist : f32 = 99999999999999999999.9
  //   for interact in data.interactables_arr
  //   {
  //     dist := linalg.distance( util_tile_to_pos( enemy.tile ), util_tile_to_pos( interact.wp ) )
  //     if dist < nearest_interactable_dist
  //     {
  //       nearest_interactable      = interact
  //       nearest_interactable_dist = dist
  //     }
  //   }

  //   // enemy.paths_arr
  // }

  if len(data.player_chars) > 0
  {
    nearest_char      : character_t
    nearest_char_dist : f32 = 99999999999999999999.9
    for char in data.player_chars
    {
      dist := linalg.distance( util_tile_to_pos( enemy.wp ), util_tile_to_pos( char.wp ) )
      if dist < nearest_char_dist
      {
        nearest_char      = char
        nearest_char_dist = dist
      }
    }

    // enemy.paths_arr
    path, err, ok := game_a_star_02_pathfind( enemy.wp, nearest_char.wp )
    if !ok
    {
      log.warn( "failed to find enemy path" )
      return
    }

    append( &enemy.paths_arr, make( [dynamic]waypoint_t, len(path), cap(path) ) )
    idx := len(enemy.paths_arr) -1
    copy( enemy.paths_arr[idx][:], path[:] )
    // append( &enemy.paths_arr, path )
    delete( path )

  }
}
