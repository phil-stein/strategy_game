package core

import        "core:fmt"
import str    "core:strings"
import linalg "core:math/linalg/glsl"


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
   
  data.fb_deferred = framebuffer_create_gbuffer( 1 ) 
  data.fb_lighting = framebuffer_create_hdr()


  // // blank_tex_srgb  := make_texture( "assets/blank.png", true )
  // blank_tex       := make_texture( "assets/blank.png", false )
  // // black_blank_tex := make_texture( "assets/blank_black.png", false )
  // blank_tex_idx := assetm_load_texture( "blank.png", false )
  data.texture_idxs.blank = assetm_load_texture( "blank.png", false )

  cube_mat  := material_t{ 
                 albedo_idx    = data.texture_idxs.blank, 
                 roughness_idx = data.texture_idxs.blank, 
                 metallic_idx  = data.texture_idxs.blank, 
                 normal_idx    = data.texture_idxs.blank, 

                 tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
                 // tint        = linalg.vec3{ 0.4, 1.0, 0.2 },
                 roughness_f = 0.75,
                 metallic_f  = 0.0,
               }
  data.material_idxs.default = assetm_add_material( cube_mat )

  suzanne_mat  := material_t{ 
           albedo_idx    = data.texture_idxs.blank, 
           roughness_idx = data.texture_idxs.blank, 
           metallic_idx  = data.texture_idxs.blank, 
           normal_idx    = data.texture_idxs.blank, 

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 0.25,
           metallic_f  = 1.0,
         }
  // suzanne_mat_idx := assetm_add_material( suzanne_mat )
  data.material_idxs.metal_01 = assetm_add_material( suzanne_mat )


  data.texture_idxs.brick_albedo    = assetm_load_texture( "brick/albedo.png", false )
  data.texture_idxs.brick_normal    = assetm_load_texture( "brick/normal.png", false )
  data.texture_idxs.brick_roughness = assetm_load_texture( "brick/roughness.png", false )

  brick_mat  := material_t{ 
           albedo_idx    = data.texture_idxs.brick_albedo, 
           roughness_idx = data.texture_idxs.brick_roughness, 
           metallic_idx  = data.texture_idxs.blank, 
           normal_idx    = data.texture_idxs.brick_normal, 

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 1.0,
           metallic_f  = 0.0,
         }
  // brick_mat_idx := assetm_add_material( brick_mat )
  data.material_idxs.brick = assetm_add_material( brick_mat )

  data.texture_idxs.dirt_cube_01_albedo = assetm_load_texture( "dirt_path_sphax_01.png", false )
  data.texture_idxs.dirt_cube_02_albedo = assetm_load_texture( "dirt_path_sphax_02.png", false )

  dirt_cube_mat  := material_t{ 
           albedo_idx    = data.texture_idxs.dirt_cube_01_albedo, 
           roughness_idx = data.texture_idxs.blank, 
           metallic_idx  = data.texture_idxs.blank, 
           normal_idx    = data.texture_idxs.blank, 

           tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
           roughness_f = 1.0,
           metallic_f  = 0.0,
         }
  // brick_mat_idx := assetm_add_material( brick_mat )
  data.material_idxs.dirt_cube_01 = assetm_add_material( dirt_cube_mat )
  dirt_cube_mat.albedo_idx = data.texture_idxs.dirt_cube_02_albedo
  data.material_idxs.dirt_cube_02 = assetm_add_material( dirt_cube_mat )

  // sphere_idx := len(data.entity_arr)
  // append( &data.entity_arr, entity_t{ pos = {  2, 2, 0 }, rot = { 0, 0, 0 }, scl = { 1, 1, 1 },
  //                                     mesh = mesh_load_fbx( "assets/sphere.fbx" ), 
  //                                     mat  = { 
  //                                              albedo    = make_texture( "assets/brick/albedo.png",    true ), 
  //                                              roughness = make_texture( "assets/brick/roughness.png", false ), 
  //                                              metallic  = blank_tex, 
  //                                              normal    = make_texture( "assets/brick/normal.png",    false ), 
  //
  //                                              tint        = linalg.vec3{ 1.0, 1.0, 1.0 },
  //                                              roughness_f = 1.0,
  //                                              metallic_f  = 0.0,
  //                                            },
  //                                   } )
  
  data.mesh_idxs.cube      = assetm_load_mesh( "cube.fbx" )
  data.mesh_idxs.sphere    = assetm_load_mesh( "sphere.fbx" ) 
  data.mesh_idxs.suzanne   = assetm_load_mesh( "suzanne_02.fbx" )
  data.mesh_idxs.dirt_cube = assetm_load_mesh( "dirt_cube.fbx" )
}


assetm_load_texture :: #force_inline proc( name: string, srgb: bool ) -> ( idx: int )
{
  tex : texture_t
  tex.handle = make_texture( str.concatenate( []string{ "assets/textures/", name} ), srgb )
  idx = len( data.texture_arr )
  append( &data.texture_arr, tex )

  return 
}

assetm_get_texture :: #force_inline proc( idx: int ) -> ( tex: ^texture_t )
{
  return &data.texture_arr[idx]
}

// assetm_add_material :: proc( albedo_idx : int, roughness_idx : int, metallic_idx : int, normal_idx : int, tint : linalg.vec3, roughness_f : f32, metallic_f : f32 )
assetm_add_material :: #force_inline proc( mat: material_t ) -> ( idx: int )
{
  idx = len( data.material_arr )
  append( &data.material_arr, mat )

  return 
}

assetm_get_material :: #force_inline proc( idx: int ) -> ( tex: ^material_t )
{
  return &data.material_arr[idx]
}

assetm_load_mesh :: #force_inline proc( name: string ) -> ( idx: int )
{
  path_cstr := str.clone_to_cstring( str.concatenate( []string{ "assets/meshes/", name} ) )
  // fmt.println( "path: ", path_cstr )
  m := mesh_load_fbx( path_cstr )
  idx = len( data.mesh_arr )
  append( &data.mesh_arr, m)

  return 
}

assetm_get_mesh :: #force_inline proc( idx: int ) -> ( tex: ^mesh_t )
{
  return &data.mesh_arr[idx]
}
