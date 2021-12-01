//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars - The Ultimate Fighter"
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
// DESCRIPTION:
//  Player related stuff.
//  Bobbing POV/weapon, movement.
//  Pending weapon.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_user;

interface

uses
  p_mobj_h,
  d_player;

procedure P_PlayerThink(player: Pplayer_t);

procedure P_CalcHeight(player: Pplayer_t);

procedure P_PlayerFaceMobj(const player: Pplayer_t; const face: Pmobj_t; const ticks: integer);

var
  allowplayerbreath: Boolean = false;

implementation

uses
  d_delphi,
  m_fixed,
  m_rnd,
  tables,
  d_ticcmd,
  d_event,
  info_h,
  info,
{$IFDEF DEBUG}
  i_io,
{$ENDIF}
  g_game,
  mars_player,
  p_genlin,
  p_mobj,
  p_tick,
  p_pspr,
  p_local,
  p_setup,    // JVAL: 3d Floors
  p_slopes,   // JVAL: Slopes
  p_3dfloors, // JVAL: Slopes
  p_spec,
  p_map,
  p_maputl,
  p_underwater,
  r_main,
  r_defs,
  sounds,
  s_sound,
  doomdef;

//
// Movement.
//
const
// 16 pixels of bob
  MAXBOB = $100000;

var
  onground: boolean;

