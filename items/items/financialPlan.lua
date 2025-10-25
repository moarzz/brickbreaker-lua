local FinancialPlan = ItemBase.new();
FinancialPlan.__index = FinancialPlan;
FinancialPlan.name = "Financial Plan";
FinancialPlan.description = "<font=bold>on level up<font=default>\ngain <font=big><color=money>3$";
FinancialPlan.rarity = "common";

function FinancialPlan.new()
    local instance = setmetatable({}, FinancialPlan):init();

    return instance;
end

function FinancialPlan.events:levelUp()
    if not hasItem("Abandon Greed") then
        gainMoneyWithAnimations(3, self.name);
    end
end

return FinancialPlan;