local UEHelpers = require("UEHelpers")

-- ==========================================
-- [EN] MOD CONFIGURATION SYSTEM
-- [FR] SYSTÈME DE CONFIGURATION DU MOD
-- ==========================================
local configFileName = "practice_mod_config.txt"

-- [EN] Default settings / [FR] Paramètres par défaut
local config = {
    scale = 1.0,      -- [EN] Text scale / [FR] Échelle du texte
    -- Info: "Anchor" positions are [0,1]
    anchorX = 0.01,   -- [EN] X Position / [FR] Position X
    anchorY = 0.3,    -- [EN] Y Position / [FR] Position Y
    showTimer = true, -- [EN] Show Timer / [FR] Afficher le chrono
    showStats = true  -- [EN] Show Stats / [FR] Afficher les stats
}

-- [EN] Save settings to file / [FR] Sauvegarder les paramètres dans un fichier
local function SaveConfig()
    local f = io.open(configFileName, "w")
    if f then
        f:write(tostring(config.scale) .. "\n")
        f:write(tostring(config.posX) .. "\n")
        f:write(tostring(config.posY) .. "\n")
        f:write(tostring(config.showTimer) .. "\n")
        f:write(tostring(config.showStats) .. "\n")
        f:close()
    end
end

-- [EN] Load settings from file / [FR] Charger les paramètres depuis le fichier
local function LoadConfig()
    local f = io.open(configFileName, "r")
    if f then
        config.scale = tonumber(f:read("*l")) or 1.0
        config.posX = tonumber(f:read("*l")) or 50
        config.posY = tonumber(f:read("*l")) or 50
        config.showTimer = f:read("*l") == "true"
        config.showStats = f:read("*l") == "true"
        f:close()
    else
        SaveConfig()
    end
end

LoadConfig()

-- ==========================================
-- [EN] INTERNAL VARIABLES
-- [FR] VARIABLES INTERNES
-- ==========================================
local initialized = false
local MainWidget = nil
local TextBox = nil
local SaveDataSubsystem = nil
local PlayerPortal = nil

local chronoEnMarche = false
local tempsActuel = 0.0
local messageAction = ""
local tempsMessage = 0
local cooldownAction = 0.0

local savestates = {}
for i = 1, 5 do
    savestates[i] = { saved = false, attempts = 0 }
end
local currentSlot = 1

local function IsValid(obj)
    return obj ~= nil and type(obj.IsValid) == "function" and obj:IsValid()
end

local function FindClass(path)
    local cls = StaticFindObject(path)
    if not IsValid(cls) then error("StaticFindObject failed: " .. path) end
    return cls
end

local function Construct(classPath, outer, name)
    local cls = FindClass(classPath)
    local obj = StaticConstructObject(cls, outer, FName(name))
    if not IsValid(obj) then error("StaticConstructObject failed: " .. classPath) end
    return obj
end

-- [EN] Update HUD Scale and Free Position / [FR] Met à jour l'échelle et la position libre
local function ApplyHUDTransforms()
    if not MainWidget or not MainWidget:IsValid() then return end

    -- 1. Appliquer l'échelle (Fonctionne parfaitement sur le MainWidget)
    MainWidget:SetRenderScale({ X = config.scale, Y = config.scale })

    -- 2. Appliquer la position
    -- On utilise les ancres pour que la position soit la même n'importe quelle taille d'écran
    MainWidget:SetAnchorsInViewport({ Minimum = { X = config.anchorX, Y = config.anchorY }, Maximum = { X = config.anchorX, Y = config.anchorY } })
end

