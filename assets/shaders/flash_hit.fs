

#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;

uniform float flashAmount;
uniform vec3 flashColor;

// Input uniform values
uniform sampler2D texture0;


// Output fragment color
out vec4 finalColor;

void main()
{
    // Get the texture coordinates
    vec2 texCoords = fragTexCoord;

    // Sample the texture at the current position
    vec4 texelColor = texture(texture0, texCoords);




    if (flashAmount == 1 && texelColor.a > 0 && texelColor.a != 90.0 / 255.0) {
            finalColor = vec4(flashColor, 1);
    } else {
        finalColor = texelColor;
    }
}
