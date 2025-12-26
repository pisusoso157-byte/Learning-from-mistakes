local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local userInputService = game:GetService("UserInputService")
local backpack = player:WaitForChild("Backpack")

local FPSDevourer = {}
FPSDevourer.running = false
local FREEZE_TOOL = "Dark Matter Slap"

local function freezeEquip()
    local c = player.Character
    local b = player:FindFirstChild("Backpack")
    if not c or not b then return false end
    local t = b:FindFirstChild(FREEZE_TOOL)
    if t then
        t.Parent = c
        return true
    end
    return false
end

local function freezeUnequip()
    local c = player.Character
    local b = player:FindFirstChild("Backpack")
    if not c or not b then return false end
    local t = c:FindFirstChild(FREEZE_TOOL)
    if t then
        t.Parent = b
        return true
    end
    return false
end

function FPSDevourer:Start()
    if FPSDevourer.running then return end
    FPSDevourer.running = true
    FPSDevourer.stop = false
    task.spawn(function()
        while FPSDevourer.running and not FPSDevourer.stop do
            freezeEquip()
            task.wait(0.035)
            freezeUnequip()
            task.wait(0.035)
        end
    end)
end

function FPSDevourer:Stop()
    FPSDevourer.running = false
    FPSDevourer.stop = true
    freezeUnequip()
end

local TARGET_TOOL = "Quantum Cloner"
local EVENT_USE = game:GetService("ReplicatedStorage").Packages.Net["RE/UseItem"]
local EVENT_TELEPORT = game:GetService("ReplicatedStorage").Packages.Net["RE/QuantumCloner/OnTeleport"]

local tool = backpack:FindFirstChild(TARGET_TOOL) or character:FindFirstChild(TARGET_TOOL)

local isExecuting = false

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.F then return end
    
    if isExecuting then return end
    isExecuting = true
    
    FPSDevourer:Start()
    
    task.wait(0.1)
    tool = tool and tool.Parent and tool or (backpack:FindFirstChild(TARGET_TOOL) or character:FindFirstChild(TARGET_TOOL))
    
    if tool then
        humanoid:EquipTool(tool)
        task.wait(0.05)
        EVENT_USE:FireServer()
        task.wait(0.05)
        EVENT_TELEPORT:FireServer()
    end
    
    task.wait(0.5)
    freezeUnequip()
    
    local backpackCheck = player:FindFirstChild("Backpack")
    if backpackCheck then
        local quantumCloner = character:FindFirstChild(TARGET_TOOL)
        if quantumCloner then
            quantumCloner.Parent = backpackCheck
        end
    end
    
    FPSDevourer:Stop()
    
    isExecuting = false
end)

player.CharacterAdded:Connect(function()
    FPSDevourer.running = false
    FPSDevourer.stop = true
    isExecuting = false
end)

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Таблица для отслеживания уже обработанных персонажей
local processedCharacters = {}

-- Функция для скрытия аксессуаров в модели персонажа
local function hideAccessories(character)
    -- Помечаем персонажа как обработанного
    processedCharacters[character] = true
    
    -- Функция для скрытия аксессуаров
    local function hideAllAccessories()
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Accessory") then
                local handle = item:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 1
                    -- Также отключаем частицы и другие эффекты
                    for _, effect in ipairs(handle:GetChildren()) do
                        if effect:IsA("ParticleEmitter") or effect:IsA("Beam") or effect:IsA("Trail") then
                            effect.Enabled = false
                        end
                    end
                end
            end
        end
    end
    
    -- Сразу скрываем существующие аксессуары
    hideAllAccessories()
    
    -- Отслеживаем добавление новых аксессуаров
    local connection
    connection = character.ChildAdded:Connect(function(child)
        if child:IsA("Accessory") then
            -- Небольшая задержка для инициализации аксессуара
            wait(0.1)
            hideAllAccessories()
        end
    end)
    
    -- Сохраняем соединение для последующей очистки
    character.Destroying:Connect(function()
        processedCharacters[character] = nil
        connection:Disconnect()
    end)
end

-- Постоянно проверяем наличие новых персонажей
local function continuousCheck()
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and not processedCharacters[model] then
            hideAccessories(model)
        end
    end
end

-- Обрабатываем уже существующие модели в Workspace
continuousCheck()

-- Обрабатываем новые модели, которые добавляются в Workspace
Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
        wait(0.5) -- Даем время для полной загрузки персонажа
        hideAccessories(child)
    end
end)

-- Постоянная проверка каждые 2 секунды для надежности
while true do
    wait(2)
    continuousCheck()
end
