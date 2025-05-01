--[[ ====================================================== ]] --
--[[         MH Vehicle Sabotage Script by MaDHouSe         ]] --
--[[ ====================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local peds = {}
local blips = {}
local hasLeaked = {}
local isLoggedIn = false
local displayBones = true
local canRepair = true
local random = nil
local lastIndex = 0
local countBraking = 0
local maxBeforeBrakeCount = math.random(5, 10)
local disableControll = false

local function UseSkillBar()
    return exports["qb-minigames"]:Skillbar(config.SkillBarType, config.SkillBarKeys)
end

--- To send a notifytation
---@param message string
---@param type string
---@param length number
local function Notify(message, type, length)
    if GetResourceState("ox_lib") ~= 'missing' then
        lib.notify({title = "MH Vehicle Sabotage", description = message, type = type})
    else
        QBCore.Functions.Notify({text = "MH Vehicle Sabotage", caption = message}, type, length)
    end
end

--- Set Brake Force
---@param vehicle any
---@param force number
local function SetBrakeForce(vehicle, force)
    SetVehicleHandlingField(vehicle, "CHandlingData", "fBrakeForce", force)
end

--- Get Brake Force
---@param vehicle any
local function GetBrakeForce(vehicle)
    return GetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeForce")
end

local function GetDistance(pos1, pos2)
    if pos1 ~= nil and pos2 ~= nil then
        return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
    end
end

--- To load a model
---@param model string
local function LoadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(1)
        end
    end
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(5)
    end
end

--- Delete all blips from the map
local function DeleteBlips()
    for k, blip in pairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end

--- Delete all shop peds from the map
local function DeletePeds()
    for k, ped in pairs(peds) do
        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, true, true)
            DeleteEntity(ped)
            DeletePed(ped)
        end
    end
end

--- Load blips
---@param shops table
local function LoadBlips()
    for k, shop in pairs(config.Shops) do
        if shop.blip.enable then
            local blip = AddBlipForCoord(shop.ped.coords)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipScale(blip, shop.blip.scale)
            SetBlipColour(blip, shop.blip.colour)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.label)
            EndTextCommandSetBlipName(blip)
            SetBlipAsShortRange(blip, true)
            blips[#blips + 1] = blip
        end
    end
end

local function ShopMenu()
    if config.MenuScript == "ox_lib" then
        local options = {}
        local num = 1
        for k, v in pairs(config.Items) do
            local image = config.ImagesBaseFolder .. v.name .. ".png"
            options[#options + 1] = {
                id = num,
                icon = image,
                title = v.label,
                description = 'Price: $'..v.price,
                arrow = false,
                onSelect = function()
                    local input = lib.inputDialog("amount_to_buy", {{type = 'number', label = "amount_to_buy", description = "enter the amount of items you want to buy", required = true, icon = 'hashtag'}})
                    if not input then return ShopMenu() end
                    TriggerServerEvent('mh-vehiclesabotage:server:giveitem', {src = PlayerData.source, name = v.name, price = v.price, amount = tonumber(input[1])})
                    ShopMenu()
                end
            }
            num = num + 1
        end
        options[#options + 1] = {id = num,title = Lang:t('info.close'), icon = "fa-solid fa-stop", description = '', arrow = false, onSelect = function() end}
        table.sort(options, function(a, b) return a.id < b.id end)
        lib.registerContext({id = 'menu', title = "Tools Shop", icon = "fa-solid fa-car", options = options})
        lib.showContext('menu')
    elseif config.MenuScript == "qb-menu" then
        local options = {{header = "Tools Shop", isMenuHeader = true}}
        for k, v in pairs(config.Items) do
            local image = config.ImagesBaseFolder .. v.name .. ".png"
            local description = 'Item: '..v.label..'<br />Price: $'..v.price..'<br />Amount: '..v.amount
            options[#options + 1] = {
                header = "", txt = '<table><td style="text-align:left; height: 50px; padding: 5px;"><img src="'..image..'" style="width:80px;"></td><td style="text-align:top; height: 50px; padding: 15px;">'..description..'</td></table>',
                params = {event = 'mh-vehiclesabotage:server:giveitem', data = {src = PlayerData.source, name = v.name, price = v.price, amount = 1}}
            }
        end
        options[#options + 1] = {header = Lang:t('info.close'), txt = '', params = {event = 'qb-menu:client:closeMenu'}}
        exports['qb-menu']:openMenu(options)
    end
end

--- Create Shop Peds
---@param shops table
local function CreateShopPeds()
    for id, shop in pairs(config.Shops) do
        if shop.enable then
            LoadModel(shop.ped.model)
            local ped = CreatePed(0, shop.ped.model, shop.ped.coords.x, shop.ped.coords.y, shop.ped.coords.z - 1, shop.ped.coords.w, false, false)
            SetEntityAsMissionEntity(ped, true, true)
            TaskStartScenarioInPlace(ped, shop.ped.senario, true)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedRandomComponentVariation(ped, 0)
            SetPedRandomProps(ped)
            peds[#peds + 1] = ped
            if GetResourceState("qb-target") ~= 'missing' then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {{
                        label = Lang:t('info.open_shop'),
                        icon = 'fa-solid fa-hotel',
                        action = function()
                            ShopMenu()
                        end,
                        canInteract = function(entity, distance, data)
                            return true
                        end
                    }},
                    distance = 2.0
                })
            elseif GetResourceState("ox_target") ~= 'missing' then
                exports.ox_target:addEntity(ped, {
                    {
                        label = Lang:t('info.open_shop'),
                        icon = 'fa-solid fa-hotel',
                        onSelect = function(data)
                            ShopMenu()
                        end,
                        canInteract = function(data)
                            return true
                        end,
                        distance = 2.0
                    },
                })
            end
        end
    end
end

--- Get Closest Vehicle
local function GetClosestVehicle()
    local coords = GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end

--- Get Closest Wheel
---@param vehicle entity
local function GetClosestWheel(vehicle)
    local closestWheelIndex = nil
    local closestWheelBone = nil
    if isLoggedIn then
        local playerCoords = GetEntityCoords(PlayerPedId())
        for wheelIndex, wheelBone in pairs(config.BrakeLine.Bones) do
            local wheelBoneIndex = GetEntityBoneIndexByName(vehicle, wheelBone)
            if wheelBoneIndex ~= -1 then
                local wheelPos = GetWorldPositionOfEntityBone(vehicle, wheelBoneIndex)
                if #(playerCoords - wheelPos) <= 1.5 then
                    closestWheelIndex = wheelIndex
                    closestWheelBone = wheelBone
                    break
                end
            end
        end
    end
    return closestWheelIndex, closestWheelBone
end

--- Start brake oil lLeak
---@param vehicle entity
local function StartBrakeOilLeak(vehicle)
    CreateThread(function()
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do Wait(1) end
        local particle = {}
        for i = 0, 25 do
            UseParticleFxAsset("core")
            local particles = StartParticleFxLoopedOnEntity("veh_oil_slick", vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, false, false, false)
            particle[#particle + 1] = particles
            Wait(0)
        end
        Wait(1000)
        for _, parti in ipairs(particle) do
            StopParticleFxLooped(parti, true)
        end
    end)
end

--- Check if a line has damage
---@param vehicle entity
local function LineHasDamage(vehicle)
    if Entity(vehicle).state.wheel_lf or Entity(vehicle).state.wheel_rf or Entity(vehicle).state.wheel_lr or Entity(vehicle).state.wheel_rr or Entity(vehicle).state.line_empty then
        return true
    end
    return false
end

--- Checks if a line has no damage
---@param vehicle entity
local function NoLineDamage(vehicle)
    if not Entity(vehicle).state.wheel_lf and not Entity(vehicle).state.wheel_rf and not Entity(vehicle).state.wheel_lr and not Entity(vehicle).state.wheel_rr then
        return true
    end
    return false
end

--- Checks if brake line is already broken
---@param vehicle entity
---@param bone string
local function IsBrakelineAlreadyBroken(vehicle, bone)
    if bone == "wheel_lf" and Entity(vehicle).state.wheel_lf then
        return true
    elseif bone == "wheel_rf" and Entity(vehicle).state.wheel_rf then
        return true
    elseif bone == "wheel_lr" and Entity(vehicle).state.wheel_lr then
        return true
    elseif bone == "wheel_rr" and Entity(vehicle).state.wheel_rr then
        return true
    end
    return false
end

--- DoJob
---@param title string
---@param item string
---@param timer number
---@param vehicle entity
---@param bone string
---@param trigger string
---@param endMessage string
---@param animData table
local function DoJob(title, item, timer, vehicle, bone, trigger, endMessage, animData)
    disableControll = true
    FreezeEntityPosition(PlayerPedId(), true)
    LoadAnimDict(animData.animation.dict)
    TaskPlayAnim(PlayerPedId(), animData.animation.dict, animData.animation.name, 3.0, 3.0, -1, animData.animation.flag or 1, 0, false, false, false)
    Wait(timer)
    FreezeEntityPosition(PlayerPedId(), false)
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mh-vehiclesabotage:server:removeItem', item)
    TriggerServerEvent(trigger, NetworkGetNetworkIdFromEntity(vehicle), bone)
    Notify(endMessage, "success", 5000)
    canRepair = true
    disableControll = false
end

--- Cut brake line
---@param netid number
---@param bone string
local function CutBrakes(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) and type(Entity(vehicle).state) == 'table' then
        if IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or
            IsThisModelABicycle(GetEntityModel(vehicle)) then
            local isBrakelineAlreadyBroken = IsBrakelineAlreadyBroken(vehicle, bone)
            if isBrakelineAlreadyBroken then
                return Notify(Lang:t('info.brakeline_is_already_broken'), "success", 5000)
            elseif not isBrakelineAlreadyBroken then
                if config.UseMiniGame then
                    local success = UseSkillBar()
                    if success then
                        DoJob(Lang:t('info.cutting_brakes'), config.BrakeLine.Cut.item, config.BrakeLine.Cut.timer, vehicle, bone, 'mh-vehiclesabotage:server:syncDestroy', Lang:t('info.brakes_has_been_cut'), config.BrakeLine.Cut)
                    else
                        ClearPedTasks(PlayerPedId())
                        canRepair = true
                    end
                else
                    DoJob(Lang:t('info.cutting_brakes'), config.BrakeLine.Cut.item, config.BrakeLine.Cut.timer, vehicle, bone, 'mh-vehiclesabotage:server:syncDestroy', Lang:t('info.brakes_has_been_cut'), config.BrakeLine.Cut)
                end
            end
        else
            Notify(Lang:t('info.vehicle_has_no_brakes'), "error", 5000)
        end
    end
end

--- Repair brake line
---@param netid number
---@param bone string
local function RepairBrakes(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) and type(Entity(vehicle).state) == 'table' then
        if IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or
            IsThisModelABicycle(GetEntityModel(vehicle)) then
            local isLineBroken = IsBrakelineAlreadyBroken(vehicle, bone)
            if not isLineBroken then
                return Notify(Lang:t('info.line_not_broken'), "success", 5000)
            elseif isLineBroken then
                DoJob(Lang:t('info.repairing_brakes'), config.BrakeLine.Repair.item, config.BrakeLine.Repair.timer, vehicle, bone, 'mh-vehiclesabotage:server:syncRepair', Lang:t('info.brakes_has_been_repaired'), config.BrakeLine.Repair)
            end
        else
            Notify(Lang:t('info.vehicle_has_no_brakes'), "error", 5000)
        end
    end
end

--- Refill line with brake oil
---@param netid number
---@param bone string
local function RefillBrakeOil(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) and type(Entity(vehicle).state) == 'table' then
        if IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or
            IsThisModelABicycle(GetEntityModel(vehicle)) then
            local noDamage = NoLineDamage(vehicle)
            if not noDamage then
                Notify(Lang:t('info.repair_the_brake_lines_first'), "error", 5000)
            elseif noDamage then
                SetVehicleDoorOpen(vehicle, 4, false, true)
                DoJob(Lang:t('info.refuel_brake_oil'), config.BrakeLine.Oil.item, config.BrakeLine.Oil.timer, vehicle, bone, 'mh-vehiclesabotage:server:syncFixed', Lang:t('info.brakes_oil_has_refilled'), config.BrakeLine.Oil)
                if hasLeaked[netid] then hasLeaked[netid].status = false end
            end
        else
            Notify(Lang:t('info.vehicle_has_no_brakes'), "error", 5000)
        end
    end
end

local function GetVehicleInFrontOfPlayer(ped)
    local coords = GetEntityCoords(ped)
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    local rayHandle = CastRayPointToPoint(coords.x, coords.y, coords.z - 1.3, offset.x, offset.y, offset.z, 10, ped, 0)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetRaycastResult(rayHandle)
    if IsEntityAVehicle(entityHit) then return entityHit end
    return nil
end

local function CheckLine(vehicle)
    local lineHasDamage = LineHasDamage(vehicle)
    if lineHasDamage or Entity(vehicle).state.line_empty then
        Notify(Lang:t("info.lines_has_damage"), "error", 5000)
    elseif not lineHasDamage and not Entity(vehicle).state.line_empty then
        Notify(Lang:t("info.lines_has_no_damage"), "error", 5000)
    end
end

local function LossControl(vehicle)
    SetBrakeForce(vehicle, 0.0)
    SetVehicleReduceGrip(vehicle, true)
    Wait(math.random(1, 3) * 1000)
    SetVehicleReduceGrip(vehicle, false)
    local netid = VehToNet(vehicle)
    if hasLeaked[netid] and hasLeaked[netid].status then return end
    SetBrakeForce(vehicle, 1.0)
end

local function OnJoin()
    QBCore.Functions.TriggerCallback("mh-vehiclesabotage:server:OnJoin", function(data)
        if data.status then
            config = data.config
            PlayerData = QBCore.Functions.GetPlayerData()
            isLoggedIn = true
            CreateShopPeds()
            LoadBlips()
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerData = {}
        isLoggedIn = false
        DeletePeds()
        DeleteBlips()
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then OnJoin() end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    OnJoin()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
    DeletePeds()
    DeleteBlips()
end)

RegisterNetEvent('mh-vehiclesabotage:client:notify', function(message, type, length)
    Notify(message, type, length)
end)

RegisterNetEvent('mh-vehiclesabotage:client:showEffect', function(netid)
    if hasLeaked[netid] and hasLeaked[netid].status then return end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        hasLeaked[netid] = {status = true, coords = GetEntityCoords(vehicle)}
        StartBrakeOilLeak(vehicle)
    end
end)

RegisterNetEvent('mh-vehiclesabotage:client:checkvehicle', function()
    local vehicle = GetVehicleInFrontOfPlayer(PlayerPedId())
    if vehicle ~= nil and vehicle ~= -1 then CheckLine(vehicle) end
end)

RegisterNetEvent('mh-vehiclesabotage:client:UseItem', function(item)
    local vehicle, distance = GetClosestVehicle()
    if vehicle > 0 and distance <= 2.5 then
        TaskTurnPedToFaceEntity(PlayerPedId(), vehicle, 5000)
        Wait(1000)
        local wheel, bone = GetClosestWheel(vehicle)
        if wheel ~= nil then
            if item == config.BrakeLine.Cut.item then
                CutBrakes(NetworkGetNetworkIdFromEntity(vehicle), bone)
            elseif item == config.BrakeLine.Repair.item then
                RepairBrakes(NetworkGetNetworkIdFromEntity(vehicle), bone)
            elseif item == config.BrakeLine.Oil.item then
                RefillBrakeOil(NetworkGetNetworkIdFromEntity(vehicle), bone)
            end
        else
            Notify(Lang:t('info.no_at_possition'), "error", 5000)
        end
    else
        Notify(Lang:t('info.no_vehicle_neerby'), "error", 5000)
    end
end)

CreateThread(function()
    while true do
        if isLoggedIn then
            if IsPedInAnyVehicle(PlayerPedId(), false) and GetVehiclePedIsUsing(PlayerPedId()) ~= 0 then
                local vehicle = GetVehiclePedIsUsing(PlayerPedId())
                if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                    local hasDamage = LineHasDamage(vehicle)
                    if GetBrakeForce(vehicle) == 0.0 then DisableControlAction(0, 76, true) end
                    if hasDamage or Entity(vehicle).state.line_empty then
                        local netid = NetworkGetNetworkIdFromEntity(vehicle)
                        if IsControlJustReleased(0, 72) or IsControlJustReleased(0, 76) then
                            if countBraking < maxBeforeBrakeCount then countBraking = countBraking + 1 end
                        end
                        if countBraking == maxBeforeBrakeCount then
                            countBraking = 0
                            SetBrakeForce(vehicle, 0.0)
                            TriggerServerEvent('mh-vehiclesabotage:server:syncOilEffect', netid)
                        end
                    elseif not hasDamage and not Entity(vehicle).state.line_empty then
                        SetBrakeForce(vehicle, 1.0)
                    end
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if isLoggedIn then
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                local vehicle = GetVehiclePedIsUsing(PlayerPedId())
                if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    for k, v in pairs(hasLeaked) do
                        if v.status and v.coords ~= nil then
                            local distance = GetDistance(v.coords, vehicleCoords)
                            if distance <= 5.0 then LossControl(vehicle) end
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isLoggedIn and disableControll and not PlayerData.metadata['isdead'] then
            sleep = 5
            if IsPauseMenuActive() then SetFrontendActive(false) end
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 38, true)
            EnableControlAction(0, 0, true)
            EnableControlAction(0, 322, true)
            EnableControlAction(0, 288, true)
            EnableControlAction(0, 213, true)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 46, true)
            EnableControlAction(0, 47, true)
        end
        Wait(sleep)
    end
end)