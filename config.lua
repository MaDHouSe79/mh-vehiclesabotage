--[[ ====================================================== ]] --
--[[              MH Brakes Script by MaDHouSe              ]] --
--[[ ====================================================== ]] --
Config = {}                       -- Placeholder don't change or edit this.
Config.BrakeLine = {}             -- Placeholder don't change or edit this.

-- Money Type
Config.MoneyType = 'cash'         -- You can use cash, bank, or if you use mh-cashasitem you can use black_money aswell.

-- Notify Script
Config.NotifyScript = "k5_notify" -- you can use (qb, k5_notify, okokNotify, Roda_Notifications)

-- Interaction
Config.InteractButton = 38        -- E, if you want to change this see: https://docs.fivem.net/docs/game-references/controls/
Config.InteractText = "E"         -- 38, if you want to change this see: https://docs.fivem.net/docs/game-references/controls/

-- SkillBar
Config.UseMiniGame = false
Config.SkillBarType = 'medium'    -- Use easy, medium, hard.
Config.SkillBarKeys = 'wad'       -- Default 1234 or wad.
function UseSkillBar()
    -- if you want you can change the skillbar to a other minigame.
    return exports["qb-minigames"]:Skillbar(Config.SkillBarType, Config.SkillBarKeys)
end
