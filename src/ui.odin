package core 

DISABLE_DOCKING :: #config(DISABLE_DOCKING, false)

import im "../external/odin-imgui"
import    "../external/odin-imgui/imgui_impl_glfw"
import    "../external/odin-imgui/imgui_impl_opengl3"

import    "vendor:glfw"
import gl "vendor:OpenGL"


ui_init :: proc()
{
	im.CHECKVERSION()
	im.CreateContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
	when !DISABLE_DOCKING {
		io.ConfigFlags += {.DockingEnable}
		io.ConfigFlags += {.ViewportsEnable}

		style := im.GetStyle()
		style.WindowRounding = 0
		style.Colors[im.Col.WindowBg].w = 1
	}

	im.StyleColorsDark()

	imgui_impl_glfw.InitForOpenGL(data.window, true)
	imgui_impl_opengl3.Init("#version 150")
}

ui_update :: proc()
{
	imgui_impl_opengl3.NewFrame()
	imgui_impl_glfw.NewFrame()
	im.NewFrame()

	im.ShowDemoWindow()

	if im.Begin("Window containing a quit button") {
		if im.Button("The quit button in question") {
			glfw.SetWindowShouldClose(data.window, true)
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
