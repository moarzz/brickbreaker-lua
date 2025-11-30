local industrialRevolution = ItemBase.new();
industrialRevolution.__index = industrialRevolution;
industrialRevolution.name = "Industrial Revolution";
industrialRevolution.description = "<font=bold>on level up\n<industrialRevolutionChance>%<font=default> chance to increase every stat of all your weapons by 1";
industrialRevolution.rarity = "legendary";
industrialRevolution.imageReference = "assets/sprites/UI/ItemIcons/Nirvana.png";

industrialRevolution.levelRequired = 2; -- does smth ig
industrialRevolution.levelCounter = 0;
industrialRevolution.currentLevelBeingChecked = 0;

function industrialRevolution.new()
    local instance = setmetatable({}, Nirvana):init();

    instance.descriptionPointers = {
        industrialRevolutionChance = hasItem("Four Leafed Clover") and 100 or 50;
    };

    return instance;
end

function industrialRevolution.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.nirvanaChance = 100;
end

function industrialRevolution.events:item_sell_FourLeafedClover()
    self.descriptionPointers.nirvanaChance = 50;
end

function industrialRevolution.events:levelUp()
    if math.random(1,100) <= self.descriptionPointers.nirvanaChance then
        for _, weapon in ipairs(WeaponHandler.getActiveWeapons()) do
            if not weapon.noAmount and weapon.type == "ball" then
                weapon.ballAmount = weapon.ballAmount + 1;
                --Balls.addBall(weapon.name, true);
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