-- SpecialSkill.lua - Defines special screen-clearing abilities

SpecialSkill = {}
SpecialSkill.__index = SpecialSkill

-- Define skill types
SpecialSkill.TYPES = {
    STAR_SHOWER = 1,
    TIME_STOP = 2, 
    SPIRIT_BOMB = 3
}

-- Skill properties
SpecialSkill.PROPERTIES = {
    [SpecialSkill.TYPES.STAR_SHOWER] = {
        name = "Star Shower",
        description = "Rain of stars damages all enemies",
        color = {1, 0.8, 0.2},  -- Gold
        duration = 3,
        particles = 100,
        damage = 5
    },
    [SpecialSkill.TYPES.TIME_STOP] = {
        name = "Time Stop",
        description = "Freezes all enemies and bullets",
        color = {0.3, 0.8, 1},  -- Light blue
        duration = 5,
        particles = 50,
        damage = 0
    },
    [SpecialSkill.TYPES.SPIRIT_BOMB] = {
        name = "Spirit Bomb",
        description = "Massive explosion clears the screen",
        color = {1, 0.4, 0.8},  -- Pink
        duration = 2,
        particles = 150,
        damage = 10
    }
}

-- Collectable skill card that appears in game
function SpecialSkill:new(x, y, type)
    local self = setmetatable({}, SpecialSkill)
    self.x = x
    self.y = y
    self.type = type or self:getRandomType()
    self.width = 30
    self.height = 40  -- Taller than power-ups to look like a card
    self.color = SpecialSkill.PROPERTIES[self.type].color
    self.active = true
    self.floatTimer = 0
    return self
end

function SpecialSkill:update(dt)
    -- Float down with a slight wobble
    self.y = self.y + 40 * dt
    self.floatTimer = self.floatTimer + dt * 4
    self.x = self.x + math.sin(self.floatTimer) * 0.5
    
    -- Remove if off screen
    if self.y > love.graphics.getHeight() then
        self.active = false
    end
end

function SpecialSkill:draw()
    -- Draw card background
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw colored border
    love.graphics.setColor(self.color)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- Draw inner pattern (simple star shape)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.8)
    
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2
    local radius = self.width * 0.3
    
    -- Draw a symbol based on skill type
    if self.type == SpecialSkill.TYPES.STAR_SHOWER then
        self:drawStar(centerX, centerY, radius)
    elseif self.type == SpecialSkill.TYPES.TIME_STOP then
        self:drawClock(centerX, centerY, radius)
    elseif self.type == SpecialSkill.TYPES.SPIRIT_BOMB then
        self:drawSpiral(centerX, centerY, radius)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw a star symbol
function SpecialSkill:drawStar(x, y, radius)
    local points = {}
    for i = 1, 5 do
        local angle = (i * 2 * math.pi / 5) - math.pi/2
        table.insert(points, x + radius * math.cos(angle))
        table.insert(points, y + radius * math.sin(angle))
        
        local innerAngle = ((i + 0.5) * 2 * math.pi / 5) - math.pi/2
        table.insert(points, x + radius * 0.4 * math.cos(innerAngle))
        table.insert(points, y + radius * 0.4 * math.sin(innerAngle))
    end
    love.graphics.polygon("fill", points)
end

-- Draw a clock symbol
function SpecialSkill:drawClock(x, y, radius)
    love.graphics.circle("line", x, y, radius)
    -- Draw hour hand
    love.graphics.line(x, y, x + radius * 0.5 * math.cos(-math.pi/3), y + radius * 0.5 * math.sin(-math.pi/3))
    -- Draw minute hand
    love.graphics.line(x, y, x + radius * 0.7 * math.cos(math.pi/6), y + radius * 0.7 * math.sin(math.pi/6))
end

-- Draw a spiral symbol
function SpecialSkill:drawSpiral(x, y, radius)
    local points = {}
    local spirals = 2
    local steps = 20
    
    for i = 0, steps do
        local t = i / steps
        local angle = t * math.pi * 2 * spirals
        local r = t * radius
        table.insert(points, x + r * math.cos(angle))
        table.insert(points, y + r * math.sin(angle))
    end
    
    love.graphics.line(points)
    love.graphics.circle("fill", x, y, radius * 0.2)
end

function SpecialSkill:getRandomType()
    local types = {}
    for type, _ in pairs(SpecialSkill.PROPERTIES) do
        table.insert(types, type)
    end
    return types[love.math.random(1, #types)]
end

-- Create particles effect for the skill
function SpecialSkill.createParticles(type, x, y, width, height)
    local properties = SpecialSkill.PROPERTIES[type]
    local particles = {}
    
    for i = 1, properties.particles do
        local particle = {
            x = x + love.math.random() * width,
            y = y + love.math.random() * height,
            vx = (love.math.random() - 0.5) * 200,
            vy = (love.math.random() - 0.5) * 200,
            radius = love.math.random(2, 6),
            color = {
                properties.color[1],
                properties.color[2],
                properties.color[3],
                love.math.random(0.5, 1)
            },
            lifetime = love.math.random(0.5, properties.duration),
            maxLifetime = love.math.random(0.5, properties.duration)
        }
        table.insert(particles, particle)
    end
    
    return particles
end

-- Update particles for animation
function SpecialSkill.updateParticles(particles, dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.lifetime = p.lifetime - dt
        
        -- Fade out as lifetime decreases
        p.color[4] = p.lifetime / p.maxLifetime
        
        if p.lifetime <= 0 then
            table.remove(particles, i)
        end
    end
    
    return #particles > 0  -- Return true if particles remain
end

-- Draw particles
function SpecialSkill.drawParticles(particles)
    for _, p in ipairs(particles) do
        love.graphics.setColor(p.color)
        love.graphics.circle("fill", p.x, p.y, p.radius)
    end
    love.graphics.setColor(1, 1, 1)
end

return SpecialSkill