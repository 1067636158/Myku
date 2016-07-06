local Levels = import("..data.MyLevels")
local Coin   = import("..views.MyCoin")

local Board = class("Board", function()
    return display.newNode()
end)

local NODE_PADDING   = 100
local NODE_ZORDER    = 0

local COIN_ZORDER    = 1000

function Board:ctor(levelData)
    cc.GameObject.extend(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    self.batch = display.newNode()
    self.batch:setPosition(display.cx, display.cy)
    self:addChild(self.batch)

    self.grid = {}

    --多加上一个屏幕的缓冲格子
    for i=1,levelData.rows * 2 do
        self.grid[i] = {}
        if levelData.grid[i] == nil then
            levelData.grid[i] = {}
        end
        for j=1,levelData.cols do
            self.grid[i][j] = levelData.grid[i][j]
        end
    end
    self.rows = levelData.rows
    self.cols = levelData.cols
    self.coins = {}
    self.flipAnimationCount = 0
    math.randomseed( tostring(os.time()):reverse():sub(1,6) )
    -- create board, place all coins
    if self.cols >= 8 then
        self.SCALE = ( 640 / self.cols ) / 100
        local NODE_PADDING2 = math.floor(NODE_PADDING * self.SCALE)
        self.offsetX = -math.floor(NODE_PADDING2 * self.cols / 2 ) - NODE_PADDING2 / 2 
        self.offsetY = -math.floor(NODE_PADDING2 * self.rows / 2 ) - NODE_PADDING2 / 2 
        for row = 1, self.rows do
            local y = row * NODE_PADDING2 + self.offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING2 + self.offsetX
                local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                nodeSprite:setScale(self.SCALE)
                self.batch:addChild(nodeSprite, NODE_ZORDER)

                local node = self.grid[row][col]
                if node ~= Levels.NODE_IS_EMPTY then
                    local coin = Coin.new(node)
                    coin:setPosition(x, y)
                    coin:setScale(self.SCALE)
                    coin.row = row
                    coin.col = col
                    self.grid[row][col] = coin
                    self.coins[#self.coins + 1] = coin
                    self.batch:addChild(coin, COIN_ZORDER)
                    --printf("%d----%d*****%d", coin.row,coin.col,coin.nodeType)
                end
            end
        end
    else
        self.SCALE = 1.0
        self.offsetX = -math.floor(NODE_PADDING * self.cols / 2) - NODE_PADDING / 2
        self.offsetY = -math.floor(NODE_PADDING * self.rows / 2) - NODE_PADDING / 2
        for row = 1, self.rows do
            local y = row * NODE_PADDING + self.offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING + self.offsetX
                local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                self.batch:addChild(nodeSprite, NODE_ZORDER)

                local node = self.grid[row][col]
                if node ~= Levels.NODE_IS_EMPTY then
                    local coin = Coin.new(node)
                    coin:setPosition(x, y)
                    coin.row = row
                    coin.col = col
                    self.grid[row][col] = coin
                    self.coins[#self.coins + 1] = coin
                    self.batch:addChild(coin, COIN_ZORDER)
                    --printf("%d----%d*****%d", coin.row,coin.col,coin.nodeType)
                 
                end
            end
        end
    end    
    print("lalala")
   
    
    self:setNodeEventEnabled(true)
    self:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)
    
    while self:CheckAll() do
        self:changeSingedCell()
    end
end
function Board:CheckAll( )
    -- body
    for _ ,v in ipairs(self.coins) do
       -- printf("%d----%d*****%d", coin.row,coin.col,coin.nodeType)
       self:findStars(v)

    end
    for i,v in pairs (self.coins) do
        if v.isNeedClean  then
            return true
        end
    end
    return false
end

function Board:checkLevelCompleted(onAnimationComplete)
    local count = 0
    for _, coin in ipairs(self.coins) do
        if coin.isWhite then count = count + 1 end
    end
    if count == #self.coins then
        -- completed
        self:setTouchEnabled(false)
        self:dispatchEvent({name = "LEVEL_COMPLETED"})
    end    
end    
function Board:findStars(coin)
    local listH = {}
    local listV = {}
    listH [#listH + 1] = coin
    listV [#listV + 1] = coin
    local i=coin.col
    while i > 1 do
        i = i -1
        local coin_left = self:getCoin(coin.row,i)
        if coin_left then
            if coin.nodeType == coin_left.nodeType then
                listH [#listH + 1] = coin_left
            else
                break
            end
        end
    end
    if coin.col ~= self.cols then
        for j=coin.col+1 , self.cols do
            local coin_right = self:getCoin(coin.row,j)
            if coin_right then
                if coin.nodeType == coin_right.nodeType then
                    listH [#listH + 1] = coin_right
                else
                    break
                end
            end
        end
    end
    if #listH < 3 then
        listH = {}
    else
        for i,v in pairs(listH) do
            v.isNeedClean = true
        end
        listH = {}
    end
    local k=coin.row
    while k > 1 do
        k = k -1
        local coin_down = self:getCoin(k,coin.col)
        if coin_down then
            if coin.nodeType == coin_down.nodeType then
                listV [#listV + 1] = coin_down
            else
                break
            end
        end
    end
    if coin.row ~= self.rows then
        for o=coin.row+1 , self.rows do
            local coin_up = self:getCoin(o,coin.col)
            if coin_up then
                if coin.nodeType == coin_up.nodeType then
                    listV [#listV + 1] = coin_up
                else
                    break
                end
            end
        end
    end
    if #listV < 3 then
        listV = {}
    else
        for i,v in pairs(listV) do
            v.isNeedClean = true
        end
        listV = {}
    end
end 
function Board:changeSingedCell()
    local sum = 0
    local DropList = {}
    local DropHigh = {}
    for i ,v in ipairs(self.coins) do
        if v.isNeedClean then
            sum = sum +1
            local drop_pad = 1
            local row = v.row
            local col = v.col
            local x = col * NODE_PADDING *self.SCALE + self.offsetX
            local y = (self.rows + 1)* NODE_PADDING * self.SCALE+ self.offsetY
            for i,v in pairs(DropList) do
                if col == v.col then
                    drop_pad = drop_pad + 1
                    y = y + NODE_PADDING * self.SCALE

                end
            end
            
            for i,k in pairs(DropHigh) do
               if col == k.col then
                   
                    table.remove(DropHigh,i)
                    
                end
            end
            local coin = Coin.new()
            DropList [#DropList + 1] = coin
            DropHigh [#DropHigh + 1] = coin
            coin.isNeedClean = false
            coin:setPosition(x, y)
            coin:setScale(self.SCALE)
            coin.row = self.rows + drop_pad
            coin.col = col
            self.grid[self.rows + drop_pad][col] = coin
            if onAnimationComplete == nil then
                self.batch:removeChild(v, true)
                self.grid[row][col] = nil
            else
            end
            self.coins[i] = coin
            self.batch:addChild(coin, COIN_ZORDER)
            


        end 
    end
    print(#DropHigh)
    for k,v in pairs(DropHigh) do
        print(v.row," ",v.col)
        if v then
            local c = v.row
            local j =1
            while j<=self.rows do
                if self.grid[j][v.col]==nil then
                    local k=j
                    while k<c+1 do
                        self:swap(k,v.col,k+1,v.col)
                        k = k + 1
                        --todo
                    end
                    j = j - 1
                    --todo
                end
                j = j + 1
                --todo
            end
        end
        print(v.row," mm ",v.col)
    end
    if onAnimationComplete == nil then
        for i=1,self.rows do
            for j=1,self.cols do
                local y = i * NODE_PADDING *self.SCALE+ self.offsetY
                local x = j * NODE_PADDING *self.SCALE+ self.offsetX
                if self.grid[i][j] then
                    self.grid[i][j]:setPosition(x,y)
                end
            end
        end
    else
        --
    end
end   
function Board:swap(row1,col1,row2,col2)
    local temp
    if self.grid[row1][col1] then
        self.grid[row1][col1].row = row2
        self.grid[row1][col1].col = col2
    end
    if self.grid[row2][col2] then
        self.grid[row2][col2].row = row1
        self.grid[row2][col2].col = col2
    end
    
    temp = self.grid[row1][col1] 
    self.grid[row1][col1] = self.grid[row2][col2]
    self.grid[row2][col2] = temp
end
function Board:checkLevelCompleted()
    local count = 0
    for _, coin in ipairs(self.coins) do
        if coin.isWhite then count = count + 1 end
    end
    if count == #self.coins then
        self:setTouchEnabled(false)
        self:dispatchEvent({name = "LEVEL_COMPLETED"})
    end
end

function Board:getCoin(row, col)
    if self.grid[row] then
        return self.grid[row][col]
    end
end

function Board:flipCoin(coin, includeNeighbour)
    if not coin or coin == Levels.NODE_IS_EMPTY then return end

    self.flipAnimationCount = self.flipAnimationCount + 1
    coin:flip(function()
        self.flipAnimationCount = self.flipAnimationCount - 1
        self.batch:reorderChild(coin, COIN_ZORDER)
        if self.flipAnimationCount == 0 then
            self:checkLevelCompleted()
        end
    end)
    if includeNeighbour then
        audio.playSound(GAME_SFX.flipCoin)
        self.batch:reorderChild(coin, COIN_ZORDER + 1)
        self:performWithDelay(function()
            self:flipCoin(self:getCoin(coin.row - 1, coin.col))
            self:flipCoin(self:getCoin(coin.row + 1, coin.col))
            self:flipCoin(self:getCoin(coin.row, coin.col - 1))
            self:flipCoin(self:getCoin(coin.row, coin.col + 1))
        end, 0.25)
    end
end

function Board:onTouch(event, x, y)
    if event ~= "began" or self.flipAnimationCount > 0 then return end

    local padding = NODE_PADDING / 2
    for _, coin in ipairs(self.coins) do
        local cx, cy = coin:getPosition()
        cx = cx + display.cx
        cy = cy + display.cy
        if x >= cx - padding
            and x <= cx + padding
            and y >= cy - padding
            and y <= cy + padding then
            --self:flipCoin(coin, true)
            break
        end
    end
end

function Board:onEnter()
    self:setTouchEnabled(true)
end

function Board:onExit()
    self:removeAllEventListeners()
end

return Board
-- function Board:checkAllStar()
--     local listH = {}
--     local listV = {}
--     for i=1 ,self.rows do
--         for j=1,self.cols do

--             if self.grid[i][j+1] and self.grid[i][j].nodeType == self.grid[i][j+1].nodeType then
--                 listH[#listH+1] = self.grid[i][j]   
--             elseif #listH < 2 then   
--                 listH={}--todo
--             else
--                 print("find a 3 coup H cell")
--                 printf("geshu---%d",#listH)
--                 print("hang",i)
--                 listH = {}--todo
--             end
--         end
--     end
--     for k=1,self.cols do
--         for m=1 ,self.rows do
--             if self.grid[m+1] and self.grid[m+1][k] then
--                 if self.grid[m][k].nodeType == self.grid[m+1][k].nodeType  then
--                     listV[#listV+1] = self.grid[m][k]   
--                 elseif #listV < 2 then   
--                     listV={}
--                 else
--                     print("find a 3 coup V cell")
--                     printf("geshu---%d",#listV)
--                     print("lie",k,"hang",m)
--                     listV = {}--todo
--                 end
            
--             end
            
--         end
--     end
-- end    
