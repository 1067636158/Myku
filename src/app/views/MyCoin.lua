
local Levels = import("..data.MyLevels")
local scheduler = cc.Director:getInstance():getScheduler()
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

local Coin = class("Coin", function(animationTime,sCale,nodeType)
	
    local index =math.random(#starsBox) 
    
    local sprite = display.newSprite(string.format(starsBox[index]))
    sprite.nodeType=index
    if animationTime ~= nil and animationTime > 0 then
        sprite:setOpacity(0)
        sprite:setScale(0.1)
        --sprite:runAction(cc.ScaleTo:create(animationTime,sCale))
        sprite:runAction(cc.FadeTo:create(animationTime, 225))
        sprite:runAction(cc.RotateBy:create(animationTime, -(360*3)))
        print(11111)
    end
    sprite.handel = scheduler:scheduleScriptFunc (function () 
        if sprite.arrows then
            if sprite.arrows.curN == 1 then
                sprite.arrows.curN = 14
            else
                sprite.arrows.curN = sprite.arrows.curN - 1
            end
            if sprite.arrows[sprite.arrows.curN] then
                sprite.arrows[sprite.arrows.curN]:setOpacity(225)
                sprite.arrows[sprite.arrows.curN]:runAction(cc.FadeOut:create(0.45))
                 print(22222)
            end
        end
    end , 0.1 , false)      
    return sprite
end)
function Coin:Explod(CELL_STAND_SCALE,cutOrder)

    local function delays(onComlete)
        self:runAction(transition.sequence({
                        cc.DelayTime:create((cutOrder - 1)* 0.05 ),
                        cc.CallFunc:create(function()
                              onComlete()
                        end)
                    }))
    end

    local function zoom1(offset, time, onComplete)
        local x, y = self:getPosition()
        local size = self:getContentSize()
        size.width = 200
        size.height = 200

        local scaleX = self:getScaleX() * (size.width + offset) / size.width
        local scaleY = self:getScaleY() * (size.height - offset) / size.height

        transition.moveTo(self, {y = y + offset, time = time})
        transition.scaleTo(self, {
            scaleX     = scaleX,
            scaleY     = scaleY,
            time       = time,
            onComplete = onComplete,
        })
    end

    local function zoom2(offset, time, onComplete)
        local x, y = self:getPosition()
        local size = self:getContentSize()
        size.width = 200
        size.height = 200

        transition.moveTo(self, {y = y - offset, time = time / 2})
        transition.scaleTo(self, {
            scaleX     = CELL_STAND_SCALE,
            scaleY     = CELL_STAND_SCALE,
            time       = time,
            onComplete = onComplete,
        })
    end

    delays(function()
        zoom1(40, 0.08, function()
            zoom2(40, 0.09, function()
                zoom1(20, 0.10, function()
                    zoom2(20, 0.11, function()
                        local particle = cc.ParticleSystemQuad:create("exp.plist")
                        self:getParent():addChild(particle,1002) -- 加到显示对象上就开始播放了
                        particle:setPosition(self:getPositionX(),self:getPositionY())
                        self:runAction(
                            transition.sequence({
                            cc.ScaleTo:create(0.30,0.1),
                            cc.CallFunc:create(function()
                                  self:removeSelf()
                                   print(333333)
                            end)
                        }))
                        self:runAction(cc.FadeTo:create(0.30, 0.2))
                        self:runAction(cc.RotateBy:create(0.30, 800))
                    end)
                end)
            end)
        end)
    end)
end

--0.58 sumtime


function Coin:onExit()
    scheduler:unscheduleScriptEntry(self.handel)
end




return Coin
