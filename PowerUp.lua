PowerUp = {}
PowerUp.__index = PowerUp

-- Define power-up types
PowerUp.TYPES = {
    TRIPLE_SHOT = 1,
    SCORE_MULTIPLIER = 2,
    RAPID_FIRE = 3,
    SHIELD = 4,
    LIVE_GIVER = 5,
}

-- Power-up properties
PowerUp.PROPERTIES = {
    [PowerUp.TYPES.TRIPLE_SHOT] = {
        name = "Triple Shot",
        color = {0.2, 1, 0.2},  -- Green
        description = "Fire in three directions!",
        duration = 60  -- 60 seconds
    },
    [PowerUp.TYPES.SCORE_MULTIPLIER] = {
        name = "2x Score",
        color = {1, 0.8, 0},  -- Gold
        description = "Double points for everything!",
        duration = 30  -- 30 seconds
    },
    [PowerUp.TYPES.RAPID_FIRE] = {
        name = "Rapid Fire",
        color = {0, 0.8, 1},  -- Cyan
        description = "Shoot twice as fast!",
        duration = 45  -- 45 seconds
    },
    [PowerUp.TYPES.SHIELD] = {
        name = "Shield",
        color = {0.7, 0.3, 1},  -- Purple
        description = "Blocks enemy bullets!",
        duration = 20  -- 20 seconds
    },
    [PowerUp.TYPES.LIVE_GIVER] = {
        name = "Extra Life",
        color = {1, 0.2, 0.2},  -- Red
        description = "Gain an extra life!",
        duration = 0  -- Instant effect
    }
}

-- Score thresholds for spawning power-ups (Fibonacci-like)
PowerUp.SCORE_THRESHOLDS = {100, 200, 500, 800, 1300, 2100, 3400, 5500}

function PowerUp:new(x, y, type)
    local self = setmetatable({}, PowerUp)
    self.x = x
    self.y = y
    self.type = type or PowerUp:getRandomType()
    self.width = 30
    self.height = 30
    self.color = PowerUp.PROPERTIES[self.type].color
    self.active = true
    return self
end

function PowerUp:update(dt)
    -- Power-ups float downward slowly
    self.y = self.y + 50 * dt
    
    -- Remove if off screen
    if self.y > love.graphics.getHeight() then
        self.active = false
    end
end

function PowerUp:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw inner rectangle for visual interest
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", self.x + 5, self.y + 5, self.width - 10, self.height - 10)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function PowerUp:getRandomType()
    local types = {}
    for type, _ in pairs(PowerUp.PROPERTIES) do
        table.insert(types, type)
    end
    return types[love.math.random(1, #types)]
end

function PowerUp:apply(player)
    local properties = PowerUp.PROPERTIES[self.type]
    local duration = properties.duration
    
    -- Each power-up has its own effect
    if self.type == PowerUp.TYPES.TRIPLE_SHOT then
        player:addPowerUp("tripleShot", duration)
    elseif self.type == PowerUp.TYPES.SCORE_MULTIPLIER then
        player:addPowerUp("scoreMultiplier", duration, 2)  -- 2x multiplier
    elseif self.type == PowerUp.TYPES.RAPID_FIRE then
        player:addPowerUp("rapidFire", duration)
    elseif self.type == PowerUp.TYPES.SHIELD then
        player:addPowerUp("shield", duration)
    elseif self.type == PowerUp.TYPES.LIVE_GIVER then
        player:addLife(1)  -- Give an extra life
    end
    
    return properties.name, properties.description
end

return PowerUp