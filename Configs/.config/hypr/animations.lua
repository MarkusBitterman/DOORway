-- DOORway managed - set via doorway.animations.preset in your home config.
-- See animations/ directory to add or edit presets.

local _a_ok, _a = pcall(require, "doorway-animation-preset")
local animation = _a_ok and _a.preset or "standard"
require("animations/" .. animation)
