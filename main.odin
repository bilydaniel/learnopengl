package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"

VERTEX_SHADER_SOURCE :: string(#load("shader.vert"))
FRAGMENT_SHADER_SOURCE :: string(#load("shader.frag"))

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
	// vertices := []f32 {
	// 	0.5, // top right
	// 	0.5,
	// 	0.0,
	// 	0.5, // bottom right
	// 	-0.5,
	// 	0.0,
	// 	-0.5, // bottom left
	// 	-0.5,
	// 	0.0,
	// 	-0.5, //top left
	// 	0.5,
	// 	0.0,
	// }

	vertices := []f32 {
		// first triangle
		-0.9,
		-0.5,
		0.0, // left
		-0.0,
		-0.5,
		0.0, // right
		-0.45,
		0.5,
		0.0, // top
		// second triangle
		0.0,
		-0.5,
		0.0, // left
		0.9,
		-0.5,
		0.0, // right
		0.45,
		0.5,
		0.0, // top
	}

	indices := []u32 {
		0, // first triangle
		1,
		3,
		1, // second
		2,
		3,
	}


	vao: u32 = 0
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao) // activates it as a global

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

	// EBO
	ebo: u32 = 0
	gl.GenBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.STATIC_DRAW,
	)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo) // binding and unbinding ebo also binds it to the vao, so if you dont want to unbind them first unbind vao

	vertexShaderId := gl.CreateShader(gl.VERTEX_SHADER)
	cVertexShaderSouce := strings.clone_to_cstring(VERTEX_SHADER_SOURCE)
	gl.ShaderSource(vertexShaderId, 1, &cVertexShaderSouce, nil)
	gl.CompileShader(vertexShaderId)
	checkShaderCompilation(vertexShaderId)


	fragmentShaderId := gl.CreateShader(gl.FRAGMENT_SHADER)
	cFragmentShaderSouce := strings.clone_to_cstring(FRAGMENT_SHADER_SOURCE)
	gl.ShaderSource(fragmentShaderId, 1, &cFragmentShaderSouce, nil)
	gl.CompileShader(fragmentShaderId)
	checkShaderCompilation(fragmentShaderId)

	shaderProgramId := gl.CreateProgram()
	gl.AttachShader(shaderProgramId, vertexShaderId)
	gl.AttachShader(shaderProgramId, fragmentShaderId)
	gl.LinkProgram(shaderProgramId)
	checkProgramLinking(shaderProgramId)

	gl.UseProgram(shaderProgramId)

	gl.DeleteShader(vertexShaderId)
	gl.DeleteShader(fragmentShaderId)

	// 0 == layout(location = 0) in vec3 aPos; in vertex shader
	// also puts data of vbo to vao
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))

	gl.EnableVertexAttribArray(0)
	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)


	for !glfw.WindowShouldClose(window) {
		// input
		processInput(window)

		// render
		gl.ClearColor(0.2, 0.3, 0.3, 1.0) // sets the color
		gl.Clear(gl.COLOR_BUFFER_BIT) // uses the color to clear

		gl.UseProgram(shaderProgramId)
		gl.BindVertexArray(vao)

		gl.DrawArrays(gl.TRIANGLES, 0, 6)

		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		//gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

		//gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)))
		gl.BindVertexArray(0)


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

checkShaderCompilation :: proc(shaderId: u32) {
	success: i32
	info: [512]u8

	gl.GetShaderiv(shaderId, gl.COMPILE_STATUS, &success)

	if success == 0 {
		gl.GetShaderInfoLog(shaderId, 512, nil, raw_data(info[:]))
		err := string(cstring(raw_data(info[:])))
		log.error(err)
	}
}

checkProgramLinking :: proc(shaderProgramId: u32) {
	success: i32
	info: [512]u8

	gl.GetProgramiv(shaderProgramId, gl.LINK_STATUS, &success)

	if success == 0 {
		gl.GetProgramInfoLog(shaderProgramId, 512, nil, raw_data(info[:]))
		err := string(cstring(raw_data(info[:])))
		log.error(err)
	}
}
