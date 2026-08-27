#version 330 core

in vec3 Normal;
in vec3 FragPos;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 cameraPos;

out vec4 FragColor;

void main()
{
    // AMBIENT
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;

    // DIFFUSE
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);

    float diffStrength = 1.0;
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diffStrength * diff * lightColor;

    // SPECULAR
    float specularStrength = 0.5;
    vec3 viewDir = normalize(cameraPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * lightColor;

    vec3 light = (ambient + diffuse + specular);

    vec3 result = light * objectColor;
    FragColor = vec4(result, 1.0);
}
