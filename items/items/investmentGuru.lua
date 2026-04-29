local InvestmentGuru = ItemBase.new();
InvestmentGuru.__index = InvestmentGuru;
InvestmentGuru.name = "Investment Guru";
InvestmentGuru.description = "<font=bold>On level up<font=default>\ngain +<color=money>1$<color=white> interest per level";
InvestmentGuru.rarity = "rare";
InvestmentGuru.imageReference = "assets/sprites/UI/ItemIcons/Investment-Guru.png";

InvestmentGuru.unique = true; -- does smthn ig

function InvestmentGuru.new()
    local instance = setmetatable({}, InvestmentGuru):init();

    return instance;
end

return InvestmentGuru;