uniform number time = 0.0;
uniform float intensity;
uniform float brightness;

uniform number exponentMult = 0.5;

float TAU = 6.28318;

mat2 rot(float a)
{
	float c = cos(a);
    float s = sin(a);

	return mat2(c, s, -s, c);
}

float box(vec3 pos, float scale)
{
    vec3 q = abs(pos * scale) - vec3(0.4, 0.4, 0.1);

    return -(length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0)) / 1.5;

}

float box_set(vec3 pos, float iTime, float gTime)
{
	float tt = mod(time / 10.0, TAU / 4.0);

	vec3 pos_origin = pos;
	pos = pos_origin;
	pos.y += sin(gTime * 0.4) * 2.5;
	pos.xy *= rot(tt);

	float box1 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);

	pos = pos_origin;
	pos.y -= sin(gTime * 0.4) * 2.5;
	pos.xy *= rot(tt);

	float box2 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);

	pos = pos_origin;
	pos.x += sin(gTime * 0.4) * 2.5;
	pos.xy *= rot(tt);

	float box3 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);

	pos = pos_origin;
	pos.x -= sin(gTime * 0.4) * 2.5;
	pos.xy *= rot(tt);

	float box4 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);

	pos = pos_origin;
	pos.xy *= rot(tt);

	float box5 = box(pos, 0.5) * 6.0;

	pos = pos_origin;

	float box6 = box(pos, 0.5) * 6.0;

	return max(max(max(max(max(box1, box2), box3), box4), box5), box6);
}

vec4 effect(vec4 colour, Image tex, vec2 textureCoords, vec2 screenCoords)
{
    vec2 p = (screenCoords.xy * 2.0 - love_ScreenSize.xy) / min(love_ScreenSize.x, love_ScreenSize.y);
	vec3 ro = vec3(0.0, -0.2 , time * 4.0);
	vec3 ray = normalize(vec3(p, 1.5));

	ray.xy = ray.xy * rot(sin(time * 0.03) * 1.4);
	ray.yz = ray.yz * rot(sin(time * 0.05) * 0.2);

	float t = 0.1;
	vec3 col = vec3(0.0);
	vec3 ac = vec3(0.0);

	for (int i = 0; i < 90; i++)
    {
		vec3 pos = ro + ray * t;
        
        float tens = mod(pos.z / 4.0, 6.0);
        
		pos = mod(pos - 2.0, 4.0) - 2.0;
		float gTime = time - float(i) * 0.01;
        
		float d = box_set(pos, time, gTime);

		d = max(abs(d), 0.01);
		t += d * 0.55;

        vec3 addition = vec3(0.0); // colour to add to the pixel

        // split segments into different colours based off of distance
        if (tens <= 1.0)
        {
            addition.x = exp(-d * 23.0);
        } else if (tens < 2.0)
        {
            addition.y = exp(-d * 23.0);
        } else if (tens < 3.0)
        {
            addition.z = exp(-d * 23.0);
        } else if (tens < 4.0)
        {
            addition.xy = vec2(exp(-d * 23.0));
        } else if (tens < 5.0)
        {
            addition.yz = vec2(exp(-d * 23.0));
        } else
        {
            addition.xyz = vec3(exp(-d * 23.0));
        }
        
        ac += addition;
	}

	col = ac * 0.02 * (0.3 + intensity) * (0.3 + brightness);

	col *= 1.0 - t * (0.02 + 0.02 * sin(time));

	col = max(col, 0.0);

	return vec4(col, 1.0);
}