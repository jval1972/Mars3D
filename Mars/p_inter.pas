//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars - The Ultimate Fighter"
//
//  Copyright (C) 1997 by Engine Technology CO. LTD
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2018 by Retro Fans of Mars3D
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Handling interactions (i.e., collisions).
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_inter;

interface

uses
  doomdef,
  dstrings,
  d_englsh,
  sounds,
  m_rnd,
  i_system,
  am_map,
  p_local,
  p_mobj_h,
  s_sound,
  d_player;

//==============================================================================
//
// P_GivePower
//
//==============================================================================
function P_GivePower(player: Pplayer_t; power: integer): boolean;

//==============================================================================
//
// P_TouchSpecialThing
//
//==============================================================================
procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);

//==============================================================================
//
// P_DamageMobj
//
//==============================================================================
procedure P_DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);

const
// a weapon is found with two clip loads,
// a big item has five clip loads
  maxammo: array[0..Ord(NUMAMMO) - 1] of integer = (300, 999, 999, 999, 999, 999, 999, 999, 999);
  clipammo: array[0..Ord(NUMAMMO) - 1] of integer = (10, 15, 10, 25, 15, 1, 5, 5, 5);

//==============================================================================
//
// P_CmdSuicide
//
//==============================================================================
procedure P_CmdSuicide;

var
  p_maxhealth: integer = 999;

  p_medikidpack: integer = 15;
  p_medikidpotion: integer = 25;
  p_tianshanganoderma: integer = 200;

  p_soulspherehealth: integer = 100;
  p_megaspherehealth: integer = 200;
  p_medikithealth: integer = 25;
  p_stimpackhealth: integer = 10;
  p_bonushealth: integer = 1;

  p_maxarmor: integer = 200;
  p_greenarmorclass: integer = 1;
  p_bluearmorclass: integer = 2;

implementation

uses
  c_cmds,
  d_delphi,
  info_h,
  info,
  m_fixed,
  d_items,
  g_game,
  p_mobj,
  p_obituaries,
  p_3dfloors,
  p_pspr,
  ps_main, // JVAL: Script Events
  r_defs,
  r_main,
  tables;

const
  BONUSADD = 6;

//==============================================================================
//
// GET STUFF
//
// P_GiveAmmo
// Num is the number of clip loads,
// not the individual count (0= 1/2 clip).
// Returns false if the ammo can't be picked up at all
//
//==============================================================================
function P_GiveAmmo(player: Pplayer_t; ammo: ammotype_t; num: integer; const excact: boolean = false): boolean;
var
  oldammo: integer;
