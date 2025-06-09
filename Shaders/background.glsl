// Simplex Diamond Pattern Shader for LÖVE2D
// Converted from Shadertoy code

// LÖVE2D uniform variables to replace Shadertoy globals
uniform float time;           // Replaces iTime
uniform vec2 resolution;      // Replaces iResolution.xy
uniform float intensity;
uniform float brightness;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // set adjustable parameters
    float scaleMult = 0.35 + intensity * 0.4; // Adjust the scale multiplier based on intensity
    float brightnessMultBoost = brightness * 1.5 + intensity * 1.0;
    float brightnessOffsetBoost = -2.5;

    // Create our output color variable
    vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);  // Initialize with alpha = 1.0
    
    // Use screen coordinates as input (similar to Shadertoy's fragCoord)
    vec2 I = screen_coords;
    
    float pi = 3.14159265359;
    // Iterator, raymarch depth and step distance
    float i = 0.0, z = 0.0, d = 0.0;
    
    // Remove the time > 2.0 condition so we see something immediately
    // Raymarch 50 steps
    for(i = 0.0; i < 50.0; i++)
    {
        // Compute raymarch point from raymarch distance and ray direction
        vec3 p = z * normalize(vec3((I - resolution.xy * 0.5) * 2.0, resolution.y));
        vec3 v;
        
        // Scroll forward and change depth color offset
        p.z -= time;
        
        // Scale shift
        if (scaleMult < 0.01) scaleMult = 0.01; // Prevent potential divide by zero
        
        // Shift the position to modulate colors
        float hueShift = time * 0.25;  // Speed of color cycling
        vec3 shiftedP = p + vec3(hueShift, hueShift * 1.5, hueShift * 1.7);
        
        // Compute distance for sine pattern (and step forward)
        v = cos(p) - sin(p).yzx;
        z += d = 1e-4+scaleMult*length(max(v=cos(p)-sin(p).yzx,v.yxz*.2));
        
        // Use shifted position for coloring (cycles hues)
        fragColor.rgb += (cos(shiftedP) + brightnessMultBoost) / (d+0.1) + brightnessOffsetBoost;  // Prevent division by very small numbers
    }
    
    // Tonemapping
    fragColor /= fragColor/(scaleMult/0.8+0.4) + 1e3;
    
    // Ensure alpha is 1.0
    fragColor.a = 1.0;
    
    // Apply the original color (usually the sprite color)
    return fragColor * color;
}