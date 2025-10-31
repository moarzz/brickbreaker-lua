local CouponCollector = ItemBase.new();
CouponCollector.__index = CouponCollector;
CouponCollector.name = "Coupon Collector";
CouponCollector.description = "<font=bold>On Level Up<font=default>\nreduce the upgrade price of a weapon by <color=money>1$\n\n<color=white>Items cost <color=money>1$<color=white> less";
CouponCollector.rarity = "common";
CouponCollector.imageReference = "assets/sprites/UI/ItemIcons/Coupon-Collector.png";

function CouponCollector.new()
    local instance = setmetatable({}, CouponCollector):init();

    return instance;
end

function CouponCollector.events:levelUp()
    if not hasItem("Abandon Greed") then
        -- Player.changeMoney(1, self.id);
        -- gainMoneyWithAnimations(1, self.name);
    end

    local randomWeaponId = math.random(1, tableLength(Balls.getUnlockedBallTypes()));
    local i = 1;

    for weaponId, weapon in pairs(Balls.getUnlockedBallTypes()) do
        if i == randomWeaponId then
            reducePriceWithAnimations(1, weapon.name, self.id);
            break;
        end

        i = i + 1;
    end
end

return CouponCollector;