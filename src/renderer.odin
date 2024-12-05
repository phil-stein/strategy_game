package core

import        "core:log"
import        "core:math"
import linalg "core:math/linalg/glsl"
import gl     "vendor:OpenGL"


exposure  :: 1.25


renderer_init :: proc()
{
  gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )
  gl.Viewport( 0, 0, i32(data.window_width), i32(data.window_height) )
  gl.Enable( gl.DEPTH_TEST )
  gl.Disable( gl.BLEND ) // enable blending of transparent texture
  // gl.FrontFace( gl.CCW )
  gl.Enable( gl.CULL_FACE )
  gl.CullFace( gl.FRONT )

  gl.Enable( gl.TEXTURE_CUBE_MAP_SEAMLESS )
  

  gl.ClearColor( 0.0, 0.0, 0.0, 1.0 )

}

renderer_update :: proc()
{
  // -- draw meshes --
  camera_set_view_mat() 

  { // deferred
    framebuffer_bind( &data.fb_deferred )
    gl.Clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
    gl.Enable( gl.DEPTH_TEST )
    gl.Enable( gl.TEXTURE_CUBE_MAP_SEAMLESS )
    gl.Disable( gl.BLEND ) // enable blending of transparent texture

    gl.Enable( gl.CULL_FACE )
    gl.CullFace( gl.BACK )

    // wireframe mode
    if ( data.wireframe_mode_enabled == true )
	  { 
      gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE) 
      gl.LineWidth( 3 )
    }
	  else
	  { gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL) }

    shader_use( data.deferred_shader )
    for &e, idx in data.entity_arr
    {
      if e.dead { continue }
      // fmt.println( "#### rendering entity[", idx, "] ####" )

      mesh := assetm_get_mesh( e.mesh_idx )

  
      e.model = util_make_model( e.pos, e.rot, e.scl )
      // @TODO:
      // e.inv_model = linalg.inverse( e.model )
      shader_act_set_mat4( "model", &e.model[0][0] )
      shader_act_set_mat4( "view",  &data.cam.view_mat[0][0] )
      shader_act_set_mat4( "proj",  &data.cam.pers_mat[0][0] )

      mat := assetm_get_material( e.mat_idx )
     
      shader_act_bind_texture( "albedo",    assetm_get_texture( mat.albedo_idx ).handle )
      shader_act_bind_texture( "roughness", assetm_get_texture( mat.roughness_idx ).handle )
      shader_act_bind_texture( "metallic",  assetm_get_texture( mat.metallic_idx ).handle )
      shader_act_bind_texture( "norm",      assetm_get_texture( mat.normal_idx ).handle )
      // shader_act_bind_texture( "emissive", e.mat.emissive )
      shader_act_set_vec3( "tint",        mat.tint )
      shader_act_set_f32(  "roughness_f", mat.roughness_f )
      shader_act_set_f32(  "metallic_f",  mat.metallic_f )
      // shader_act_set_f32(  "emissive_f",  e.mat.emissive_f )
      
      // shader_act_set_vec2_f( "uv_tile", 1.0, 1.0 )
      // shader_act_set_vec2_f( "uv_offs", 0.0, 0.0 )
      shader_act_set_vec2( "uv_tile", mat.uv_tile )
      shader_act_set_vec2( "uv_offs", mat.uv_offs )


      gl.BindVertexArray( mesh.vao )
      gl.DrawElements( gl.TRIANGLES,             // Draw triangles.
                       i32(mesh.indices_len),  // indices length
                       gl.UNSIGNED_INT,          // Data type of the indices.
                       rawptr(uintptr(0)) )      // Pointer to indices. (Not needed.)

      shader_act_reset_tex_idx()
    }

    if ( data.wireframe_mode_enabled == true )
	  { gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL) }

    // skybox -----------------------------------------------------------------
    gl.DepthFunc(gl.LEQUAL);  // change depth function so depth test passes when values are equal to depth buffer's content

    shader_use( data.skybox_shader )
    view_no_pos := data.cam.view_mat
    // view_no_pos[3][0] = 0.0 
    // view_no_pos[3][1] = 0.0 
    // view_no_pos[3][2] = 0.0 
    util_model_set_pos( &view_no_pos, linalg.vec3{ 0.0, 0.0, 0.0 } )
    shader_act_set_mat4( "view", &view_no_pos[0][0] )
    shader_act_set_mat4( "proj", &data.cam.pers_mat[0][0] )

    // skybox cube
    gl.BindVertexArray(data.skybox_vao);
    shader_act_bind_cube_map( "cube_map", data.cubemap.environment )
    gl.DrawArrays(gl.TRIANGLES, 0, 36);
    gl.BindVertexArray(0);
    gl.DepthFunc(gl.LESS); // set depth function back to default
    framebuffer_unbind()
  }

  { // lighting pass
    
    framebuffer_bind( &data.fb_lighting )
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.Disable(gl.DEPTH_TEST);
  
    shader_use( data.lighting_shader )

    shader_act_set_vec3( "view_pos", data.cam.pos )
    shader_act_set_f32( "cube_map_intensity", data.cubemap.intensity )

    shader_act_bind_cube_map("irradiance_map", data.cubemap.irradiance )
    shader_act_bind_cube_map("prefilter_map", data.cubemap.prefilter )
    shader_act_bind_texture("brdf_lut", data.brdf_lut )

    shader_act_bind_texture("color", data.fb_deferred.buffer01 )
    shader_act_bind_texture("material", data.fb_deferred.buffer02 )
    shader_act_bind_texture("normal", data.fb_deferred.buffer03 )
    shader_act_bind_texture("position", data.fb_deferred.buffer04 )
    // @TODO: shadow

    // -- set lights --
    shader_act_set_i32( "dir_lights_len", 1 )
    shader_act_set_vec3_f( "dir_lights[0].direction", 1.0, 1.0, 0.0 )
    shader_act_set_vec3_f( "dir_lights[0].color",     1.0,  1.0, 1.0 )

    shader_act_set_i32( "point_lights_len", 0 )
    // ...
    
    gl.BindVertexArray(data.quad_vao);
    gl.DrawArrays(gl.TRIANGLES, 0, 6);
    gl.Enable(gl.DEPTH_TEST);
    gl.Enable( gl.CULL_FACE )
    framebuffer_unbind()
  }

  { // outline
    if data.player_chars_current >= 0
    { renderer_draw_scene_outline( data.player_chars[data.player_chars_current].entity_idx ) }
  }

  { // post fx
    shader_use( data.post_fx_shader )

    gl.Clear(gl.COLOR_BUFFER_BIT);
    gl.Disable(gl.DEPTH_TEST);
    gl.Disable( gl.CULL_FACE )

    shader_act_set_f32( "exposure", exposure )
    
    shader_act_bind_texture( "tex", data.fb_lighting.buffer01 )
    shader_act_bind_texture( "position", data.fb_deferred.buffer04 )
    // shader_act_bind_texture( "water_tex", data.texture_arr[data.texture_idxs.brick_albedo].handle )

    if data.player_chars_current >= 0
    { 
      shader_act_bind_texture( "outline", data.fb_outline.buffer01 )
      shader_act_set_vec3( "outline_color", data.player_chars[data.player_chars_current].color )
    }
    

    gl.BindVertexArray(data.quad_vao);
    gl.DrawArrays(gl.TRIANGLES, 0, 6);
    gl.Enable(gl.DEPTH_TEST);
    gl.Enable( gl.CULL_FACE )
  }
}

