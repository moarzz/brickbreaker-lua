local UtilityFunction = require("UtilityFunction")
local Balls = require("Balls")

-- This file contains the player class, it manages his level, his abilities and his stats
local Player = {
    level = 1,
    xp = 0,
    xpToNextLevel = 5,
    xpRequiredMult = 1.5,
    levelingUp = false
}

function Player:gainXP(amount)
    self.xp = self.xp + amount
    if self.xp >= self.xpToNextLevel then
        self:levelUp()
    end
end

function Player:levelUp()
    self.xp = 0
    self.level = self.level + 1
    self.xpToNextLevel = math.ceil(self.xpToNextLevel * self.xpRequiredMult)
    self.levelingUp = true
    -- Add any additional level-up logic here, such as increasing player stats or unlocking abilities
end

function Player:drawXPBar(width, height)
    local xpRatio = self.xp / self.xpToNextLevel
    love.graphics.setColor(0, 0, 0, 1) -- Black color for the XP bar background
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(UtilityFunction.HslaToRgba(195, 1, 0.5, 1)) -- Blue color for the XP bar
    love.graphics.rectangle("fill", 0, 0, width * xpRatio, height)
    love.graphics.setColor(1, 1, 1) -- Reset color to white
    love.graphics.rectangle("line", 0, 0, width, height) -- Draw the border of the XP bar
    love.graphics.print("Lv ".. self.level, 5, 5) -- Print the level inside the XP bar
end

function Player:drawLevelUpShop()
    love.graphics.setColor(0, 0, 0, 1) -- Black color for the background
    love.graphics.rectangle("fill", 150, 100, love.graphics.getWidth()- 300 , love.graphics.getHeight() - 200)
    love.graphics.setColor(1, 1, 1) -- White color for the text
    love.graphics.print("Level Up! Choose an upgrade:", 50, 50)
    -- Add buttons or options for upgrades here
    for i = 1, 3 do
        local buttonX = 175 + (i-1) * ((love.graphics.getWidth()- 300)/3)
        local buttonWidth = (love.graphics.getWidth()- 300)/3 - 60
        local buttonHeight = love.graphics.getHeight() - 250
        local mouseX, mouseY = love.mouse.getPosition()
        -- checks if button is hoverd and change color based on if it is
        isHovered = mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= 125 and mouseY <= 125 + buttonHeight
        color = isHovered and love.graphics.setColor(0.7, 0.7, 0.7, 1) or love.graphics.setColor(0.5, 0.5, 0.5, 1) 
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", 175 + (i-1) * ((love.graphics.getWidth()- 300)/3), 125, (love.graphics.getWidth()- 300)/3 -60, love.graphics.getHeight() - 250) -- Example button
        love.graphics.setColor(1, 1, 1) -- White color for the text
        love.graphics.printf("Upgrade ".. i, 175 + (i-1) * ((love.graphics.getWidth()- 300)/3), 150, (love.graphics.getWidth()- 300)/3 -60, "center")
    end
end

function Player:detectUpgradeClick(x, y)
    local buttonWidth = (love.graphics.getWidth() - 300) / 3 - 60
    local buttonHeight = love.graphics.getHeight() - 250
    local buttonY = 125

    for i = 1, 3 do
        local buttonX = 175 + (i - 1) * ((love.graphics.getWidth() - 300) / 3)
        if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
            print("Upgrade ".. i .." clicked!")
            -- upgrade logic
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        Player:detectUpgradeClick(x, y)
    end
end

local upgradeOptions = {
    {name = "+Ball speed", description = "Increase ball speed", effect = function() end},
    {name = "Size", description = "Increase ball size", effect = function() end},
    {name = "Power-up", description = "Unlock a new power-up", effect = function() end}
}
return Player