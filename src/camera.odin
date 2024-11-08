package core

// import        "core:fmt"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "vendor:glfw"


CAM_POV        :: 45.0 * math.PI / 180.0
CAM_NEAR_PLANE :: 0.1
CAM_FAR_PLANE  :: 1000

CAM_SPEED            :: 5
CAM_SPEED_SHIFT_MULT :: 5


camera_turntable_view_mat :: proc( radius, speed: f32 ) -> ( view: linalg.mat4 )
{
  cam_x := math.sin_f32( f32(glfw.GetTime()) * speed ) * radius  
	cam_z := math.cos_f32( f32(glfw.GetTime()) * speed ) * radius  

	pos    : linalg.vec3 = { cam_x, 0.0, cam_z }
	center : linalg.vec3 = { 0.0, 0.0, 0.0 }
	up     : linalg.vec3 = { 0.0, 1.0, 0.0 }
	return linalg.mat4LookAt(pos, center, up)
}
camera_get_front :: proc() -> ( front: linalg.vec3 )
{
	front.x = math.cos_f32(data.cam.yaw_rad) * math.cos_f32(data.cam.pitch_rad)
	front.y = math.sin_f32(data.cam.pitch_rad)
	front.z = math.sin_f32(data.cam.yaw_rad) * math.cos_f32(data.cam.pitch_rad);
  return
}
camera_get_right :: proc() -> ( right: linalg.vec3 )
{
  up     : linalg.vec3 = { 0, 1, 0 }
  front := camera_get_front()
  right  = linalg.cross( up, front )
  right  = linalg.normalize( right )
  return
}
camera_get_up :: proc() -> ( up: linalg.vec3 )
{
  front := camera_get_front()
  right := camera_get_right()
  up     = linalg.cross( front, right ) 
  up     = linalg.normalize( up ) 
  return
}

camera_set_view_mat :: proc()
{
  up      := camera_get_up() 
  front   := camera_get_front()
  center  := data.cam.pos + front
  data.cam.view_mat = linalg.mat4LookAt(data.cam.pos, center, up)

  // fmt.println( "view[0]: ", view[0] )
  // fmt.println( "view[1]: ", view[1] )
  // fmt.println( "view[2]: ", view[2] )
  // fmt.println( "view[3]: ", view[3] )
}

camera_set_pers_mat :: proc( width, height: f32)
{
  data.cam.pers_mat = linalg.mat4Perspective(CAM_POV, width / height, CAM_NEAR_PLANE, CAM_FAR_PLANE)

  // fmt.println( "pers[0]: ", pers[0] )
  // fmt.println( "pers[1]: ", pers[1] )
  // fmt.println( "pers[2]: ", pers[2] )
  // fmt.println( "pers[3]: ", pers[3] )
}

camera_set_pitch_yaw_rad :: proc( pitch, yaw: f32)
{
  data.cam.pitch_rad = pitch
  data.cam.yaw_rad   = yaw
  // fmt.println( "picth: ", pitch, ", yaw: ", yaw )
  
  // target is where we set the dir + pos
  data.cam.target = camera_get_front()
  data.cam.target += data.cam.pos 
}

// rotates the camera accoding to the mouse-movement
camera_rotate_by_mouse :: proc() 
{
	@(static) init       := false
	@(static) pitch, yaw : f32

	xoffset := input.mouse_delta_x
	yoffset := input.mouse_delta_y

	xoffset *= input.mouse_sensitivity
	yoffset *= input.mouse_sensitivity

	
	yaw   += xoffset
	pitch += yoffset

	// printf("pitch: %f, yaw: %f\n", pitch, yaw);

	if ( pitch > 89.0 )
	{ pitch = 89.0 }
	if ( pitch < -89.0 )
	{ pitch = -89.0 }

	if ( !init )
	{
    pitch = math.to_degrees( data.cam.pitch_rad )
    yaw   = math.to_degrees( data.cam.yaw_rad )
		init = true;
	}

	pitch_rad := math.to_radians( pitch )
  yaw_rad   := math.to_radians( yaw )

  camera_set_pitch_yaw_rad( pitch_rad, yaw_rad )
}

camera_move_by_keys :: proc()
{
	dist  : linalg.vec3
  front := camera_get_front()
  up    := camera_get_up()
  // -- move the cam --
	speed := CAM_SPEED * data.delta_t
	if ( input.key_states[Key.LEFT_SHIFT].down )
	{ speed *= CAM_SPEED_SHIFT_MULT; }
	if ( input.key_states[Key.W].down )
	{
    dist = front * speed
    data.cam.pos += dist
	}
	if ( input.key_states[Key.S].down )
	{
    dist = front * -speed
    data.cam.pos += dist
	}
	if ( input.key_states[Key.A].down )
	{
    dist = linalg.cross( front, up )
    dist = linalg.normalize( dist )
    dist *= -speed
    data.cam.pos += dist
	}
	if ( input.key_states[Key.D].down )
	{
    dist = linalg.cross( front, up )
    dist = linalg.normalize( dist )
    dist *= speed
    data.cam.pos += dist
	}
	if ( input.key_states[Key.Q].down )
	{
    dist = up * -speed
    data.cam.pos += dist
	}
	if ( input.key_states[Key.E].down )
	{
    dist = up * speed
    data.cam.pos += dist
	}
}
