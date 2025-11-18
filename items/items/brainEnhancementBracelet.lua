local brainEnhancementBracelet = ItemBase.new();
brainEnhancementBracelet.__index = brainEnhancementBracelet;
brainEnhancementBracelet.name = "Brain Enhancement Bracelet";
brainEnhancementBracelet.description = "Increase XP gain by <font=bold>22%";
brainEnhancementBracelet.rarity = "common";
brainEnhancementBracelet.imageReference = "assets/sprites/UI/ItemIcons/Brain-Enhancement-Bracelet.png";

function brainEnhancementBracelet.new()
    local instance = setmetatable({}, brainEnhancementBracelet):init();
    return instance;
end

function brainEnhancementBracelet:purchase()
    Player.xpGainMult = Player.xpGainMult + 0.22
end

return brainEnhancementBracelet;