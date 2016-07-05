
local Levels = import("..data.MyLevels")
    local starsBox = 
{
    "#x0001.png",
    "#x0002.png",
    "#x0003.png",
    "#x0004.png",
    "#x0005.png",
    "#x0006.png",
    "#x0007.png",
    "#x0008.png",
}

local Coin = class("Coin", function(nodeType)
	
    local index =math.random(#starsBox) 
    
    local sprite = display.newSprite(string.format(starsBox[index]))
          sprite.nodeType=index
    return sprite
end)



return Coin
