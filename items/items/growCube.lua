local GrowCube = ItemBase.new();
GrowCube.__index = GrowCube;
GrowCube.name = "Grow Cube";
GrowCube.description = "<font=bold>On Level Up<font=default>this Item gains +1 to a random stat";
GrowCube.rarity = "uncommon";
GrowCube.imageReference = "assets/sprites/UI/itemIcons/Grow-Cube.png";

function GrowCube.new()
    local instance = setmetatable({}, GrowCube):init();

    return instance;
end

function GrowCube.events:levelUp()
    local statNames = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"};
    local randomStatName = table.remove(statNames, math.random(1, #statNames));

    self.stats[randomStatName] = (self.stats[randomStatName] or 0) + (randomStatName == "cooldown" and -1 or 1);

    if randomStatName == "amount" then
        Balls.amountIncrease(1);
    end
end

return GrowCube;