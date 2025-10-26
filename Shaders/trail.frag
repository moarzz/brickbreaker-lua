vec4 effect(vec4 colour, Image tex, vec2 texCoords, vec2 screenCoords)
{
    vec4 pixel = vec4(1.0);//Texel(tex, texCoords) * colour;

    pixel.a = 0.1 + (1.0 - abs(texCoords.x - 0.5) * 2.0) * 0.1 + texCoords.y * 0.3;

    return pixel;
}
