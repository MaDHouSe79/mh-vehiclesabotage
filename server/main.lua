--[[ ====================================================== ]] --
--[[         MH Vehicle Sabotage Script by MaDHouSe         ]] --
--[[ ====================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local vehicles = {}

--- Check if a player is a admin
---@param src number
local function IsAdmin(src)
    if SV_Config.AdminHasAccess then
        if QBCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command') then
            return true
        end
    end
    return false
end

--- Checks if the used item is a correct item.
---@param item string
local function IsCorrectItem(item)
    local isCorrect = false
    for k, v in pairs(SV_Config.Items) do
        if v.name == item then
            isCorrect = true
        end
    end
    return isCorrect
end

--- Display ther required items
---@param src number
---@param item string
local function RequiredItems(src, item)
    local items = { { name = item, image = QBCore.Shared.Items[item].image } }
    TriggerClientEvent('qb-inventory:client:requiredItems', src, items, true)
    Wait(5000)
    TriggerClientEvent('qb-inventory:client:requiredItems', src, items, false)
end

--- Check if a plate exist
---@param plate any
local function DoesPlateExist(plate)
    local found = false
    local result = MySQL.Sync.fetchAll('SELECT * FROM mh_vehicle_sabotage WHERE plate = ?', { plate })
    if result ~= nil and result[1] ~= nil and result[1].plate ~= nil and result[1].plate == plate then
        found = true
    end
    return found
end

--- Get vehicle data from database
---@param plate string
local function GetVehicleData(plate)
    local data = {}
    local result = MySQL.Sync.fetchAll('SELECT * FROM mh_vehicle_sabotage WHERE plate = ?', { plate })
    if result ~= nil and result[1] ~= nil then
        data = result[1]
    end
    return data
end

--- Checks if a line is broken
---@param vehicle any
local function IsALineBroken(vehicle)
    if Entity(vehicle).state.brakeline_lf then
        return true
    elseif Entity(vehicle).state.brakeline_rf then
        return true
    elseif Entity(vehicle).state.brakeline_lr then
        return true
    elseif Entity(vehicle).state.brakeline_rr then
        return true
    end
    return false
end

--- Checks if a line is broken
---@param vehicle any
local function HasTireDamage(vehicle)
    if Entity(vehicle).state.tire_lf then
        return true
    elseif Entity(vehicle).state.tire_rf then
        return true
    elseif Entity(vehicle).state.tire_lr then
        return true
    elseif Entity(vehicle).state.tire_rr then
        return true
    elseif Entity(vehicle).state.tire_damage then
        return true
    end
    return false
end

--- Does vehicle exist in the list
---@param vehicle entity
local function DoesVehicleExist(vehicle)
    local exist = false
    for k, v in pairs(vehicles) do
        if v == vehicle then
            exist = true
        end
    end
    return exist
end

--- Add vehicle to list
---@param vehicle entity
local function AddVehicle(vehicle)
    local exist = DoesVehicleExist(vehicle)
    if not exist then
        vehicles[#vehicles + 1] = vehicle
        Entity(vehicle).state.brakeline_damage = false
        Entity(vehicle).state.brakeline_lf = false
        Entity(vehicle).state.brakeline_rf = false
        Entity(vehicle).state.brakeline_lr = false
        Entity(vehicle).state.brakeline_rr = false
        Entity(vehicle).state.tire_damage = false
        Entity(vehicle).state.tire_lf = false
        Entity(vehicle).state.tire_rf = false
        Entity(vehicle).state.tire_lr = false
        Entity(vehicle).state.tire_rr = false
    end
end

--- Use Item
---@param src number
---@param item string
local function UseItem(src, item)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local canUse = IsCorrectItem(item)
    if not canUse then return end
    if SV_Config.UseAsJob and item ~= 'carbom' then
        if Player.PlayerData.job.type == SV_Config.NeededJobType and Player.PlayerData.job.onduty or IsAdmin(src) then
            if Player.Functions.HasItem(item, 1) then
                TriggerClientEvent('mh-vehiclesabotage:client:UseItem', src, item)
            else
                RequiredItems(src, item)
            end
        else
            TriggerClientEvent('mh-vehiclesabotage:client:notify', src, Lang:t('info.wrong_job', {job = SV_Config.NeededJobType}))
        end
    elseif not SV_Config.UseAsJob then
        if Player.Functions.HasItem(item, 1) then
            TriggerClientEvent('mh-vehiclesabotage:client:UseItem', src, item)
        else
            RequiredItems(src, item)
        end
    end
end

--- Check vehicle and add data to the vehicle.
---@param netid number
local function CheckVehicle(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local vehicleExist = DoesVehicleExist(vehicle)
        if not vehicleExist then
            local plate = GetVehicleNumberPlateText(vehicle)
            local exist = DoesPlateExist(plate)
            if exist then
                if SV_Config.Debug then print("[mh-vehiclesabotage] - Create vehicle with broken brakes on plate: " .. plate) end
                AddVehicle(vehicle)
                local vehicleData = GetVehicleData(plate)
                if type(vehicleData) == 'table' then
                    Entity(vehicle).state.brakeline_lf = (vehicleData.brakeline_lf == 1) or false
                    Entity(vehicle).state.brakeline_rf = (vehicleData.brakeline_rf == 1) or false
                    Entity(vehicle).state.brakeline_lr = (vehicleData.brakeline_lr == 1) or false
                    Entity(vehicle).state.brakeline_rr = (vehicleData.brakeline_rr == 1) or false
                    Entity(vehicle).state.brakeline_damage = (vehicleData.brakeline_damage == 1) or false
                    Entity(vehicle).state.tire_lf = (vehicleData.tire_lf == 1) or false
                    Entity(vehicle).state.tire_rf = (vehicleData.tire_rf == 1) or false
                    Entity(vehicle).state.tire_lr = (vehicleData.tire_lr == 1) or false
                    Entity(vehicle).state.tire_rr = (vehicleData.tire_rr == 1) or false
                    Entity(vehicle).state.tire_damage = (vehicleData.tire_damage == 1) or false
                end
                return
            elseif not exist then
                if SV_Config.Debug then print("[mh-vehiclesabotage] - Create vehicle with good brakes on plate: " .. plate) end
                AddVehicle(vehicle)
                return
            end
        end
    end
end

local function UpdateVehicleState(vehicle, bone, type, state)
    if not bone then return end
    if bone == "wheel_lf" then     -- Left front wheel.
        if type == "brakeline_lf" then -- Brakeline
            Entity(vehicle).state.brakeline_damage = state
            Entity(vehicle).state.brakeline_lf = state
        elseif type == "tire_lf" then -- Tire 
            Entity(vehicle).state.tire_damage = state
            Entity(vehicle).state.tire_lf = state
        end
    elseif bone == "wheel_rf" then -- Right front wheel.
        if type == "brakeline_rf" then -- Brakelinee
            Entity(vehicle).state.brakeline_damage = state
            Entity(vehicle).state.brakeline_rf = state
        elseif type == "tire_rf" then -- Tire
            Entity(vehicle).state.tire_damage = state
            Entity(vehicle).state.tire_rf = state
        end
    elseif bone == "wheel_lr" then -- Left Back wheel.
        if type == "brakeline_lr" then  -- Brakeline
            Entity(vehicle).state.brakeline_damage = state
            Entity(vehicle).state.brakeline_lr = state
        elseif type == "tire_lr" then -- Tire
            Entity(vehicle).state.tire_damage = state
            Entity(vehicle).state.tire_lr = state
        end
    elseif bone == "wheel_rr" then -- Right Back wheel.
        if type == "brakeline_rr" then  -- Brakeline 
            Entity(vehicle).state.brakeline_damage = state
            Entity(vehicle).state.brakeline_rr = state
        elseif type == "tire_rr" then -- Tire
            Entity(vehicle).state.tire_damage = state
            Entity(vehicle).state.tire_rr = state
        end
    end
end

--- Update the line data statebag and database
---@param vehicle any
---@param bone any
---@param plate any
---@param type any
local function UpdateData(vehicle, bone, plate, type)
    if not vehicle or not type or not plate then return end
    if DoesEntityExist(vehicle) then
        local query, data = nil, nil
        if type == "insert" then
            if not bone then return end
            data = { 1, plate, 1 }
            if bone == 'wheel_lf' then
                query = "INSERT INTO mh_vehicle_sabotage (brakeline_lf, plate, brakeline_damage) VALUES (?, ?, ?)"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_lf", true)
            elseif bone == 'wheel_rf' then
                query = "INSERT INTO mh_vehicle_sabotage (brakeline_rf, plate, brakeline_damage) VALUES (?, ?, ?)"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_rf", true)
            elseif bone == 'wheel_lr' then
                query = "INSERT INTO mh_vehicle_sabotage (brakeline_lr, plate, brakeline_damage) VALUES (?, ?, ?)"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_lr", true)
            elseif bone == 'wheel_rr' then
                query = "INSERT INTO mh_vehicle_sabotage (brakeline_rr, plate, brakeline_damage) VALUES (?, ?, ?)"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_rr", true)
            end
            goto run
        elseif type == "wrecked" then
            if not bone then return end
            data = { 1, plate }
            if bone == 'wheel_lf' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_lf = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_lf", true)
                goto run
            elseif bone == 'wheel_rf' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_rf = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_rf", true)
                goto run
            elseif bone == 'wheel_lr' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_lr = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_lr", true)
                goto run
            elseif bone == 'wheel_rr' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_rr = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rf", "brakeline_rr", true)
                goto run
            end
        elseif type == "repair" then
            if not bone then return end
            data = { 0, plate }
            if bone == 'wheel_lf' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_lf = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lf", "brakeline_lf", false)
                goto run
            elseif bone == 'wheel_rf' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_rf = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lf", "brakeline_rf", false)
                goto run
            elseif bone == 'wheel_lr' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_lr = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lf", "brakeline_lr", false)
                goto run
            elseif bone == 'wheel_rr' then
                query = "UPDATE mh_vehicle_sabotage SET brakeline_rr = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lf", "brakeline_rr", false)
                goto run
            end
        elseif type == "refilled" then
            data = { plate }
            query = "DELETE FROM mh_vehicle_sabotage WHERE plate = ?"
            UpdateVehicleState(vehicle, "wheel_lf", "brakeline_lf", false)
            UpdateVehicleState(vehicle, "wheel_rf", "brakeline_rf", false)
            UpdateVehicleState(vehicle, "wheel_lr", "brakeline_lr", false)
            UpdateVehicleState(vehicle, "wheel_rr", "brakeline_rr", false)
            goto run

        elseif type == "damagetire" then
            if not bone then return end
            data = {1, 1, plate}
            if bone == 'wheel_lf' then
                query = "UPDATE mh_vehicle_sabotage SET tire_lf = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lf", "tire_lf", true)
            elseif bone == 'wheel_rf' then
                query = "UPDATE mh_vehicle_sabotage SET tire_rf = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rf", "tire_rf", true)
            elseif bone == 'wheel_lr' then
                query = "UPDATE mh_vehicle_sabotage SET tire_lr = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lr", "tire_lr", true)
            elseif bone == 'wheel_rr' then
                query = "UPDATE mh_vehicle_sabotage SET tire_rr = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rr", "tire_rr", true)
            end
            goto run
        elseif type == "repairtire" then
            if not bone then return end
            data = {0, 1, plate}
            if bone == 'wheel_lf' then
                query = "UPDATE mh_vehicle_sabotage SET tire_lf = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lf", "tire_lf", false)
            elseif bone == 'wheel_rf' then
                query = "UPDATE mh_vehicle_sabotage SET tire_rf = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rf", "tire_rf", false)
            elseif bone == 'wheel_lr' then
                query = "UPDATE mh_vehicle_sabotage SET tire_lr = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_lr", "tire_lr", false)
            elseif bone == 'wheel_rr' then
                query = "UPDATE mh_vehicle_sabotage SET tire_rr = ?, tire_damage = ? WHERE plate = ?"
                UpdateVehicleState(vehicle, "wheel_rr", "tire_rr", false)
            end
            goto run
        end
        ::run::
        if query ~= nil and data ~= nil then
            MySQL.Async.execute(query, data)
        end
    end
