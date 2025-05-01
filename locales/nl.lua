--[[ ===================================================== ]] --
--[[          MH Cutting Brakes Script by MaDHouSe         ]] --
--[[ ===================================================== ]] --
local Translations = {
    info = {
        ['open_shop'] = "Open Tool Shop",
        ['cutting_brakes'] = "Remmen snijden...",
        ['repairing_brakes'] = "Remleiding repareren...",
        ['brakes_has_been_cut'] = "De remmen van het voertuig zijn door gesneden!",
        ['brakes_has_been_repaired'] = "De remmen van het voertuig zijn gerepareerd, ga nu rem vloeistof bijvullen!",
        ['vehicle_has_no_brakes'] = "Dit voertuig heeft geen remmen om door te snijden...",
        ['refuel_brake_oil'] = "Rem vloeistof bijvullen",
        ['brakes_oil_has_refilled'] = "De remolie is bijgevuld",
        ['no_vehicle_neerby'] = "Er is geen voertuig in de buurt...",
        ['no_at_possition'] = "Er is geen voertuig wiel in de buurt...",
        ['shop_not_found'] = "Shop not found..",
        ['wrong_job'] = 'Je bent niet opgeleid als (%{job}) om dit te kunnen doen.',
        ['repair_the_brake_lines_first'] = "Repareer eerst de remleidingen van het voertuig",
        ['brakeline_is_already_broken'] = "This brakeline is already broken",
        ['line_not_broken'] = "Deze remleiding is niet kapot.",
        ['brakeline_is_brakeline'] = "Remleiding is gebroken",
        ['repair_brakeline'] = "Repareer Remleiding",
        ['close'] = "Close",
    },
}

if GetConvar('qb_locale', 'en') == 'nl' then
    Lang = Locale:new({phrases = Translations, warnOnMissing = true, fallbackLang = Lang})
end
