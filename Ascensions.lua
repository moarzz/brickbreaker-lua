local Ascensions = {
    {
        name = "Ascension 0",
        description = "No modifiers",
    },
    { -- done
        name = "Ascension 1",
        description = "Bricks scale in health 20% faster",
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
        description = "Boss spawns after 9 minutes instead of 10",
        onMatchStart = function()
            setBossSpawnTime(540)
        end
    },
    {
        name = "Ascension 5",
        description = "healing Bricks appear 50% more often",
    },
    {
        name = "Ascension 6",
        description = "bricks have 20% more health",
    },
    {
        name = "Ascension 7",
        description = "weapon upgrades cost 1$ more",
    },
    {
        name = "Ascension 8",
        description = "bricks move 20% faster",
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