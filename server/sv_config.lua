--[[ ====================================================== ]] --
--[[         MH Vehicle Sabotage Script by MaDHouSe         ]] --
--[[ ====================================================== ]] --
SV_Config = {}

SV_Config.Debug = false              -- Shows prints in the server console.
--
SV_Config.AdminHasAccess = true      -- If true a admin has also access to use the needed items.
--
SV_Config.UseAsJob = false           -- If true items can only be used when a player has the job, a admin can use it aswell.
SV_Config.NeededJobType = 'mechanic' -- Job needed.
--
SV_Config.UseOilMarker = true        -- If true when a line is cutted it left a oil mark on t he ground.
--
SV_Config.MoneyType = 'cash'         -- You can use cash, bank, or if you use mh-cashasitem you can use black_money aswell.
--
SV_Config.NotifyScript = "k5_notify" -- you can use (qb, k5_notify, okokNotify, Roda_Notifications)
--
SV_Config.InteractButton = 38        -- E, if you want to change this see: https://docs.fivem.net/docs/game-references/controls/
SV_Config.InteractText = "E"         -- 38, if you want to change this see: https://docs.fivem.net/docs/game-references/controls/
--
SV_Config.ImagesBaseFolder = "nui://qb-inventory/html/images/"
SV_Config.MenuScript = "ox_lib"      -- default qb-menu but you can use ox_lib aswell when SV_Config.UseInventory is false
--
SV_Config.UseMPH = false             -- Use MPH, default false for kph, when false it uses kph.
SV_Config.SpeedMultiplier = SV_Config.UseMPH and 2.23694 or 3.6

SV_Config.Fontawesome = {
    boss = "fa-solid fa-people-roof",
    pump = "fa-solid fa-gas-pump",
    trucks = "fa-solid fa-truck",
    trailers = "fa-solid fa-trailer",
    garage = "fa-solid fa-warehouse",
    goback = "fa-solid fa-backward-step",
    shop = "fa-solid fa-basket-shopping",
    buy = "fa-solid fa-cash-register",
    stop = "fa-solid fa-stop",
    store = "fa-solid fa-store",
}

SV_Config.Items = {
    [1] = {name = "brake_cutter", label = 'Brake Cutter', price = 25, amount = 1},
    [2] = {name = "brake_line",  label = 'Brake Line', price = 100, amount = 4},
    [3] = {name = "brake_oil", label = 'Brake Oil', price = 150, amount = 1},
    [4] = {name = "carbom", label = 'Car Bom', price = 15000, amount = 1},
    [5] = {name = "tire_knife", label = 'Tire Knife', price = 150, amount = 1},
    [6] = {name = "toolbox", label = 'Toolbox', price = 150, amount = 1},
    [7] = {name = "new_tire", label = 'A new Tire', price = 50, amount = 4},
}

SV_Config.WheelBones = {
    [1] = 'wheel_lf', -- Left front wheel.
    [2] = 'wheel_rf', -- Right front wheel.
    [3] = 'wheel_lr', -- Left Back wheel.
    [4] = 'wheel_rr'  -- Right Back wheel.
}

SV_Config.Shops = {
    {
        id = 1,
        enable = true, -- if false you need to add the items in qb-shops or add it in the crafting bench.
        label = "Tools Shops",
        items = SV_Config.Items,
        ped = {
            model = "A_M_M_ProlHost_01",
            senario = "WORLD_HUMAN_STAND_MOBILE",
            coords = vector4(151.5432, -986.7175, 30.0971, 251.1479),
        },
        blip = {
            enable = true, -- true you see the blip on the map, if false you don't see the blip on the map.
            sprite = 544,  -- if you want to change this see (https://docs.fivem.net/docs/game-references/blips/)
            scale = 0.8,
            colour = 4,    -- if you want to change this see (https://docs.fivem.net/docs/game-references/blips/)
        }
    },
    -- you can add more shops below this, copy the block above this and past it below this and change the coords.
}

SV_Config.VehicleTire = {
    Damage = {
        item = "tire_knife",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
        ReduseOnUse = 5,
        MaxQuality = 100
    },
    Repair = {
        item = "new_tire",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
    },
}

SV_Config.VehicleBom = {
    Add = {
        item = "carbom",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
    },
    Remove = {
        item = "toolbox",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
    },
}

SV_Config.BrakeLine = {
    Bones = SV_Config.WheelBones,
    Cut = {
        item = "brake_cutter",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
        ReduseOnUse = 5,
        MaxQuality = 100
    },
    Repair = {
        item = "brake_line",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
    },
    Oil = {
        item = "brake_oil",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
    },
}