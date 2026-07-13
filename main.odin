package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

VERTEX_SHADER_SOURCE :: string(#load("shader.vert"))
FRAGMENT_SHADER_SOURCE :: string(#load("shader.frag"))
FRAGMENT_SHADER_YELLOW_SOURCE :: string(#load("shader_yellow.frag"))

Shader :: struct {
	id: u32,
}

shader_make :: proc(vertex_path: string, fragment_path: string) -> (Shader, bool) {
	shader := Shader{}
	temp := runtime.default_temp_allocator_temp_begin()
	defer runtime.default_temp_allocator_temp_end(temp)

	vertex_shader_source, err := os.read_entire_file(vertex_path, context.temp_allocator)
	if err != nil {
		fmt.eprintfln("vertex shader read error: %s", err)
		return shader, false
	}

	fragment_shader_source, err2 := os.read_entire_file(fragment_path, context.temp_allocator)
	if err2 != nil {
		fmt.eprintfln("vertex shader read error: %s", err)
		return shader, false
	}

	vertex_shader_id := shader_compile(gl.VERTEX_SHADER, string(vertex_shader_source))
	fragment_shader_id := shader_compile(gl.FRAGMENT_SHADER, string(fragment_shader_source))

	shader_program_id := gl.CreateProgram()
	gl.AttachShader(shader_program_id, vertex_shader_id)
	gl.AttachShader(shader_program_id, fragment_shader_id)
	gl.LinkProgram(shader_program_id)
	checkProgramLinking(shader_program_id)

	gl.DeleteShader(vertex_shader_id)
	gl.DeleteShader(fragment_shader_id)

	shader.id = shader_program_id

	return shader, true
}

shader_compile :: proc(shader_type: u32, shader_source: string) -> u32 {
	shader_id := gl.CreateShader(shader_type)
	shader_source_c := strings.clone_to_cstring(shader_source, context.temp_allocator)
	gl.ShaderSource(shader_id, 1, &shader_source_c, nil)
	gl.CompileShader(shader_id)
	checkShaderCompilation(shader_id)

	return shader_id
}

shader_use :: proc(shader: Shader) {
	gl.UseProgram(shader.id)
}

shader_set_bool :: proc(shader: Shader, name: cstring, value: bool) {
}

shader_set_int :: proc(shader: Shader, name: cstring, value: i32) {
}

shader_set_float :: proc(shader: Shader, name: cstring, value: f32) {
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


	
	//odinfmt: disable
	vertices := []f32{
		// positions          // colors
		 0.5, -0.5, 0.0,      1.0, 0.0, 0.0, // bottom right
		-0.5, -0.5, 0.0,      0.0, 1.0, 0.0, // bottom left
		 0.0,  0.5, 0.0,      0.0, 0.0, 1.0, // top
	}
	//odinfmt: enable

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

	// 0 == layout(location = 0) in vec3 aPos; in vertex shader
	// also puts data of vbo to vao
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), uintptr(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)


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

	shader_program, ok := shader_make("shader.vert", "shader.frag")
	if !ok {
		return
	}

	shader_use(shader_program)

	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)


	for !glfw.WindowShouldClose(window) {
		// input
		processInput(window)

		// render

		timeValue := glfw.GetTime()
		greenValue: f32 = f32((math.sin(timeValue) / 2) + 0.5)
		redValue: f32 = f32((math.cos(timeValue) / 2) + 0.5)
		vertexColorLocation := gl.GetUniformLocation(shader_program.id, "myColor")
		shader_use(shader_program) // activate the shader first to set the uniform
		gl.Uniform4f(vertexColorLocation, redValue, greenValue, 0, 1)


		gl.ClearColor(0.2, 0.3, 0.3, 1.0) // sets the color
		gl.Clear(gl.COLOR_BUFFER_BIT) // uses the color to clear


		gl.BindVertexArray(vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)


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
