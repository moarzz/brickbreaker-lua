
vec4 effect(vec4 colour, Image image, vec2 textureCoords, vec2 screenCoords)
{
    vec2 uv = textureCoords;
    vec2 center = vec2(0.5, 0.5);
    vec2 centered = uv - center;
    
    // Barrel distortion parameters
    float strength = 0.2;  // Strength of the barrel effect
    float radius = length(centered);
    
    // Apply barrel distortion
    float distorted = radius * (1.0 + strength * radius * radius);
    vec2 distortedUv = center + (centered / radius) * distorted;
    
    // Check if distorted UV is out of bounds
    if (distortedUv.x < 0.0 || distortedUv.x > 1.0 || 
        distortedUv.y < 0.0 || distortedUv.y > 1.0) {
        // Draw the bezel at the edges
        vec2 edgeUv = uv;
        float edgeDist = max(abs(centered.x), abs(centered.y));
        
        // Bezel extrusion
        float bezelWidth = 0.15;
        if (edgeDist > 0.5 - bezelWidth) {
            // We're in the bezel region
            float bezelFactor = (edgeDist - (0.5 - bezelWidth)) / bezelWidth;
            
            // Create 3D lighting on the bezel
            vec2 bezelNormal = normalize(centered);
            
            // Top-left light source
            vec3 lightDir = normalize(vec3(-0.5, 1.0, -0.5));
            vec3 bezelNormalVec = normalize(vec3(bezelNormal.x, 0.3, bezelNormal.y));
            float bezelLight = 0.05 + 0.12 * max(0.0, dot(bezelNormalVec, lightDir));
            
            // Darker at the very edge (chamfer)
            float chamfer = pow(bezelFactor, 1.5);
            float bezelColor = mix(0.02, bezelLight, chamfer);
            
            return vec4(vec3(bezelColor), 1.0);
        }
        
        return vec4(0.0);  // Draw nothing outside bezel
    }
    
    // Sample the texture from the distorted coordinates
    vec4 color = Texel(image, distortedUv);
    
    // Chromatic aberration
    float aberrationStrength = 0.002;
    vec2 aberrationDir = normalize(centered);
    float redShift = Texel(image, distortedUv + aberrationDir * aberrationStrength).r;
    float greenShift = Texel(image, distortedUv).g;
    float blueShift = Texel(image, distortedUv - aberrationDir * aberrationStrength).b;
    
    color.r = redShift;
    color.b = blueShift;
    
    // Add subtle scanlines for arcade authenticity
    float scanlines = sin(uv.y * 600.0) * 0.04 + 0.96;
    color.rgb *= scanlines;
    
    // Subtle highlight on the top-left corner of the bezel
    float cornerLight = 0.0;
    if (uv.x < 0.1 && uv.y < 0.1) {
        cornerLight = (0.1 - max(uv.x, uv.y)) * 0.2;
    }
    color.rgb += cornerLight * vec3(0.3, 0.3, 0.35);
    
    return color * colour;
}