renderer_draw_quad :: proc( pos, scl: linalg.vec2, texture_handle: u32 )
{
  gl.Disable( gl.CULL_FACE )
  gl.Disable( gl.DEPTH_TEST)

  // -- draw triangle --
  // gl.UseProgram( data.quad_shader )
  shader_use( data.quad_shader )
  gl.BindVertexArray( data.quad_vao )
  // gl.Uniform2f( gl.GetUniformLocation(data.quad_shader, "pos"), pos.x, pos.y )
  // gl.Uniform2f( gl.GetUniformLocation(data.quad_shader, "scl"), scl.x, scl.y )
  shader_act_set_vec2( "pos", pos )
  shader_act_set_vec2( "scl", scl )
  
  gl.ActiveTexture( gl.TEXTURE0 )
  gl.BindTexture( gl.TEXTURE_2D, texture_handle )
  // gl.Uniform1i( gl.GetUniformLocation(data.quad_shader, "tex"), 0 )
  shader_act_set_i32( "tex", 0 )

  gl.DrawArrays( gl.TRIANGLES,    // Draw triangles.
                 0,               // Begin drawing at index 0.
                 6 )              // Use 3 indices.

  gl.Enable( gl.CULL_FACE )
  gl.Enable( gl.DEPTH_TEST)
}

renderer_draw_scene_outline :: proc( entity_idx: int )
{
  // @OPTIMIZATION: only clear buffer when deselecting
  gl.ClearColor( 0.0, 0.0, 0.0, 0.0 )
  w, h := window_get_size()
  gl.Viewport( 0, 0, i32(w), i32(h) )
  framebuffer_bind( &data.fb_outline )
  gl.Clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT ) // clear bg
  
  // draw in solid-mode for fbo
	if data.wireframe_mode_enabled == true
	{ gl.PolygonMode( gl.FRONT_AND_BACK, gl.FILL ) }
  
  e := &data.entity_arr[entity_idx]
  if e.dead { log.error( "entity_idx passed to renderer_draw_scene_outline() invalid:", entity_idx ) } 

  // mesh
  // mesh = assetm_get_mesh_by_idx(e->mesh); // [m]
  // renderer_direct_draw_mesh_textured_mat(e->model, mesh, tex, RGB_F_RGB(1));
  gl.Disable( gl.BLEND )
  gl.Enable( gl.CULL_FACE )

	// ---- shader & draw call -----	

	shader_use( data.basic_shader )
	// gl.ActiveTexture( gl.TEXTURE0 )
	// gl.BindTexture( gl.TEXTURE_2D, assetm_get_texture( data.texture_idxs.blank ).handle ) 
	// shader_act_set_int( "tex", 0 )
	shader_act_bind_texture( "tex", assetm_get_texture( data.texture_idxs.blank ).handle )
	shader_act_set_vec3( "tint", linalg.vec3{ 1, 1, 1 } )
	
	shader_act_set_mat4( "model", &e.model[0][0] )
	shader_act_set_mat4( "view",  &data.cam.view_mat[0][0] )
	shader_act_set_mat4( "proj",  &data.cam.pers_mat[0][0] )

  mesh := assetm_get_mesh( e.mesh_idx )
  gl.BindVertexArray( mesh.vao )
  gl.DrawElements( gl.TRIANGLES,             // Draw triangles.
                   i32(mesh.indices_len),  // indices length
                   gl.UNSIGNED_INT,          // Data type of the indices.
                   rawptr(uintptr(0)) )      // Pointer to indices. (Not needed.)

  
	// reset if wireframe-mode
  if data.wireframe_mode_enabled == true
	{ gl.PolygonMode( gl.FRONT_AND_BACK, gl.LINE ) }
	
	framebuffer_unbind()
}
