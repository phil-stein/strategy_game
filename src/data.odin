package core

import linalg "core:math/linalg/glsl"
import str    "core:strings"
import        "core:fmt"
import        "vendor:glfw"
import gl     "vendor:OpenGL"


WINDOW_TYPE :: enum { MINIMIZED, MAXIMIZED, FULLSCREEN };

texture_t :: struct
{
  handle : u32
}

material_t :: struct
{
  albedo_idx       : int,
  roughness_idx    : int,
  metallic_idx     : int,
  normal_idx       : int,

  tint             : linalg.vec3,
  roughness_f      : f32,
  metallic_f       : f32,

}

mesh_t :: struct
{
  vao:         u32,
  vbo:         u32,
  indices_len: int 
}


entity_t :: struct
{
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

TILE_ARR_X_MAX  :: 10
TILE_ARR_Z_MAX  :: 10
TILE_LEVELS_MAX :: 2
Tile_Nav_Type :: enum
{
  EMPTY,
  BLOCKED,
  TRAVERSABLE,
  // slopes, etc.
}
nav_type_level_arr :: [TILE_ARR_X_MAX][TILE_ARR_Z_MAX]Tile_Nav_Type

character_t :: struct
{
  tile       : waypoint_t,
  entity_idx : int,
}

data_t :: struct
{
  delta_t_real      : f32,
  delta_t           : f32,
  total_t           : f32,
  cur_fps           : f32,
  time_scale        : f32,

  window: glfw.WindowHandle,
  window_width   : int,
  window_height  : int,
  monitor_width  : int,
  monitor_height : int,

  vsync_enabled  : bool,

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

  brdf_lut : u32,

  cubemap : cubemap_t,

  fb_deferred : framebuffer_t,
  fb_lighting : framebuffer_t,

  wireframe_mode_enabled : bool,
  
  mouse_x           : f32,
  mouse_y           : f32,  
  mouse_delta_x     : f32,
  mouse_delta_y     : f32, 

  mouse_sensitivity : f32,

  cam : struct
  {
    pos       : linalg.vec3,
    target    : linalg.vec3,
    pitch_rad : f32, 
    yaw_rad   : f32, 
    view_mat  : linalg.mat4,
    pers_mat  : linalg.mat4,
  },
  
  entity_arr  : [dynamic]entity_t,
  
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
  },
  material_idxs : struct
  {
    default      : int,
    metal_01     : int,
    brick        : int,
    dirt_cube_01 : int,
    dirt_cube_02 : int,
  },
  mesh_idxs : struct
  {
    cube      : int,
    sphere    : int,
    suzanne   : int,
    dirt_cube : int,
  },

  tile_00_str : string,
  tile_01_str : string,

  tile_str_arr  : [TILE_LEVELS_MAX]string,
  tile_type_arr : [TILE_LEVELS_MAX]nav_type_level_arr,

  player_chars : [3]character_t,

}
data : data_t =
{
  delta_t_real      = 0.0,
  delta_t           = 0.0,
  total_t           = 0.0,
  cur_fps           = 0.0,
  time_scale        = 1.0,
  
  wireframe_mode_enabled = false,
  
  mouse_x           = 0.0,
  mouse_y           = 0.0, 
  mouse_delta_x     = 0.0,
  mouse_delta_y     = 0.0, 

  mouse_sensitivity = 0.5,

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

  tile_00_str = 
  "XXXXXXXXXX"+
  "X.XXXX..XX"+
  "XXX.X.XXXX"+
  "X.XXXX...X"+
  "X..XXXXX.X"+
  "X..XXXXX.X"+
  "XXX.XXXX.X"+
  "X.XXXXXXXX"+
  "XXXXX.X..X"+
  "XXXXXXXXXX",
  
  tile_01_str = 
  "XXXXXX..XX"+
  "X..X......"+
  "X.......X."+
  "..XX.....X"+
  "...X...X.X"+
  "...X......"+
  "X.....XX.."+
  "...X...XXX"+
  "XX....X..."+
  "XXXXX.....",
}