begin
  if ammo = am_noammo then
  begin
    result := false;
    exit;
  end;

  if (Ord(ammo) < 0) or (Ord(ammo) > Ord(NUMAMMO)) then
    I_Error('P_GiveAmmo(): bad type %d', [Ord(ammo)]);

  if player.ammo[Ord(ammo)] = player.maxammo[Ord(ammo)] then
  begin
    result := false;
    exit;
  end;

  if not excact then
  begin
    if num <> 0 then
      num := num * clipammo[Ord(ammo)]
    else
      num := clipammo[Ord(ammo)] div 2;
  end;

  if num = 0 then
    num := 1;

  if not excact then
    if (gameskill = sk_baby) or (gameskill = sk_nightmare) then
    begin
      // give double ammo in trainer mode,
      // you'll need in nightmare
      num := num * 2
    end;

  oldammo := player.ammo[Ord(ammo)];
  player.ammo[Ord(ammo)] := player.ammo[Ord(ammo)] + num;

  if player.ammo[Ord(ammo)] > player.maxammo[Ord(ammo)] then
    player.ammo[Ord(ammo)] := player.maxammo[Ord(ammo)];

  // If non zero ammo,
  // don't change up weapons,
  // player was lower on purpose.
  if oldammo <> 0 then
  begin
    result := true;
    exit;
  end;

  // We were down to zero,
  // so select a new weapon.
  // Preferences are not user selectable.
  case ammo of
    am_bullet:
      begin
        if player.readyweapon = wp_fist then
          if player.weaponowned[Ord(wp_pistol)] <> 0 then
            player.pendingweapon := wp_pistol;
      end;
    am_shockgunammo:
      begin
        if (player.readyweapon = wp_fist) or
           (player.readyweapon = wp_pistol) then
        begin
          if player.weaponowned[Ord(wp_shockgun)] <> 0 then
            player.pendingweapon := wp_shockgun;
        end;
      end;
    am_nervegunammo:
      begin
        if (player.readyweapon = wp_fist) or
           (player.readyweapon = wp_pistol) then
        begin
          if player.weaponowned[Ord(wp_nervegun)] <> 0 then
            player.pendingweapon := wp_nervegun;
        end;
      end;
    am_freezegunammo:
      begin
        if (player.readyweapon = wp_fist) or
           (player.readyweapon = wp_pistol) then
        begin
          if player.weaponowned[Ord(wp_freezegun)] <> 0 then
            player.pendingweapon := wp_freezegun;
        end;
      end;
    am_flamegunammo:
      begin
        if (player.readyweapon = wp_fist) or
           (player.readyweapon = wp_pistol) then
        begin
          if player.weaponowned[Ord(wp_flamegun)] <> 0 then
            player.pendingweapon := wp_flamegun;
        end;
      end;
    am_grenades:
      begin
        if (player.readyweapon = wp_fist) or
           (player.readyweapon = wp_pistol) then
        begin
          if player.weaponowned[Ord(wp_grenades)] <> 0 then
            player.pendingweapon := wp_grenades;
        end;
      end;
    am_disk:
      begin
        if (player.readyweapon = wp_fist) or
           (player.readyweapon = wp_pistol) then
        begin
          if player.weaponowned[Ord(wp_boomerang)] <> 0 then
            player.pendingweapon := wp_boomerang;
        end;
      end;
    am_misl:
      begin
        if player.readyweapon = wp_fist then
        begin
          if player.weaponowned[Ord(wp_missile)] <> 0 then
            player.pendingweapon := wp_missile;
        end
      end;
    am_trackingmisl:
      begin
        if player.readyweapon = wp_fist then
        begin
          if player.weaponowned[Ord(wp_trackingmissile)] <> 0 then
            player.pendingweapon := wp_trackingmissile;
        end
      end;
  end;

  result := true;
end;

//==============================================================================
//
// P_GiveWeapon
// The weapon name may have a MF_DROPPED flag ored in.
//
//==============================================================================
function P_GiveWeapon(player: Pplayer_t; weapon: weapontype_t; dropped: boolean): boolean;
var
  gaveammo: boolean;
  gaveweapon: boolean;
  ammo: ammotype_t;
begin
  ammo := weaponinfo[Ord(weapon)].ammo;
  if netgame and (deathmatch <> 2) and not dropped then
  begin
  // leave placed weapons forever on net games
    if player.weaponowned[Ord(weapon)] <> 0 then
    begin
      result := false;
      exit;
    end;

    player.bonuscount := player.bonuscount + BONUSADD;
    player.weaponowned[Ord(weapon)] := 1;

    if deathmatch <> 0 then
      P_GiveAmmo(player, ammo, 5)
    else
      P_GiveAmmo(player, ammo, 1);
    player.pendingweapon := weapon;

    if (player = @players[consoleplayer]) then
      S_StartSound(nil, Ord(sfx_itemup));
    result := false;
    exit;
  end;

  if ammo <> am_noammo then
    gaveammo := P_GiveAmmo(player, ammo, 1)
  else
    gaveammo := false;

  if player.weaponowned[Ord(weapon)] <> 0 then
    gaveweapon := false
  else
  begin
    gaveweapon := true;
    player.weaponowned[Ord(weapon)] := 1;
    player.pendingweapon := weapon;
  end;

  result := gaveweapon or gaveammo;
end;

//==============================================================================
//
// P_GiveBody
// Returns false if the body isn't needed at all
//
//==============================================================================
function P_GiveBody(player: Pplayer_t; num: integer): boolean;
begin
  if player.health >= p_maxhealth then
  begin
    result := false;
    exit;
  end;

  player.health := player.health + num;
  if player.health > p_maxhealth then
    player.health := p_maxhealth;
  player.mo.health := player.health;

  result := true;
