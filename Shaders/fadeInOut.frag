uniform number fade = 0.0;

uniform Image fadeOut;

// uniform bool fadeIn = true;

vec4 effect(vec4 colour, Image fadeIn, vec2 textureCoords, vec2 screenCoords)
{
    vec4 fadeInColour = Texel(fadeIn, textureCoords);

    // fadeIn
    float innerDist = sqrt(2) * (fade - 0.2) / 0.8;
    float outerDist = sqrt(2) * fade / 0.6 * 1.5;

    float dist = length(textureCoords * 2.0 - vec2(1.0));

    if (dist >= outerDist)
    {
        fadeInColour.a = 0.0;
    } else if (dist <= innerDist)
    {
        fadeInColour.a = 1.0;
    } else
    {
        fadeInColour.a = 1.0 - (dist - innerDist) / (outerDist - innerDist);
    }

    vec4 fadeOutColour = Texel(fadeOut, textureCoords);

    innerDist = sqrt(2) * fade;
    outerDist = sqrt(2) * fade * 1.5;

    dist = length(textureCoords * 2.0 - vec2(1.0));

    if (dist >= outerDist)
    {
        fadeOutColour.a = 1.0;
    } else if (dist <= innerDist)
    {
        fadeOutColour.a = 0.0;
    } else
    {
        fadeOutColour.a = (dist - innerDist) / (outerDist - innerDist);
    }

    vec3 finalColour = fadeInColour.rgb * fadeInColour.a + fadeOutColour.rgb * fadeOutColour.a;

    return vec4(finalColour, 1.0);
}