local moneyCrazy = ItemBase.new();
moneyCrazy.__index = moneyCrazy;
moneyCrazy.name = "Money Crazy";
moneyCrazy.description = "collecting a dollar bill <color=amount><font=big>accelerates<color=white><font=default> your items for 2 seconds";
moneyCrazy.rarity = "uncommon";
moneyCrazy.imageReference = "assets/sprites/UI/ItemIcons/Money-Crazy.png";

moneyCrazy.unique = true;

function moneyCrazy.new()
    local instance = setmetatable({}, moneyCrazy):init();
    
    return instance;
end

return moneyCrazy;