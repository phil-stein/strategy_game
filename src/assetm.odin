package core

import        "core:fmt"
import str    "core:strings"
import linalg "core:math/linalg/glsl"
import        "core:time"
import        "core:log"

assetm_init :: proc()
{

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

  data.mouse_pick_shader     = shader_make( #load( "../assets/shaders/basic.vert",         string ), 
                                            #load( "../assets/shaders/mouse_picking.frag", string ))
   
  data.fb_deferred   = framebuffer_create_gbuffer( 1 ) 
  data.fb_lighting   = framebuffer_create_hdr()
  data.fb_outline    = framebuffer_create_single_channel_f( 1 )
  data.fb_mouse_pick = framebuffer_create_single_channel_f( 4 ) // @TODO: use size_divisor


  // // blank_tex_srgb  := make_texture( "assets/blank.png", true )
  // blank_tex       := make_texture( "assets/blank.png", false )
  // // black_blank_tex := make_texture( "assets/blank_black.png", false )
  // blank_tex_idx := assetm_load_texture( "blank.png", false )
  
  data.texture_idxs.blank = assetio_load_texture( "blank.png", true )

  cube_mat  := material_t{ 
                 albedo_idx    = data.texture_idxs.blank, 
                 roughness_idx = data.texture_idxs.blank, 
                 metallic_idx  = data.texture_idxs.blank, 
                 normal_idx    = data.texture_idxs.blank, 

                 uv_tile       = linalg.vec2{ 1, 1 },
                 uv_offs       = linalg.vec2{ 0, 0 },

                 tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
                 // tint        = linalg.vec3{ 0.4, 1.0, 0.2 },
                 roughness_f = 0.75,
                 metallic_f  = 0.0,
               }
  data.material_idxs.default = assetm_add_material( cube_mat, "default" )

  suzanne_mat  := material_t{ 
           albedo_idx    = data.texture_idxs.blank, 
           roughness_idx = data.texture_idxs.blank, 
           metallic_idx  = data.texture_idxs.blank, 
           normal_idx    = data.texture_idxs.blank, 

           uv_tile       = linalg.vec2{ 1, 1 },
           uv_offs       = linalg.vec2{ 0, 0 },

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 0.25,
           metallic_f  = 1.0,
         }
  data.material_idxs.metal_01 = assetm_add_material( suzanne_mat, "metal_mat" )


  debug_timer_static_start( "water-textures" )
  data.texture_idxs.water_albedo    = assetio_load_texture( "water/albedo.png", true )
  data.texture_idxs.water_normal    = assetio_load_texture( "water/normal.png", false )
  // data.texture_idxs.water_roughness = assetio_load_texture( "water/specular.png", false )
  data.texture_idxs.water_roughness = assetio_load_texture( "water/roughness.png", false )
  debug_timer_stop()
  water_mat  := material_t{ 
           albedo_idx    = data.texture_idxs.water_albedo, 
           roughness_idx = data.texture_idxs.water_roughness, 
           metallic_idx  = data.texture_idxs.blank, 
           normal_idx    = data.texture_idxs.water_normal, 

           uv_tile       = linalg.vec2{ 15, 15 },
           uv_offs       = linalg.vec2{ 0,   0 },

           tint        = linalg.vec3{ 0.17, 1.0, 0.625 },
           roughness_f = 1.0,
           metallic_f  = 0.0,
  }
  data.material_idxs.water = assetm_add_material( water_mat, "water_mat" )


  debug_timer_static_start( "brick-textures" )
  data.texture_idxs.brick_albedo    = assetio_load_texture( "brick/albedo.png", true )
  data.texture_idxs.brick_normal    = assetio_load_texture( "brick/normal.png", false )
  data.texture_idxs.brick_roughness = assetio_load_texture( "brick/roughness.png", false )
  debug_timer_stop()

  brick_mat  := material_t{ 
           albedo_idx    = data.texture_idxs.brick_albedo, 
           roughness_idx = data.texture_idxs.brick_roughness, 
           metallic_idx  = data.texture_idxs.blank, 
           normal_idx    = data.texture_idxs.brick_normal, 

           uv_tile       = linalg.vec2{ 1, 1 },
           uv_offs       = linalg.vec2{ 0, 0 },

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 1.0,
           metallic_f  = 0.0,
         }
  data.material_idxs.brick = assetm_add_material( brick_mat, "brick_mat" )

  data.texture_idxs.dirt_cube_01_albedo = assetio_load_texture( "dirt_path_sphax_01.png", true, [3]f32{ 1.3, 1.15, 1 }  )
  data.texture_idxs.dirt_cube_02_albedo = assetio_load_texture( "dirt_path_sphax_02.png", true, [3]f32{ 1.3, 1.15, 1 }  )

  dirt_cube_mat  := material_t{ 
           albedo_idx    = data.texture_idxs.dirt_cube_01_albedo, 
           roughness_idx = data.texture_idxs.blank, 
           metallic_idx  = data.texture_idxs.blank, 
           normal_idx    = data.texture_idxs.blank, 

           uv_tile       = linalg.vec2{ 1, 1 },
           uv_offs       = linalg.vec2{ 0, 0 },

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 1.0,
           metallic_f  = 0.0,
         }
  data.material_idxs.dirt_cube_01 = assetm_add_material( dirt_cube_mat, "dirt_cube_mat_00" )
  dirt_cube_mat.albedo_idx = data.texture_idxs.dirt_cube_02_albedo
  data.material_idxs.dirt_cube_02 = assetm_add_material( dirt_cube_mat, "dirt_cube_mat_01" )

  // time.stopwatch_start( &stopwatch )
  debug_timer_static_start( "robot-textures" )
  data.texture_idxs.robot_albedo    = assetio_load_texture( "robot_character_06/albedo.png", true )
  data.texture_idxs.robot_normal    = assetio_load_texture( "robot_character_06/normal.png", false )
  data.texture_idxs.robot_metallic  = assetio_load_texture( "robot_character_06/metallic.png", false )
  data.texture_idxs.robot_roughness = assetio_load_texture( "robot_character_06/roughness.png", false )
  debug_timer_stop()
  // time.stopwatch_stop( &stopwatch )
  // log.info( "TIMER: robot-textures: ", stopwatch._accumulation )
  robot_mat := material_t{ 
           albedo_idx    = data.texture_idxs.robot_albedo, 
           roughness_idx = data.texture_idxs.robot_roughness, 
           metallic_idx  = data.texture_idxs.robot_metallic, 
           normal_idx    = data.texture_idxs.robot_normal, 

           uv_tile       = linalg.vec2{ 1, 1 },
           uv_offs       = linalg.vec2{ 0, 0 },

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 1.0,
           metallic_f  = 1.0,
         }
  data.material_idxs.robot = assetm_add_material( robot_mat, "robot_char" )

  // time.stopwatch_reset( &stopwatch )
  // time.stopwatch_start( &stopwatch )
  debug_timer_static_start( "female-textures" )
  data.texture_idxs.female_albedo    = assetio_load_texture( "female_char_01/albedo.png", true )
  data.texture_idxs.female_normal    = assetio_load_texture( "female_char_01/normal.png", false )
  data.texture_idxs.female_metallic  = assetio_load_texture( "female_char_01/metallic.png", false )
  data.texture_idxs.female_roughness = assetio_load_texture( "female_char_01/roughness.png", false )
  debug_timer_stop()
  // time.stopwatch_stop( &stopwatch )
  // log.info( "TIMER: female-textures: ", stopwatch._accumulation )
  // time.stopwatch_reset( &stopwatch )
  female_char := material_t{ 
           albedo_idx    = data.texture_idxs.female_albedo, 
           roughness_idx = data.texture_idxs.female_roughness, 
           metallic_idx  = data.texture_idxs.female_metallic, 
           normal_idx    = data.texture_idxs.female_normal, 

           uv_tile       = linalg.vec2{ 1, 1 },
           uv_offs       = linalg.vec2{ 0, 0 },

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 1.0,
           metallic_f  = 1.0,
         }
  data.material_idxs.female = assetm_add_material( female_char, "female_char" )

  debug_timer_static_start( "demon-textures" )
  data.texture_idxs.demon_albedo    = assetio_load_texture( "demon02/albedo.png", true )
  data.texture_idxs.demon_normal    = assetio_load_texture( "demon02/normal.png", false )
  data.texture_idxs.demon_metallic  = assetio_load_texture( "demon02/metallic.png", false )
  data.texture_idxs.demon_roughness = assetio_load_texture( "demon02/roughness.png", false )
  debug_timer_stop()
  demon_char := material_t{ 
           albedo_idx    = data.texture_idxs.demon_albedo, 
           roughness_idx = data.texture_idxs.demon_roughness, 
           metallic_idx  = data.texture_idxs.demon_metallic, 
           normal_idx    = data.texture_idxs.demon_normal, 

           uv_tile       = linalg.vec2{ 1, 1 },
           uv_offs       = linalg.vec2{ 0, 0 },

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 1.0,
           metallic_f  = 1.0,
         }
  data.material_idxs.demon = assetm_add_material( demon_char, "demon_char" )
  
  // ---- mesh ----

  debug_timer_static_start( "loading meshes" )
  data.mesh_idxs.icon_jump   = assetio_load_mesh( "icon_jump.fbx" ) 
  data.mesh_idxs.icon_attack = assetio_load_mesh( "icon_attack.fbx" ) 
  
  data.mesh_idxs.quad        = assetio_load_mesh( "quad.fbx" )
  data.mesh_idxs.cube        = assetio_load_mesh( "cube.fbx" )
  data.mesh_idxs.sphere      = assetio_load_mesh( "sphere.fbx" ) 
  data.mesh_idxs.suzanne     = assetio_load_mesh( "suzanne_02.fbx" )
  data.mesh_idxs.dirt_cube   = assetio_load_mesh( "dirt_cube.fbx" )
  data.mesh_idxs.dirt_ramp   = assetio_load_mesh( "dirt_ramp.fbx" )
  data.mesh_idxs.robot_char  = assetio_load_mesh( "robot_character_06_01.fbx" )
  data.mesh_idxs.female_char = assetio_load_mesh( "female_char_01_01.fbx" )
  data.mesh_idxs.spring      = assetio_load_mesh( "spring_01.fbx" )
  data.mesh_idxs.demon_char  = assetio_load_mesh( "demon02.fbx" )
  // data.mesh_idxs.skeleton      = assetio_load_mesh( "demon02_chains.fbx" )
  data.mesh_idxs.box         = assetio_load_mesh( "box_01.fbx" )
  debug_timer_stop()
}
assetm_cleanup :: proc()
{
  when ODIN_DEBUG
  {
    for i in 0 ..< len(data.texture_arr)
    {
      delete( data.texture_arr[i].name )
    }
    for i in 0 ..< len(data.material_arr)
    {
      delete( data.material_arr[i].name )
    }
    for i in 0 ..< len(data.mesh_arr)
    {
      delete( data.mesh_arr[i].name )
    }
  }
}


assetm_get_texture :: #force_inline proc( idx: int ) -> ( tex: ^texture_t )
{
  return &data.texture_arr[idx]
}

assetm_add_material :: #force_inline proc( mat: material_t, name: string ) -> ( idx: int )
{
  idx = len( data.material_arr )
  append( &data.material_arr, mat )
  
  when ODIN_DEBUG
  { data.material_arr[idx].name = str.clone( name ) }

  return 
}

assetm_get_material :: #force_inline proc( idx: int ) -> ( tex: ^material_t )
{
  return &data.material_arr[idx]
}

assetm_get_mesh :: #force_inline proc( idx: int ) -> ( tex: ^mesh_t )
{
  return &data.mesh_arr[idx]
}
