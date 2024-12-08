package core 

DISABLE_DOCKING :: #config(DISABLE_DOCKING, false )

import im     "../external/odin-imgui"
import        "../external/odin-imgui/imgui_impl_glfw"
import        "../external/odin-imgui/imgui_impl_opengl3"

import        "vendor:glfw"
import gl     "vendor:OpenGL"

import        "core:os"
import        "core:fmt"
import        "core:strconv"
import str    "core:strings"
import linalg "core:math/linalg/glsl"
import        "core:reflect"

font     : ^im.Font
font_big : ^im.Font

ui_init :: proc()
{
	im.CHECKVERSION()
	im.CreateContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
	when !DISABLE_DOCKING 
  {
		io.ConfigFlags += {.DockingEnable}
		io.ConfigFlags += {.ViewportsEnable}
	}
	im.StyleColorsDark()
	style := im.GetStyle()
	style.WindowRounding    = 10.0
  style.TabRounding       = 10.0
  style.GrabRounding      = 10.0
  style.PopupRounding     = 10.0
  style.FrameRounding     = 10.0
  style.ScrollbarRounding = 10.0

	// style.Colors[im.Col.WindowBg].w = 1
  style.Colors[im.Col.WindowBg]            = im.Vec4{ 0.2,  0.2,  0.2,  1.0 }

  style.Colors[im.Col.Header]              = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.HeaderHovered]       = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.HeaderActive]        = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.Tab]                 = im.Vec4{ 0.2,  0.2,  0.2,  1.0 }
  style.Colors[im.Col.TabHovered]          = im.Vec4{ 0.35, 0.35, 0.35,  1.0 }
  style.Colors[im.Col.TabSelected]         = im.Vec4{ 0.30, 0.30, 0.30, 1.0 }
  style.Colors[im.Col.TabDimmed]           = im.Vec4{ 0.20, 0.20, 0.20, 1.0 }
  style.Colors[im.Col.TabDimmedSelected]   = im.Vec4{ 0.25, 0.25, 0.25, 1.0 }
  style.Colors[im.Col.TabSelectedOverline] = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }

  style.Colors[im.Col.Button]              = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.ButtonActive]        = im.Vec4{ 0.05, 0.05, 0.05, 1.0 }
  style.Colors[im.Col.ButtonHovered]       = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.TitleBg]             = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.TitleBgActive]       = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.TitleBgCollapsed]    = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.FrameBg]             = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.FrameBgActive]       = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.FrameBgHovered]      = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }

  style.Colors[im.Col.CheckMark]           = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }
  style.Colors[im.Col.SliderGrab]          = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }
  style.Colors[im.Col.SliderGrabActive]    = im.Vec4{ 1.0,  1.0,  1.0,  1.0 }

  style.Colors[im.Col.Separator]           = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.SeparatorActive]     = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.SeparatorHovered]    = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.ResizeGrip]          = im.Vec4{ 0.5,  0.5,  0.5,  1.0 }
  style.Colors[im.Col.ResizeGripHovered]   = im.Vec4{ 0.6,  0.6,  0.6,  1.0 }
  style.Colors[im.Col.ResizeGripActive]    = im.Vec4{ 0.7,  0.7,  0.7,  1.0 }
  
  style.Colors[im.Col.DockingPreview]      = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }

	imgui_impl_glfw.InitForOpenGL(data.window, true)
	imgui_impl_opengl3.Init("#version 150")

  font     = im.FontAtlas_AddFontFromFileTTF( io.Fonts, "assets/fonts/JetBrainsMonoNL-Regular.ttf", 20 )
  font_big = im.FontAtlas_AddFontFromFileTTF( io.Fonts, "assets/fonts/JetBrainsMonoNL-Regular.ttf", 24 )
  im.FontAtlas_Build( io.Fonts )
  // im.PushFont( font )

}

