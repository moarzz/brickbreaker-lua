local InvestmentGuru = ItemBase.new();
InvestmentGuru.__index = InvestmentGuru;
InvestmentGuru.name = "Investment Guru";
InvestmentGuru.description = "<font=bold>On level up<font=default>\nadd a <font=bold>Long Term Investment<font=default> in the shop";
InvestmentGuru.rarity = "rare";
InvestmentGuru.imageReference = "assets/sprites/UI/itemIcons/Investment-Guru.png";

InvestmentGuru.unique = true; -- does smthn ig

function InvestmentGuru.new()
    local instance = setmetatable({}, InvestmentGuru):init();

    return instance;
end

return InvestmentGuru;