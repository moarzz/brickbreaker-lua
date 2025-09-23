-- main.lua - Complete ripple effect converted from Shadertoy
-- This is a working Love2D (Lua game framework) implementation
local damageRipples = {}
local time = 0
local shader
local points = {}
local maxPoints = 4

-- Shader code converted from your Shadertoy shader
local fragmentShaderCode = [[
#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.141592653
#define POINT_COUNT_MAX 4

uniform float u_time;
uniform vec2 u_resolution;
uniform int u_pointCount;
uniform vec2 u_points[POINT_COUNT_MAX];
uniform float u_timers[POINT_COUNT_MAX];

vec2 baseDistortion(vec2 pixelPos, float time) {
    vec2 distortion = vec2(0.0);
    distortion.x += sin(pixelPos.x / 400.0 * PI + time * 0.05) * 2.0;
    distortion.y += sin(pixelPos.y / 300.0 * PI + time * 0.03) * 1.5;
    return distortion;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 fragCoord = screen_coords;
    vec2 pixelCoords = fragCoord + baseDistortion(fragCoord, u_time);
    vec2 distortedPoint = pixelCoords;
    
    // Apply ripple distortions
    for (int i = 0; i < POINT_COUNT_MAX; i++) {
        if (i >= u_pointCount) break;
        
        float distance = length(pixelCoords - u_points[i]);
        float speedMult = 2.0;
        float distanceSlowdown = 1.0 + (distance / 75.0);
        float effectiveTimer = u_timers[i] * speedMult / distanceSlowdown;
        float rippleRadius = effectiveTimer * 40.0;
        float rippleWidth = 20.0;
        
        if (distance >= rippleRadius - rippleWidth && distance <= rippleRadius + rippleWidth) {
            float ripplePhase = (distance - rippleRadius) / 15.0;
            float amplitude = 200.0 * sin(ripplePhase * PI) * 
                             exp(-abs(ripplePhase) * 0.8) * 
                             (1.0 - u_timers[i] / 15.0);
            
            float fallOffDistance = 5.0;
            amplitude = amplitude * min(fallOffDistance / distance, 1.0);
            
            vec2 direction = normalize(pixelCoords - u_points[i]);
            distortedPoint += direction * amplitude;
        }
    }
    
    // Sample the canvas texture at the distorted coordinates
    vec2 distortedUV = distortedPoint / u_resolution;
    
    // Keep UV coordinates in bounds
    distortedUV = clamp(distortedUV, 0.0, 1.0);
    
    return Texel(texture, distortedUV);
}
]]

function damageRipples.load()
    -- Create the shader
    shader = love.graphics.newShader(fragmentShaderCode)
    
    -- Initialize points (converted from your original hardcoded points)
    local modulation = 10.0
    
    -- Add the first point (the one that was active in your original code)
    addRipplePoint(400, 200, 0, 3.0, modulation)
    
    -- Uncomment these to add the other points from your original code:
    addRipplePoint(400, 150, 4.0, 2.5, modulation)
    addRipplePoint(150, 400, 8.0, 4.0, modulation)
    addRipplePoint(450, 350, 12.0, 3.5, modulation)
end

function damageRipples.update(dt)
    time = time + dt
    
    -- Add ripple on mouse click
    if love.mouse.isDown(1) then
        local mx, my = love.mouse.getPosition()
        -- Only add if we're not at max points and not too close to existing points
        if #points < maxPoints then
            addRipplePoint(mx, my, time * 3, 3.0, 10.0)
        end
    end
    
    -- Remove old/faded ripples
    for i = #points, 1, -1 do
        local timer = (time * points[i].speed + points[i].timeOffset) % points[i].modulation
        if timer > 9.0 then -- Remove when almost faded
            table.remove(points, i)
        end
    end
end

function damageRipples.draw()
    local width, height = love.graphics.getDimensions()
    
    -- Prepare uniform data
    local pointPositions = {}
    local timers = {}
    
    for i = 1, maxPoints do
        if points[i] then
            pointPositions[i*2-1] = points[i].x
            pointPositions[i*2] = points[i].y
            timers[i] = (time * points[i].speed + points[i].timeOffset) % points[i].modulation
        else
            pointPositions[i*2-1] = 0
            pointPositions[i*2] = 0
            timers[i] = 0
        end
    end
    
    -- Set shader uniforms and apply ripple effect to gameCanvas
    love.graphics.setCanvas()
    love.graphics.setShader(shader)
    shader:send("u_time", time)
    shader:send("u_resolution", {width, height})
    shader:send("u_pointCount", math.min(#points, maxPoints))
    shader:send("u_points", pointPositions)
    shader:send("u_timers", unpack(timers))

    -- Draw the gameCanvas image with the ripple shader
    love.graphics.draw(gameCanvas, 0, 0)
    love.graphics.setShader()
    
    -- Draw UI
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("Click to add ripples", 10, 10)
    love.graphics.print("Active ripples: " .. #points .. "/" .. maxPoints, 10, 30)
    love.graphics.print("Press 'c' to clear all ripples", 10, 50)
    love.graphics.print("Press 'r' to reset to original points", 10, 70)
    love.graphics.setColor(1, 1, 1, 1)
end

function damageRipples.keypressed(key)
    if key == "c" then
        -- Clear all ripples
        points = {}
    elseif key == "r" then
        -- Reset to original points
        points = {}
        local modulation = 10.0
        addRipplePoint(400, 200, 0, 3.0, modulation)
        addRipplePoint(400, 150, 4.0, 2.5, modulation)
        addRipplePoint(150, 400, 8.0, 4.0, modulation)
        addRipplePoint(450, 350, 12.0, 3.5, modulation)
    elseif key == "escape" then
        love.event.quit()
    end
end

local pointID = 0
-- Helper functions
function addRipplePoint(x, y, timeOffset, speed, modulation)
    if #points < maxPoints then
        table.insert(points, {
            id = pointID,
            x = x,
            y = y,
            timeOffset = timeOffset or 0,
            speed = speed or 3.0,
            modulation = modulation or 10.0
        })
        Timer.after(2, function()
            -- Automatically remove point after 2 seconds
            for i = #points, 1, -1 do
                if points[i].id == pointID then
                    table.remove(points, i)
                    break
                end
            end
        end)
        pointID = pointID + 1
    end
end

return damageRipples