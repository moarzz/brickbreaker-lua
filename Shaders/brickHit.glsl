uniform float time;
uniform vec2 resolution;
uniform float intensity = 1.0;  // Controls the overall intensity of the effect

vec3 palette(in float t)
{
    // Increased saturation and brightness in color palette
    vec3 a = vec3(0.6, 0.6, 0.6);  // Increased base brightness
    vec3 b = vec3(0.6, 0.6, 0.6);  // Increased color variation scale
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    
    return a + b*cos(6.283185*(c*t+d));
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    //parameters
    float width = 0.02;
    float speed = -2.0;
    float timeOffset = 0.025;
    float startTime = 0.0;
    float variationSpeed = 0.5;
    float minFreq = 0.25;
    float maxFreq = 2.0;
    float colMult = 1.5;     // Increased color multiplier for brighter colors
    float colPow = 0.8;      // Decreased power for less contrast/darkness
    float waveRange = 0.1;
    
    //normalized uv
    vec2 uv = (screen_coords * 2.0 - resolution.xy) / resolution.y;
    
    //make a gradients in a sine form that starts from the middle
    float dist = length(uv);
    float freq = mix(minFreq, maxFreq, clamp(dist / 1.0, 0.0, 1.0));
    
    vec3 col = palette(dist+(time+timeOffset-startTime)*variationSpeed);
    
    dist = sin((min(dist, waveRange)*0.25+(max(dist-waveRange, 0.0))*2.5 + (time+timeOffset-startTime)*speed)/4.);
    dist = abs(dist);
    
    dist = width/dist;
    col *= dist;
    
    //pow modifier with reduced darkening effect
    col = vec3(pow(col.x, colPow), pow(col.y, colPow), pow(col.z, colPow));
    
    //mult modifier with increased brightness
    col = clamp(col * colMult, 0.0, 1.0);
    float gammaBoost = mix(-0.1, 0.0,max(smoothstep(waveRange, 0.5, dist)*1.0, step(1.0, dist)));
    // Calculate alpha - more straightforward approach
    float alpha = smoothstep(0.0, 0.3, max(max(col.r, col.g), col.b));
    
    // Scale alpha by intensity
    alpha *= intensity;
    
    // Enhance color brightness with intensity
    col *= mix(1.0, 1.5, intensity);
    
    // Return the final color with proper alpha
    return vec4(col, dist-0.1);
}