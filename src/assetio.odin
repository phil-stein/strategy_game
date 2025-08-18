package core

import        "core:fmt"
import str    "core:strings"
import linalg "core:math/linalg/glsl"
import        "core:math"
import        "core:time"
import        "core:log"
import        "core:os"
import        "core:image"
import        "core:image/png"
import        "core:mem"
import gl     "vendor:OpenGL"
// import        "core:prof/spall"
import tracy  "../external/odin-tracy"

TEXTURES_PATH_START :: "assets/textures/"
TEXTURES_EXTENSIONS :: "tex"
MESH_PATH_START     :: "assets/meshes/"
MESH_EXTENSIONS     :: "mesh"


TEXTURE_HEADER_BYTE_SIZE :: /* len */ 4 /* width */ +4 /* height */ +4 /* channels */ +4
assetio_convert_texture :: proc( path: string )
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )
  when TRACY_ENABLE { tracy.Zone() }

  image_file_bytes, ok := os.read_entire_file( str.concatenate( []string{ TEXTURES_PATH_START, path}, context.temp_allocator ) ) 
  if !ok 
  {
    // Print error to stderr and exit with errorcode
    fmt.eprintln("could not read texture file: ", path)
    os.exit(1)
  }
  defer delete( image_file_bytes, context.allocator )

  // Load image  Odin's core:image library.
  image_ptr :  ^image.Image
  err       :   image.Error
  // options   :=  image.Options { .alpha_add_if_missing }
  options   :=  image.Options { }

  image_ptr, err =  png.load_from_bytes( image_file_bytes, options )
  defer png.destroy( image_ptr )
  image_w := i32( image_ptr.width )
  image_h := i32( image_ptr.height )

  if err != nil
  {
      fmt.println("ERROR: Image failed to load.")
  }

  // Copy bytes from icon buffer into slice.
  pixels := make( []u8, len(image_ptr.pixels.buf) )
  defer delete( pixels )
  for b, i in image_ptr.pixels.buf 
  {
      pixels[i] = b
  }

  conv_data := make( []byte, len(pixels) + TEXTURE_HEADER_BYTE_SIZE )
  defer delete( conv_data )

  pos := 0
  // len
  conv_data[pos] = byte(len(pixels) >> 24); pos += 1
  conv_data[pos] = byte(len(pixels) >> 16); pos += 1
  conv_data[pos] = byte(len(pixels) >> 8);  pos += 1
  conv_data[pos] = byte(len(pixels));       pos += 1
  bytes_len := int(conv_data[3]) + int(conv_data[2]) << 8 + int(conv_data[1]) << 16 + int(conv_data[0]) << 24
  // fmt.println( "len(pixels):", len(pixels), ", bytes_len:", bytes_len )
  // fmt.println( "len-bytes:", conv_data[3], conv_data[2], conv_data[1], conv_data[0] )
  // width
  conv_data[pos] = byte(image_ptr.width >> 24); pos += 1
  conv_data[pos] = byte(image_ptr.width >> 16); pos += 1
  conv_data[pos] = byte(image_ptr.width >> 8);  pos += 1
  conv_data[pos] = byte(image_ptr.width);       pos += 1
  // height
  conv_data[pos] = byte(image_ptr.height >> 24); pos += 1
  conv_data[pos] = byte(image_ptr.height >> 16); pos += 1
  conv_data[pos] = byte(image_ptr.height >> 8);  pos += 1
  conv_data[pos] = byte(image_ptr.height);       pos += 1
  // channels 
  conv_data[pos] = byte(image_ptr.channels >> 24); pos += 1
  conv_data[pos] = byte(image_ptr.channels >> 16); pos += 1
  conv_data[pos] = byte(image_ptr.channels >> 8);  pos += 1
  conv_data[pos] = byte(image_ptr.channels);       pos += 1
  // fmt.println( "len:", len(pixels), ", width:", image_ptr.width, ", height:", image_ptr.height, ", channels:", image_ptr.channels )
  // fmt.println( "pos:", pos )
  // fmt.println( "header written" )
  // fmt.println( "len(pixels):", len(pixels) ) 
  // fmt.println( "len(conv_data):", len(conv_data) ) 
  // fmt.println( "HEADER_BYTE_SIZE:", HEADER_BYTE_SIZE ) 
  // fmt.println( "len(conv_data) + HEADER_BYTE_SIZE:", len(conv_data) + HEADER_BYTE_SIZE ) 

  // copy_slice()
  // fmt.println( mem.copy( &conv_data[pos], &pixels,  len(pixels) ) )
  copy_slice( conv_data[pos:], pixels )


  // replace .png with .tex
  path_conv := str.clone( path, context.temp_allocator )
  path_conv  = str.cut( path_conv, 0, len(path_conv) - 3/* , context.temp_allocator */ )
  // fmt.println( "path_conv: ", path_conv )
  path_conv  = str.concatenate( []string{ path_conv, TEXTURES_EXTENSIONS }, context.temp_allocator )
  // fmt.println( "path_conv: ", path_conv )
  path_conv  = str.concatenate( []string{ TEXTURES_PATH_START, path_conv }, context.temp_allocator )
  fmt.println( "path_conv: ", path_conv )

  os.write_entire_file(  path_conv, conv_data )
  // fmt.println( "wrote file" )
}
assetio_load_texture :: proc( path: string, srgb: bool, tint:= [3]f32{ 1, 1, 1 } ) -> ( assetm_idx: int )
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )
  when TRACY_ENABLE { tracy.Zone() }

  // replace .png with .tex
  path_conv := str.clone( path, context.temp_allocator )
  path_conv  = str.cut( path_conv, 0, len(path_conv) - 3/* , context.temp_allocator */ )
  // fmt.println( "path_conv: ", path_conv )
  name      := str.concatenate( []string{ path_conv, TEXTURES_EXTENSIONS }, context.temp_allocator )
  // fmt.println( "path_conv: ", path_conv )
  path_conv  = str.concatenate( []string{ TEXTURES_PATH_START, name }, context.temp_allocator )
  // fmt.println( "path_conv: ", path_conv )
  // fmt.println( "path:", path )

  when ODIN_DEBUG
  {
    if !os.exists( path_conv )
    {
      assetio_convert_texture( path )
    }
    // @TODO: when .png edited
  }

  bytes, ok := os.read_entire_file_from_filename( path_conv, context.allocator )
  defer delete( bytes, context.allocator )
  if !ok 
  {
    // Print error to stderr and exit with errorcode
    fmt.eprintln("could not read texture file: ", path)
    os.exit(1)
  }

  // for i := 0; i < math.min( 20, len(bytes) ); i += 4 
  // {
  //   val := int(bytes[i +3]) + (int(bytes[i +2]) << 8) + (int(bytes[i +1]) << 16) + (int(bytes[i +0]) << 24)
  //   fmt.println( i / 4, ":", bytes[i +0], bytes[i +1], bytes[i +2], bytes[i +3], "->", val )
  //   fmt.printf( "%d : %x %x %x %x\n", i / 4, bytes[i +0], bytes[i +1], bytes[i +2], bytes[i +3] )
  // }

  pos        := 0
  pixels_len := int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24)
  pos        += 4
  width      := int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24)
  pos        += 4
  height     := int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24)
  pos        += 4
  channels   := int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24)
  // fmt.println( "len-bytes:", bytes[3], bytes[2], bytes[1], bytes[0] )
  // fmt.println( "bytes_len:", bytes_len )
  // fmt.println( "width:    ", width )
  // fmt.println( "height:   ", height )
  // fmt.println( "channels: ", channels )


  // // Copy bytes from icon buffer into slice.
  // pixels := make( []u8, pixels_len )
  // defer delete( pixels )
  // tint_idx := 0
  // // for b, i in image_ptr.pixels.buf 
  // for i in 0 ..< pixels_len 
  // {
  //   idx := TEXTURE_HEADER_BYTE_SIZE + i
  //   pixels[i] = byte( f32(bytes[idx] ) )// * tint[tint_idx] )
  //   tint_idx += 1
  //   if tint_idx >= 3 { tint_idx = 0 }
  // }
  
  pixels := &bytes[TEXTURE_HEADER_BYTE_SIZE]

  handle : u32
  gl.GenTextures( 1, &handle )
  gl.BindTexture( gl.TEXTURE_2D, handle )

  // Texture wrapping options.
  // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT )
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT )
  
  // Texture filtering options.
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR )


  gl_internal_format : i32 = srgb ? gl.SRGB_ALPHA : gl.RGBA
  gl_format          : u32 = gl.RGBA
  switch channels
  {
    case 1:
      gl_internal_format = srgb ? gl.SRGB8 : gl.R8
      gl_format = gl.RED
      break;
    // case 2:
    //   gl_internal_format = gl.RG8
    //   gl_format = gl.RG
    //   // P_INFO("gl.RGB");
    //   break;
    case 3:
      gl_internal_format = srgb ? gl.SRGB : gl.RGB
      gl_format = gl.RGB
      break;
    case 4:
      gl_internal_format = srgb ? gl.SRGB_ALPHA : gl.RGBA
      gl_format = gl.RGBA
      break;
    case:
      fmt.eprintln( "texture has incorrect channel amount: ", channels )
      os.exit( 1 )
  }
  assert( channels >= 1 && channels <= 4, "texture has incorrect channel amount" )

  // Describe texture.
  gl.TexImage2D(
      gl.TEXTURE_2D,      // texture type
      0,                  // level of detail number (default = 0)
      gl_internal_format, // gl.RGBA, // texture format
      i32(width),         // width
      i32(height),        // height
      0,                  // border, must be 0
      gl_format,          // gl.RGBA, // pixel data format
      gl.UNSIGNED_BYTE,   // data type of pixel data
      pixels,             // image data
  )

  // must be called after glTexImage2D
  gl.GenerateMipmap(gl.TEXTURE_2D);

  tex : texture_t
  tex.handle   = handle
  tex.width    = width
  tex.height   = height
  tex.channels = channels
  when ODIN_DEBUG
  { tex.name   = str.clone( name ) }
  idx := len( data.texture_arr )
  append( &data.texture_arr, tex )

  return idx 
}
assetio_load_png :: #force_inline proc( name: string, srgb: bool, tint := [3]f32{ 1, 1, 1 } ) -> ( idx: int )
{
  tex : texture_t
  tex.handle = make_texture( str.concatenate( []string{ TEXTURES_PATH_START, name}, context.temp_allocator ), srgb, tint )
  idx = len( data.texture_arr )
  append( &data.texture_arr, tex )

  return idx
}

