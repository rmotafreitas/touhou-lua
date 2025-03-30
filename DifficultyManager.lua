-- DifficultyManager.lua - Handles game difficulty scaling based on score

DifficultyManager = {
    currentLevel = 1,
    maxLevel = 10,
    
    -- Score thresholds for difficulty increases
    LEVEL_THRESHOLDS = {
        500,    -- Level 2
        1000,   -- Level 3
        2000,   -- Level 4
        3500,   -- Level 5
        5500,   -- Level 6
        8000,   -- Level 7
        12000,  -- Level 8
        16000,  -- Level 9
        20000   -- Level 10
    },
    
    -- Game parameters that change with difficulty
    PARAMETERS = {
        -- Level 1 (default/starting values)
        [1] = {
            enemySpawnDelay = 3.0,
            enemyHealth = 3,
            enemyBulletSpeed = 150,
            enemySpeed = 50,
            bulletCount = {  -- Number of bullets in patterns
                circle = 8,
                spiral = 3,
                aimed = 3
            }
        },
        -- Higher levels increase difficulty
        [2] = { enemySpawnDelay = 2.7, enemyHealth = 3, enemyBulletSpeed = 160, enemySpeed = 55 },
        [3] = { enemySpawnDelay = 2.4, enemyHealth = 4, enemyBulletSpeed = 170, enemySpeed = 60 },
        [4] = { enemySpawnDelay = 2.1, enemyHealth = 4, enemyBulletSpeed = 180, enemySpeed = 65, bulletCount = { circle = 10 } },
        [5] = { enemySpawnDelay = 1.8, enemyHealth = 5, enemyBulletSpeed = 190, enemySpeed = 70 },
        [6] = { enemySpawnDelay = 1.5, enemyHealth = 5, enemyBulletSpeed = 200, enemySpeed = 75, bulletCount = { spiral = 4, aimed = 4 } },
        [7] = { enemySpawnDelay = 1.2, enemyHealth = 6, enemyBulletSpeed = 210, enemySpeed = 80 },
        [8] = { enemySpawnDelay = 1.0, enemyHealth = 6, enemyBulletSpeed = 220, enemySpeed = 85, bulletCount = { circle = 12 } },
        [9] = { enemySpawnDelay = 0.8, enemyHealth = 7, enemyBulletSpeed = 230, enemySpeed = 90, bulletCount = { spiral = 5, aimed = 5 } },
        [10] = { enemySpawnDelay = 0.7, enemyHealth = 8, enemyBulletSpeed = 240, enemySpeed = 95, bulletCount = { circle = 16, spiral = 6, aimed = 6 } }
    }
}

-- Initialize difficulty manager
function DifficultyManager.init()
    DifficultyManager.currentLevel = 1
end

-- Update difficulty based on score
function DifficultyManager.updateDifficulty(score)
    local prevLevel = DifficultyManager.currentLevel
    
    -- Check if we should increase level
    for i = DifficultyManager.currentLevel, DifficultyManager.maxLevel - 1 do
        if score >= DifficultyManager.LEVEL_THRESHOLDS[i] then
            DifficultyManager.currentLevel = i + 1
        else
            break
        end
    end
    
    -- Return true if level increased
    return DifficultyManager.currentLevel > prevLevel
end

-- Get a specific parameter for current difficulty level
function DifficultyManager.getParameter(paramName, patternType)
    local levelParams = DifficultyManager.PARAMETERS[DifficultyManager.currentLevel]
    
    -- Handle nested parameters (like bulletCount)
    if patternType and paramName == "bulletCount" then
        -- Check if this level has a specific override for this pattern
        if levelParams.bulletCount and levelParams.bulletCount[patternType] then
            return levelParams.bulletCount[patternType]
        end
        
        -- Search backward for the most recent level that defines this parameter
        for level = DifficultyManager.currentLevel - 1, 1, -1 do
            local params = DifficultyManager.PARAMETERS[level]
            if params.bulletCount and params.bulletCount[patternType] then
                return params.bulletCount[patternType]
            end
        end
    end
    
    -- For regular parameters, check if current level has it
    if levelParams[paramName] then
        return levelParams[paramName]
    end
    
    -- If not found in current level, search backward for the most recent definition
    for level = DifficultyManager.currentLevel - 1, 1, -1 do
        local params = DifficultyManager.PARAMETERS[level]
        if params[paramName] then
            return params[paramName]
        end
    end
    
    return nil  -- Parameter not found (should never happen with proper setup)
end

-- Get current difficulty level (1-10)
function DifficultyManager.getLevel()
    return DifficultyManager.currentLevel
end

-- Get level name for display
function DifficultyManager.getLevelName()
    local names = {
        "Novice",
        "Easy",
        "Normal",
        "Challenging",
        "Hard",
        "Very Hard",
        "Expert",
        "Master",
        "Nightmare",
        "Lunatic"
    }
    return names[DifficultyManager.currentLevel]
end

return DifficultyManager