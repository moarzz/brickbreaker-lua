local Thundershock = ItemBase.new();
Thundershock.__index = Thundershock;
Thundershock.name = "Thundershock";
Thundershock.description = "<font=bold>On brick destroyed<font=default>\nSummon a lightning bolt that deals 35% of a random brick's health";
Thundershock.rarity = "common";
Thundershock.shotCount = 0;
Thundershock.unique = true
-- CoverLaser.imageReference = "assets/sprites/UI/ItemIcons/Cover-Laser.png";
function Thundershock.new()
    local instance = setmetatable({}, Thundershock):init();

    return instance;
end

function Thundershock:onBrickDestroyed()
    playSoundEffect(lightningPulseSFX, 0.1, 0.85)
    local selectedBrickIds = {}
    local iterations = 0
    local go = true
    local randomBrick
    while go do
        iterations = iterations + 1
        local randomBrickId = math.random(1, #bricks)
        randomBrick = bricks[randomBrickId]
        if randomBrick.y >= 0 and randomBrick.health > 0 and (not randomBrick.destroyed) then
            go = false
        elseif iterations >= 100 then
            go = false
        end
    end
    createSpriteAnimation(randomBrick.x + randomBrick.width/2, randomBrick.y + randomBrick.height/2, 0.25, sparkVFX, 512, 512, 0.075, 1)

    local thunderDamage = math.ceil(randomBrick.health * 0.35)
    Timer.after(0.125, function()
        dealDamage({stats = {damage = thunderDamage}}, randomBrick)
    end)
end


return Thundershock;