// @TODO: this dont work too good
win_flags : im.WindowFlags = { im.WindowFlag.NoTitleBar }
// p_open := true
ui_update :: proc()
{
	imgui_impl_opengl3.NewFrame()
	imgui_impl_glfw.NewFrame()
	im.NewFrame()

	im.ShowDemoWindow()

  im.DockSpaceOverViewport( 0, im.GetMainViewport(), { im.DockNodeFlag.PassthruCentralNode } )

  
  if /* p_open && */ im.Begin( "window", nil /* &p_open */,  win_flags ) 
  {
    map_tab, entities_tab, player_chars_tab, framebuffers_tab, assetm_tab, data_tab : bool
    if im.BeginTabBar( "tabs" )
    {
      if im.BeginTabItem( "map" )
      {
        map_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "entities" )
      {
        entities_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "player_chars" )
      {
        player_chars_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "assetm" )
      {
        assetm_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "data" )
      {
        data_tab = true
        im.EndTabItem()
      }
      im.EndTabBar()
    }
    im.SameLine()
    if im.Button( "undock" )
    {
      if im.WindowFlag.NoTitleBar in win_flags
      {
        /* win_flags = win_flags | { im.WindowFlag.NoDocking } */
        win_flags = win_flags - { im.WindowFlag.NoTitleBar }
      }
      else 
      {
        win_flags = win_flags + { im.WindowFlag.NoTitleBar }
      }

      fmt.println( "win_flags: ", win_flags )
      im.SetWindowPos( im.Vec2{ 0, 0 } )
    }
    // im.SameLine()
    // is_collapsed := im.IsWindowCollapsed()
    // if im.Button( is_collapsed ? "V" : "X" )
    // {
    //   im.SetWindowCollapsed( !is_collapsed ) 
    // }

    im.Separator()

    if      map_tab          { ui_map_tab()          }
    else if entities_tab     { ui_entity_tab()       }
    else if player_chars_tab { ui_player_chars_tab() }
    else if assetm_tab       { ui_assetm_tab()       }
    else if data_tab         { ui_data_tab()         }
    // else if framebuffers_tab { ui_framebuffer_tab()  }
	}
	im.End()

	im.Render()
	display_w, display_h := glfw.GetFramebufferSize(data.window)
	// gl.Viewport(0, 0, display_w, display_h)
	// gl.ClearColor(0, 0, 0, 1)
	// gl.Clear(gl.COLOR_BUFFER_BIT)
	imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

	when !DISABLE_DOCKING {
		backup_current_window := glfw.GetCurrentContext()
		im.UpdatePlatformWindows()
		im.RenderPlatformWindowsDefault()
		glfw.MakeContextCurrent(backup_current_window)
	}
}

ui_cleanup :: proc()
{
	imgui_impl_glfw.Shutdown()
	imgui_impl_opengl3.Shutdown()
	im.DestroyContext()
}

