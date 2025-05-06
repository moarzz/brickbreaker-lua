shaders = {}

local pulseRadius = 0
local pulseActive = false

-- Create a custom shader for the pulse effect
local pulseShader = love.graphics.newShader([[
// Center of the pulse
extern vec2 center;
// Current radius of the pulse
extern float radius;
// Intensity of the offset
extern float intensity;
// Width of the affected outer circle
extern float width;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Calculate distance from the center
    float dist = distance(screen_coords, center);

    // Check if the pixel is within the edge of the pulse
    if (dist >= radius - width && dist <= radius) {
        // Calculate the offset based on the distance
        float offset = intensity * (1.0 - (dist - (radius - width)) / width);
        texture_coords += vec2(offset, offset);
    }

    // Return the modified color
    return Texel(texture, texture_coords) * color;
}
]])

-- Function to trigger the pulse
function shaders.triggerPulse(x, y, intensity, width)
    width = width or 10
    pulseShader:send("center", {x, y})
    pulseShader:send("intensity", intensity)
    pulseShader:send("width", width)
    pulseRadius = 0
    pulseActive = true
end

-- Function to update the pulse
function shaders.updatePulse(dt)
    if pulseActive then
        pulseRadius = pulseRadius + 200 * dt -- Expand the radius over time
        pulseShader:send("radius", pulseRadius)

        if pulseRadius > screenWidth then
            pulseActive = false -- Stop the pulse when it exceeds the screen
        end
    end
end

-- Function to draw the pulse effect
function shaders.drawPulse()
    if pulseActive then
        love.graphics.setShader(pulseShader) -- Apply the custom shader
    end
end

function shaders.draw()
    --Applies all the shaders if they're active
    shaders.drawPulse()

    --draw the canvas with the applied shaders
    love.graphics.draw(gameCanvas) -- Draw the game canvas with the shader
    love.graphics.setShader() -- Reset the shader
end

return shaders