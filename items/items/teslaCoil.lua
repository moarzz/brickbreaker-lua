local TeslaCoil = ItemBase.new();
TeslaCoil.__index = TeslaCoil;
TeslaCoil.name = "Tesla Coil";
TeslaCoil.description = "<font=bold>On level up<font=default>\nupgrade all stats of a random weapon by 1";
TeslaCoil.rarity = "rare";
TeslaCoil.imageReference = "assets/sprites/UI/ItemIcons/Tesla-Coil.png";

function TeslaCoil.new()
    local instance = setmetatable({}, TeslaCoil):init();

    return instance;
end

function TeslaCoil.events:levelUp()
    local weapons = WeaponHandler.getActiveWeapons();
    local randomWeaponId = math.random(1, #weapons);
    local i = 1;

    for i, weapon in ipairs(weapons) do
        local statNames = {};

        for statName, statValue in pairs(weapon.stats) do
            statNames[statName] = statValue;
        end

        if weapon.type == "ball" and (not statNames["amount"]) then
            statNames["amount"] = 0;
        end

        if i == randomWeaponId then
            for statName, statValue in pairs(statNames) do
                gainStatWithAnimation(statName, weapon.name, self.id);
            end
        end
    end
end

return TeslaCoil;