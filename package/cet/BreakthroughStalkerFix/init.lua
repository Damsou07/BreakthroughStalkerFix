-- Candidat 0.1.0 : Cyberpunk 2077 2.5, CET 1.38.0 ; validation en jeu requise.
-- Révision de ciblage : enregistrement observé sur l'arme équipée par l'utilisateur.
-- Une seule propriété visuelle est modifiée ; aucun paramètre balistique.
local targetRecord = "Items.Uncommon_Nekomata_Breakthrough"
local donorRecord = "Items.Preset_Omaha_Suzie"
local targetFlat = targetRecord .. ".previewEffectTag"
local originalValue = nil
local appliedValue = nil

local function report(message)
    print("[BreakthroughStalkerFix] " .. message)
end

local function restore()
    if originalValue == nil then return end
    -- Ne pas écraser une valeur différente appliquée depuis par un autre mod.
    local current = TweakDB:GetFlat(targetFlat)
    if current ~= nil and appliedValue ~= nil and current.value == appliedValue.value then
        if not TweakDB:SetFlat(targetFlat, originalValue) or not TweakDB:Update(targetRecord) then
            report("Échec du retrait en mémoire ; quitter complètement le jeu.")
            return
        end
        report("Valeur initiale restaurée.")
    else
        report("Retrait ignoré : valeur modifiée par une autre source.")
    end
    originalValue = nil
    appliedValue = nil
end

registerForEvent("onInit", function()
    local version = GetVersion()
    if version ~= "v1.38.0" and version ~= "1.38.0" then
        report("Version CET non validée : " .. tostring(version) .. ". Aucune modification.")
        return
    end
    if originalValue ~= nil then return end
    local target = TweakDB:GetRecord(targetRecord)
    local donor = TweakDB:GetRecord(donorRecord)
    if target == nil or donor == nil then
        report("Enregistrement absent. Aucune modification.")
        return
    end
    local previous = TweakDB:GetFlat(targetFlat)
    local replacement = TweakDB:GetFlat(donorRecord .. ".previewEffectTag")
    local targetName = TweakDB:GetFlat(targetRecord .. ".previewEffectName")
    local donorName = TweakDB:GetFlat(donorRecord .. ".previewEffectName")
    if previous == nil or replacement == nil or targetName == nil or donorName == nil
        or previous.value ~= "ricochet" or replacement.value ~= "pierce"
        or targetName.value ~= "weaponPreview" or donorName.value ~= "weaponPreview" then
        report("Préconditions différentes des données étudiées. Aucune modification.")
        return
    end
    -- Réutilisation du CName existant de Lizzie, sans créer de type ni d'enregistrement.
    originalValue = previous
    appliedValue = replacement
    if not TweakDB:SetFlat(targetFlat, replacement) or not TweakDB:Update(targetRecord) then
        report("Échec d'application ; tentative de restauration.")
        restore()
        return
    end
    local actual = TweakDB:GetFlat(targetFlat)
    if actual == nil or actual.value ~= "pierce" or target:PreviewEffectTag().value ~= "pierce" then
        report("Échec de relecture ; tentative de restauration.")
        restore()
        return
    end
    report("Candidat actif : " .. targetRecord .. " previewEffectTag ricochet -> pierce. Test en jeu requis.")
end)

registerForEvent("onShutdown", restore)
