local Overclock = ItemBase.new();
Overclock.__index = Overclock;
Overclock.name = "Overclock";
Overclock.description = "When you buy this, increase the <color=damage>damage<color=white> of all your weapons by 1";
Overclock.rarity = "uncommon";
Overclock.imageReference = "assets/sprites/UI/ItemIcons/Overclock.png";

Overclock.consumable = true; -- does smthn ig

function Overclock.new()
    local instance = setmetatable({}, Overclock):init();

    return instance;
end

function Overclock:purchase()
    for _, weapon in ipairs(WeaponHandler.getActiveWeapons()) do
        weapon.stats.damage = weapon.stats.damage + 1
    end
end

return Overclock;