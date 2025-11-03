// Code borrowed from https://www.shadertoy.com/view/XdjXDy and https://www.shadertoy.com/view/XdSBD1
// -Policy/praxlor
// To play music and fx press the pause/play button next to iChannel3 at the bottom right

// MIT License
uniform number GLOW = 0.45;

uniform vec2 fixxedDimensions = vec2(640.0, 360.0);

uniform number brightness = 0.0029;
uniform number darkmatter = 0.300;
uniform number distfading = 0.750;
uniform number saturation = 0.850;

uniform int iterations = 15;
uniform number magicnum = 0.53;

uniform int volsteps = 50;
uniform number stepsize = 0.13;
//#define stepsize 0.1

uniform number zoom = 2.200;
uniform number tile = 0.850;
uniform number speed = 0.0002;

uniform number time = 0.0;

float tau = 6.28318;
// float pi = 3.14159;

uniform Image smallNoise;

// #define FREQ_CHANNEL iChannel1

// const float pi = 3.1415927;

// signed distance functions
float sdSphere(vec3 p, float s)
{
    return length(p) - s;
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float SCurve(float value)
{
    if (value < 0.5) {
        return value * value * value * value * value * 16.0;
    }

    value -= 1.0;

    return value * value * value * value * value * 16.0 + 1.0;
}

vec4 effect(vec4 colour, Image fadeIn, vec2 textureCoords, vec2 screenCoords)
{
    // vec2 fakeScreenCoords = screenCoords * vec2(min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y)) + vec2((love_ScreenSize.xy - fixxedDimensions * min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y)) / 2.0);
    vec2 fakeScreenCoords = (screenCoords - vec2((love_ScreenSize.xy - fixxedDimensions * min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y)) / 2.0)) / vec2(min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y));
    fakeScreenCoords.y = fixxedDimensions.y - fakeScreenCoords.y;

    vec4 retColour = colour;

    float glow_mul = pow(GLOW, 1.7);

    vec4 ret = vec4(0.0);
    vec2 pp = fakeScreenCoords.xy / fixxedDimensions.xy;
    pp = 2.0 * pp - 1.0; // map [0 : 1] -> [-1 : 1]
    pp.x *= fixxedDimensions.x / fixxedDimensions.y;//iResolution.x / iResolution.y;

    vec3 lookAt = vec3(1.0, 0.0, 0.0);

    float eyer = 1.3;
    float eyea = 0.0; // previously based off of mouse position
    float eyea2 = -0.21 * tau; // previously based off of mouse position

    vec3 ro = vec3(
        eyer * cos(eyea) * sin(eyea2),
        eyer * cos(eyea2),
        eyer * sin(eyea) * sin(eyea2)
    ); //camera position

    // todo: unify spacial coordinates
    vec3 front = normalize(lookAt - ro);
    vec3 left = normalize(cross(normalize(vec3(0.0, 1.0, -0.13)), front));
    vec3 up = normalize(cross(front, left));
    vec3 rd = normalize(front * 1.115 + left * pp.x + up * pp.y); // rect vector

    vec3 bh = vec3(1.3, 0.0, 1.0); // blackhole position
    float bhr = 0.1; // radius
    float bhmass = 0.005; // mass

    vec3 camPos = ro; // camera pos
    vec3 pv = rd;
    float dt = 0.02; // step

    vec3 col = vec3(0.0);

    float noncaptured = 1.0;

    vec3 c1 = vec3(0.3, 0.3, 0.35); // accretion disc color mix 1
    vec3 c2 = vec3(0.7, 0.8, 0.83); // accretion disc color mix 2

    float glow = 0.0019; // glow

    float radius = 0.17;

    vec3 bhv;
    vec3 dcol = vec3(0.0);
    float sd_disc = 0.0;

    for (float t = 0.0; t < 1.0; t += 0.005)
    {
        camPos += pv * dt * noncaptured;

        // gravity
        bhv = bh - camPos;
        // float r = dot(bhv, bhv);
        pv += normalize(bhv) * ((bhmass) / dot(bhv, bhv));

        noncaptured = smoothstep(0.0, 0.566, sdSphere(camPos - bh, bhr));

        // Texture for the accretion disc
        float dr = length(bhv.xz);
        float da = atan(bhv.x, bhv.z);
        
        vec2 ra = vec2(
            dr,
            da * (0.01 + (dr - bhr) * 0.002) + tau + time * 0.003 + abs(pow(glow_mul / 300.0, 1.2))
        );
        
        ra *= vec2(10.0, 20.0);

        // Accretion disc color
        dcol = mix(c2, c1, pow(length(bhv) - bhr, 4.0)) * max(0.0, Texel(smallNoise, ra * vec2(0.1, 0.5)).r + 0.05) * (4.0 / ((0.001 + (length(bhv) - bhr) * 50.0)));

        sd_disc = smoothstep(0.0, 1.0, -sdTorus((camPos * vec3(1.0, 25.0, 1.0)) - bh, vec2(0.8, 0.99)));

        col += max(vec3(0.0), dcol * sd_disc * noncaptured);

        // this is a cool jet effect
        // col += dcol * (1.0 / dr) * noncaptured * 0.01;

        // Glow
        col += vec3(1.0, 0.9, 0.85) * (1.0 / vec3(dot(bhv, bhv))) * glow * glow_mul * noncaptured;
    }

    col *= vec3(0.72, 0.8, 1.0) * 1.2;

    ret = vec4(length(bhv) - bhr);
    ret.y = length(bhv);
    ret.z = bhr;
    ret.w = glow_mul;

    // blackhole color
    retColour = vec4(col, 1.0);

    vec4 bhb = ret;


