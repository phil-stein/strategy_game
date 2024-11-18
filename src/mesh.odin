package core

import        "core:fmt"
// import        "core:c"
// import        "core:time"
// import        "core:math"
import linalg "core:math/linalg/glsl"
// import        "core:os"
// import        "core:runtime"
// import        "vendor:glfw"
import gl     "vendor:OpenGL"

import fbx    "../external/ufbx"


F32_PER_VERT :: ( 3 + 2 + 3 + 3 )  // pos, uvs, normals, tangents

mesh_load_fbx_data :: proc( path: cstring ) -> (  indices: [dynamic]u32, vertices: [dynamic]f32 )
{
  // fmt.println( "loc: ", loc )

  // Load the .fbx file
  opts  := fbx.Load_Opts{}
  err   := fbx.Error{}
  scene := fbx.load_file(path, &opts, &err)
  if scene == nil 
  {
    fmt.printf("%s\n", err.description.data)
    fmt.println( "path: ", path )
    panic("Failed to load")
  }
  defer fbx.free_scene( scene )
  assert( scene.meshes.count > 0 )
  
  m := scene.meshes.data[0]

  for face_ix in 0 ..< m.faces.count 
  {
    face := m.faces.data[face_ix]
    assert(face.num_indices == 3, "mesh faces with more than 3 triangles.\n"); 

    i0 := int(face.index_begin)
    i1 := i0 +1
    i2 := i0 +2
    
    _pos0 := m.vertex_position.values.data[m.vertex_position.indices.data[i0]]
    _pos1 := m.vertex_position.values.data[m.vertex_position.indices.data[i1]]
    _pos2 := m.vertex_position.values.data[m.vertex_position.indices.data[i2]]
    pos0 : linalg.vec3 = { f32(_pos0.x), f32(_pos0.y), f32(_pos0.z) }
    pos1 : linalg.vec3 = { f32(_pos1.x), f32(_pos1.y), f32(_pos1.z) }
    pos2 : linalg.vec3 = { f32(_pos2.x), f32(_pos2.y), f32(_pos2.z) }

    _tex0 := m.vertex_uv.values.data[m.vertex_uv.indices.data[i0]]
    _tex1 := m.vertex_uv.values.data[m.vertex_uv.indices.data[i1]]
    _tex2 := m.vertex_uv.values.data[m.vertex_uv.indices.data[i2]]
    tex0  : linalg.vec2 = { f32(_tex0.x), f32(_tex0.y) }
    tex1  : linalg.vec2 = { f32(_tex1.x), f32(_tex1.y) }
    tex2  : linalg.vec2 = { f32(_tex2.x), f32(_tex2.y) }

    uv0 := tex1 - tex0
    uv1 := tex2 - tex0
    
    edge0 := pos1 - pos0
    edge1 := pos2 - pos0

    r := 1.0 / (uv0.x * uv1.y - uv0.y * uv1.x)
    tan := linalg.vec3{ ((edge0.x * uv1.y) - (edge1.x * uv0.y)) * r,
                        ((edge0.y * uv1.y) - (edge1.y * uv0.y)) * r,
                        ((edge0.z * uv1.y) - (edge1.z * uv0.y)) * r }

    for vertex_ix in 0 ..< face.num_indices
    {
      index := face.index_begin + u32(vertex_ix)

      append( &indices, index )
      pos    := m.vertex_position.values.data[m.vertex_position.indices.data[index]]
      normal := m.vertex_normal.values.data[m.vertex_normal.indices.data[index]] 
      uv     := m.vertex_uv.values.data[m.vertex_uv.indices.data[index]]
     
      // @NOTE: flip to go from blender coord sys to the engines
      append( &vertices, f32(pos.x) )
      append( &vertices, f32(pos.z) )
      append( &vertices, f32(-pos.y) )

      append( &vertices, f32(uv.x) )
      append( &vertices, f32(1.0 - uv.y) )  // flip bc. opengl loads textures flipped

      append( &vertices, f32(normal.x) )
      append( &vertices, f32(normal.z) )
      append( &vertices, f32(-normal.y) )

      append( &vertices, f32(tan.x) )
      append( &vertices, f32(tan.z) )
      append( &vertices, f32(-tan.y) )
    }

  }
  return 
}

