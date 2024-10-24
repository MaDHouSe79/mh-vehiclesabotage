<p align="center">
    <img width="140" src="https://icons.iconarchive.com/icons/iconarchive/red-orb-alphabet/128/Letter-M-icon.png" />  
    <h1 align="center">Hi 👋, I'm MaDHouSe</h1>
    <h3 align="center">A passionate allround developer </h3>    
</p>

<p align="center">
    <a href="https://github.com/MaDHouSe79/mh-brakes/issues">
        <img src="https://img.shields.io/github/issues/MaDHouSe79/mh-brakes"/> 
    </a>
    <a href="https://github.com/MaDHouSe79/mh-brakes/watchers">
        <img src="https://img.shields.io/github/watchers/MaDHouSe79/mh-brakes"/> 
    </a> 
    <a href="https://github.com/MaDHouSe79/mh-brakes/network/members">
        <img src="https://img.shields.io/github/forks/MaDHouSe79/mh-brakes"/> 
    </a>  
    <a href="https://github.com/MaDHouSe79/mh-brakes/stargazers">
        <img src="https://img.shields.io/github/stars/MaDHouSe79/mh-brakes?color=white"/> 
    </a>
    <a href="https://github.com/MaDHouSe79/mh-brakes/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/MaDHouSe79/mh-brakes?color=black"/> 
    </a>      
</p>

