package core

// import        "core:fmt"
import        "core:log"
import        "core:c"
import        "core:math"
import linalg "core:math/linalg/glsl"
// import        "vendor:glfw"
import gl     "vendor:OpenGL"
// import        "core:image"
// import        "core:image/png"
import stbi   "vendor:stb/image"


cubemap_load :: proc( buf: [^]byte, buf_len: int ) -> ( cm: cubemap_t)
{



  // @BUGG: @OPTIMIZATION: reloading cubemap adds a lot of memory
  // if (core_data->cube_map.loaded) { cubemap_free(); }

  // fix seams betweencubemap faces
  // this shoud be activated in renderer
  gl.Enable( gl.TEXTURE_CUBE_MAP_SEAMLESS )
  
  // load hdr image ----------------------------------------------------------------------
 
//   void*  buf = NULL;
//   size_t buf_len = 0;
//   char _path[ASSET_PATH_MAX +64];
//   int len = 0;
//   SPRINTF(ASSET_PATH_MAX + 64, _path, "%stextures/%s", core_data->asset_path, path);
//   buf = (void*)file_io_read_len(_path, &len);
//   buf_len = (size_t)len;
//   ERR_CHECK(buf != NULL || buf_len != 0, "cubemap_hdr '%s' requested in cubemap_load(), doesn't exist in the asset folder.\n -> [FILE] '%s', [LINE] %d", path, _file, _line);

  stbi.set_flip_vertically_on_load( 0 )
  width, height, channels : c.int
  img_data := stbi.loadf_from_memory( buf, c.int(buf_len), &width, &height, &channels, 0 )
  hdr_texture : u32
  if img_data != nil
  {
    gl.GenTextures( 1, &hdr_texture )
    gl.BindTexture( gl.TEXTURE_2D, hdr_texture )
    gl.TexImage2D( gl.TEXTURE_2D, 0, gl.RGB16F, width, height, 0, gl.RGB, gl.FLOAT, img_data ) 

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    stbi.image_free( img_data )
  }
  else
  { log.errorf( "failed to load HDR image\n" ) }

  // gen framebuffer ---------------------------------------------------------------------
    
  capture_fbo, capture_rbo : u32
  gl.GenFramebuffers( 1, &capture_fbo )
  gl.GenRenderbuffers( 1, &capture_rbo )

  gl.BindFramebuffer( gl.FRAMEBUFFER, capture_fbo )
  gl.BindRenderbuffer( gl.RENDERBUFFER, capture_rbo )
  gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, 512, 512 )
  gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, capture_fbo )

  // gen cubemap -------------------------------------------------------------------------
 
  // @TODO: clear cubemap ???

  cubemap : u32
  gl.GenTextures( 1, &cubemap )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, cubemap )
  // for (u32 i = 0; i < 6; ++i)
  for i in 0..<6
  {
    // note that we store each face with 16 bit floating point values
    gl.TexImage2D( u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i), 0, gl.RGB16F, 
                   512, 512, 0, gl.RGB, gl.FLOAT, nil )
  }
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S,     gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T,     gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R,     gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR )
  
  // render cubemap ----------------------------------------------------------------------
 
  // mesh_t* cube_mesh = assetm_get_mesh("cube");
  // cube_mesh := mesh_load_fbx( "assets/cube.fbx" )
  cube_mesh := assetm_get_mesh( data.mesh_idxs.cube )

  proj : linalg.mat4
  pers : f32 = 90.0
  pers = math.to_radians( pers )
  proj = linalg.mat4Perspective( pers, 1.0, 0.1, 10.0 )
  // mat4 view_mats[6]; 
  view_mats : [6]linalg.mat4
  view_mats[0] = linalg.mat4LookAt( linalg.vec3{ 0.0, 0.0, 0.0 }, linalg.vec3{  1.0,  0.0,  0.0 }, linalg.vec3{ 0.0, -1.0,  0.0 } )
  view_mats[1] = linalg.mat4LookAt( linalg.vec3{ 0.0, 0.0, 0.0 }, linalg.vec3{ -1.0,  0.0,  0.0 }, linalg.vec3{ 0.0, -1.0,  0.0 } )
  view_mats[2] = linalg.mat4LookAt( linalg.vec3{ 0.0, 0.0, 0.0 }, linalg.vec3{  0.0,  1.0,  0.0 }, linalg.vec3{ 0.0,  0.0,  1.0 } )
  view_mats[3] = linalg.mat4LookAt( linalg.vec3{ 0.0, 0.0, 0.0 }, linalg.vec3{  0.0, -1.0,  0.0 }, linalg.vec3{ 0.0,  0.0, -1.0 } )
  view_mats[4] = linalg.mat4LookAt( linalg.vec3{ 0.0, 0.0, 0.0 }, linalg.vec3{  0.0,  0.0,  1.0 }, linalg.vec3{ 0.0, -1.0,  0.0 } )
  view_mats[5] = linalg.mat4LookAt( linalg.vec3{ 0.0, 0.0, 0.0 }, linalg.vec3{  0.0,  0.0, -1.0 }, linalg.vec3{ 0.0, -1.0,  0.0 } )
  
  // convert HDR equirectangular environment map to cubemap equivalent
  // shader_use(&core_data->equirect_shader);
  // shader_set_int(&core_data->equirect_shader, "equirect_map", 0);
  // shader_set_mat4(&core_data->equirect_shader, "proj", proj);
  gl.UseProgram( data.equirect_shader )
  gl.Uniform1i(gl.GetUniformLocation(data.equirect_shader, "equirect_map"), 0)
  gl.UniformMatrix4fv(gl.GetUniformLocation(data.equirect_shader, "proj"), 1, gl.FALSE, &proj[0][0])
  
  gl.ActiveTexture( gl.TEXTURE0 )
  gl.BindTexture( gl.TEXTURE_2D, hdr_texture )

  gl.Disable( gl.CULL_FACE )
  // REMOVE_FLAG(core_data->opengl_state, (opengl_state_flag)OPENGL_CULL_FACE);
  gl.Viewport( 0, 0, 512, 512 ) // don't forget to configure the viewport to the capture dimensions.
  gl.BindFramebuffer( gl.FRAMEBUFFER, capture_fbo )
  // for (u32 i = 0; i < 6; ++i)
  for i in 0..<6
  {
    // shader_set_mat4(&core_data->equirect_shader, "view", view_mats[i]);
    gl.UniformMatrix4fv(gl.GetUniformLocation(data.equirect_shader, "view"), 1, gl.FALSE, &view_mats[i][0][0])
    gl.FramebufferTexture2D( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, 
                             u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i), cubemap, 0 )
    gl.Clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )

    gl.BindVertexArray( cube_mesh.vao )
    // if (cube_mesh->indexed)
    // { _glDrawElements(GL_TRIANGLES, cube_mesh->indices_count, GL_UNSIGNED_INT, 0); }
    // else
    // { _glDrawArrays(GL_TRIANGLES, 0, cube_mesh->verts_count); }
    // @TODO: @UNSURE: @BUGG: not checking indexed, but i think mesh_load_fbx() 
    //                        only makes indexed meshes, so idk, its fine prob
    gl.DrawElements( gl.TRIANGLES, i32(cube_mesh.indices_len), gl.UNSIGNED_INT, nil )
  }
  gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )  
  
  // then let OpenGL generate mipmaps from first mip face (combatting visible dots artifact)
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, cubemap )
  gl.GenerateMipmap( gl.TEXTURE_CUBE_MAP )
  
  // render irradiencemap ----------------------------------------------------------------

  irradiance_map : u32
  gl.GenTextures( 1, &irradiance_map ) 
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, irradiance_map )
  // for (u32 i = 0; i < 6; ++i)
  for i in 0..<6
  {
    gl.TexImage2D( u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i), 0, gl.RGB16F, 32, 32, 0, 
                   gl.RGB, gl.FLOAT, nil )
  }
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR )

  gl.BindFramebuffer( gl.FRAMEBUFFER, capture_fbo )
  gl.BindRenderbuffer( gl.RENDERBUFFER, capture_rbo )
  gl.RenderbufferStorage( gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, 32, 32 )

  // shader_use(&core_data->irradiance_map_shader);
  // shader_set_mat4(&core_data->irradiance_map_shader, "proj", proj);
  // shader_set_int(&core_data->irradiance_map_shader, "environment_map", 0);
  gl.UseProgram( data.irradiance_map_shader)
  gl.Uniform1i(gl.GetUniformLocation(data.irradiance_map_shader, "equirect_map"), 0)
  gl.UniformMatrix4fv(gl.GetUniformLocation(data.irradiance_map_shader, "proj"), 1, gl.FALSE, &proj[0][0])

  gl.ActiveTexture( gl.TEXTURE0 )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, cubemap )

  gl.Viewport( 0, 0, 32, 32 ) // don't forget to configure the viewport to the capture dimensions.
  gl.BindFramebuffer( gl.FRAMEBUFFER, capture_fbo )
  // for (u32 i = 0; i < 6; ++i)
  for i in 0..<6
  {
    // shader_set_mat4(&core_data->irradiance_map_shader, "view", view_mats[i]);
    gl.UniformMatrix4fv(gl.GetUniformLocation(data.irradiance_map_shader, "view"), 1, gl.FALSE, &view_mats[i][0][0])
    gl.FramebufferTexture2D( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, 
                             u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i), irradiance_map, 0);
    gl.Clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )

    gl.BindVertexArray( cube_mesh.vao ) 
    // if (cube_mesh->indexed)
    // { _glDrawElements(GL_TRIANGLES, cube_mesh->indices_count, GL_UNSIGNED_INT, 0); }
    // else
    // { _glDrawArrays(GL_TRIANGLES, 0, cube_mesh->verts_count); }
    // @TODO: @UNSURE: @BUGG: not checking indexed, but i think mesh_load_fbx() 
    //                        only makes indexed meshes, so idk, its fine prob
    gl.DrawElements( gl.TRIANGLES, i32(cube_mesh.indices_len), gl.UNSIGNED_INT, nil )
  }
  gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )

  
  // gen radiance map --------------------------------------------------------------------
  
  prefilter_map : u32
  gl.GenTextures( 1, &prefilter_map ) 
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, prefilter_map )
  // for (u32 i = 0; i < 6; ++i)
  for i in 0..<6
  {
    gl.TexImage2D( u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i), 0, gl.RGB16F, 128, 128, 0, gl.RGB, gl.FLOAT, nil )
  }
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE )
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR ) 
  gl.TexParameteri( gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR ) 
  gl.GenerateMipmap( gl.TEXTURE_CUBE_MAP )

  // render radiance map -----------------------------------------------------------------
  
  // shader_use(&core_data->prefilter_shader);
  // shader_set_int(&core_data->prefilter_shader, "environment_map", 0);
  // shader_set_mat4(&core_data->prefilter_shader, "proj", proj);
  gl.UseProgram( data.prefilter_shader )
  gl.Uniform1i(gl.GetUniformLocation( data.prefilter_shader, "environment_map" ), 0)
  gl.UniformMatrix4fv(gl.GetUniformLocation(data.prefilter_shader, "proj"), 1, gl.FALSE, &proj[0][0])
  gl.ActiveTexture( gl.TEXTURE0 )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, cubemap )

  gl.BindFramebuffer( gl.FRAMEBUFFER, capture_fbo )
  max_mip_levels : u32 = 5
  // for (u32 mip = 0; mip < max_mip_levels; ++mip)
  for mip in 0..<max_mip_levels
  {
    // reisze framebuffer according to mip-level size.
    mip_w : i32 = i32(128.0 * math.pow( 0.5, f32(mip) ))
    mip_h : i32 = i32(128.0 * math.pow( 0.5, f32(mip) ))
    gl.BindRenderbuffer( gl.RENDERBUFFER, capture_rbo )
    gl.RenderbufferStorage( gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, mip_w, mip_h )
    gl.Viewport( 0, 0, mip_w, mip_h )

    roughness := f32(mip) / f32(max_mip_levels - 1)
    // shader_set_float(&core_data->prefilter_shader, "roughness", roughness);
    gl.Uniform1f( gl.GetUniformLocation(data.prefilter_shader, "roughness"), roughness )
    // for (u32  i = 0; i < 6; ++i)
    for i in 0..<6
    {
      // shader_set_mat4(&core_data->prefilter_shader, "view", view_mats[i]);
      gl.UniformMatrix4fv(gl.GetUniformLocation(data.prefilter_shader, "view"), 1, gl.FALSE, &view_mats[i][0][0])
      gl.FramebufferTexture2D( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, 
                               u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i), prefilter_map, i32(mip) )

      gl.Clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
      
      gl.BindVertexArray( cube_mesh.vao )
      // if (cube_mesh->indexed)
      // { _glDrawElements(GL_TRIANGLES, cube_mesh->indices_count, GL_UNSIGNED_INT, 0); }
      // else
      // { _glDrawArrays(GL_TRIANGLES, 0, cube_mesh->verts_count); }
      // @TODO: @UNSURE: @BUGG: not checking indexed, but i think mesh_load_fbx() 
      //                        only makes indexed meshes, so idk, its fine prob
      gl.DrawElements( gl.TRIANGLES, i32(cube_mesh.indices_len), gl.UNSIGNED_INT, nil )
    }
  }
  gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )

  gl.Enable( gl.CULL_FACE )
  // core_data->opengl_state |= OPENGL_CULL_FACE;
  
  gl.DeleteFramebuffers( 1, &capture_fbo )
  gl.DeleteRenderbuffers( 1, &capture_rbo )

  // texture_free_handle(prefilter_map);
  
  // ASSETM_PF("[cubemap] loaded cubemap '%s''\n", path);

  cm.loaded = true
  // ERR_CHECK(strlen(path) < CUBE_MAP_NAME_MAX, "not enough space in cube_map.name for the given name / path. %d|%d", (int)strlen(path), CUBE_MAP_NAME_MAX); 
  // strcpy(c.name, path);
  cm.environment = cubemap
  cm.irradiance  = irradiance_map
  cm.prefilter   = prefilter_map
  cm.intensity   = 1.0

  texture_free_handle( hdr_texture )

  return
}

