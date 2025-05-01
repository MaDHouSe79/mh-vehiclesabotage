--[[ ====================================================== ]] --
--[[              MH Brakes Script by MaDHouSe              ]] --
--[[ ====================================================== ]] --
SV_Config = {}

SV_Config.Debug = false               -- Shows prints in the server console.
SV_Config.AdminHasAccess = true      -- If true a admin has also access to use the needed items.
SV_Config.UseAsJob = false           -- If true items can only be used when a player has the job, a admin can use it aswell.
SV_Config.NeededJobType = 'mechanic' -- Job needed.
SV_Config.UseOilMarker = true        -- If true when a line is cutted it left a oil mark on t he ground.
SV_Config.MoneyType = 'cash'         -- You can use cash, bank, or if you use mh-cashasitem you can use black_money aswell.
SV_Config.NotifyScript = "k5_notify" -- you can use (qb, k5_notify, okokNotify, Roda_Notifications)
SV_Config.InteractButton = 38        -- E, if you want to change this see: https://docs.fivem.net/docs/game-references/controls/
SV_Config.InteractText = "E"         -- 38, if you want to change this see: https://docs.fivem.net/docs/game-references/controls/
SV_Config.UseMiniGame = true
SV_Config.SkillBarType = 'medium'    -- Use easy, medium, hard.
SV_Config.SkillBarKeys = 'wad'       -- Default 1234 or wad.
SV_Config.UseInventory = false
SV_Config.ImagesBaseFolder = "nui://qb-inventory/html/images/"
SV_Config.MenuScript = "ox_lib"      -- default qb-menu but you can use ox_lib aswell when SV_Config.UseInventory is false

SV_Config.Items = {
    [1] = {name = "brake_cutter", label = 'Brake Cutter', price = 25, amount = 10},
    [2] = {name = "brake_line",  label = 'Brake Line', price = 100, amount = 10},
    [3] = {name = "brake_oil", label = 'Brake Oil', price = 150, amount = 10},
}

SV_Config.Shops = {
    {
        id = 1,
        enable = true, -- if false you need to add the items in qb-shops.
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

SV_Config.BrakeLine = {
    Cut = {
        item = "brake_cutter",
        timer = 10000,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer',
            flags = 1
        },
        maxUse = 4,
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
    Bones = { -- All used wheel bones for text on wheels when this line is broken.
        [1] = 'wheel_lf', -- Left front wheel.
        [2] = 'wheel_rf', -- Right front wheel.
        [3] = 'wheel_lr', -- Left Back wheel.
        [4] = 'wheel_rr'  -- Right Back wheel.
    },
}