end;

//==============================================================================
//
// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.
//
//==============================================================================
function P_GiveArmor(player: Pplayer_t; armortype: integer): boolean;
var
  hits: integer;
begin
  hits := armortype * 100;
  if player.armorpoints >= hits then
  begin
    result := false;  // don't pick up
    exit;
  end;

  player.armortype := armortype;
  player.armorpoints := hits;

  result := true;
end;

//==============================================================================
//
// P_GiveCard
//
//==============================================================================
procedure P_GiveCard(player: Pplayer_t; card: card_t);
begin
  if player.cards[Ord(card)] then
    exit;

  player.bonuscount := BONUSADD;
  player.cards[Ord(card)] := true;
end;

//==============================================================================
//
// P_GivePower
//
//==============================================================================
function P_GivePower(player: Pplayer_t; power: integer): boolean;
begin
  if power = Ord(pw_invulnerability) then
  begin
    player.powers[power] := INVULNTICS;
    result := true;
    exit;
  end;

  if power = Ord(pw_invisibility) then
  begin
    player.powers[power] := INVISTICS;
    player.mo.flags := player.mo.flags or MF_SHADOW;
    result := true;
    exit;
  end;

  if power = Ord(pw_infrared) then
  begin
    player.powers[power] := INFRATICS;
    result := true;
    exit;
  end;

  if power = Ord(pw_ironfeet) then
  begin
    player.powers[power] := IRONTICS;
    result := true;
    exit;
  end;

  if power = Ord(pw_strength) then
  begin
    P_GiveBody(player, 100);
    player.powers[power] := 1;
    result := true;
    exit;
  end;

  if player.powers[power] <> 0 then
    result := false // already got it
  else
  begin
    player.powers[power] := 1;
    result := true;
  end;
end;

//
// P_TouchSpecialThing
//
var
  bonus_snd: integer = -1;

//==============================================================================
//
// P_TouchSpecialThing
//
//==============================================================================
procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
var
  player: Pplayer_t;
  delta: fixed_t;
  sound: integer;
  s_spr: string;
