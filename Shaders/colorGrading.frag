// Color Grading Shader for LÖVE2D
// Provides comprehensive color correction and grading capabilities

// Basic adjustments
uniform float brightness = 0.0;      // -1.0 to 1.0
uniform float contrast = 1.0;        // 0.5 to 2.0
uniform float saturation = 1.0;      // 0.0 to 2.0
uniform float vibrance = 0.0;        // -1.0 to 1.0

// Color temperature (Kelvin shift)
uniform float temperature = 0.0;     // -1.0 (cooler/blue) to 1.0 (warmer/orange)

// Shadows, midtones, highlights
uniform float shadowsLift = 0.0;     // -1.0 to 1.0
uniform float midtonesLift = 0.0;    // -1.0 to 1.0
uniform float highlightsLift = 0.0;  // -1.0 to 1.0

// Color channels
uniform float redShift = 0.0;        // -1.0 to 1.0
uniform float greenShift = 0.0;      // -1.0 to 1.0
uniform float blueShift = 0.0;       // -1.0 to 1.0

// Vignette
uniform float vignetteStrength = 0.0; // 0.0 to 1.0
uniform float vignetteSoftness = 0.5; // 0.1 to 2.0

// Curves (simple lift/gain for shadows/mids/highs)
uniform float shadowsGain = 1.0;     // 0.5 to 2.0
uniform float midtonesGain = 1.0;    // 0.5 to 2.0
uniform float highlightsGain = 1.0;  // 0.5 to 2.0

// RGB to HSV conversion
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Get luminance (perceived brightness)
float getLuminance(vec3 color)
{
    return dot(color, vec3(0.299, 0.587, 0.114));
}

// Apply tone curve to a channel
float toneCurve(float t)
{
    // Simple S-curve for contrast
    t = t * 2.0 - 1.0;
    t = t * abs(t);
    return t * 0.5 + 0.5;
}

vec4 effect(vec4 colour, Image tex, vec2 textureCoords, vec2 screenCoords)
{
    vec4 texColor = Texel(tex, textureCoords);
    vec3 fragColor = texColor.rgb;
    
    // Apply brightness
    fragColor += vec3(brightness);
    
    // Apply contrast
    fragColor = (fragColor - 0.5) * contrast + 0.5;
    
    // Store original luminance for later use
    float lum = getLuminance(fragColor);
    
    // Convert to HSV for saturation and vibrance adjustments
    vec3 hsv = rgb2hsv(fragColor);
    
    // Apply saturation
    hsv.y *= saturation;
    
    // Apply vibrance (increases saturation of less saturated colors)
    hsv.y = mix(hsv.y, hsv.y + vibrance * (1.0 - hsv.y), 0.5);
    
    // Convert back to RGB
    fragColor = hsv2rgb(hsv);
    
    // Apply color temperature shift
    // Warm: increase red, decrease blue
    // Cool: decrease red, increase blue
    if (temperature > 0.0)
    {
        fragColor.r += temperature * 0.3;
        fragColor.b -= temperature * 0.2;
    }
    else
    {
        fragColor.r += temperature * 0.2;
        fragColor.b -= temperature * 0.3;
    }
    
    // Apply channel shifts
    fragColor.r += redShift * 0.2;
    fragColor.g += greenShift * 0.2;
    fragColor.b += blueShift * 0.2;
    
    // Apply shadows/midtones/highlights adjustments based on luminance
    float tonalWeight;
    
    // Shadows (0.0 - 0.3)
    tonalWeight = smoothstep(0.5, 0.0, lum);
    fragColor = mix(fragColor, fragColor + vec3(shadowsLift * 0.3), tonalWeight);
    fragColor *= mix(1.0, shadowsGain, tonalWeight);
    
    // Midtones (0.3 - 0.7)
    tonalWeight = 1.0 - abs(lum - 0.5) * 2.0;
    tonalWeight = smoothstep(0.0, 1.0, tonalWeight);
    fragColor = mix(fragColor, fragColor + vec3(midtonesLift * 0.2), tonalWeight);
    fragColor *= mix(1.0, midtonesGain, tonalWeight);
    
    // Highlights (0.7 - 1.0)
    tonalWeight = smoothstep(0.3, 1.0, lum);
    fragColor = mix(fragColor, fragColor + vec3(highlightsLift * 0.2), tonalWeight);
    fragColor *= mix(1.0, highlightsGain, tonalWeight);
    
    // Apply vignette
    if (vignetteStrength > 0.0)
    {
        vec2 center = vec2(0.5, 0.5);
        vec2 toCenter = center - textureCoords;
        float vignette = length(toCenter) * vignetteSoftness;
        vignette = 1.0 - smoothstep(0.0, 1.0, vignette);
        fragColor = mix(fragColor, fragColor * vignette, vignetteStrength);
    }
    
    // Clamp values to valid range
    fragColor = clamp(fragColor, 0.0, 1.0);
    
    return vec4(fragColor, texColor.a);
}
