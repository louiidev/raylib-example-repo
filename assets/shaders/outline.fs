#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform vec4 outlineColor;  // Color of the outline
uniform float outlineSize;  // Width of the outline (in pixels)




// Output fragment color
out vec4 finalColor;

void main()
{
    // Get the texture coordinates
    vec2 texCoords = fragTexCoord;
    
    // Sample the texture at the current position
    vec4 texelColor = texture(texture0, texCoords);
    
    // Check if the current pixel is part of the text (alpha > 0)
    float alpha = texelColor.a;
    
    // If the current pixel is not part of the text, check neighboring pixels
    if (alpha < 0.1)
    {
        // Sample points in a circle around the current pixel
        float totalAlpha = 0.0;
        
        // Calculate pixel size in texture coordinates (assuming texture size is known)
        vec2 pixelSize = 1.0 / textureSize(texture0, 0);
        float testDistance = outlineSize * pixelSize.x;
        
        // Sample in several directions to check for nearby text
        for (float angle = 0.0; angle < 6.28; angle += 0.52) {  // Roughly 12 samples
            vec2 sampleOffset = vec2(cos(angle), sin(angle)) * testDistance;
            vec4 sampleColor = texture(texture0, texCoords + sampleOffset);
            totalAlpha = max(totalAlpha, sampleColor.a);
        }
        
        // If any nearby pixels are part of the text, this pixel is part of the outline
        if (totalAlpha > 0.1)
        {
            // Set color to outline color
            finalColor = outlineColor;
            return;
        }
    }
    
    // Apply tint color to the original texture color
    finalColor = texelColor * colDiffuse;
}