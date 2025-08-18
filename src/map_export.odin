package core

import      "core:fmt"
import      "core:log"
import      "core:os"
import str  "core:strings"
import ufbx "../external/ufbx"


map_export_current :: proc( file_name: string  )
{
  txt_sb := str.builder_make()
  defer str.builder_destroy( &txt_sb )
  vert_count := 0

  for level, level_idx in data.tile_str_arr
  {
    for x := 0; x < TILE_ARR_X_MAX; x += 1 
    {
      for z := 0; z < TILE_ARR_Z_MAX; z += 1 
      {
        switch data.tile_type_arr[level_idx][x][z] 
        {
          case Tile_Nav_Type.SPRING:          fallthrough
          case Tile_Nav_Type.BOX:             fallthrough
          case Tile_Nav_Type.EMPTY:
          {
            // do nothing
          }
          case Tile_Nav_Type.RAMP_FORWARD:
          {
            // v -1.000000 -1.000000 1.000000
            // v -1.000000 1.000000 1.000000
            // v -1.000000 -1.000000 -1.000000
            // v 1.000000 -1.000000 1.000000
            // v 1.000000 1.000000 1.000000
            // v 1.000000 -1.000000 -1.000000
            // s 1
            // f 1 2 3
            // f 6 5 4
            // f 5 1 4
            // f 6 1 3
            // f 3 5 6
            // f 5 2 1
            // f 6 4 1
            // f 3 2 5

            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x),  0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x),  0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "s 0\n" ) )
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 1 + vert_count, 2 + vert_count, 3 + vert_count ) )  
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 5 + vert_count, 4 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 1 + vert_count, 4 + vert_count ) )   
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 1 + vert_count, 3 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 5 + vert_count, 6 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 2 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 4 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 2 + vert_count, 5 + vert_count ) ) 

            vert_count += 6
          }
          case Tile_Nav_Type.RAMP_BACKWARD:
          {
            // v 0.500000 -0.500000 -0.500000
            // v 0.500000 0.500000 -0.500000
            // v 0.500000 -0.500000 0.500000
            // v -0.500000 -0.500000 -0.500000
            // v -0.500000 0.500000 -0.500000
            // v -0.500000 -0.500000 0.500000
            // s 1
            // f 1 2 3
            // f 6 5 4
            // f 5 1 4
            // f 6 1 3
            // f 3 5 6
            // f 5 2 1
            // f 6 4 1
            // f 3 2 5

            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x),  0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x),  0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "s 0\n" ) )
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 1 + vert_count, 2 + vert_count, 3 + vert_count ) )  
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 5 + vert_count, 4 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 1 + vert_count, 4 + vert_count ) )   
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 1 + vert_count, 3 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 5 + vert_count, 6 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 2 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 4 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 2 + vert_count, 5 + vert_count ) ) 

            vert_count += 6
          }
          case Tile_Nav_Type.RAMP_LEFT:
          {
            // v 0.500000 -0.500000 0.500000
            // v 0.500000 0.500000 0.500000
            // v -0.500000 -0.500000 0.500000
            // v 0.500000 -0.500000 -0.500000
            // v 0.500000 0.500000 -0.500000
            // v -0.500000 -0.500000 -0.500000
            // s 1
            // f 1 2 3
            // f 6 5 4
            // f 5 1 4
            // f 6 1 3
            // f 3 5 6
            // f 5 2 1
            // f 6 4 1
            // f 3 2 5

            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x),  0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x),  0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "s 0\n" ) )
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 1 + vert_count, 2 + vert_count, 3 + vert_count ) )  
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 5 + vert_count, 4 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 1 + vert_count, 4 + vert_count ) )   
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 1 + vert_count, 3 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 5 + vert_count, 6 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 2 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 4 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 2 + vert_count, 5 + vert_count ) ) 

            vert_count += 6
          }
          case Tile_Nav_Type.RAMP_RIGHT:
          {
            // v -0.500000 -0.500000 -0.500000
            // v -0.500000 0.500000 -0.500000
            // v 0.500000 -0.500000 -0.500000
            // v -0.500000 -0.500000 0.500000
            // v -0.500000 0.500000 0.500000
            // v 0.500000 -0.500000 0.500000
            // s 1
            // f 1 2 3
            // f 6 5 4
            // f 5 1 4
            // f 6 1 3
            // f 3 5 6
            // f 5 2 1
            // f 6 4 1
            // f 3 2 5

            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x),  0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x),  0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "s 0\n" ) )
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 1 + vert_count, 2 + vert_count, 3 + vert_count ) )  
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 5 + vert_count, 4 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 1 + vert_count, 4 + vert_count ) )   
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 1 + vert_count, 3 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 5 + vert_count, 6 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 5 + vert_count, 2 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 6 + vert_count, 4 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v\n", 3 + vert_count, 2 + vert_count, 5 + vert_count ) ) 

            vert_count += 6
          }
          case Tile_Nav_Type.BLOCKED:         fallthrough
          case Tile_Nav_Type.TRAVERSABLE:     
          {
            // v -1.000000 -1.000000 1.000000
            // v -1.000000 1.000000 1.000000
            // v -1.000000 -1.000000 -1.000000
            // v -1.000000 1.000000 -1.000000
            // v 1.000000 -1.000000 1.000000
            // v 1.000000 1.000000 1.000000
            // v 1.000000 -1.000000 -1.000000
            // v 1.000000 1.000000 -1.000000
            // s 0
            // f 1 2 4 3
            // f 3 4 8 7
            // f 7 8 6 5
            // f 5 6 2 1
            // f 3 7 5 1
            // f 8 4 2 6
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -1.000000 + x, -1.000000 + level_idx,  1.000000 + z ) )
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -1.000000 + x,  1.000000 + level_idx,  1.000000 + z ) )
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -1.000000 + x, -1.000000 + level_idx, -1.000000 + z ) )
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -1.000000 + x,  1.000000 + level_idx, -1.000000 + z ) )
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  1.000000 + x, -1.000000 + level_idx,  1.000000 + z ) )
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  1.000000 + x,  1.000000 + level_idx,  1.000000 + z ) )
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  1.000000 + x, -1.000000 + level_idx, -1.000000 + z ) )
            // str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  1.000000 + x,  1.000000 + level_idx, -1.000000 + z ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x),  0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n", -0.500000 + f32(x),  0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x),  0.500000 + f32(level_idx),  0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x), -0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "v %v %v %v\n",  0.500000 + f32(x),  0.500000 + f32(level_idx), -0.500000 + f32(z) ) )
            str.write_string( &txt_sb, fmt.tprintf( "s 0\n" ) )
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v %v\n", 1 + vert_count, 2 + vert_count, 4 + vert_count, 3 + vert_count ) )  
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v %v\n", 3 + vert_count, 4 + vert_count, 8 + vert_count, 7 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v %v\n", 7 + vert_count, 8 + vert_count, 6 + vert_count, 5 + vert_count ) )   
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v %v\n", 5 + vert_count, 6 + vert_count, 2 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v %v\n", 3 + vert_count, 7 + vert_count, 5 + vert_count, 1 + vert_count ) ) 
            str.write_string( &txt_sb, fmt.tprintf( "f %v %v %v %v\n", 8 + vert_count, 4 + vert_count, 2 + vert_count, 6 + vert_count ) ) 

            vert_count += 8
          }
        }
      }
    }
  }

  txt := str.to_string( txt_sb )
  ok := os.write_entire_file( file_name, transmute([]byte)txt )
  if !ok { log.error( "failed writing level to file" ) } 
}