data_init :: proc()
{

  data.tile_str_arr[0] = data.tile_00_str
  data.tile_str_arr[1] = data.tile_01_str

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
  


  data.basic_shader          = shader_make( #load( "../assets/shaders/basic.vert", string ), 
                                            #load( "../assets/shaders/basic.frag", string ), "basic_shader" )

  data.quad_shader           = shader_make( #load( "../assets/shaders/quad.vert", string ), 
                                            #load( "../assets/shaders/quad.frag", string ), "quad_shader" )

  data.deferred_shader       = shader_make( #load( "../assets/shaders/basic.vert",    string ), 
                                            #load( "../assets/shaders/deferred.frag", string ), "deferred_shader" )
  
  data.lighting_shader       = shader_make( #load( "../assets/shaders/screen.vert", string ), 
                                            #load( "../assets/shaders/pbr.frag",    string ), "lighting_shader" )

  data.post_fx_shader        = shader_make( #load( "../assets/shaders/screen.vert",  string ), 
                                            #load( "../assets/shaders/post_fx.frag", string ), "post_fx_shader" )

  data.skybox_shader         = shader_make( #load( "../assets/shaders/cubemap/cube_map.vert",  string ), 
                                            #load( "../assets/shaders/cubemap/cube_map.frag", string ), "skybox_shader" )

  data.brdf_lut_shader       = shader_make( #load( "../assets/shaders/cubemap/brdf_lut.vert", string ), 
                                            #load( "../assets/shaders/cubemap/brdf_lut.frag", string ))

  data.equirect_shader       = shader_make( #load( "../assets/shaders/cubemap/render_equirect.vert", string ), 
                                            #load( "../assets/shaders/cubemap/render_equirect.frag", string ))
 
  data.irradiance_map_shader = shader_make( #load( "../assets/shaders/cubemap/render_equirect.vert", string ), 
                                            #load( "../assets/shaders/cubemap/irradiance_map.frag", string ))
 
  data.prefilter_shader      = shader_make( #load( "../assets/shaders/cubemap/render_equirect.vert", string ), 
                                            #load( "../assets/shaders/cubemap/prefilter_map.frag", string ))
   
  data.fb_deferred = framebuffer_create_gbuffer( 1 ) 
  data.fb_lighting = framebuffer_create_hdr()

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
  
  window_set_title( str.clone_to_cstring( fmt.tprint( "amazing title | fps: ", data.cur_fps, ", vsync: ", data.vsync_enabled ) ) )
}

data_post_update :: proc()
{
  data.mouse_delta_x = 0.0
  data.mouse_delta_y = 0.0
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

        if tile_str[tile_str_idx] == 'X'
        {
          // idx := len(data.entity_arr)
          // append( &data.entity_arr, 
          //         entity_t{ pos = { f32(x) * 2 - f32(TILE_ARR_X_MAX) +1, 
          //                           f32(y) * 2, 
          //                           f32(z) * 2 - f32(TILE_ARR_Z_MAX) +1
          //                         }, 
          //                   rot = { 0, 0, 0 }, scl = { 1, 1, 1 },
          //                   mesh_idx = data.mesh_idxs.cube, 
          //                   mat_idx  = data.material_idxs.brick 
          //                 } )
          append( &data.entity_arr, 
                  entity_t{ pos = { f32(x) * 2 - f32(TILE_ARR_X_MAX) +1, 
                                    f32(y) * 2, 
                                    f32(z) * 2 - f32(TILE_ARR_Z_MAX) +1
                                  }, 
                            rot = { 0, 0, 0 }, scl = { 1, 1, 1 },
                            mesh_idx = data.mesh_idxs.dirt_cube, 
                            mat_idx  = y == 1 ? data.material_idxs.dirt_cube_02 : data.material_idxs.dirt_cube_01
                          } )
          // fmt.println( "idx: ", idx, "pos: ", data.entity_arr[idx].pos, 
          //              " \t| x, z: ", x, z, "MAX: ", TILE_ARR_X_MAX, TILE_ARR_Z_MAX ,
          //              ", ", f32(x) * 2 - f32(TILE_ARR_X_MAX) , f32(z) * 2 - f32(TILE_ARR_Z_MAX))
        }
      }
    }
  }


  // populate data.tile_type_arr
// // game_build_nav_struct :: proc( /* num_levels: int, levels: []string */ ) -> ( nav: [len(data.tile_str_arr)]nav_type_level_arr )
// data_build_nav_struct :: proc(  )
// {
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
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.EMPTY
          case 'X':
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.TRAVERSABLE
            if level_idx > 0
            {
              data.tile_type_arr[level_idx -1][x][z] = Tile_Nav_Type.BLOCKED
            }
          case:
            data.tile_type_arr[level_idx][x][z] = Tile_Nav_Type.EMPTY
        }
      }
    }
  }
// }

}

