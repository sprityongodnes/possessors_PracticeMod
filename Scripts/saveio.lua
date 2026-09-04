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
---@field luaPlayerSaveData LuaPlayerSaveData
LuaSaveData = {}

--- FPoseObjectData mirror class.
---@class LuaPoseObjectData
---@field FlagSet string[]
---@field BoolMap table<string, boolean>
---@field IntMap table<string, integer>
---@field FloatMap table<string, number>
---@field VectorMap table<string, FVector>
LuaPoseObjectData = {}

--- FPlayerSaveData mirror class.
---@class LuaPlayerSaveData
---@field UnlockedAbilityFlags integer
---@field Chroma integer
---@field ItemAmounts table<string, integer>
---@field PlayerWeaponDatas table<string, table<integer, string>>
---@field DeathLocation FVector
---@field MapTrackedDeathLocation FVector
---@field CorpseChroma integer
---@field LoadoutPrimaryWeapon string
---@field LoadoutSecondaryWeapons table<integer, string>>
LuaPlayerSaveData = {}

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
        local i = 1
        objData.FlagSet:ForEach(function(name)
            if not name then return true end
            ---@type FName
            local flagFName = name:get()
            luaObjData.FlagSet[i] = flagFName:ToString()
            i = i + 1
        end)
        objData.BoolMap:ForEach(function(k, v)
            if not k then return true end
            ---@type FName
            local boolFName = k:get()
            ---@type boolean
            local bool = v:get()
            luaObjData.BoolMap[boolFName:ToString()] = bool
        end)
        objData.IntMap:ForEach(function(k, v)
            if not k then return true end
            ---@type FName
            local intFName = k:get()
            ---@type integer
            local int = v:get()
            luaObjData.IntMap[intFName:ToString()] = int
        end)
        objData.FloatMap:ForEach(function(k, v)
            if not k then return true end
            ---@type FName
            local floatFName = k:get()
            ---@type number
            local float = v:get()
            luaObjData.FloatMap[floatFName:ToString()] = float
        end)
        objData.VectorMap:ForEach(function(k, v)
            if not k then return true end
            ---@type FName
            local vectorFName = k:get()
            ---@type FVector
            local vector = v:get()
            luaObjData.VectorMap[vectorFName:ToString()] = vector
        end)

        perObjData[fname:ToString()] = luaObjData
    end)

    -- Player save data item amounts
    local playerSaveItemAmounts = {}
    saveData.PlayerSaveData.ItemAmounts:ForEach(function(key, value)
        if not key then return end
        ---@type UItemDataAsset
        local itemData = key:get()
        if not IsValid(itemData) then return end
        local count = value:get()
        playerSaveItemAmounts[itemData:GetFName():ToString()] = count
    end)
    local playerSaveWeaponDatas = {}
    saveData.PlayerSaveData.PlayerWeaponDatas:ForEach(function(key, value)
        print('trying to add weapon')
        if not key then return end
        print('key is real')
        ---@type UWeaponDataAsset
        local weapon = key:get()
        ---@type FPlayerWeaponData
        local data = value:get()
        local affixSlots = {}
        data.AffixSlots:ForEach(function(slotParam, affixData)
            if not slotParam then return end
            ---@type integer
            local slot = slotParam:get()
            ---@type UAffixDataAsset
            local data = affixData:get()
            print(IsValid(data))
            if IsValid(data) then
                affixSlots[slot] = data:GetFName():ToString()
            else
                affixSlots[slot] = ""
            end
        end)
        print('adding weapon ' .. weapon:GetFName():ToString())
        playerSaveWeaponDatas[weapon:GetFName():ToString()] = affixSlots
    end)

    -- Loadout secondary weapons
    local playerLoadoutSecondaryWeapons = {}
    saveData.PlayerSaveData.CurrentLoadout.SecondaryWeapons:ForEach(function(key, value)
        if not key then return end
        ---@type integer
        local directionIndex = key:get()
        ---@type UWeaponDataAsset
        local weaponData = value:get()
        if IsValid(weaponData) then
            playerLoadoutSecondaryWeapons[directionIndex] = weaponData:GetFName():ToString()
        else
            playerLoadoutSecondaryWeapons[directionIndex] = ""
        end
    end)

    return {
        luaPlayerSaveData = {
            Chroma = saveData.PlayerSaveData.Chroma,
            CorpseChroma = saveData.PlayerSaveData.CorpseChroma,
            UnlockedAbilityFlags = saveData.PlayerSaveData.UnlockedAbilityFlags,
            DeathLocation = saveData.PlayerSaveData.DeathLocation,
            MapTrackedDeathLocation = saveData.PlayerSaveData.MapTrackedDeathLocation,
            ItemAmounts = playerSaveItemAmounts,
            PlayerWeaponDatas = playerSaveWeaponDatas,
            LoadoutPrimaryWeapon = saveData.PlayerSaveData.CurrentLoadout.PrimaryWeapon:GetFName():ToString(),
            LoadoutSecondaryWeapons = playerLoadoutSecondaryWeapons,
        },
        currentCheckpointName = saveData.CurrentCheckpointID:ToString(),
        currentCheckpointRegionTag = saveData.CurrentCheckpointRegionTag.TagName:ToString(),
        bHudVisible = saveData.bHUDVisible,
        perObjectSaveData = perObjData,
    }
end

local function LoadDataIntoFNameMap(map, data)
    map:Empty()
    for k, v in pairs(data) do
        map:Add(FName(k), v)
    end
