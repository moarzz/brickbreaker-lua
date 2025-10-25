// Simplex Diamond Pattern Shader for LÖVE2D
// Converted from Shadertoy code

// LÖVE2D uniform variables to replace Shadertoy globals
uniform float time;           // Replaces iTime
uniform float intensity;
uniform float brightness;

vec4 effect(vec4 colour, Image tex, vec2 textureCoords, vec2 screenCoords)
{
    // set adjustable parameters
    float scaleMult = 0.35 + intensity * 0.4; // Adjust the scale multiplier based on intensity
    float brightnessMultBoost = brightness * 1.0 + intensity * 1.0 + 0.5;
    float brightnessOffsetBoost = -1;

    // Create our output colour variable
    vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);  // Initialize with alpha = 1.0
    
    // Use screen coordinates as input (similar to Shadertoy's fragCoord)
    vec2 I = textureCoords * vec2(1920, 1080);
    
    // Iterator, raymarch depth and step distance
    float i = 0.0, z = 0.0, d = 0.0;
    
    // Remove the time > 2.0 condition so we see something immediately
    // Raymarch 50 steps
    for(i = 0.0; i < 50.0; i++)
    {
        // Compute raymarch point from raymarch distance and ray direction
        vec3 p = z * normalize(vec3((I - vec2(1920.0, 1080.0) * 0.5) * 2.0, 1080.0));
        vec3 v;
        
        // Scroll forward and change depth colour offset
        p.z += time;
        
        // Shift the position to modulate colors
        float hueShift = time * 0.25;  // Speed of colour cycling
        vec3 shiftedP = p + vec3(hueShift, hueShift * 1.5, hueShift * 1.7);
        
        // Compute distance for sine pattern (and step forward)
        v = cos(p) - sin(p).yzx;
        d = scaleMult * length(max(v, v.yxz * 0.2));
        z += d;
        
        // Use shifted position for coloring (cycles hues)
        fragColor.rgb += (cos(shiftedP) + brightnessMultBoost) / (d + 0.1) + brightnessOffsetBoost;  // Prevent division by very small numbers
    }
    
    // Tonemapping
    fragColor /= fragColor / (scaleMult / 0.8 + 0.4) + 1000.0;
    
    //fragColor *= 1.0 - fadeIn * pow(length(textureCoords) + 1.0, 0.6);
    //fragColor *= 1.0 - fadeOut * pow(-length(textureCoords) - 1.0, 2.0);

    // Ensure alpha is 1.0
    fragColor.a = 1.0;
    
    // Apply the original colour (usually the sprite colour)
    return fragColor;
}