mesh_load_fbx :: proc( path: cstring, loc := #caller_location ) -> ( mesh: mesh_t )
{
  indices, vertices := mesh_load_fbx_data( path )

  mesh = mesh_make(&vertices[0], len(vertices), &indices[0], len(indices))

  delete( vertices )
  delete( indices )

  return mesh
}

mesh_make :: proc( vertices: [^]f32, vertices_len: int, indices: [^]u32, indices_len: int ) -> ( mesh: mesh_t )
{
  // fmt.println( "sizeof(vertices): ", size_of(vertices) )
  // fmt.println( "len(vertices): ", len(vertices) )
  // fmt.println( "sizeof(indices): ", size_of(indices) )
  // fmt.println( "len(indices): ", len(indices) )
  // mesh.indices_len = i32(len(indices))
  mesh.indices_len  = indices_len 
  mesh.vertices_len = vertices_len


  // Set up vertex array / element array / buffer objects
  gl.GenVertexArrays( 1, &mesh.vao )
  gl.BindVertexArray( mesh.vao )

  vbo : u32 
  gl.GenBuffers( 1, &vbo )
  gl.BindBuffer( gl.ARRAY_BUFFER, vbo )

  ebo : u32 
  gl.GenBuffers( 1, &ebo)
  gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, ebo )
  
  // Describe GPU buffer.
  gl.BufferData( gl.ARRAY_BUFFER,     // target
                 vertices_len * size_of(f32),   // size of the buffer object's data store
                 vertices,            // data used for initialization
                 gl.STATIC_DRAW )     // usage

  gl.BufferData( gl.ELEMENT_ARRAY_BUFFER, indices_len * size_of(u32), indices, gl.STATIC_DRAW )

  F_PER_V :: F32_PER_VERT // floats per vertex

  // position
  gl.VertexAttribPointer(0,                       // index
                         3,                       // size
                         gl.FLOAT,                // type
                         gl.FALSE,                // normalized
                         F_PER_V * size_of(f32),  // stride
                         0)                       // offset
  
  gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, F_PER_V * size_of(f32), 3 * size_of(f32) )  // uvs
  gl.VertexAttribPointer( 2, 3, gl.FLOAT, gl.FALSE, F_PER_V * size_of(f32), 5 * size_of(f32) )  // normals
  gl.VertexAttribPointer( 3, 3, gl.FLOAT, gl.FALSE, F_PER_V * size_of(f32), 8 * size_of(f32) )  // tangents 

  gl.EnableVertexAttribArray( 0 ) // pos
  gl.EnableVertexAttribArray( 1 ) // uv
  gl.EnableVertexAttribArray( 2 ) // normal
  gl.EnableVertexAttribArray( 3 ) // tangents 

  return
}