end
--- Loads data from lua save data into an in-engine
--- save data object.
--- As I can't figure out how to construct certain objects without causing a crash,
--- this can only remove certain things from save data, not add them.
---@param luaData LuaSaveData
---@param saveData FSaveSlotData
function LoadLuaData(luaData, saveData)
    saveData.CurrentCheckpointID = FName(luaData.currentCheckpointName)
    saveData.CurrentCheckpointRegionTag.TagName = FName(luaData.currentCheckpointRegionTag)

    -- Object data
    -- avoids a concurrent modification issue, didn't test if this was necessary but just to be safe
    local toRemove = {}
    local i = 1 -- lua arrays start at 1
    saveData.PerObjectSaveData:ForEach(function(k, v)
        local name = k:get()
        local luaObjData = luaData.perObjectSaveData[name:ToString()]
        if not luaObjData then
            toRemove[i] = name
            i = i + 1
        else
            ---@type FPoseObjectData
            local objData = v:get()
            LoadDataIntoFNameMap(objData.BoolMap, luaObjData.BoolMap)
            LoadDataIntoFNameMap(objData.IntMap, luaObjData.IntMap)
            LoadDataIntoFNameMap(objData.FloatMap, luaObjData.FloatMap)
            LoadDataIntoFNameMap(objData.VectorMap, luaObjData.VectorMap)
            objData.FlagSet:Empty()
            for i, flagName in ipairs(luaObjData.FlagSet) do
                objData.FlagSet:Add(FName(flagName))
            end
        end
    end)
    for i, v in ipairs(toRemove) do
        saveData.PerObjectSaveData:Remove(v)
    end

    -- Item/Weapon data
    -- Requires getting item objects from the UItemDataProvider
    ---@type UItemDataProvider
    local itemDataProvider = FindFirstOf("ItemDataProvider")
    if IsValid(itemDataProvider) then
        print('yippeeee')
        -- Item data
        saveData.PlayerSaveData.ItemAmounts:Empty()
        for k, v in pairs(luaData.luaPlayerSaveData.ItemAmounts) do
            print('adding data: item ' .. k .. ' x' .. v)
            local data = itemDataProvider:FindItemByName(0, FName(k))
            print(IsValid(data))
            saveData.PlayerSaveData.ItemAmounts:Add(data, v)
        end
        -- Weapon data
        -- Cannot create weapon data so again this can only go backwards
        -- First remove data
        -- reusing old i and toRemove
        i = 1
        toRemove = {}
        saveData.PlayerSaveData.PlayerWeaponDatas:ForEach(function(weaponParam, data)
            ---@type UWeaponDataAsset
            local weapon = weaponParam:get()
            if not luaData.luaPlayerSaveData.PlayerWeaponDatas[weapon:GetFName():ToString()] then
                print('Adding weapon ' .. weapon:GetFName():ToString() .. ' to remove list')
                toRemove[i] = weapon
                i = i + 1
            end
        end)
        for index, weaponData in ipairs(toRemove) do
            print('removing a weapon')
            saveData.PlayerSaveData.PlayerWeaponDatas:Remove(weaponData)
        end

        -- Now set affix slots on remaining data
        for k, v in pairs(luaData.luaPlayerSaveData.PlayerWeaponDatas) do
            local data = itemDataProvider:FindWeaponByName(0, FName(k))
            print(IsValid(data))
            if saveData.PlayerSaveData.PlayerWeaponDatas:Contains(data) then
                local weaponData = saveData.PlayerSaveData.PlayerWeaponDatas:Find(data)
                -- The return type on Find is wrong, you need to call get() first.
                local affixSlots = weaponData:get().AffixSlots
                print('emptied affix slots for weapon ' .. k)
                affixSlots:Empty()
                for slot, affixName in pairs(v) do
                    print('adding an affix ' .. affixName .. ' back to weapon ' .. k)
                    if affixName == "" then
                        affixSlots:Add(slot, CreateInvalidObject())
                    else
                        affixSlots:Add(slot, itemDataProvider:FindAffixByName(FName(affixName)))
                    end
                end
            end
        end
        -- Set loadout
        saveData.PlayerSaveData.CurrentLoadout.PrimaryWeapon = itemDataProvider:FindWeaponByName(0,
            FName(luaData.luaPlayerSaveData.LoadoutPrimaryWeapon))
        for k, v in pairs(luaData.luaPlayerSaveData.LoadoutSecondaryWeapons) do
            if v == "" then
                saveData.PlayerSaveData.CurrentLoadout.SecondaryWeapons:Add(k, CreateInvalidObject())
            else
                saveData.PlayerSaveData.CurrentLoadout.SecondaryWeapons:Add(k,
                    itemDataProvider:FindWeaponByName(0, FName(v)))
            end
        end
    end


    -- Misc player data
    saveData.PlayerSaveData.Chroma = luaData.luaPlayerSaveData.Chroma
    saveData.PlayerSaveData.CorpseChroma = luaData.luaPlayerSaveData.CorpseChroma
    saveData.PlayerSaveData.DeathLocation = luaData.luaPlayerSaveData.DeathLocation
    saveData.PlayerSaveData.MapTrackedDeathLocation = luaData.luaPlayerSaveData.MapTrackedDeathLocation
    saveData.PlayerSaveData.UnlockedAbilityFlags = luaData.luaPlayerSaveData.UnlockedAbilityFlags

    return saveData
end
