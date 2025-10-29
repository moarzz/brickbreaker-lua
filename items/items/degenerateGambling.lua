local DegenerateGambling = ItemBase.new();
DegenerateGambling.__index = DegenerateGambling;
DegenerateGambling.name = "Degenerate Gambling";
DegenerateGambling.description = "<font=bold>on level up\n<gambleChance>%<font=default> chance to gain <font=big><color=money>15$";
DegenerateGambling.rarity = "uncommon";
DegenerateGambling.imageReference = "assets/sprites/UI/ItemIcons/Degenerate-Gambling.png";

DegenerateGambling.randomnessMult = 0.8; -- does smthn ig

function DegenerateGambling.new()
    local instance = setmetatable({}, DegenerateGambling):init();

    instance.descriptionPointers = {
        gambleChance = hasItem("Four Leafed Clover") and 50 or 25;
    };

    return instance;
end

function DegenerateGambling.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.gambleChance = 50;
end

function DegenerateGambling.events:item_sell_FourLeafedClover()
    self.descriptionPointers.gambleChance = 25;
end

function DegenerateGambling.events:levelUp()
    if hasItem("Abandon Greed") then
        return;
    end

    if math.random(1,100) <= (self.descriptionPointers.gambleChance) then
        Player.changeMoney(15);
        -- gainMoneyWithAnimations(20, self.name);
    end
end

return DegenerateGambling;