--[[ ====================================================== ]] --
--[[              MH Brakes Script by MaDHouSe              ]] --
--[[ ====================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local vehicles = {}

local function IsAdmin(src)
    if SV_Config.AdminHasAccess then
        if QBCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command') then
            return true
        end
    end
    return false
end

local function IsCorrectItem(item)
    local isCorrect = false
    for k, v in pairs(SV_Config.Items) do
        if v.name == item then
            isCorrect = true
        end
    end
    return isCorrect
end

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

local function RequiredItems(src, item)
    local items = {{
        name = item,
        image = QBCore.Shared.Items[item].image
    }}
    TriggerClientEvent('qb-inventory:client:requiredItems', src, items, true)
    Wait(5000)
    TriggerClientEvent('qb-inventory:client:requiredItems', src, items, false)
end

local function DoesPlateExist(plate)
    local found = false
    local result = MySQL.Sync.fetchAll('SELECT * FROM mh_brakes WHERE plate = ?', {plate})
    if result ~= nil and result[1] ~= nil and result[1].plate ~= nil and result[1].plate == plate then
        found = true
    end
    return found
end

local function GetVehicleData(plate)
    local data = {}
    local result = MySQL.Sync.fetchAll('SELECT * FROM mh_brakes WHERE plate = ?', {plate})
    if result ~= nil and result[1] ~= nil then
        data = result[1]
    end
    return data
end

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

local function ShowEffect(netid)
    if SV_Config.UseOilMarker then
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then
            if Entity(vehicle).state.wheel_lf or Entity(vehicle).state.wheel_rf or Entity(vehicle).state.wheel_lr or
                Entity(vehicle).state.wheel_rr or Entity(vehicle).state.oil_empty then
                TriggerClientEvent('mh-brakes:client:showEffect', -1, netid)
            end
        end
    end
end

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
            Entity(vehicle).state.oil_empty = nil
            Entity(vehicle).state.wheel_lf = nil
            Entity(vehicle).state.wheel_rf = nil
            Entity(vehicle).state.wheel_lr = nil
            Entity(vehicle).state.wheel_rr = nil
            v = nil
        end
    end
end

local function UseItem(src, item)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return
    end
    local canUse = IsCorrectItem(item)
    if not canUse then
        return
    end
    if SV_Config.UseAsJob then
        if Player.PlayerData.job.type == SV_Config.NeededJobType and Player.PlayerData.job.onduty or IsAdmin(src) then
            if Player.Functions.HasItem(item, 1) then
                TriggerClientEvent('mh-brakes:client:UseItem', src, item)
            else
                RequiredItems(src, item)
            end
        else
            TriggerClientEvent('mh-brakes:client:notify', src, Lang:t('info.wrong_job', {
                job = SV_Config.NeededJobType
            }))
        end
    elseif not SV_Config.UseAsJob then
        if Player.Functions.HasItem(item, 1) then
            TriggerClientEvent('mh-brakes:client:UseItem', src, item)
        else
            RequiredItems(src, item)
        end
    end
end

local function CheckVehicle(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local vehicleExist = DoesVehicleExist(vehicle)
        if not vehicleExist then
            local plate = GetVehicleNumberPlateText(vehicle)
            local exist = DoesPlateExist(plate)
            if exist then
                if SV_Config.Debug then print("[mh-brakes] - Create vehicle with broken brakes on plate: " .. plate) end
                AddVehicle(vehicle)
                local vehicleData = GetVehicleData(plate)
                if type(vehicleData) == 'table' then
                    Entity(vehicle).state.wheel_lf = (vehicleData.wheel_lf == 1) or false
                    Entity(vehicle).state.wheel_rf = (vehicleData.wheel_rf == 1) or false
                    Entity(vehicle).state.wheel_lr = (vehicleData.wheel_lr == 1) or false
                    Entity(vehicle).state.wheel_rr = (vehicleData.wheel_rr == 1) or false
                    Entity(vehicle).state.oil_empty = (vehicleData.oil_empty == 1) or false
                    ShowEffect(netid)
                end
                return
            elseif not exist then
                if SV_Config.Debug then print("[mh-brakes] - Create vehicle with good brakes on plate: " .. plate) end
                AddVehicle(vehicle)
                Entity(vehicle).state.oil_empty = false
                Entity(vehicle).state.wheel_lf = false
                Entity(vehicle).state.wheel_rf = false
                Entity(vehicle).state.wheel_lr = false
                Entity(vehicle).state.wheel_rr = false
                return
            end
        end
    end
end

local function UpdateLineData(vehicle, bone, plate, type)
    if not vehicle or not type or not plate then
        return
    end
    local query, data = nil, nil
    if DoesEntityExist(vehicle) then
        if type == "insert" then
            if not bone then
                return
            end
            data = {1, plate, 1}
            if bone == 'wheel_lf' then
                query = "INSERT INTO mh_brakes (wheel_lf, plate, oil_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_lf = true
                Entity(vehicle).state.oil_empty = true
            elseif bone == 'wheel_rf' then
                query = "INSERT INTO mh_brakes (wheel_rf, plate, oil_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_rf = true
                Entity(vehicle).state.oil_empty = true
            elseif bone == 'wheel_lr' then
                query = "INSERT INTO mh_brakes (wheel_lr, plate, oil_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_lr = true
                Entity(vehicle).state.oil_empty = true
            elseif bone == 'wheel_rr' then
                query = "INSERT INTO mh_brakes (wheel_rr, plate, oil_empty) VALUES (?, ?, ?)"
                Entity(vehicle).state.wheel_rr = true
                Entity(vehicle).state.oil_empty = true
            end
            ShowEffect(NetworkGetNetworkIdFromEntity(vehicle))
            goto run
        elseif type == "wrecked" then
            if not bone then
                return
            end
            data = {1, plate}
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
            if not bone then
                return
            end
            data = {0, plate}
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
            data = {plate}
            query = "DELETE FROM mh_brakes WHERE plate = ?"
            Entity(vehicle).state.oil_empty = false
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

RegisterNetEvent('mh-brakes:server:openShop', function(shopId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return
    end
    if SV_Config.Shops[shopId] then
        local shopitems = GetShopItems(shopId)
        exports['qb-inventory']:CreateShop({
            name = 'toolsmarket-' .. shopId,
            label = SV_Config.Shops[shopId].label,
            slots = #shopitems,
            items = shopitems
        })
        exports['qb-inventory']:OpenShop(src, 'toolsmarket-' .. shopId)
    else
        TriggerClientEvent('mh-brakes:client:notify', src, Lang:t('info.shop_not_found'))
    end
end)

RegisterServerEvent("mh-brakes:server:removeItem", function(item)
    local src = source
    if not item then
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return
    end
    local canRemove = IsCorrectItem(item)
    if not canRemove then
        return
    end
    local tmpItem = exports['qb-inventory']:GetItemByName(src, item)
    if tmpItem ~= nil then
        if tmpItem.name == 'brake_cutter' then
            if tmpItem.info ~= nil and tmpItem.info.quality ~= nil then
                local currenItem = Player.PlayerData.items[tmpItem.slot]
                currenItem.info.quality = tmpItem.info.quality - SV_Config.BrakeLine.Cut.ReduseOnUse
                if currenItem.amount <= 0 then
                    currenItem.amount = 0
                end
                Player.Functions.SetInventory(Player.PlayerData.items, true)
            end
        else
            Player.Functions.RemoveItem(tmpItem.name, 1)
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[tmpItem.name], 'remove', 1)
        end
    end
end)

RegisterNetEvent('mh-brakes:server:giveitem', function(source, item, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return
    end
    if item == SV_Config.BrakeLine.Cut.item then
        local current = Player.Functions.GetMoney(Config.MoneyType)
        if current >= price then
            Player.Functions.RemoveMoney(Config.MoneyType, amount)
            local info = {
                quality = SV_Config.BrakeLine.Cut.MaxQuality
            }
            Player.Functions.AddItem(SV_Config.BrakeLine.Cut.item, 1, nil, info)
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[SV_Config.BrakeLine.Cut.item], 'add', 1)
        end
    end
end)

RegisterServerEvent("mh-brakes:server:onjoin", function()
    local src = source
    TriggerClientEvent('mh-brakes:client:onjoin', src, SV_Config.Shops, SV_Config.BrakeLine)
end)

RegisterServerEvent("mh-brakes:server:syncDestroy", function(netid, bone)
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

RegisterServerEvent("mh-brakes:server:syncRepair", function(netid, bone)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local exist = DoesPlateExist(plate)
        if exist then
            UpdateLineData(vehicle, bone, plate, "repair")
        end
    end
end)

RegisterServerEvent("mh-brakes:server:syncFixed", function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        local isALineBroken = IsALineBroken(vehicle)
        if not isALineBroken then
            UpdateLineData(vehicle, nil, plate, "refilled")
        end
    end
end)

RegisterNetEvent('mh-brakes:server:checkVehicle', function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        CheckVehicle(netid)
    end
end)

RegisterNetEvent('mh-brakes:server:registerVehicle', function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local exist = DoesVehicleExist(vehicle)
        if not exist then
            if SV_Config.Debug then print("[^3" .. GetCurrentResourceName() .. "^7] - Register vehicle with plate: "..GetVehicleNumberPlateText(vehicle)) end
            AddVehicle(vehicle)
        end
    end
end)

RegisterNetEvent('mh-brakes:server:unregisterVehicle', function(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local exist = DoesVehicleExist(vehicle)
        if exist then
            if SV_Config.Debug then print("[^3" .. GetCurrentResourceName() .. "^7] - Inregister vehicle with plate: "..GetVehicleNumberPlateText(vehicle)) end
            RemoveVehicle(vehicle)
        end
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
    Wait(5100)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mh_brakes` (
            `id` int(10) NOT NULL AUTO_INCREMENT,
            `plate` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `wheel_lf` int(10) NOT NULL DEFAULT 0,
            `wheel_rf` int(10) NOT NULL DEFAULT 0,
            `wheel_lr` int(10) NOT NULL DEFAULT 0,
            `wheel_rr` int(10) NOT NULL DEFAULT 0,
            `oil_empty` int(10) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`) USING BTREE
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;    
    ]])
end)
