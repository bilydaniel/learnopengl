#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec3 Normal;
out vec3 FragPos;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);

    Normal = aNormal;

    // this computation is necesery if i do non-uniform scaling, it breaks the normal vector
    //Normal = mat3(transpose(inverse(model))) * aNormal;
    // in practice calculate this on the cpu and send it via uniform, inverse is very expensive

    FragPos = vec3(model * vec4(aPos, 1.0));
}
