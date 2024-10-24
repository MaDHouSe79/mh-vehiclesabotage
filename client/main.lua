--[[ ====================================================== ]] --
--[[              MH Brakes Script by MaDHouSe              ]] --
--[[ ====================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local peds = {}
local blips = {}
local vehicles = {}
local isLoggedIn = false
local displayBones = true
local canRepair = true
local random = nil
local lastIndex = 0

local function DoesVehicleExist(vehicle)
    local exist = false
    for k, v in pairs(vehicles) do
        if v == vehicle then
            exist = true
        end
    end
    return exist
end

local function AddVehicle(vehicle)
    local exist = DoesVehicleExist(vehicle)
    if not exist then
        vehicles[#vehicles + 1] = vehicle
        Entity(vehicle).state.oil_empty = false
    end
end

local function RemoveVehicle(vehicle)
    for k, v in pairs(vehicles) do
        if v == vehicle then
            v = nil
        end
    end
end

local function Notify(message, type, length)
    local exist = true
    if Config.NotifyScript == "k5_notify" then
        if GetResourceState("k5_notify") ~= 'missing' then
            exports["k5_notify"]:notify("MH Brakes", message, "k5style", length)
        else
            exist = false
        end
    elseif Config.NotifyScript == "okokNotify" then
        if GetResourceState("okokNotify") ~= 'missing' then
            exports['okokNotify']:Alert("MH Brakes", message, length, type)
        else
            exist = false
        end
    elseif Config.NotifyScript == "ox_lib" then
        if GetResourceState("k5_notify") ~= 'missing' then
            lib.notify({
                title = "MH Brakes",
                description = message,
                type = type
            })
        else
            exist = false
        end
    elseif Config.NotifyScript == "Roda_Notifications" then
        if GetResourceState("Roda_Notifications") ~= 'missing' then
            exports['Roda_Notifications']:showNotify("MH Brakes", message, type, length)
        else
            exist = false
        end
    elseif Config.NotifyScript == "qb" then
        QBCore.Functions.Notify({
            text = "MH Brakes",
            caption = message
        }, type, length)
    end
    if not exist then
        QBCore.Functions.Notify({
            text = "MH Brakes",
            caption = message
        }, type, length)
    end
end

local function Draw3DText(x, y, z, txt, font, scale, num)
    local _x, _y, _z = table.unpack(GetGameplayCamCoords())
    local distance = 1 / GetDistanceBetweenCoords(_x, _y, _z, x, y, z, true) * 20
    local value = distance * 1 / GetGameplayCamFov() * 100
    SetTextScale(scale * value, num * value)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(txt)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function RequiredItems(item)
    local items = {{
        name = item,
        image = QBCore.Shared.Items[item].image
    }}
    TriggerEvent('qb-inventory:client:requiredItems', items, true)
    Wait(5000)
    TriggerEvent('qb-inventory:client:requiredItems', items, false)
end

local function LoadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(1)
        end
    end
end

local function DeleteBlips()
    for k, blip in pairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end

local function DeletePeds()
    for k, ped in pairs(peds) do
        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, true, true)
            DeleteEntity(ped)
            DeletePed(ped)
        end
    end
end

local function LoadBlips(shops)
    for k, shop in pairs(shops) do
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

local function CreateShopPed(shops)
    for id, shop in pairs(shops) do
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
            exports['qb-target']:AddTargetEntity(ped, {
                options = {{
                    label = Lang:t('info.open_shop'),
                    icon = 'fa-solid fa-hotel',
                    action = function()
                        TriggerServerEvent('mh-brakes:server:openShop', shop.id)
                    end,
                    canInteract = function(entity, distance, data)
                        return true
                    end
                }},
                distance = 2.0
            })
        end
    end
end

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

local function GetClosestWheel(vehicle)
    local closestWheelIndex = nil
    local closestWheelBone = nil
    if isLoggedIn then
        local playerCoords = GetEntityCoords(PlayerPedId())
        for wheelIndex, wheelBone in pairs(Config.BrakeLine.Bones) do
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

local function StartBrakeOilLeak(vehicle)
    CreateThread(function()
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Wait(1)
        end
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

local function LineHasDamage(vehicle)
    if Entity(vehicle).state.wheel_lf or Entity(vehicle).state.wheel_rf or Entity(vehicle).state.wheel_lr or
        Entity(vehicle).state.wheel_rr then
        return true
    end
    return false
end

local function NoLineDamage(vehicle)
    if not Entity(vehicle).state.wheel_lf and not Entity(vehicle).state.wheel_rf and not Entity(vehicle).state.wheel_lr and
        not Entity(vehicle).state.wheel_rr then
        return true
    end
    return false
end

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

local function SetBrakeForce(vehicle, force)
    SetVehicleHandlingField(vehicle, "CHandlingData", "fBrakeForce", force)
end

local function GetBrakeForce(vehicle)
    return GetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeForce")
end

local function Progressbar(title, item, timer, vehicle, bone, trigger, endMessage, animData)
    QBCore.Functions.Progressbar('mh_brakes', title, timer, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = animData.animation.dict,
        anim = animData.animation.name,
        flags = animData.animation.flag
    }, {}, {}, function()
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent('mh-brakes:server:removeItem', item)
        TriggerServerEvent(trigger, NetworkGetNetworkIdFromEntity(vehicle), bone)
        Notify(endMessage, "success", 5000)
        canRepair = true
        displayBones = true
    end, function()
        ClearPedTasks(PlayerPedId())
        canRepair = true
        displayBones = true
    end)
end

local function CutBrakes(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) and type(Entity(vehicle).state) == 'table' then
        if IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or
            IsThisModelABicycle(GetEntityModel(vehicle)) then
            displayBones = false
            local isBrakelineAlreadyBroken = IsBrakelineAlreadyBroken(vehicle, bone)
            if isBrakelineAlreadyBroken then
                return Notify(Lang:t('info.brakeline_is_already_broken'), "success", 5000)
            elseif not isBrakelineAlreadyBroken then
                local success = exports["qb-minigames"]:Skillbar(Config.SkillBarType, Config.SkillBarKeys)
                if success then
                    Progressbar(Lang:t('info.cutting_brakes'), Config.BrakeLine.Cut.item, Config.BrakeLine.Cut.timer, vehicle, bone, 'mh-brakes:server:syncDestroy', Lang:t('info.brakes_has_been_cut'), Config.BrakeLine.Cut)
                else
                    ClearPedTasks(PlayerPedId())
                    canRepair = true
                    displayBones = true
                end
            end
        else
            Notify(Lang:t('info.vehicle_has_no_brakes'), "error", 5000)
        end
    end
end

local function RepairBrakes(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) and type(Entity(vehicle).state) == 'table' then
        if IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or
            IsThisModelABicycle(GetEntityModel(vehicle)) then
            displayBones = false
            local isLineBroken = IsBrakelineAlreadyBroken(vehicle, bone)
            if not isLineBroken then
                return Notify(Lang:t('info.line_not_broken'), "success", 5000)
            elseif isLineBroken then
                Progressbar(Lang:t('info.repairing_brakes'), Config.BrakeLine.Repair.item, Config.BrakeLine.Repair.timer, vehicle, bone, 'mh-brakes:server:syncRepair', Lang:t('info.brakes_has_been_repaired'), Config.BrakeLine.Repair)
            end
        else
            Notify(Lang:t('info.vehicle_has_no_brakes'), "error", 5000)
        end
    end
end

local function RefillBrakeOil(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) and type(Entity(vehicle).state) == 'table' then
        if IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or
            IsThisModelABicycle(GetEntityModel(vehicle)) then
            displayBones = false
            local noDamage = NoLineDamage(vehicle)
            if not noDamage then
                Notify(Lang:t('info.repair_the_brake_lines_first'), "error", 5000)
            elseif noDamage then
                SetVehicleDoorOpen(vehicle, 4, false, true)
                Progressbar(Lang:t('info.refuel_brake_oil'), Config.BrakeLine.Oil.item, Config.BrakeLine.Oil.timer, vehicle, bone, 'mh-brakes:server:syncFixed', Lang:t('info.brakes_oil_has_refilled'), Config.BrakeLine.Oil)
            end
        else
            Notify(Lang:t('info.vehicle_has_no_brakes'), "error", 5000)
        end
    end
end

local function ShowBones(vehicle)
    if isLoggedIn and displayBones then
        if Config.BrakeLine.Bones ~= nil then
            local textOffset = 0.15
            lastIndex = 0
            local pressTxt, refillTxt = "", ""
            local playerCoords = GetEntityCoords(PlayerPedId())
            for wheelIndex, wheelBone in pairs(Config.BrakeLine.Bones) do
                local wheelBoneIndex = GetEntityBoneIndexByName(vehicle, wheelBone)
                if wheelBoneIndex ~= -1 then
                    local wheels = {}
                    local wheelPos = GetWorldPositionOfEntityBone(vehicle, wheelBoneIndex)
                    local offset = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, wheelBone))
                    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) -
                                         vector3(offset.x, offset.y, offset.z))
                    if QBCore.Functions.HasItem(Config.BrakeLine.Repair.item, 1) then
                        pressTxt = Lang:t('info.repair_brakeline')
                    end
                    if QBCore.Functions.HasItem(Config.BrakeLine.Oil.item, 1) then
                        refillTxt = Lang:t("info.refuel_brake_oil")
                    end
                    if Entity(vehicle).state.wheel_lf and wheelBone == 'wheel_lf' then
                        wheels[#wheels + 1] = {
                            index = wheelIndex,
                            bone = Lang:t('info.brakeline_is_brakeline'),
                            color = "~r~"
                        }
                    end
                    if Entity(vehicle).state.wheel_rf and wheelBone == 'wheel_rf' then
                        wheels[#wheels + 1] = {
                            index = wheelIndex,
                            bone = Lang:t('info.brakeline_is_brakeline'),
                            color = "~r~"
                        }
                    end
                    if Entity(vehicle).state.wheel_lr and wheelBone == 'wheel_lr' then
                        wheels[#wheels + 1] = {
                            index = wheelIndex,
                            bone = Lang:t('info.brakeline_is_brakeline'),
                            color = "~r~"
                        }
                    end
                    if Entity(vehicle).state.wheel_rr and wheelBone == 'wheel_rr' then
                        wheels[#wheels + 1] = {
                            index = wheelIndex,
                            bone = Lang:t('info.brakeline_is_brakeline'),
                            color = "~r~"
                        }
                    end
                    if wheelBone == 'wheel_lr' or wheelBone == 'wheel_rr' then
                        textOffset = 0.02
                    end
                    if #wheels >= 1 then
                        for k, wheel in pairs(wheels) do
                            if distance < 1.5 then
                                lastIndex = wheel.index
                                if canRepair then
                                    Draw3DText(offset.x, offset.y, offset.z + textOffset * wheel.index, pressTxt, 4, 0.06, 0.06)
                                else
                                    Draw3DText(offset.x, offset.y, offset.z + textOffset * wheel.index, wheel.color .. wheel.bone, 4, 0.06, 0.06)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ShowBrakeOilRefillTxt(vehicle)
    if isLoggedIn and displayBones then
        local lineHasDamage = LineHasDamage(vehicle)
        if lineHasDamage then
            canRepair = false
        end
        local playerCoords = GetEntityCoords(PlayerPedId())
        local textOffset = 0.15
        local lines = {'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr'}
        if random == nil then
            random = lines[math.random(1, #lines)]
        end
        local lf = IsBrakelineAlreadyBroken(vehicle, 'wheel_lf')
        local rf = IsBrakelineAlreadyBroken(vehicle, 'wheel_rf')
        local lr = IsBrakelineAlreadyBroken(vehicle, 'wheel_lr')
        local rr = IsBrakelineAlreadyBroken(vehicle, 'wheel_rr')
        local refillTxt = ""
        if canRepair and not lineHasDamage then
            if QBCore.Functions.HasItem("brake_oil", 1) then
                refillTxt = Lang:t("info.refuel_brake_oil")
            end
            local offset = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, random))
            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(offset.x, offset.y, offset.z))
            if distance < 1.5 then
                Draw3DText(offset.x, offset.y, offset.z + textOffset * lastIndex, "~o~" .. refillTxt, 4, 0.06, 0.06)
            end
        end
    end
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
    if resource == GetCurrentResourceName() then
        PlayerData = QBCore.Functions.GetPlayerData()
        isLoggedIn = true
        TriggerServerEvent('mh-brakes:server:onjoin')
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    TriggerServerEvent('mh-brakes:server:onjoin')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
    DeletePeds()
    DeleteBlips()