begin
  delta := special.z - toucher.z;

  if (delta > toucher.height) or (delta < - 8 * FRACUNIT) then
  // out of reach
    exit;

  if bonus_snd < 0 then
    bonus_snd := S_GetSoundNumForName('ITEMUP');

  sound := bonus_snd;
  player := toucher.player;

  // Dead thing touching.
  // Can happen with a sliding player corpse.
  if toucher.health <= 0 then
    exit;

  s_spr :=
        Chr(sprnames[special.sprite] and $FF) +
        Chr((sprnames[special.sprite] shr 8) and $FF) +
        Chr((sprnames[special.sprite] shr 16) and $FF) +
        Chr((sprnames[special.sprite] shr 24) and $FF);

  if s_spr = 'ICR1' then // Red keycard
  begin
    if not player.cards[Ord(it_redcard)] then
      player._message := GOTREDCARD;
    P_GiveCard(player, it_redcard);
    if netgame then
      exit;
  end
  else if s_spr = 'ICR2' then // Blue keycard
  begin
    if not player.cards[Ord(it_bluecard)] then
      player._message := GOTBLUECARD;
    P_GiveCard(player, it_bluecard);
    if netgame then
      exit;
  end
  else if s_spr = 'ICR3' then // Gold keycard
  begin
    if not player.cards[Ord(it_yellowcard)] then
      player._message := GOTYELWCARD;
    P_GiveCard(player, it_yellowcard);
    if netgame then
      exit;
  end
  else if s_spr = 'LITC' then // Weapon #1 - Gun (+ 40 bullets)
  begin
    if not P_GiveAmmo(player, am_bullet, 4) then
      exit;
    player._message := GOTWEAPON1;
  end
  else if s_spr = 'ELEC' then // Weapon #2 - Shock Gun
  begin
    if not P_GiveWeapon(player, wp_shockgun, false) then
      exit;
    player._message := GOTWEAPON2;
  end
  else if s_spr = 'FUZC' then // Weapon #3 - Nerve gun
  begin
    if not P_GiveWeapon(player, wp_nervegun, false) then
      exit;
    player._message := GOTWEAPON3;
  end
  else if s_spr = 'FREC' then // Weapon #4 - Freeze gun
  begin
    if not P_GiveWeapon(player, wp_freezegun, false) then
      exit;
    player._message := GOTWEAPON4;
  end
  else if s_spr = 'FLAC' then // Weapon #5 - Flame gun
  begin
    if not P_GiveWeapon(player, wp_flamegun, false) then
      exit;
    player._message := GOTWEAPON5;
  end
  else if s_spr = 'BOB2' then // Weapon #6 - Grenades
  begin
    if not P_GiveWeapon(player, wp_grenades, false) then
      exit;
    player._message := GOTWEAPON6;
  end
  else if s_spr = 'CDCC' then // Weapon #7 - Boomerang
  begin
    if not P_GiveWeapon(player, wp_boomerang, false) then
      exit;
    player._message := GOTWEAPON7;
  end
  else if s_spr = 'MISC' then // Weapon #8 - Missile Launcher
  begin
    if not P_GiveWeapon(player, wp_missile, false) then
      exit;
    player._message := GOTWEAPON8;
  end
  else if s_spr = 'DEVC' then // Weapon #9 - Tracking Missile Launcher
  begin
    if not P_GiveWeapon(player, wp_trackingmissile, false) then
      exit;
    player._message := GOTWEAPON9;
  end
  else if s_spr = 'GUN1' then // Ammo bullets
  begin
    if not P_GiveAmmo(player, am_bullet, 1) then
      exit;
    player._message := GOTBULLETS;
  end
  else if s_spr = 'MIS1' then // Tracking missiles
  begin
    if not P_GiveAmmo(player, am_trackingmisl, 1) then
      exit;
    player._message := GOTTRACKINGMISSILES;
  end
  else if s_spr = 'MIS2' then // Tracking missiles BOX
  begin
    if not P_GiveAmmo(player, am_misl, 4) then
      exit;
    player._message := GOTMISSILESBOX;
  end
  else if s_spr = 'FRES' then // Freezegun ammo
  begin
    if not P_GiveAmmo(player, am_freezegunammo, 1) then
      exit;
    player._message := GOTFREEZEGUNAMMO;
  end
  else if s_spr = 'ELEES' then // Shockgun ammo
  begin
    if not P_GiveAmmo(player, am_shockgunammo, 1) then
      exit;
    player._message := GOTSCHOCKGUNAMMO;
  end
  else if s_spr = 'GUN2' then // Box of bullets
  begin
    if not P_GiveAmmo(player, am_bullet, 3) then
      exit;
    player._message := GOTBOXOFBULLETS;
  end
  else if s_spr = 'BOB1' then // Grenade
  begin
    if not P_GiveAmmo(player, am_grenades, 1) then
      exit;
    player._message := GOTGRENADES;
  end
  else if s_spr = 'CDR1' then // Boomerang disk
  begin
    if not P_GiveAmmo(player, am_disk, 1) then
      exit;
    player._message := GOTDISK;
  end
  else if s_spr = 'CDCS' then // Boomerang disk - dropper by player
  begin
    if not P_GiveAmmo(player, am_disk, 1, true) then
      exit;
    player._message := GOTDISK;
  end
  else if s_spr = 'CDR2' then // Boomerang disk pack
  begin
    if not P_GiveAmmo(player, am_disk, 10) then
      exit;
    player._message := GOTDISKS;
  end
  else if s_spr = 'HSP1' then // MT_HEALTH15 (Medkit pack)
  begin
    if not P_GiveBody(player, p_medikidpack) then
      exit;
    player._message := GOTHEALTH15;
  end
  else if s_spr = 'HSP2' then // MT_HEALTH25 (Medkit potion)
  begin
    if not P_GiveBody(player, p_medikidpotion) then
      exit;
    player._message := GOTHEALTH25;
  end
  else if s_spr = 'HSP3' then // MT_HEALTH200 (Tianshan Ganoderma)
  begin
    if not P_GiveBody(player, p_tianshanganoderma) then
      exit;
    player._message := GOTHEALTH200;
  end
  else if s_spr = 'STAR' then // MT_ALLMAP
  begin
    if not P_GivePower(player, Ord(pw_allmap)) then
      exit;
    player._message := GOTMAP;
  end
  else if s_spr = 'DFK4' then // MT_RADIATIONSUIT
  begin
    if not P_GivePower(player, Ord(pw_ironfeet)) then
      exit;
    player._message := GOTSUIT;
  end
  else if s_spr = 'RGLA' then // MT_NIGHTVISOR
  begin
    if not P_GivePower(player, Ord(pw_infrared)) then
      exit;
    player._message := GOTVISOR;
  end
  else if s_spr = 'FILY' then // MT_JETPACK
  begin
    if not P_GivePower(player, Ord(pw_jetpack)) then
      exit;
    player._message := GOTJETPACK;
  end
  else if s_spr = 'DFK1' then // MT_ARMORSHIELD
  begin
    if not P_GiveArmor(player, p_greenarmorclass) then
      exit;
    player._message := GOTARMOR;
  end
  else if s_spr = 'DFK2' then // MT_ARMORVEST
  begin
    if not P_GiveArmor(player, p_bluearmorclass) then
      exit;
     player._message := GOTMEGA;
  end
  else if s_spr = 'DFK3' then // MT_ARMORBONUS
  begin
    player.armorpoints := player.armorpoints + 1; // can go over 100%
    if player.armorpoints > p_maxarmor then
      player.armorpoints := p_maxarmor;
    if player.armortype = 0 then
      player.armortype := 1;
    player._message := GOTARMBONUS;
  end
  else
    I_Error('P_TouchSpecialThing(): Unknown gettable thing');

  if special.flags and MF_COUNTITEM <> 0 then
    player.itemcount := player.itemcount + 1;
  P_RemoveMobj(special);
  player.bonuscount := player.bonuscount + BONUSADD;
  if player = @players[consoleplayer] then
    if sound >= 0 then
      S_StartSound(nil, sound);
