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

procedure A_RaiseWeapon(player: Pplayer_t; psp: Ppspdef_t);

procedure A_ThowGrenade(player: Pplayer_t; psp: Ppspdef_t);

procedure A_BoomerangDisk(actor: Pmobj_t);

procedure A_ThowBoomerangDisk(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRocketMissile(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireTrackingMissile(player: Pplayer_t; psp: Ppspdef_t);

procedure A_RestoreReadyWeapon(player: Pplayer_t; psp: Ppspdef_t);

procedure A_DoPendingDoor(player: Pplayer_t; psp: Ppspdef_t);

implementation

uses
  d_delphi,
  d_englsh,
  doomdef,
  d_items,
  g_game,
  info_h,
  info,
  info_common,
  info_rnd,
  mars_map_extra,
  mars_sounds,
  m_fixed,
  m_rnd,
  tables,
  p_common,
  p_doors,
  p_inter,
  p_map,
  p_maputl,
  p_mobj,
  p_local,
  p_pspr,
  p_setup,
  p_sight,
  p_spec,
  p_switch,
  p_tick,
  r_defs,
  r_main,
  s_sound;

procedure A_PunchAndKick(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
begin
  MARS_StartSound(player.mo, snd_FISTSHT);

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
    MARS_StartSound(linetarget, snd_FISTEXP);
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
  z := player.mo.z + player.viewheight;

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
    Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1));

  P_SpawnPlayerMissile(player.mo, MT_SHOCKGUNMISSILE);
end;

procedure A_ShockGunSound(player: Pplayer_t; psp: Ppspdef_t);
begin
  MARS_StartSound(player.mo, snd_GUN2ACT);
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

  if thing.flags2_ex and MF_EX_BOSS <> 0 then
      Exit; // No nerve damage for bosses

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
    Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1));

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
    Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1));

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
    Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate);

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
    P_SetPsprite(player, Ord(ps_weapon), Ord(S_NULL));
    exit;
  end;
end;

procedure A_RaiseWeapon(player: Pplayer_t; psp: Ppspdef_t);
var
  speed: fixed_t;
begin
  speed := RAISESPEED;
  if psp.state.params <> nil then
    if psp.state.params.Count > 0 then
      speed := psp.state.params.FixedVal[0];

  psp.sy := psp.sy - speed;

  if psp.sy > WEAPONTOP then
    exit;

  psp.sy := WEAPONTOP;
end;

var
  MT_GRENADEMISSILE: integer = -2;

procedure A_ThowGrenade(player: Pplayer_t; psp: Ppspdef_t);
begin
  if MT_GRENADEMISSILE = -2 then
    MT_GRENADEMISSILE := Info_GetMobjNumForName('MT_GRENADEMISSILE');

  if MT_GRENADEMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SpawnPlayerMissile(player.mo, MT_GRENADEMISSILE);
end;

// A_BoomerangDisk

var
  bdisk: Pmobj_t;

const
  BOOMERANGDISK_RANGE = 32 * FRACUNIT;
  BOOMERANGDISK_DAMAGE = 1;
  BOOMERANGDISK_TIMEOUT = TICRATE;
  BOOMERANGDISK_LOWFLOOR = 2 * FRACUNIT;

function PIT_BoomerangDisk(thing: Pmobj_t): boolean;
var
  p: Pplayer_t;
  dist: fixed_t;
  dist2: fixed_t;
  damage: integer;
begin
  if thing = bdisk then
  begin
    result := true;
    exit;
  end;

  if not P_ThingsInSameZ(thing, bdisk) then
  begin
    result := true;
    exit;
  end;

  dist := P_AproxDistance(thing.x - bdisk.x, thing.y - bdisk.y);

  dist := dist - thing.radius;

  if dist < 0 then
    dist := 0;

  if dist >= BOOMERANGDISK_RANGE then
  begin
    result := true; // out of range
    exit;
  end;

  p := thing.player;
  if p <> nil then
    if p.playerstate = PST_LIVE then
      if leveltime - bdisk.spawntime > BOOMERANGDISK_TIMEOUT then
      begin
        if p.ammo[Ord(am_disk)] < p.maxammo[Ord(am_disk)] then
        begin
          p.ammo[Ord(am_disk)] := p.ammo[Ord(am_disk)] + 1;
          P_RemoveMobj(bdisk);
          if p = @players[consoleplayer] then
            MARS_StartSound(nil, snd_ITEMUP);
          p._message := RETURNDISK;
          result := false;  // Stop
          exit;
        end;
      end;

  if (thing.flags and MF_SHOOTABLE <> 0) and (p = nil) then
  begin
    damage := BOOMERANGDISK_DAMAGE;

    if bdisk.flags3_ex and MF3_EX_FREEZEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFREEZEDAMAGE <> 0 then
        damage := 0;

    if bdisk.flags3_ex and MF3_EX_FLAMEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFLAMEDAMAGE <> 0 then
        damage := 0;

    if bdisk.flags4_ex and MF4_EX_SHOCKGUNDAMAGE <> 0 then
      if thing.flags4_ex and MF4_EX_NOSHOCKGUNDAMAGE <> 0 then
        damage := 0;

    if damage > 0 then
      if P_CheckSight(thing, bdisk) then
        P_DamageMobj(thing, bdisk, bdisk, damage);
  end;

  if dist <= bdisk.radius + thing.radius then
  begin
    dist2 := P_AproxDistance(thing.x - bdisk.x - bdisk.momx, thing.y - bdisk.y - bdisk.momy);
    if dist2 < dist then  // Disk is going towards thing
    begin
      P_MobjBounceMobj(bdisk, thing);
      result := false;
      exit;
    end;
  end;

  result := true;
