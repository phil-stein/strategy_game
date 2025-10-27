// #+private file // makes ui_cmd_t, ui_cmd_win_commands private
package core


import        "core:fmt"
import        "core:log"
import        "core:math"
import str    "core:strings"
import        "core:strconv"
import linalg "core:math/linalg/glsl"

ui_cmd_t :: struct
{
  cmd_str  : string,
  callback : proc( args: ..string ),
  num_args : string,
  desc     : string,
  example  : string,
}

// @DOC: add command definitions here -----------------------------------
ui_cmd_win_commands := [?]ui_cmd_t{ 
  { cmd_str="test",      callback=cmd_test,      num_args="0",  desc="just a test" }, 
  { cmd_str="help",      callback=cmd_help,      num_args="0",  desc="prints info about all available cmd's" }, 
  { cmd_str="log",       callback=cmd_log,       num_args="1+", desc="logs to ui_cmd_log_win()" }, 
  { cmd_str="light_i",   callback=cmd_light_i,   num_args="1",  desc="sets the data.cubemap.intensity value", example="light_i 4.7535" }, 
  { cmd_str="wireframe", callback=cmd_wireframe, num_args="0",  desc="toggles data.wireframe_mode_enabled" }, 
  { cmd_str="reset",     callback=cmd_reset,     num_args="0",  desc="resets all character & enemy paths" }, 
  { cmd_str="export",    callback=cmd_export,    num_args="0+", desc="export current level, name optional", example="export | export name.obj" }, 
  { cmd_str="ui",        callback=cmd_ui,        num_args="0",  desc="toggle imgui editor ui" }, 
  { cmd_str="ui_demo",   callback=cmd_ui_demo,   num_args="0",  desc="toggle imgui ui demo" }, 
}
// @TODO: commands
//        - [X] reset
//        - [X] export
//        - [ ] 

show_help_win := false
txt_win_timer : f32 = 0.0
txt_win_sb := str.builder_make()
txt_win_color := linalg.vec3{ 1, 1, 1 }