end

RegisterServerEvent("mh-vehiclesabotage:server:removeItem", function(item)
    local src = source
    if not item then return end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local canRemove = IsCorrectItem(item)
    if not canRemove then return end
    local tmpItem = exports['qb-inventory']:GetItemByName(src, item)
    if tmpItem ~= nil then
        if tmpItem.name == 'brake_cutter' then
            if tmpItem.info ~= nil and tmpItem.info.quality ~= nil then
                local currenItem = Player.PlayerData.items[tmpItem.slot]
                currenItem.info.quality = tmpItem.info.quality - SV_Config.BrakeLine.Cut.ReduseOnUse
                if currenItem.amount <= 0 then currenItem.amount = 0 end
                Player.Functions.SetInventory(Player.PlayerData.items, true)
            end
        elseif tmpItem.name == 'tire_knife' then
            if tmpItem.info ~= nil and tmpItem.info.quality ~= nil then
                local currenItem = Player.PlayerData.items[tmpItem.slot]
                currenItem.info.quality = tmpItem.info.quality - SV_Config.VehicleTire.Damage.ReduseOnUse
                if currenItem.amount <= 0 then currenItem.amount = 0 end
                Player.Functions.SetInventory(Player.PlayerData.items, true)
            end
        else
            Player.Functions.RemoveItem(tmpItem.name, 1)
            if GetResourceState("qb-inventory") ~= 'missing' then
                TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[tmpItem.name], 'remove', 1)
            end
        end
    end
