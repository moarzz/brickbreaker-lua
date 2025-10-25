local Nirvana = ItemBase.new();
Nirvana.__index = Nirvana;
Nirvana.name = "Nirvana";
Nirvana.description = "<font=bold>on level up\n<nirvanaChance>%<font=default> chance to increase every stat of all your weapons by 1";
Nirvana.rarity = "legendary";

Nirvana.levelRequired = 2; -- does smth ig
Nirvana.levelCounter = 0;
Nirvana.currentLevelBeingChecked = 0;

function Nirvana.new()
    local instance = setmetatable({}, Nirvana):init();

    instance.descriptionPointers = {
        nirvanaChance = hasItem("Four Leafed Clover") and 100 or 50;
    };

    return instance;
end

function Nirvana.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.nirvanaChance = 100;
end

function Nirvana.events:item_sell_FourLeafedClover()
    self.descriptionPointers.nirvanaChance = 50;
end

function Nirvana.events:levelUp()
    if math.random(1,100) <= self.descriptionPointers.nirvanaChance then
        for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
            if not weapon.noAmount and weapon.type == "ball" then
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
end

return Nirvana;