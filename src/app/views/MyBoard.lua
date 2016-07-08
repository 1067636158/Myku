local Levels = import("..data.MyLevels")
local Coin   = import("..views.MyCoin")

local Board = class("Board", function()
    return display.newNode()
end)

local NODE_PADDING   = 100
local NODE_ZORDER    = 0
local  curSwapBeginRow = -1
local  curSwapBeginCol = -1
local COIN_ZORDER    = 1000
local isInTouch = false
local isEnableTouch = true
local isOnTouch = true
local scheduler = cc.Director:getInstance():getScheduler()
--isCanSwap = nil

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
        NODE_PADDING2 = math.floor(NODE_PADDING * self.SCALE)
        self.offsetX = -math.floor(NODE_PADDING2 * self.cols / 2 ) - NODE_PADDING2 / 2 
        self.offsetY = -math.floor(NODE_PADDING2 * self.rows / 2 ) - NODE_PADDING2 / 2 
    else
        self.SCALE = 1.0
        NODE_PADDING2 = math.floor(NODE_PADDING * self.SCALE)
        self.offsetX = -math.floor(NODE_PADDING2 * self.cols / 2) - NODE_PADDING2 / 2
        self.offsetY = -math.floor(NODE_PADDING2 * self.rows / 2) - NODE_PADDING2 / 2 
    end   
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
                    coin.isNeedClean = false
                    coin.row = row
                    coin.col = col
                    self.grid[row][col] = coin
                    self.coins[#self.coins + 1] = coin
                    self.batch:addChild(coin, COIN_ZORDER)
                    --printf("%d----%d*****%d", coin.row,coin.col,coin.nodeType)
                end
            end
        end 
    print("lalala")
   
    self:lined()
    self:setNodeEventEnabled(true)
    self:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)
    
    while self:CheckAll() do
        self:changeSingedCell()
    end
end
function Board:lined(  )
    for row = 1, self.rows do
        local y = row * NODE_PADDING* self.SCALE + self.offsetY
        for col = 1, self.cols do
            local x = col * NODE_PADDING* self.SCALE + self.offsetX
            coin = self.grid[row][col]
            coin:setPosition(x, y)
            coin:setScale(self.SCALE)
        end
    end
end
function Board:CheckAll( )
    -- body
    for _ ,v in ipairs(self.coins) do
       -- printf("%d----%d*****%d", coin.row,coin.col,coin.nodeType)
       self:findStars(v)

    end 
   
    return self:checkNotClean()
end

function Board:checkNotClean()
    for _, coin in ipairs(self.coins) do
        if coin.isNeedClean then
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
        for i,v in ipairs(listH) do
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
        for i,v in ipairs(listV) do
            v.isNeedClean = true
        end
        listV = {}
    end
end 
function Board:changeSingedCell(onAnimationComplete)
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
             if onAnimationComplete == nil then
                coin = Coin.new()
            else
                coin = Coin.new()
            end
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
                self.batch:removeChild(self.grid[row][col], true)
                self.grid[row][col] = nil
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
        self:lined()
    else
        for i=1,self.rows do
            for j ,v in pairs(DropHigh) do
                local y = i * NODE_PADDING * self.SCALE + self.offsetY
                local x = v.col * NODE_PADDING * self.SCALE + self.offsetX
                local coin_t = self.grid[i][v.col]
                local x_t,y_t = coin_t:getPosition()
                if coin_t then
                    local x_t,y_t = coin_t:getPosition()
                    if(math.abs(y_t - y) > NODE_PADDING/2 ) then
                        coin_t:runAction(transition.sequence({
                            cc.DelayTime:create(0.2),
                            cc.MoveTo:create(0.9, cc.p(x, y))
                        }))
                    end
                end
                
            end
        end
        print("init2")
        self.handle  = scheduler:scheduleScriptFunc (function () 
            scheduler:unscheduleScriptEntry(self.handle )
            print("init")
            if self:CheckAll() then
                self:changeSingedCell(function() end)
            end
        end, 1.23 , false)--
    end
