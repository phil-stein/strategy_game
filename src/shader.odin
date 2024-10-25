package core

import        "core:fmt"
import gl     "vendor:OpenGL"
import linalg "core:math/linalg/glsl"

handle_act  : u32
tex_idx_act : u32 = 0


shader_make :: proc( vertex_src, fragment_src: string, name := "unnamed") -> ( handle: u32 )
{
  // Compile vertex shader and fragment shader.
  // Note how much easier this is in Odin than in C++!
  program_ok      : bool
  // vertex_shader   := string( #load( "../assets/basic.vert" ) )
  // fragment_shader := string( #load( "../assets/basic.frag" ) )
  // handle, program_ok = gl.load_shaders_source( vertex_shader, fragment_shader )
  handle, program_ok = gl.load_shaders_source( vertex_src, fragment_src )

  if ( !program_ok )
  {
    fmt.println( "ERROR: Failed to load and compile shaders: ", name )
    panic( "shader comp failed" ) 
  }

  return
}


shader_use :: #force_inline proc( handle: u32 )
{
  gl.UseProgram( handle )
  handle_act  = handle
  tex_idx_act = 0
}
shader_delete :: #force_inline proc( handle: u32 )
{
	gl.DeleteProgram( handle )
  if handle == handle_act { handle_act = 0; tex_idx_act = 0 }
}
// resete tex_idx_act for the shader_act_... procs
shader_act_reset_tex_idx :: #force_inline proc( )
{
  tex_idx_act = 0
}

// shader set ---------------------------------------------------------------------------------

shader_set_bool :: #force_inline proc( handle: u32, name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), value )
}
// set an integer in the shader
shader_set_i32:: #force_inline proc( handle: u32, name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), value )
}
// set a float in the shader
shader_set_f32:: #force_inline proc( handle: u32, name: cstring, value: f32 )
{
	gl.Uniform1f( gl.GetUniformLocation( handle, name ), value )
}
// set a vec2 in the shader
shader_set_vec2_f :: #force_inline proc( handle: u32, name: cstring, x, y: f32 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle, name ), x, y )
}
// set a vec2 in the shader
shader_set_vec2 :: #force_inline proc( handle: u32, name: cstring, v: linalg.vec2 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle, name ), v.x, v.y )
}
// set a vec3 in the shader
shader_set_vec3_f :: #force_inline proc( handle: u32, name: cstring, x, y, z: f32 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle, name ), x, y, z )
}
// set a vec3 in the shader
shader_set_vec3 :: #force_inline proc( handle: u32, name: cstring, v: linalg.vec3 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle, name ), v.x, v.y, v.z )
}
// set a matrix 4x4 in the shader
// shader_set_mat4 :: #force_inline proc( handle: u32, name: cstring, value: linalg.mat4 )
shader_set_mat4 :: #force_inline proc( handle: u32, name: cstring, value: [^]f32 )
{
	// GLint transformLoc = gl.GetUniformLocation( handle, name )
	// gl.UniformMatrix4fv( transformLoc, 1, GL_FALSE, value[0] ) 
  gl.UniformMatrix4fv(gl.GetUniformLocation( handle, name ), 1, gl.FALSE, value )
}

shader_bind_texture :: #force_inline proc( handle: u32, name: cstring, tex_handle: u32, tex_idx: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx )
  gl.BindTexture( gl.TEXTURE_2D, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), i32(tex_idx) )
}
shader_bind_cube_map :: #force_inline proc( handle: u32, name: cstring, tex_handle: u32, tex_idx: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), i32(tex_idx) )
}

// shader act ---------------------------------------------------------------------------------

shader_act_set_bool :: #force_inline proc( name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), value )
}
// set an integer in the shader
shader_act_set_i32:: #force_inline proc( name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), value )
}
// set a float in the shader
shader_act_set_f32:: #force_inline proc( name: cstring, value: f32 )
{
	gl.Uniform1f( gl.GetUniformLocation( handle_act, name ), value )
}
// set a vec2 in the shader
shader_act_set_vec2_f :: #force_inline proc( name: cstring, x, y: f32 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle_act, name ), x, y )
}
// set a vec2 in the shader
shader_act_set_vec2 :: #force_inline proc( name: cstring, v: linalg.vec2 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle_act, name ), v.x, v.y )
}
// set a vec3 in the shader
shader_act_set_vec3_f :: #force_inline proc( name: cstring, x, y, z: f32 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle_act, name ), x, y, z )
}
// set a vec3 in the shader
shader_act_set_vec3 :: #force_inline proc( name: cstring, v: linalg.vec3 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle_act, name ), v.x, v.y, v.z )
}
// set a matrix 4x4 in the shader
// shader_act_set_mat4 :: #force_inline proc( name: cstring, value: linalg.mat4 )
shader_act_set_mat4 :: #force_inline proc( name: cstring, value: [^]f32 )
{
	// GLint transformLoc = gl.GetUniformLocation( handle_act, name )
	// gl.UniformMatrix4fv( transformLoc, 1, GL_FALSE, value[0] ) 
  gl.UniformMatrix4fv(gl.GetUniformLocation( handle_act, name ), 1, gl.FALSE, value )
}

shader_act_bind_cube_map :: #force_inline proc( name: cstring, tex_handle: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx_act )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(tex_idx_act) )
  tex_idx_act += 1
}
// shader_act_bind_texture :: #force_inline proc( name: cstring, tex_handle: u32, tex_idx: u32 )
shader_act_bind_texture :: #force_inline proc( name: cstring, tex_handle: u32, loc := #caller_location )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx_act )
  gl.BindTexture( gl.TEXTURE_2D, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(tex_idx_act) )
  tex_idx_act += 1

  // fmt.println( #procedure, " called by: ", loc.procedure, " line: ", loc.line, " -> ", loc.file_path )
}
