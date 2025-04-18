package core

import linalg "core:math/linalg/glsl"
import str    "core:strings"
import        "core:fmt"
import        "vendor:glfw"
import gl     "vendor:OpenGL"

// "typedefs" for linalg/glsl package
vec2 :: linalg.vec2
vec3 :: linalg.vec3
vec4 :: linalg.vec4
mat3 :: linalg.mat3
mat4 :: linalg.mat4

Window_Type :: enum { MINIMIZED, MAXIMIZED, FULLSCREEN };

texture_t :: struct
{
  handle   : u32,
  width    : int,
  height   : int,
  channels : int,

  name   : string,  // @TODO: only needed in debug mode
}

material_t :: struct
{
  albedo_idx       : int,
  roughness_idx    : int,
  metallic_idx     : int,
  normal_idx       : int,

  uv_tile          : linalg.vec2,
  uv_offs          : linalg.vec2,

  tint             : linalg.vec3,
  roughness_f      : f32,
  metallic_f       : f32,

  name             : string,  // @TODO: only needed in debug mode
}

mesh_t :: struct
{
  vao          : u32,
  vbo          : u32,
  vertices_len : int, 
  indices_len  : int, 

  name         : string  // @TODO: only needed in debug mode
}

// Interactable_Type :: enum
// {
//   BOX,
// }
// 
// interactable_t :: struct
// {
//   wp   : waypoint_t,
//   type : Combo_Type,
// }

entity_t :: struct
{
  dead             : bool,

  pos, rot, scl    : linalg.vec3,
  
  mesh_idx         : int,

  mat_idx          : int,

  model, inv_model : linalg.mat4,

}

cubemap_t :: struct
{
  loaded : bool,
  // name   : string,

  environment : u32,
  irradiance  : u32,
  prefilter   : u32,
  intensity   : f32,
}

Tile_Nav_Type :: enum
{
  EMPTY,
  BLOCKED,
  TRAVERSABLE,
  RAMP_FORWARD,  // used to be RAMP_UP 
  RAMP_BACKWARD, // used to be RAMP_DOWN 
  RAMP_LEFT,
  RAMP_RIGHT,
  SPRING,
  BOX,
}

waypoint_t :: struct
{
  level_idx : int,
  x, z      : int,

  // usually will be NONE
  combo_type : Combo_Type,
}

Combo_Type :: enum
{
  NONE,
  JUMP, // also spring
  ATTACK,
  PUSH,
}
// intersections_t :: struct
// {
//   wp   : waypoint_t,
//   type : Combo_Type,
// }
character_t :: struct
{
  wp              : waypoint_t,
  entity_idx      : int,
  halo_entity_idx : int,
  color           : vec3,
  path_offset     : vec3,

  // -- gameplay --
  max_walk_dist   : int,
  max_jump_dist   : int,
  max_turns       : int,
  current_turns   : int,

  // -- paths --
  paths_arr              : [dynamic][dynamic]waypoint_t,
  left_turns             : int,
  path_current_combo     : Combo_Type,
}

Pathfind_Error :: enum
{
  NONE,
  NOT_FOUND,
  TOO_LONG,
  START_END_SAME_TILE, // @TODO:
  // NOT_REACHABLE_VIA_GAME_A_STAR_PATHFIND,
  PATH_NEEDS_TO_BE_REVERSED,
}

