local Ascensions = {
    {
        name = "Ascension 0",
        description = "No modifiers",
    },
    { -- done
        name = "Ascension 1",
        description = "Bricks scale in health 25% faster",
    },
    { -- done
        name = "Ascension 2",
        description = "fast bricks appear twice as often",
    },
    {
        name = "Ascension 3",
        description = "items cost 1$ extra",
    },
    {
        name = "Ascension 4",
        description = "Boss spawns after 8 minutes instead of 10",
        onMatchStart = function()
            setBossSpawnTime(480)
        end
    },
    {
        name = "Ascension 5",
        description = "healing Bricks appear twice as often",
    },
    {
        name = "Ascension 6",
        description = "weapon upgrades cost 1$ more",
    },
    {
        name = "Ascension 7",
        description = "bricks have 25% more health",
        onMatchStart = function()
            Player.brickHealthScalingMult = (Player.brickHealthScalingMult or 1) * 1.2
        end
    },
    {
        name = "Ascension 8",
        description = "bricks move 25% faster",
        onMatchStart = function()
            Player.brickHealthScalingMult = (Player.brickHealthScalingMult or 1) * 1.2
        end
    },
    {
        name = "Ascension 9",
        description = "There are only 2 options in the shop and on weapon unlock",
        onMatchStart = function()
            Player.brickHealthScalingMult = (Player.brickHealthScalingMult or 1) * 1.2
        end
    },
}

local currentAscension = 0
function Ascensions.setAscension(ascensionNum)
    currentAscension = ascensionNum
end

function Ascensions.getCurrentAscension()
    return currentAscension
end

function Ascensions.increaseAscension()
    if currentAscension < #Ascensions then
        currentAscension = currentAscension + 1
    end
end

function Ascensions.reduceAscension()
    if currentAscension > 0 then
        currentAscension = currentAscension - 1
    end
end

return Ascensions