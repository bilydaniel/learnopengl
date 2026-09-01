package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import la "core:math/linalg"
import "core:os"
import "core:strings"
import stbi "vendor:stb/image"

import gl "vendor:OpenGL"
import "vendor:glfw"

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
		fmt.eprintfln("vertex shader read error: %s", err2)
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
	location := gl.GetUniformLocation(shader.id, name)
	gl.Uniform1i(location, i32(value))
}

shader_set_int :: proc(shader: Shader, name: cstring, value: i32) {
	location := gl.GetUniformLocation(shader.id, name)
	gl.Uniform1i(location, value)
}

shader_set_float :: proc(shader: Shader, name: cstring, value: f32) {
	location := gl.GetUniformLocation(shader.id, name)
	gl.Uniform1f(location, value)
}

shader_set_vec3 :: proc(shader: Shader, name: cstring, value: [^]f32) {
	location := gl.GetUniformLocation(shader.id, name)
	gl.Uniform3fv(location, 1, value)
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

Camera :: struct {
	pos:   la.Vector3f32,
	front: la.Vector3f32,
	up:    la.Vector3f32,
	fov:   f32,
	yaw:   f32,
	pitch: f32,
}

init_camera :: proc() -> ^Camera {
	camera := new(Camera)
	camera.pos = la.Vector3f32{0, 0, 6}
	camera.front = la.Vector3f32{0, 0, -1}
	camera.up = la.Vector3f32{0, 1, 0}
	camera.fov = 45
	camera.yaw = -90
	camera.pitch = 0

	return camera
}


get_view_matrix :: proc(camera: ^Camera) -> la.Matrix4f32 {
	//TODO: @finish
	result := la.Matrix4f32{}

	return result
}

d_time: f32 = 0
last_frame: f32 = 0

last_mouse_x: f64 = 400
last_mouse_y: f64 = 300
first_mouse := true
camera: ^Camera = nil

light_pos: la.Vector3f32 = {1.2, 1.0, 2.0}

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	camera = init_camera()
	glfw.Init()
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
	gl.Enable(gl.DEPTH_TEST)
	glfw.SetFramebufferSizeCallback(window, windowResize)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	cube_positions := [dynamic]la.Vector3f32{}
	append(&cube_positions, la.Vector3f32{0, 0, 0})
	append(&cube_positions, la.Vector3f32{2, 5, -15})
	append(&cube_positions, la.Vector3f32{-1.5, -2.2, -2.5})
	append(&cube_positions, la.Vector3f32{-3.8, -2, -12.3})
	append(&cube_positions, la.Vector3f32{2.4, -0.4, -3.5})
	append(&cube_positions, la.Vector3f32{-1.7, 3, -7.5})
	append(&cube_positions, la.Vector3f32{1.3, -2, -2.5})
	append(&cube_positions, la.Vector3f32{1.5, 2, -2.5})
	append(&cube_positions, la.Vector3f32{1.5, 0.2, -1.5})
	append(&cube_positions, la.Vector3f32{-1.3, 1, -1.5})

	point_light_positions := [dynamic]la.Vector3f32{}
	append(&point_light_positions, la.Vector3f32{0.7, 0.2, 2})
	append(&point_light_positions, la.Vector3f32{2.3, -3.3, -4})
	append(&point_light_positions, la.Vector3f32{-4, 2, -12})
	append(&point_light_positions, la.Vector3f32{0, 0, -3})

	vertices: [dynamic]f32 = {}

	// Back Face
	append(&vertices, -0.5, -0.5, -0.5)
	append(&vertices, 0.0, 0.0, -1.0)
	append(&vertices, 0.0, 0.0)

	append(&vertices, 0.5, -0.5, -0.5)
	append(&vertices, 0.0, 0.0, -1.0)
	append(&vertices, 1.0, 0.0)

	append(&vertices, 0.5, 0.5, -0.5)
	append(&vertices, 0.0, 0.0, -1.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, 0.5, 0.5, -0.5)
	append(&vertices, 0.0, 0.0, -1.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, -0.5, 0.5, -0.5)
	append(&vertices, 0.0, 0.0, -1.0)
	append(&vertices, 0.0, 1.0)

	append(&vertices, -0.5, -0.5, -0.5)
	append(&vertices, 0.0, 0.0, -1.0)
	append(&vertices, 0.0, 0.0)

	// Front Face
	append(&vertices, -0.5, -0.5, 0.5)
	append(&vertices, 0.0, 0.0, 1.0)
	append(&vertices, 0.0, 0.0)

	append(&vertices, 0.5, -0.5, 0.5)
	append(&vertices, 0.0, 0.0, 1.0)
	append(&vertices, 1.0, 0.0)

	append(&vertices, 0.5, 0.5, 0.5)
	append(&vertices, 0.0, 0.0, 1.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, 0.5, 0.5, 0.5)
	append(&vertices, 0.0, 0.0, 1.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, -0.5, 0.5, 0.5)
	append(&vertices, 0.0, 0.0, 1.0)
	append(&vertices, 0.0, 1.0)

	append(&vertices, -0.5, -0.5, 0.5)
	append(&vertices, 0.0, 0.0, 1.0)
	append(&vertices, 0.0, 0.0)

	// Left Face
	append(&vertices, -0.5, 0.5, 0.5)
	append(&vertices, -1.0, 0.0, 0.0)
	append(&vertices, 0.0, 0.0)

	append(&vertices, -0.5, 0.5, -0.5)
	append(&vertices, -1.0, 0.0, 0.0)
	append(&vertices, 1.0, 0.0)

	append(&vertices, -0.5, -0.5, -0.5)
	append(&vertices, -1.0, 0.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, -0.5, -0.5, -0.5)
	append(&vertices, -1.0, 0.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, -0.5, -0.5, 0.5)
	append(&vertices, -1.0, 0.0, 0.0)
	append(&vertices, 0.0, 1.0)

	append(&vertices, -0.5, 0.5, 0.5)
	append(&vertices, -1.0, 0.0, 0.0)
	append(&vertices, 0.0, 0.0)

	// Right Face
	append(&vertices, 0.5, 0.5, 0.5)
	append(&vertices, 1.0, 0.0, 0.0)
	append(&vertices, 0.0, 0.0)

	append(&vertices, 0.5, 0.5, -0.5)
	append(&vertices, 1.0, 0.0, 0.0)
	append(&vertices, 1.0, 0.0)

	append(&vertices, 0.5, -0.5, -0.5)
	append(&vertices, 1.0, 0.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, 0.5, -0.5, -0.5)
	append(&vertices, 1.0, 0.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, 0.5, -0.5, 0.5)
	append(&vertices, 1.0, 0.0, 0.0)
	append(&vertices, 0.0, 1.0)

	append(&vertices, 0.5, 0.5, 0.5)
	append(&vertices, 1.0, 0.0, 0.0)
	append(&vertices, 0.0, 0.0)

	// Bottom Face
	append(&vertices, -0.5, -0.5, -0.5)
	append(&vertices, 0.0, -1.0, 0.0)
	append(&vertices, 0.0, 0.0)

	append(&vertices, 0.5, -0.5, -0.5)
	append(&vertices, 0.0, -1.0, 0.0)
	append(&vertices, 1.0, 0.0)

	append(&vertices, 0.5, -0.5, 0.5)
	append(&vertices, 0.0, -1.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, 0.5, -0.5, 0.5)
	append(&vertices, 0.0, -1.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, -0.5, -0.5, 0.5)
	append(&vertices, 0.0, -1.0, 0.0)
	append(&vertices, 0.0, 1.0)

	append(&vertices, -0.5, -0.5, -0.5)
	append(&vertices, 0.0, -1.0, 0.0)
	append(&vertices, 0.0, 0.0)

	// Top Face
	append(&vertices, -0.5, 0.5, -0.5)
	append(&vertices, 0.0, 1.0, 0.0)
	append(&vertices, 0.0, 0.0)

	append(&vertices, 0.5, 0.5, -0.5)
	append(&vertices, 0.0, 1.0, 0.0)
	append(&vertices, 1.0, 0.0)

	append(&vertices, 0.5, 0.5, 0.5)
	append(&vertices, 0.0, 1.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, 0.5, 0.5, 0.5)
	append(&vertices, 0.0, 1.0, 0.0)
	append(&vertices, 1.0, 1.0)

	append(&vertices, -0.5, 0.5, 0.5)
	append(&vertices, 0.0, 1.0, 0.0)
	append(&vertices, 0.0, 1.0)

	append(&vertices, -0.5, 0.5, -0.5)
	append(&vertices, 0.0, 1.0, 0.0)
	append(&vertices, 0.0, 0.0)

	vao: u32 = 0
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)


	vbo: u32 = 0
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)


	width, height, channels: i32
	container := stbi.load("container2.png", &width, &height, &channels, 3)
	if container == nil {
		log.error("failed loading file")
		return
	}

	texture: u32
	gl.GenTextures(1, &texture)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_BORDER)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_BORDER)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, container)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	stbi.image_free(container)


	width2, height2, channels2: i32
	container_spec := stbi.load("container2_specular.png", &width2, &height2, &channels2, 3)
	if container_spec == nil {
		log.error("failed loading file")
		return
	}

	texture_spec: u32
	gl.GenTextures(1, &texture_spec)
	gl.ActiveTexture(gl.TEXTURE1)
	gl.BindTexture(gl.TEXTURE_2D, texture_spec)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_BORDER)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_BORDER)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGB,
		width2,
		height2,
		0,
		gl.RGB,
		gl.UNSIGNED_BYTE,
		container_spec,
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	stbi.image_free(container_spec)

	stride: i32 = 8 * size_of(f32)
	// POS
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, uintptr(0))
	gl.EnableVertexAttribArray(0)
	// NORMAL
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, stride, uintptr(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)
	// TEXTURE
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, stride, uintptr(6 * size_of(f32)))
	gl.EnableVertexAttribArray(2)


	lighting_shader, lighting_shader_ok := shader_make(
		"lighting_shader.vert",
		"lighting_shader.frag",
	)
	if !lighting_shader_ok {
		return
	}
	shader_use(lighting_shader)

	shader_set_int(lighting_shader, "material.diffuse", 0)
	shader_set_int(lighting_shader, "material.specular", 1)
	shader_set_float(lighting_shader, "material.shininess", 32.0)


	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	model_location := gl.GetUniformLocation(lighting_shader.id, "model")
	view_location := gl.GetUniformLocation(lighting_shader.id, "view")
	projection_location := gl.GetUniformLocation(lighting_shader.id, "projection")


	light_vao: u32 = 0
	gl.GenVertexArrays(1, &light_vao)
	gl.BindVertexArray(light_vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	//POS
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, uintptr(0))
	gl.EnableVertexAttribArray(0)


	light_source_shader, light_source_ok := shader_make(
		"light_source_shader.vert",
		"light_source_shader.frag",
	)
	if !light_source_ok {
		return
	}
	shader_use(light_source_shader)

	model_location_light_source := gl.GetUniformLocation(light_source_shader.id, "model")
	view_location_light_source := gl.GetUniformLocation(light_source_shader.id, "view")
	projection_location_light_source := gl.GetUniformLocation(light_source_shader.id, "projection")


	for !glfw.WindowShouldClose(window) {
		current_frame := f32(glfw.GetTime())
		d_time = current_frame - last_frame
		last_frame = current_frame

		process_input(window) // input
		shader_use(lighting_shader) // activate the shader first to set the uniform


		// t := f32(glfw.GetTime())
		// light_pos.x = 3 * math.cos(t)
		// light_pos.z = 3 * math.sin(t)
		shader_set_vec3(lighting_shader, "cameraPos", raw_data(&camera.pos))
		//shader_set_vec3(lighting_shader, "light.position", raw_data(&light_pos))
		light_color := la.Vector3f32{1, 1, 1}

		// directional light
		dir_light_direction: la.Vector3f32 = {-0.2, -1.0, -0.3}
		dir_light_ambient: la.Vector3f32 = {0.05, 0.05, 0.05}
		dir_light_diffuse: la.Vector3f32 = {0.4, 0.4, 0.4}
		dir_light_specular: la.Vector3f32 = {0.5, 0.5, 0.5}

		shader_set_vec3(lighting_shader, "dirLight.direction", raw_data(&dir_light_direction))
		shader_set_vec3(lighting_shader, "dirLight.ambient", raw_data(&dir_light_ambient))
		shader_set_vec3(lighting_shader, "dirLight.diffuse", raw_data(&dir_light_diffuse))
		shader_set_vec3(lighting_shader, "dirLight.specular", raw_data(&dir_light_specular))

		// point lights
		point_light_ambient: la.Vector3f32 = {0.05, 0.05, 0.05}
		point_light_diffuse: la.Vector3f32 = {0.8, 0.8, 0.8}
		point_light_specular: la.Vector3f32 = {1.0, 1.0, 1.0}

		point_light_names := [4]cstring {
			"pointLights[0]",
			"pointLights[1]",
			"pointLights[2]",
			"pointLights[3]",
		}

		temp := runtime.default_temp_allocator_temp_begin()
		for i in 0 ..< 4 {
			pos := point_light_positions[i]
			position_name := strings.clone_to_cstring(
				fmt.tprintf("%s.position", point_light_names[i]),
				context.temp_allocator,
			)
			ambient_name := strings.clone_to_cstring(
				fmt.tprintf("%s.ambient", point_light_names[i]),
				context.temp_allocator,
			)
			diffuse_name := strings.clone_to_cstring(
				fmt.tprintf("%s.diffuse", point_light_names[i]),
				context.temp_allocator,
			)
			specular_name := strings.clone_to_cstring(
				fmt.tprintf("%s.specular", point_light_names[i]),
				context.temp_allocator,
			)
			constant_name := strings.clone_to_cstring(
				fmt.tprintf("%s.constant", point_light_names[i]),
				context.temp_allocator,
			)
			linear_name := strings.clone_to_cstring(
				fmt.tprintf("%s.linear", point_light_names[i]),
				context.temp_allocator,
			)
			quadratic_name := strings.clone_to_cstring(
				fmt.tprintf("%s.quadratic", point_light_names[i]),
				context.temp_allocator,
			)

			shader_set_vec3(lighting_shader, position_name, raw_data(&pos))
			shader_set_vec3(lighting_shader, ambient_name, raw_data(&point_light_ambient))
			shader_set_vec3(lighting_shader, diffuse_name, raw_data(&point_light_diffuse))
			shader_set_vec3(lighting_shader, specular_name, raw_data(&point_light_specular))
			shader_set_float(lighting_shader, constant_name, 1.0)
			shader_set_float(lighting_shader, linear_name, 0.09)
			shader_set_float(lighting_shader, quadratic_name, 0.032)
		}
		runtime.default_temp_allocator_temp_end(temp)

		// spotLight
		spot_light_ambient: la.Vector3f32 = {0.0, 0.0, 0.0}
		spot_light_diffuse: la.Vector3f32 = {1.0, 1.0, 1.0}
		spot_light_specular: la.Vector3f32 = {1.0, 1.0, 1.0}

		shader_set_vec3(lighting_shader, "spotLight.position", raw_data(&camera.pos))
		shader_set_vec3(lighting_shader, "spotLight.direction", raw_data(&camera.front))
		shader_set_vec3(lighting_shader, "spotLight.ambient", raw_data(&spot_light_ambient))
		shader_set_vec3(lighting_shader, "spotLight.diffuse", raw_data(&spot_light_diffuse))
		shader_set_vec3(lighting_shader, "spotLight.specular", raw_data(&spot_light_specular))
		shader_set_float(lighting_shader, "spotLight.constant", 1.0)
		shader_set_float(lighting_shader, "spotLight.linear", 0.09)
		shader_set_float(lighting_shader, "spotLight.quadratic", 0.032)
		shader_set_float(lighting_shader, "spotLight.cutoff", math.cos(math.to_radians(f32(12.5))))
		shader_set_float(
			lighting_shader,
			"spotLight.outerCutoff",
			math.cos(math.to_radians(f32(15.0))),
		)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Clear(gl.DEPTH_BUFFER_BIT)

		gl.BindVertexArray(vao)
		view := la.matrix4_look_at_f32(camera.pos, camera.pos + camera.front, camera.up)
		perspective := la.matrix4_perspective(math.to_radians(camera.fov), 800.0 / 600, 0.1, 100.0)

		gl.UniformMatrix4fv(view_location, 1, gl.FALSE, raw_data(&view))
		gl.UniformMatrix4fv(projection_location, 1, gl.FALSE, raw_data(&perspective))

		translate := la.matrix4_translate(la.Vector3f32{0, 0, 0})
		angle: f32 = 0
		rotate := la.matrix4_rotate(angle, la.Vector3f32{1.0, 0.0, 0.0})
		model := translate * rotate
		gl.UniformMatrix4fv(model_location, 1, gl.FALSE, raw_data(&model))


		for i := 0; i < len(cube_positions); i += 1 {
			translate := la.matrix4_translate(cube_positions[i])

			angle: f32 = 20 * f32(i)
			if i % 2 == 0 {
				angle += f32(glfw.GetTime())
			} else {
				angle -= f32(glfw.GetTime())
			}

			rotate := la.matrix4_rotate(angle, la.Vector3f32{1.0, 0.3, 0.5})
			model := translate * rotate
			gl.UniformMatrix4fv(model_location, 1, gl.FALSE, raw_data(&model))

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}
		//gl.DrawArrays(gl.TRIANGLES, 0, 36)

		// LIGHT SOURCE
		shader_use(light_source_shader)
		gl.BindVertexArray(light_vao)
		gl.UniformMatrix4fv(view_location_light_source, 1, gl.FALSE, raw_data(&view))
		gl.UniformMatrix4fv(projection_location_light_source, 1, gl.FALSE, raw_data(&perspective))
		shader_set_vec3(light_source_shader, "lightColor", raw_data(&light_color))

		for point_light_position in point_light_positions {
			translate_light_source := la.matrix4_translate(point_light_position)
			angle_light_source: f32 = 0
			rotate_light_source := la.matrix4_rotate(
				angle_light_source,
				la.Vector3f32{1.0, 0.0, 0.0},
			)
			scale_light_source := la.matrix4_scale(la.Vector3f32{0.2, 0.2, 0.2})
			model_light_source := translate_light_source * rotate_light_source * scale_light_source
			gl.UniformMatrix4fv(
				model_location_light_source,
				1,
				gl.FALSE,
				raw_data(&model_light_source),
			)

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

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

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}

	ratio_delta: f32 = 0.001

	camera_speed: f32 = 2.5 * d_time
	if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
		camera.pos += camera.front * camera_speed
	}

	if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
		camera.pos -= camera.front * camera_speed
	}

	if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
		camera_right := la.normalize(la.cross(camera.front, camera.up))
		camera.pos -= camera_right * camera_speed
	}

	if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
		camera_right := la.normalize(la.cross(camera.front, camera.up))
		camera.pos += camera_right * camera_speed
	}

	if glfw.GetKey(window, glfw.KEY_SPACE) == glfw.PRESS {
		camera.pos += camera.up * camera_speed
	}

	if glfw.GetKey(window, glfw.KEY_LEFT_CONTROL) == glfw.PRESS {
		camera.pos -= camera.up * camera_speed
	}

}