data_t :: struct
{
  delta_t_real      : f32,
  delta_t           : f32,
  total_t           : f32,
  cur_fps           : f32,
  time_scale        : f32,

  window                 : glfw.WindowHandle,
  window_type            : Window_Type,
  window_width           : int,
  window_height          : int,
  monitor                : glfw.MonitorHandle,
  monitor_width          : int,
  monitor_height         : int,
  monitor_size_cm_width  : f32,
  monitor_size_cm_height : f32,
  monitor_dpi_width      : f32,
  monitor_dpi_height     : f32,
  monitor_ppi_width      : f32,
  monitor_ppi_height     : f32,
  vsync_enabled          : bool,

  quad_vao : u32,
  quad_vbo : u32,

  line_mesh : mesh_t,

  skybox_vao : u32,
  skybox_vbo : u32,

  // global_shader         : u32,
  basic_shader          : u32,
  deferred_shader       : u32,
  lighting_shader       : u32,
  post_fx_shader        : u32,
  skybox_shader         : u32,
  quad_shader           : u32,
  equirect_shader       : u32,
  irradiance_map_shader : u32,
  prefilter_shader      : u32,
  brdf_lut_shader       : u32,
  mouse_pick_shader     : u32,

  brdf_lut : u32,

  cubemap : cubemap_t,

  fb_deferred   : framebuffer_t,
  fb_lighting   : framebuffer_t,
  fb_outline    : framebuffer_t,
  fb_mouse_pick : framebuffer_t,

  wireframe_mode_enabled : bool,
  
  cam : struct
  {
    pos       : linalg.vec3,
    target    : linalg.vec3,
    pitch_rad : f32, 
    yaw_rad   : f32, 
    view_mat  : linalg.mat4,
    pers_mat  : linalg.mat4,
  },

  editor_ui : struct
  {
    active    : bool,
    show_demo : bool,
    show_main : bool,
    style     : enum { DARK_DEFAULT, DARK_LIGHT },
  },  

  text : struct
  {
    atlas_tex_handle  : u32,
    glyph_size        : i32,
    last_draw_calls   : i32,
    draw_calls        : i32,
    font_name         : string,
    draw_solid        : bool,

    shader            : u32,
    baked_shader      : u32,

    mesh              : mesh_t,
  },
  
  entity_arr          : [dynamic]entity_t,
  entity_dead_idx_arr : [dynamic]int,
  
  // assetm
  mesh_arr     : [dynamic]mesh_t,
  texture_arr  : [dynamic]texture_t,
  material_arr : [dynamic]material_t,

  texture_idxs : struct
  {
    blank               : int,
    brick_albedo        : int,
    brick_normal        : int,  
    brick_roughness     : int,
    dirt_cube_01_albedo : int,
    dirt_cube_02_albedo : int,
    robot_albedo        : int,
    robot_normal        : int,  
    robot_roughness     : int,
    robot_metallic      : int,  
    female_albedo       : int,
    female_normal       : int,  
    female_roughness    : int,
    female_metallic     : int,  
    water_albedo        : int,
    water_normal        : int,  
    water_roughness     : int,
    demon_albedo        : int,
    demon_normal        : int,  
    demon_roughness     : int,
    demon_metallic      : int,  
  },
  material_idxs : struct
  {
    default      : int,
    metal_01     : int,
    brick        : int,
    dirt_cube_01 : int,
    dirt_cube_02 : int,
    robot        : int,
    female       : int,
    water        : int,
    demon        : int,
  },
  mesh_idxs : struct
  {
    quad        : int,
    cube        : int,
    sphere      : int,
    suzanne     : int,
    dirt_cube   : int,
    dirt_ramp   : int,
    robot_char  : int,
    female_char : int,
    spring      : int,
    demon_char  : int,
    box         : int,

    icon_jump   : int,
    icon_attack : int,
  },

  tile_00_str : string,
  tile_01_str : string,
  tile_02_str : string,

  tile_str_arr       : [TILE_LEVELS_MAX]string,
  tile_type_arr      : [TILE_LEVELS_MAX][TILE_ARR_X_MAX][TILE_ARR_Z_MAX]Tile_Nav_Type,
  tile_entity_id_arr : [TILE_LEVELS_MAX][TILE_ARR_X_MAX][TILE_ARR_Z_MAX]int,
  tile_ramp_wp_arr   : [TILE_LEVELS_MAX][dynamic]waypoint_t,

  player_chars : [3]character_t,
  player_chars_current : int,

  enemy_chars         : [3]character_t,
  enemy_chars_current : int,

  // @TODO: pretty sure not being used
  // interactables_arr : [dynamic]interactable_t,

}
TILE_ARR_X_MAX  :: 10
TILE_ARR_Z_MAX  :: 10
TILE_LEVELS_MAX :: 3
// global struct holding most data about the game, except input
data : data_t =
{
  delta_t_real      = 0.0,
  delta_t           = 0.0,
  total_t           = 0.0,
  cur_fps           = 0.0,
  time_scale        = 1.0,
  
  wireframe_mode_enabled = false,

  cam = 
  {
    // pos       = { 0, 5, -6 },
    pos       = { 0,11.5, -12 },
    target    = {  0, 0, 0 },
    // pitch_rad = -0.4,
    // yaw_rad   = 14.2,
    pitch_rad = -0.78397244,
    yaw_rad   = 14.130187,
  },

  editor_ui = 
  {
    active    = true,
    show_main = false,
    show_demo = false,
  },

  // tile_00_str = 
  // "XXXXXXXXXX"+
  // "X.XXXX.XXX"+
  // "XXXXX.XXXX"+
  // "X.XXXX..XX"+
  // "X..XXXXX.X"+
  // "X..XXXXX.X"+
  // "XXX.XXXX.X"+
  // "X.XXXXXXXX"+
  // "XXXXX.X..X"+
  // "XXXXXXXXXX",
  // 
  // tile_01_str = 
  // "XXXXX...>X"+
  // "X..^......"+
  // "X.......X."+
  // "..Xv.....X"+
  // "...X...X.X"+
  // "...X....XX"+
  // "......XX.."+
  // "...X...X<."+
  // "XX....X..."+
  // "XXX<......",
  
  tile_00_str = 
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX"+
  "XXXXXXXXXX",
  
  tile_01_str = 
  "XXXXX...>X"+
  "X........X"+
  "^..XX....X"+
  "...X.....X"+
  "...X..XXXX"+
  "...^..XX<."+
  ".O....XX.."+
  "....#..X.."+
  "XX.....X.."+
  "XXX<......",

  tile_02_str = 
  "XXX<......"+
  "^........v"+
  ".........X"+
  ".........X"+
  "......XXXX"+
  "......X<.."+
  "......XX.."+
  ".......^.."+
  "XX........"+
  "XX<.......",

  player_chars_current = 0,
}