//
// P_Thrust
// Moves the given origin along a given angle.
//
procedure P_Thrust(player: Pplayer_t; angle: angle_t; const move: fixed_t);
begin
  {$IFDEF FPC}
  angle := _SHRW(angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := angle shr ANGLETOFINESHIFT;
  {$ENDIF}

  player.mo.momx := player.mo.momx + FixedMul(move, finecosine[angle]);
  player.mo.momy := player.mo.momy + FixedMul(move, finesine[angle]);
end;

//
// P_CalcHeight
// Calculate the walking / running height adjustment
//
procedure P_CalcHeight(player: Pplayer_t);
var
  angle: integer;
  clheight: fixed_t; // JVAL: 20211101 - Crouch
  flheight: fixed_t; // JVAL: 20211101 - Crouch
  range: fixed_t; // JVAL: 20211101 - Crouch
begin
  // Regular movement bobbing
  // (needs to be calculated for gun swing
  // even if not on ground)
  // OPTIMIZE: tablify angle
  // Note: a LUT allows for effects
  //  like a ramp with low health.

  if (player.mo.flags4_ex and MF4_EX_FLY <> 0) and not onground then  // JVAL: 20211109 - Fly (Jet pack)
    player.bob := FRACUNIT div 2
  else
  begin
    player.bob := FixedMul(player.mo.momx, player.mo.momx) +
                  FixedMul(player.mo.momy, player.mo.momy);
    player.bob := player.bob div 4;

    if player.bob > MAXBOB then
      player.bob := MAXBOB;
  end;

  player.oldviewz := player.viewz;  // JVAL: Slopes

  // JVAL: 20211101 - Crouch
  player.mo.height := player.mo.info.height - player.crouchheight;
  clheight := P_3dCeilingHeight(player.mo);
  if player.mo.z + player.mo.height > clheight then
  begin
    flheight := P_3dFloorHeight(player.mo);
    player.mo.z := clheight - player.mo.height;
    if player.mo.z < flheight then
    begin
      player.mo.z := flheight;
      player.lastautocrouchtime := leveltime;
      player.lastongroundtime := leveltime;
      range := clheight - flheight;
      player.crouchheight := player.mo.info.height - range;
      if player.crouchheight > PMAXCROUCHHEIGHT then
        player.crouchheight := PMAXCROUCHHEIGHT;
      player.mo.height := player.mo.info.height - player.crouchheight;
    end;
  end;

  if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then
  begin
    player.viewz := player.mo.z + PVIEWHEIGHT - player.crouchheight;

    if player.viewz > player.mo.ceilingz - NEARVIEWZ then
      player.viewz := player.mo.ceilingz - NEARVIEWZ;
    if player.viewz < player.mo.floorz + NEARVIEWZ then
      player.viewz := player.mo.floorz + NEARVIEWZ;

//    player.viewz := player.mo.z + player.viewheight;  JVAL removed!
    exit;
  end;

  angle := (FINEANGLES div 20 * leveltime) and FINEMASK;
  player.viewbob := FixedMul(player.bob div 2, finesine[angle]);

  // move viewheight
  if player.playerstate = PST_LIVE then
  begin
    player.viewheight := player.viewheight + player.deltaviewheight;

    if player.viewheight > PVIEWHEIGHT then
    begin
      player.viewheight := PVIEWHEIGHT;
      player.deltaviewheight := 0;
    end;

    if player.viewheight < PVIEWHEIGHT div 2 then
    begin
      player.viewheight := PVIEWHEIGHT div 2;
      if player.deltaviewheight <= 0 then
        player.deltaviewheight := 1;
    end;

    if player.deltaviewheight <> 0 then
    begin
      player.deltaviewheight := player.deltaviewheight + FRACUNIT div 4;
      if player.deltaviewheight = 0 then
        player.deltaviewheight := 1;
    end;
  end;
  player.viewz := player.mo.z + player.viewheight + player.viewbob - player.crouchheight; // JVAL: 20211101 - Crouch

  if player.mo.flags4_ex and MF4_EX_VIEWZCALCED <> 0 then
    player.viewz := player.viewz div 2 + player.oldviewz div 2
  else
    player.mo.flags4_ex := player.mo.flags4_ex or MF4_EX_VIEWZCALCED;

  // JVAL: 20211114 - For underwater
  if (player.mo.floorclip <> 0) and
     (player.playerstate <> PST_DEAD) and
     (player.mo.z <= player.mo.floorz) then
    player.viewz := player.viewz - player.mo.floorclip;

  // JVAL: 20211117 - Prevent underwater view when underwater portal not allowed
  if player.nextunderwaterportaltic > leveltime then
  begin
    if Psubsector_t(player.mo.subsector).sector.special = 14 then
      if player.viewz < player.mo.floorz + PUNDERWATERPORTALHEIGHT + VERYNEARVIEWZ then
        player.viewz := player.mo.floorz + PUNDERWATERPORTALHEIGHT + VERYNEARVIEWZ;
    // JVAL: 20211118 - Prevent upwater view when underwater portal not allowed
    // (actually this is prevented by the NEARVIEWZ, but in case that some consts are changed...
    if Psubsector_t(player.mo.subsector).sector.special = 10 then
      if player.viewz > player.mo.ceilingz - PUNDERWATERSECTORCHEIGHT - VERYNEARVIEWZ then
        player.viewz := player.mo.ceilingz - PUNDERWATERSECTORCHEIGHT - VERYNEARVIEWZ;
  end;

  if player.viewz > player.mo.ceilingz - NEARVIEWZ then
    player.viewz := player.mo.ceilingz - NEARVIEWZ;
  if player.viewz < player.mo.floorz + NEARVIEWZ then
    player.viewz := player.mo.floorz + NEARVIEWZ;

  {$IFDEF DEBUG}
  printf('leveltime=%5d,viewz=%6d,viewheight=%6d,viewbob=%6d,deltaviewheight=%6d,crouchheight=%6d,x=%6d,y=%6d,z=%6d'#13#10, [
    leveltime, player.viewz, player.viewheight, player.viewbob, player.deltaviewheight, player.crouchheight, player.mo.x, player.mo.y, player.mo.z]);
  {$ENDIF}
end;

function P_GetMoveFactor(const mo: Pmobj_t): fixed_t;
var
  momentum, friction: integer;
