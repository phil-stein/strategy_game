package core

import str "core:strings"
import linalg "core:math/linalg/glsl"


assetm_init :: proc()
{

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
           metallic_f  = 0.1,
         }
  // brick_mat_idx := assetm_add_material( brick_mat )
  data.material_idxs.brick = assetm_add_material( brick_mat )

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
  
  data.mesh_idxs.cube    = assetm_load_mesh( "cube.fbx" )
  // = mesh_load_fbx( "assets/sphere.fbx" ), 
  data.mesh_idxs.suzanne = assetm_load_mesh( "suzanne_02.fbx" )
}


assetm_load_texture :: #force_inline proc( name: string, srgb: bool ) -> ( idx: int )
{
  tex : texture_t
  tex.handle = make_texture( str.concatenate( []string{ "assets/", name} ), srgb )
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
  path_cstr := str.clone_to_cstring( str.concatenate( []string{ "assets/", name} ) )
  m := mesh_load_fbx( path_cstr )
  idx = len( data.mesh_arr )
  append( &data.mesh_arr, m)

  return 
}

assetm_get_mesh :: #force_inline proc( idx: int ) -> ( tex: ^mesh_t )
{
  return &data.mesh_arr[idx]
}
