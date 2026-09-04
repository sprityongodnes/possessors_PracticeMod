local UEHelpers = require("UEHelpers")
local saveio = require("saveio")
local util = require("util")

-- ==========================================
-- [EN] MOD CONFIGURATION SYSTEM
-- [FR] SYSTÈME DE CONFIGURATION DU MOD
-- ==========================================
local configFileName = "practice_mod_config.txt"

-- [EN] Default settings / [FR] Paramètres par défaut
local config = {
    scale = 1.0,        -- [EN] Text scale / [FR] Échelle du texte
    posX = 50,          -- [EN] X Position in pixels / [FR] Position X en pixels
    posY = 50,          -- [EN] Y Position in pixels / [FR] Position Y en pixels
    showTimer = true,   -- [EN] Show Timer / [FR] Afficher le chrono
    showStats = true,   -- [EN] Show Stats / [FR] Afficher les stats
    showFPS = true      -- [EN] Show FPS / [FR] Afficher les FPS
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
        f:write(tostring(config.showFPS) .. "\n")
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
        local fpsRead = f:read("*l")
        config.showFPS = (fpsRead == nil) and true or (fpsRead == "true")
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
---@type USaveSlotSubsystem
local SaveDataSubsystem = nil
---@type ABP_PoseGameMode_C
local PoseGameMode = nil

local chronoEnMarche = false
local tempsActuel = 0.0
local messageAction = ""
local tempsMessage = 0
local cooldownAction = 0.0

-- Hooks to track
local playerPreHook
local playerPostHook
local quitPreHook
local quitPostHook

---@type table<integer, SaveState>
local savestates = {}
local currentSlot = 1

local pendingSaveStateLoad = false

-- [EN] Update HUD Scale and Free Pixel Position / [FR] Met à jour l'échelle et la position en pixels
local function ApplyHUDTransforms()
    if not MainWidget or not MainWidget:IsValid() then return end

    MainWidget:SetRenderScale({ X = config.scale, Y = config.scale })
    MainWidget:SetAnchorsInViewport({ Minimum = { X = 0.0, Y = 0.0 }, Maximum = { X = 0.0, Y = 0.0 } })
    MainWidget:SetAlignmentInViewport({ X = 0.0, Y = 0.0 })
    MainWidget:SetPositionInViewport({ X = config.posX, Y = config.posY }, false)
end

-- [EN] Initializes needed variables and finds important objects / [FR] Créer des vars utiles et trouver les objets utiles
local function Init()
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

        MainWidget:AddToViewport(0)
        ApplyHUDTransforms()

        SaveDataSubsystem = FindFirstOf("SaveSlotSubsystem")
        PoseGameMode = FindFirstOf("BP_PoseGameMode_C")
    end)

    if success then
        initialized = true
        return true
    end
    return false
end

-- Signal we need to reinitialize
local function Deinit()
    initialized = false
    UnregisterHook("/Game/Pose/Common/Systems/BP_PoseHUD.BP_PoseHUD_C:ReturnToMainMenu", quitPreHook, quitPostHook)
    UnregisterHook("/Game/Pose/Characters/PlayerCharacter/ABP_Player.ABP_Player_C:OnTick", playerPreHook, playerPostHook)
end

-- [EN] Save State Logic / [FR] Logique de sauvegarde
local function SaveState()
    ---@type ABP_PosePlayerPawn_C
    local Pawn = UEHelpers.GetPlayer()
    if not Pawn or not SaveDataSubsystem then return end

    ---@type UPoseSaveSlot
    local saveData = SaveDataSubsystem:GetSaveGame()
    local previousAttempts = (savestates[currentSlot] and savestates[currentSlot].attempts) or 0

    savestates[currentSlot] = {
        luaSaveData = SaveDataToLuaTable(saveData.SaveSlotData),
        pos = Pawn:K2_GetActorLocation(),
        rot = Pawn:K2_GetActorRotation(),
        health = Pawn.PrimaryHealth:GetCurrentEnergy(),
        ammo = Pawn.AmmoEnergy:GetCurrentEnergy(),
        heals = Pawn.HealEnergy:GetCurrentEnergy(),
        attempts = previousAttempts,
        savedTime = tempsActuel -- [FR] Sauvegarde du chrono actuel
    }

    messageAction = "Saved Slot " .. tostring(currentSlot)
    tempsMessage = 2.0
end