data_init :: proc()
{

// init .player_chars
  for &char, i in data.player_chars
  {
    // char.has_path = false
    char.wp         = waypoint_t{ level_idx=0, x=0, z=0 }
    char.entity_idx = -1
    char.left_turns = 0
    // char.path_finished = false

    char.max_walk_dist = 20 // 14
    char.max_jump_dist = 4
    char.max_turns     = 3
    char.current_turns = 0

    char.path_offset = vec3{ 0, f32(i) * 0.1, 0 }

    // // @NOTE: @UNSURE: doing this to have chars with no path 
    // //                 be abled to intersect with other chars paths
    // //                 also setting wp again in main.odin after 
    // //                 adding entities
    // path := make( [dynamic]waypoint_t, 1 )
    // path[0] = char.wp
    // append( &char.paths_arr, path )
  }
  data.player_chars[0].color = vec3{ 0, 1, 1 }
  data.player_chars[1].color = vec3{ 1, 0, 1 }
  data.player_chars[2].color = vec3{ 1, 1, 0 }
  
  for &enemy, i in data.enemy_chars
  {
    enemy.color  = vec3{ 1, 0, 0 }

    enemy.wp         = waypoint_t{ level_idx=0, x=0, z=0 }
    enemy.entity_idx = -1
    enemy.left_turns = 0

    enemy.max_walk_dist = 20 // 14
    enemy.max_jump_dist = 4
    enemy.max_turns     = 3
    enemy.current_turns = 0

    enemy.path_offset = vec3{ 0, f32(len(data.player_chars) + i) * 0.1, 0 }
  }
  


  // init .title_str_arr
  data.tile_str_arr[0] = data.tile_00_str
  data.tile_str_arr[1] = data.tile_01_str
  data.tile_str_arr[2] = data.tile_02_str

  // screen quad 
	quad_verts := [?]f32{ 
	  // pos       // uv 
	  -1.0,  1.0,  0.0, 1.0,
	  -1.0, -1.0,  0.0, 0.0,
	   1.0, -1.0,  1.0, 0.0,

	  -1.0,  1.0,  0.0, 1.0,
	   1.0, -1.0,  1.0, 0.0,
	   1.0,  1.0,  1.0, 1.0
	}

	// screen quad VAO
	gl.GenVertexArrays( 1, &data.quad_vao )
	gl.GenBuffers( 1, &data.quad_vbo )
	gl.BindVertexArray( data.quad_vao )
	gl.BindBuffer( gl.ARRAY_BUFFER, data.quad_vbo);
	gl.BufferData( gl.ARRAY_BUFFER, size_of(quad_verts), &quad_verts, gl.STATIC_DRAW); // quad_verts is 24 long
	gl.EnableVertexAttribArray(0);
	gl.VertexAttribPointer( 0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0 )
	gl.EnableVertexAttribArray( 1 )
	gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32) )

  // cube map -------------------------------------------------------------------------------------

	skybox_verts := [?]f32{ 
    // positions          
    -1.0,  1.0, -1.0,
    -1.0, -1.0, -1.0,
     1.0, -1.0, -1.0,
     1.0, -1.0, -1.0,
     1.0,  1.0, -1.0,
    -1.0,  1.0, -1.0,

    -1.0, -1.0,  1.0,
    -1.0, -1.0, -1.0,
    -1.0,  1.0, -1.0,
    -1.0,  1.0, -1.0,
    -1.0,  1.0,  1.0,
    -1.0, -1.0,  1.0,

    1.0, -1.0, -1.0,
    1.0, -1.0,  1.0,
    1.0,  1.0,  1.0,
    1.0,  1.0,  1.0,
    1.0,  1.0, -1.0,
    1.0, -1.0, -1.0,

    -1.0, -1.0,  1.0,
    -1.0,  1.0,  1.0,
     1.0,  1.0,  1.0,
     1.0,  1.0,  1.0,
     1.0, -1.0,  1.0,
    -1.0, -1.0,  1.0,

    -1.0,  1.0, -1.0,
     1.0,  1.0, -1.0,
     1.0,  1.0,  1.0,
     1.0,  1.0,  1.0,
    -1.0,  1.0,  1.0,
    -1.0,  1.0, -1.0,

    -1.0, -1.0, -1.0,
    -1.0, -1.0,  1.0,
     1.0, -1.0, -1.0,
     1.0, -1.0, -1.0,
    -1.0, -1.0,  1.0,
     1.0, -1.0,  1.0
  }

  //  cube vao
  gl.GenVertexArrays( 1, &data.skybox_vao )
  gl.GenBuffers( 1, &data.skybox_vbo )
  gl.BindVertexArray( data.skybox_vao )
  gl.BindBuffer( gl.ARRAY_BUFFER, data.skybox_vbo )
	gl.BufferData( gl.ARRAY_BUFFER, size_of(skybox_verts), &skybox_verts, gl.STATIC_DRAW ) 
  gl.EnableVertexAttribArray( 0 )
	gl.VertexAttribPointer( 0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0 )
  // ----------------------------------------------------------------------------------------------

  // line mesh ------------------------------------------------------------------------------------

  line_verts := [?]f32 {
    // // pos    uvs  
    // 0, 0, 0,  0, 0, 
    // 0, 1, 0,  0, 0, 

    // pos    uvs    normals   tangents
    0, 0, 0,  0, 0,  0, 0, 0,  0, 0, 0, 
    0, 1, 0,  0, 0,  0, 0, 0,  0, 0, 0, 
  }
  // // const int verts_01_len = 2 * FLOATS_PER_VERT;
  // // mesh_make((f32*)verts_01, (int)verts_01_len, &core_data->line_mesh);
  gl.GenVertexArrays( 1, &data.line_mesh.vao )
  gl.GenBuffers( 1, &data.line_mesh.vbo )
  gl.BindVertexArray( data.line_mesh.vao )
  gl.BindBuffer( gl.ARRAY_BUFFER, data.line_mesh.vbo )
	gl.BufferData( gl.ARRAY_BUFFER, size_of(line_verts), &line_verts, gl.STATIC_DRAW )

  gl.EnableVertexAttribArray( 0 ) // pos
	gl.VertexAttribPointer( 0, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 0 )
	gl.EnableVertexAttribArray( 1 ) // uv
	gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 3 * size_of(f32) )
	gl.EnableVertexAttribArray( 2 ) // normals 
	gl.VertexAttribPointer( 2, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 5 * size_of(f32) )
	gl.EnableVertexAttribArray( 3 ) // tangents 
	gl.VertexAttribPointer( 3, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 8 * size_of(f32) )

  // ----------------------------------------------------------------------------------------------
  
}

