#pragma language glsl3

uniform vec2 resolution;
uniform float intensity;
uniform float radius; // e.g. 6.0

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec2 pixel = 1.0 / resolution;
    vec4 sum = vec4(0.0);
    float weightSum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = 1.0 - abs(float(i)) / radius;
        w = max(0.0, w);
        sum += Texel(tex, texture_coords + vec2(float(i) * pixel.x, 0.0)) * w;
        weightSum += w;
    }
    sum /= weightSum;
    return sum * intensity * color;
}
