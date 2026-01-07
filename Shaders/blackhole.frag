// Fixed for WebGL Compatibility
uniform number time; // Removed = 0.0
uniform number brightness;
uniform number intensity;

const vec2 fixxedDimensions = vec2(640.0, 360.0);
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
const float AA = 1.0;
const float discSpeed = 1.7; 

// Declared as constants for loop stability
const int discStepsInt = 6;
const float discSteps = 6.0;

const float bhSize = 0.3; 
const float bhSizeRecip = 1.0 / 0.3; // Use literal to avoid variable division
const float tau = 6.28318;

const vec2 angle1 = vec2(0.0, 6.28318 + 0.1);
const vec2 angle2 = vec2(-0.0294170667, 6.28318 + 0.08529146665);

float SCurve(float value)
{
    if (value < 0.5) {
        return pow(value, 5.0) * 16.0;
    }
    float v = value - 1.0; // Avoid inline assignment
    return v * v * v * v * v * 16.0 + 1.0;
}

vec3 background(vec2 coords)
{
    vec3 retColour = vec3(0.0);
    vec2 uv = coords - 0.5;
    uv.y /= fixxedDimensions.x / fixxedDimensions.y;
    
    vec3 dir = vec3(uv * zoom, 1.0);
    float nTime = time * speed + 0.2;

    float a1 = 0.5;
    float a2 = 0.8;

    mat2 rot1 = mat2(cos(a1), sin(a1), -sin(a1), cos(a1));
    mat2 rot2 = mat2(cos(a2), sin(a2), -sin(a2), cos(a2));
    
    dir.xz *= rot1;
    dir.xy *= rot2;
    
    vec3 from = vec3(1.0, 0.5, 0.5);
    from += vec3(nTime * 2.0, nTime, -2.0);
    from.xz *= rot1;
    from.xy *= rot2;

    float s = 0.1;
    float fade = 1.0;
    vec3 v = vec3(0.0);
    for (int i = 0; i < volsteps; i++)
    {
        vec3 p = from + s * dir * 0.5;
        p = abs(vec3(tile) - mod(p, vec3(tile * 2.0))); 
        
        float pa = 0.0;
        float a = 0.0;
        
        for (int j = 0; j < iterations; j++)
        {
            p = abs(p) / dot(p, p) - magicnum;
            a += abs(length(p) - pa);
            pa = length(p);
        }

        float dm = max(0.0, darkmatter - a * a * 0.001);
        a = pow(a, 2.5);

        if (i > 6)
        {
            fade *= 1.0 - dm;
        }

        v += vec3(s, s * s, s * s * s * s) * a * bgBrightness * fade + (float(brightness) + float(intensity)) * 0.00000001;

        fade *= distfading;
        s += stepsize;
    }

    v = mix(vec3(length(v)), v, saturation);
    vec3 C = vec3(v * 0.01);
    C.r = pow(C.r, 0.35);
    C.g = pow(C.g, 0.36);
    C.b = pow(C.b, 0.4);

    C.r = SCurve(C.r);
    C.g = mix(C.g, SCurve(C.g), 0.9);
    C.b = mix(C.b, SCurve(C.b), 0.6);

    return retColour + pow(C, vec3(1.08));
}

float hash_f(float x) // Renamed to avoid overloading
{
    return fract(sin(x) * 152754.742);
}
float hash_v2(vec2 x) // Renamed to avoid overloading
{
    return hash_f(x.x + hash_f(x.y));
}

float value(vec2 p, float f)
{
    float bl = hash_v2(floor(p * f + vec2(0.0, 0.0)));
    float br = hash_v2(floor(p * f + vec2(1.0, 0.0)));
    float tl = hash_v2(floor(p * f + vec2(0.0, 1.0)));
    float tr = hash_v2(floor(p * f + vec2(1.0, 1.0)));
    
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

    float rot_val = float(time) * discSpeed * (1.0 - disMix / 2.0);
    float sRot = sin(rot_val);
    float cRot = cos(rot_val);

    for (int i = 0; i < discStepsInt; i++) // Use integer loop
    {
        position -= dist * ray.xz;
        lengthPos = length(position);

        float intense = clamp(1.0 - abs((float(i) - 0.8) / discSteps * 2.0), 0.0, 1.0);
        float distMult = clamp((lengthPos - bhSize * 0.75) * bhSizeRecip * 1.5, 0.0, 1.0);
        distMult *= clamp((bhSize * 10.0 - lengthPos) * bhSizeRecip * 0.2, 0.0, 1.0);
        distMult *= distMult;
        
        vec2 angle = vec2(
            0.02 * atan(abs((-position.y * sRot + position.x * cRot) / (position.x * sRot + position.y * cRot + 0.0001))),
            (lengthPos + float(time) * bhSize * 0.3 + intense * bhSize * 0.2) * bhSizeRecip * 0.05
        );
        float noise = value(angle, 70.0) * 0.66 + 0.33 * value(angle, 140.0);
        float extraWidth = noise * (1.0 - clamp(float(i) / discSteps * 2.0 - 1.0, 0.0, 1.0));
        float alpha = clamp(noise * (intense + extraWidth) * (7.0 * bhSizeRecip + 0.01) * dist * distMult, 0.0, 1.0);
        vec3 col = mix(outsideCol, insideCol, min(1.0, intense * 2.0));
        o = clamp(mix(o, col, alpha), vec3(0.0), vec3(1.0));
    }  
 
    return clamp(o - 0.005, 0.0, 1.0);
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
    
    // Constant loop for AA
    for (int j = 0; j < 1; j++)
    {
        for (int i = 0; i < 1; i++)
        {
            vec3 ray = normalize(vec3((fragCoordRot - fixxedDimensions * 0.5 + vec2(float(i), float(j)) / AA) / fixxedDimensions.x, 1.0));
            vec3 pos = vec3(2.0, 1.04808437466, -9.94504998187);
            Rotate(ray, angle2);

            if (i == 0 && j == 0) { distortBg = ray; }

            for (int discs = 0; discs < discIterations; discs++) 
            {
                for (int h = 0; h < 6; h++) 
                {
                    float dotpos = dot(pos, pos);
                    float invDist = inversesqrt(dotpos);
                    float centDist = dotpos * invDist;
                    float farLimit = centDist * 0.5;
                    float closeLimit = centDist * 0.1 + 0.05 * centDist * centDist / bhSize;
                    float stepDist = min(0.92 * abs(pos.y / (ray.y + 0.00001)), min(farLimit, closeLimit));
                    float bendForce = stepDist / dotpos * bhSize * 0.625 * invDist;
                    ray = normalize(ray - bendForce * pos);

                    if (i == 0 && j == 0) {
                        distortBg = distortBg - (bendForce * 0.2) * pos;
                    }
                    pos += stepDist * ray;
                }

                float dist2 = length(pos);
                if(dist2 < bhSize * 0.1) { break; }
                if(dist2 > bhSize * 1000.0) { useBg = true; break; }

                if (abs(pos.y) <= bhSize * 0.002) 
                {
                    pos.y = 0.0;
                    pos += abs(bhSize * 0.001 / (ray.y + 0.00001)) * ray;
                    colOut += raymarchDisk(ray, pos);
                }
            }
        }
    }

    if (useBg) { colOut += background(distortBg.xy / (distortBg.z + 0.0001)); }
    return vec4(colOut, 1.0);
}