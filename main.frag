#version 330 core
out vec4 FragColor;

in vec3 objectColor;
in vec2 TexCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;

uniform vec3 lightColor;

void main()
{
	float ambientStrength = 0.1;
	vec3 ambient = ambientStrength * lightColor;

	vec4 textureColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), texture(texture2, TexCoord).a * 0.2);
	FragColor =  textureColor * vec4(objectColor, 1.0) * vec4(ambient, 1.0);
}

