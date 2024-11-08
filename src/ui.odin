package core 

DISABLE_DOCKING :: #config(DISABLE_DOCKING, false )

import im "../external/odin-imgui"
import    "../external/odin-imgui/imgui_impl_glfw"
import    "../external/odin-imgui/imgui_impl_opengl3"

import    "vendor:glfw"
import gl "vendor:OpenGL"

import    "core:os"
import    "core:fmt"

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
  style.Colors[im.Col.WindowBg]        = im.Vec4{ 0.2,  0.2,  0.2,  1.0 }

  style.Colors[im.Col.Header]          = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.HeaderHovered]   = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.HeaderActive]    = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.Tab]             = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.TabHovered]      = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.TabSelected]     = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.Button]          = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.ButtonActive]    = im.Vec4{ 0.05, 0.05, 0.05, 1.0 }
  style.Colors[im.Col.ButtonHovered]   = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.TitleBg]          = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.TitleBgActive]    = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.TitleBgCollapsed] = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.FrameBg]          = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.FrameBgActive]    = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.FrameBgHovered]   = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }

  style.Colors[im.Col.CheckMark]        = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }
  style.Colors[im.Col.SliderGrab]       = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }
  style.Colors[im.Col.SliderGrabActive] = im.Vec4{ 1.0,  1.0,  1.0,  1.0 }

  style.Colors[im.Col.Separator]        = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.SeparatorActive]  = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.SeparatorHovered] = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.ResizeGrip]        = im.Vec4{ 0.5,  0.5,  0.5,  1.0 }
  style.Colors[im.Col.ResizeGripHovered] = im.Vec4{ 0.6,  0.6,  0.6,  1.0 }
  style.Colors[im.Col.ResizeGripActive]  = im.Vec4{ 0.7,  0.7,  0.7,  1.0 }
  
  style.Colors[im.Col.DockingPreview]    = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }

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

	if im.Begin("characters") 
  {
		// if im.Button("The quit button in question") {
		// 	glfw.SetWindowShouldClose(data.window, true)
		// }
    if im.TreeNode("data.player_chars" )
    {
      for char, i in data.player_chars
      {
        if char.entity_idx > 0
        {
          if im.TreeNodeStr("char_window", "data.player_chars[%d]", i )
          {
            im.Text( "entity_idx:      %d", char.entity_idx )
            im.Text( "halo_entity_idx: %d", char.halo_entity_idx )
            im.Text( "has_path:        %d", char.has_path )
            im.Text( "path_len:        %d", len(char.path) )

            im.TreePop()
          }
        }
      }
      im.TreePop()
    }
    if im.TreeNode("framebuffers" )
    {
      SCALE :: 0.35
      w := f32(data.window_width)  * SCALE
      h := f32(data.window_height) * SCALE
      
      im.Text( "color" )
      im.Image( im.TextureID(uintptr(data.fb_deferred.buffer01)), im.Vec2{ w, h } )
      im.Text( "material" )
      im.Image( im.TextureID(uintptr(data.fb_deferred.buffer02)), im.Vec2{ w, h } )
      im.Text( "normal" )
      im.Image( im.TextureID(uintptr(data.fb_deferred.buffer03)), im.Vec2{ w, h } )
      im.Text( "position" )
      im.Image( im.TextureID(uintptr(data.fb_deferred.buffer04)), im.Vec2{ w, h } )
      im.Text( "lighting" )
      im.Image( im.TextureID(uintptr(data.fb_lighting.buffer01)), im.Vec2{ w, h } )

      im.TreePop()
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
	im.DestroyContext()
	imgui_impl_glfw.Shutdown()
	imgui_impl_opengl3.Shutdown()
}