end;

//==============================================================================
// P_SpawnDroppedMobj
//
// KillMobj
//
//==============================================================================
function P_SpawnDroppedMobj(x, y, z: fixed_t; _type: integer): Pmobj_t;
begin
  result := P_SpawnMobj(x, y, z, _type);
  result.flags := result.flags or MF_DROPPED; // special versions of items
  // JVAL Dropped items fall down to floor.
  if not G_NeedsCompatibilityMode then
  begin
    result.z := result.z + 32 * FRACUNIT;
    result.momz := 4 * FRACUNIT;
    result.momx := 64 * N_Random;
    result.momy := 64 * N_Random;
  end;
end;

//==============================================================================
//
// P_KillMobj
//
//==============================================================================
procedure P_KillMobj(source: Pmobj_t; target: Pmobj_t);
var
  item: integer;
  gibhealth: integer;
  zpos: integer;
  skullfly: boolean;
begin
  skullfly := target.flags or MF_SKULLFLY <> 0;
  target.flags := target.flags and not (MF_SHOOTABLE or MF_FLOAT or MF_SKULLFLY);
  target.flags3_ex := target.flags3_ex and not MF3_EX_BOUNCE;

  if not skullfly and (target.flags3_ex and MF3_EX_NOGRAVITYDEATH = 0) then
    target.flags := target.flags and not MF_NOGRAVITY;

  target.flags := target.flags or (MF_CORPSE or MF_DROPOFF);
  target.flags2_ex := target.flags2_ex and not MF2_EX_PASSMOBJ;
  target.height := target.height div 4;

  if (source <> nil) and (source.player <> nil) then
  begin
    // count for intermission
    if target.flags and MF_COUNTKILL <> 0 then
      Pplayer_t(source.player).killcount := Pplayer_t(source.player).killcount + 1;

    if target.player <> nil then
      Pplayer_t(source.player).frags[pDiff(target.player, @players[0], SizeOf(players[0]))] :=
        Pplayer_t(source.player).frags[pDiff(target.player, @players[0], SizeOf(players[0]))] + 1;
  end
  else if not netgame and (target.flags and MF_COUNTKILL <> 0) then
  begin
    // count all monster deaths,
    // even those caused by other monsters
    players[0].killcount := players[0].killcount + 1;
  end;

  if target.player <> nil then
  begin
    // count environment kills against you
    if source = nil then
      Pplayer_t(target.player).frags[pDiff(target.player, @players[0], SizeOf(players[0]))] :=
        Pplayer_t(target.player).frags[pDiff(target.player, @players[0], SizeOf(players[0]))] + 1;

    target.flags := target.flags and not MF_SOLID;
    target.flags4_ex := target.flags4_ex and not MF4_EX_FLY;  // JVAL: 20211109 - Fly (Jet pack)
    target.flags := target.flags and not MF_NOGRAVITY;  // JVAL: 20211116 - Cancel no gravity
    Pplayer_t(target.player).powers[Ord(pw_jetpack)] := 0;
    Pplayer_t(target.player).playerstate := PST_DEAD;

    // JVAL
    // Save the attacker coordinates
    if Pplayer_t(target.player).attacker <> nil then
    begin
      Pplayer_t(target.player).attackerx := Pplayer_t(target.player).attacker.x;
      Pplayer_t(target.player).attackery := Pplayer_t(target.player).attacker.y;
    end;

    P_DropWeapon(target.player);

    if (target.player = @players[consoleplayer]) and (amstate = am_only) then
    begin
      // don't die in auto map,
      // switch view prior to dying
      amstate := am_inactive;
      AM_Stop;
    end;

  end;

  gibhealth := target.info.gibhealth;
  if gibhealth >= 0 then
    gibhealth := -target.info.spawnhealth;

  if (target.health < gibhealth) and (target.info.xdeathstate <> 0) then
    P_SetMobjState(target, target.info.xdeathstate)
  else
    P_SetMobjState(target, target.info.deathstate);
  target.tics := target.tics - P_Random and 3;

  if target.tics < 1 then
    target.tics := 1;

  if target.player <> nil then    // JVAL: Script Events
    PS_EventPlayerDied(pDiff(@players[0], target.player, SizeOf(player_t)), source);
  PS_EventActorDied(target, source); // JVAL: Script Events

  // Drop stuff.
  // This determines the kind of object spawned
  // during the death frame of a thing.

  if target.info.dropitem > 0 then
    item := target.info.dropitem
  else
    item := 0;

