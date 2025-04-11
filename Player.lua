local upgradesUI = require("upgradesUI")

-- This file contains the player class, it manages his level, his abilities and his stats
Player = {
    level = 1,
    xp = 0,
    xpToNextLevel = 5,
    xpRequiredMult = 1.5,
    money = 0,
    lives = 3,
    levelingUp = false
}

function Player:gainXP(amount)
    self.xp = self.xp + amount
    if self.xp >= self.xpToNextLevel then
        self:levelUp()
    end
end

function Player:drawXPBar(width, height)
    local xpRatio = self.xp / self.xpToNextLevel
    love.graphics.setColor(0, 0, 0, 1) -- Black color for the XP bar background
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(HslaToRgba(195, 1, 0.5, 1)) -- Blue color for the XP bar
    love.graphics.rectangle("fill", 0, 0, width * xpRatio, height)
    love.graphics.setColor(1, 1, 1) -- Reset color to white
    love.graphics.rectangle("line", 0, 0, width, height) -- Draw the border of the XP bar
    love.graphics.print("Lv ".. self.level, 5, 5) -- Print the level inside the XP bar
    love.graphics.setColor(1, 1, 1) -- reset color to white
end



function Player:levelUp()
    self.xp = 0
    self.level = self.level + 1
    self.xpToNextLevel = math.ceil(self.xpToNextLevel * self.xpRequiredMult)
    self.levelingUp = true
    upgradesUI.chooseUpgrades()
end



return Player