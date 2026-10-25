import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {hashId,readDatabase} from '../scripts/inspect-tweakdb.mjs';

test('TweakDBID : vecteur CRC32 standard et longueur UTF-8', () => {
  assert.equal(hashId('123456789'),0x9cbf43926n);
});
for (const name of ['tweakdb-comparison.json','tweakdb-ep1-comparison.json']) {
  test('preuve locale : '+name, () => {
    const data=JSON.parse(fs.readFileSync('research/metadata/'+name,'utf8'));
    const find=name=>data.records.find(r=>r.name===name);
    const target=find('Items.Uncommon_Nekomata_Breakthrough');
    const donor=find('Items.Preset_Omaha_Suzie');
    assert.equal(target.exists,true); assert.equal(donor.exists,true);
    assert.deepEqual(target.flats.previewEffectTag,{type:'CName',value:'ricochet'});
    assert.deepEqual(donor.flats.previewEffectTag,{type:'CName',value:'pierce'});
    assert.deepEqual(target.flats.previewEffectName,donor.flats.previewEffectName);
    assert.deepEqual(target.flats.evolution,donor.flats.evolution);
    assert.ok(target.flats.tags.value.includes('TechWeapon'));
    assert.ok(donor.flats.tags.value.includes('TechWeapon'));
  });
}
test('alternative YAML : un seul champ et un seul enregistrement',()=>{
  const content=fs.readFileSync('package/tweakxl-future/BreakthroughStalkerFix.yaml','utf8');
  assert.equal(content.split('\n').filter(l=>l.trim()&&!l.startsWith('#')).join('\n'),
    'Items.Uncommon_Nekomata_Breakthrough:\n  previewEffectTag: pierce');
});
test('lecteur : refuse un format inconnu et un fichier tronqué',()=>{
  fs.mkdirSync('.test-output',{recursive:true});
  const file='.test-output/invalid-tweakdb.bin';
  fs.writeFileSync(file,Buffer.alloc(32));
  assert.throws(()=>readDatabase(file),/Format/);
  fs.writeFileSync(file,Buffer.alloc(4));
  assert.throws(()=>readDatabase(file),/hors limites/);
});