end)

RegisterNetEvent('mh-vehiclesabotage:server:giveitem', function(data)
    local tmpData = nil
    if type(data) == 'table' then if data.data ~= nil then tmpData = data.data else tmpData = data end end
    local src = tmpData.src
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local price = tmpData.price * tmpData.amount
    local current = Player.Functions.GetMoney(SV_Config.MoneyType)
    if current >= price then
        Player.Functions.RemoveMoney(SV_Config.MoneyType, price)
        if tmpData.name == SV_Config.BrakeLine.Cut.item then
            Player.Functions.AddItem(tmpData.name, tmpData.amount, nil, { quality = SV_Config.BrakeLine.Cut.MaxQuality })
        elseif tmpData.name == SV_Config.VehicleTire.Damage.item then
            Player.Functions.AddItem(tmpData.name, tmpData.amount, nil, { quality = SV_Config.VehicleTire.Damage.MaxQuality })
        else
            Player.Functions.AddItem(tmpData.name, tmpData.amount, nil, nil)
        end
        if GetResourceState("qb-inventory") ~= 'missing' then
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[tmpData.name], 'add', data.amount)
        end
    else
        TriggerClientEvent('mh-vehiclesabotage:client:notify', src, "you have no money....")
    end
end)

QBCore.Functions.CreateCallback("mh-vehiclesabotage:server:OnJoin", function(source, cb)
    cb({status = true, config = SV_Config})
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncDestroy", function(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local exist = DoesPlateExist(plate)
        if not exist then
            UpdateData(vehicle, bone, plate, "insert")
        elseif exist then
            UpdateData(vehicle, bone, plate, "wrecked")
        end
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncAddSpeedBom", function(netid, value)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        Entity(vehicle).state.exploded = false
        Entity(vehicle).state.hasBom = true
        Entity(vehicle).state.speed = value
        Entity(vehicle).state.timed = false
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncAddTimedBom", function(netid, value)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        Entity(vehicle).state.exploded = false
        Entity(vehicle).state.hasBom = true
        Entity(vehicle).state.timed = value
        Entity(vehicle).state.speed = false
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncVehicleExploded", function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        Entity(vehicle).state.exploded = true
        Entity(vehicle).state.hasBom = false
        Entity(vehicle).state.timed = false
        Entity(vehicle).state.speed = false
    end
end)

