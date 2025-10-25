local ArcheologistHat = ItemBase.new();
ArcheologistHat.__index = ArcheologistHat;
ArcheologistHat.name = "Archeologist Hat";
ArcheologistHat.description = "<font=bold>On Level Up<font=default>\nadd a random rare or legendary item to the shop";
ArcheologistHat.rarity = "rare";

function ArcheologistHat.new()
    local instance = setmetatable({}, ArcheologistHat):init();

    return instance;
end

return ArcheologistHat;