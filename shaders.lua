shaders = {}

function shaders.load()
    glowEffect.glow.strength = 500 -- Adjust glow intensity
    glowEffect.glow.min_luma = 0.05 -- Minimum brightness to glow
end

function shaders.drawGlowLayer()
    love.graphics.setCanvas(glowCanvas)
    love.graphics.clear()

    -- Draw bricks for glow
    drawBricks()

    -- Draw paddle for glow
    love.graphics.setColor(1, 1, 1, 0.8) -- Use alpha < 1 for transparency
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)

    love.graphics.setCanvas()
end

function shaders.draw()

    -- Draw the main game canvas
    love.graphics.draw(gameCanvas)

    love.graphics.setCanvas()
    
    -- Reset the shader
    love.graphics.setShader()
end

return shaders