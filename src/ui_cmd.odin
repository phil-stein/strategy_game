// #+private file // makes ui_cmd_t, ui_cmd_win_commands private
package core


import     "core:fmt"
import     "core:log"
import str "core:strings"
import     "core:strconv"

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
  { cmd_str="test",     callback=cmd_test,    num_args="0",  desc="just a test" }, 
  { cmd_str="help",     callback=cmd_help,    num_args="0",  desc="prints info about all available cmd's" }, 
  { cmd_str="log",      callback=cmd_log,     num_args=">1", desc="logs to ui_cmd_log_win()" }, 
  { cmd_str="light_i",  callback=cmd_light_i, num_args="1",  desc="sets the data.cubemap.intensity value", example="light_i 4.7535" }, 
}

// @DOC: add command procedures here ------------------------------------

@(private="file")
cmd_test :: proc( args: ..string )
{
  fmt.println( "|- test -|" )
}

@(private="file")
cmd_help :: proc( args: ..string )
{
  @TODO: use the ui_cmd_t struct to make good help thing
}

@(private="file")
cmd_log :: proc( args: ..string )
{
  txt, err := str.join( args, " ", context.temp_allocator )
  if err != .None { panic( "yeah no good" ) }
  append( &data.editor_ui.log_arr, fmt.aprint( "[LOG]", txt ) )
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
}