MESH_HEADER_BYTE_SIZE :: /* len-indices */ 4 /* len-vertices */ +4
assetio_convert_mesh :: proc( path: string )
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )
  when TRACY_ENABLE { tracy.Zone() }

  indices, vertices := mesh_load_fbx_data( str.clone_to_cstring( str.concatenate( []string{ MESH_PATH_START, path}, context.temp_allocator ), context.temp_allocator) )

  conv_data := make( []byte, ( len(indices) * 4) + ( len(vertices) * 4 ) + MESH_HEADER_BYTE_SIZE )
  defer delete( conv_data )

  pos := 0
  // len-indices
  conv_data[pos] = byte(len(indices) >> 24); pos += 1
  conv_data[pos] = byte(len(indices) >> 16); pos += 1
  conv_data[pos] = byte(len(indices) >> 8);  pos += 1
  conv_data[pos] = byte(len(indices));       pos += 1
  // len-vertices
  conv_data[pos] = byte(len(vertices) >> 24); pos += 1
  conv_data[pos] = byte(len(vertices) >> 16); pos += 1
  conv_data[pos] = byte(len(vertices) >> 8);  pos += 1
  conv_data[pos] = byte(len(vertices));       pos += 1

  // copy_slice( conv_data[pos:], )
  for i in indices
  {
    conv_data[pos] = byte(i >> 24); pos += 1
    conv_data[pos] = byte(i >> 16); pos += 1
    conv_data[pos] = byte(i >> 8);  pos += 1
    conv_data[pos] = byte(i);       pos += 1
  }
  for v in vertices
  {
    conv_data[pos] = byte(transmute(u32)v >> 24); pos += 1
    conv_data[pos] = byte(transmute(u32)v >> 16); pos += 1
    conv_data[pos] = byte(transmute(u32)v >> 8);  pos += 1
    conv_data[pos] = byte(transmute(u32)v);       pos += 1
  }

  // replace .fbx with .mesh
  path_conv := str.clone( path, context.temp_allocator )
  path_conv  = str.cut( path_conv, 0, len(path_conv) - 3/* , context.temp_allocator */ )
  // fmt.println( "path_conv: ", path_conv )
  // path_conv  = str.concatenate( []string{ path_conv, "mesh" }, context.temp_allocator )
  // fmt.println( "path_conv: ", path_conv )
  path_conv  = str.concatenate( []string{ MESH_PATH_START, path_conv, MESH_EXTENSIONS }, context.temp_allocator )
  fmt.println( "path_conv: ", path_conv )

  os.write_entire_file(  path_conv, conv_data )
}

