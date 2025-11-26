local Smoke = require("particleSystems.smoke");
local Explosion = require("particleSystems.explosion");
local ArcaneMissile = require("particleSystems.arcaneMissile");
local FlameBurst = require("particleSystems.flameBurst");

local WeaponHandler = {};
local self = WeaponHandler; -- for readability

function WeaponHandler.init()
    self.activeWeapons = {};

    self.activeEntities = {};
end

function WeaponHandler.update(dt)
end

function WeaponHandler.draw()
end

return WeaponHandler;