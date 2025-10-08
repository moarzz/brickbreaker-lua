// Input uniforms
uniform vec2 resolution;    // Screen resolution
uniform float intensity;    // Glow intensity

// Shader effect variables
varying vec2 vTexCoord;    // Texture coordinates

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texcolor = Texel(tex, texture_coords);
    vec4 glow = vec4(0.0);
    vec2 pixel = 1.0 / resolution;
    
    // Use two passes of blur for a more natural glow
    // First pass - 10x10 kernel for wider outer glow
    for(int i = -4; i <= 4; i++) {
        for(int j = -4; j <= 4; j++) {
            vec2 offset = vec2(float(i), float(j)) * pixel * 3.0;
            vec4 sample = Texel(tex, texture_coords + offset);
            float weight = 1.0 - length(vec2(i, j)) / 7.5;
            weight = max(0.0, weight);
            glow += sample * sample.a * weight;
        }
    }
    glow = glow / 32.0; // Normalize the glow

    // Combine glow with the original color (no inner glow)
    vec4 finalColor = texcolor + glow * intensity;
    finalColor.a = max(texcolor.a, glow.a * intensity);
    return finalColor * color;
}

