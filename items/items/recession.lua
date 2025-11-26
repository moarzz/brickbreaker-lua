local Recession = ItemBase.new();
Recession.__index = Recession;
Recession.name = "Recession";
Recession.description = "<font=bold>On Level Up<font=default>\nreduce the upgrade price of all your items by 1 (min 0)";
Recession.rarity = "uncommon";
Recession.imageReference = "assets/sprites/UI/ItemIcons/Recession.png";

Recession.descriptionOverwrite = true; -- does smthn ig

function Recession.new()
    local instance = setmetatable({}, Recession):init();

    return instance;
end

function Recession.events:levelUp()
    for _, weaponType in ipairs(WeaponHandler.getActiveWeapons()) do
        reducePriceWithAnimations(1, weaponType.name, self.id);
    end
end

return Recession;