local Thundershock = ItemBase.new();
Thundershock.__index = Thundershock;
Thundershock.name = "Thundershock";
Thundershock.description = "<font=bold>On brick destroyed<font=default>\nSummon a lightning bolt that deals 40% of a random brick's health";
Thundershock.rarity = "uncommon";
Thundershock.shotCount = 0;
Thundershock.unique = true
Thundershock.imageReference = "assets/sprites/UI/ItemIcons/Thundershock.png";
function Thundershock.new()
    local instance = setmetatable({}, Thundershock):init();

    return instance;
end

function Thundershock:onBrickDestroyed()
    local selectedBrickIds = {}
    local iterations = 0
    local go = true
    local randomBrick
    while go do
        iterations = iterations + 1
        local randomBrickId = math.random(1, #bricks)
        randomBrick = bricks[randomBrickId]
        if randomBrick then
            if randomBrick.y >= 0 and randomBrick.health > 0 and (not randomBrick.destroyed) and (randomBrick.type ~= "boss") then
                go = false
            elseif iterations >= 100 then
                go = false
            end
        end
    end
    if not randomBrick then
        return
    end
    createSpriteAnimation(randomBrick.x + randomBrick.width/2, randomBrick.y + randomBrick.height/2, 0.25, sparkVFX, 512, 512, 0.075, 1)

    local thunderDamage = math.ceil(randomBrick.health * (hasItem("Four Leafed Clover") and 0.8 or 0.4))
    Timer.after(0.125, function()
        if randomBrick.type ~= "boss" then
            dealDamage({stats = {damage = thunderDamage}}, randomBrick)
        end
    end)
end


return Thundershock;