//}

//void mainImage(out vec4 retColour, in vec2 fragCoord)
//{
    // vec4 bhb = blackhole(retColour, fragCoord);

    // float ruv = length((fragCoord.xy - 0.5 * love_ScreenSize.xy) / love_ScreenSize.y);
    // vec4 color = vec4(0.0, 0.0, 0.0, 1.0) * exp(-ruv * 1.1) * 1.15;

    // vec3 p1, p2;

    // float resolution = max(love_ScreenSize.y, love_ScreenSize.y);

    // starfield
    vec4 L;
    vec4 C;

    // get coords and direction
    vec2 uv = (fakeScreenCoords / fixxedDimensions.xy) - 0.5; // [-0.5 : 0.5]
    uv.y /= fixxedDimensions.x / fixxedDimensions.y;
    
    vec3 dir = vec3(uv * zoom, 1.0);
    float nTime = time * speed + 0.2;

	float a1 = 0.5; // previously based off of mouse position
	float a2 = 0.8; // previously based off of mouse position

    mat2 rot1 = mat2(cos(a1), sin(a1), -sin(a1), cos(a1));
    mat2 rot2 = mat2(cos(a2), sin(a2), -sin(a2), cos(a2));
    
    dir.xz *= rot1;
    dir.xy *= rot2;
    
    vec3 from = vec3(1.0, 0.5, 0.5);
    
    from += vec3(nTime * 2.0, nTime, -2.0);
    from.xz *= rot1;
    from.xy *= rot2;

    // volumetric rendering
    float s = 0.1;
    float fade = 1.0;
    vec3 v = vec3(0.0);
    
    for (int i = 0; i < volsteps; i++)
    {
        vec3 p = from + s * dir * 0.5;
        
        p = abs(vec3(tile) - mod(p, vec3(tile * 2.0))); // tiling fold
        
        float pa = 0.0;
        float a = 0.0;//pa = 0.0;
        
        for (int j = 0; j < iterations; j++)
        {
            p = abs(p) / dot(p, p) - magicnum;
            a += abs(length(p) - pa); // absolute sum of average change
            pa = length(p);
        }
        float dm = max(0.0, darkmatter - a * a * 0.001); //dark matter
        a = pow(a, 2.5); // add contrast
        if (i > 6)
        {
            fade *= 1.0 - dm; // dark matter, don't render near
        }
        //v+=vec3(dm,dm*.5,0.);
        v += fade;
        v += vec3(s, s * s, s * s * s * s) * a * brightness * fade; // coloring based on distance
        fade *= distfading; // distance fading
        s += stepsize;
    }

    v = mix(vec3(length(v)), v, saturation); //color adjust

    C = vec4(v * 0.01, 1.0);

    C.r = pow(C.r, 0.35);
    C.g = pow(C.g, 0.36);
    C.b = pow(C.b, 0.4);

    L = C;

    C.r = mix(L.r, SCurve(C.r), 1.0);
    C.g = mix(L.g, SCurve(C.g), 0.9);
    C.b = mix(L.b, SCurve(C.b), 0.6);


    // Occlusion
    C *= clamp(pow(vec4((bhb.x / 1.5)), vec4(5.0)), vec4(0.0), vec4(1.0));

    retColour += pow(vec4(C.rgb, 1.0), vec4(1.08));

    return retColour;
}