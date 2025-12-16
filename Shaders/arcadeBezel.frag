uniform float targetAberration = 0.00135;
uniform bool enableBezel = true;
uniform float pixelationScale = 0.0;  // 0.0 = no pixelation, higher values = more pixelated

vec4 effect(vec4 colour, Image image, vec2 textureCoords, vec2 screenCoords)
{
    vec2 uv = textureCoords;
    vec2 center = vec2(0.5, 0.5);
    vec2 centered = uv - center;
    
    // Barrel distortion parameters
    float strength = 0.1;  // Strength of the barrel effect
    float radius = length(centered);
    
    // Apply barrel distortion only if bezel is enabled
    vec2 distortedUv = uv;
    if (enableBezel) {
        float distorted = radius * (1.0 + strength * radius * radius);
        distortedUv = center + (centered / radius) * distorted;
    }
    
    float lightIntensity = 2.8;
    // Check if distorted UV is out of bounds
    if (enableBezel && (distortedUv.x < 0.0 || distortedUv.x > 1.0 || 
        distortedUv.y < 0.0 || distortedUv.y > 1.0)) {
        // Draw the bezel at the edges if enabled
        if (enableBezel) {
            vec2 edgeUv = uv;
            float edgeDist = max(abs(centered.x), abs(centered.y));
            
            // Bezel extrusion
            float bezelWidth = 0.15;
            if (edgeDist > 0.5 - bezelWidth) {
                // We're in the bezel region
                float bezelFactor = (edgeDist - (0.5 - bezelWidth)) / bezelWidth;
                
                // Determine which edge we're on
                vec2 absEdge = abs(centered);
                float edgeType = max(absEdge.x, absEdge.y) - min(absEdge.x, absEdge.y);
                
                // Create 3D lighting on the bezel
                vec2 bezelNormal = normalize(centered);
                
                // Light from directly above
                vec3 lightDir = normalize(vec3(0.0, 1.0, 0.0));
                
                // Surface normal points outward from center
                vec3 surfaceNormal = normalize(vec3(bezelNormal.x, 0.5, bezelNormal.y));
                
                // Apply lighting
                float lighting = max(0.15, dot(surfaceNormal, lightDir));
                
                // Smooth darkness based on Y position (top is darker)
                float topDarkness = mix(0.5, 1.0, (centered.y + 0.5) * 0.5);
                
                // Blend between shadow and lit
                float chamfer = pow(bezelFactor, 1.2);
                float bezelColor = mix(0.02, lighting * 0.4 * topDarkness, chamfer);
                
                // Add corner highlights on the bezel
                float cornerLight = 0.0;
                
                // Top-left corner
                if (uv.x < 0.1 && uv.y < 0.1) {
                    cornerLight += (0.1 - max(uv.x, uv.y)) * lightIntensity;
                }
                
                // Top-right corner
                if (uv.x > 0.9 && uv.y < 0.1) {
                    cornerLight += (0.1 - max(1.0 - uv.x, uv.y)) * lightIntensity;
                }
                
                // Bottom-left corner
                if (uv.x < 0.1 && uv.y > 0.9) {
                    cornerLight += (0.1 - max(uv.x, 1.0 - uv.y)) * lightIntensity;
                }
                
                // Bottom-right corner
                if (uv.x > 0.9 && uv.y > 0.9) {
                    cornerLight += (0.1 - max(1.0 - uv.x, 1.0 - uv.y)) * lightIntensity;
                }
                
                bezelColor += cornerLight * 0.3;
                
                return vec4(vec3(bezelColor), 1.0);
            }
        }
        
        return vec4(0.0);  // Draw nothing outside bezel
    }
    
    // Sample the texture from the distorted coordinates
    vec2 sampleUv = distortedUv;
    
    // Apply pixelation if enabled
    if (pixelationScale > 0.0) {
        float pixelSize = pixelationScale / 100.0;
        sampleUv = floor(distortedUv / pixelSize) * pixelSize;
    }
    
    vec4 color = Texel(image, sampleUv);
    
    // Chromatic aberration
    float aberrationStrength = targetAberration;
    vec2 aberrationDir = normalize(centered);
    float redShift = Texel(image, distortedUv + aberrationDir * aberrationStrength).r;
    float greenShift = Texel(image, distortedUv).g;
    float blueShift = Texel(image, distortedUv - aberrationDir * aberrationStrength).b;
    
    color.r = redShift;
    color.b = blueShift;
    
    // Add subtle scanlines for arcade authenticity
    float scanlines = sin(uv.y * 600.0) * 0.05 + 0.95;
    color.rgb *= scanlines;
    
    return color * colour;
}
