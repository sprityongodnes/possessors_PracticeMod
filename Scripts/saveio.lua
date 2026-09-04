--- Save data in pure lua data instead of relying on objects
--- owned by the engine.
--- The below fields were deemed irrelevant and skipped:
--- LastSaveTime
--- TotalPlaytimeSeconds
--- GameplayDifficulty (just change it in the menu idc)
---@class LuaSaveData
---@field currentCheckpointName string
---@field currentCheckpointRegionTag string
---@field bHudVisible boolean -- genuinely no clue what this does so I'm not touching it.
---@field perObjectSaveData table<string, LuaPoseObjectData>
LuaSaveData = {}

--- FPoseObjectData mirror class.
---@class LuaPoseObjectData
---@field FlagSet string[]
---@field BoolMap table<string, boolean>
---@field IntMap table<string, integer>
---@field FloatMap table<string, number>
---@field VectorMap table<string, FVector>
LuaPoseObjectData = {}

--- All information needed for a savestate.
---@class SaveState
---@field luaSaveData LuaSaveData
---@field pos FVector
---@field rot FRotator
---@field health number
---@field ammo number
---@field heals number
SaveState = {}

--- Converts an FSaveSlotData to LuaSaveData.
---@param saveData FSaveSlotData
---@return LuaSaveData
function SaveDataToLuaTable(saveData)
    print("Saving current save data as a lua table!")
    local perObjData = {}

    -- Per object save data handling
    saveData.PerObjectSaveData:ForEach(function(key, value)
        ---@type FName
        local fname = key:get()
        ---@type FPoseObjectData
        local objData = value:get()
        ---@type LuaPoseObjectData
        local luaObjData = {
            FlagSet = {},
            BoolMap = {},
            IntMap = {},
            FloatMap = {},
            VectorMap = {},
        }
        local i = 0
        objData.FlagSet:ForEach(function(name)
            if not name then return true end
            ---@type FName
            local flagFName = name:get()
            luaObjData.FlagSet[i] = flagFName:ToString()
            i = i + 1
        end)
        objData.BoolMap:ForEach(function(key, value)
            if not key then return true end
            ---@type FName
            local boolFName = key:get()
            ---@type boolean
            local bool = value:get()
            luaObjData.BoolMap[boolFName:ToString()] = bool
        end)
        objData.IntMap:ForEach(function(key, value)
            if not key then return true end
            ---@type FName
            local intFName = key:get()
            ---@type integer
            local int = value:get()
            luaObjData.IntMap[intFName:ToString()] = int
        end)
        objData.FloatMap:ForEach(function(key, value)
            if not key then return true end
            ---@type FName
            local floatFName = key:get()
            ---@type number
            local float = value:get()
            luaObjData.FloatMap[floatFName:ToString()] = float
        end)
        objData.VectorMap:ForEach(function(key, value)
            if not key then return true end
            ---@type FName
            local vectorFName = key:get()
            ---@type FVector
            local vector = value:get()
            luaObjData.VectorMap[vectorFName:ToString()] = vector
        end)

        perObjData[fname:ToString()] = luaObjData
        print("Saving object data: " .. fname:ToString())
    end)


    return {
        currentCheckpointName = saveData.CurrentCheckpointID:ToString(),
        currentCheckpointRegionTag = saveData.CurrentCheckpointRegionTag.TagName:ToString(),
        bHudVisible = saveData.bHUDVisible,
        perObjectSaveData = perObjData,
    }
end

--- Loads data from lua save data into an in-engine
--- save data object.
--- As I can't figure out how to construct certain objects without causing a crash,
--- this can only remove certain things from save data, not add them.
---@param luaData LuaSaveData
---@param saveData FSaveSlotData
function LoadLuaData(luaData, saveData)
    -- saveData.CurrentCheckpointID = FName(luaData.currentCheckpointName)
    -- saveData.CurrentCheckpointRegionTag.TagName = FName(luaData.currentCheckpointRegionTag)

    -- Object data
    -- saveData.PerObjectSaveData:Empty()

    -- avoids a concurrent modification issue, didn't test if this was necessary but just to be safe
    local toRemove = {}
    local i = 1 -- lua arrays start at 1???
    saveData.PerObjectSaveData:ForEach(function(k, v)
        local name = k:get()
        print('checking ' .. name:ToString())
        if not luaData.perObjectSaveData[name:ToString()] then
            toRemove[i] = name
            i = i + 1
            print('appending to toRemove')
        end
    end)

    -- print(table.concat(toRemove, ", "))
    for i, v in ipairs(toRemove) do
        print('removing')
        saveData.PerObjectSaveData:Remove(v)
    end
    -- for k, v in pairs(luaData.perObjectSaveData) do
    --     print('creating new obj data')
    -- ---@type FPoseObjectData
    -- local objData = Construct("/Script/Pose.PoseObjectData", saveData, "saveState_objData_" .. k)
    -- for name, bool in pairs(v.BoolMap) do
    --     objData.BoolMap:Add(FName(name), bool)
    -- end
    -- for name, int in pairs(v.IntMap) do
    --     objData.IntMap:Add(FName(name), int)
    -- end
    -- for name, float in pairs(v.FloatMap) do
    --     objData.FloatMap:Add(FName(name), float)
    -- end
    -- for name, vec in pairs(v.VectorMap) do
    --     objData.VectorMap:Add(FName(name), vec)
    -- end
    -- for i = 1, #v.FlagSet, 1 do
    --     objData.FlagSet:Add(FName(v.FlagSet[i]))
    -- end
    -- saveData.PerObjectSaveData:Add(FName(k), v) -- ue4ss should convert this table automatically
    -- end

    return saveData
end
