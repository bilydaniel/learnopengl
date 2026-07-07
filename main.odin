package main

import "base:runtime"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	glfw.Init()
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(800, 600, "Learn OpenGL", nil, nil)
	if window == nil {
		log.error("failed to create window")
		return
	}

	glfw.MakeContextCurrent(window)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 800, 600)
	glfw.SetFramebufferSizeCallback(window, windowResize)

	// TRIANGLE
	// 0 0 is middle -1 left, -1 down
	vertices := []f32 {
		-0.5, //
		-0.5,
		0.0,
		0.5, //
		-0.5,
		0.0,
		0.0, //
		0.5,
		0.0,
	}

	// vertex buffer object
	vbo: u32 = 0
	// generate a buffer, we can make more than one at a time
	gl.GenBuffers(1, &vbo)
	// bind the buffer
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)


	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	) // array_buffer = vbo (its bound)


	for !glfw.WindowShouldClose(window) {
		// input
		processInput(window)

		// render
		gl.ClearColor(0.2, 0.3, 0.3, 1.0) // sets the color
		gl.Clear(gl.COLOR_BUFFER_BIT) // uses the color to clear


		glfw.PollEvents()
		glfw.SwapBuffers(window)
	}

}

// if i need context here, its officially a C function, doesent have context
// context = runtime.default_context()
windowResize :: proc "cdecl" (window: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}

processInput :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}
