// probably the most math dense shader ive ever made
// it is not readable; dont even try to comprehend it

uniform number time = 0.0;

const vec2 fixxedDimensions = vec2(640.0, 360.0);

const float brightness = 0.0029;
const float darkmatter = 0.300;
const float distfading = 0.750;
const float saturation = 0.850;

const int iterations = 15;
const float magicnum = 0.53;

const int volsteps = 100;
const float stepsize = 0.13;

const float zoom = 1.200;
const float tile = 0.850;
const float speed = 0.00035;

const int AA = 4; // anti aliasing (lower = better performance)

const float discSpeed = 1.7; // disk rotation speed

const float discSteps = 12.0; // disk texture layers
const float bhSize = 0.3; // size of BH

const float tau = 6.28318;

float SCurve(float value)
{
    // for some reason pow(value, 5.0) doesnt work

    if (value < 0.5) {
        return value * value * value * value * value * 16.0;
    }

    value -= 1.0;

    return value * value * value * value * value * 16.0 + 1.0;
}

vec4 background(vec2 coords)
{
    vec4 retColour;

    // starfield
    vec4 L;
    vec4 C;

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

    retColour += pow(vec4(C.rgb, 1.0), vec4(1.08));
    retColour.a = 1.0;

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

vec4 raymarchDisk(vec3 ray, vec3 zeroPos)
{
	vec3 position = zeroPos;
    float lengthPos = length(position.xz);
    float dist = min(1.0, lengthPos * (1.0 / bhSize) * 0.5) * bhSize * 0.4 * (1.0 / discSteps) / abs(ray.y);

    position += dist * discSteps * ray * 0.5;

    vec2 deltaPos;
    deltaPos.x = -zeroPos.z * 0.01 + zeroPos.x;
    deltaPos.y =  zeroPos.x * 0.01 + zeroPos.z;
    deltaPos = normalize(deltaPos - zeroPos.xz);
    
    float parallel = dot(ray.xz, deltaPos);
    parallel /= sqrt(lengthPos);
    parallel *= 0.5;
    float redShift = parallel + 0.3;
    redShift *= redShift;

    redShift = clamp(redShift, 0.0, 1.0);
    
    float disMix = clamp((lengthPos - bhSize * 2.0) * (1.0 / bhSize) * 0.24, 0.0, 1.0);
    vec3 insideCol =  mix(vec3(1.0, 1.0, 0.8), vec3(1.0, 0.7, 0.6) * 0.2, disMix);
    
    insideCol *= mix(vec3(2.0, 1.0, 0.5), vec3(1.6, 2.4, 4.0), redShift);
	insideCol *= 1.25;
    redShift += 0.12;
    redShift *= redShift;

    vec4 o = vec4(0.0);

    for (float i = 0.0; i < discSteps; i++)
    {
        position -= dist * ray;

        float intensity = clamp(1.0 - abs((i - 0.8) * (1.0 / discSteps) * 2.0), 0.0, 1.0);
        float lengthPos = length(position.xz);
        float distMult = 1.0;

        distMult *= clamp((lengthPos - bhSize * 0.75) * (1.0 / bhSize) * 1.5, 0.0, 1.0);
        distMult *= clamp((bhSize * 10.0 - lengthPos) * (1.0 / bhSize) * 0.20, 0.0, 1.0);
        distMult *= distMult;

        float u = lengthPos + time * bhSize * 0.3 + intensity * bhSize * 0.2;

        vec2 xy;
        float rot = mod(time * discSpeed * (1.0 - disMix / 2.0), 8192.0);
        xy.x = -position.z * sin(rot) + position.x * cos(rot);
        xy.y =  position.x * sin(rot) + position.z * cos(rot);

        float x = abs(xy.x / xy.y);
		float angle = 0.02 * atan(x);
  
        const float f = 70.0;
        float noise = value(vec2(angle, u * (1.0 / bhSize) * 0.05), f);
        noise = noise * 0.66 + 0.33 * value(vec2(angle, u * (1.0 / bhSize) * 0.05), f * 2.0);

        float extraWidth = noise * 1.0 * (1.0 - clamp(i * (1.0 / discSteps) * 2.0 - 1.0, 0.0, 1.0));

        float alpha = clamp(noise * (intensity + extraWidth) * ((1.0 / bhSize) * 7.0 + 0.01) * dist * distMult, 0.0, 1.0);

        vec3 col = 2.0 * mix(vec3(0.3, 0.2, 0.15) * insideCol, insideCol, min(1.0, intensity * 2.0));
        o = clamp(vec4(col * alpha + o.rgb * (1.0 - alpha), o.a * (1.0 - alpha) + alpha), vec4(0.0), vec4(1.0));

        lengthPos *= (1.0 / bhSize);
   
        o.rgb += redShift * (intensity * 1.0 + 0.5) * (1.0 / discSteps) * 100.0 * distMult / (lengthPos * lengthPos);
    }  
 
    o.rgb = clamp(o.rgb - 0.005, 0.0, 1.0);

    return o;
}


void Rotate(inout vec3 vector, vec2 angle)
{
	vector.yz = cos(angle.y) * vector.yz + sin(angle.y) * vec2(-1.0, 1.0) * vector.zy;
	vector.xz = cos(angle.x) * vector.xz + sin(angle.x) * vec2(-1.0, 1.0) * vector.zx;
}

vec4 effect(vec4 colour, Image img, vec2 textureCoords, vec2 screenCoords)
{
    vec2 fakeScreenCoords = (screenCoords - vec2((love_ScreenSize.xy - fixxedDimensions * min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y)) / 2.0)) / vec2(min(love_ScreenSize.x / fixxedDimensions.x, love_ScreenSize.y / fixxedDimensions.y));
    fakeScreenCoords.y = fixxedDimensions.y - fakeScreenCoords.y;

    vec4 colOut = vec4(0.0);
    
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
            //setting up camera
            vec3 ray = normalize(vec3((fragCoordRot - fixxedDimensions * 0.5 + vec2(i, j) / float(AA)) / fixxedDimensions.x, 1.0));
            vec3 pos = vec3(2.0, 0.05, -10.0); // previously based off of mouse position
            vec2 angle = vec2(0.0, tau + 0.1);

            float dist = length(pos);
            Rotate(pos, angle);
            angle.xy -= min(0.3 / dist, tau * 0.5) * vec2(1.0, 0.5);
            Rotate(ray, angle);

            if (i == 0 && j == 0)
            {
                distortBg = ray;
            }

            vec4 col = vec4(0.0);

            for (int disks = 0; disks < 20; disks++) // steps
            {
                for (int h = 0; h < 6; h++) // reduces tests for exit conditions (to minimise branching)
                {
                    float dotpos = dot(pos, pos);
                    float invDist = inversesqrt(dotpos); // reciprocal of distance to BH
                    float centDist = dotpos * invDist; // 1.0 / dotpos 	// distance to BH
                    float stepDist = 0.92 * abs(pos.y / ray.y);  // conservative distance to disk (y==0)   
                    float farLimit = centDist * 0.5; // limit step size far from to BH
                    float closeLimit = centDist * 0.1 + 0.05 * centDist * centDist * (1.0 / bhSize); // limit step size closse to BH
                    stepDist = min(stepDist, min(farLimit, closeLimit));
    
                    float invDistSqr = invDist * invDist; // reciprocal of dotpos ^ 4.0
                    float bendForce = stepDist * invDistSqr * bhSize * 0.625;  // bending force
                    ray = normalize(ray - (bendForce * invDist) * pos);  // bend ray towards BH

                    if (i == 0 && j == 0)
                    {
                        distortBg = normalize(distortBg - (bendForce * invDist * 0.2) * pos); // bend bg towards bh by a smaller amnt then the actual light
                    }

                    pos += stepDist * ray;
                }

                float dist2 = length(pos);

                if(dist2 < bhSize * 0.1) // ray sucked in to BH
                {
                    break;
                }
                else if(dist2 > bhSize * 1000.0) // ray escaped BH
                {
                    useBg = true;
                    break;
                }
                else if (abs(pos.y) <= bhSize * 0.002) // ray hit accretion disk
                {
                    vec4 diskCol = raymarchDisk(ray, pos); // render disk
                    pos.y = 0.0;
                    pos += abs(bhSize * 0.001 / ray.y) * ray;
                    col = vec4(diskCol.rgb * (1.0 - col.a) + col.rgb, col.a + diskCol.a * (1.0 - col.a));
                }
            }

            col.a = 1.0;
            colOut += col;
        }
    }

    colOut /= colOut.a;

    if (useBg)
    {
        colOut += background(distortBg.xy / distortBg.z);
    }

    return colOut;
}