RegisterNetEvent("mh-vehiclesabotage:server:syncDamageTire", function(netid, bone)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local exist = DoesPlateExist(plate)
        if not exist then CheckVehicle(src, vehicle) end
        local hasTireDamage = HasTireDamage(vehicle, bone)
        if hasTireDamage then
            Notify(src, "This tire is already damages...")
        elseif not hasTireDamage then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player.Functions.HasItem("tire_knife", 1) then
                UpdateData(vehicle, bone, plate, "damagetire")
            else
                Notify(src, "You don't have a tire knife...")
            end
        end
    end
end)

RegisterNetEvent("mh-vehiclesabotage:server:syncRepairTire", function(netid, bone)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local exist = DoesPlateExist(plate)
        if exist then
            local hasTireDamage = HasTireDamage(vehicle, bone)
            if not hasTireDamage then
                Notify(src, "This tire is fine...")
            elseif hasTireDamage then
                local Player = QBCore.Functions.GetPlayer(src)
                if Player then
                    if Player.Functions.HasItem(SV_Config.VehicleTire.Repair.item, 1) then
                        UpdateData(vehicle, bone, plate, "repairtire")
                    else
                        Notify(src, "You don't have a tire...")
                    end
                end
            end
        end
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncRepairBrakes", function(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local exist = DoesPlateExist(plate)
        if exist then UpdateData(vehicle, bone, plate, "repair") end
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncRefillBrakeOil", function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local isALineBroken = IsALineBroken(vehicle)
        if not isALineBroken then UpdateData(vehicle, nil, plate, "refilled") end
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncOilEffect", function(netid)
    if SV_Config.UseOilMarker then
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then
            if Entity(vehicle).state.brakeline_lf or Entity(vehicle).state.brakeline_rf or Entity(vehicle).state.brakeline_lr or Entity(vehicle).state.brakeline_rr or Entity(vehicle).state.brakeline_damage then
                TriggerClientEvent('mh-vehiclesabotage:client:showEffect', -1, netid)
            end
        end
    end
end)

