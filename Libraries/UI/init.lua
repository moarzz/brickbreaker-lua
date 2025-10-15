-- this file allows *marginally* easier interaction with the library
-- it allows users to use:
--* require("library")
-- instead of:
--* require("library/componentHandler");
-- (yes that is all this file realistically does)

local path = (...);

_G.ComponentHandler = require(path .. ".componentHandler");
_G.UIScene = require(path .. ".scene");

return ComponentHandler;