# My Youtube Channel and Discord
- [Subscribe](https://www.youtube.com/c/@MaDHouSe79) 
- [Discord](https://discord.gg/vJ9EukCmJQ)

# MH Brakes (OneSync Required)
- Cut any vehicle brakes, players that drive this car have no brakes.
- A player can fix the brakes if they have the items that is needed.
- It has 3 items, one for repare, one to cut the brakes, and one to refill the brake oil.

# Installation
- Place the folder `mh-brakes` in the folder `[mh]`
- Add the shared items in `qb-core/shared/items.lua`
- Add the images from the `mh-brakes/images` folder to the `qb-inventory/html/images` folder.
- Add in server.cfg below `ensure [defaultmaps]` add `ensure [mh]`
- Restart your server.

# Server.cfg Example
```conf
# QBCore & Extra stuff
ensure qb-core
ensure mh-cashasitem # if you use mh-cashasitem
ensure mh-brakes # add here if you use mh-brakes
ensure [qb]
ensure [standalone]
ensure [voice]
ensure [defaultmaps]
ensure [mh] # add here.
```

# Inventory Images
![alttext](https://github.com/MaDHouSe79/mh-brakes/blob/main/image/brake_toolbox.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-brakes/blob/main/image/brake_cutter.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-brakes/blob/main/image/brake_line.png?raw=true)


# SQL Database
```sql
CREATE TABLE IF NOT EXISTS `broken_brakes` (
    `id` int(10) NOT NULL AUTO_INCREMENT,
    `plate` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `oil` int(10) NOT NULL DEFAULT 1,
    `wheel_lf` int(10) NOT NULL DEFAULT 0,
    `wheel_rf` int(10) NOT NULL DEFAULT 0,
    `wheel_lm` int(10) NOT NULL DEFAULT 0,
    `wheel_rm` int(10) NOT NULL DEFAULT 0,
    `wheel_lr` int(10) NOT NULL DEFAULT 0,
    `wheel_rr` int(10) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
```

# QB Shared items
```lua
brake_oil                    = { name = 'brake_oil', label = 'Brake Oil', weight = 2500, type = 'item', image = 'brake_oil.png', unique = false, useable = true, shouldClose = true, description = 'To refill your vehicle brake oil' },
brake_toolbox                = { name = 'brake_toolbox', label = 'Toolbox', weight = 2500, type = 'item', image = 'brake_toolbox.png', unique = false, useable = true, shouldClose = true, description = 'A toolbox for vehicle tools' },
brake_cutter                 = { name = 'brake_cutter', label = 'Brake Cutter', weight = 500, type = 'item', image = 'brake_cutter.png', unique = false, useable = true, shouldClose = true, description = 'A Brake Cutter to cut brake lines' },
brake_line                   = { name = 'brake_line', label = 'Brake Line', weight = 200, type = 'item', image = 'brake_line.png', unique = false, useable = true, shouldClose = true, description = 'A brake line to fix a vehicle brake' },
```

# Replace Code `qb-core` (client side)
- in `qb-core/client/functions.lua` arount line 351
```lua
function QBCore.Functions.SpawnVehicle(model, cb, coords, isnetworked, teleportInto)
    local ped = PlayerPedId()
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    isnetworked = isnetworked == nil or isnetworked
    QBCore.Functions.LoadModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    local netid = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(netid, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(model)
    if teleportInto then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
    TriggerServerEvent('mh-brakes:server:checkVehicle', netid) -- Add here
    if cb then cb(veh) end
end
```

# Replace code `qb-inventory` (Server side)
- in `qb-inventory/server/main.lua` around line 329
```lua
QBCore.Functions.CreateCallback('qb-inventory:server:attemptPurchase', function(source, cb, data)
    local itemInfo = data.item
    local amount = data.amount
    local shop = string.gsub(data.shop, 'shop%-', '')
    local price = itemInfo.price * amount
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then
        cb(false)
        return
    end

    local shopInfo = RegisteredShops[shop]
    if not shopInfo then
        cb(false)
        return
    end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if shopInfo.coords then
        local shopCoords = vector3(shopInfo.coords.x, shopInfo.coords.y, shopInfo.coords.z)
        if #(playerCoords - shopCoords) > 10 then
            cb(false)
            return
        end
    end

    if not CanAddItem(source, itemInfo.name, amount) then
        TriggerClientEvent('QBCore:Notify', source, 'Cannot hold item', 'error')
        cb(false)
        return
    end

    if Player.PlayerData.money.cash >= price then
        Player.Functions.RemoveMoney('cash', price, 'shop-purchase')
        if itemInfo.name == 'brake_cutter' then
            TriggerEvent('mh-brakes:server:giveitem', source, 'brake_cutter', amount, price)
        else
            AddItem(source, itemInfo.name, amount, nil, itemInfo.info, 'shop-purchase')
            TriggerEvent('qb-shops:server:UpdateShopItems', shop, itemInfo, amount)
        end
        cb(true)
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have enough money', 'error')
        cb(false)
    end
end)
```

# Replace code `qb-garages` (server side)
- in `qb-garages/client/main.lua` find `qb-garages:client:takeOutGarage` around line 289
```lua
RegisterNetEvent('qb-garages:client:takeOutGarage', function(data)
    QBCore.Functions.TriggerCallback('qb-garages:server:IsSpawnOk', function(spawn)
        if spawn then
            local location = GetSpawnPoint(data.garage)
            if not location then return end
            QBCore.Functions.TriggerCallback('qb-garages:server:spawnvehicle', function(netId, properties, vehPlate)
                while not NetworkDoesNetworkIdExist(netId) do Wait(10) end
                local veh = NetworkGetEntityFromNetworkId(netId)
                Citizen.Await(CheckPlate(veh, vehPlate))
                QBCore.Functions.SetVehicleProperties(veh, properties)
                exports[Config.FuelResource]:SetFuel(veh, data.stats.fuel)
                TriggerServerEvent('qb-garages:server:updateVehicleState', 0, vehPlate)
                TriggerEvent('vehiclekeys:client:SetOwner', vehPlate)
                if Config.Warp then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
                if Config.VisuallyDamageCars then doCarDamage(veh, data.stats, properties) end
                SetVehicleEngineOn(veh, true, true, false)
                TriggerServerEvent('mh-brakes:server:checkVehicle', netId) -- add here
            end, data.plate, data.vehicle, location, true)
        else
            QBCore.Functions.Notify(Lang:t('error.not_depot'), 'error', 5000)
        end
    end, data.plate, data.type)
end)
```

# LICENSE
[GPL LICENSE](./LICENSE)<br />
&copy; [MaDHouSe79](https://www.youtube.com/@MaDHouSe79)