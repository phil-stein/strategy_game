#version 330 core

in vec2  inUV;
out vec4 FragColor;

uniform sampler2D glyph_texture;
uniform vec3 color;
uniform bool solid;
uniform float alpha;

void main() 
{
  // Cyan color is: 0.5, 1, 1
  if ( solid )
  { FragColor = vec4(color.rgb, 1.0); }
  else
  { FragColor = vec4(color.rgb, texture(glyph_texture, inUV).r * alpha); }
  // FragColor = vec4( inUV.xy, 0.0, 1.0 );
}
