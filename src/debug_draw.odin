package core

import linalg "core:math/linalg/glsl"
import gl     "vendor:OpenGL"

debug_draw_line :: proc(pos0, pos1, tint: linalg.vec3, width: f32)
{
	// ---- mvp ----
  model := make_model( linalg.vec3{ 0, 0, 0 }, linalg.vec3{ 0, 0, 0 }, linalg.vec3{ 1, 1, 1 } )

  // @UNSURE: if i shoulf call this
  // camera_set_view_mat()
  // camera_set_pers_mat()

  // framebuffer_unbind()
  gl.Disable( gl.DEPTH_TEST )
  gl.Disable( gl.CULL_FACE )
	
	w, h := window_get_size()

  gl.LineWidth( width )

  // ---- vbo sub data ----

  _pos0 := [3]f32{ pos0.x, pos0.y, pos0.z }
  _pos1 := [3]f32{ pos1.x, pos1.y, pos1.z }
  gl.BindBuffer(gl.ARRAY_BUFFER, data.line_mesh.vbo);
  gl.BufferSubData(gl.ARRAY_BUFFER, 0            * size_of(f32), 3 * size_of(f32), &_pos0[0] )
  gl.BufferSubData(gl.ARRAY_BUFFER, F32_PER_VERT * size_of(f32), 3 * size_of(f32), &_pos1[0] )

	// ---- shader & draw call -----	

	shader_use( data.basic_shader )
	gl.ActiveTexture( gl.TEXTURE0 )
	gl.BindTexture(gl.TEXTURE_2D, assetm_get_texture( data.texture_idxs.blank ).handle )
	shader_set_i32( data.basic_shader,  "tex", 0 )
	shader_set_vec3( data.basic_shader, "tint", tint )
	
	shader_set_mat4(data.basic_shader, "model", &model[0][0] )
	shader_set_mat4(data.basic_shader, "view",  &data.cam.view_mat[0][0] )
	shader_set_mat4(data.basic_shader, "proj",  &data.cam.pers_mat[0][0] )

	gl.BindVertexArray(data.line_mesh.vao);
  gl.DrawArrays(gl.LINES, 0, 2);
  // gl.DrawElements(gl.LINES, 2, gl.UNSIGNED_INT, rawptr(uintptr(0)) );

  gl.Enable( gl.DEPTH_TEST )
  gl.Enable( gl.CULL_FACE )
}

debug_draw_aabb :: proc(min, max, color: linalg.vec3, width: f32)
{
  top0 := linalg.vec3{ max[0], max[1], max[2] }
  top1 := linalg.vec3{ max[0], max[1], min[2] } 
  top2 := linalg.vec3{ min[0], max[1], min[2] } 
  top3 := linalg.vec3{ min[0], max[1], max[2] } 
  
  bot0 := linalg.vec3{ max[0], min[1], max[2] }
  bot1 := linalg.vec3{ max[0], min[1], min[2] }
  bot2 := linalg.vec3{ min[0], min[1], min[2] }
  bot3 := linalg.vec3{ min[0], min[1], max[2] }
  
  debug_draw_line( top0, top1, color, width ) 
  debug_draw_line( top1, top2, color, width ) 
  debug_draw_line( top2, top3, color, width ) 
  debug_draw_line( top3, top0, color, width ) 
  
  debug_draw_line( bot0, bot1, color, width ) 
  debug_draw_line( bot1, bot2, color, width ) 
  debug_draw_line( bot2, bot3, color, width ) 
  debug_draw_line( bot3, bot0, color, width ) 
  
  debug_draw_line( bot0, top0, color, width ) 
  debug_draw_line( bot1, top1, color, width ) 
  debug_draw_line( bot2, top2, color, width ) 
  debug_draw_line( bot3, top3, color, width ) 
}
