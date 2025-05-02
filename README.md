<p align="center">
    <img width="140" src="https://icons.iconarchive.com/icons/iconarchive/red-orb-alphabet/128/Letter-M-icon.png" />  
    <h1 align="center">Hi 👋, I'm MaDHouSe</h1>
    <h3 align="center">A passionate allround developer </h3>    
</p>

<p align="center">
    <a href="https://github.com/MaDHouSe79/mh-vehiclesabotage/issues">
        <img src="https://img.shields.io/github/issues/MaDHouSe79/mh-vehiclesabotage"/> 
    </a>
    <a href="https://github.com/MaDHouSe79/mh-vehiclesabotage/watchers">
        <img src="https://img.shields.io/github/watchers/MaDHouSe79/mh-vehiclesabotage"/> 
    </a> 
    <a href="https://github.com/MaDHouSe79/mh-vehiclesabotage/network/members">
        <img src="https://img.shields.io/github/forks/MaDHouSe79/mh-vehiclesabotage"/> 
    </a>  
    <a href="https://github.com/MaDHouSe79/mh-vehiclesabotage/stargazers">
        <img src="https://img.shields.io/github/stars/MaDHouSe79/mh-vehiclesabotage?color=white"/> 
    </a>
    <a href="https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/MaDHouSe79/mh-vehiclesabotage?color=black"/> 
    </a>      
</p>

# My Youtube Channel and Discord
- [Subscribe](https://www.youtube.com/c/@MaDHouSe79) 
- [Discord](https://discord.gg/vJ9EukCmJQ)

# MH Vehicle Sabotage (OneSync Required)
- Sabotage any vehicle brakes, any player that drive this vehicle have no brakes.
- A player can fix the brakes if they have the items that is needed,
- but if you set `SV_Config.UseAsJob` to true, then only players with the job can use and fix it.
- It has 3 items, one for repare, one to cut the brakes, and one to refill the brake oil.

# Dependencies
- [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3)
- [progressbar](https://github.com/qbcore-framework/qb-core/progressbar)
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-inventory](https://github.com/qbcore-framework/qb-core/qb-inventory) (2.0)
- [qb-target](https://github.com/qbcore-framework/qb-target) or [ox_target](https://github.com/overextended/ox_target/releases)
- [qb-minigames](https://github.com/qbcore-framework/qb-core/qb-minigames)

# Inventory Images
![alttext](https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/image/brake_cutter.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/image/brake_line.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/image/brake_oil.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/image/carbom.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/image/tire_knife.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/image/toolbox.png?raw=true)
![alttext](https://github.com/MaDHouSe79/mh-vehiclesabotage/blob/main/image/new_tire.png?raw=true)

# Installation
- Place the folder `mh-vehiclesabotage` in the folder `[mh]`
- Add the shared items in `qb-core/shared/items.lua`
- Add the images from the `mh-vehiclesabotage/images` folder to the `qb-inventory/html/images` folder.
- Add in server.cfg below `ensure [defaultmaps]` add `ensure [mh]`
- Restart your server.

# QB Shared items
```lua
brake_cutter                 = { name = 'brake_cutter', label = 'Brake Cutter', weight = 100, type = 'item', image = 'brake_cutter.png', unique = true, useable = true, shouldClose = true, description = 'A Brake Cutter to cut brake lines' },
brake_line                   = { name = 'brake_line', label = 'Brake Line', weight = 200, type = 'item', image = 'brake_line.png', unique = false, useable = true, shouldClose = true, description = 'A brake line to fix a vehicle brake' },
brake_oil                    = { name = 'brake_oil', label = 'Brake Oil', weight = 500, type = 'item', image = 'brake_oil.png', unique = false, useable = true, shouldClose = true, description = 'To refill your vehicle brake oil' },
carbom                       = { name = 'carbom', label = 'Car Bom', weight = 1000, type = 'item', image = 'carbom.png', unique = true, useable = true, shouldClose = true, description = 'A carbom' },
toolbox                      = { name = 'toolbox', label = 'Toolbox', weight = 1000, type = 'item', image = 'toolbox.png', unique = false, useable = true, shouldClose = true, description = 'Toolbox' },
tire_knife                   = { name = 'tire_knife', label = 'Tire knife', weight = 100, type = 'item', image = 'tire_knife.png', unique = true, useable = true, shouldClose = true, description = 'A Tire knife' },
new_tire                     = { name = 'new_tire', label = 'New Tire', weight = 2500, type = 'item', image = 'new_tire.png', unique = true, useable = true, shouldClose = true, description = 'A new vehicle tire' },
```

# Replace code in `qb-core` (client side)
- in `qb-core/client/functions.lua` around line 396
```lua
function QBCore.Functions.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    TriggerServerEvent('mh-vehiclesabotage:server:unregisterVehicle', NetworkGetNetworkIdFromEntity(vehicle)) -- or add here
    DeleteVehicle(vehicle)
end
```

# Add code for `qb-radialmenu`
- in `qb-radialmenu/client/main.lua` around line 107
```lua
VehicleMenu.items[#VehicleMenu.items + 1] = {
    id = 'check_brakeline',
    title = 'Check Vehicle',
    icon = "check",
    type = 'client',
    event = "mh-vehiclesabotage:client:checkvehicle",
    shouldClose = true
}
```

# LICENSE
[GPL LICENSE](./LICENSE)<br />
&copy; [MaDHouSe79](https://www.youtube.com/@MaDHouSe79)
