uniform number points_x[120];
uniform number points_y[120];
uniform number trailRadius;
uniform int usedPoints;

vec4 effect(vec4 colour, Image tex, vec2 texCoords, vec2 screenCoords)
{
    vec4 fakeScreenPos = (vec4(screenCoords, 0.0, 1.0) - vec4((love_ScreenSize.xy - vec2(1920.0, 1080.0) * min(love_ScreenSize.x / 1920.0, love_ScreenSize.y / 1080.0)) / 2.0, 0.0, 0.0)) / vec4(vec2(min(love_ScreenSize.x / 1920.0, love_ScreenSize.y / 1080.0)), 1.0, 1.0);

    float biggest = 0.0;

    // WebGL requires a constant limit (120)
    for (int i = 1; i < 120; i++)
    {
        // Break manually if we hit our dynamic limit
        if (i >= usedPoints) { break; }

        vec2 prev = vec2(points_x[i - 1], points_y[i - 1]);
        vec2 cur = vec2(points_x[i], points_y[i]);

        float len = length(prev - cur);
        // Avoid division by zero if points are at the same spot
        float lineDot = (((fakeScreenPos.x - prev.x) * (cur.x - prev.x)) + ((fakeScreenPos.y - prev.y) * (cur.y - prev.y))) / (len * len + 0.00001);
        lineDot = clamp(lineDot, 0.0, 1.0);
        
        float time = (float(usedPoints) - float(i) - lineDot + 1.0) / float(usedPoints);

        vec2 closest = prev + (lineDot * (cur - prev));
        float dist = length(fakeScreenPos.xy - closest);

        if (dist <= trailRadius * time)
        {
            biggest = max(biggest, time * time * min((trailRadius * time - dist) / 2.0, 1.0));
        }
    }

    return vec4(vec3(1.0), biggest) * colour;
}