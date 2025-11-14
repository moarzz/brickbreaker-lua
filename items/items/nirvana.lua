local Nirvana = ItemBase.new();
Nirvana.__index = Nirvana;
Nirvana.name = "Nirvana";
Nirvana.description = "When you buy this, increase all your weapon's stats by 2";
Nirvana.rarity = "legendary";

Nirvana.consumable = true; -- does smthn ig

function Nirvana.new()
    local instance = setmetatable({}, Nirvana):init();

    return instance;
end

function Nirvana:purchase()
    for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
        if not weapon.noAmount and weakpon.type == "ball" then
            weapon.ballAmount = weapon.ballAmount + 2;
            Balls.addBall(weapon.name, true);
            Balls.addBall(weapon.name, true);
        end

        for statName, statValue in pairs(weapon.stats) do
            if statName == "cooldown" then
                weapon.stats[statName] = statValue - 2;
            elseif statName == "speed" then
                weapon.stats[statName] = statValue + 100;
            else
                weapon.stats[statName] = statValue + 1;
            end
        end
    end
end

return Nirvana;