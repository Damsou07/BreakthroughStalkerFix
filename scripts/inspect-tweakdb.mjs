// Lecture seule du format 8/4 : voir research/reference/TweakDBReader.cs et Header.cs.
// Les noms interrogés proviennent des scripts locaux ; les identifiants inconnus restent numériques.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function hashId(name) {
  let crc = 0xffffffff;
  const bytes = Buffer.from(name, 'utf8');
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return BigInt((crc ^ 0xffffffff) >>> 0) | (BigInt(bytes.length) << 32n);
}
function hashType(name) {
  let hash = 0xcbf29ce484222325n;
  for (const byte of Buffer.from(name)) hash = BigInt.asUintN(64, (hash ^ BigInt(byte)) * 0x100000001b3n);
  return hash;
}
export function readDatabase(file) {
  const data = fs.readFileSync(file);
  let position = 0;
  function take(size) {
    if (size < 0 || position + size > data.length) throw Error('Lecture hors limites');
    const start = position; position += size; return start;
  }
  const u32 = () => data.readUInt32LE(take(4));
  const u64 = () => data.readBigUInt64LE(take(8));
  const byte = () => data[take(1)];
  function vlq() {
    const first = byte(); let value = first & 63; let shift = 6;
    if (first & 64) {
      let next;
      do {
        if (shift > 27) throw Error('VLQ trop long');
        next = byte(); value += (next & 127) * 2 ** shift; shift += 7;
      } while (next & 128);
    }
    return first & 128 ? -value : value;
  }
  function value(type) {
    if (type.startsWith('array:')) {
      const count = vlq();
      if (count < 0 || count > data.length) throw Error('Taille de tableau invalide');
      return Array.from({length: count}, () => value(type.slice(6)));
    }
    if (type === 'CName') {
      const count = vlq();
      // Les noms non vides de cette analyse doivent être encodés en UTF-8.
      if (count > 0) throw Error('CName UTF-16 non pris en charge : arrêt sans approximation');
      const start = take(-count); return data.toString('utf8', start, position);
    }
    if (type === 'TweakDBID') return '0x' + u64().toString(16);
    if (type === 'Float') return data.readFloatLE(take(4));
    if (type === 'Bool') { const result = byte(); if (result > 1) throw Error('Bool invalide'); return !!result; }
    if (type === 'Int32') return data.readInt32LE(take(4));
    throw Error('Type non pris en charge');
  }
  const header = Array.from({length: 8}, u32);
  if (header[0] !== 0x0bb1db47 || header[1] !== 8 || header[2] !== 4) throw Error('Format TweakDB non pris en charge');
  for (const offset of header.slice(4)) if (offset < 32 || offset > data.length) throw Error('Offset invalide');
  position = header[4];
  const count = u32();
  if (count > 1000) throw Error('Nombre de types invalide');
  const types = Array.from({length: count}, () => ({hash:u64(), values:u32(), keys:u32(), offset:u32()}));
  const supported = ['CName','TweakDBID','Float','Bool','Int32'];
  const names = new Map([...supported, ...supported.map(t => 'array:' + t)].map(t => [hashType(t), t]));
  const flats = new Map(); const pools = [];
  for (const pool of types) {
    const type = names.get(pool.hash);
    if (!type) continue;
    position = pool.offset;
    // Comme le lecteur de référence, lire les comptes effectifs dans le bloc.
    const valueCount = u32();
    if (valueCount > data.length) throw Error('Nombre de valeurs invalide');
    const values = Array.from({length:valueCount}, () => value(type));
    const keyCount = u32();
    if (keyCount > data.length / 12) throw Error('Nombre de clés invalide');
    for (let index = 0; index < keyCount; index++) {
      const key = u64(); const valueIndex = u32();
      if (valueIndex >= values.length || flats.has(key)) throw Error('Index ou clé invalide');
      flats.set(key, {type, value:values[valueIndex]});
    }
    const next = types.map(t => t.offset).filter(o => o > pool.offset).sort((a,b) => a-b)[0] ?? header[5];
    if (position !== next) throw Error('Fin de bloc inattendue');
    pools.push({type, values:valueCount, keys:keyCount});
  }
  position = header[5]; const recordCount = u32(); const records = new Map();
  for (let index = 0; index < recordCount; index++) records.set(u64(), u32());
  if (position !== header[6]) throw Error('Fin des enregistrements inattendue');
  return {header, pools, flats, records};
}
function scriptNames(directory) {
  const names = new Set();
  function visit(folder) {
    for (const entry of fs.readdirSync(folder, {withFileTypes:true})) {
      const full = path.join(folder, entry.name);
      if (entry.isDirectory()) visit(full);
      else if (entry.name.endsWith('.script')) {
        for (const match of fs.readFileSync(full,'utf8').matchAll(/t"([^"\r\n]+)"/g)) names.add(match[1]);
      }
    }
  }
  visit(directory); return [...names].sort();
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [file, scriptDirectory, output] = process.argv.slice(2);
  if (!file || !scriptDirectory || !output) throw Error('Usage : node inspect-tweakdb.mjs fichier.bin scripts_locaux sortie.json');
  const db = readDatabase(file);
  // Identifiant publié par l'auteur de Netrunner's Data Dump, vérifié ensuite dans le binaire.
  const names = [...new Set([...scriptNames(scriptDirectory), 'Items.Preset_Omaha_Suzie'])].sort();
  const resolved = new Map(names.map(name => ['0x'+hashId(name).toString(16), name]));
  function resolve(value) { return Array.isArray(value) ? value.map(resolve) : (resolved.get(value) ?? value); }
  const properties = ['previewEffectName','previewEffectTag','evolution','statModifiers','statModifierGroups','OnEquip','OnAttach','tags'];
  const records = names.filter(name => /Breakthrough|Omaha_Suzie|Nekomata|Kiroshi|Optics/.test(name)).map(name => ({
    name, exists:db.records.has(hashId(name)),
    flats:Object.fromEntries(properties.map(property => {
      const flat = db.flats.get(hashId(name+'.'+property));
      return [property, flat ? {...flat,value:resolve(flat.value)} : null];
    }))
  }));
  fs.writeFileSync(output, JSON.stringify({file,header:db.header,pools:db.pools,records},null,2)+'\n');
  console.log(JSON.stringify(records.filter(r => r.exists).map(r => ({name:r.name,previewEffectName:r.flats.previewEffectName,previewEffectTag:r.flats.previewEffectTag})),null,2));
}