begin
  result := ORIG_FRICTION_FACTOR;

  // If the floor is icy or muddy, it's harder to get moving. This is where
  // the different friction factors are applied to 'trying to move'. In
  // p_mobj.c, the friction factors are applied as you coast and slow down.

  if (mo.flags and (MF_NOGRAVITY or MF_NOCLIP) = 0) and
     (mo.flags_ex and MF_EX_LOWGRAVITY = 0) then
  begin
    friction := mo.friction;
    if friction = ORIG_FRICTION then            // normal floor

    else if friction > ORIG_FRICTION then       // ice
    begin
      result := mo.movefactor;
      mo.movefactor := ORIG_FRICTION_FACTOR;    // reset
    end
    else                                        // sludge
    begin

      // phares 3/11/98: you start off slowly, then increase as
      // you get better footing

      momentum := P_AproxDistance(mo.momx, mo.momy);
      result := mo.movefactor;
      if momentum > MORE_FRICTION_MOMENTUM shl 2 then
        result := result shl 3
      else if momentum > MORE_FRICTION_MOMENTUM shl 1 then
        result := result shl 2
      else if momentum > MORE_FRICTION_MOMENTUM then
        result := result shl 1;

      mo.movefactor := ORIG_FRICTION_FACTOR;  // reset
    end;
  end;
end;

