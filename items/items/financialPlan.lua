local FinancialPlan = ItemBase.new();
FinancialPlan.__index = FinancialPlan;
FinancialPlan.name = "Financial Plan";
FinancialPlan.description = "<font=bold>on level up<font=default>\ngain <font=big><color=money>2$";
FinancialPlan.rarity = "common";
FinancialPlan.imageReference = "assets/sprites/UI/ItemIcons/Financial-Plan.png";

function FinancialPlan.new()
    local instance = setmetatable({}, FinancialPlan):init();

    return instance;
end

function FinancialPlan.events:levelUp()
    if not hasItem("Abandon Greed") then
        Player.changeMoney(2, self.id);
        -- gainMoneyWithAnimations(3, self.name);
    end
end

return FinancialPlan;