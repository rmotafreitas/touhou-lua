-- ScoreManager.lua - Handles saving, loading, and managing high scores

-- Simple JSON encoder/decoder for Lua
local json = {}

-- Encode table to JSON string
function json.encode(data)
    local result = ""
    
    if type(data) == "table" then
        result = "{"
        local first = true
        for k, v in pairs(data) do
            if not first then result = result .. "," end
            result = result .. '"' .. tostring(k) .. '":'
            if type(v) == "string" then
                result = result .. '"' .. v .. '"'
            elseif type(v) == "number" or type(v) == "boolean" then
                result = result .. tostring(v)
            elseif type(v) == "table" then
                result = result .. json.encode(v)
            end
            first = false
        end
        result = result .. "}"
    elseif type(data) == "number" or type(data) == "boolean" then
        result = tostring(data)
    elseif type(data) == "string" then
        result = '"' .. data .. '"'
    end
    
    return result
end

-- Decode JSON string to table (improved version)
function json.decode(str)
    -- Try to clean up the JSON string
    str = string.gsub(str, "^%s*(.-)%s*$", "%1") -- Trim whitespace
    
    print("Attempting to decode: " .. str)
    
    -- For basic JSON (our specific use case), we can use pattern matching
    if string.match(str, "^{\"highScore\":([0-9]+)}$") then
        local score = tonumber(string.match(str, "^{\"highScore\":([0-9]+)}$"))
        print("Extracted high score: " .. tostring(score))
        return {highScore = score}
    end
    
    -- If direct pattern fails, try the more complex approach
    str = str:gsub('"([^"]+)"%s*:', "[%1]=")
    str = "return " .. str
    
    local func, err = load(str, "json", "t", {})
    if not func then 
        print("JSON decode error: " .. tostring(err))
        return {} 
    end
    
    local success, result = pcall(func)
    if not success then 
        print("JSON execution error: " .. tostring(result))
        return {} 
    end
    
    return result
end

-- The ScoreManager module
ScoreManager = {
    highScore = 0,
    saveFile = "highscores.json"
}

-- Initialize ScoreManager
function ScoreManager.init()
    -- Load existing scores
    ScoreManager.loadScores()
end

-- Load scores from file
function ScoreManager.loadScores()
    local saveDir = love.filesystem.getSaveDirectory()
    print("Loading scores from: " .. saveDir .. "/" .. ScoreManager.saveFile)
    
    if love.filesystem.getInfo(ScoreManager.saveFile) then
        local contents, size = love.filesystem.read(ScoreManager.saveFile)
        print("File contents: [" .. tostring(contents) .. "], size: " .. tostring(size))
        
        if contents and size > 0 then
            -- Ensure contents is valid JSON
            if string.match(contents, "^%s*{.*}%s*$") then
                local data = json.decode(contents)
                if data and type(data.highScore) == "number" then
                    ScoreManager.highScore = data.highScore
                    print("Successfully loaded high score: " .. ScoreManager.highScore)
                else
                    print("Failed to parse high score data")
                end
            else
                print("File does not contain valid JSON object")
            end
        else
            print("Empty file")
        end
    else
        print("Creating new high score file")
        ScoreManager.saveScores()
    end
end

-- Save scores to file
function ScoreManager.saveScores()
    local data = {
        highScore = ScoreManager.highScore
    }
    
    local jsonStr = json.encode(data)
    print("Writing to file: " .. jsonStr)
    
    local success, message = love.filesystem.write(ScoreManager.saveFile, jsonStr)
    if success then
        print("Scores saved successfully")
        
        -- Verify the file was written correctly
        if love.filesystem.getInfo(ScoreManager.saveFile) then
            local contents = love.filesystem.read(ScoreManager.saveFile)
            print("Verification - file contains: " .. tostring(contents))
        else
            print("Warning: File doesn't exist after saving")
        end
    else
        print("Failed to save scores: " .. tostring(message))
    end
end

-- Update high score if current score is higher
function ScoreManager.updateHighScore(currentScore)
    currentScore = math.floor(currentScore)
    if currentScore > ScoreManager.highScore then
        ScoreManager.highScore = currentScore
        ScoreManager.saveScores()
        return true  -- Indicates a new high score was achieved
    end
    return false
end

-- Helper function to manually set high score (for testing)
function ScoreManager.setHighScore(value)
    ScoreManager.highScore = value
    ScoreManager.saveScores()
    print("High score manually set to: " .. value)
end

return ScoreManager