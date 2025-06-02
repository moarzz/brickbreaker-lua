// Horizontal Gaussian blur shader
extern vec2 texSize;
extern number blurSize = 2.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 sum = vec4(0.0);
    vec2 texelSize = 1.0 / texSize;
    
    // 9-tap Gaussian blur with weights
    float weights[9] = float[](0.05, 0.09, 0.12, 0.15, 0.18, 0.15, 0.12, 0.09, 0.05);
    float offsets[9] = float[](-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0);
    
    for (int i = 0; i < 9; i++) {
        vec2 offset = vec2(offsets[i] * texelSize.x * blurSize, 0.0);
        sum += Texel(texture, texture_coords + offset) * weights[i];
    }
    
    return sum * color;
}
