package core 

import        "core:math"
import linalg "core:math/linalg/glsl"

util_model_set_pos :: #force_inline proc( model: ^linalg.mat4, pos: linalg.vec3 )
{
  model[3][0] = pos.x 
  model[3][1] = pos.y 
  model[3][2] = pos.z 
}

util_make_model :: proc( pos, rot, scale: linalg.vec3 ) -> ( model: linalg.mat4 )
{
	// mat4_make_identity(model);
	// float x = rot[0];  m_deg_to_rad(&x);
	// float y = rot[1];  m_deg_to_rad(&y);
	// float z = rot[2];  m_deg_to_rad(&z);
  model = linalg.identity( linalg.mat4 )
  x := math.to_radians( rot.x )
  y := math.to_radians( rot.y )
  z := math.to_radians( rot.z )
	
  // @NOTE: idk why its in different position than in my own c math lib
  //        prob bc. the core:math/linalg/glsl lib is different 
  model *= linalg.mat4Translate( pos )

	// mat4_rotate_at(model, pos, x, VEC3_X(1));
	// mat4_rotate_at(model, pos, y, VEC3_Y(1));
	// mat4_rotate_at(model, pos, z, VEC3_Z(1));
  model *= linalg.mat4Rotate( { 1.0, 0.0, 0.0 }, x )
  model *= linalg.mat4Rotate( { 0.0, 1.0, 0.0 }, y )
  model *= linalg.mat4Rotate( { 0.0, 0.0, 1.0 }, z )
	
	// mat4_translate(model, pos);

	// mat4_scale(model, scale, model);
  model *= linalg.mat4Scale( scale )

  // fmt.println( "model[0]: ", model[0] )
  // fmt.println( "model[1]: ", model[1] )
  // fmt.println( "model[2]: ", model[2] )
  // fmt.println( "model[3]: ", model[3] )

  return
}

ray_t :: struct
{
  pos : linalg.vec3,
  dir : linalg.vec3,
}
ray_hit_t :: struct
{
  hit   : bool,
  dist  : f32,
  point : linalg.vec3,
}

// taken from: https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html
// @DOC: get hit between ray and aabb
//       returns true if hit
//       puts hit point in hit_out
//       puts dist between ray->pos and hit_out in dist
// INLINE bool phys_collision_check_ray_v_aabb(ray_t* ray, vec3 min, vec3 max, f32* dist, vec3 hit_out) 
util_ray_intersect_aabb :: proc( ray: ray_t, min, max: linalg.vec3 ) -> ( hit: ray_hit_t )
{
  hit.hit  = false
  hit.dist = 0.0
  
  t1 : f32 = (min[0] - ray.pos[0]) / ray.dir[0]
  t2 : f32 = (max[0] - ray.pos[0]) / ray.dir[0]
  t3 : f32 = (min[1] - ray.pos[1]) / ray.dir[1]
  t4 : f32 = (max[1] - ray.pos[1]) / ray.dir[1]
  t5 : f32 = (min[2] - ray.pos[2]) / ray.dir[2]
  t6 : f32 = (max[2] - ray.pos[2]) / ray.dir[2]

  // ray intersects aabb twice, these are the distances to these points
  // f32 tmin = MAX(MAX(MIN(t1, t2), MIN(t3, t4)), MIN(t5, t6));
  // f32 tmax = MIN(MIN(MAX(t1, t2), MAX(t3, t4)), MAX(t5, t6));
  tmin := math.max(math.max(math.min(t1, t2), math.min(t3, t4)), math.min(t5, t6));
  tmax := math.min(math.min(math.max(t1, t2), math.max(t3, t4)), math.max(t5, t6));

  // if tmax < 0, ray (line) is intersecting AABB, but whole AABB is behing us
  if tmax < 0  { return hit }

  // if tmin > tmax, ray doesn't intersect AABB
  if tmin > tmax { return hit }

  // if tmin <  0 dist is tmax
  if   tmin < 0.0 { hit.dist = tmax }
  else            { hit.dist = tmin }
  
  // set ray_hit_t 
  // vec3_mul_f(ray->dir, hit->dist, hit->hit_point);
  // vec3_add(hit->hit_point, ray->pos, hit->hit_point);
  hit.point = ray.dir * hit.dist
  hit.point = hit.point + ray.pos

  // @TODO:
  // vec3 pos = { min[0] + max[0], min[1] + max[1], min[2] + max[2] };
  // vec3_sub(hit->hit_point, pos, hit->normal);
  // vec3_normalize(hit->normal, hit->normal);

  hit.hit = true 
  return hit 
}

util_tile_to_pos :: #force_inline proc( tile: waypoint_t ) -> ( pos: linalg.vec3 )
{
  return linalg.vec3{ 
          f32(tile.x)         * 2 - f32(TILE_ARR_X_MAX) +1,
          f32(tile.level_idx) * 2, 
          f32(tile.z)         * 2 - f32(TILE_ARR_Z_MAX) +1
         }
}

