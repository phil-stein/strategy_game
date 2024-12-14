package core

import    "core:fmt"
import gl "vendor:OpenGL"

Framebuffer_Type :: enum
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
  type: Framebuffer_Type,
  
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

framebuffer_resize_callback :: proc()
{
  framebuffer_resize_to_window( &data.fb_deferred )
  framebuffer_resize_to_window( &data.fb_lighting )
  framebuffer_resize_to_window( &data.fb_outline )
  framebuffer_resize_to_window( &data.fb_mouse_pick )
}

framebuffer_resize_to_window :: proc(fb: ^framebuffer_t)
{
  w := data.window_width
  h := data.window_height
	// if (fb->size_divisor > 1)
	// {
	//   w = (int)( w / fb->size_divisor );
	//   h = (int)( h / fb->size_divisor );
	// }
	fb.width  = w
	fb.height = h

  framebuffer_delete( fb )
  framebuffer_create( fb )
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
  if (fb.type == Framebuffer_Type.DEFERRED)
  {
    gl.DeleteTextures(1, &fb.buffer02);
    gl.DeleteTextures(1, &fb.buffer03);
    gl.DeleteTextures(1, &fb.buffer04);
  }
  if (fb.type != Framebuffer_Type.SINGLE_CHANNEL)
  {
    gl.DeleteRenderbuffers(1, &fb.rbo);
  }
  gl.DeleteFramebuffers(1, &fb.fbo);
}

framebuffer_create :: proc( fb: ^framebuffer_t )
{
  switch fb.type
  {
	  case Framebuffer_Type.RGB:
    {
      panic( "Framebuffer_Type.RGB not handled yet" )
    }
	  case Framebuffer_Type.RGB16F:
    {
      fb^ = framebuffer_create_hdr()
    }
	  case Framebuffer_Type.SINGLE_CHANNEL:
    {
      panic( "Framebuffer_Type.SINGLE_CHANNEL not handled yet" )
    }
	  case Framebuffer_Type.SINGLE_CHANNEL_F:
    {
      fb^ = framebuffer_create_single_channel_f( fb.size_divisor )
    }
	  case Framebuffer_Type.DEPTH:
    {
      panic( "Framebuffer_Type.DEPTH not handled yet" )
    }
    case Framebuffer_Type.DEFERRED:    
    {
      fb^ = framebuffer_create_gbuffer( fb.size_divisor )
    }
  }
}

// u32* tex_buffer, u32* fbo, u32* rbo, f32 size_divisor, int* width, int* height
framebuffer_create_hdr :: proc( loc := #caller_location) -> ( fb: framebuffer_t )
{
  // fmt.println( loc )

  fb.type = Framebuffer_Type.RGB16F

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
  fb.type = Framebuffer_Type.DEFERRED


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

framebuffer_create_single_channel_f :: proc( size_divisor: int ) -> ( fb: framebuffer_t )
{
  fb.type = Framebuffer_Type.SINGLE_CHANNEL_F
  fb.size_divisor = size_divisor

  // create framebuffer object
	gl.GenFramebuffers( 1, &fb.fbo )
	// set fbo to be the active framebuffer to be modified
	gl.BindFramebuffer( gl.FRAMEBUFFER, fb.fbo )

  w := data.window_width
  h := data.window_height
	// scale the resolution 
	w = w / size_divisor 
	h = h / size_divisor 

	// generate texture
	gl.GenTextures( 1, &fb.buffer01 )
	gl.BindTexture( gl.TEXTURE_2D, fb.buffer01 )

	gl.TexImage2D( gl.TEXTURE_2D, 0, gl.R16F, i32(w), i32(h), 0, gl.RED, gl.FLOAT, nil ) // gl.UNSIGNED_BYTE
	gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
	gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR )
	// attach it to currently bound framebuffer object
	gl.FramebufferTexture2D( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fb.buffer01, 0 )

	// create render buffer object
	gl.GenRenderbuffers( 1, &fb.rbo )
	gl.BindRenderbuffer( gl.RENDERBUFFER, fb.rbo )  // &rbo
	gl.RenderbufferStorage( gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, i32(w), i32(h) )
	gl.BindRenderbuffer( gl.RENDERBUFFER, 0 )

	// attach render buffer object to the depth and stencil buffer
	gl.FramebufferRenderbuffer( gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, fb.rbo )  // &rbo

	if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE)
	{
	  panic("-!!!-> ERROR_CREATING_FRAMEBUFFER")
	}

	// unbind the framebuffer, opengl now renders to the default buffer again
	gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )

	// free memory
	// glDeleteFramebuffers(1, &fbo);

  return fb
}
