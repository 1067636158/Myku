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

    self.grid = clone(levelData.grid)
    self.rows = levelData.rows
    self.cols = levelData.cols
    self.coins = {}
    self.flipAnimationCount = 0
    math.randomseed( tostring(os.time()):reverse():sub(1,6) )
    -- create board, place all coins
    if self.cols >= 8 then
        local SCALE = ( 640 / self.cols ) / 100
        local NODE_PADDING2 = math.floor(NODE_PADDING * SCALE)
        local offsetX = -math.floor(NODE_PADDING2 * self.cols / 2 ) - NODE_PADDING2 / 2 
        local offsetY = -math.floor(NODE_PADDING2 * self.rows / 2 ) - NODE_PADDING2 / 2 
        for row = 1, self.rows do
            local y = row * NODE_PADDING2 + offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING2 + offsetX
                local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                nodeSprite:setScale(SCALE)
                self.batch:addChild(nodeSprite, NODE_ZORDER)

                local node = self.grid[row][col]
                if node ~= Levels.NODE_IS_EMPTY then
                    local coin = Coin.new(node)
                    coin:setPosition(x, y)
                    coin:setScale(SCALE)
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
        local offsetX = -math.floor(NODE_PADDING * self.cols / 2) - NODE_PADDING / 2
        local offsetY = -math.floor(NODE_PADDING * self.rows / 2) - NODE_PADDING / 2
        for row = 1, self.rows do
            local y = row * NODE_PADDING + offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING + offsetX
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
    for _ ,v in ipairs(self.coins) do
       -- printf("%d----%d*****%d", coin.row,coin.col,coin.nodeType)
       self:findStars(v)

    end
    
    self:setNodeEventEnabled(true)
    self:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)
    self:changeSingedCell()
    -- self:checkAll()
end
 
function Board:checkAll()
    local listH = {}
    local listV = {}
    for i=1 ,self.rows do
        for j=1,self.cols do

            if self.grid[i][j+1] and self.grid[i][j].nodeType == self.grid[i][j+1].nodeType then
                listH[#listH+1] = self.grid[i][j]   
            elseif #listH < 2 then   
                listH={}--todo
            else
                print("find a 3 coup H cell")
                printf("geshu---%d",#listH)
                print("hang",i)
                listH = {}--todo
            end
        end
    end
    for k=1,self.cols do
        for m=1 ,self.rows do
            if self.grid[m+1] and self.grid[m+1][k] then
                if self.grid[m][k].nodeType == self.grid[m+1][k].nodeType  then
                    listV[#listV+1] = self.grid[m][k]   
                elseif #listV < 2 then   
                    listV={}
                else
                    print("find a 3 coup V cell")
                    printf("geshu---%d",#listV)
                    print("lie",k,"hang",m)
                    listV = {}--todo
                end
            
            end
            
        end
    end
end    

function Board:checkLevelCompleted()
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
        local coin_left = self.grid[coin.row][i]
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
            local coin_right = self.grid[coin.row][j]
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
        local coin_down = self.grid[k][coin.col]
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
            local coin_up = self.grid[o][coin.col]
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
    for _ ,v in ipairs(self.coins) do
        if v.isNeedClean then
            sum = sum +1
            print("aaaaaaaa")
        end
    end
end   
function Board:checkLevelCompleted()
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