assetio_load_mesh :: proc( path: string ) -> ( assetm_idx: int )
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )
  when TRACY_ENABLE { tracy.Zone() }

  // replace .png with .tex
  path_conv := str.clone( path, context.temp_allocator )
  path_conv  = str.cut( path_conv, 0, len(path_conv) - 3/* , context.temp_allocator */ )
  // fmt.println( "path_conv: ", path_conv )
  name      := str.concatenate( []string{ path_conv, MESH_EXTENSIONS }, context.temp_allocator )
  // fmt.println( "path_conv: ", path_conv )
  path_conv  = str.concatenate( []string{ MESH_PATH_START, name }, context.temp_allocator )
  // fmt.println( "path_conv: ", path_conv )
  // fmt.println( "path:", path )

  when ODIN_DEBUG
  {
    if !os.exists( path_conv )
    {
      assetio_convert_mesh( path )
    }
    // @TODO: when .mesh edited
  }

  bytes, ok := os.read_entire_file_from_filename( path_conv, context.allocator )
  defer delete( bytes, context.allocator )
  if !ok 
  {
    // Print error to stderr and exit with errorcode
    fmt.eprintln("could not read texture file: ", path)
    os.exit(1)
  }

  pos          := 0
  indices_len  := int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24)
  pos          += 4
  vertices_len := int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24)
  pos          += 4

  indices := make( []u32, indices_len )
  defer delete( indices )
  for i in 0 ..< indices_len
  {
    indices[i] = u32( int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24) )
    pos        += 4
  }

  vertices := make( []f32, vertices_len )
  defer delete( vertices )
  for i in 0 ..< vertices_len
  {
    vertices[i] = transmute(f32)( i32( int(bytes[pos +3]) + (int(bytes[pos +2]) << 8) + (int(bytes[pos +1]) << 16) + (int(bytes[pos +0]) << 24) ) )
    pos        += 4
  }

  m := mesh_make( &vertices[0], len(vertices), &indices[0], len(indices) )
  assetm_idx = len( data.mesh_arr )
  append( &data.mesh_arr, m)

  when ODIN_DEBUG
  { data.mesh_arr[assetm_idx].name = str.clone( name ) }

  return assetm_idx 
}

assetio_load_fbx :: #force_inline proc( name: string ) -> ( idx: int )
{
  path_cstr := str.clone_to_cstring( str.concatenate( []string{ MESH_PATH_START, name}, context.temp_allocator ), context.temp_allocator )
  // fmt.println( "path: ", path_cstr )
  m := mesh_load_fbx( path_cstr )
  idx = len( data.mesh_arr )
  append( &data.mesh_arr, m)

  when ODIN_DEBUG
  { data.mesh_arr[idx].name = str.clone( name ) }

  return 
}
