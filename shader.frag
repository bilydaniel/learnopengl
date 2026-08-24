#version 330 core

out vec4 FragColor;
in vec2 TexCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform float ratio;

void main()
{
    //FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    //FragColor = vec4(myColor, 1.0);
    //FragColor = vec4(posColor, 1.0);
    //FragColor = texture(myTexture, TexCoord) * vec4(myColor, 1);
    vec2 flippedTexCoord = vec2(-TexCoord.x, TexCoord.y);
    //FragColor = mix(texture(texture1, TexCoord), texture(texture2, flippedTexCoord), ratio);
    FragColor = texture(texture1, TexCoord);
    //FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