-- [EN] In-game native HUD creation / [FR] Création du HUD natif en jeu
local function InitHUD()
    local p = UEHelpers.GetPlayerController()
    if not p or not p:IsValid() or not p.MyHUD or not p.MyHUD:IsValid() then
        return false
    end

    local success, err = pcall(function()
        MainWidget = Construct("/Script/UMG.UserWidget", p.MyHUD.PlayerHUD, "PracticeModRootWidget")
        local tree = Construct("/Script/UMG.WidgetTree", MainWidget, "PracticeModRootWidgetTree")
        MainWidget.WidgetTree = tree

        TextBox = Construct("/Script/UMG.TextBlock", MainWidget, "PracticeModTextOverlay")
        TextBox.Font.Size = 18
        TextBox:SetText(FText("Practice Mod Ready"))
        tree.RootWidget = TextBox

        MainWidget:AddToViewport(999)
        ApplyHUDTransforms()

        PlayerPortal = FindFirstOf("CBP_PlayerPortal_C")
        SaveDataSubsystem = FindFirstOf("SaveSlotSubsystem")
    end)

    if success then
        initialized = true
        return true
    end
    return false
end

-- [EN] Save State Logic / [FR] Logique de sauvegarde
local function SaveState()
    local Pawn = UEHelpers.GetPlayer()
    if not Pawn or not SaveDataSubsystem then return end

    local Loc = Pawn:K2_GetActorLocation()
    local Rot = Pawn:K2_GetActorRotation()

    savestates[currentSlot] = {
        saved = true,
        attempts = 0,
        posX = Loc.X,
        posY = Loc.Y,
        posZ = Loc.Z,
        rotPitch = Rot.Pitch,
        rotRoll = Rot.Roll,
        rotYaw = Rot.Yaw,
        health = Pawn.PrimaryHealth:GetCurrentEnergy(),
        heals = Pawn.HealEnergy:GetCurrentEnergy(),
        ammo = Pawn.AmmoEnergy:GetCurrentEnergy(),
        saveData = SaveDataSubsystem:GetSaveGame(),
    }

    messageAction = "Saved Slot " .. tostring(currentSlot)
    tempsMessage = 2.0
end

-- [EN] Load State Logic / [FR] Logique de chargement
local function LoadState()
    if cooldownAction > 0 then return end
    local state = savestates[currentSlot]

    if not state or not state.saved then
        messageAction = "Slot " .. tostring(currentSlot) .. " is empty!"
        tempsMessage = 1.5
        return
    end

    local Pawn = UEHelpers.GetPlayer()
    if not Pawn or not SaveDataSubsystem then return end

    SaveDataSubsystem.ActiveSaveGame = state.saveData
    SaveDataSubsystem:LoadData()

    Pawn:K2_TeleportTo({ X = state.posX, Y = state.posY, Z = state.posZ },
        { Pitch = state.rotPitch, Roll = state.rotRoll, Yaw = state.rotYaw })

    Pawn.PrimaryHealth:SetEnergy(state.health)
    Pawn.HealEnergy:SetEnergy(state.heals)
    Pawn.AmmoEnergy:SetEnergy(state.ammo)

    state.attempts = state.attempts + 1
    cooldownAction = 0.3
    messageAction = "Loaded Slot " .. tostring(currentSlot)
    tempsMessage = 1.0
end

-- ==========================================
-- [EN] CONTROLS & KEYBINDS / [FR] CONTRÔLES & RACCOURCIS
-- ==========================================

-- [EN] Timer & Slots / [FR] Chrono & Slots
RegisterKeyBind(Key.F1, function() chronoEnMarche = not chronoEnMarche end)
RegisterKeyBind(Key.F2, function() tempsActuel = 0.0 end)
RegisterKeyBind(Key.F3,
    function()
        currentSlot = (currentSlot == 1) and 5 or (currentSlot - 1); messageAction = "Slot: " .. tostring(currentSlot); tempsMessage = 1.0
    end)
RegisterKeyBind(Key.F4,
    function()
        currentSlot = (currentSlot == 5) and 1 or (currentSlot + 1); messageAction = "Slot: " .. tostring(currentSlot); tempsMessage = 1.0
    end)

-- [EN] Save & Load / [FR] Sauvegarder & Charger
RegisterKeyBind(Key.F5, SaveState)
RegisterKeyBind(Key.F6, LoadState)