end   
function Board:swap(row1,col1,row2,col2,callBack,timeScale)
   local swap = function(row1_,col1_,row2_,col2_)
        local temp
        if self:getCoin(row1_,col1_) then
            self.grid[row1_][col1_].row = row2
            self.grid[row1_][col1_].col = col2
        end
        if self:getCoin(row2_,col2_) then
            self.grid[row2_][col2_].row = row1
            self.grid[row2_][col2_].col = col1
        end
        temp = self.grid[row1_][col1_] 
        if self.grid[row2_] and  self.grid[row2_][col2_] then
            self.grid[row1_][col1_] = self.grid[row2_][col2_]
            self.grid[row2_][col2_] = temp
        end
    end
    if callBack == nil then
        swap(row1,col1,row2,col2)
        return
    end

    if self:getCoin(row1,col1) == nil or self:getCoin(row2,col2) == nil then
        print("have one nil value with the swap function!!!!")
        return
    end

    local X1,Y1 = col1 * NODE_PADDING * self.SCALE + self.offsetX , row1  * NODE_PADDING * self.SCALE + self.offsetY
    local X2,Y2 = col2 * NODE_PADDING * self.SCALE + self.offsetX , row2  * NODE_PADDING * self.SCALE + self.offsetY
    local moveTime = 0.6 
    if timeScale then
        moveTime = moveTime * timeScale
    end
    if callBack then
        -- print(isCanSwap)
        -- print("dddd")
        -- if isCanSwap == nil then
            print("dddd")
            self.grid[row2][col2]:setLocalZOrder(COIN_ZORDER + 1)
            self.grid[row1][col1]:runAction(transition.sequence({
                cc.MoveTo:create(moveTime, cc.p(X2,Y2)),
                cc.CallFunc:create(function()
                        --改动锚点的渲染前后顺序，移动完成后回归原本zorder
                    self.grid[row2][col2]:setLocalZOrder(COIN_ZORDER)
                    self:swap(row1,col1,row2,col2)
                    isOnTouch = true
                    callBack()
                    end)
                }))
            self.grid[row2][col2]:runAction(cc.MoveTo:create(moveTime, cc.p(X1,Y1)))
            
            -- isCanSwap =1
            -- print(isCanSwap)
        -- else
        --     isCanSwap = nil 
        --     --todo
        -- end
       
    else
    end
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
function Board:onTouch( event , x, y)
    if not isEnableTouch then
        return
    end
    if event == "began" then
        local row,col = self:getRandC(x, y)
        curSwapBeginRow = row
        curSwapBeginCol = col
        if curSwapBeginRow == -1 or curSwapBeginCol == -1 then
            return false 
        end
        isInTouch = true
        self.grid[curSwapBeginRow][curSwapBeginCol]:setLocalZOrder(COIN_ZORDER+1)
        return true
    end
    if isInTouch and (event == "moved" or event == "ended"  )then
        local padding = NODE_PADDING* self.SCALE / 2
        local coin_center = self.grid[curSwapBeginRow][curSwapBeginCol]
        local cx, cy = coin_center:getPosition()
        cx = cx + display.cx
        cy = cy + display.cy
        local AnchBack =function ( )
            local p_a = coin_center:getAnchorPoint()
            local x_a = (0.5 - p_a.x ) *  NODE_PADDING * self.SCALE + curSwapBeginCol * NODE_PADDING * self.SCALE+ self.offsetX
            local y_a = (0.5 - p_a.y) *  NODE_PADDING * self.SCALE + curSwapBeginRow * NODE_PADDING * self.SCALE+ self.offsetY
            coin_center:setAnchorPoint(cc.p(0.5,0.5))
            coin_center:setPosition(cc.p(x_a  , y_a ))
        end
        local AnimBack =function ()
            isEnableTouch = false
                coin_center:runAction(
                    transition.sequence({
                    cc.MoveTo:create(0.4,cc.p(curSwapBeginCol * NODE_PADDING * self.SCALE
                     + self.offsetX,curSwapBeginRow * NODE_PADDING * self.SCALE + self.offsetY)),
                    cc.CallFunc:create(function()
                          isEnableTouch = true
                    end)
                }))
            coin_center:runAction(cc.ScaleTo:create(0.5,self.SCALE))
            self.grid[curSwapBeginRow][curSwapBeginCol]:setLocalZOrder(COIN_ZORDER)
        end
        if event == "ended" then
            AnchBack()
            AnimBack()
            return 
        end

        if x < cx - 2*padding
            or x > cx + 2*padding
            or y < cy - 2*padding
            or y > cy + 2*padding then
            isInTouch = false

            --划归锚点偏移
            AnchBack()
            local row,col = self:getRandC(x, y)
            --进入十字框以内
            if ((x >= cx - padding
            and x <= cx + padding)
            or (y >= cy - padding
            and y <= cy + padding) )and (row ~= -1 and col ~= -1)  then
                --防止移动超过一格的情况
                if row - curSwapBeginRow > 1 then row = curSwapBeginRow + 1 end
                if curSwapBeginRow - row > 1 then row = curSwapBeginRow - 1 end
                if col -  curSwapBeginCol > 1 then col = curSwapBeginCol + 1 end
                if curSwapBeginCol - col  > 1 then col = curSwapBeginCol - 1 end
                    self:swap(row,col,curSwapBeginRow,curSwapBeginCol,function()
                        self:findStars(self.grid[row][col])
                        self:findStars(self.grid[curSwapBeginRow][curSwapBeginCol])
                        if self:checkNotClean() then
                            self:changeSingedCell(function() end)
                        else
                            self:swap(curSwapBeginRow,curSwapBeginCol,row,col,function()
                                
                                end,0.6)
                        end
                    end)
            else
                AnimBack()
                return
            end
            
        else
            x_vec = (cx - x)/ NODE_PADDING* self.SCALE * 0.3 + 0.5
            y_vec = (cy - y)/ NODE_PADDING* self.SCALE * 0.3 + 0.5
            coin_center:setAnchorPoint(cc.p(x_vec,y_vec))
        end
    end
    return true
