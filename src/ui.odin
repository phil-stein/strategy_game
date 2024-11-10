package core 

DISABLE_DOCKING :: #config(DISABLE_DOCKING, false )

import im  "../external/odin-imgui"
import     "../external/odin-imgui/imgui_impl_glfw"
import     "../external/odin-imgui/imgui_impl_opengl3"

import     "vendor:glfw"
import gl  "vendor:OpenGL"

import     "core:os"
import     "core:fmt"
import     "core:strconv"
import str "core:strings"

font : ^im.Font

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
  font = im.FontAtlas_AddFontFromFileTTF( io.Fonts, "assets/fonts/JetBrainsMonoNL-Regular.ttf", 20 )
  im.FontAtlas_Build( io.Fonts )
  // im.PushFont( font )

}

ui_update :: proc()
{
	imgui_impl_opengl3.NewFrame()
	imgui_impl_glfw.NewFrame()
	im.NewFrame()

	im.ShowDemoWindow()

  im.DockSpaceOverViewport( 0, im.GetMainViewport(), { im.DockNodeFlag.PassthruCentralNode } )


  // @TODO: this dont work too good
  win_flags : im.WindowFlags = { im.WindowFlag.NoTitleBar }
  if im.Begin( "cock", nil,  win_flags ) 
  {
		// if im.Button("The quit button in question") {
		// 	glfw.SetWindowShouldClose(data.window, true)
		// }

    if im.BeginTabBar( "tabs" )
    {
      if im.BeginTabItem( "entities" )
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
        im.EndTabItem()
      }
      if im.BeginTabItem( "player_chars" )
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
        im.EndTabItem()
      }
      if im.BeginTabItem( "framebuffers" )
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
        im.EndTabItem()
      }
      // if im.BeginTabItem( "my" )
      // {
      //   im.EndTabItem()
      // }
      // if im.BeginTabItem( "snorkle" )
      // {
      //   im.EndTabItem()
      // }
      im.EndTabBar()
    }
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
