#pragma language glsl3

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
    // First pass - wider radius for outer glow
    for(int i = -8; i <= 8; i++) {
        for(int j = -8; j <= 8; j++) {
            vec2 offset = vec2(float(i), float(j)) * pixel * 2.0;
            vec4 sample = Texel(tex, texture_coords + offset);
            float weight = 1.0 - length(vec2(i, j)) / 12.0;
            weight = max(0.0, weight);
            glow += sample * sample.a * weight;
        }
    }
    glow = glow / 100.0; // Normalize the glow

    // Second pass - tighter radius for inner glow
    vec4 innerGlow = vec4(0.0);
    for(int i = -4; i <= 4; i++) {
        for(int j = -4; j <= 4; j++) {
            vec2 offset = vec2(float(i), float(j)) * pixel;
            vec4 sample = Texel(tex, texture_coords + offset);
            float weight = 1.0 - length(vec2(i, j)) / 6.0;
            weight = max(0.0, weight);
            innerGlow += sample * sample.a * weight;
        }
    }
    innerGlow = innerGlow / 40.0; // Normalize the inner glow

    // Combine both glows with the original color
    vec4 finalColor = texcolor + (glow + innerGlow) * intensity;
    finalColor.a = max(texcolor.a, (glow.a + innerGlow.a) * intensity);
    
    return finalColor * color;
}