end;

procedure P_BoomerangDisk(spot: Pmobj_t);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := BOOMERANGDISK_RANGE;
  if internalblockmapformat then
  begin
    yh := MapBlockIntY(int64(spot.y) + int64(dist) - int64(bmaporgy));
    yl := MapBlockIntY(int64(spot.y) - int64(dist) - int64(bmaporgy));
    xh := MapBlockIntX(int64(spot.x) + int64(dist) - int64(bmaporgx));
    xl := MapBlockIntX(int64(spot.x) - int64(dist) - int64(bmaporgx));
  end
  else
  begin
    yh := MapBlockInt(spot.y + dist - bmaporgy);
    yl := MapBlockInt(spot.y - dist - bmaporgy);
    xh := MapBlockInt(spot.x + dist - bmaporgx);
    xl := MapBlockInt(spot.x - dist - bmaporgx);
  end;

  bdisk := spot;

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_BoomerangDisk);
end;

function P_BoomerangDiskReturn(const mo: Pmobj_t; const p: Pplayer_t): boolean;
var
  targetang, diskang: angle_t;
  dist: fixed_t;
  itargetang, idiskang: integer;
  newang: angle_t;
  speed: fixed_t;
  slope: fixed_t;
begin
  Result := False;

  if p.mo = nil then
    Exit;

  if not P_CheckSight(mo, p.mo) then
    Exit;

  targetang := R_PointToAngle2(mo.x, mo.y, p.mo.x, p.mo.y);
  diskang := mo.angle;

  speed := FixedSqrt(FixedMul(mo.momx, mo.momx) + FixedMul(mo.momy, mo.momy));

  if targetang <> diskang then
  begin
    itargetang := targetang div ANGLETOFINEUNIT;
    idiskang := diskang div ANGLETOFINEUNIT;

    // Turn towads player
    if (Abs(itargetang - idiskang) < ANG45 div ANGLETOFINEUNIT) or
      (Abs(itargetang - idiskang) > ANG315 div ANGLETOFINEUNIT) then
    begin
      if Abs(itargetang - idiskang) < ANG45 div ANGLETOFINEUNIT then
      begin
        if itargetang > idiskang then
          newang := diskang + ANG5
        else
          newang := diskang - ANG5;
      end
      else
      begin
        if itargetang > idiskang then
          newang := diskang - ANG5
        else
          newang := diskang + ANG5;
      end;

      mo.angle := newang;
      newang := newang div ANGLETOFINEUNIT;

      mo.momx := FixedMul(speed, finecosine[newang]);
      mo.momy := FixedMul(speed, finesine[newang]);
    end;
  end;

  if speed >= FRACUNIT then
  begin
    // change slope
    dist := P_AproxDistance(p.mo.x - mo.x, p.mo.y - mo.y);

    dist := dist div speed;

    if dist < 1 then
      dist := 1;
    if p.mo.height >= 56 * FRACUNIT then
      slope := (p.mo.z + 40 * FRACUNIT - mo.z) div dist
    else
      slope := (p.mo.z + mo.height * 2 div 3 - mo.z) div dist;

    if slope < mo.momz then
      mo.momz := mo.momz - FRACUNIT div 8
    else
      mo.momz := mo.momz + FRACUNIT div 8;
  end;

  Result := True;
end;

procedure P_BoomerangFriction(actor: Pmobj_t);
begin
  actor.momx := actor.momx * 15 div 16;
  actor.momy := actor.momy * 15 div 16;
end;

