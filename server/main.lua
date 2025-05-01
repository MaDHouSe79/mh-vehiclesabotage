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

--- Get shop items
---@param shopId number
local function GetShopItems(shopId)
    local shopitems = {}
    for _, item in pairs(SV_Config.Shops[shopId].items) do
        local isCorrect = IsCorrectItem(item.name)
        if isCorrect then
            shopitems[#shopitems + 1] = {
                name = item.name,
                amount = item.amount,
                price = item.price
            }
        end
    end
    return shopitems
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
    local result = MySQL.Sync.fetchAll('SELECT * FROM mh_brakes WHERE plate = ?', { plate })
    if result ~= nil and result[1] ~= nil and result[1].plate ~= nil and result[1].plate == plate then
        found = true
    end
    return found
end

--- Get vehicle data from database
---@param plate string
local function GetVehicleData(plate)
    local data = {}
    local result = MySQL.Sync.fetchAll('SELECT * FROM mh_brakes WHERE plate = ?', { plate })
    if result ~= nil and result[1] ~= nil then
        data = result[1]
    end
    return data
end

--- Checks if a line is broken
---@param vehicle any
local function IsALineBroken(vehicle)
    if Entity(vehicle).state.wheel_lf then
        return true
    elseif Entity(vehicle).state.wheel_rf then
        return true
    elseif Entity(vehicle).state.wheel_lr then
        return true
    elseif Entity(vehicle).state.wheel_rr then
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
        Entity(vehicle).state.line_empty = false
        Entity(vehicle).state.wheel_lf = false
        Entity(vehicle).state.wheel_rf = false
        Entity(vehicle).state.wheel_lr = false
        Entity(vehicle).state.wheel_rr = false
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
    if SV_Config.UseAsJob then
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
                    Entity(vehicle).state.wheel_lf = (vehicleData.wheel_lf == 1) or false
                    Entity(vehicle).state.wheel_rf = (vehicleData.wheel_rf == 1) or false
                    Entity(vehicle).state.wheel_lr = (vehicleData.wheel_lr == 1) or false
                    Entity(vehicle).state.wheel_rr = (vehicleData.wheel_rr == 1) or false
                    Entity(vehicle).state.line_empty = (vehicleData.line_empty == 1) or false
                end
                return
            elseif not exist then
                if SV_Config.Debug then print("[mh-vehiclesabotage] - Create vehicle with good brakes on plate: " .. plate) end
                AddVehicle(vehicle)
                Entity(vehicle).state.line_empty = false
                Entity(vehicle).state.wheel_lf = false
                Entity(vehicle).state.wheel_rf = false
                Entity(vehicle).state.wheel_lr = false
                Entity(vehicle).state.wheel_rr = false
                return
            end
        end
    end
end

--- Update the line data statebag and database
---@param vehicle any
---@param bone any
---@param plate any
---@param type any
local function UpdateLineData(vehicle, bone, plate, type)
    if not vehicle or not type or not plate then return end
    if DoesEntityExist(vehicle) then
        local query, data = nil, nil
        if type == "insert" then
            if not bone then return end
            data = { 1, plate, 1 }
            if bone == 'wheel_lf' then
                query = "INSERT INTO mh_brakes (wheel_lf, plate, line_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_lf = true
                Entity(vehicle).state.line_empty = true
            elseif bone == 'wheel_rf' then
                query = "INSERT INTO mh_brakes (wheel_rf, plate, line_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_rf = true
                Entity(vehicle).state.line_empty = true
            elseif bone == 'wheel_lr' then
                query = "INSERT INTO mh_brakes (wheel_lr, plate, line_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_lr = true
                Entity(vehicle).state.line_empty = true
            elseif bone == 'wheel_rr' then
                query = "INSERT INTO mh_brakes (wheel_rr, plate, line_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_rr = true
                Entity(vehicle).state.line_empty = true
            end
            goto run
        elseif type == "wrecked" then
            if not bone then return end
            data = { 1, plate }
            if bone == 'wheel_lf' then
                query = "UPDATE mh_brakes SET wheel_lf = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_lf = true
                goto run
            elseif bone == 'wheel_rf' then
                query = "UPDATE mh_brakes SET wheel_rf = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_rf = true
                goto run
            elseif bone == 'wheel_lr' then
                query = "UPDATE mh_brakes SET wheel_lr = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_lr = true
                goto run
            elseif bone == 'wheel_rr' then
                query = "UPDATE mh_brakes SET wheel_rr = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_rr = true
                goto run
            end
        elseif type == "repair" then
            if not bone then return end
            data = { 0, plate }
            if bone == 'wheel_lf' then
                query = "UPDATE mh_brakes SET wheel_lf = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_lf = false
                goto run
            elseif bone == 'wheel_rf' then
                query = "UPDATE mh_brakes SET wheel_rf = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_rf = false
                goto run
            elseif bone == 'wheel_lr' then
                query = "UPDATE mh_brakes SET wheel_lr = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_lr = false
                goto run
            elseif bone == 'wheel_rr' then
                query = "UPDATE mh_brakes SET wheel_rr = ? WHERE plate = ?"
                Entity(vehicle).state.wheel_rr = false
                goto run
            end
        elseif type == "refilled" then
            data = { plate }
            query = "DELETE FROM mh_brakes WHERE plate = ?"
            Entity(vehicle).state.line_empty = false
            Entity(vehicle).state.wheel_lf = false
            Entity(vehicle).state.wheel_rf = false
            Entity(vehicle).state.wheel_lr = false
            Entity(vehicle).state.wheel_rr = false
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
            UpdateLineData(vehicle, bone, plate, "insert")
        elseif exist then
            UpdateLineData(vehicle, bone, plate, "wrecked")
        end
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncRepair", function(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local exist = DoesPlateExist(plate)
        if exist then UpdateLineData(vehicle, bone, plate, "repair") end
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncFixed", function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local isALineBroken = IsALineBroken(vehicle)
        if not isALineBroken then UpdateLineData(vehicle, nil, plate, "refilled") end
    end
end)

RegisterServerEvent("mh-vehiclesabotage:server:syncOilEffect", function(netid)
    if SV_Config.UseOilMarker then
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then
            if Entity(vehicle).state.wheel_lf or Entity(vehicle).state.wheel_rf or Entity(vehicle).state.wheel_lr or Entity(vehicle).state.wheel_rr or Entity(vehicle).state.line_empty then
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

CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mh_brakes` (
            `id` int(10) NOT NULL AUTO_INCREMENT,
            `plate` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `wheel_lf` int(10) NOT NULL DEFAULT 0,
            `wheel_rf` int(10) NOT NULL DEFAULT 0,
            `wheel_lr` int(10) NOT NULL DEFAULT 0,
            `wheel_rr` int(10) NOT NULL DEFAULT 0,
            `line_empty` int(10) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`) USING BTREE
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
    ]])
end)