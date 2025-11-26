local PlusSixBuff = ItemBase.new();
PlusSixBuff.__index = PlusSixBuff;
PlusSixBuff.name = "Plus Six Buff";
PlusSixBuff.description = "";
PlusSixBuff.rarity = "rare";

function PlusSixBuff.new()
    local instance = setmetatable({}, PlusSixBuff):init();

    local itemStats = {};
    local statUnlocked = {}
    for _, weapon in ipairs(WeaponHandler.getActiveWeapons()) do
        for statName, _ in pairs(weapon.stats) do
            if not statUnlocked[statName] and statName ~= "damage" then
                table.insert(itemStats, statName);
                statUnlocked[statName] = true
            end
        end
        if weapon.type == "ball" then
            if not statUnlocked["amount"] then
                table.insert(itemStats, "amount");
                statUnlocked["amount"] = true
            end
        end
    end

    local statNames = {
        "speed";
        "amount";
        "ammo";
        "fireRate";
        "cooldown";
        "range";
    };

    local itemNames = {
        "Running Shoes ++";
        "Two for One Meal Ticket ++";
        "Extended Magazine ++";
        "Fast Hands ++";
        "Duct Tape ++";
        "Fake Pregnancy Belly ++";

    };

    local itemVersion = math.random(1, #itemStats);

    local randStat = itemStats[itemVersion];

    local name = "no name found"
    for i, statName in ipairs(statNames) do
        if randStat == statName then
            name = itemNames[i]
        end
    end
    instance.name = name;
    instance.stats[randStat] = randStat == "cooldown" and -6 or (randStat == "damage" and 3 or 6);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. (randStat == "cooldown" and "-.png" or "+.png")
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusSixBuff;