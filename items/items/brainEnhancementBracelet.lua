local brainEnhancementBracelet = ItemBase.new();
brainEnhancementBracelet.__index = brainEnhancementBracelet;
brainEnhancementBracelet.name = "Brain Enhancement Bracelet";
brainEnhancementBracelet.description = "Increase XP gain by <font=bold>18%";
brainEnhancementBracelet.rarity = "common";
brainEnhancementBracelet.imageReference = "assets/sprites/UI/ItemIcons/Brain-Enhancement-Bracelet.png";

function brainEnhancementBracelet.new()
    local instance = setmetatable({}, brainEnhancementBracelet):init();
    Player.xpGainMult = Player.xpGainMult + 0.18
    return instance;
end

return brainEnhancementBracelet;