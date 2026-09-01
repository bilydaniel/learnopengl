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