//
// P_MovePlayer
//
procedure P_MovePlayer(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  look: integer;
  look16: integer; // JVAL Smooth Look Up/Down
  look2: integer;
  fly: integer; // JVAL: 20211109 - Fly (Jet pack)
  onair: boolean; // JVAL: 20211109 - Fly (Jet pack)
  onwater: boolean; // JVAL: 20211116 - Swimming mode (Underwater sectors)
  movefactor: fixed_t;
  an: angle_t;
  xyspeed: fixed_t;
begin
  cmd := @player.cmd;

  player.mo.angle := player.mo.angle + _SHLW(cmd.angleturn, 16);

  // Do not let the player control movement
  //  if not onground.
  onground := player.mo.z <= player.mo.floorz;

  if not onground then
    onground := player.mo.flags2_ex and MF2_EX_ONMOBJ <> 0;

  if onground then
    player.lastongroundtime := leveltime; // JVAL: 20211101 - Crouch

  onair := (player.cheats and CF_LOWGRAVITY <> 0) or (player.mo.flags4_ex and MF4_EX_FLY <> 0); // JVAL: 20211109 - Fly (Jet pack)
  onwater := player.mo.flags4_ex and MF4_EX_SWIM <> 0; // JVAL: 20211109 - Swim mode (Underwater sectors)
  // villsa [STRIFE] allows player to climb over things by jumping
  // haleyjd 20110205: air control thrust should be 256, not cmd.forwardmove
  if not onground and not onair and not onwater and (cmd.forwardmove <> 0) then  // JVAL: 20211109 - Fly (Jet pack)
  begin
    P_Thrust(player, player.mo.angle, 256);
  end
  else
  begin
    if onwater then
      movefactor := SWIM_FRICTION_FACTOR  // JVAL: 20211109 - Swim mode (Underwater sectors)
    else
      movefactor := ORIG_FRICTION_FACTOR;

    if player.cheats and CF_LOWGRAVITY = 0 then
      if Psubsector_t(player.mo.subsector).sector.special and FRICTION_MASK <> 0 then
        movefactor := P_GetMoveFactor(player.mo); //movefactor * 2;

    // JVAL: 20211101 - Crouch
    if cmd.crouch > 0 then
      movefactor := FixedMul(FixedDiv(CROUCH_FRICTION_FACTOR, ORIG_FRICTION_FACTOR), movefactor);

    if onair or // JVAL: 20211109 - Fly (Jet pack)
       onwater or // JVAL: 20211109 - Swim mode (Underwater sectors)
      ((cmd.forwardmove <> 0) and
       (onground or ((cmd.jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0)))) then
      P_Thrust(player, player.mo.angle, cmd.forwardmove * movefactor);

    if onair or // JVAL: 20211109 - Fly (Jet pack)
       onwater or // JVAL: 20211109 - Swim mode (Underwater sectors)
      ((cmd.sidemove <> 0) and
       (onground or ((cmd.jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0)))) then
      P_Thrust(player, player.mo.angle - ANG90, cmd.sidemove * movefactor);
  end;

  // JVAL: Adjust speed while flying
  if onair and not onwater and (player.mo.z > player.mo.floorz) then  // JVAL: 20211109 - Fly (Jet pack)
  begin
    if player.mo.momx > MAX_PLAYERAIRMOVE then
      player.mo.momx := MAX_PLAYERAIRMOVE
    else if player.mo.momx < -MAX_PLAYERAIRMOVE then
      player.mo.momx := -MAX_PLAYERAIRMOVE;
    if player.mo.momy > MAX_PLAYERAIRMOVE then
      player.mo.momy := MAX_PLAYERAIRMOVE
    else if player.mo.momy < -MAX_PLAYERAIRMOVE then
      player.mo.momy := -MAX_PLAYERAIRMOVE;

    if (cmd.forwardmove = 0) and (cmd.sidemove = 0) then
    begin
      player.mo.momx := player.mo.momx * 15 div 16;
      player.mo.momy := player.mo.momy * 15 div 16;
    end;
  end
  else if onwater then
  begin
    if cmd.swim <> 0 then
      player.mo.momz := player.mo.momz + cmd.swim * FRACUNIT; // JVAL: 20211116 - Swim mode (Underwater sectors)

    if player.mo.momz > MAX_PLAYERSWIMZMOVE then
      player.mo.momz := MAX_PLAYERSWIMZMOVE
    else if player.mo.momz < -MAX_PLAYERSWIMZMOVE then
      player.mo.momz := -MAX_PLAYERSWIMZMOVE;

    if player.mo.z > player.mo.floorz then  // JVAL: 20211116 - Swim mode (Underwater sectors)
    begin
      if player.mo.momx > MAX_PLAYERSWIMMOVE then
        player.mo.momx := MAX_PLAYERSWIMMOVE
      else if player.mo.momx < -MAX_PLAYERSWIMMOVE then
        player.mo.momx := -MAX_PLAYERSWIMMOVE;
      if player.mo.momy > MAX_PLAYERSWIMMOVE then
        player.mo.momy := MAX_PLAYERSWIMMOVE
      else if player.mo.momy < -MAX_PLAYERSWIMMOVE then
        player.mo.momy := -MAX_PLAYERSWIMMOVE;
    end
    else
    begin
      if player.mo.momx > MAX_PLAYERWATERMOVE then
        player.mo.momx := MAX_PLAYERWATERMOVE
      else if player.mo.momx < -MAX_PLAYERWATERMOVE then
        player.mo.momx := -MAX_PLAYERWATERMOVE;
      if player.mo.momy > MAX_PLAYERWATERMOVE then
        player.mo.momy := MAX_PLAYERWATERMOVE
      else if player.mo.momy < -MAX_PLAYERWATERMOVE then
        player.mo.momy := -MAX_PLAYERWATERMOVE;
    end;

    if (cmd.forwardmove = 0) and (cmd.sidemove = 0) then
    begin
      player.mo.momx := player.mo.momx * 11 div 12;
      player.mo.momy := player.mo.momy * 11 div 12;
    end;
  end
  else if player.mo.flags2_ex and MF2_EX_ONMOBJ <> 0 then
  begin
    if (cmd.forwardmove = 0) and (cmd.sidemove = 0) then
    begin
      player.mo.momx := player.mo.momx * 15 div 16;
      player.mo.momy := player.mo.momy * 15 div 16;
    end;
  end;

  if (cmd.forwardmove <> 0) or (cmd.sidemove <> 0) then
  begin
    if player.mo.state = @states[Ord(S_PLAY)] then
      P_SetMobjState(player.mo, Ord(S_PLAY_RUN1))
    else if player.mo.state = @states[Ord(S_CPLAY)] then
      P_SetMobjState(player.mo, Ord(S_CPLAY_RUN1))
    else if player.mo.state = @states[Ord(S_FPLAY)] then
      P_SetMobjState(player.mo, Ord(S_FPLAY_RUN1));
  end;

// JVAL Look UP and DOWN
  if zaxisshift then
  begin
    look16 := cmd.lookupdown16;
    if look16 > 7 * 256 then
      look16 := look16 - 16 * 256;

    if player.angletargetticks > 0 then
      player.centering := true
    else if look16 <> 0 then
    begin
      if look16 = TOCENTER * 256 then
        player.centering := true
      else
      begin
        player.lookdir16 := player.lookdir16 + Round(5 * look16 / 16);
        player.lookdir := player.lookdir16 div 16;

        if player.lookdir16 > MAXLOOKDIR * 16 then
          player.lookdir16 := MAXLOOKDIR * 16
        else if player.lookdir16 < MINLOOKDIR * 16 then
          player.lookdir16 := MINLOOKDIR * 16;

        if player.lookdir > MAXLOOKDIR then
          player.lookdir := MAXLOOKDIR
        else if player.lookdir < MINLOOKDIR then
          player.lookdir := MINLOOKDIR;
      end;
    end;

    if player.centering then
    begin
      // JVAL Smooth Look Up/Down
      if player.lookdir16 > 0 then
        player.lookdir16 := player.lookdir16 - 8 * 16
      else if player.lookdir16 < 0 then
        player.lookdir16 := player.lookdir16 + 8 * 16;

      if abs(player.lookdir16) < 8 * 16 then
      begin
        player.lookdir16 := 0;
        player.centering := false;
      end;

      player.lookdir := player.lookdir16 div 16;
    end;
  end;

  if onair or onwater then
  begin
    // JVAL: 20211116 - z momentum by forward/backward move when flying or swimming (algorithm from RAD)
    player.mo.momz :=  player.mo.momz - player.thrustmomz;
    player.thrustmomz := 0;

    player.mo.momz := player.mo.momz * 15 div 16;

    if player.lookdir16 <> 0 then
    begin
      an := (R_PointToAngle2(0, 0, player.mo.momx, player.mo.momy) - player.mo.angle) shr FRACBITS;
      xyspeed := FixedMul(FixedSqrt(FixedMul(player.mo.momx, player.mo.momx) + FixedMul(player.mo.momy, player.mo.momy)), fixedcosine[an]);
      if xyspeed <> 0 then
      begin
        player.thrustmomz := ((xyspeed div 16) * player.lookdir16) div 256; //ORIG_FRICTION_FACTOR;
        player.mo.momz :=  player.mo.momz + player.thrustmomz;
      end;
    end;
  end
  else
    player.thrustmomz := 0;

  if not G_NeedsCompatibilityMode then
  begin
  // JVAL Look LEFT and RIGHT
    look2 := cmd.lookleftright;
    if look2 > 7 then
      look2 := look2 - 16;

    if player.angletargetticks > 0 then
      player.forwarding := true
    else if look2 <> 0 then
    begin
      if look2 = TOFORWARD then
        player.forwarding := true
      else
      begin
        player.lookdir2 := (player.lookdir2 + 2 * look2) and 255;
        if player.lookdir2 in [64..127] then
          player.lookdir2 := 63
        else if player.lookdir2 in [128..191] then
          player.lookdir2 := 192;
      end;
    end
    else
      if player.oldlook2 <> 0 then
        player.forwarding := true;

    if player.forwarding then
    begin
      if player.lookdir2 in [3..63] then
        player.lookdir2 := player.lookdir2 - 6
      else if player.lookdir2 in [192..251] then
        player.lookdir2 := player.lookdir2 + 6;

      if (player.lookdir2 < 8) or (player.lookdir2 > 247) then
      begin
        player.lookdir2 := 0;
        player.forwarding := false;
      end;
    end;
    player.mo.viewangle := player.lookdir2 shl 24;

    player.oldlook2 := look2;

    if (onground or (player.cheats and CF_LOWGRAVITY <> 0)) and (cmd.jump > 1) then
    begin
      // JVAL: 20211101 - Crouch
      if cmd.crouch > 0 then
        player.mo.momz := 4 * FRACUNIT
      else if Psubsector_t(player.mo.subsector).sector.special = 14 then  // JVAL: Underwater portal sector
        player.mo.momz := 12 * FRACUNIT
      else
        player.mo.momz := 8 * FRACUNIT;
    end;

    // JVAL: 20211101 - Crouch
    if (leveltime - player.lastongroundtime < TICRATE) and (cmd.crouch <> 0) then
    begin
      player.crouchheight := player.crouchheight + cmd.crouch * FRACUNIT;
      if player.crouchheight > PMAXCROUCHHEIGHT then
        player.crouchheight := PMAXCROUCHHEIGHT;
    end
    else if (leveltime - player.lastautocrouchtime > TICRATE) and (player.crouchheight <> 0) then
    begin
      player.crouchheight := player.crouchheight - 2 * FRACUNIT;
      if player.crouchheight < 0 then
        player.crouchheight := 0;
    end;
    if not onground and (cmd.crouch <> 0) then
      if player.mo.momz > -4 * FRACUNIT then
      begin
        player.mo.momz := player.mo.momz - FRACUNIT div 2;
        if player.mo.momz < -4 * FRACUNIT then
          player.mo.momz := -4 * FRACUNIT;
      end;
  end
  else
    player.lookdir2 := 0;

  // JVAL: 20211109 - Fly (Jet pack)
  fly := cmd.fly;
  if fly > 7 then
    fly := fly - 16;

  if (fly <> 0) and (player.powers[Ord(pw_jetpack)] <> 0) then
  begin
    if fly <> TOCENTER then
    begin
      player.flyheight := fly * 2;
      if player.mo.flags4_ex and MF4_EX_FLY = 0 then
      begin
        player.mo.flags4_ex := player.mo.flags4_ex or MF4_EX_FLY;
        player.mo.flags := player.mo.flags or MF_NOGRAVITY;
      end;
    end
    else
    begin
      player.mo.flags4_ex := player.mo.flags4_ex and not MF4_EX_FLY;
      player.mo.flags := player.mo.flags and not MF_NOGRAVITY;
    end;
  end;

  if player.mo.flags4_ex and MF4_EX_FLY <> 0 then
  begin
    player.mo.momz := player.flyheight * FRACUNIT;
    if player.flyheight <> 0 then
      player.flyheight := player.flyheight div 2;
  end;

end;

//
// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
//
const
  ANG5 = ANG90 div 18;
  ANG355 = ANG270 +  ANG5 * 17; // add by JVAL

procedure P_DeathThink(player: Pplayer_t);
var
  angle: angle_t;
  delta: angle_t;
  attackeratwater: boolean;
  playeratwater: boolean;
begin
  P_MovePsprites(player);

  // fall to the ground
  if player.viewheight > 6 * FRACUNIT then
    player.viewheight := player.viewheight - FRACUNIT;

  if player.viewheight < 6 * FRACUNIT then
    player.viewheight := 6 * FRACUNIT;

  if player.viewheight > 6 * FRACUNIT then
    if player.lookdir < 45 then
    begin
      player.lookdir := player.lookdir + 5;
      player.lookdir16 := player.lookdir * 16; // JVAL Smooth Look Up/Down
    end;

  player.deltaviewheight := 0;
  onground := player.mo.z <= player.mo.floorz;
  P_CalcHeight(player);

  // Sink slowly in water when dead
  player.mo.flags4_ex := player.mo.flags4_ex or MF4_EX_FORCELOWUNDERWATERGRAVITY;

  // JVAL: Check water portal (MARS)
  P_CheckPlayerWaterSector(player);

  if player.attacker <> nil then
    attackeratwater := Psubsector_t(player.attacker.subsector).sector.renderflags and SRF_UNDERWATER <> 0
  else
    attackeratwater := false;

  playeratwater := Psubsector_t(player.mo.subsector).sector.renderflags and SRF_UNDERWATER <> 0;

  if (player.attacker <> nil) and (player.attacker <> player.mo) and (playeratwater = attackeratwater) then
  begin

    angle := R_PointToAngle2(
      player.mo.x, player.mo.y, player.attackerx, player.attackery);

    delta := angle - player.mo.angle;

    if (delta < ANG5) or (delta > ANG355) then
    begin
      // Looking at killer,
      //  so fade damage flash down.
      player.mo.angle := angle;

      if player.damagecount <> 0 then
        player.damagecount := player.damagecount - 1;
    end
    else if delta < ANG180 then
      player.mo.angle := player.mo.angle + ANG5
    else
      player.mo.angle := player.mo.angle - ANG5;

  end
  else if player.damagecount <> 0 then
    player.damagecount := player.damagecount - 1;

  if player.cmd.buttons and BT_USE <> 0 then
    player.playerstate := PST_REBORN;
end;

var
  brsnd: integer = -1;
  brsnd2: integer = -1;
  rnd_breath: Integer = 0;

procedure A_PlayerBreath(p: Pplayer_t);
var
  sndidx: integer;
begin
  if p.health <= 0 then
    exit;

  if p.playerstate = PST_DEAD then
    exit;

  if leveltime - p.lastbreath < 3 * TICRATE + (C_Random(rnd_breath) mod TICRATE) then
    exit;

  p.lastbreath := leveltime;

  if allowplayerbreath then
    if p.mo.flags4_ex and MF4_EX_SWIM = 0 then
    begin
      if p.hardbreathtics > 0 then
      begin
        if brsnd2 < 0 then
          brsnd2 := S_GetSoundNumForName('player/breath2');
        sndidx := brsnd2;
      end
      else
      begin
        if brsnd < 0 then
          brsnd := S_GetSoundNumForName('player/breath');
        sndidx := brsnd;
      end;
      if sndidx > 0 then
        S_StartSound(@p.mo.soundorg1, sndidx);
    end;
end;

procedure P_AngleTarget(player: Pplayer_t);
var
  ticks: LongWord;
  angle: angle_t;
  diff: angle_t;
begin
  if player.angletargetticks <= 0 then
    exit;

  player.cmd.angleturn := 0;
  angle := R_PointToAngle2(player.mo.x, player.mo.y, player.angletargetx, player.angletargety);
  diff := player.mo.angle - angle;

  ticks := player.angletargetticks;
  if diff > ANG180 then
  begin
    diff := ANGLE_MAX - diff;
    player.mo.angle := player.mo.angle + (diff div ticks);
  end
  else
    player.mo.angle := player.mo.angle - (diff div ticks);

  dec(player.angletargetticks);
end;

procedure P_PlayerFaceMobj(const player: Pplayer_t; const face: Pmobj_t; const ticks: integer);
begin
  player.angletargetx := face.x;
  player.angletargety := face.y;
  player.angletargetticks := ticks;
end;

//
// P_PlayerThink
//
procedure P_PlayerThink(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  newweapon: weapontype_t;
  sec: Psector_t; // JVAL: 3d Floors
begin
  MARS_PlayerThink(player);

  // fixme: do this in the cheat code
  if player.mo = nil then
    exit;

  if player.cheats and CF_NOCLIP <> 0 then
    player.mo.flags := player.mo.flags or MF_NOCLIP
  else
    player.mo.flags := player.mo.flags and not MF_NOCLIP;

  // chain saw run forward
  cmd := @player.cmd;
  if player.mo.flags and MF_JUSTATTACKED <> 0 then
  begin
    cmd.angleturn := 0;
    cmd.forwardmove := $c800 div 512;
    cmd.sidemove := 0;
    player.mo.flags := player.mo.flags and not MF_JUSTATTACKED;
  end;

  if player.quaketics > 0 then
  begin
    Dec(player.quaketics, FRACUNIT);
    if player.quaketics < 0 then
      player.quaketics := 0;
  end;

  if player.teleporttics > 0 then
  begin
    Dec(player.teleporttics, FRACUNIT);
    if player.teleporttics < 0 then
      player.teleporttics := 0;
  end;

  if player.playerstate = PST_DEAD then
  begin
    P_DeathThink(player);
    exit;
  end;

  P_AngleTarget(player);

  // Move around.
  // Reactiontime is used to prevent movement
  //  for a bit after a teleport.
  if player.mo.reactiontime <> 0 then
    player.mo.reactiontime := player.mo.reactiontime - 1
  else
    P_MovePlayer(player);

  P_CalcHeight(player);

  // JVAL: 3d Floors
  sec := Psubsector_t(player.mo.subsector).sector;
  if sec.special <> 0 then
    P_PlayerInSpecialSector(player, sec, P_FloorHeight(sec, player.mo.x, player.mo.y));    // JVAL: 3d Floors
  if sec.midsec >= 0 then
    if sectors[sec.midsec].special <> 0 then
      P_PlayerInSpecialSector(player, @sectors[sec.midsec], sectors[sec.midsec].ceilingheight);  // JVAL: 3d Floors

  // JVAL: Check water portal (MARS)
  P_CheckPlayerWaterSector(player);

  // Check for weapon change.

  // A special event has no other buttons.
  if cmd.buttons and BT_SPECIAL <> 0 then
    cmd.buttons := 0;

  if cmd.buttons and BT_CHANGE <> 0 then
  begin
    // The actual changing of the weapon is done
    //  when the weapon psprite can do it
    //  (read: not in the middle of an attack).
    newweapon := weapontype_t(_SHR(cmd.buttons and BT_WEAPONMASK, BT_WEAPONSHIFT));

    if player.weaponowned[Ord(newweapon)] <> 0 then
      player.pendingweapon := newweapon;
  end;

  // check for use
  if cmd.buttons and BT_USE <> 0 then
  begin
    if not player.usedown then
    begin
      P_UseLines(player);
      player.usedown := true;
    end;
  end
  else
    player.usedown := false;

  // cycle psprites
  P_MovePsprites(player);

  // Counters, time dependend power ups.

  // Strength counts up to diminish fade.
  if player.powers[Ord(pw_strength)] <> 0 then
    player.powers[Ord(pw_strength)] := player.powers[Ord(pw_strength)] + 1;

  if player.powers[Ord(pw_invulnerability)] <> 0 then
    player.powers[Ord(pw_invulnerability)] := player.powers[Ord(pw_invulnerability)] - 1;

  if player.powers[Ord(pw_invisibility)] <> 0 then
  begin
    player.powers[Ord(pw_invisibility)] := player.powers[Ord(pw_invisibility)] - 1;
    if player.powers[Ord(pw_invisibility)] = 0 then
      player.mo.flags := player.mo.flags and not MF_SHADOW;
  end;

  if player.powers[Ord(pw_infrared)] <> 0 then
    player.powers[Ord(pw_infrared)] := player.powers[Ord(pw_infrared)] - 1;

  if player.powers[Ord(pw_ironfeet)] <> 0 then
    player.powers[Ord(pw_ironfeet)] := player.powers[Ord(pw_ironfeet)] - 1;

  if player.damagecount <> 0 then
    player.damagecount := player.damagecount - 1;

  if player.hardbreathtics > 0 then
    player.hardbreathtics := player.hardbreathtics - 1;

  if player.bonuscount <> 0 then
    player.bonuscount := player.bonuscount - 1;


  // Handling colormaps.
  if player.powers[Ord(pw_invulnerability)] <> 0 then
  begin
    if (player.powers[Ord(pw_invulnerability)] > 4 * 32) or
       (player.powers[Ord(pw_invulnerability)] and 8 <> 0) then
      player.fixedcolormap := INVERSECOLORMAP
    else
      player.fixedcolormap := 0;
  end
  else if player.powers[Ord(pw_infrared)] <> 0 then
  begin
    if (player.powers[Ord(pw_infrared)] > 4 * 32) or
       (player.powers[Ord(pw_infrared)] and 8 <> 0) then
      // almost full bright
      player.fixedcolormap := 1
    else
      player.fixedcolormap := 0;
  end
  else
    player.fixedcolormap := 0;

  A_PlayerBreath(player);
end;

end.

