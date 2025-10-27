vec4 effect(vec4 colour, Image tex, vec2 texCoords, vec2 screenCoords)
{
    vec4 pixel = vec4(1.0);//Texel(tex, texCoords) * colour;

    float horizontalDis = 0.1;
    float falloff = 0.3;

    pixel.a = 0.1 + (1.0 - abs(texCoords.x - 0.5) * 2.0) * horizontalDis + texCoords.y * falloff;

    return pixel;
}