RegisterNetEvent("baseevents:enteredVehicle", function(currentVehicle, currentSeat, vehicleDisplayName, netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local playerName = GetPlayerName(src)
        if SV_Config.Debug then
            print("[^3" .. GetCurrentResourceName() .. "^7] - Player " .. playerName .. " Entered Vehicle: " .. vehicleDisplayName .. " Seat: " .. currentSeat .. " Entity: " .. currentVehicle .. " Netid:" .. netId)
        end
        CheckVehicle(netId)
    end
end)

RegisterNetEvent('baseevents:leftVehicle', function(currentVehicle, currentSeat, vehicleDisplayName, netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local playerName = GetPlayerName(src)
        if SV_Config.Debug then
            print("[^3" .. GetCurrentResourceName() .. "^7] - Player " .. playerName .. " Left Vehicle: " .. vehicleDisplayName .. " Seat: " .. currentSeat .. " Entity: " .. currentVehicle .. " Netid:" .. netId)
        end
        CheckVehicle(netid)
    end
end)

AddEventHandler('entityCreated', function(entity)
    Wait(2000)
    if DoesEntityExist(entity) and GetEntityPopulationType(entity) == 7 and GetEntityType(entity) == 2 then
        CheckVehicle(NetworkGetNetworkIdFromEntity(entity))
    end
end)

QBCore.Functions.CreateUseableItem(SV_Config.BrakeLine.Cut.item, function(source, item)
    local src = source
    UseItem(src, SV_Config.BrakeLine.Cut.item)
end)

QBCore.Functions.CreateUseableItem(SV_Config.BrakeLine.Repair.item, function(source, item)
    local src = source
    UseItem(src, SV_Config.BrakeLine.Repair.item)
end)

QBCore.Functions.CreateUseableItem(SV_Config.BrakeLine.Oil.item, function(source, item)
    local src = source
    UseItem(src, SV_Config.BrakeLine.Oil.item)
end)

QBCore.Functions.CreateUseableItem(SV_Config.VehicleBom.Add.item, function(source, item)
    local src = source
    UseItem(src, SV_Config.VehicleBom.Add.item)
end)

QBCore.Functions.CreateUseableItem(SV_Config.VehicleBom.Remove.item, function(source, item)
    local src = source
    UseItem(src, SV_Config.VehicleBom.Remove.item)
end)

QBCore.Functions.CreateUseableItem(SV_Config.VehicleTire.Damage.item, function(source, item)
    local src = source
    UseItem(src, SV_Config.VehicleTire.Damage.item)
end)

QBCore.Functions.CreateUseableItem(SV_Config.VehicleTire.Repair.item, function(source, item)
    local src = source
    UseItem(src, SV_Config.VehicleTire.Repair.item)
end)

CreateThread(function()
    MySQL.Async.execute('DROP TABLE IF EXISTS mh_brakes')
    Wait(100)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mh_vehicle_sabotage` (
            `id` int(10) NOT NULL AUTO_INCREMENT,
            `plate` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `brakeline_lf` int(10) NOT NULL DEFAULT 0,
            `brakeline_rf` int(10) NOT NULL DEFAULT 0,
            `brakeline_lr` int(10) NOT NULL DEFAULT 0,
            `brakeline_rr` int(10) NOT NULL DEFAULT 0,
            `brakeline_damage` int(10) NOT NULL DEFAULT 0,
            `tire_lf` int(10) NOT NULL DEFAULT 0,
            `tire_rf` int(10) NOT NULL DEFAULT 0,
            `tire_lr` int(10) NOT NULL DEFAULT 0,
            `tire_rr` int(10) NOT NULL DEFAULT 0,
            `tire_damage` int(10) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`) USING BTREE
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
    ]])
end)