-- [EN] Visibility Toggles / [FR] Cacher ou Afficher des infos
RegisterKeyBind(Key.F7, function()
    config.showTimer = not config.showTimer
    SaveConfig()
end)
RegisterKeyBind(Key.F8, function()
    config.showStats = not config.showStats
    SaveConfig()
end)

-- [EN] FREE POSITIONING (Arrow Keys) / [FR] DÉPLACEMENT LIBRE (Flèches Directionnelles)
-- Utilisation des codes hexadécimaux bruts pour garantir que la touche soit reconnue
local VK_LEFT  = 0x25
local VK_UP    = 0x26
local VK_RIGHT = 0x27
local VK_DOWN  = 0x28
local moveStep = 20 -- Nombre de pixels par déplacement

RegisterKeyBind(VK_LEFT, function()
    config.posX = math.max(0, config.posX - moveStep)
    ApplyHUDTransforms()
    SaveConfig()
end)

RegisterKeyBind(VK_RIGHT, function()
    config.posX = config.posX + moveStep
    ApplyHUDTransforms()
    SaveConfig()
end)

RegisterKeyBind(VK_UP, function()
    config.posY = math.max(0, config.posY - moveStep)
    ApplyHUDTransforms()
    SaveConfig()
end)

RegisterKeyBind(VK_DOWN, function()
    config.posY = config.posY + moveStep
    ApplyHUDTransforms()
    SaveConfig()
end)

-- [EN] SCALING (Page Up / Page Down) / [FR] TAILLE DU HUD (Page Up / Page Down)
local VK_PRIOR = 0x21               -- Page Up
local VK_NEXT  = 0x22               -- Page Down

RegisterKeyBind(VK_NEXT, function() -- Page Down (Réduire)
    config.scale = math.max(0.5, config.scale - 0.1)
    ApplyHUDTransforms()
    SaveConfig()
    messageAction = string.format("HUD Scale: %.1fx", config.scale); tempsMessage = 1.5
end)

RegisterKeyBind(VK_PRIOR, function() -- Page Up (Agrandir)
    config.scale = math.min(3.0, config.scale + 0.1)
    ApplyHUDTransforms()
    SaveConfig()
    messageAction = string.format("HUD Scale: %.1fx", config.scale); tempsMessage = 1.5
end)

-- ==========================================
-- [EN] MAIN GAME TICK / [FR] BOUCLE PRINCIPALE
-- ==========================================
local function GameTickLogic(dt)
    if not initialized then
        InitHUD()
        return
    end

    if cooldownAction > 0 then cooldownAction = cooldownAction - dt end
    if chronoEnMarche then tempsActuel = tempsActuel + dt end
    if tempsMessage > 0 then
        tempsMessage = tempsMessage - dt
        if tempsMessage <= 0 then messageAction = "" end
    end

    local lines = {}

    if config.showTimer then
        local heures = math.floor(tempsActuel / 3600)
        local minutes = math.floor((tempsActuel % 3600) / 60)
        local secondes = math.floor(tempsActuel % 60)
        local millisecondes = math.floor((tempsActuel % 1) * 100)
        local tempsFormate = (heures > 0)
            and string.format("%02d:%02d:%02d.%02d", heures, minutes, secondes, millisecondes)
            or string.format("%02d:%02d.%02d", minutes, secondes, millisecondes)
        table.insert(lines, "Timer : " .. tempsFormate)
    end

    if config.showStats then
        table.insert(lines, string.format("Slot: %d | Attempts: %d", currentSlot, savestates[currentSlot].attempts))
    end

    if messageAction ~= "" then
        table.insert(lines, messageAction)
    end

    if TextBox and TextBox:IsValid() then
        TextBox:SetText(FText(table.concat(lines, "\n")))
    end
end

RegisterHook("/Game/Pose/Characters/PlayerCharacter/ABP_Player.ABP_Player_C:OnTick", function(self, DeltaTime)
    local dt = type(DeltaTime) == "number" and DeltaTime or DeltaTime:get()
    pcall(GameTickLogic, dt)
end)
