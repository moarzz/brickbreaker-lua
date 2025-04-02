local UtilityFunction = require("UtilityFunction")

-- This file contains the player class, it manages his level, his abilities and his stats
local Player = {
    level = 1,
    xp = 3,
    xpToNextLevel = 5,
    xpRequiredMult = 1.5,
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
end

function Player:drawXPBar(width, height)
    local xpRatio = self.xp / self.xpToNextLevel
    love.graphics.setColor(0, 0, 0, 1) -- Black color for the XP bar background
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(UtilityFunction.HslaToRgba(195, 1, 0.5, 1)) -- Blue color for the XP bar
    love.graphics.rectangle("fill", 0, 0, width * xpRatio, height)
    love.graphics.setColor(1, 1, 1) -- Reset color to white
    love.graphics.rectangle("line", 0, 0, width, height) -- Draw the border of the XP bar
end
return Player