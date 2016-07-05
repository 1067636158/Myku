
local Levels = {}

Levels.NODE_IS_WHITE  = 1
Levels.NODE_IS_BLACK  = 0
Levels.NODE_IS_EMPTY  = "X"

local levelsData = {}

levelsData[1] = {
    rows = 6,
    cols = 6,
    grid = {
        {1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1},
        {1, 1, 0, 1, 1, 1},
        {1, 0, 0, 0, 1, 1},
        {1, 1, 0, 1, 1, 1}
    }
}

levelsData[2] = {
    rows = 8,
    cols = 8,
    grid = {
        {1, 1, 1, 1, 1, 1, 0, 1},
        {1, 1, 1, 1, 1, 1, 0, 1},
        {1, 1, 1, 1, 1, 1, 0, 1},
        {1, 1, 1, 1, 1, 1, 0, 1},
        {1, 1, 1, 1, 1, 1, 0, 1},
        {1, 1, 1, 1, 1, 1, 0, 1},
        {1, 1, 1, 1, 1, 1, 0, 1},
        {1, 1, 1, 1, 1, 1, 0, 1},
    }
}

levelsData[3] = {
   rows = 9,
    cols = 9,
    grid = {
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
        {1, 1, 1, 1, 1, 1, 0, 1 , 1},
    }
}

function Levels.numLevels()
    return #levelsData
end

function Levels.get(levelIndex)
    assert(levelIndex >= 1 and levelIndex <= #levelsData, string.format("levelsData.get() - invalid levelIndex %s", tostring(levelIndex)))
    return clone(levelsData[levelIndex])
end

return Levels