ui_cmd_update :: proc()
{
  // {
  //   x := ( input.mouse_x / f32(data.window_width) )  /* * 2 -1 */
  //   y := 1 - ( input.mouse_y / f32(data.window_height) ) /* * 2 -1 */

  //   pos := linalg.vec2{  0.500,  0.500 }
  //   scl := linalg.vec2{  0.350,  0.350 }
  //   renderer_draw_quad( pos, scl, data.texture_arr[data.texture_idxs.blank].handle, linalg.vec3{ 0.1, 0.1, 0.1 } )
  //   // text_draw_string( fmt.tprintf( "x: %v y: %v", input.mouse_x, input.mouse_y ), linalg.vec2{ 0, 0 } )
  //   pos = (pos +1) * 0.5
  //   // scl = (scl +1) * 0.5
  //   inside := util_point_in_rect( linalg.vec2{ x, y }, pos, scl )
  //   text_draw_string( fmt.tprintf( "x: %v, y: %v", x, y ), linalg.vec2{ 0, 0 } )
  //   text_draw_string( fmt.tprintf( "inside: %v", inside ), linalg.vec2{ 0, 0.05 } )
  //   text_draw_string( fmt.tprintf( "pos: %v", pos ), linalg.vec2{ 0, 0.1 } )
  //   text_draw_string( fmt.tprintf( "scl: %v", scl ), linalg.vec2{ 0, 0.15 } )
  //   text_draw_string( fmt.tprintf( "pos.y - (scl.y * 0.5): %v", pos.y - (scl.y * 0.5) ), linalg.vec2{ 0, 0.2 } )
  //   text_draw_string( fmt.tprintf( "pos.y + (scl.y * 0.5): %v", pos.y + (scl.y * 0.5) ), linalg.vec2{ 0, 0.25 } )
  // }
  
  TEXT_SIZE_Y      := ( f32(data.text.glyph_size) / f32(data.window_height) )
  TEXT_SIZE_X      := TEXT_SIZE_Y * 0.27
  TEXT_LINE_HEIGHT := TEXT_SIZE_Y * 2.0
  // fmt.println( "TEXT_SIZE_Y:", TEXT_SIZE_Y, "TEXT_SIZE_X:", TEXT_SIZE_X )

  if txt_win_timer > 0
  { 
    txt_win_str := str.to_string( txt_win_sb )

    pos := linalg.vec2{ 0.00000, -0.750 }
    scl := linalg.vec2{ TEXT_SIZE_X * f32( len(txt_win_str) +1 ), TEXT_SIZE_Y * 1.5 /* 0.050 */ }
    renderer_draw_quad( pos, scl, data.texture_arr[data.texture_idxs.blank].handle, linalg.vec3{ 0.1, 0.1, 0.1 }, math.min( 1, txt_win_timer + 0.65 ) )

    str_pos := linalg.vec2{ scl.x * -1 + 0.01, pos.y - scl.y - ( TEXT_SIZE_Y * 1 ) }
    str_width, str_len := text_draw_string( txt_win_str, str_pos, txt_win_color * math.min( 1, txt_win_timer + 0.1 ), math.min( 1, txt_win_timer + 0.0 ) )

    // tick timer down, only if not mouse over text
    x := ( input.mouse_x / f32(data.window_width) )  /* * 2 -1 */
    y := 1 - ( input.mouse_y / f32(data.window_height) ) /* * 2 -1 */
    inside := util_point_in_rect( linalg.vec2{ x, y }, (pos +1) * 0.5, scl )
    if !inside { txt_win_timer -= data.delta_t_real }
  }

  if show_help_win
  {
    if input.key_states[Key.ESCAPE].pressed || 
       input.key_states[Key.Q].pressed
    {
      show_help_win = false
    }

    @(static) help_win_max_str_len : int = 0

    scl_x := math.max( 0.25, TEXT_SIZE_X * f32(help_win_max_str_len) )
    scl_y := TEXT_LINE_HEIGHT * ( len(ui_cmd_win_commands) +3 ) * 0.5
    pos := linalg.vec2{ 0.000, 0.0 /* 0.450 */ }
    scl := linalg.vec2{ scl_x/* 0.500 */, scl_y /* 0.350 */ }
    renderer_draw_quad( pos, scl, data.texture_arr[data.texture_idxs.blank].handle, linalg.vec3{ 0.1, 0.1, 0.1 } )

    str_pos := linalg.vec2{ scl.x * -1 + TEXT_SIZE_X/* 0.01 */, pos.y + scl.y - ( TEXT_SIZE_Y * 4 ) }
    str_width, str_len := text_draw_string( "help ( press q to close )", str_pos )
    if str_len > help_win_max_str_len { help_win_max_str_len = str_len }
    renderer_draw_quad( linalg.vec2{ pos.x, str_pos.y + 0.01 }, linalg.vec2{ scl.x, 0.005 }, data.texture_arr[data.texture_idxs.blank].handle, linalg.vec3{ 0.8, 0.8, 0.8 } )
    str_pos += linalg.vec2{ 0, -TEXT_LINE_HEIGHT }
    for cmd in ui_cmd_win_commands
    {
      str_pos += linalg.vec2{ 0, -TEXT_LINE_HEIGHT }
      example_str := fmt.tprintf( "| >%v", cmd.example )
      str_width, str_len = text_draw_string( fmt.tprintf( ":%v <%v> -> %v %v", cmd.cmd_str, cmd.num_args, cmd.desc, len(cmd.example) > 0 ? example_str : "" ), str_pos )
      if str_len > help_win_max_str_len { help_win_max_str_len = str_len }
    }

    // closing by clicking ouside window
    if input.mouse_button_states[Mouse_Button.LEFT].pressed
    {
      x := ( input.mouse_x / f32(data.window_width) )  /* * 2 -1 */
      y := 1 - ( input.mouse_y / f32(data.window_height) ) /* * 2 -1 */
      inside := util_point_in_rect( linalg.vec2{ x, y }, (pos +1) * 0.5, scl )
      if !inside { show_help_win = false }
    }

    // fmt.println( "data.text.glyph_size:", data.text.glyph_size )
  }
}
ui_cmd_set_text :: proc( txt: string, duration : f32 = 2.0, color := linalg.vec3{ 1, 1, 1 } )
{
  txt_win_timer = duration
  str.builder_reset( &txt_win_sb )
  str.write_string( &txt_win_sb, txt )
  txt_win_color = color
}

