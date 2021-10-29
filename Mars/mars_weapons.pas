//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars3D" based on DelphiDoom
//
//  Copyright (C) 1997 by Engine Technology CO. LTD
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2018 by Retro Fans of Mars3D
//  Copyright (C) 2004-2021 by Jim Valavanis
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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_weapons;

interface

uses
  d_player,
  p_mobj_h,
  p_pspr_h;

procedure A_PunchAndKick(player: Pplayer_t; psp: Ppspdef_t);

procedure A_BulletCartridgeDrop(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireShockGun(player: Pplayer_t; psp: Ppspdef_t);

procedure A_ShockGunSound(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FriendlyExplode(actor: Pmobj_t);

procedure A_FireNerveGun(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireFreezeGun(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireFlameGun(player: Pplayer_t; psp: Ppspdef_t);

procedure A_LowerWeapon(player: Pplayer_t; psp: Ppspdef_t);

implementation

uses
  d_delphi,
  doomdef,
  d_items,
  info_h,
  info,
  info_common,
  info_rnd,
  m_fixed,
  m_rnd,
  tables,
  p_common,
  p_map,
  p_maputl,
  p_mobj,
  p_local,
  p_pspr,
  p_setup,
  p_tick,
  r_main,
  s_sound;

procedure A_PunchAndKick(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
begin
  S_StartSound(player.mo, 'FISTSHT');

  damage := (P_Random mod 10 + 1) * 2;

  if player.powers[Ord(pw_strength)] <> 0 then
    damage := damage * 10;

  angle := player.mo.angle;
  angle := angle + _SHLW(P_Random - P_Random, 18);
  slope := P_AimLineAttack(player.mo, angle, MELEERANGE);
  P_LineAttack(player.mo, angle, MELEERANGE, slope, damage);

  // turn to face target
  if linetarget <> nil then
  begin
    S_StartSound(player.mo, 'FISTEXP');
    player.mo.angle :=
      R_PointToAngle2(player.mo.x, player.mo.y, linetarget.x, linetarget.y);
  end;
end;

var
  MT_BULLETCARTRIDGE: integer = -2;

procedure A_BulletCartridgeDrop(player: Pplayer_t; psp: Ppspdef_t);
var
  x, y, z: fixed_t;
  ang: angle_t;
  mo: Pmobj_t;
begin
  if MT_BULLETCARTRIDGE = -2 then
    MT_BULLETCARTRIDGE := Info_GetMobjNumForName('MT_BULLETCARTRIDGE');

  if MT_BULLETCARTRIDGE < 0 then
    Exit;

  x := player.mo.x;
  y := player.mo.y;
  z := player.mo.z + PVIEWHEIGHT;

  ang := player.mo.angle;
  x := x + finecosine[ang shr ANGLETOFINESHIFT] * 24;
  y := y + finesine[ang shr ANGLETOFINESHIFT] * 24;

  mo := P_SpawnMobj(x, y, z, MT_BULLETCARTRIDGE);
  ang := ang + ANG90;
  mo.angle := ang;

  mo.momx := player.mo.momx + finecosine[ang shr ANGLETOFINESHIFT] * 4;
  mo.momy := player.mo.momy + finesine[ang shr ANGLETOFINESHIFT] * 4;
  mo.momz := player.mo.momz + 3 * FRACUNIT;
end;

var
  MT_SHOCKGUNMISSILE: integer = -2;

procedure A_FireShockGun(player: Pplayer_t; psp: Ppspdef_t);
begin
  if MT_SHOCKGUNMISSILE = -2 then
    MT_SHOCKGUNMISSILE := Info_GetMobjNumForName('MT_SHOCKGUNMISSILE');

  if MT_SHOCKGUNMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  P_SpawnPlayerMissile(player.mo, MT_SHOCKGUNMISSILE);
end;

procedure A_ShockGunSound(player: Pplayer_t; psp: Ppspdef_t);
begin
  S_StartSound(player.mo, 'GUN2ACT');
end;

// A_FriendlyExplode

var
  fe_x, fe_y: fixed_t;
  fe_dist: fixed_t;
  fe_tics: integer;

function PIT_FriendlyExplode(thing: Pmobj_t): boolean;
begin
  Result := True;

  if thing.health <= 0 then
    Exit;

  if thing.flags2_ex and MF2_EX_FRIEND <> 0 then
    if thing.friendtics = 0 then
      Exit;

  if thing.friendticstime = leveltime then
    Exit;
    
  if not Info_IsMonster(thing._type) then
    Exit;

  if P_AproxDistance(fe_x - thing.x, fe_y - thing.y) > fe_dist + thing.radius then
    Exit;

  thing.friendtics := thing.friendtics + fe_tics;
  thing.friendticstime := leveltime;
  thing.flags2_ex := thing.flags2_ex or MF2_EX_FRIEND;

//  if thing.state <> @states[thing.info.seestate] then
//    P_SetMobjStateNF(thing, statenum_t(thing.info.seestate));
end;

procedure A_FriendlyExplode(actor: Pmobj_t);
const
  DEF_TICS = 10 * TICRATE;
  DEF_RADIUS = 128 * FRACUNIT;
var
  tics: integer;
  radius, r2: integer;
  x, y: fixed_t;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
begin
  tics := actor.state.params.IntVal[0];
  if tics <= 0 then
    tics := DEF_TICS;

  radius := actor.state.params.FixedVal[1];
  if radius <= 0 then
    radius := DEF_RADIUS;

  x := actor.x;
  y := actor.y;

  r2 := radius div 2;
  if internalblockmapformat then
  begin
    xl := MapBlockIntX(int64(x) - int64(bmaporgx) - r2);
    xh := MapBlockIntX(int64(x) - int64(bmaporgx) + r2);
    yl := MapBlockIntY(int64(y) - int64(bmaporgy) - r2);
    yh := MapBlockIntY(int64(y) - int64(bmaporgy) + r2);
  end
  else
  begin
    xl := MapBlockInt(x - bmaporgx - r2);
    xh := MapBlockInt(x - bmaporgx + r2);
    yl := MapBlockInt(y - bmaporgy - r2);
    yh := MapBlockInt(y - bmaporgy + r2);
  end;

  fe_x := x;
  fe_y := y;
  fe_dist := r2;
  fe_tics := tics;

  for bx := xl to xh do
    for by := yl to yh do
      if P_BlockThingsIterator(bx, by, PIT_FriendlyExplode) then
end;

var
  MT_NERVEGUNMISSILE: integer = -2;

procedure A_FireNerveGun(player: Pplayer_t; psp: Ppspdef_t);
begin
  if MT_NERVEGUNMISSILE = -2 then
    MT_NERVEGUNMISSILE := Info_GetMobjNumForName('MT_NERVEGUNMISSILE');

  if MT_NERVEGUNMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  P_SpawnPlayerMissile(player.mo, MT_NERVEGUNMISSILE);
end;

var
  MT_FREEZEGUNMISSILE: integer = -2;

procedure A_FireFreezeGun(player: Pplayer_t; psp: Ppspdef_t);
begin
  if MT_FREEZEGUNMISSILE = -2 then
    MT_FREEZEGUNMISSILE := Info_GetMobjNumForName('MT_FREEZEGUNMISSILE');

  if MT_FREEZEGUNMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  P_SpawnPlayerMissile(player.mo, MT_FREEZEGUNMISSILE);
end;

var
  MT_FLAMEGUNMISSILE: integer = -2;

procedure A_FireFlameGun(player: Pplayer_t; psp: Ppspdef_t);
begin
  if MT_FLAMEGUNMISSILE = -2 then
    MT_FLAMEGUNMISSILE := Info_GetMobjNumForName('MT_FLAMEGUNMISSILE');

  if MT_FLAMEGUNMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate));

  P_SpawnPlayerMissile(player.mo, MT_FLAMEGUNMISSILE);
end;

//
// A_LowerWeapon(const speed: float)
//
procedure A_LowerWeapon(player: Pplayer_t; psp: Ppspdef_t);
var
  speed: fixed_t;
begin
  speed := LOWERSPEED;
  if psp.state.params <> nil then
    if psp.state.params.Count > 0 then
      speed := psp.state.params.FixedVal[0];

  psp.sy := psp.sy + speed;

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
    P_SetPsprite(player, Ord(ps_weapon), S_NULL);
    exit;
  end;
end;

end.