loadFile :: proc(filePath: string) -> []byte {
	result, err := os.read_entire_file(filePath, context.allocator)
	if err != nil {
		log.error("failed to load image %s - %s", "container.jpg", err)
	}
	return result
}

mouse_callback :: proc "cdecl" (window: glfw.WindowHandle, x: f64, y: f64) {
	if first_mouse {
		last_mouse_x = x
		last_mouse_y = y
		first_mouse = false
	}
	x_offset := x - last_mouse_x
	y_offset := last_mouse_y - y // y is bottom to top

	last_mouse_x = x
	last_mouse_y = y

	sensitivity := 0.1

	x_offset_sensitivity := x_offset * sensitivity
	y_offset_sensitivity := y_offset * sensitivity

	camera.yaw += f32(x_offset_sensitivity)
	camera.pitch += f32(y_offset_sensitivity)

	if camera.pitch > 89 {
		camera.pitch = 89
	}

	if camera.pitch < -89 {
		camera.pitch = -89
	}

	camera_direction := la.Vector3f32{}
	camera_direction.x =
		math.cos(math.to_radians(camera.yaw)) * math.cos(math.to_radians(camera.pitch))
	camera_direction.y = math.sin(math.to_radians(camera.pitch))
	camera_direction.z =
		math.sin(math.to_radians(camera.yaw)) * math.cos(math.to_radians(camera.pitch))
	camera.front = la.normalize(camera_direction)
}

scroll_callback :: proc "cdecl" (window: glfw.WindowHandle, x: f64, y: f64) {
	camera.fov -= f32(y)

	if camera.fov < 1 {
		camera.fov = 1
	}

	if camera.fov > 45 {
		camera.fov = 45
	}
}
