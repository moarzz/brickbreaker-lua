local SacredGift = ItemBase.new();
SacredGift.__index = SacredGift;
SacredGift.name = "Sacred Gift";
SacredGift.description = "When you buy this, increase all your weapon's stats by 1";
SacredGift.rarity = "legendary";

SacredGift.consumable = true; -- does smthn ig

function SacredGift.new()
    local instance = setmetatable({}, SacredGift):init();

    return instance;
end

function SacredGift:purchase()
    for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
        if not weapon.noAmount and weakpon.type == "ball" then
            weapon.ballAmount = weapon.ballAmount + 1;
            Balls.addBall(weapon.name, true);
        end

        for statName, statValue in pairs(weapon.stats) do
            if statName == "cooldown" then
                weapon.stats[statName] = statValue - 1;
            elseif statName == "speed" then
                weapon.stats[statName] = statValue + 50;
            else
                weapon.stats[statName] = statValue + 1;
            end
        end
    end
end

return SacredGift;