-- [EN] Load State Logic / [FR] Logique de chargement
local function LoadState()
    if cooldownAction > 0 then return end
    local state = savestates[currentSlot]

    if not state then
        messageAction = "Slot " .. tostring(currentSlot) .. " is empty!"
        tempsMessage = 1.5
        return
    end

    ---@type ABP_PosePlayerController_C
    local controller = UEHelpers:GetPlayerController()

    -- [FR] Restauration du chrono au moment de la sauvegarde
    tempsActuel = state.savedTime or 0.0

    LoadLuaData(state.luaSaveData, SaveDataSubsystem.ActiveSaveGame.SaveSlotData)
    SaveDataSubsystem:SetSavingEnabled(FName("meow"), false)
    controller:RestartLevel()

    Deinit()                    
    pendingSaveStateLoad = true 

    ExecuteInGameThreadWithDelay(1100, function()
        SaveDataSubsystem:SetSavingEnabled(FName("meow"), true)
        SaveDataSubsystem.SaveDisablingReasons:Empty()
    end)

    state.attempts = (state.attempts or 0) + 1
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
RegisterKeyBind(Key.F3, function()
    currentSlot = (currentSlot == 1) and 5 or (currentSlot - 1)
    messageAction = "Slot: " .. tostring(currentSlot)
    tempsMessage = 1.0
end)
RegisterKeyBind(Key.F4, function()
    currentSlot = (currentSlot == 5) and 1 or (currentSlot + 1)
    messageAction = "Slot: " .. tostring(currentSlot)
    tempsMessage = 1.0
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
RegisterKeyBind(Key.F9, function()
    config.showFPS = not config.showFPS
    SaveConfig()
    messageAction = "FPS: " .. (config.showFPS and "ON" or "OFF")
    tempsMessage = 1.0
end)

-- [EN] FREE POSITIONING (Arrow Keys) / [FR] DÉPLACEMENT LIBRE (Flèches Directionnelles)
local VK_LEFT  = 0x25
local VK_UP    = 0x26
local VK_RIGHT = 0x27
local VK_DOWN  = 0x28
local moveStep = 20

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

RegisterKeyBind(VK_NEXT, function()
    config.scale = math.max(0.5, config.scale - 0.1)
    ApplyHUDTransforms()
    SaveConfig()
    messageAction = string.format("HUD Scale: %.1fx", config.scale)
    tempsMessage = 1.5
end)

RegisterKeyBind(VK_PRIOR, function()
    config.scale = math.min(3.0, config.scale + 0.1)
    ApplyHUDTransforms()
    SaveConfig()
    messageAction = string.format("HUD Scale: %.1fx", config.scale)
    tempsMessage = 1.5
end)

-- ==========================================
-- [EN] MAIN GAME TICK / [FR] BOUCLE PRINCIPALE
-- ==========================================
local function GameTickLogic(dt)
    if cooldownAction > 0 then cooldownAction = cooldownAction - dt end
    if chronoEnMarche then tempsActuel = tempsActuel + dt end
    if tempsMessage > 0 then
        tempsMessage = tempsMessage - dt
        if tempsMessage <= 0 then messageAction = "" end
    end

    local lines = {}

    -- [FR] Le Chrono s'affiche en premier (en haut)
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

    -- [FR] Les FPS s'affichent en second (en dessous du Chrono)
    if config.showFPS then
        local currentFps = math.floor((1.0 / math.max(dt, 0.0001)) + 0.5)
        table.insert(lines, string.format("FPS: %d", currentFps))
    end

    -- [FR] Les Stats s'affichent en dernier
    if config.showStats then
        local attemptsCount = (savestates[currentSlot] and savestates[currentSlot].attempts) or 0
        table.insert(lines, string.format("Slot: %d | Attempts: %d", currentSlot, attemptsCount))
    end

    if messageAction ~= "" then
        table.insert(lines, messageAction)
    end

    if TextBox and TextBox:IsValid() then
        TextBox:SetText(FText(table.concat(lines, "\n")))
    end
end

local function StartPlayerHook()
    if not initialized then
        Init()
        if not initialized then
            error("[PracticeMod] Unable to initialize PracticeMod, maybe try restarting?")
            return
        end
        playerPreHook, playerPostHook = RegisterHook(
            "/Game/Pose/Characters/PlayerCharacter/ABP_Player.ABP_Player_C:OnTick",
            function(self, DeltaTime)
                local dt = type(DeltaTime) == "number" and DeltaTime or DeltaTime:get()
                pcall(GameTickLogic, dt)
            end)
        quitPreHook, quitPostHook = RegisterHook(
            "/Game/Pose/Common/Systems/BP_PoseHUD.BP_PoseHUD_C:ReturnToMainMenu",
            Deinit)
    end
end

local player = UEHelpers:GetPlayer()
if player:IsValid() then
    StartPlayerHook()
end

local gameStartRegistered = false
RegisterBeginPlayPostHook(function(Context)
    if not gameStartRegistered then
        RegisterHook("/Game/Pose/UI/LoadingScreen/WBP_LoadingScreen.WBP_LoadingScreen_C:StartFadeOut", function()
            StartPlayerHook()
            if pendingSaveStateLoad then
                local state = savestates[currentSlot]
                ---@type ABP_PosePlayerPawn_C
                local pawn = UEHelpers:GetPlayer()
                pawn:K2_TeleportTo(state.pos, state.rot)
                pawn.PrimaryHealth:SetEnergy(state.health)
                pawn.HealEnergy:SetEnergy(state.heals)
                pawn.AmmoEnergy:SetEnergy(state.ammo)
                pendingSaveStateLoad = false
            end
        end)
        gameStartRegistered = true
    end
end)
