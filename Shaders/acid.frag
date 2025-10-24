uniform number time = 0.0;
uniform float intensity;
uniform float brightness;

float tau = 6.28318;

mat2 rot(float a)
{
	float c = cos(a);
    float s = sin(a);

	return mat2(c, s, -s, c);
}

vec3 palette(float t)
{
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);

    return a + b * cos(tau * (c * t + d));
}

vec4 effect(vec4 colour, Image tex, vec2 textureCoords, vec2 screenCoords)
{
    vec2 uv = (screenCoords * 2.0 - love_ScreenSize.xy) / min(love_ScreenSize.x, love_ScreenSize.y);

    float scaleMult = 0.35 + intensity * 0.4; // Adjust the scale multiplier based on intensity

    uv *= rot(sin(time / 17.4) * 1.1);
    uv += vec2(sin(time / 4.4), sin(time / 5.8 + 0.2)) * 0.08;

    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);
    
    for (float i = 0.0; i < 3.0; i++)
    {
        uv = fract(uv * 1.5) - 0.5;

        float d = length(uv) * exp(-length(uv0));

        vec3 col = palette(length(uv0) + i * 0.4 + time * 0.2);

        d = abs(sin(d * 8.0 + time / 2.0) / 8.0);
        d = pow(0.01 / d, 1.2);

        finalColor += col * d;
    }

    finalColor = sqrt(finalColor * 4.0) / 10.0;
        
    return vec4(finalColor, 1.0);
}