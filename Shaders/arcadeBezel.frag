uniform bool disableBezel; 
uniform float targetAberration; // Defaults to 0.0 in browser
uniform float pixelationScale;

vec4 effect(vec4 colour, Image image, vec2 textureCoords, vec2 screenCoords)
{
    vec2 uv = textureCoords;
    vec2 center = vec2(0.5, 0.5);
    vec2 centered = uv - center;
    
    float strength = 0.1;
    float radius = length(centered);
    vec2 distortedUv = uv;

    if (!disableBezel) {
        float distorted = radius * (1.0 + strength * radius * radius);
        distortedUv = center + (centered / (radius + 0.00001)) * distorted;
    }
    
    // BEZEL RENDERING
    if (!disableBezel && (distortedUv.x < 0.0 || distortedUv.x > 1.0 || distortedUv.y < 0.0 || distortedUv.y > 1.0)) {
        float edgeDist = max(abs(centered.x), abs(centered.y));
        float bezelWidth = 0.15;
        if (edgeDist > 0.5 - bezelWidth) {
            float bezelFactor = (edgeDist - (0.5 - bezelWidth)) / bezelWidth;
            vec2 bezelNormal = normalize(centered + 0.00001);
            vec3 surfaceNormal = normalize(vec3(bezelNormal.x, 0.5, bezelNormal.y));
            float lighting = max(0.15, dot(surfaceNormal, normalize(vec3(0.0, 1.0, 0.0))));
            float bezelColor = mix(0.02, lighting * 0.4 * mix(0.5, 1.0, (centered.y + 0.5) * 0.5), pow(bezelFactor, 1.2));
            return vec4(vec3(bezelColor), 1.0);
        }
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
    
    // SCREEN CONTENT
    vec2 sampleUv = distortedUv;
    if (pixelationScale > 0.0) {
        float pixelSize = pixelationScale / 100.0;
        sampleUv = floor(distortedUv / pixelSize) * pixelSize;
    }
    
    // CHROMATIC ABERRATION FIX
    // Use a small default (0.0015) if targetAberration is not sent from Lua
    float finalAberration = (targetAberration <= 0.0) ? 0.0015 : targetAberration;
    vec2 aberrationDir = normalize(centered + 0.00001);

    // Sample all three channels separately 
    float r = Texel(image, sampleUv + aberrationDir * finalAberration).r;
    float g = Texel(image, sampleUv).g;
    float b = Texel(image, sampleUv - aberrationDir * finalAberration).b;
    
    vec4 color = vec4(r, g, b, 1.0);

    // Scanlines
    float scanlines = sin(uv.y * 600.0) * 0.05 + 0.95;
    color.rgb *= scanlines;
    
    return color * colour;
}