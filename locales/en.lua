--[[ ===================================================== ]] --
--[[          MH Cutting Brakes Script by MaDHouSe         ]] --
--[[ ===================================================== ]] --
local Translations = {
    info = {
        ['open_shop'] = "Open Tool Shop",
        ['cutting_brakes'] = "Cutting brakes...",
        ['repairing_brakes'] = "Repairing brake line...",
        ['brakes_has_been_cut'] = "The vehicle's brakes has been cut!",
        ['brakes_has_been_repaired'] = "The vehicle's brakes have been repaired, refill your brake oil!",
        ['vehicle_has_no_brakes'] = "This vehicle has no brakes to cut...",
        ['refuel_brake_oil'] = "Refill brake oil",
        ['brakes_oil_has_refilled'] = "The Brake oil has been refilled",
        ['no_vehicle_neerby'] = "There is no vehicle nearby",
        ['no_at_possition'] = "There is no vehicle wheel nearby",
        ['shop_not_found'] = "Shop not found..",
        ['wrong_job'] = 'You are not trained as a (%{job}) to be able to do this.',
        ['repair_the_brake_lines_first'] = "Repair the vehicle brake lines first",
        ['brakeline_is_already_broken'] = "This brakeline is already broken",
        ['line_not_broken'] = "This brakeline is not broken.",
        ['brakeline_is_brakeline'] = "Brakeline is broken",
        ['repair_brakeline'] = "Repair Brakeline",
        ['close'] = "Close",
    },
}

if GetConvar('qb_locale', 'en') == 'en' then
    Lang = Locale:new({phrases = Translations, warnOnMissing = true, fallbackLang = Lang})
end
