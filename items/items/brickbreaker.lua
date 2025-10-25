local Brickbreaker = ItemBase.new();
Brickbreaker.__index = Brickbreaker;
Brickbreaker.name = "Brickbreaker";
Brickbreaker.description = "Every damage you deal has a <font=bold><killChance>%<font=default> chance of instantly killing the brick (<font=bold><bigKillChance>%</font=bold><font=default> for big bricks, <font=bold>0%</font=bold><font=default> for boss)";
Brickbreaker.rarity = "legendary";

Brickbreaker.unique = true; -- does smthn ig

function Brickbreaker.new()
    local instance = setmetatable({}, Brickbreaker):init();

    instance.descriptionPointers = {
        killChance    = hasItem("Four Leafed Clover") and 20 or 10;
        bigKillChance = hasItem("Four Leafed Clover") and 10 or 5;
    };

    return instance;
end

function Brickbreaker.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.killChance = 20;
    self.descriptionPointers.bigKillChance = 10;
end

function Brickbreaker.events:item_sell_FourLeafedClover()
    self.descriptionPointers.killChance = 10;
    self.descriptionPointers.bigKillChance = 5;
end

return Brickbreaker;