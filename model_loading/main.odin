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


	point_light_positions := [dynamic]la.Vector3f32{}
	append(&point_light_positions, la.Vector3f32{0.7, 0.2, 2})

	vertices: [dynamic]f32 = {}

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


	// width, height, channels: i32
	// container := stbi.load("container2.png", &width, &height, &channels, 3)
	// if container == nil {
	// 	log.error("failed loading file")
	// 	return
	// }
	//
	// texture: u32
	// gl.GenTextures(1, &texture)
	// gl.ActiveTexture(gl.TEXTURE0)
	// gl.BindTexture(gl.TEXTURE_2D, texture)
	//
	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_BORDER)
	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_BORDER)
	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	//
	// gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, container)
	// gl.GenerateMipmap(gl.TEXTURE_2D)
	// stbi.image_free(container)


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


	// lighting_shader, lighting_shader_ok := shader_make(
	// 	"lighting_shader.vert",
	// 	"lighting_shader.frag",
	// )
	// if !lighting_shader_ok {
	// 	return
	// }
	// shader_use(lighting_shader)
	//
	// shader_set_int(lighting_shader, "material.diffuse", 0)
	// shader_set_int(lighting_shader, "material.specular", 1)
	// shader_set_float(lighting_shader, "material.shininess", 32.0)
	//
	//
	// gl.BindVertexArray(0)
	// gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	//
	// model_location := gl.GetUniformLocation(lighting_shader.id, "model")
	// view_location := gl.GetUniformLocation(lighting_shader.id, "view")
	// projection_location := gl.GetUniformLocation(lighting_shader.id, "projection")
	//
	//
	// light_vao: u32 = 0
	// gl.GenVertexArrays(1, &light_vao)
	// gl.BindVertexArray(light_vao)
	// gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	//
	// //POS
	// gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, uintptr(0))
	// gl.EnableVertexAttribArray(0)
	//
	//
	// light_source_shader, light_source_ok := shader_make(
	// 	"light_source_shader.vert",
	// 	"light_source_shader.frag",
	// )
	// if !light_source_ok {
	// 	return
	// }
	// shader_use(light_source_shader)
	//
	// model_location_light_source := gl.GetUniformLocation(light_source_shader.id, "model")
	// view_location_light_source := gl.GetUniformLocation(light_source_shader.id, "view")
	// projection_location_light_source := gl.GetUniformLocation(light_source_shader.id, "projection")

	mesh := mesh_init(nil, nil, nil)
	fmt.printf("mesh: %v\n", mesh)

	for !glfw.WindowShouldClose(window) {
		current_frame := f32(glfw.GetTime())
		d_time = current_frame - last_frame
		last_frame = current_frame

		process_input(window) // input
		//shader_use(lighting_shader) // activate the shader first to set the uniform


		//shader_set_vec3(lighting_shader, "cameraPos", raw_data(&camera.pos))
		light_color := la.Vector3f32{1, 1, 1}

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Clear(gl.DEPTH_BUFFER_BIT)

		gl.BindVertexArray(vao)
		view := la.matrix4_look_at_f32(camera.pos, camera.pos + camera.front, camera.up)
		perspective := la.matrix4_perspective(math.to_radians(camera.fov), 800.0 / 600, 0.1, 100.0)

		// gl.UniformMatrix4fv(view_location, 1, gl.FALSE, raw_data(&view))
		// gl.UniformMatrix4fv(projection_location, 1, gl.FALSE, raw_data(&perspective))

		translate := la.matrix4_translate(la.Vector3f32{0, 0, 0})
		angle: f32 = 0
		rotate := la.matrix4_rotate(angle, la.Vector3f32{1.0, 0.0, 0.0})
		model := translate * rotate
		//gl.UniformMatrix4fv(model_location, 1, gl.FALSE, raw_data(&model))


		//gl.DrawArrays(gl.TRIANGLES, 0, 36)

		// LIGHT SOURCE
		// shader_use(light_source_shader)
		// gl.BindVertexArray(light_vao)
		// gl.UniformMatrix4fv(view_location_light_source, 1, gl.FALSE, raw_data(&view))
		// gl.UniformMatrix4fv(projection_location_light_source, 1, gl.FALSE, raw_data(&perspective))
		// shader_set_vec3(light_source_shader, "lightColor", raw_data(&light_color))

		for point_light_position in point_light_positions {
			translate_light_source := la.matrix4_translate(point_light_position)
			angle_light_source: f32 = 0
			rotate_light_source := la.matrix4_rotate(
				angle_light_source,
				la.Vector3f32{1.0, 0.0, 0.0},
			)
			scale_light_source := la.matrix4_scale(la.Vector3f32{0.2, 0.2, 0.2})
			model_light_source := translate_light_source * rotate_light_source * scale_light_source
			// gl.UniformMatrix4fv(
			// 	model_location_light_source,
			// 	1,
			// 	gl.FALSE,
			// 	raw_data(&model_light_source),
			// )

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		gl.BindVertexArray(0)

		glfw.PollEvents()
		glfw.SwapBuffers(window)
	}

}