end
-- function Board:onTouch(event, x, y)
--     if event == "began" then
--         local row,col = self:getRandC(x, y)
--         curSwapBeginRow = row
--         curSwapBeginCol = col
--         print(row," 11",col)
        
--     end
--     if isOnTouch and event == "ended" then
--         local padding = NODE_PADDING *self.SCALE 
--         local coin_center = self.grid[curSwapBeginRow][curSwapBeginCol]
--         local cx, cy = coin_center:getPosition()
--         print(x," 33",y)
--         cx = cx + display.cx
--         cy = cy + display.cy
--         print(cx," 44",cy)
--         isOnTouch = false
--         if (math.abs(x-cx)>=math.abs(y-cy))then
--             if (x-cx)>=20 then
--                 local row,col = self:getRandC(cx+padding, cy)
--                 print(row," 51",col)
--                 if row ==-1 then
--                     row,col=curSwapBeginRow, curSwapBeginCol
--                 end

--                 self:swap(curSwapBeginRow, curSwapBeginCol, row, col, function()
--                 end)

--             elseif (x-cx)<=-20 then
                
--                 local row,col = self:getRandC(cx-padding, cy)
--                 print(row," 52",col)
--                 if row ==-1 then
--                     row,col=curSwapBeginRow, curSwapBeginCol
--                 end
--                 self:swap(curSwapBeginRow, curSwapBeginCol, row, col, function()
--                 end)
            
            
--             end 
--         else
--             if (y-cy)>=20 then
--                 local row,col = self:getRandC(cx, cy+padding)
--                 print(row," 53",col)
--                 if row ==-1 then
--                     row,col=curSwapBeginRow, curSwapBeginCol
--                 end
--                 self:swap(curSwapBeginRow, curSwapBeginCol, row, col, function()
--                 end)
--             elseif (y-cy)<=20 then
                
--                 local row,col = self:getRandC(cx, cy-padding)
--                 print(row," 54",col)
--                 if row ==-1 then
--                     row,col=curSwapBeginRow, curSwapBeginCol
--                 end
--                 self:swap(curSwapBeginRow, curSwapBeginCol, row, col, function()
--                 end)
            
--             end
--         end
--     end
--     return true
-- end
-- function Board:onTouch(event, x, y)
--     if event == "began" then
--         local row,col = self:getRandC(x, y)
--         print(row,col)
--         if curSwapBeginRow>0 or curSwapBeginCol>0 then
--             self:swap(curSwapBeginRow, curSwapBeginCol, row, col, function()
--         end)--todo
--         end
--     elseif event == "ended" then
--         local row,col = self:getRandC(x, y)
--         print(row,col)
--         curSwapBeginRow = row
--         curSwapBeginCol = col
        
--     end
--     return true
-- end
function Board:getRandC(x,y)
    local padding = (NODE_PADDING * self.SCALE) / 2
    for _, coin in ipairs(self.coins) do
        local cx, cy = coin:getPosition()
        cx = cx + display.cx
        cy = cy + display.cy
        if x >= cx - padding
            and x <= cx + padding
            and y >= cy - padding
            and y <= cy + padding then
            return coin.row , coin.col
        end
    end
    return -1 , -1
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
