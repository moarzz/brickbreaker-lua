local Smoke = require("particleSystems.smoke");
local Explosion = require("particleSystems.explosion");
local ArcaneMissile = require("particleSystems.arcaneMissile");
local FlameBurst = require("particleSystems.flameBurst");

local WeaponHandler = {};
local self = WeaponHandler; -- for readability

function WeaponHandler.init()
    self.activeWeapons = {};
end

function WeaponHandler.addWeapon(weapon)
    if type(weapon) == "string" then
        weapon = Items.getWeaponByName(weapon).new();
    end

    table.insert(self.activeWeapons, weapon);
end

function WeaponHandler.update(dt)
    if Player.levelingUp or Player.choosingUpgrade then
        return;
    end

    for _, v in ipairs(self.activeWeapons) do
        v:update(dt);
    end
end

function WeaponHandler.draw()
    for _, v in ipairs(self.activeWeapons) do
        v:draw();
    end
end

WeaponHandler.init(); -- call init on require
return WeaponHandler;