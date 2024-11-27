package core

import        "base:runtime"
import        "core:time"
import        "core:fmt"

timer_t :: struct
{
  static     : bool,
  idx        : int,
  parent_idx : int,
  name       : string,
  loc_start  : runtime.Source_Code_Location,
  loc_stop   : runtime.Source_Code_Location,

  stopwatch  : time.Stopwatch,
}

timer_arr             :  [dynamic]timer_t
// timer_stopped_arr_idx switches every frame so
// timer_stopped_arr[timer_stopped_arr_idx == 0 ? 1 : 0], 
// from last frame is shown in ui
timer_stopped_arr     :  [2][dynamic]timer_t
timer_stopped_arr_idx := 0
timer_static_arr      :  [dynamic]timer_t

timer_stack_parent_idx := 0


// @NOTE: only have this when debug
when ODIN_DEBUG 
{

debug_timer_static_start :: proc( _name: string, _loc := #caller_location ) -> ( idx: int )
{
  idx = len( timer_arr )
  append( &timer_arr, timer_t{ static=true, loc_start=_loc, idx=idx, name=_name, parent_idx=timer_stack_parent_idx } )
  time.stopwatch_reset( &timer_arr[idx].stopwatch )
  time.stopwatch_start( &timer_arr[idx].stopwatch )

  timer_stack_parent_idx += 1

  return idx
  
} 
debug_timer_start :: proc( _name: string, _loc := #caller_location ) -> ( idx: int )
{
  idx = len( timer_arr )
  append( &timer_arr, timer_t{ static=false, loc_start=_loc, idx=idx, name=_name, parent_idx=timer_stack_parent_idx } )
  time.stopwatch_reset( &timer_arr[idx].stopwatch )
  time.stopwatch_start( &timer_arr[idx].stopwatch )
  
  timer_stack_parent_idx += 1

  return idx
}
debug_timer_stop :: proc( loc := #caller_location ) -> ( __timer: timer_t, failed: bool )
{
  // timer := &timer_arr[len(timer_arr) -1]
  if len(timer_arr) <= 0
  {
    fmt.eprintf( "[ERROR] called debug_timer_stop() with no timers on the stack\n -> %s:%d - %s", loc.procedure, loc.line, loc.file_path )
    return timer_t{}, true
  }
  _timer := pop( &timer_arr )
  _timer.loc_stop = loc
  append( &timer_stopped_arr[timer_stopped_arr_idx], _timer )
  timer := &timer_stopped_arr[timer_stopped_arr_idx][len(timer_stopped_arr[timer_stopped_arr_idx]) -1]
  time.stopwatch_stop( &timer.stopwatch )

  timer_stack_parent_idx -= 1
  
  if timer.static
  {
    append( &timer_static_arr, timer^ )
    // print debug info
    SEPERATOR :: "_"
    fmt.printf( "[STATIC TIMER] %s:", timer.name )
    // @NOTE: %10d and {:10d} doesnt work so i have to manually do padding
    width := 20
    for i in 0 ..< width - len(timer.name)
    { fmt.printf( SEPERATOR ) }
    p_len := fmt.printf( "%d", timer.stopwatch._accumulation )
    width = 15
    for i in 0 ..< width - p_len 
    { fmt.printf( SEPERATOR ) }
    p_len = fmt.printf( "%s", timer.loc_start.file_path )
    width = 55
    for i in 0 ..< width - p_len 
    { fmt.printf( SEPERATOR ) }
    fmt.printf( "%s():%d\n", timer.loc_start.procedure, timer.loc_start.line )
  }

  return timer^, false
}
debug_timer_update :: proc()
{
  clear( &timer_arr )
  timer_stopped_arr_idx = timer_stopped_arr_idx == 0 ? 1 : 0
  clear( &timer_stopped_arr[timer_stopped_arr_idx] )
}
debug_timer_cleanup :: proc()
{
  delete( timer_arr )
  delete( timer_stopped_arr[0] )
  delete( timer_stopped_arr[1] )
  delete( timer_static_arr )
}

} // when ODIN_DEBUG
else
{
debug_timer_static_start :: proc( _name: string, _loc := #caller_location ) {}
debug_timer_start :: proc( _name: string, _loc := #caller_location ) {} 
debug_timer_stop :: proc( loc := #caller_location ) {} 
debug_timer_update :: proc() {}
debug_timer_cleanup :: proc() {}
}
