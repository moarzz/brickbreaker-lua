uniform number fade = 0.0;

uniform bool fadeIn = true;

vec4 effect(vec4 colour, Image tex, vec2 textureCoords, vec2 screenCoords)
{
    vec4 pixelColour = Texel(tex, textureCoords);

    if (fadeIn)
    {
        float innerDist = sqrt(2.0) * (fade - 0.2) / 0.8;
        float outerDist = sqrt(2.0) * fade / 0.6;

        float dist = length(textureCoords * 2.0 - vec2(1.0));

        if (dist >= outerDist)
        {
            pixelColour.a = 0.0;
        } else if (dist <= innerDist)
        {
            pixelColour.a = 1.0;
        } else
        {
            pixelColour.a = 1.0 - (dist - innerDist) / (outerDist - innerDist);
        }
    } else
    {
        float innerDist = sqrt(2.0) * fade;
        float outerDist = sqrt(2.0) * fade;

        float dist = length(textureCoords * 2.0 - vec2(1.0));

        if (dist >= outerDist)
        {
            pixelColour.a = 1.0;
        } else if (dist <= innerDist)
        {
            pixelColour.a = 0.0;
        } else
        {
            pixelColour.a = (dist - innerDist) / (outerDist - innerDist);
        }
    }


    return pixelColour * colour;
}