end)

RegisterNetEvent('mh-brakes:client:notify', function(message, type, length)
    Notify(message, type, length)
end)

RegisterNetEvent('mh-brakes:client:onjoin', function(shops, brakeLine)
    Config.BrakeLine = brakeLine
    CreateShopPed(shops)
    LoadBlips(shops)
end)

RegisterNetEvent('mh-brakes:client:showEffect', function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        StartBrakeOilLeak(vehicle)
    end
end)

RegisterNetEvent('mh-brakes:client:UseItem', function(item)
    local vehicle, distance = GetClosestVehicle()
    if vehicle > 0 and distance <= 2.5 then
        TaskTurnPedToFaceEntity(PlayerPedId(), vehicle, 5000)
        Wait(1000)
        local wheel, bone = GetClosestWheel(vehicle)
        if wheel ~= nil then
            if item == Config.BrakeLine.Cut.item then
                CutBrakes(NetworkGetNetworkIdFromEntity(vehicle), bone)
            elseif item == Config.BrakeLine.Repair.item then
                RepairBrakes(NetworkGetNetworkIdFromEntity(vehicle), bone)
            elseif item == Config.BrakeLine.Oil.item then
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
            local vehicle, distance = GetClosestVehicle()
            if vehicle > 0 and distance <= 2.5 then
                local hasDamage = LineHasDamage(vehicle)
                if hasDamage and not IsPedInAnyVehicle(PlayerPedId(), false) then
                    ShowBones(vehicle)
                elseif not hasDamage and not IsPedInAnyVehicle(PlayerPedId(), false) then
                    if Entity(vehicle).state.oil_empty then
                        ShowBrakeOilRefillTxt(vehicle)
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
                if GetVehiclePedIsUsing(PlayerPedId()) ~= 0 then
                    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
                    if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                        local hasDamage = LineHasDamage(vehicle)
                        if lineHasDamage or Entity(vehicle).state.oil_empty then
                            SetBrakeForce(vehicle, 0.0)
                        elseif not hasDamage and not Entity(vehicle).state.oil_empty then
                            SetBrakeForce(vehicle, 1.0)
                        end
                        if GetBrakeForce(vehicle) == 0.0 then
                            DisableControlAction(0, 76, true)
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
        if isLoggedIn then
            if IsPedInAnyVehicle(PlayerPedId(), true) then
                local vehicle = GetVehiclePedIsUsing(PlayerPedId())
                if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                    if Entity(vehicle).state.oil_empty == nil then
                        print("[^3" .. GetCurrentResourceName() .. "^7] - Register new vehicle....")
                        TriggerServerEvent('mh-brakes:server:registerVehicle', NetworkGetNetworkIdFromEntity(vehicle))
                    end
                end
            end
        end
        Wait(1000)
    end
end)
