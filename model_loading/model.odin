package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import la "core:math/linalg"
import "core:os"
import "core:strconv"
import "core:strings"
import stbi "vendor:stb/image"

import gl "vendor:OpenGL"
import "vendor:glfw"

Vertex :: struct {
	position:  la.Vector3f32,
	normal:    la.Vector3f32,
	texCoords: la.Vector2f32,
}

Texture :: struct {
	id:   u32,
	type: string,
}

Vertices :: [dynamic]Vertex
Indices :: [dynamic]u32
Textures :: [dynamic]Texture

Mesh :: struct {
	vertices: Vertices,
	indices:  Indices,
	textures: Textures,
	vao:      u32,
	vbo:      u32,
	ebo:      u32,
}

mesh_init :: proc(vertices: Vertices, indices: Indices, textures: Textures) -> Mesh {
	mesh := Mesh{vertices, indices, textures, 0, 0, 0}
	setup_mesh(&mesh)

	return mesh
}

mesh_draw :: proc(mesh: ^Mesh, shader: Shader) {
	diffuse_nr: u32 = 1
	specular_nr: u32 = 1

	for i := 0; i < len(mesh.textures); i += 1 {
		gl.ActiveTexture(gl.TEXTURE0 + u32(i))

		number: string = {}
		name: string = mesh.textures[i].type // TODO: switch to enums?
		buffer: [64]byte = {}

		if (name == "texture_diffuse") {
			diffuse_nr += 1
			number = strconv.write_int(buffer[:], i64(diffuse_nr), 10)
		} else if (name == "texture_specular") {
			specular_nr += 1
			number = strconv.write_int(buffer[:], i64(specular_nr), 10)
		}

	}

}

setup_mesh :: proc(mesh: ^Mesh) {
	gl.GenVertexArrays(1, &mesh.vao)
	gl.GenBuffers(1, &mesh.vbo)
	gl.GenBuffers(1, &mesh.ebo)

	gl.BindVertexArray(mesh.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)

	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(mesh.vertices) * size_of(Vertex),
		raw_data(mesh.vertices),
		gl.STATIC_DRAW,
	)

	stride: i32 = size_of(Vertex)
	// POSITION
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, 0)
	// NORMAL
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, stride, offset_of(Vertex, normal))
	// TEXCOORDS
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, stride, offset_of(Vertex, texCoords))

	gl.BindVertexArray(0)
}
