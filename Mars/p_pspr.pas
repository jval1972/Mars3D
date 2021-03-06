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
//  Sprite animation.
//  Weapon sprite animation, weapon objects.
//  Action functions for weapons.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_pspr;

interface

uses
// Basic data types.
// Needs fixed point, and BAM angles.
  m_fixed,
  tables,
  info_h,
  p_pspr_h,
  p_mobj_h,
  d_player;

const
//
// Frame flags:
// handles maximum brightness (torches, muzzle flare, light sources)
//
  FF_FULLBRIGHT = $8000; // flag in thing->frame
  FF_FRAMEMASK = $7fff;

//==============================================================================
//
// P_DropWeapon
//
//==============================================================================
procedure P_DropWeapon(player: Pplayer_t);

//==============================================================================
//
// A_WeaponReady
//
//==============================================================================
procedure A_WeaponReady(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_ReFire
//
//==============================================================================
procedure A_ReFire(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_CheckReload
//
//==============================================================================
procedure A_CheckReload(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Lower
//
//==============================================================================
procedure A_Lower(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Raise
//
//==============================================================================
procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_GunFlash
//
//==============================================================================
procedure A_GunFlash(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FirePistol
//
//==============================================================================
procedure A_FirePistol(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Light0
//
//==============================================================================
procedure A_Light0(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Light1
//
//==============================================================================
procedure A_Light1(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Light2
//
//==============================================================================
procedure A_Light2(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// P_SetupPsprites
//
//==============================================================================
procedure P_SetupPsprites(player: Pplayer_t);

//==============================================================================
//
// P_MovePsprites
//
//==============================================================================
procedure P_MovePsprites(player: Pplayer_t);

//==============================================================================
//
// P_BulletSlope
//
//==============================================================================
procedure P_BulletSlope(mo: Pmobj_t);

//==============================================================================
//
// P_SetPsprite
//
//==============================================================================
procedure P_SetPsprite(player: Pplayer_t; position: integer; stnum: integer);

//
// Adjust weapon bottom and top
//
const
  WEAPONTOP = 32 * FRACUNIT;
  WEAPONBOTTOM = WEAPONTOP + 96 * FRACUNIT;

const
  LOWERSPEED = 6 * FRACUNIT;
  RAISESPEED = 6 * FRACUNIT;

implementation

uses
  d_delphi,
  i_system,
  info,
//
// Needs to include the precompiled
//  sprite animation tables.
// Header generated by multigen utility.
// This includes all the data for thing animation,
// i.e. the Thing Atrributes table
// and the Frame Sequence table.
  doomdef,
  d_event,
  d_items,
  m_rnd,
  p_common,
  p_local,
  p_tick,
  p_mobj,
  p_enemy,
  p_map,
  mars_sounds;

//
// P_SetPsprite
//
const
  PSPR_CYCLE_LIMIT = 1000000;

//==============================================================================
//
// P_SetPsprite
//
//==============================================================================
procedure P_SetPsprite(player: Pplayer_t; position: integer; stnum: integer);
var
  psp: Ppspdef_t;
  state: Pstate_t;
  cycle_counter: integer;
begin
  cycle_counter := 0;
  psp := @player.psprites[position];
  repeat
    if Ord(stnum) = 0 then
    begin
      // object removed itself
      psp.state := nil;
      break;
    end;

    state := @states[Ord(stnum)];
    psp.state := state;
    psp.tics := P_TicsFromState(state); // could be 0

    // coordinate set
    if state.misc1 <> 0 then
      psp.sx := state.misc1 * FRACUNIT;

    if state.misc2 <> 0 then
      psp.sy := state.misc2 * FRACUNIT;

    // Call action routine.
    // Modified handling.
    if Assigned(state.action.acp2) then
    begin
      if state.params <> nil then
        state.params.actor := player.mo;
      state.action.acp2(player, psp);
      if psp.state = nil then
        break;
    end;

    stnum := psp.state.nextstate;

    inc(cycle_counter);
    if cycle_counter > PSPR_CYCLE_LIMIT then
      I_Error('P_SetPsprite(): Infinite state cycle detected in player sprites (readyweapon=%d, pendinfweapon=%d)!',
        [Ord(player.readyweapon), Ord(player.pendingweapon)]);
  until psp.tics <> 0;
  // an initial state of 0 could cycle through
end;

//
// P_CalcSwing
//
var
  swingx: fixed_t;
  swingy: fixed_t;

//==============================================================================
//
// P_CalcSwing
//
//==============================================================================
procedure P_CalcSwing(player: Pplayer_t);
var
  swing: fixed_t;
  angle: integer;
begin
  // OPTIMIZE: tablify this.
  // A LUT would allow for different modes,
  //  and add flexibility.

  swing := player.bob;

  angle := (FINEANGLES div 70 * leveltime) and FINEMASK;
  swingx := FixedMul(swing, finesine[angle]);

  angle := (FINEANGLES div 70 * leveltime + FINEANGLES div 2) and FINEMASK;
  swingy := -FixedMul(swingx, finesine[angle]);
end;

//==============================================================================
//
// P_BringUpWeapon
// Starts bringing the pending weapon up
// from the bottom of the screen.
// Uses player
//
//==============================================================================
procedure P_BringUpWeapon(player: Pplayer_t);
var
  newstate: integer;
begin
  if player.pendingweapon = wp_nochange then
    player.pendingweapon := player.readyweapon;

  newstate := weaponinfo[Ord(player.pendingweapon)].upstate;

  player.pendingweapon := wp_nochange;
  player.psprites[Ord(ps_weapon)].sy := WEAPONBOTTOM;

  P_SetPsprite(player, Ord(ps_weapon), newstate);
end;

//==============================================================================
//
// P_CheckAmmo
// Returns true if there is enough ammo to shoot.
// If not, selects the next weapon to use.
//
//==============================================================================
function P_CheckAmmo(player: Pplayer_t): boolean;
var
  ammo: ammotype_t;
begin
  ammo := weaponinfo[Ord(player.readyweapon)].ammo;

  // Some do not need ammunition anyway.
  // Return if current ammunition sufficient.
  if (ammo = am_noammo) or (player.ammo[Ord(ammo)] > 0) then
  begin
    result := true;
    exit;
  end;

  // Out of ammo, pick a weapon to change to.
  // Preferences are set here.
  repeat
    if (player.weaponowned[Ord(wp_trackingmissile)] <> 0) and
       (player.ammo[Ord(am_trackingmisl)] > 0) then
      player.pendingweapon := wp_trackingmissile
    else if (player.weaponowned[Ord(wp_missile)] <> 0) and
            (player.ammo[Ord(am_misl)] > 0) then
      player.pendingweapon := wp_missile
    else if (player.weaponowned[Ord(wp_boomerang)] <> 0) and
            (player.ammo[Ord(am_disk)] > 0) then
      player.pendingweapon := wp_boomerang
    else if (player.weaponowned[Ord(wp_grenades)] <> 0) and
            (player.ammo[Ord(am_grenades)] > 0) then
      player.pendingweapon := wp_grenades
    else if (player.weaponowned[Ord(wp_flamegun)] <> 0) and
            (player.ammo[Ord(am_flamegunammo)] > 0) then
      player.pendingweapon := wp_flamegun
    else if (player.weaponowned[Ord(wp_freezegun)] <> 0) and
            (player.ammo[Ord(am_freezegunammo)] > 0) then
      player.pendingweapon := wp_freezegun
    else if (player.weaponowned[Ord(wp_nervegun)] <> 0) and
            (player.ammo[Ord(am_nervegunammo)] > 0) then
      player.pendingweapon := wp_nervegun
    else if (player.weaponowned[Ord(wp_shockgun)] <> 0) and
            (player.ammo[Ord(am_shockgunammo)] > 0) then
      player.pendingweapon := wp_shockgun
    else if (player.weaponowned[Ord(wp_pistol)] <> 0) and
            (player.ammo[Ord(am_bullet)] > 0) then
      player.pendingweapon := wp_pistol
    else
      // If everything fails.
      player.pendingweapon := wp_fist;

  until not (player.pendingweapon = wp_nochange);

  // Now set appropriate weapon overlay.
  P_SetPsprite(player, Ord(ps_weapon), weaponinfo[Ord(player.readyweapon)].downstate);

  result := false;
end;

//==============================================================================
//
// P_FireWeapon.
//
//==============================================================================
procedure P_FireWeapon(player: Pplayer_t);
var
  newstate: integer;
begin
  if P_CheckAmmo(player) then
  begin
    P_SetMobjState(player.mo, Ord(S_PLAY_ATK1));
    if (player.refire > 0) and (weaponinfo[Ord(player.readyweapon)].holdatkstate > 0) then
      newstate := weaponinfo[Ord(player.readyweapon)].holdatkstate
    else if weaponinfo[Ord(player.readyweapon)].atkstate > 0 then
      newstate := weaponinfo[Ord(player.readyweapon)].atkstate  // JVAL: 20211122 - Key sequences do not have attack state
    else
      exit;
    P_SetPsprite(player, Ord(ps_weapon), newstate);
    P_NoiseAlert(player.mo, player.mo);
  end;
end;

//==============================================================================
//
// P_DropWeapon
// Player died, so put the weapon away.
//
//==============================================================================
procedure P_DropWeapon(player: Pplayer_t);
begin
  P_SetPsprite(player, Ord(ps_weapon), weaponinfo[Ord(player.readyweapon)].downstate);
end;

//==============================================================================
//
// A_WeaponReady
// The player can fire the weapon
// or change to another weapon at this time.
// Follows after getting weapon up,
// or after previous attack/fire sequence.
//
//==============================================================================
procedure A_WeaponReady(player: Pplayer_t; psp: Ppspdef_t);
var
  newstate: integer;
  angle: integer;
begin
  // get out of attack state
  if (player.mo.state = @states[Ord(S_PLAY_ATK1)]) or
     (player.mo.state = @states[Ord(S_PLAY_ATK2)]) then
    P_SetMobjState(player.mo, Ord(S_PLAY))
  else if (player.mo.state = @states[Ord(S_CPLAY_ATK1)]) or
     (player.mo.state = @states[Ord(S_CPLAY_ATK2)]) then
    P_SetMobjState(player.mo, Ord(S_CPLAY))
  else if (player.mo.state = @states[Ord(S_FPLAY_ATK1)]) or
     (player.mo.state = @states[Ord(S_FPLAY_ATK2)]) then
    P_SetMobjState(player.mo, Ord(S_FPLAY));

  // check for change
  //  if player is dead, put the weapon away
  if (player.pendingweapon <> wp_nochange) or (player.health = 0) then
  begin
    // change weapon
    //  (pending weapon should allready be validated)
    newstate := weaponinfo[Ord(player.readyweapon)].downstate;
    P_SetPsprite(player, Ord(ps_weapon), newstate);
    exit;
  end;

  // check for fire
  //  the missile launcher and bfg do not auto fire
  if player.cmd.buttons and BT_ATTACK <> 0 then
  begin
    if not player.attackdown then
    begin
      player.attackdown := true;
      P_FireWeapon(player);
      exit;
    end;
  end
  else
    player.attackdown := false;

  // bob the weapon based on movement speed
  angle := (100 * leveltime) and FINEMASK;
  psp.sx := FRACUNIT + FixedMul(player.bob, finecosine[angle]) div 2;
  angle := angle and (FINEANGLES div 2 - 1);
  psp.sy := WEAPONTOP + FixedMul(player.bob, finesine[angle]) div 2;
end;

//==============================================================================
//
// A_ReFire
// The player can re-fire the weapon
// without lowering it entirely.
//
//==============================================================================
procedure A_ReFire(player: Pplayer_t; psp: Ppspdef_t);
begin
  // check for fire
  //  (if a weaponchange is pending, let it go through instead)
  if (player.cmd.buttons and BT_ATTACK <> 0) and
     (player.pendingweapon = wp_nochange) and
     (player.health > 0) then
  begin
    player.refire := player.refire + 1;
    P_FireWeapon(player);
  end
  else
  begin
    player.refire := 0;
    P_CheckAmmo(player);
  end;
end;

//==============================================================================
//
// A_CheckReload
//
//==============================================================================
procedure A_CheckReload(player: Pplayer_t; psp: Ppspdef_t);
begin
  P_CheckAmmo(player);
end;

//==============================================================================
//
// A_Lower
// Lowers current weapon,
//  and changes weapon at bottom.
//
//==============================================================================
procedure A_Lower(player: Pplayer_t; psp: Ppspdef_t);
begin
  psp.sy := psp.sy + LOWERSPEED;

  // Is already down.
  if psp.sy < WEAPONBOTTOM then
    exit;

  // Player is dead.
  if player.playerstate = PST_DEAD then
  begin
    psp.sy := WEAPONBOTTOM;
    // don't bring weapon back up
    exit;
  end;

  // The old weapon has been lowered off the screen,
  // so change the weapon and start raising it
  if player.health = 0 then
  begin
    // Player is dead, so keep the weapon off screen.
    P_SetPsprite(player, Ord(ps_weapon), Ord(S_NULL));
    exit;
  end;

  if weaponinfo[Ord(player.readyweapon)].flags and WF_WEAPON <> 0 then
    player.oldreadyweapon := player.readyweapon;
  player.readyweapon := player.pendingweapon;

  P_BringUpWeapon(player);
end;

//==============================================================================
//
// A_Raise
//
//==============================================================================
procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t);
var
  newstate: integer;
begin
  psp.sy := psp.sy - RAISESPEED;

  if psp.sy > WEAPONTOP then
    exit;

  psp.sy := WEAPONTOP;

  // The weapon has been raised all the way,
  //  so change to the ready state.
  newstate := weaponinfo[Ord(player.readyweapon)].readystate;

  P_SetPsprite(player, Ord(ps_weapon), newstate);
end;

//==============================================================================
//
// A_GunFlash
//
//==============================================================================
procedure A_GunFlash(player: Pplayer_t; psp: Ppspdef_t);
begin
  P_SetMobjState(player.mo, Ord(S_PLAY_ATK2));
  P_SetPsprite(player, Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate);
end;

//
// P_BulletSlope
// Sets a slope so a near miss is at aproximately
// the height of the intended target
//
var
  bulletslope: fixed_t;

//==============================================================================
//
// P_BulletSlope
//
//==============================================================================
procedure P_BulletSlope(mo: Pmobj_t);
var
  an: angle_t;
begin
  // see which target is to be aimed at
  an := mo.angle;
  bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);
    if linetarget = nil then
    begin
      an := an - $8000000;
      bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);
      if zaxisshift and (linetarget = nil) then
        bulletslope := (Pplayer_t(mo.player).lookdir * FRACUNIT) div 173;
    end;
  end;
end;

//==============================================================================
//
// P_GunShot
//
//==============================================================================
procedure P_GunShot(mo: Pmobj_t; accurate: boolean);
var
  angle: angle_t;
  damage: integer;
begin
  damage := 5 * ((P_Random mod 3) + 1);
  angle := mo.angle;

  if not accurate then
    angle := angle + _SHLW(P_Random - P_Random, 18);

  P_LineAttack(mo, angle, MISSILERANGE, bulletslope, damage);
end;

//==============================================================================
//
// A_FirePistol
//
//==============================================================================
procedure A_FirePistol(player: Pplayer_t; psp: Ppspdef_t);
var
  am: integer;
begin

  MARS_StartSound(player.mo, snd_GUN1SHT);

  P_SetMobjState(player.mo, Ord(S_PLAY_ATK2));

  am := Ord(weaponinfo[Ord(player.readyweapon)].ammo);
  player.ammo[am] := player.ammo[am] - 1;

  P_SetPsprite(player, Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate);

  P_BulletSlope(player.mo);
  P_GunShot(player.mo, player.refire = 0);
end;

//==============================================================================
//
// A_Light0
//
//==============================================================================
procedure A_Light0(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 0;
end;

//==============================================================================
//
// A_Light1
//
//==============================================================================
procedure A_Light1(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 1;
end;

//==============================================================================
//
// A_Light2
//
//==============================================================================
procedure A_Light2(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 2;
end;

//==============================================================================
//
// P_SetupPsprites
// Called at start of level for each player.
//
//==============================================================================
procedure P_SetupPsprites(player: Pplayer_t);
var
  i: integer;
begin
  // remove all psprites
  for i := 0 to Ord(NUMPSPRITES) - 1 do
    player.psprites[i].state := nil;

  // spawn the gun
  player.pendingweapon := player.readyweapon;
  P_BringUpWeapon(player);
end;

//==============================================================================
//
// P_MovePsprites
// Called every tic by player thinking routine.
//
//==============================================================================
procedure P_MovePsprites(player: Pplayer_t);
var
  i: integer;
  psp: Ppspdef_t;
  state: Pstate_t;
begin
  for i := 0 to Ord(NUMPSPRITES) - 1 do
  begin
    psp := @player.psprites[i];
    // a null state means not active
    state := psp.state;
    if state <> nil then
    begin
      // drop tic count and possibly change state
      // a -1 tic count never changes
      if psp.tics <> -1 then
      begin
        psp.tics := psp.tics - 1;
        if psp.tics = 0 then
          P_SetPsprite(player, i, psp.state.nextstate);
      end;
    end;
  end;

  player.psprites[Ord(ps_flash)].sx := player.psprites[Ord(ps_weapon)].sx;
  player.psprites[Ord(ps_flash)].sy := player.psprites[Ord(ps_weapon)].sy;
end;

end.