// JVAL: Check if dropitem is set to drop a custom item.
  if target.flags2_ex and MF2_EX_CUSTOMDROPITEM <> 0 then
    item := target.dropitem;

// JVAL: 20200301 - Fix P_SpawnDroppedMobj() bug
  if item <= 0 then
    Exit;

  if target.flags4_ex and MF4_EX_ABSOLUTEDROPITEMPOS <> 0 then
    P_SpawnDroppedMobj(target.x, target.y, target.z, item)
  else if Psubsector_t(target.subsector).sector.midsec >= 0 then // JVAL: 3d Floors
  begin
    zpos := P_3dFloorHeight(target);
    P_SpawnDroppedMobj(target.x, target.y, zpos, item)
  end
  else
    P_SpawnDroppedMobj(target.x, target.y, ONFLOORZ, item);
end;

//
// P_DamageMobj
// Damages both enemies and players
// "inflictor" is the thing that caused the damage
//  creature or missile, can be NULL (slime, etc)
// "source" is the thing to target after taking damage
//  creature or NULL
// Source and inflictor are the same for melee attacks.
// Source can be NULL for slime, barrel explosions
// and other environmental stuff.
//
const
  PLAYER_DAMAGE_FACTORS: array[skill_t] of fixed_t = (
    $8000, $10000, $10000, $18000, $18000
  );
  PLAYERSHOOT_DAMAGE_FACTORS: array[skill_t] of fixed_t = (
    $14000, $12000, $10000, $E000, $10000
  );

//==============================================================================
//
// P_DamageMobj
//
//==============================================================================
procedure P_DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);
var
  ang: angle_t;
  saved: integer;
  player: Pplayer_t;
  thrust: fixed_t;
  mass: integer;
