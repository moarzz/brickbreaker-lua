// Improved glow shader with separate bright pass
extern number threshold = 0.5;
extern number intensity = 1.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Sample the original pixel
    vec4 pixel = Texel(texture, texture_coords);
    
    // Calculate brightness using luminance weights
    float brightness = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
    
    // Only keep pixels brighter than the threshold
    if (brightness > threshold) {
        // Return the original color, but can adjust intensity
        return pixel * intensity;
    } else {
        // Return black (no contribution to glow)
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
}
