#version 460 core

out vec4 FragColor;
in  vec2 uv_coords;

uniform sampler2D tex;

void main() 
{
  // FragColor = vec4( 1.0, 1.0, 1.0, 1.0);
  // FragColor = vec4( uv_coords.x, uv_coords.y, 0.0, 1.0);
  FragColor = vec4( texture( tex, uv_coords ).rgb, 1.0 );
}
