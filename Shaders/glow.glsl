// Input uniforms
uniform vec2 resolution;    // Screen resolution
uniform float intensity;    // Glow intensity
uniform float shadowIntensity; // Shadow intensity (default 0.5)
uniform vec2 shadowOffset;  // Shadow offset in pixels (default vec2(4.0, 4.0))

// Shader effect variables
varying vec2 vTexCoord;    // Texture coordinates

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texcolor = Texel(tex, texture_coords);
    vec4 glow = vec4(0.0);
    vec4 shadow = vec4(0.0);
    vec2 pixel = 1.0 / resolution;
    
    // Shadow pass - sample from offset position
    vec2 shadowCoords = texture_coords + (shadowOffset * pixel);
    for(int i = -2; i <= 2; i++) {
        for(int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * pixel;
            vec4 sample = Texel(tex, shadowCoords + offset);
            float weight = 1.0 - length(vec2(i, j)) / 3.5;
            weight = max(0.0, weight);
            shadow += sample * sample.a * weight;
        }
    }
    shadow = shadow / 25.0; // Normalize the shadow
    shadow = vec4(0.0, 0.0, 0.0, shadow.a * shadowIntensity); // Make shadow black
    
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

    // Combine shadow, glow with the original color
    vec4 finalColor = shadow + texcolor + glow * intensity;
    finalColor.a = max(max(texcolor.a, glow.a * intensity), shadow.a);
    return finalColor * color;
}