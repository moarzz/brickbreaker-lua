// probably the most math dense shader ive ever made
// it is not readable; dont even try to comprehend it

uniform number time = 0.0;

const vec2 fixxedDimensions = vec2(640.0, 360.0);

uniform number brightness = 0.0;
uniform number intensity = 0.0;

const float bgBrightness = 0.0029;
const float darkmatter = 0.300;
const float distfading = 0.750;
const float saturation = 0.850;

const int iterations = 15;
const float magicnum = 0.53;

const int volsteps = 30;
const float stepsize = 0.13;

const float zoom = 1.200;
const float tile = 0.850;
const float speed = 0.00035;

const int discIterations = 10;

const float AA = 1.0; // anti aliasing (lower = better performance)

const float discSpeed = 1.7; // disk rotation speed

const float discSteps = 6.0; // disk texture layers
const float bhSize = 0.3; // size of BH
const float bhSizeRecip = 1.0 / bhSize;

const float tau = 6.28318;

const vec2 angle1 = vec2(0.0, tau + 0.1);
// cosx = 1.0
// cosy = 0.99500416527
// sinx = 0.0
// siny = 0.09983341664
const vec2 angle2 = vec2(-0.0294170667, tau + 0.08529146665);

float SCurve(float value)
{
    // for some reason pow(value, 5.0) doesnt work

    if (value < 0.5) {
        return pow(value, 5.0) * 16.0;
    }

    value -= 1.0;

    return value * value * value * value * value * 16.0 + 1.0;
}

vec3 background(vec2 coords)
{
    vec3 retColour;

    // starfield
    // vec3 L;
    vec3 C;

    // get coords and direction
    vec2 uv = coords - 0.5; // [-0.5 : 0.5]
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

        v += fade;
        v += vec3(s, s * s, s * s * s * s) * a * bgBrightness * fade + (brightness + intensity) * 0.00000001; // coloring based on distance

        fade *= distfading; // distance fading
        s += stepsize;
    }

    v = mix(vec3(length(v)), v, saturation); //color adjust

    C = vec3(v * 0.01);

    C.r = pow(C.r, 0.35);
    C.g = pow(C.g, 0.36);
    C.b = pow(C.b, 0.4);

    // L = C;

    C.r = SCurve(C.r);
    C.g = mix(C.g, SCurve(C.g), 0.9);
    C.b = mix(C.b, SCurve(C.b), 0.6);

    retColour += pow(C, vec3(1.08));
    // retColour.a = 1.0;

    return retColour;
}

float hash(float x)
{
    return fract(sin(x) * 152754.742); // rand
}
float hash(vec2 x)
{
    return hash(x.x + hash(x.y));
}

float value(vec2 p, float f) // value noise
{
    float bl = hash(floor(p * f + vec2(0.0, 0.0)));
    float br = hash(floor(p * f + vec2(1.0, 0.0)));
    float tl = hash(floor(p * f + vec2(0.0, 1.0)));
    float tr = hash(floor(p * f + vec2(1.0, 1.0)));
    
    vec2 fr = fract(p * f);
    fr = (3.0 - 2.0 * fr) * fr * fr;

    float b = mix(bl, br, fr.x);
    float t = mix(tl, tr, fr.x);

    return mix(b, t, fr.y);
}

vec3 raymarchDisk(vec3 ray, vec3 zeroPos)
{
    vec2 position = zeroPos.xz;
    float lengthPos = length(position);
    float dist = min(1.0, lengthPos * bhSizeRecip * 0.5) * bhSize * 0.4 * (1.0 / discSteps) / abs(ray.y);

    position += dist * discSteps * ray.xz * 0.5;
    
    float disMix = clamp((lengthPos - bhSize * 2.0) * bhSizeRecip * 0.24, 0.0, 1.0);
    vec3 insideCol = mix(vec3(5.0, 2.5, 1.0), vec3(5.0, 1.75, 0.75) * 0.2, disMix);
    vec3 outsideCol = vec3(0.3, 0.2, 0.15) * insideCol;

    vec3 o = vec3(0.0);

    float rot = time * discSpeed * (1.0 - disMix / 2.0);
    float sRot = sin(rot);
    float cRot = cos(rot);

    for (float i = 0.0; i < discSteps; i++)
    {
        position -= dist * ray.xz;
        lengthPos = length(position);

        float intense = clamp(1.0 - abs((i - 0.8) / discSteps * 2.0), 0.0, 1.0);
        float distMult = clamp((lengthPos - bhSize * 0.75) * bhSizeRecip * 1.5, 0.0, 1.0);
        distMult *= clamp((bhSize * 10.0 - lengthPos) * bhSizeRecip * 0.2, 0.0, 1.0);
        distMult *= distMult;

		vec2 angle = vec2(
            0.02 * atan(abs((-position.y * sRot + position.x * cRot) / (position.x * sRot + position.y * cRot))),
            (lengthPos + time * bhSize * 0.3 + intense * bhSize * 0.2) * bhSizeRecip * 0.05
        );

        float noise = value(angle, 70.0) * 0.66 + 0.33 * value(angle, 140.0);

        float extraWidth = noise * (1.0 - clamp(i / discSteps * 2.0 - 1.0, 0.0, 1.0));
        float alpha = clamp(noise * (intense + extraWidth) * (7.0 * bhSizeRecip + 0.01) * dist * distMult, 0.0, 1.0);

        vec3 col = mix(outsideCol, insideCol, min(1.0, intense * 2.0));
        o = clamp(mix(o, col, alpha), vec3(0.0), vec3(1.0));
    }  
 
    o = clamp(o - 0.005, 0.0, 1.0);

    return o;
}


