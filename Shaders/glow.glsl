extern number threshold;
extern number blurSize;
extern vec2 texSize;
extern Image tex;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 texel = 1.0 / texSize;
    vec4 bright = Texel(texture, texture_coords);
    float brightness = dot(bright.rgb, vec3(0.2126, 0.7152, 0.0722));
    if (brightness < threshold) return vec4(0.0);

    vec4 sum = vec4(0.0);
    for (int x = -4; x <= 4; x++) {
        for (int y = -4; y <= 4; y++) {
            vec2 offset = vec2(x, y) * texel * blurSize;
            sum += Texel(tex, texture_coords + offset);
        }
    }
    sum /= 81.0;
    return sum * color* 50.;
}