procedure P_BoomerangAccelerate(actor: Pmobj_t);
begin
  if P_AproxDistance(actor.momx, actor.momy) < actor.info.speed * 15 div 16 then
  begin
    actor.momx := actor.momx * 17 div 16;
    actor.momy := actor.momy * 17 div 16;
  end;
end;

procedure A_BoomerangDisk(actor: Pmobj_t);
var
  i: integer;
begin
  if (actor.velocityxy < FRACUNIT) or ((Abs(actor.momx) < FRACUNIT) and (Abs(actor.momy) < FRACUNIT)) then
    if leveltime - actor.spawntime > BOOMERANGDISK_TIMEOUT then
    begin
      actor.flags := actor.flags or MF_SPECIAL;
      actor.flags := actor.flags and not MF_NOGRAVITY;
      actor.flags3_ex := actor.flags3_ex and not MF3_EX_THRUACTORS;
      P_BoomerangFriction(actor);
      exit;
    end;

  actor.angle := R_PointToAngle2(0, 0, actor.momx, actor.momy);
  if actor.z - actor.floorz < BOOMERANGDISK_LOWFLOOR then // Apply friction
    P_BoomerangFriction(actor)
  else
    P_BoomerangAccelerate(actor);

  P_BoomerangDisk(actor);

  if actor.health <= 0 then
    exit;

  if leveltime - actor.spawntime > BOOMERANGDISK_TIMEOUT then
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
        if P_BoomerangDiskReturn(actor, @players[i]) then
          Break;
end;

var
  MT_DISKMISSILE: integer = -2;

procedure A_ThowBoomerangDisk(player: Pplayer_t; psp: Ppspdef_t);
var
  x, y, z: fixed_t;
  dist: fixed_t;
  ang: angle_t;
  th: Pmobj_t;
  speed: fixed_t;
  slope: fixed_t;
begin
  if MT_DISKMISSILE = -2 then
    MT_DISKMISSILE := Info_GetMobjNumForName('MT_DISKMISSILE');

  if MT_DISKMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  dist := player.mo.info.radius + mobjinfo[MT_DISKMISSILE].radius + 4 * FRACUNIT;
  ang := player.mo.angle div ANGLETOFINEUNIT;
  x := player.mo.x + FixedMul(dist, finecosine[ang]);
  y := player.mo.y + FixedMul(dist, finesine[ang]);
  slope := (player.lookdir * FRACUNIT) div 173;
  z := player.mo.z + player.viewheight + slope;

  th := P_SpawnMobj(x, y, z, MT_DISKMISSILE);

  S_StartSound(th, mobjinfo[MT_DISKMISSILE].seesound);

  th.angle := player.mo.angle + (((P_Random - P_Random) * ANG5) div 256);

  speed := mobjinfo[MT_DISKMISSILE].speed;

  th.momx := FixedMul(speed, finecosine[ang]);
  th.momy := FixedMul(speed, finesine[ang]);
  th.momz := FixedMul(speed, slope);
end;


var
  MT_ROCKETMISSILE: integer = -2;

procedure A_FireRocketMissile(player: Pplayer_t; psp: Ppspdef_t);
begin
  if MT_ROCKETMISSILE = -2 then
    MT_ROCKETMISSILE := Info_GetMobjNumForName('MT_ROCKETMISSILE');

  if MT_ROCKETMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SetPsprite(player,
    Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate);

  P_SpawnPlayerMissile(player.mo, MT_ROCKETMISSILE);
end;


var
  MT_TRACKINGROCKETMISSILE: integer = -2;

procedure A_FireTrackingMissile(player: Pplayer_t; psp: Ppspdef_t);
begin
  if MT_TRACKINGROCKETMISSILE = -2 then
    MT_TRACKINGROCKETMISSILE := Info_GetMobjNumForName('MT_TRACKINGROCKETMISSILE');

  if MT_TRACKINGROCKETMISSILE < 0 then
    Exit;

  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SetPsprite(player,
    Ord(ps_flash), weaponinfo[Ord(player.readyweapon)].flashstate);

  P_SpawnPlayerMissile(player.mo, MT_TRACKINGROCKETMISSILE);
end;

procedure A_RestoreReadyWeapon(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.pendingweapon := player.oldreadyweapon;
end;

procedure A_DoPendingDoor(player: Pplayer_t; psp: Ppspdef_t);
var
  line: Pline_t;
begin
  if (player.pendingline >= 0) and (player.pendingline < numlines) then
  begin
    line := @lines[player.pendingline];
    if EV_DoDoor(line, vldoor_e(player.pendinglinetype)) <> 0 then
      P_ChangeSwitchTexture(line, player.pendinglineuseagain);
  end;
end;

end.