ui_display_texture :: proc( name: cstring, w, h, hover_w, hover_h: f32, handle: u32, no_name := false )
{
  if !no_name { im.Text( name ) }
  im.Image( im.TextureID(uintptr(handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  if im.BeginItemTooltip( )
  {
    im.Image( im.TextureID(uintptr(handle)), im.Vec2{ hover_w, hover_h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
    im.EndTooltip()
  }
}
ui_display_2_texture :: proc( name_00: cstring, w_00, h_00, hover_w_00, hover_h_00: f32, handle_00: u32,
                              name_01: cstring, w_01, h_01, hover_w_01, hover_h_01: f32, handle_01: u32, no_name := false )
{
  if !no_name 
  { 
    im.Text( name_00 ) 
    im.SameLine()
    im.Text( name_01 ) 
  }
  im.Image( im.TextureID(uintptr(handle_00)), im.Vec2{ w_00, h_00 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  if im.BeginItemTooltip( )
  {
    im.Image( im.TextureID(uintptr(handle_00)), im.Vec2{ hover_w_00, hover_h_00 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
    im.EndTooltip()
  }
  im.SameLine()

  im.Image( im.TextureID(uintptr(handle_01)), im.Vec2{ w_01, h_01 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  if im.BeginItemTooltip( )
  {
    im.Image( im.TextureID(uintptr(handle_01)), im.Vec2{ hover_w_01, hover_h_01 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
    im.EndTooltip()
  }
}

ui_entity_tab :: proc()
{
  im.SeparatorText( "reflected" )
  ui_display_any( data.entity_arr, "data.entity_arr" )
  im.SeparatorText( "" )

  // // if im.TreeNode("data.entity_arr" )
  // if im.CollapsingHeader( "data.entity_arr" )
  // {
  for &e, i in data.entity_arr
  {
    if i == 0
    {
      im.Text( " | data.entity_arr[0] is invalid |" )
      im.Text( " |  -> this is hacky fix this    |" )
      continue
    }

    // tree_id_string := fmt.tprintf( "entity-tree: %d", i )
    // tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
    // if im.TreeNodeStr(tree_id_string_cstr, "data.entity_arr[%d]", i )
    tree_id_string := fmt.tprintf( "data.entity_arr[%d]", i )
    tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
    if im.CollapsingHeader( tree_id_string_cstr )
    {
      debug_draw_sphere( e.pos, linalg.vec3{ 0.2, 0.2, 0.2 }, linalg.vec3{ 1, 1, 1 } )

      im.Text( "entity_idx:      %d", i )

      im.SeparatorText( "transform" )

      // im.SliderFloat3( "pos", (^[3]f32)(&e.pos), -100, 100 )
      // im.InputFloat3(  "pos", (^[3]f32)(&e.pos) )
      im.DragFloat3(  "pos", (^[3]f32)(&e.pos) )
      // im.SliderFloat3( "rot", (^[3]f32)(&e.rot), -360, 360 )
      // im.InputFloat3(  "rot", (^[3]f32)(&e.rot) )
      im.DragFloat3( "rot", (^[3]f32)(&e.rot) )
      // im.SliderFloat3( "scl", (^[3]f32)(&e.scl), -100, 100 )
      // im.InputFloat3(  "scl", (^[3]f32)(&e.scl) )
      im.DragFloat3(  "scl", (^[3]f32)(&e.scl), 0.5 )

      im.Separator()

      // im.TreePop()
    }
  }
  // }
}
ui_player_chars_tab :: proc()
{
  im.SeparatorText( "reflected" )
  ui_display_any( data.player_chars, "data.player_chars" )
  im.SeparatorText( "" )

  im.Text( "data.player_chars_current: %d", data.player_chars_current )
  // // if im.TreeNode( "data.player_chars" )
  // if im.CollapsingHeader( "data.player_chars" )
  // {
  for char, i in data.player_chars
  {
    if char.entity_idx > 0
    {
      // tree_id_string      := fmt.tprintf( "player-chars-tree: %d", i )
      // tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
      // if im.TreeNodeExStr( tree_id_string_cstr, { im.TreeNodeFlag. } "data.player_chars[%d]", i )

      tree_id_string      := fmt.tprintf( "data.player_chars[%d]", i )
      tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
      if im.CollapsingHeader( tree_id_string_cstr )
      {
        im.Text( "entity_idx:      %d", char.entity_idx )
        im.Text( "halo_entity_idx: %d", char.halo_entity_idx )
        // im.Text( "has_path:        %d", char.has_path )
        im.Text( "path_len:        %d", len(char.paths_arr) )

        // im.TreePop()
      }
    }
  }
  // }

}

level_combo_selected_idx := 0
ui_map_tab :: proc()
{
  im.SeparatorText( "reflected" )
  ui_display_any( data.tile_str_arr, "data.tile_str_arr" )
  ui_display_any( data.tile_type_arr, "data.tile_type_arr" )
  ui_display_any( data.tile_entity_id_arr, "data.tile_entity_id_arr" )
  im.SeparatorText( "" )

  tile_strs   := [?]cstring{ "empty", "blocked", "tile" }
  id_strs     := [?]cstring{ " ",     "X",       "#", "^", "v", "<", ">" }
  id_strs_idx := 0
  selected    := false

  level := level_combo_selected_idx

  if im.BeginCombo( "level", str.clone_to_cstring( fmt.tprint( "level: ", level ), context.temp_allocator ) )
  {
    for idx in 0 ..< TILE_LEVELS_MAX
    {
      is_selected := level == idx

      if im.Selectable( str.clone_to_cstring( fmt.tprint(idx), context.temp_allocator ), is_selected )
      { 
        level_combo_selected_idx = idx
        level = idx 
      }

      // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
      if is_selected 
      { im.SetItemDefaultFocus() }
    }
    im.EndCombo()
  }
  for z := TILE_ARR_Z_MAX -1; z >= 0; z -= 1
  {
    for x := TILE_ARR_X_MAX -1; x >= 0; x -= 1
    {
      if x != TILE_ARR_X_MAX -1 { im.SameLine() }
      
      im.PushID( str.clone_to_cstring( fmt.tprint( z * TILE_ARR_X_MAX + x ), context.temp_allocator ) )
      
      switch data.tile_type_arr[level][x][z]
      {
        case Tile_Nav_Type.EMPTY:
        {
          id_strs_idx = 0
          selected = false
        }
        case Tile_Nav_Type.BLOCKED:
        {
          id_strs_idx = 1
          selected = false
        }
        case Tile_Nav_Type.TRAVERSABLE:
        {
          id_strs_idx = 2 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_FORWARD:
        {
          id_strs_idx = 3 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_BACKWARD:
        {
          id_strs_idx = 4 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_LEFT:
        {
          id_strs_idx = 5 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_RIGHT:
        {
          id_strs_idx = 6 
          selected = true 
        }
      }
      im.PushStyleVarImVec2( im.StyleVar.SelectableTextAlign, im.Vec2{ 0.5, 0.5 } )
      im.PushFont( font_big )
      // if im.Selectable( str.clone_to_cstring( fmt.tprint( x, z ) ), selected, {}, im.Vec2{ 35, 35 } )
      if im.Selectable( id_strs[id_strs_idx], selected, {}, im.Vec2{ 35, 35 } )
      {
        im.OpenPopup( "tile_type_popup" )
      }
      im.PopStyleVar()
      im.PopFont()
      if im.IsItemHovered()
      {
        // debug_draw_sphere( util_tile_to_pos( waypoint_t{ level_idx=level, x=x, z=z } ), 
        //                    linalg.vec3{ 0.2, 0.2, 0.2 }, 
        //                    linalg.vec3{ 1, 1, 1 } )
        
        pos := util_tile_to_pos( waypoint_t{ level_idx=level, x=x, z=z } )
        min := pos + linalg.vec3{ -1, -1, -1 }
        max := pos + linalg.vec3{  1,  1,  1 }
        debug_draw_aabb( min, max, linalg.vec3{ 1, 1, 1 }, 15 )
      }
      if im.BeginPopup( "tile_type_popup" )
      {
        im.Text( fmt.ctprintf( "%v %v %v", level, x, z ) )
        im.SeparatorText( tile_strs[id_strs_idx] )
        if data.tile_type_arr[level][x][z] != Tile_Nav_Type.EMPTY && im.Button( "empty" ) 
        { 
          if data.tile_type_arr[level][x][z] == Tile_Nav_Type.TRAVERSABLE ||
             data.tile_type_arr[level][x][z] == Tile_Nav_Type.BLOCKED
          {
            data_entity_remove( data.tile_entity_id_arr[level][x][z] )
          }
          data.tile_type_arr[level][x][z] = Tile_Nav_Type.EMPTY
        }
        if data.tile_type_arr[level][x][z] == Tile_Nav_Type.EMPTY && im.Button( "tile" )  
        {
          data_entity_add( 
                  entity_t{ pos = util_tile_to_pos( waypoint_t{ level, x, z, Combo_Type.NONE } ), 
                            rot = { 0, 0, 0 }, scl = { 1, 1, 1 },
                            mesh_idx = data.mesh_idxs.dirt_cube, 
                            mat_idx  = level == 1 ? data.material_idxs.dirt_cube_02 : 
                                                    data.material_idxs.dirt_cube_01
                          } )
          data.tile_type_arr[level][x][z] = Tile_Nav_Type.TRAVERSABLE
          if level +1 < TILE_LEVELS_MAX && data.tile_type_arr[level +1][x][z] == Tile_Nav_Type.TRAVERSABLE
          { data.tile_type_arr[level][x][z] = Tile_Nav_Type.BLOCKED } 
        }
        if data.tile_type_arr[level][x][z] == Tile_Nav_Type.BLOCKED && im.Button( "remove blocking tile" )
        {
          data_entity_remove( data.tile_entity_id_arr[level +1][x][z] )
        }
        im.EndPopup()
      }
      im.PopID()

      // x += 1
    }
    // z += 1
  }
}
ui_assetm_tab :: proc()
{

  // im.Text( "blank" )
  // im.Image( im.TextureID(uintptr(data.texture_arr[data.texture_idxs.blank].handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  //
  // im.Text( "brick-albedo" )
  // im.Image( im.TextureID(uintptr(data.texture_arr[data.texture_idxs.brick_albedo].handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  // im.Text( "brick-normal" )
  // im.Image( im.TextureID(uintptr(data.texture_arr[data.texture_idxs.brick_normal].handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  
  if im.BeginTabBar( "assetm-tab-tabs" )
  {
    if im.BeginTabItem( "materials" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( data.material_arr, "data.material_arr" )
      im.SeparatorText( "" )

      for &m, i in data.material_arr
      {
        if im.CollapsingHeader( str.clone_to_cstring( m.name, context.temp_allocator )  )
        {
          // im.Text( str.clone_to_cstring( m.name, context.temp_allocator ) )
          
          im.SeparatorText( "tint" )

          w := (im.GetContentRegionAvail().x - im.GetStyle().ItemSpacing.y) * 0.40
          im.SetNextItemWidth( w )
          im.PushID( str.clone_to_cstring( fmt.tprint( "color-picker3_00", i ), context.temp_allocator ) )
          im.ColorPicker3("##MyColor##5", (^[3]f32)(&m.tint), { im.ColorEditFlags.PickerHueBar, im.ColorEditFlags.NoSidePreview, im.ColorEditFlags.NoInputs, im.ColorEditFlags.NoAlpha });
          im.PopID()
          
          im.SameLine()
          im.SetNextItemWidth(w);
          im.PushID( str.clone_to_cstring( fmt.tprint( "color-picker3_01", i ), context.temp_allocator ) )
          im.ColorPicker3("##MyColor##6", (^[3]f32)(&m.tint), { im.ColorEditFlags.PickerHueWheel, im.ColorEditFlags.NoSidePreview, im.ColorEditFlags.NoInputs, im.ColorEditFlags.NoAlpha } )
          im.PopID()

          im.PushID( str.clone_to_cstring( fmt.tprint( "color-dragfloat3", i ), context.temp_allocator ) )
          im.DragFloat3( "", (^[3]f32)(&m.tint), 0.1, 0, 1)
          im.PopID()
          color_int := [3]i32{ i32(m.tint[0] * 255.0), i32(m.tint[1] * 255.0), i32(m.tint[2] * 255.0) }
          im.PushID( str.clone_to_cstring( fmt.tprint( "color-dragint3", i ), context.temp_allocator ) )
          im.DragInt3( "", &color_int, 0.1, 0, 255)
          im.PopID()
          m.tint[0] = f32(color_int[0]) / 255.0
          m.tint[1] = f32(color_int[1]) / 255.0
          m.tint[2] = f32(color_int[2]) / 255.0
          
          im.SeparatorText( "properties" )

          im.DragFloat( fmt.ctprintf( "roughness_f : f32" ), &m.roughness_f, 0.05, 0.0, 1.0  )
          im.DragFloat( fmt.ctprintf( "metallic_f : f32" ), &m.metallic_f,   0.05, 0.0, 1.0 )
          im.DragFloat2( fmt.ctprintf( "uv_tile: linalg.vec2" ), &m.uv_tile, 0.05 )
          im.DragFloat2( fmt.ctprintf( "uv_offs: linalg.vec2" ), &m.uv_offs, 0.05 )

          im.SeparatorText( "textures" )

          t_albedo    := assetm_get_texture( m.albedo_idx )
          t_roughness := assetm_get_texture( m.roughness_idx )
          t_metallic  := assetm_get_texture( m.metallic_idx )
          t_normal    := assetm_get_texture( m.normal_idx )
 
          SCALE :: 225
          
          t_00   := t_albedo
          t_w_00 : f32 = SCALE
          t_h_00 : f32 = SCALE * ( f32(t_00.height) / f32(t_00.width) )
          t_01   := t_roughness
          t_w_01 : f32 = SCALE
          t_h_01 : f32 = SCALE * ( f32(t_01.height) / f32(t_01.width) )
          ui_display_2_texture( fmt.ctprintf( "albedo: %s",    t_albedo.name ),    t_w_00, t_h_00, t_w_00*4, t_h_00*4, t_albedo.handle,
                                fmt.ctprintf( "roughness: %s", t_roughness.name ), t_w_01, t_h_01, t_w_01*4, t_h_01*4, t_roughness.handle )

          t_00   = t_metallic
          t_w_00 = SCALE
          t_h_00 = SCALE * ( f32(t_00.height) / f32(t_00.width) )
          t_01   = t_normal
          t_w_01 = SCALE
          t_h_01 = SCALE * ( f32(t_01.height) / f32(t_01.width) )
          ui_display_2_texture( fmt.ctprintf( "metallic: %s", t_metallic.name ), t_w_00, t_h_00, t_w_00*4, t_h_00*4, t_metallic.handle,
                                fmt.ctprintf( "normal: %s",   t_normal.name ),   t_w_01, t_h_01, t_w_01*4, t_h_01*4, t_normal.handle )
        }
      }
      im.EndTabItem()
    }
    if im.BeginTabItem( "textures" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( data.texture_arr, "data.texture_arr" )
      im.SeparatorText( "" )

      for t, i in data.texture_arr
      {
        name_cstr := str.clone_to_cstring( t.name, context.temp_allocator )
        if im.CollapsingHeader( name_cstr )
        {
          SCALE :: 350
          w : f32 = SCALE
          h : f32 = SCALE * ( f32(t.height) / f32(t.width) )
          ui_display_texture( name_cstr, w, h, w*2, h*2, t.handle, no_name=true )

          im.Text( str.clone_to_cstring( fmt.tprint( "width:    ", t.width ),    context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprint( "height:   ", t.height ),   context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprint( "channels: ", t.channels ), context.temp_allocator ) )
        }
      }
      im.EndTabItem()
    }
    if im.BeginTabItem( "meshes" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( data.mesh_arr, "data.mesh_arr" )
      im.SeparatorText( "" )

      im.Text( "F32_PER_VERT: %d", F32_PER_VERT )
      for m, i in data.mesh_arr
      {
        if im.CollapsingHeader( str.clone_to_cstring( m.name, context.temp_allocator )  )
        {
          im.Text( str.clone_to_cstring( fmt.tprintf( "vao:          %d", m.vao ),          context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprintf( "vbo:          %d", m.vbo ),          context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprintf( "vertices_len: %d", m.vertices_len / F32_PER_VERT ), context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprintf( "indices_len:  %d", m.indices_len ),  context.temp_allocator ) )
        }
      }
      im.EndTabItem()
    }
    im.EndTabBar()
  }
}
ui_data_tab :: proc()
{
  if im.BeginTabBar( "data-tab-tabs" )
  {
    if im.BeginTabItem( "data" )
    {
      im.SeparatorText( "reflected" )
      ui_display_struct_members( data, "data" )
      im.SeparatorText( "" )

      im.NewLine()
      im.Text( "delta_t_real:            %f", data.delta_t_real )
      im.Text( "delta_t:                 %f", data.delta_t )
      im.Text( "total_t:                 %f", data.total_t )
      im.Text( "cur_fps:                 %f", data.cur_fps )
      im.Text( "time_scale:              %f", data.time_scale )
      im.DragFloat( "time_scale", &data.time_scale, 0.1 )
      
      im.NewLine()
      im.Text( "window_width:            %d", data.window_width )
      im.Text( "window_height:           %d", data.window_height )
      im.Text( "monitor_width:           %d", data.monitor_width )
      im.Text( "monitor_height:          %d", data.monitor_height )
      im.Text( "vsync_enabled:           %s", data.vsync_enabled ? "true" : "false" )
      vsync := data.vsync_enabled
      im.Checkbox( "vsync_enabled", &vsync )
      if vsync != data.vsync_enabled
      { window_set_vsync( vsync ) }

      im.NewLine()
      im.Text( "wireframe_mode_enabled:  %s", data.wireframe_mode_enabled ? "true" : "false" )
      im.Checkbox( "wireframe_mode_enabled", &data.wireframe_mode_enabled )
  
      SCALE :: 225
      t_w : f32 = SCALE
      t_h : f32 = SCALE 
      ui_display_texture( "brdf_lut", t_w, t_h, t_w*2, t_h*2, data.brdf_lut )

      im.NewLine()
      im.Text( "cam.pos:                 %f, %f, %f", data.cam.pos.x, data.cam.pos.y, data.cam.pos.z )
      im.DragFloat3( "cam.pos", (^[3]f32)(&data.cam.pos) )
      im.Text( "cam.target:              %f, %f, %f", data.cam.target.x, data.cam.target.y, data.cam.target.z )
      // im.DragFloat3( "cam.target", (^[3]f32)(&data.cam.target) )
      im.Text( "cam.pitch_rad:           %f", data.cam.pitch_rad )
      im.DragFloat( "cam.pitch_rad", &data.cam.pitch_rad, 0.1 )
      im.Text( "cam.yaw_rad:             %f", data.cam.yaw_rad )
      im.DragFloat( "cam.yaw_rad",   &data.cam.yaw_rad, 0.1 )

      im.NewLine()
      im.Text( "editor_ui.active:        %s", data.editor_ui.active ? "true" : "false" )

      im.NewLine()
      im.Text( "TILE_ARR_X_MAX:          %d", TILE_ARR_X_MAX )
      im.Text( "TILE_ARR_Z_MAX:          %d", TILE_ARR_Z_MAX )
      im.Text( "TILE_LEVELS_MAX:         %d", TILE_LEVELS_MAX )

      im.EndTabItem()
    }
    if im.BeginTabItem( "framebuffers" )
    {
      SCALE :: 0.35
      w := f32(data.window_width)  * SCALE
      h := f32(data.window_height) * SCALE

      // im.Text( "color" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer01)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "material" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer02)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "normal" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer03)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "position" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer04)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "lighting" )
      // im.Image( im.TextureID(uintptr(data.fb_lighting.buffer01)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      ui_display_texture( "color",    w, h, w*2, h*2, data.fb_deferred.buffer01 )
      ui_display_texture( "material", w, h, w*2, h*2, data.fb_deferred.buffer02 )
      ui_display_texture( "normal",   w, h, w*2, h*2, data.fb_deferred.buffer03 )
      ui_display_texture( "position", w, h, w*2, h*2, data.fb_deferred.buffer04 )
      ui_display_texture( "lighting", w, h, w*2, h*2, data.fb_lighting.buffer01 )

      im.EndTabItem()
    }
    if im.BeginTabItem( "timers" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( timer_static_arr, "timer_static_arr" )
      ui_display_any( timer_stopped_arr, "timer_stopped_arr" )
      im.SeparatorText( "" )

      if im.CollapsingHeader( fmt.ctprintf( "static timer[%d]", len(timer_static_arr) ) )
      {
        for &t, i in timer_static_arr
        {
          ui_display_timer( &t )
        }
      }
      if im.CollapsingHeader( fmt.ctprintf( "timer[%d]", len(timer_stopped_arr[timer_stopped_arr_idx == 0 ? 1 : 0]) ) )
      {
        for &t, i in timer_stopped_arr[timer_stopped_arr_idx == 0 ? 1 : 0]
        {
          ui_display_timer( &t )
        }
      }
      im.EndTabItem()
    }
  }
  im.EndTabBar()
} 
ui_display_timer :: #force_inline proc( t: ^timer_t)
{
  indent_w : f32 = 15.0 * f32(t.parent_idx)
  if t.parent_idx != 0
  {
    im.Indent( indent_w ) 
  }
  if im.TreeNode( fmt.ctprintf( "%s -> %s():%d", t.name, t.loc_start.procedure, t.loc_start.line ) )
  {
    // im.Text( str.clone_to_cstring( fmt.tprint( "time:", f32( t.stopwatch._accumulation) / ( 1000000.0 ), "ms |", t.stopwatch._accumulation ), context.temp_allocator ) )
    im.Text( fmt.ctprintf( "time: %.2fms | %d", f32( t.stopwatch._accumulation) / ( 1000000.0 ), t.stopwatch._accumulation ) ) 
    im.Text( fmt.ctprintf( "idx: %d, parent_idx: %d", t.idx, t.parent_idx ) ) 

    im.SeparatorText( "started" )
    im.Text( fmt.ctprint( "proc:", t.loc_start.procedure, ", line:", t.loc_start.line, ", col: ", t.loc_start.column ) )
    im.Text( fmt.ctprint( "file:", t.loc_start.file_path ) )

    im.SeparatorText( "stopped" )
    im.Text( fmt.ctprint( "proc:", t.loc_stop.procedure, ", line:", t.loc_stop.line, ", col: ", t.loc_stop.column ) )
    im.Text( fmt.ctprint( "file:", t.loc_stop.file_path ) )


    im.TreePop()
  }
  if t.parent_idx != 0
  {
    im.Unindent( indent_w )
  }
}

ui_display_any :: #force_inline proc( v: any, name: string, indent_idx := 0 )
{
  ui_display_type_info( type_info_of( v.id ), v, name, indent_idx )
}
ui_display_type_info :: proc( type: ^reflect.Type_Info, v: any, name: string, indent_idx := 0 )
{
  // indent_w : f32 = 15.0 * f32(indent_idx)
  // if indent_idx != 0
  // {
  //   im.Indent( indent_w ) 
  // }
  for i in 0 ..< indent_idx
  {
    im.Text( "| " )
    im.SameLine()
  }

  switch
  {
    case v.id == typeid_of( string ) || v.id == typeid_of( cstring ):
    { im.Text( fmt.ctprintf( "%s : %s = \"%s\"", name, v.id, v ) ) }
    case ( reflect.is_integer( type ) && !reflect.is_unsigned( type ) ):
    { im.DragInt( fmt.ctprintf( "%s : %s", name, v.id ), (^i32)(v.data) ) }
    case ( reflect.is_integer( type ) && reflect.is_unsigned( type ) ):
    { im.DragInt( fmt.ctprintf( "%s : %s", name, v.id ), (^i32)(v.data), 1.0, 0.0 ) }
    case reflect.is_float( type ):
    { im.DragFloat( fmt.ctprintf( "%s : %s", name, v.id ), (^f32)(v.data), 0.05 ) }
    case v.id == typeid_of( bool ):
    { im.Checkbox( fmt.ctprintf( "%s : %s", name, v.id ), (^bool)(v.data) ) }
    case v.id == typeid_of( [2]f32 ) || v.id == typeid_of( linalg.vec2 ): 
    { im.DragFloat2( fmt.ctprintf( "%s : %s", name, v.id ), (^[2]f32)(v.data), 0.05 ) }
    case v.id == typeid_of( [3]f32 ) || v.id == typeid_of( linalg.vec3 ): 
    { im.DragFloat3( fmt.ctprintf( "%s : %s", name, v.id ), (^[3]f32)(v.data), 0.05 ) }
    case v.id == typeid_of( [4]f32 ) || v.id == typeid_of( linalg.vec4 ): 
    { im.DragFloat4( fmt.ctprintf( "%s : %s", name, v.id ), (^[4]f32)(v.data), 0.05 ) }
    case reflect.is_array( type ) || reflect.is_dynamic_array( type ):
    {
      if im.CollapsingHeader( fmt.ctprintf( "%s : %s", name, v.id ) )
      {
        for idx := 0; idx < reflect.length( v ); idx += 1
        { 
          val : any
          ok  : bool
          _idx := idx
          val, _idx, ok = reflect.iterate_array( v, &_idx )
          if !ok { break }
          // im.Text( fmt.ctprintf( "%s[%d] : %s = %v", name, idx, val.id, val ) ) 
          ui_display_any( val, fmt.tprintf( "%s[%d]", name, idx ), indent_idx +1 )
        }
      }
    }
    case reflect.is_struct( type ):
    {
      ui_display_struct_members( v, name, indent_idx +1 )
    }
    case: 
    { im.Text( fmt.ctprintf( "%s : %s = %v", name, type, v ) ) }
  }
  
  // if indent_ix != 0
  // {
  //   im.Unindent( indent_w )
  // }
}
ui_display_struct_members :: proc( value: any, name: string, indent_idx := 1 )
{
  if im.CollapsingHeader( fmt.ctprintf( "%s : %s", name, value.id  ) ) 
  {
    types_arr  := reflect.struct_field_types( value.id )
    names_arr  := reflect.struct_field_names( value.id )
    for type, i in types_arr
    {
      v := reflect.struct_field_value_by_name( value, names_arr[i] )
      ui_display_type_info( type, v, names_arr[i], indent_idx )
    }
  }
}
