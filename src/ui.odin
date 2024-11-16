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

  // @TODO: custom font
  // im_io := im.GetIO()
  // im.FontAtlas_AddFontFromMemoryTTF()
  // f_config := im.FontConfig{  
  //
  // }
  // im.FontAtlas_AddFont( io.Fonts, f_config )
  // file_data, succsess := os.read_entire_file_from_filename( "assets/fonts/JetBrainsMonoNL-Regular.ttf" )
  // // fmt.println( "file_data", file_data )
  // fmt.println( "succsess: ", succsess )
  font     = im.FontAtlas_AddFontFromFileTTF( io.Fonts, "assets/fonts/JetBrainsMonoNL-Regular.ttf", 20 )
  font_big = im.FontAtlas_AddFontFromFileTTF( io.Fonts, "assets/fonts/JetBrainsMonoNL-Regular.ttf", 24 )
  im.FontAtlas_Build( io.Fonts )
  // im.PushFont( font )

}

// @TODO: this dont work too good
win_flags : im.WindowFlags = { im.WindowFlag.NoTitleBar }
p_open := true
ui_update :: proc()
{
	imgui_impl_opengl3.NewFrame()
	imgui_impl_glfw.NewFrame()
	im.NewFrame()

	im.ShowDemoWindow()

  im.DockSpaceOverViewport( 0, im.GetMainViewport(), { im.DockNodeFlag.PassthruCentralNode } )

  
  if p_open && im.Begin( "window", &p_open,  win_flags ) 
  {
    map_tab, entities_tab, player_chars_tab, framebuffers_tab, assetm_tab : bool
    if im.BeginTabBar( "tabs" )
    {
      if im.BeginTabItem( "map" )
      {
        // ui_map_tab()
        map_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "entities" )
      {
        // ui_entity_tab()
        entities_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "player_chars" )
      {
        // ui_player_chars_tab()
        player_chars_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "assetm" )
      {
        // ui_assetm_tab()
        assetm_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "framebuffers" )
      {
        // ui_framebuffer_tab()
        framebuffers_tab = true
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
    if      map_tab          { ui_map_tab()          }
    else if entities_tab     { ui_entity_tab()       }
    else if player_chars_tab { ui_player_chars_tab() }
    else if assetm_tab       { ui_assetm_tab()       }
    else if framebuffers_tab { ui_framebuffer_tab()  }
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

ui_entity_tab :: proc()
{
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
    if im.CollapsingHeader(tree_id_string_cstr )
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
        im.Text( "has_path:        %d", char.has_path )
        im.Text( "path_len:        %d", len(char.path) )

        // im.TreePop()
      }
    }
  }
  // }

}
ui_framebuffer_tab :: proc()
{
  // // if im.TreeNode( "framebuffers" )
  // if im.CollapsingHeader( "" )
  // {
  SCALE :: 0.35
  w := f32(data.window_width)  * SCALE
  h := f32(data.window_height) * SCALE

  im.Text( "color" )
  im.Image( im.TextureID(uintptr(data.fb_deferred.buffer01)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  im.Text( "material" )
  im.Image( im.TextureID(uintptr(data.fb_deferred.buffer02)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  im.Text( "normal" )
  im.Image( im.TextureID(uintptr(data.fb_deferred.buffer03)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  im.Text( "position" )
  im.Image( im.TextureID(uintptr(data.fb_deferred.buffer04)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  im.Text( "lighting" )
  im.Image( im.TextureID(uintptr(data.fb_lighting.buffer01)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  // }
}

level_combo_selected_idx := 0
ui_map_tab :: proc()
{
  tile_strs   := [?]cstring{ "empty", "blocked", "tile" }
  id_strs     := [?]cstring{ " ",     "X",       "#" }
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
        im.SeparatorText( tile_strs[id_strs_idx] )
        if im.Button( "empty" ) 
        { 
          if data.tile_type_arr[level][x][z] == Tile_Nav_Type.TRAVERSABLE ||
             data.tile_type_arr[level][x][z] == Tile_Nav_Type.BLOCKED
          {
            data_entity_remove( data.tile_entity_id_arr[level][x][z] )
          }
          data.tile_type_arr[level][x][z] = Tile_Nav_Type.EMPTY
        }
        if im.Button( "tile" )  
        {
          data_entity_add( 
                  entity_t{ pos = util_tile_to_pos( waypoint_t{ level, x, z } ), 
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
  // os.exit( 1 )
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

  for t in data.texture_arr
  {
    im.Text( str.clone_to_cstring( t.name, context.temp_allocator ) )

    SCALE :: 250
    w : f32 = SCALE * ( f32(t.width) / f32(t.height) )
    h : f32 = SCALE
    im.Image( im.TextureID(uintptr(t.handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  }
}
