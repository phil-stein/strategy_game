package core

// import    "core:fmt"
import gl "vendor:OpenGL"

FRAMEBUFFER_TYPE :: enum
{
	RGB				       = gl.RGB,
	RGB16F			     = gl.RGBA16F, // @TODO: check if GL_RGB16F works as well
	SINGLE_CHANNEL	 = gl.RED,
	SINGLE_CHANNEL_F = gl.R16F,
	DEPTH			       = gl.DEPTH_COMPONENT,  // @UNSURE: not used i think, shadowmap ?
  DEFERRED         = 0x9999,
}

framebuffer_t :: struct
{
  type: FRAMEBUFFER_TYPE,
  
  buffer01 : u32, 
  buffer02 : u32,  
	buffer03 : u32,  
	buffer04 : u32,  
	fbo      : u32, 
	rbo      : u32, 

	// use either not both
	size_divisor  : int,
	width, height : int,

	// bool is_msaa;
	// int  samples;
}


framebuffer_bind :: #force_inline proc(fb: ^framebuffer_t)
{
	gl.BindFramebuffer(gl.FRAMEBUFFER, fb.fbo);
}
framebuffer_bind_fbo :: #force_inline proc( fbo: u32 )
{
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo);
}
framebuffer_unbind :: #force_inline proc()
{
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0);
}

framebuffer_delete :: #force_inline proc(fb: ^framebuffer_t)
{
  gl.DeleteTextures(1, &fb.buffer01);
  if (fb.type == FRAMEBUFFER_TYPE.DEFERRED)
  {
    gl.DeleteTextures(1, &fb.buffer02);
    gl.DeleteTextures(1, &fb.buffer03);
    gl.DeleteTextures(1, &fb.buffer04);
  }
  if (fb.type != FRAMEBUFFER_TYPE.SINGLE_CHANNEL)
  {
    gl.DeleteRenderbuffers(1, &fb.rbo);
  }
  gl.DeleteFramebuffers(1, &fb.fbo);
}

// u32* tex_buffer, u32* fbo, u32* rbo, f32 size_divisor, int* width, int* height
framebuffer_create_hdr :: proc() -> ( fb: framebuffer_t )
{
  fb.type = FRAMEBUFFER_TYPE.RGB16F

	// create framebuffer object
	gl.GenFramebuffers(1, &fb.fbo);
	// set fbo to be the active framebuffer to be modified
	gl.BindFramebuffer(gl.FRAMEBUFFER, fb.fbo);


  w := data.window_width
  h := data.window_height

	// // scale the resolution 
  // if (*width || *height <= 0)
  // {
	//   // scale the resolution 
	//   w = int( f32(w) / f32(size_divisor) )
	//   h = int( f32(h) / f32(size_divisor) )
  // }
	fb.width  = w
	fb.height = h
  fb.size_divisor = 1 

	// generate texture
	gl.GenTextures(1, &fb.buffer01);
	gl.BindTexture(gl.TEXTURE_2D, fb.buffer01);

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB16F, i32(w), i32(h), 0, gl.RGB, gl.UNSIGNED_BYTE, nil);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
	// glBindTexture(gl.TEXTURE_2D, 0);
	// attach it to currently bound framebuffer object
	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fb.buffer01, 0);

	// create render buffer object
	gl.GenRenderbuffers(1, &fb.rbo);
	gl.BindRenderbuffer(gl.RENDERBUFFER, fb.rbo);  // &rbo
	gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, i32(w), i32(h));
	// glRenderbufferStorageMultisample(gl.RENDERBUFFER, 4, gl.DEPTH24_STENCIL8, i32(w), i32(h));
	gl.BindRenderbuffer(gl.RENDERBUFFER, 0);

	// attach render buffer object to the depth and stencil buffer
	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, fb.rbo);  // &rbo

	if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE)
	{
		// ERR("-!!!-> ERROR_CREATING_FRAMEBUFFER");
	  panic("-!!!-> ERROR_CREATING_FRAMEBUFFER")
	}

	// unbind the framebuffer, opengl now renders to the default buffer again
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0);

  return
}


// u32* pos_buffer, u32* norm_buffer, u32* mat_buffer, u32* col_buffer, u32* fbo, u32* rbo, f32 size_divisor, int* width, int* height
framebuffer_create_gbuffer :: proc( size_divisor: int ) -> ( fb: framebuffer_t )
{
  gl.GenFramebuffers(1, &fb.fbo);
  gl.BindFramebuffer(gl.FRAMEBUFFER, fb.fbo);

  w := data.window_width
  h := data.window_height

	// scale the resolution 
	w = int( f32(w) / f32(size_divisor) )
	h = int( f32(h) / f32(size_divisor) )
	fb.width  = w
	fb.height = h
  fb.size_divisor = size_divisor
  fb.type = FRAMEBUFFER_TYPE.DEFERRED


  // - color buffer
  gl.GenTextures(1, &fb.buffer01);
  gl.BindTexture(gl.TEXTURE_2D, fb.buffer01);
  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(w), i32(h), 0, gl.RGBA, gl.UNSIGNED_BYTE, nil);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fb.buffer01, 0);
 
  // - material buffer
  gl.GenTextures(1, &fb.buffer02);
  gl.BindTexture(gl.TEXTURE_2D, fb.buffer02);
  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(w), i32(h), 0, gl.RGBA, gl.UNSIGNED_BYTE, nil);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT1, gl.TEXTURE_2D, fb.buffer02, 0);
 
  // - normal color buffer
  gl.GenTextures(1, &fb.buffer03);
  gl.BindTexture(gl.TEXTURE_2D, fb.buffer03);
  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, i32(w), i32(h), 0, gl.RGBA, gl.FLOAT, nil);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT2, gl.TEXTURE_2D, fb.buffer03, 0);

  // - position color buffer
  gl.GenTextures(1, &fb.buffer04);
  gl.BindTexture(gl.TEXTURE_2D, fb.buffer04);
  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, i32(w), i32(h), 0, gl.RGBA, gl.FLOAT, nil);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT3, gl.TEXTURE_2D, fb.buffer04, 0);

  // - tell OpenGL which color attachments we'll use (of this framebuffer) for rendering 
  attachments : [4]u32 = { gl.COLOR_ATTACHMENT0, gl.COLOR_ATTACHMENT1, gl.COLOR_ATTACHMENT2, gl.COLOR_ATTACHMENT3 };
  gl.DrawBuffers(4, &attachments[0]);

	// create render buffer object
	gl.GenRenderbuffers(1, &fb.rbo);
	gl.BindRenderbuffer(gl.RENDERBUFFER, fb.rbo);  // &rbo
	gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, i32(w), i32(h));
	// glRenderbufferStorageMultisample(gl.RENDERBUFFER, 4, gl.DEPTH24_STENCIL8, w, h);
	gl.BindRenderbuffer(gl.RENDERBUFFER, 0);

	// attach render buffer object to the depth and stencil buffer
	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, fb.rbo);  // &rbo

	if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE)
	{
    panic("-!!!-> ERROR_CREATING_FRAMEBUFFER\n");
	}

	// unbind the framebuffer, opengl now renders to the default buffer again
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0);

  return
}