data_pre_updated :: proc()
{
  @(static) first_frame := true
  // ---- time ----
	data.delta_t_real = f32(glfw.GetTime()) - data.total_t
	data.total_t      = f32(glfw.GetTime())
  data.cur_fps      = 1 / data.delta_t_real
  if ( first_frame ) 
  { data.delta_t_real = 0.016; first_frame = false; } // otherwise dt first frame is like 5 seconds
  data.delta_t = data.delta_t_real * data.time_scale
  
  window_set_title( 
    str.clone_to_cstring( 
      fmt.tprint( "amazing title | fps: ", data.cur_fps, ", vsync: ", data.vsync_enabled ), 
      context.temp_allocator ) 
  )
  
  data.text.last_draw_calls = data.text.draw_calls
  data.text.draw_calls = 0
}

data_cleanup :: proc()
{
  for &char in data.player_chars
  {
    for p in char.paths_arr
    { delete( p ) }
    clear( &char.paths_arr )
    delete( char.paths_arr )
  }
  for &enemy in data.enemy_chars
  {
    for p in enemy.paths_arr
    { delete( p ) }
    clear( &enemy.paths_arr )
    delete( enemy.paths_arr )
  }

  delete( data.entity_arr )
  delete( data.entity_dead_idx_arr )

  delete( data.mesh_arr )
  delete( data.texture_arr )
  delete( data.material_arr )

  for arr, i in data.tile_ramp_wp_arr
  {
    // fmt.printfln( "data.tile_ramp_wp_arr[%d] len -> %d", i, len(arr) )
    delete( arr )
  }
}