// @DOC: add command procedures here ------------------------------------

@(private="file")
cmd_test :: proc( args: ..string )
{
  fmt.println( "|- test -|" )
  ui_cmd_set_text( "test test test test test test test test test test test test test test test test test test test test", color=linalg.vec3{ 1, 0, 1 } )
}

@(private="file")
cmd_help :: proc( args: ..string )
{
  // @TODO: use the ui_cmd_t struct to make good help thing
  show_help_win = true 
  append( &data.editor_ui.log_arr, fmt.aprint( "showing help window" ) )
}

@(private="file")
cmd_log :: proc( args: ..string )
{
  if len(args) < 1
  {
    append( &data.editor_ui.log_arr, fmt.aprint( "[LOG] ERROR no message" ) )
    ui_cmd_set_text( "ERROR no message given to :log", 2.5, color=linalg.vec3{ 1, 0, 0 } )
  }
  else
  {
    txt, err := str.join( args, " ", context.temp_allocator )
    if err != .None { panic( "yeah no good" ) }
    append( &data.editor_ui.log_arr, fmt.aprint( "[LOG]", txt ) )
    ui_cmd_set_text( txt, 2.5 )
  }
}

@(private="file")
cmd_light_i :: proc( args: ..string )
{
  if len(args) < 1 { log.error( "light_i cmd needs argumend" ); return }

  light_i, ok := strconv.parse_f32( args[0] )
  if !ok { log.error( "yeah no good" ); return }
  fmt.println( "light_i:", light_i )

  data.cubemap.intensity = light_i

  append( &data.editor_ui.log_arr, fmt.aprint( "[LIGHT INTENSITY]", light_i ) )

  ui_cmd_set_text( data.editor_ui.log_arr[len(data.editor_ui.log_arr) -1] )
}

@(private="file")
cmd_wireframe :: proc( args: ..string )
{
  data.wireframe_mode_enabled = !data.wireframe_mode_enabled
  append( &data.editor_ui.log_arr, fmt.aprint( "[WIREFRAME]", data.wireframe_mode_enabled ) )

  ui_cmd_set_text( data.editor_ui.log_arr[len(data.editor_ui.log_arr) -1] )
}

@(private="file")
cmd_reset :: proc( args: ..string )
{
  data.player_chars_current = -1

  for &char in data.player_chars
  {
    for &p in char.paths_arr
    { clear( &p ) }
    clear( &char.paths_arr )
  }

  append( &data.editor_ui.log_arr, fmt.aprint( "[reset]" ) )
  ui_cmd_set_text( data.editor_ui.log_arr[len(data.editor_ui.log_arr) -1] )
}

@(private="file")
cmd_export :: proc( args: ..string )
{
  if len(args) > 0
  {
    map_export_current( args[0] )
  }
  else { map_export_current( "big_honkin_level.obj" ) }

  append( &data.editor_ui.log_arr, fmt.aprint( "[exported]" ) )
  ui_cmd_set_text( data.editor_ui.log_arr[len(data.editor_ui.log_arr) -1] )
}

@(private="file")
cmd_ui :: proc( args: ..string )
{
  data.editor_ui.show_main = !data.editor_ui.show_main
}

@(private="file")
cmd_ui_demo :: proc( args: ..string )
{
  data.editor_ui.show_demo = !data.editor_ui.show_demo
}

