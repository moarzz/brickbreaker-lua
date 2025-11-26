local LightBeam = WeaponBase.new();
LightBeam.__index = LightBeam;
LightBeam.name = "Light Beam";
LightBeam.type = "spell";
LightBeam.description = "Fires beams of light that pierces through bricks, dealing huge aoe damage.";
LightBeam.rarity = "rare";
LightBeam.startingPrice = 100;
LightBeam.size = 1;
LightBeam.stats = {
    damage = 2;
    amount = 2;
    cooldown = 12;
};

LightBeam.trail = Trail.new(10, 50);
LightBeam.noAmount = true;

function LightBeam.new()
    local instance = setmetatable({}, LightBeam):init();

    return instance;
end

function LightBeam:onBuy()
    -- cast (?)
end

return LightBeam;