mesh_make_cube :: proc() -> ( mesh: mesh_t )
{
  vertices := [?]f32 { 
    // pos,       uvs     normals    tangents 
    -1, -1, -1,   0, 0,   0, 0, 0,   0, 0, 0,  
    +1, -1, -1,   1, 0,   0, 0, 0,   0, 0, 0,  
    -1, +1, -1,   0, 1,   0, 0, 0,   0, 0, 0, 
    +1, +1, -1,   1, 1,   0, 0, 0,   0, 0, 0, 
                                              
    -1, -1, +1,   0, 0,   0, 0, 0,   0, 0, 0, 
    +1, -1, +1,   1, 0,   0, 0, 0,   0, 0, 0, 
    -1, +1, +1,   0, 1,   0, 0, 0,   0, 0, 0, 
    +1, +1, +1,   1, 1,   0, 0, 0,   0, 0, 0, 
                                              
    -1, -1, -1,   0, 0,   0, 0, 0,   0, 0, 0, 
    -1, +1, -1,   1, 0,   0, 0, 0,   0, 0, 0, 
    -1, -1, +1,   0, 1,   0, 0, 0,   0, 0, 0, 
    -1, +1, +1,   1, 1,   0, 0, 0,   0, 0, 0, 
                                              
    +1, -1, -1,   0, 0,   0, 0, 0,   0, 0, 0, 
    +1, +1, -1,   1, 0,   0, 0, 0,   0, 0, 0, 
    +1, -1, +1,   0, 1,   0, 0, 0,   0, 0, 0, 
    +1, +1, +1,   1, 1,   0, 0, 0,   0, 0, 0, 
                                     
    -1, -1, -1,   0, 0,   0, 0, 0,   0, 0, 0, 
    +1, -1, -1,   1, 0,   0, 0, 0,   0, 0, 0, 
    -1, -1, +1,   0, 1,   0, 0, 0,   0, 0, 0, 
    +1, -1, +1,   1, 1,   0, 0, 0,   0, 0, 0, 
                                     
    -1, +1, -1,   0, 0,   0, 0, 0,   0, 0, 0, 
    +1, +1, -1,   1, 0,   0, 0, 0,   0, 0, 0, 
    -1, +1, +1,   0, 1,   0, 0, 0,   0, 0, 0, 
    +1, +1, +1,   1, 1,   0, 0, 0,   0, 0, 0, 
  }
  // index_array : [3 * 2 * 6] u32
  // index_array = {
  index_array := [?]u32 {
    0,  1,   2,  1,  2,  3, // Face 1
    4,  5,   6,  5,  6,  7, // Face 2
    8,  9,  10,  9, 10, 11, // Face 3
    12, 13, 14, 13, 14, 15, // Face 4
    16, 17, 18, 17, 18, 19, // Face 5
    20, 21, 22, 21, 22, 23, // Face 6
  }

  // fmt.println( "size_of(vertices): ", size_of(vertices) )
  // fmt.println( "len(vertices) * size_of(f32): ", len(vertices) * size_of(f32) )
  // fmt.println( "len(vertices): ", len(vertices) )
  // fmt.println( "len(index_array): ", len(index_array) )
  // fmt.println( "size_of(index_array): ", size_of(index_array) )
  return mesh_make( &vertices[0], len(vertices), &index_array[0], len(index_array) )

  // // fmt.println( "sizeof: ", size_of(index_array) )
  // // fmt.println( "len: ", len(index_array) )
  // indices_len = len(index_array)

  // // Set up vertex array / element array / buffer objects
  // gl.GenVertexArrays(1, &global_vao)
  // gl.BindVertexArray(global_vao)

  // vbo : u32 
  // gl.GenBuffers(1, &vbo)
  // gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

  // ebo : u32 
  // gl.GenBuffers(1, &ebo)
  // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
  // 
  // // Describe GPU buffer.
  // gl.BufferData(gl.ARRAY_BUFFER,     // target
  //               size_of(vertices),   // size of the buffer object's data store
  //               &vertices,           // data used for initialization
  //               gl.STATIC_DRAW)      // usage

  // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(index_array), &index_array, gl.STATIC_DRAW)

  // // Position and color attributes. Don't forget to enable!
  // gl.VertexAttribPointer(0,                   // index
  //                        3,                   // size
  //                        gl.FLOAT,            // type
  //                        gl.FALSE,            // normalized
  //                        5 * size_of(f32),    // stride
  //                        0)                   // offset
  // 
  // gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))

  // // Enable the vertex position and color attributes defined above.
  // gl.EnableVertexAttribArray(0)
  // gl.EnableVertexAttribArray(1)

  // return
}
