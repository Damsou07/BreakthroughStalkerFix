import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {lua, lauxlib, lualib, to_luastring, to_jsstring} from 'fengari';

const mod = fs.readFileSync('package/cet/BreakthroughStalkerFix/init.lua','utf8');
const setup = `
local target = "Items.Uncommon_Nekomata_Breakthrough"
local donor = "Items.Preset_Omaha_Suzie"
local preset = "Items.Preset_Nekomata_Breakthrough"
local flat = target .. ".previewEffectTag"
local events, writes, logs = {}, {}, {}
local values = {
  [preset .. ".previewEffectTag"] = {value="ricochet"},
  [preset .. ".previewEffectName"] = {value="weaponPreview"},
  [flat] = {value="ricochet"},
  [target .. ".previewEffectName"] = {value="weaponPreview"},
  [donor .. ".previewEffectTag"] = {value="pierce"},
  [donor .. ".previewEffectName"] = {value="weaponPreview"}
}
local version = "v1.38.0"
function GetVersion() return version end
function registerForEvent(name, callback) events[name] = callback end
function print(message) table.insert(logs,message) end
TweakDB = {}
function TweakDB:GetFlat(name) return values[name] end
function TweakDB:GetRecord(name)
  return {PreviewEffectTag=function() return values[name .. ".previewEffectTag"] end}
end
function TweakDB:Update(name)
  assert(name == target, "Mise à jour du mauvais enregistrement")
  return true
end
function TweakDB:SetFlat(name,value)
  assert(name == flat, "Écriture hors du périmètre visuel")
  values[name] = value
  table.insert(writes,{name,value.value})
  return true
end
`;
function execute(body) {
  const state = lauxlib.luaL_newstate(); lualib.luaL_openlibs(state);
  const status = lauxlib.luaL_dostring(state, to_luastring(setup + '\n' + mod + '\n' + body));
  const error = status ? to_jsstring(lua.lua_tostring(state,-1)) : undefined;
  lua.lua_close(state); assert.equal(status,0,error);
}
test('application unique, idempotence et restauration', () => execute(`
events.onInit(); assert(values[flat].value == "pierce"); assert(#writes == 1)
events.onInit(); assert(#writes == 1)
events.onShutdown(); assert(values[flat].value == "ricochet"); assert(#writes == 2)
events.onShutdown(); assert(#writes == 2)
`));
test('ciblage réel : Uncommon corrigé et restauré, ancien preset et Lizzie inchangés', () => execute(`
events.onInit()
assert(writes[1][1] == "Items.Uncommon_Nekomata_Breakthrough.previewEffectTag")
assert(values[flat].value == "pierce")
assert(values[preset .. ".previewEffectTag"].value == "ricochet")
assert(values[donor .. ".previewEffectTag"].value == "pierce")
assert(string.find(logs[#logs], "Items.Uncommon_Nekomata_Breakthrough", 1, true))
events.onShutdown()
assert(#writes == 2 and writes[2][1] == flat and writes[2][2] == "ricochet")
assert(values[preset .. ".previewEffectTag"].value == "ricochet")
assert(values[donor .. ".previewEffectTag"].value == "pierce")
`));
for (const [name, alteration] of [
  ['CET non étudié','version="v1.37.1"'],
  ['enregistrement absent','function TweakDB:GetRecord(name) return nil end'],
  ['valeur déjà corrigée','values[flat]={value="pierce"}'],
  ['conflit de valeur','values[flat]={value="custom"}'],
  ['donneur incompatible','values[donor .. ".previewEffectTag"]={value="other"}'],
  ['champ absent','values[flat]=nil'],
  ['effet incompatible','values[target .. ".previewEffectName"]={value="None"}']
]) test(name + ' : zéro écriture', () => execute(alteration+'; events.onInit(); assert(#writes == 0)'));
test('retrait préserve une modification ultérieure', () => execute(`
events.onInit(); values[flat]={value="other-mod"}; events.onShutdown()
assert(values[flat].value == "other-mod"); assert(#writes == 1)
`));
test('échec de mise à jour : restauration', () => execute(`
local calls=0
function TweakDB:Update(name) calls=calls+1; return calls > 1 end
events.onInit(); assert(values[flat].value == "ricochet"); assert(#writes == 2)
`));
test('échec de relecture du record : restauration', () => execute(`
function TweakDB:GetRecord(name) return {PreviewEffectTag=function() return {value="ricochet"} end} end
events.onInit(); assert(values[flat].value == "ricochet"); assert(#writes == 2)
`));
test('échec d’écriture : aucun changement', () => execute(`
function TweakDB:SetFlat(name,value) return false end
events.onInit(); assert(values[flat].value == "ricochet"); assert(#writes == 0)
`));