begin
  if target.flags and MF_SHOOTABLE = 0 then
  begin
  // 19/9/2009 JVAL: Display a warning message for debugging
    I_DevWarning('P_DamageMobj(): Trying to damage unshootable mobj "%s"'#13#10, [target.info.name]);
//    target.tics := -1;
    exit; // shouldn't happen...
  end;

  // JVAL: Invulnerable monsters
  if target.flags_ex and MF_EX_INVULNERABLE <> 0 then
    exit;

  if target.flags2_ex and MF2_EX_NODAMAGE <> 0 then
    exit;

  if target.health <= 0 then
    exit;

  if target.flags and MF_SKULLFLY <> 0 then
  begin
    target.momx := 0;
    target.momy := 0;
    target.momz := 0;
  end;

  if inflictor <> nil then
  begin
    if inflictor.flags3_ex and MF3_EX_FREEZEDAMAGE <> 0 then
    begin
      if target.flags3_ex and MF3_EX_NOFREEZEDAMAGE <> 0 then
        exit;
      if target.flags3_ex and MF3_EX_FREEZEDAMAGERESIST <> 0 then
        if damage > 1 then
          damage := _SHR1(damage);
    end;
    if inflictor.flags3_ex and MF3_EX_FLAMEDAMAGE <> 0 then
    begin
      if target.flags3_ex and MF3_EX_NOFLAMEDAMAGE <> 0 then
        exit;
      if target.flags4_ex and MF4_EX_FLAMEDAMAGERESIST <> 0 then
        if damage > 1 then
          damage := _SHR1(damage);
    end;
    if inflictor.flags4_ex and MF4_EX_SHOCKGUNDAMAGE <> 0 then
    begin
      if target.flags4_ex and MF4_EX_NOSHOCKGUNDAMAGE <> 0 then
        exit;
      if target.flags4_ex and MF4_EX_SHOCKGUNDAMAGERESIST <> 0 then
        if damage > 1 then
          damage := _SHR1(damage);
    end;
    if inflictor.flags4_ex and MF4_EX_POISONDAMAGE <> 0 then
    begin
      if target.flags4_ex and MF4_EX_NOPOISONDAMAGE <> 0 then
        exit;
      if target.flags4_ex and MF4_EX_POISONDAMAGERESIST <> 0 then
        if damage > 1 then
          damage := _SHR1(damage);
    end;
    if inflictor.flags4_ex and MF4_EX_DISKDAMAGE <> 0 then
    begin
      if target.flags4_ex and MF4_EX_NODISKDAMAGE <> 0 then
        exit;
      if target.flags4_ex and MF4_EX_DISKDAMAGERESIST <> 0 then
        if damage > 1 then
          damage := _SHR1(damage);
    end;
  end;

  player := target.player;
  if (player <> nil) and (damage < 1000) then
    damage := (damage * PLAYER_DAMAGE_FACTORS[gameskill]) div FRACUNIT; // Damage player according to skill

  if (inflictor <> nil) and (target.flags_ex and MF_EX_FIRERESIST <> 0) then
  begin
    if damage > 1 then
      damage := _SHR1(damage);
  end;

  // Some close combat weapons should not
  // inflict thrust and push the victim out of reach,
  // thus kick away unless using the chainsaw.
  if (inflictor <> nil) and (target.flags and MF_NOCLIP = 0) and
    ((source = nil) or (source.player = nil)) then
  begin
    ang := R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y);

    mass := target.mass;
    if mass = 0 then
    begin
      I_DevWarning('P_DamageMobj(): Target (%s) mass is zero'#13#10, [target.info.name]);
      thrust := 0;
    end
    else
      thrust := (damage * $2000 * 100) div mass;

    // make fall forwards sometimes
    if (damage < 40) and (damage > target.health) and
       (target.z - inflictor.z > 64 * FRACUNIT) and (P_Random and 1 <> 0) then
    begin
      ang := ang + ANG180;
      thrust := thrust * 4;
    end;

    {$IFDEF FPC}
    ang := _SHRW(ang, ANGLETOFINESHIFT);
    {$ELSE}
    ang := ang shr ANGLETOFINESHIFT;
    {$ENDIF}
    target.momx := target.momx + FixedMul(thrust, finecosine[ang]);
    target.momy := target.momy + FixedMul(thrust, finesine[ang]);
  end;

  // player specific
  if player <> nil then
  begin
    // end of game hell hack
    if (Psubsector_t(target.subsector).sector.special = 11) and (damage >= target.health) then
      damage := target.health - 1;

    // Below certain threshold,
    // ignore damage in GOD mode, or with INVUL power.
    if (damage < 1000) and
       ((player.cheats and CF_GODMODE <> 0) or (player.powers[Ord(pw_invulnerability)] <> 0)) then
      exit;

    if player.armortype <> 0 then
    begin
      if player.armortype = 1 then
        saved := damage div 3
      else
        saved := damage div 2;

      if player.armorpoints <= saved then
      begin
        // armor is used up
        saved := player.armorpoints;
        player.armortype := 0;
      end;
      player.armorpoints := player.armorpoints - saved;
      damage := damage - saved;
    end;
    player.health := player.health - damage;  // mirror mobj health here for Dave
    if player.health < 0 then
      player.health := 0;

    player.attacker := source;
    player.damagecount := player.damagecount + damage;  // add damage after armor / invuln

    player.damagetype := DAMAGE_BLOOD;

    if source <> nil then
      if source.flags4_ex and MF4_EX_POISONDAMAGE <> 0 then
        player.damagetype := DAMAGE_POISON;
    if inflictor <> nil then
      if inflictor.flags4_ex and MF4_EX_POISONDAMAGE <> 0 then
        player.damagetype := DAMAGE_POISON;

    if player.damagecount > 100 then
      player.damagecount := 100;  // teleport stomp does 10k points...

    player.hardbreathtics := player.damagecount * 10;
  end;

  if source <> nil then
    if source.player <> nil then
      if damage < 1000 then
        damage := (damage * PLAYERSHOOT_DAMAGE_FACTORS[gameskill]) div FRACUNIT;  // Damage monsters according to skill

  if damage < 1 then
    damage := 1;

  // do the damage
  target.health := target.health - damage;
  if target.health <= 0 then
  begin
    P_KillMobj(source, target);
    P_Obituary(target, inflictor, source);
    exit;
  end;

  if (P_Random < target.painchance) and
     ((target.flags and MF_SKULLFLY) = 0) then
  begin
    target.flags := target.flags or MF_JUSTHIT; // fight back!
    P_SetMobjState(target, target.info.painstate);
  end;

  target.reactiontime := 0; // we're awake now...

  if (target.threshold = 0)  and
     (source <> nil) and (source <> target) then
  begin
    // if not intent on another player,
    // chase after this one
    if target.flags2_ex and MF2_EX_DONTINFIGHTMONSTERS = 0 then
    begin
      target.target := source;
      target.threshold := BASETHRESHOLD;
      if (target.state = @states[target.info.spawnstate]) and
         (target.info.seestate <> Ord(S_NULL)) then
        P_SetMobjState(target, target.info.seestate);
    end;
  end;
end;

//==============================================================================
//
// P_CmdSuicide
//
//==============================================================================
procedure P_CmdSuicide;
begin
  if demoplayback then
  begin
    I_Warning('P_CmdSuicide(): You can''t suicide during demo playback.'#13#10);
    exit;
  end;
  if demorecording then
  begin
    I_Warning('P_CmdSuicide(): You can''t suicide during demo recording.'#13#10);
    exit;
  end;

  if (gamestate = GS_LEVEL) and (players[consoleplayer].mo <> nil) then
  begin
    if players[consoleplayer].health > 0 then
    begin
      C_ExecuteCmd('closeconsole');
      P_DamageMobj(players[consoleplayer].mo, nil, nil, 10000);
      players[consoleplayer]._message := 'You give up too easy';
    end
    else
      printf('You''re already dead.'#13#10);
  end
  else
    I_Warning('P_CmdSuicide(): You can''t suicide if you aren''t playing.'#13#10);
end;

end.