void Rotate(inout vec3 vector, vec2 angle)
{
	vector.yz = cos(angle.y) * vector.yz + sin(angle.y) * vec2(-vector.z, vector.y);
	vector.xz = cos(angle.x) * vector.xz + sin(angle.x) * vec2(-vector.z, vector.x);
}

vec4 effect(vec4 colour, Image img, vec2 textureCoords, vec2 screenCoords)
{
    vec2 fakeScreenCoords = (screenCoords - vec2((love_ScreenSize.xy - fixxedDimensions * min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y)) * 0.5)) / vec2(min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y));
    fakeScreenCoords.y = fixxedDimensions.y - fakeScreenCoords.y;

    vec3 colOut = vec3(0.0);
    
    vec2 fragCoordRot;
    fragCoordRot.x = fakeScreenCoords.x * 0.985 + fakeScreenCoords.y * 0.174;
    fragCoordRot.y = fakeScreenCoords.y * 0.985 - fakeScreenCoords.x * 0.174;
    fragCoordRot += vec2(-0.06, 0.12) * fixxedDimensions;

    vec3 distortBg = vec3(0.0);

    bool useBg = false;
    
    for (int j = 0; j < AA; j++)
    {
        for (int i = 0; i < AA; i++)
        {
            vec3 ray = normalize(vec3((fragCoordRot - fixxedDimensions * 0.5 + vec2(i, j) / AA) / fixxedDimensions.x, 1.0));

            vec3 pos = vec3(
                2.0,
                1.04808437466,
                -9.94504998187
            );

            Rotate(ray, angle2);

            if (i == 0 && j == 0)
            {
                distortBg = ray;
            }

            for (int discs = 0; discs < discIterations; discs++) // steps
            {
                // 6 is the minimum number of iterations that doesnt look shit
                for (int h = 0; h < 6; h++) // reduces tests for exit conditions (to minimise branching)
                {
                    float dotpos = dot(pos, pos);
                    float invDist = inversesqrt(dotpos); // reciprocal of distance to BH
                    float centDist = dotpos * invDist; // sqrt(dotpos) // distance to BH
                    // float stepDist = 0.92 * abs(pos.y / ray.y);  // conservative distance to disk (y==0)   
                    float farLimit = centDist * 0.5; // limit step size far from to BH
                    float closeLimit = centDist * 0.1 + 0.05 * centDist * centDist / bhSize; // limit step size closse to BH
                    float stepDist = min(0.92 * abs(pos.y / ray.y), min(farLimit, closeLimit));
    
                    // float invDistSqr = 1.0 / dotpos; // reciprocal of dotpos
                    float bendForce = stepDist / dotpos * bhSize * 0.625 * invDist; // bending force
                    ray = normalize(ray - bendForce * pos); // bend ray towards BH

                    if (i == 0 && j == 0)
                    {
                        distortBg = distortBg - (bendForce * 0.2) * pos; // bend bg towards bh by a smaller amnt then the actual light
                    }

                    pos += stepDist * ray;
                }

                float dist2 = length(pos);

                if(dist2 < bhSize * 0.1) // ray sucked in to BH
                {
                    break;
                }

                if(dist2 > bhSize * 1000.0) // ray escaped BH
                {
                    useBg = true;
                    break;
                }

                if (abs(pos.y) <= bhSize * 0.002) // ray hit accretion disk
                {
                    pos.y = 0.0;
                    pos += abs(bhSize * 0.001 / ray.y) * ray;
                    colOut += raymarchDisk(ray, pos);
                }
            }
        }
    }

    colOut /= AA * AA;

    if (useBg)
    {
        colOut += background(distortBg.xy / distortBg.z);
    }

    return vec4(colOut, 1.0);
}