data_entity_remove :: proc( idx: int )
{
  assert( !data.entity_arr[idx].dead, "tried removing dead entity" )
  assert( idx >= 0 && idx < len(data.entity_arr), "invalid entity idx" )

  data.entity_arr[idx].dead = true
  append( &data.entity_dead_idx_arr, idx )
}
data_entity_add :: proc( e: entity_t ) -> ( idx: int )
{
  idx = -1

  if len(data.entity_dead_idx_arr) > 0
  {
    idx = pop(&data.entity_dead_idx_arr)
    data.entity_arr[idx] = e
  }
  else
  {
    idx = len(data.entity_arr)
    append( &data.entity_arr, e )
  }
  
  return idx
}

data_create_map :: proc()
{
  // for z in 0 ..< TILE_ARR_Z_MAX
  for y := 0; y < len(data.tile_str_arr); y += 1
  {
    tile_str := data.tile_str_arr[y]

    for z := TILE_ARR_Z_MAX -1; z >= 0; z -= 1    // reversed so the str aligns with the created map
    {
      for x := TILE_ARR_X_MAX -1; x >= 0; x -= 1  // reversed so the str aligns with the created map
      {
        // data.tile_str_idx := x + (z*TILE_ARR_X_MAX)
        tile_str_idx := ( TILE_ARR_X_MAX * TILE_ARR_Z_MAX ) - ( x + (z*TILE_ARR_X_MAX) +1 ) // reversed idx so the str aligns with the created map

        if tile_str[tile_str_idx] == 'X' ||
           tile_str[tile_str_idx] == 'O' ||
           tile_str[tile_str_idx] == '#'
        {
          mesh_idx := data.mesh_idxs.dirt_cube if tile_str[tile_str_idx] == 'X' else
                      data.mesh_idxs.spring    if tile_str[tile_str_idx] == 'O' else
                      data.mesh_idxs.box       if tile_str[tile_str_idx] == '#' else
                      data.mesh_idxs.sphere
          data.tile_entity_id_arr[y][x][z] = len(data.entity_arr)
          data_entity_add( 
                  entity_t{ pos = util_tile_to_pos( waypoint_t{ level_idx=y, x=x, z=z } ), 
                            rot = { 0, 0, 0 }, scl = { 1, 1, 1 },
                            mesh_idx = mesh_idx, 
                            mat_idx  = y == 1 ? data.material_idxs.dirt_cube_02 : data.material_idxs.dirt_cube_01
                          } )
          
          // if tile_str[tile_str_idx] == 'O'
          // {
          //   append( &data.interactables_arr, interactable_t{ wp=waypoint_t{ level_idx=y, x=x, z=z }, type=Combo_Type.JUMP } )
          // }
          // else if tile_str[tile_str_idx] == '#'
          // {
          //   append( &data.interactables_arr, interactable_t{ wp=waypoint_t{ level_idx=y, x=x, z=z }, type=Combo_Type.BOX } )
          // }
          

          // fmt.println( "idx: ", idx, "pos: ", data.entity_arr[idx].pos, 
          //              " \t| x, z: ", x, z, "MAX: ", TILE_ARR_X_MAX, TILE_ARR_Z_MAX ,
          //              ", ", f32(x) * 2 - f32(TILE_ARR_X_MAX) , f32(z) * 2 - f32(TILE_ARR_Z_MAX))
        }
        else if tile_str[tile_str_idx] == '^' ||
                tile_str[tile_str_idx] == 'v' ||
                tile_str[tile_str_idx] == '<' ||
                tile_str[tile_str_idx] == '>' 
        {
          y_rot : f32 = 0   if tile_str[tile_str_idx] == '^' else 
                        90  if tile_str[tile_str_idx] == '<' else 
                        180 if tile_str[tile_str_idx] == 'v' else 
                        270 if tile_str[tile_str_idx] == '>' else 0 

          data.tile_entity_id_arr[y][x][z]   = len(data.entity_arr)
          append( &data.tile_ramp_wp_arr[y], waypoint_t{ level_idx=y, x=x, z=z } /* len(data.entity_arr) */ )
          data_entity_add( 
                  entity_t{ pos = util_tile_to_pos( waypoint_t{ level_idx=y, x=x, z=z } ), 
                            rot = { 0, y_rot, 0 }, scl = { 1, 1, 1 },
                            mesh_idx = data.mesh_idxs.dirt_ramp, 
                            mat_idx  = y == 1 ? data.material_idxs.dirt_cube_02 : data.material_idxs.dirt_cube_01
                          } )
          // fmt.println( "idx: ", idx, "pos: ", data.entity_arr[idx].pos, 
          //              " \t| x, z: ", x, z, "MAX: ", TILE_ARR_X_MAX, TILE_ARR_Z_MAX ,
          //              ", ", f32(x) * 2 - f32(TILE_ARR_X_MAX) , f32(z) * 2 - f32(TILE_ARR_Z_MAX))
        }
        else if tile_str[tile_str_idx] != '.' 
        { fmt.eprintln("[ERROR] uknown char in tile_str:", rune(tile_str[tile_str_idx]), ", idx:", tile_str_idx ) }
      }
    }
  }

  // populate data.tile_type_arr
  // @TODO: check if this tile is even allowed to be blocked
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
          { data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.EMPTY }
          case 'X':
          {
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.TRAVERSABLE
            if level_idx > 0
            { data.tile_type_arr[level_idx -1][x][z] = Tile_Nav_Type.BLOCKED }
          }
          case 'O':
          {
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.SPRING
          }
          case '#':
          {
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.BOX
          }
          case '^': 
          { 
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.RAMP_FORWARD
            if level_idx > 0
            { data.tile_type_arr[level_idx -1][x][z] = Tile_Nav_Type.BLOCKED }
          }
          case 'v': 
          { 
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.RAMP_BACKWARD
            if level_idx > 0
            { data.tile_type_arr[level_idx -1][x][z] = Tile_Nav_Type.BLOCKED }
          }
          case '<': 
          { 
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.RAMP_LEFT
            if level_idx > 0
            { data.tile_type_arr[level_idx -1][x][z] = Tile_Nav_Type.BLOCKED }
          }
          case '>': 
          {
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.RAMP_RIGHT
            if level_idx > 0
            { data.tile_type_arr[level_idx -1][x][z] = Tile_Nav_Type.BLOCKED }
          }
          case:
          { data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.EMPTY }
        }
      }
    }
  }
// }

}

