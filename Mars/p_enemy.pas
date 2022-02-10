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
//  Enemy thinking, AI.
//  Action Pointer Functions
//  that are associated with states/frames.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_enemy;

interface

uses
  doomdef,
  p_local,
  p_mobj_h,
  s_sound,
  d_player,
// Data.
  sounds;

//==============================================================================
//
// A_Fall
//
//==============================================================================
procedure A_Fall(actor: Pmobj_t);

//==============================================================================
//
// A_Look
//
//==============================================================================
procedure A_Look(actor: Pmobj_t);

//==============================================================================
//
// A_Chase
//
//==============================================================================
procedure A_Chase(actor: Pmobj_t);

//==============================================================================
//
// A_FaceTarget
//
//==============================================================================
procedure A_FaceTarget(actor: Pmobj_t);

//==============================================================================
//
// A_PosAttack
//
//==============================================================================
procedure A_PosAttack(actor: Pmobj_t);

//==============================================================================
//
// A_SPosAttack
//
//==============================================================================
procedure A_SPosAttack(actor: Pmobj_t);

//==============================================================================
//
// A_CPosAttack
//
//==============================================================================
procedure A_CPosAttack(actor: Pmobj_t);

//==============================================================================
//
// A_CPosRefire
//
//==============================================================================
procedure A_CPosRefire(actor: Pmobj_t);

//==============================================================================
//
// A_TroopAttack
//
//==============================================================================
procedure A_TroopAttack(actor: Pmobj_t);

//==============================================================================
//
// A_SargAttack
//
//==============================================================================
procedure A_SargAttack(actor: Pmobj_t);

//==============================================================================
//
// A_Tracer
//
//==============================================================================
procedure A_Tracer(actor: Pmobj_t);

//==============================================================================
//
// A_SkullAttack
//
//==============================================================================
procedure A_SkullAttack(actor: Pmobj_t);

//==============================================================================
//
// A_Scream
//
//==============================================================================
procedure A_Scream(actor: Pmobj_t);

//==============================================================================
//
// A_XScream
//
//==============================================================================
procedure A_XScream(actor: Pmobj_t);

//==============================================================================
//
// A_Pain
//
//==============================================================================
procedure A_Pain(actor: Pmobj_t);

//==============================================================================
//
// A_Explode
//
//==============================================================================
procedure A_Explode(thingy: Pmobj_t);

//==============================================================================
//
// A_BossDeath
//
//==============================================================================
procedure A_BossDeath(mo: Pmobj_t);

//==============================================================================
//
// A_Hoof
//
//==============================================================================
procedure A_Hoof(mo: Pmobj_t);

//==============================================================================
//
// A_PlayerScream
//
//==============================================================================
procedure A_PlayerScream(mo: Pmobj_t);

//==============================================================================
//
// P_DoChase
//
//==============================================================================
procedure P_DoChase(actor: Pmobj_t; const fast: boolean);

//==============================================================================
//
// P_NoiseAlert
//
//==============================================================================
procedure P_NoiseAlert(target: Pmobj_t; emmiter: Pmobj_t);

//==============================================================================
//
// P_CheckMeleeRange
//
//==============================================================================
function P_CheckMeleeRange(actor: Pmobj_t): boolean;

//==============================================================================
//
// P_TryWalk
//
//==============================================================================
function P_TryWalk(actor: Pmobj_t): boolean;

//==============================================================================
//
// P_Move
//
//==============================================================================
function P_Move(actor: Pmobj_t): boolean;

//==============================================================================
//
// P_Massacre
//
//==============================================================================
procedure P_Massacre;

//==============================================================================
//
// A_TurretChase
//
//==============================================================================
procedure A_TurretChase(actor: Pmobj_t);

type
  dirtype_t = (
    DI_EAST,
    DI_NORTHEAST,
    DI_NORTH,
    DI_NORTHWEST,
    DI_WEST,
    DI_SOUTHWEST,
    DI_SOUTH,
    DI_SOUTHEAST,
    DI_NODIR,
    NUMDIRS
  );

//==============================================================================
//
// P_BothFriends
//
//==============================================================================
function P_BothFriends(mo1, mo2: Pmobj_t): boolean;

implementation

uses
  d_delphi,
  doomdata,
  d_think,
  d_main,
  g_game,
  m_fixed,
  tables,
  i_system,
  info_h,
  info,
  info_common,
  m_rnd,
  mars_version,
  p_map,
  p_maputl,
  p_setup,
  p_sight,
  p_switch,
  p_tick,
  p_mobj,
  p_inter,
  p_common,
  p_sounds,
  ps_main,
  r_defs,
  r_main;

const
  opposite: array[0..8] of dirtype_t = (
    DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST,
    DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR
  );

  diags: array[0..3] of dirtype_t = (
    DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST
  );

//==============================================================================
//
// A_Fall
//
//==============================================================================
procedure A_Fall(actor: Pmobj_t);
begin
  // actor is on ground, it can be walked over
  actor.flags := actor.flags and not MF_SOLID;

  // So change this if corpse objects
  // are meant to be obstacles.
end;

//
// ENEMY THINKING
// Enemies are allways spawned
// with targetplayer = -1, threshold = 0
// Most monsters are spawned unaware of all players,
// but some can be made preaware
//

//
// Called by P_NoiseAlert.
// Recursively traverse adjacent sectors,
// sound blocking lines cut off traversal.
//

var
  soundtarget: Pmobj_t;

//==============================================================================
//
// P_RecursiveSound
//
//==============================================================================
procedure P_RecursiveSound(sec: Psector_t; soundblocks: integer);
var
  i: integer;
  check: Pline_t;
  other: Psector_t;
begin
  // wake up all monsters in this sector
  if (sec.validcount = validcount) and
     (sec.soundtraversed <= soundblocks + 1) then
    exit; // already flooded

  sec.validcount := validcount;
  sec.soundtraversed := soundblocks + 1;
  sec.soundtarget := soundtarget;

  for i := 0 to sec.linecount - 1 do
  begin
    check := sec.lines[i];
    if check.flags and ML_TWOSIDED = 0 then
      continue;
    // JVAL: 20200407 - Avoid false ML_TWOSIDED flag
    if (check.sidenum[1] < 0) or (check.sidenum[0] < 0) then
      continue;

    P_LineOpening(check, false);

    if openrange <= 0 then
      continue; // closed door

    if sides[check.sidenum[0]].sector = sec then
      other := sides[check.sidenum[1]].sector
    else
      other := sides[check.sidenum[0]].sector;

    if check.flags and ML_SOUNDBLOCK <> 0 then
    begin
      if soundblocks = 0 then
        P_RecursiveSound(other, 1);
    end
    else
      P_RecursiveSound(other, soundblocks);
  end;
end;

//==============================================================================
//
// P_NoiseAlert
// If a monster yells at a player,
// it will alert other monsters to the player.
//
//==============================================================================
procedure P_NoiseAlert(target: Pmobj_t; emmiter: Pmobj_t);
begin
  soundtarget := target;
  inc(validcount);
  P_RecursiveSound(Psubsector_t(emmiter.subsector).sector, 0);
end;

//==============================================================================
//
// P_BothFriends
//
// JVAL: New function
//
//==============================================================================
function P_BothFriends(mo1, mo2: Pmobj_t): boolean;
var
  f1, f2: boolean;
begin
  if (mo1 = nil) or (mo2 = nil) then
  begin
    result := false;
    exit;
  end;

  f1 := (mo1.player <> nil) or (mo1.flags2_ex and MF2_EX_FRIEND <> 0);
  if not f1 then
  begin
    result := false;
    exit;
  end;

  f2 := (mo2.player <> nil) or (mo2.flags2_ex and MF2_EX_FRIEND <> 0);
  if not f2 then
  begin
    result := false;
    exit;
  end;

  if deathmatch <> 0 then
    if mo1.player <> nil then
      if mo2.player <> nil then
      begin
        result := false;
        exit;
      end;

  result := true;
end;

//==============================================================================
//
// P_CheckMeleeRange
//
//==============================================================================
function P_CheckMeleeRange(actor: Pmobj_t): boolean;
var
  pl: Pmobj_t;
  dist: fixed_t;
  mrange: integer;
begin
  pl := actor.target;
  if pl = nil then
  begin
    result := false;
    exit;
  end;

  // Friendly monsters do not attack each other
  if P_BothFriends(pl, actor) then
  begin
    result := false;
    exit;
  end;

  dist := P_AproxDistance(pl.x - actor.x, pl.y - actor.y);

  mrange := actor.info.meleerange;
  if mrange = 0 then
    mrange := MELEERANGE
  else if mrange < FRACUNIT then
    mrange := mrange * FRACUNIT;

  if dist >= mrange - 20 * FRACUNIT + pl.info.radius then
  begin
    result := false;
    exit;
  end;

  // JVAL: 20210207 - Added MF3_EX_MELEECHECKZ
  if actor.flags3_ex and MF3_EX_MELEECHECKZ <> 0 then
  begin
    if pl.z > actor.z + actor.height then
    begin // Target is higher than the attacker
      result := false;
      exit;
    end;

    if actor.z > pl.z + pl.height then
    begin // Attacker is higher
      result := false;
      exit;
    end;
  end;

  result := P_CheckSight(actor, actor.target);
end;

//==============================================================================
//
// P_CheckMissileRange
//
//==============================================================================
function P_CheckMissileRange(actor: Pmobj_t): boolean;
var
  dist: fixed_t;
begin
  if not P_CheckSight(actor, actor.target) then
  begin
    result := false;
    exit;
  end;

  if actor.flags and MF_JUSTHIT <> 0 then
  begin
    // the target just hit the enemy,
    // so fight back!
    actor.flags := actor.flags and not MF_JUSTHIT;
    result := true;
    exit;
  end;

  if actor.reactiontime <> 0 then
  begin
    result := false; // do not attack yet
    exit;
  end;

  // Friendly monsters do not attack each other
  if P_BothFriends(actor, actor.target) then
  begin
    result := false;
    exit;
  end;

  // OPTIMIZE: get this from a global checksight
  dist := P_AproxDistance(actor.x - actor.target.x, actor.y - actor.target.y) -
            64 * FRACUNIT;

  if actor.info.meleestate = 0 then
    dist := dist - 128 * FRACUNIT;  // no melee attack, so fire more

  dist := FixedInt(dist);

  if dist > 200 then
    dist := 200;

  if actor.flags3_ex and MF3_EX_MISSILEMORE <> 0 then
    dist := dist div 2;
  if actor.flags3_ex and MF3_EX_MISSILEEVENMORE <> 0 then
    dist := dist div 8;

  if actor.info.minmissilechance > 0 then
    if actor.info.minmissilechance < dist then
      dist := actor.info.minmissilechance;

  if P_Random < dist then
    result := false
  else
    result := true;
end;

//
// P_Move
// Move in the current direction,
// returns false if the move is blocked.
//
const
  xspeed: array[0..7] of fixed_t =
    (FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000, 0, 47000);

  yspeed: array[0..7] of fixed_t =
    (0, 47000, FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000);

//==============================================================================
//
// P_Move
//
//==============================================================================
function P_Move(actor: Pmobj_t): boolean;
var
  tryx: fixed_t;
  tryy: fixed_t;
  ld: Pline_t;
  try_ok: boolean;
begin
  if actor.movedir = Ord(DI_NODIR) then
  begin
    result := false;
    exit;
  end;

  if Ord(actor.movedir) >= 8 then
    I_Error('P_Move(): Weird actor->movedir = %d', [Ord(actor.movedir)]);

  tryx := actor.x + actor.info.speed * xspeed[actor.movedir];
  tryy := actor.y + actor.info.speed * yspeed[actor.movedir];

  try_ok := P_TryMove(actor, tryx, tryy);

  if not try_ok then
  begin
    // open any specials
    if (actor.flags and MF_FLOAT <> 0) and floatok then
    begin
      // must adjust height
      if actor.z < tmfloorz then
        actor.z := actor.z + P_FloatSpeed(actor)
      else
        actor.z := actor.z - P_FloatSpeed(actor);

      actor.flags := actor.flags or MF_INFLOAT;
      result := true;
      exit;
    end;

    if numspechit = 0 then
    begin
      result := false;
      exit;
    end;

    actor.movedir := Ord(DI_NODIR);
    result := false;
    while numspechit > 0 do
    begin
      dec(numspechit);
      ld := spechit[numspechit];

      if ld.flags and ML_TRIGGERSCRIPTS <> 0 then
        if actor.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
          PS_EventUseLine(actor, pDiff(ld, lines, SizeOf(line_t)), P_PointOnLineSide(actor.x, actor.y, ld));

      // if the special is not a door
      // that can be opened,
      // return false
      if P_UseSpecialLine(actor, ld, 0) then
        result := true;
    end;
    exit;
  end
  else
    actor.flags := actor.flags and not MF_INFLOAT;

  if actor.flags and MF_FLOAT = 0 then
  begin
    if actor.z > actor.floorz then
      P_HitFloor(actor);
    actor.z := actor.floorz;
  end;

  result := true;
end;

//==============================================================================
// P_TryWalk
//
// TryWalk
// Attempts to move actor on
// in its current (ob->moveangle) direction.
// If blocked by either a wall or an actor
// returns FALSE
// If move is either clear or blocked only by a door,
// returns TRUE and sets...
// If a door is in the way,
// an OpenDoor call is made to start it opening.
//
//==============================================================================
function P_TryWalk(actor: Pmobj_t): boolean;
begin
  if not P_Move(actor) then
    result := false
  else
  begin
    actor.movecount := P_Random and 15;
    result := true;
  end;
end;

//==============================================================================
//
// P_NewChaseDir
//
//==============================================================================
procedure P_NewChaseDir(actor: Pmobj_t);
var
  deltax: fixed_t;
  deltay: fixed_t;
  d: array[0..2] of dirtype_t;
  tdir: dirtype_t;
  olddir: dirtype_t;
  turnaround: dirtype_t;
  idx: integer;
begin
  if actor.target = nil then
    I_Error('P_NewChaseDir(): called with no target');

  olddir := dirtype_t(actor.movedir);
  turnaround := opposite[Ord(olddir)];

  deltax := actor.target.x - actor.x;
  deltay := actor.target.y - actor.y;

  // JVAL: 20210209 - MF3_EX_CAUSEFEAR & MF3_EX_NOFEAR flags
  if actor.target.flags3_ex and MF3_EX_CAUSEFEAR <> 0 then
    if actor.flags3_ex and MF3_EX_NOFEAR <> 0 then
      actor.flags2_ex := actor.flags2_ex or MF2_EX_FRIGHTENED;

  if actor.flags2_ex and MF2_EX_FRIGHTENED <> 0 then
  begin
    deltax := -deltax;
    deltay := -deltay;
  end;

  if deltax > 10 * FRACUNIT then
    d[1] := DI_EAST
  else if deltax < -10 * FRACUNIT then
    d[1] := DI_WEST
  else
    d[1] := DI_NODIR;

  if deltay < -10 * FRACUNIT then
    d[2] := DI_SOUTH
  else if deltay > 10 * FRACUNIT then
    d[2] := DI_NORTH
  else
    d[2] := DI_NODIR;

  // try direct route
  if (d[1] <> DI_NODIR) and (d[2] <> DI_NODIR) then
  begin
    if deltay < 0 then
      idx := 2
    else
      idx := 0;
    if deltax > 0 then
      inc(idx);
    actor.movedir := Ord(diags[idx]);
    if (actor.movedir <> Ord(turnaround)) and P_TryWalk(actor) then
      exit;
  end;

  // try other directions
  if (P_Random > 200) or (abs(deltay) > abs(deltax)) then
  begin
    tdir := d[1];
    d[1] := d[2];
    d[2] := tdir;
  end;

  if d[1] = turnaround then
    d[1] := DI_NODIR;
  if d[2] = turnaround then
    d[2] := DI_NODIR;

  if d[1] <> DI_NODIR then
  begin
    actor.movedir := Ord(d[1]);
    if P_TryWalk(actor) then
      exit; // either moved forward or attacked
  end;

  if d[2] <> DI_NODIR then
  begin
    actor.movedir := Ord(d[2]);
    if P_TryWalk(actor) then
      exit;
  end;

  // there is no direct path to the player,
  // so pick another direction.
  if olddir <> DI_NODIR then
  begin
    actor.movedir := Ord(olddir);
    if P_TryWalk(actor) then
      exit;
  end;

  // randomly determine direction of search
  if P_Random and 1 <> 0 then
  begin
    for tdir := DI_EAST to DI_SOUTHEAST do
    begin
      if tdir <> turnaround then
      begin
        actor.movedir := Ord(tdir);
        if P_TryWalk(actor) then
          exit;
      end;
    end;
  end
  else
  begin
    for tdir := DI_SOUTHEAST downto DI_EAST do
    begin
      if tdir <> turnaround then
      begin
        actor.movedir := Ord(tdir);
        if P_TryWalk(actor) then
          exit;
      end;
    end;
  end;

  if turnaround <> DI_NODIR then
  begin
    actor.movedir := Ord(turnaround);
    if P_TryWalk(actor) then
      exit;
  end;

  actor.movedir := Ord(DI_NODIR); // can not move
end;

//---------------------------------------------------------------------------
//
// FUNC P_LookForMonsters
//
//---------------------------------------------------------------------------
const
  MONS_LOOK_RANGE = 20 * 64 * FRACUNIT;
  MONS_LOOK_LIMIT = 256;

//==============================================================================
//
// P_LookForMonsters
//
//==============================================================================
function P_LookForMonsters(actor: Pmobj_t): boolean;
var
  count: integer;
  mo: Pmobj_t;
  think: Pthinker_t;
  inher: integer;
  maxrange: fixed_t;
begin
  if actor.flags2_ex and MF2_EX_FRIEND = 0 then
    if not P_CheckSight(players[0].mo, actor) then
    begin // Player can't see monster
      result := false;
      exit;
    end;

  count := 0;
  think := thinkercap.next;
  while think <> @thinkercap do
  begin
    if @think._function.acp1 <> @P_MobjThinker then
    begin
      think := think.next;
      continue;
    end;

    mo := Pmobj_t(think);

    if (mo.flags and MF_COUNTKILL = 0) or (mo = actor) or (mo.health <= 0) then
    begin // Not a valid monster
      think := think.next;
      continue;
    end;

    if P_BothFriends(mo, actor) then
    begin // Friendly monsters do not hurt each other
      think := think.next;
      continue;
    end;

    inher := Info_GetInheritance(mo.info);
    if inher = Info_GetInheritance(actor.info) then
    begin
      think := think.next;
      continue;
    end;

    if actor.info.maxtargetrange > 0 then
      maxrange := actor.info.maxtargetrange * FRACUNIT
    else
      maxrange := MONS_LOOK_RANGE;

    if P_AproxDistance(actor.x - mo.x, actor.y - mo.y) > maxrange then
    begin // Out of range
      think := think.next;
      continue;
    end;

    if P_Random < 16 then
    begin // Skip
      think := think.next;
      continue;
    end;

    inc(count);
    if count > MONS_LOOK_LIMIT then
    begin // Stop searching
      result := false;
      exit;
    end;

    if not P_CheckSight(actor, mo) then
    begin // Out of sight
      think := think.next;
      continue;
    end;

    // Found a target monster
    actor.target := mo;
    result := true;
    exit;
  end;

  result := false;
end;

//==============================================================================
//
// P_LookForPlayers
// If allaround is false, only look 180 degrees in front.
// Returns true if a player is targeted.
//
//==============================================================================
function P_LookForPlayers(actor: Pmobj_t; allaround: boolean): boolean;
var
  c: integer;
  stop: integer;
  player: Pplayer_t;
  an: angle_t;
  dist: fixed_t;
  initial: boolean;
begin
  c := 0;
  stop := (actor.lastlook - 1) and 3;

  initial := true;
  while true do
  begin
    if initial then
      initial := false
    else
      actor.lastlook := (actor.lastlook + 1) and 3;

    if not playeringame[actor.lastlook] then
      continue;

    if (c = 2) or (actor.lastlook = stop) then
    begin
      // done looking
      result := false;
      exit;
    end;
    inc(c);

    player := @players[actor.lastlook];

    if player.health <= 0 then
      continue;   // dead

    if actor.info.maxtargetrange > 0 then
      if P_AproxDistance(actor.x - player.mo.x, actor.y - player.mo.y) > actor.info.maxtargetrange * FRACUNIT then
        continue; // JVAL: 20210211 - Out of range

    if not P_CheckSight(actor, player.mo) then
      continue;   // out of sight

    if not allaround then
    begin
      an := R_PointToAngle2(actor.x, actor.y, player.mo.x, player.mo.y) - actor.angle;

      if (an > ANG90) and (an < ANG270) then
      begin
        dist := P_AproxDistance(player.mo.x - actor.x, player.mo.y - actor.y);
        // if real close, react anyway
        if dist > MELEERANGE then
          continue; // behind back
      end;
    end;

    actor.target := player.mo;
    result := true;
    exit;
  end;

  result := false;
end;

//==============================================================================
//
// P_LookForTargets
//
//==============================================================================
function P_LookForTargets(actor: Pmobj_t; allaround: boolean): boolean;
begin
  if actor.flags2_ex and MF2_EX_FRIEND <> 0 then
    result := P_LookForMonsters(actor)
  else
    result := P_LookForPlayers(actor, allaround);
end;

//==============================================================================
//
// ACTION ROUTINES
//
// A_Look
// Stay in state until a player is sighted.
//
//==============================================================================
procedure A_Look(actor: Pmobj_t);
var
  targ: Pmobj_t;
  seeyou: boolean;
  sound: integer;
begin
  actor.threshold := 0; // any shot will wake up
  targ := Psubsector_t(actor.subsector).sector.soundtarget;
  seeyou := false;
  if (targ <> nil) and (targ.flags and MF_SHOOTABLE <> 0) then
  begin
    actor.target := targ;

    if actor.flags and MF_AMBUSH <> 0 then
    begin
      if P_CheckSight(actor, targ) then
        seeyou := true;
    end
    else
      seeyou := true;
  end;

  if not seeyou then
  begin
    if not P_LookForTargets(actor, actor.flags_ex and MF_EX_LOOKALLAROUND <> 0) then
      exit;
  end;

  // go into chase state
  if actor.info.seesound <> 0 then
  begin
    sound := actor.info.seesound;

    if actor.flags_ex and MF_EX_RANDOMSEESOUND <> 0 then
    begin
      if actor.flags_ex and MF_EX_BOSS <> 0 then
        // full volume
        P_RandomSound(nil, sound)
      else
        P_RandomSound(actor, sound)
    end
    else
    begin
      if actor.flags_ex and MF_EX_BOSS <> 0 then
        // full volume
        S_StartSound(nil, sound)
      else
        S_StartSound(actor, sound);
    end;
  end;

  if actor.state <> @states[actor.info.seestate] then
    P_SetMobjState(actor, actor.info.seestate);
end;

//==============================================================================
// P_DoChase
//
// A_Chase
// Actor has a melee attack,
// so it tries to close as fast as possible
//
//==============================================================================
procedure P_DoChase(actor: Pmobj_t; const fast: boolean);
var
  delta: integer;
  nomissile: boolean;
  dist: fixed_t;
  ang: angle_t;
begin
  if actor.reactiontime <> 0 then
    actor.reactiontime := actor.reactiontime - 1;

  // modify target threshold
  if actor.threshold <> 0 then
  begin
    if (actor.target = nil) or (actor.target.health <= 0) then
      actor.threshold := 0
    else
      actor.threshold := actor.threshold - 1;
  end;

  // turn towards movement direction if not there yet
  if actor.movedir < 8 then
  begin
    actor.angle := actor.angle and $E0000000;
    delta := actor.angle - _SHLW(actor.movedir, 29);

    if delta > 0 then
      actor.angle := actor.angle - ANG90 div 2
    else if delta < 0 then
      actor.angle := actor.angle + ANG90 div 2;
  end;

  if P_BothFriends(actor, actor.target) then
  begin
    if P_LookForTargets(actor, actor.flags_ex and MF_EX_LOOKALLAROUND <> 0) then
      exit; // got a new target
    if actor.state <> @states[actor.info.spawnstate] then
      P_SetMobjStateNF(actor, actor.info.spawnstate);
    exit;
  end;

  if (actor.target = nil) or
     (actor.target.flags and MF_SHOOTABLE = 0) then
  begin
    // look for a new target
    if P_LookForTargets(actor, true) then
      exit; // got a new target

    if actor.state <> @states[actor.info.spawnstate] then
      P_SetMobjStateNF(actor, actor.info.spawnstate);
    exit;
  end;

  // do not attack twice in a row
  if actor.flags and MF_JUSTATTACKED <> 0 then
  begin
    actor.flags := actor.flags and not MF_JUSTATTACKED;
    if (gameskill <> sk_nightmare) and not fastparm then
      P_NewChaseDir(actor);
    exit;
  end;

  // check for melee attack
  if (actor.info.meleestate <> 0) and P_CheckMeleeRange(actor) then
  begin
    A_AttackSound(actor, actor);
    if actor.state <> @states[actor.info.meleestate] then
      P_SetMobjState(actor, actor.info.meleestate);
    exit;
  end;

  nomissile := false;
  // check for missile attack
  if actor.info.missilestate <> 0 then
  begin
    if (gameskill < sk_nightmare) and not fastparm and (actor.movecount <> 0) then
      nomissile := true
    else if not P_CheckMissileRange(actor) then
      nomissile := true;
    if not nomissile then
    begin
      if actor.state <> @states[actor.info.missilestate] then
        P_SetMobjState(actor, actor.info.missilestate);
      actor.flags := actor.flags or MF_JUSTATTACKED;
      exit;
    end;
  end;

  // possibly choose another target
  if netgame and
    (actor.threshold = 0) and
    not P_CheckSight(actor, actor.target) then
  begin
    if P_LookForTargets(actor, true) then
      exit;  // got a new target
  end;

  // chase towards player
  actor.movecount := actor.movecount - 1;
  if (actor.movecount < 0) or not P_Move(actor) then
    P_NewChaseDir(actor);

  if fast then
  begin
    if actor.fastchasetics > 0 then
      dec(actor.fastchasetics)
    else
    begin
      actor.fastchasetics := 0;
      actor.momx := 0;
      actor.momy := 0;
      dist := P_AproxDistance(actor.x - actor.target.x, actor.y - actor.target.y);
      if dist < 64 * 10 * FRACUNIT then
        if P_Random < 100 then
        begin
          ang := R_PointToAngle2(actor.x, actor.y, actor.target.x, actor.target.y);
          if P_Random < 128 then
            ang := ang + ANG90
          else
            ang := ang - ANG90;
          ang := ang shr ANGLETOFINESHIFT;
          actor.momx := 2 * actor.info.speed * finecosine[ang];
          actor.momy := 2 * actor.info.speed * finesine[ang];
          actor.fastchasetics := 3;
        end;
    end;
  end;

  // make active sound
  if (actor.info.activesound <> 0) and (P_Random < 3) then
    A_ActiveSound(actor, actor);
end;

//==============================================================================
//
// A_Chase
//
//==============================================================================
procedure A_Chase(actor: Pmobj_t);
begin
  P_DoChase(actor, false);
end;

//==============================================================================
//
// A_FaceTarget
//
//==============================================================================
procedure A_FaceTarget(actor: Pmobj_t);
begin
  if actor.target = nil then
    exit;

  actor.flags := actor.flags and not MF_AMBUSH;

  actor.angle :=
    R_PointToAngle2(actor.x, actor.y, actor.target.x, actor.target.y);

  if actor.target.flags and MF_SHADOW <> 0 then
    if actor.flags2_ex and MF2_EX_SEEINVISIBLE = 0 then
      actor.angle := actor.angle + _SHLW(P_Random - P_Random, 21);
end;

//==============================================================================
//
// A_PosAttack
//
//==============================================================================
procedure A_PosAttack(actor: Pmobj_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
begin
  if actor.target = nil then
    exit;

  A_FaceTarget(actor);
  angle := actor.angle;
  slope := P_AimLineAttack(actor, angle, MISSILERANGE);

  S_StartSound(actor, Ord(sfx_pistol));
  angle := angle + _SHLW(P_Random - P_Random, 20);
  damage := ((P_Random mod 5) + 1) * 3;
  P_LineAttack(actor, angle, MISSILERANGE, slope, damage);
end;

//==============================================================================
//
// A_SPosAttack
//
//==============================================================================
procedure A_SPosAttack(actor: Pmobj_t);
var
  i: integer;
  angle: angle_t;
  bangle: angle_t;
  damage: integer;
  slope: integer;
begin
  if actor.target = nil then
    exit;

  S_StartSound(actor, actor.info.attacksound);
  A_FaceTarget(actor);
  bangle := actor.angle;
  slope := P_AimLineAttack(actor, bangle, MISSILERANGE);

  for i := 0 to 2 do
  begin
    angle := bangle + _SHLW(P_Random - P_Random, 20);
    damage := ((P_Random mod 5) + 1) * 3;
    P_LineAttack(actor, angle, MISSILERANGE, slope, damage);
  end;
end;

//==============================================================================
//
// A_CPosAttack
//
//==============================================================================
procedure A_CPosAttack(actor: Pmobj_t);
var
  angle: angle_t;
  bangle: angle_t;
  damage: integer;
  slope: integer;
begin
  if actor.target = nil then
    exit;

  S_StartSound(actor, actor.info.attacksound);
  A_FaceTarget(actor);
  bangle := actor.angle;

  slope := P_AimLineAttack(actor, bangle, MISSILERANGE);

  angle := bangle + _SHLW(P_Random - P_Random, 20);
  damage := ((P_Random mod 5) + 1) * 3;
  P_LineAttack(actor, angle, MISSILERANGE, slope, damage);
end;

//==============================================================================
//
// A_CPosRefire
//
//==============================================================================
procedure A_CPosRefire(actor: Pmobj_t);
begin
  // keep firing unless target got out of sight
  A_FaceTarget(actor);

  if P_Random < 40 then
    exit;

  if (actor.target = nil) or (actor.target.health <= 0) or
     not P_CheckSight(actor, actor.target) then
    if actor.state <> @states[actor.info.seestate] then
      P_SetMobjState(actor, actor.info.seestate);
end;

//==============================================================================
//
// A_TroopAttack
//
//==============================================================================
procedure A_TroopAttack(actor: Pmobj_t);
var
  damage: integer;
  mobj_no: integer;
begin
  if actor.target = nil then
    exit;

  A_FaceTarget(actor);
  if P_CheckMeleeRange(actor) then
  begin
    if actor.info.meleesound > 0 then
      S_StartSound(actor, actor.info.meleesound);
    damage := (P_Random mod 8 + 1) * 3;
    P_DamageMobj(actor.target, actor, actor, damage);
    exit;
  end;

  if not P_CheckStateParams(actor, 1) then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('A_TroopAttack(): Unknown missile %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  // launch a missile
  P_SpawnMissile(actor, actor.target, mobj_no);
end;

//==============================================================================
//
// A_SargAttack
//
//==============================================================================
procedure A_SargAttack(actor: Pmobj_t);
var
  damage: integer;
begin
  if actor.target = nil then
    exit;

  A_FaceTarget(actor);
  if P_CheckMeleeRange(actor) then
  begin
    damage := ((P_Random mod 10) + 1) * 4;
    P_DamageMobj(actor.target, actor, actor, damage);
  end;
end;

const
  TRACEANGLE = $c000000;

//==============================================================================
//
// A_Tracer
//
//==============================================================================
procedure A_Tracer(actor: Pmobj_t);
var
  exact: angle_t;
  dist: fixed_t;
  slope: fixed_t;
  dest: Pmobj_t;
  th: Pmobj_t;
begin
  if ((gametic - demostarttic) and 3) <> 0 then // [crispy] fix revenant internal demo bug
    exit;

  // spawn a puff of smoke behind the rocket
  P_SpawnPuff(actor.x, actor.y, actor.z);

  th := P_SpawnMobj(actor.x - actor.momx,
                    actor.y - actor.momy,
                    actor.z, Ord(MT_SMOKE));

  th.momz := FRACUNIT;
  th.tics := th.tics - P_Random and 3;
  if th.tics < 1 then
    th.tics := 1;

  // adjust direction
  dest := actor.tracer;

  if (dest = nil) or (dest.health <= 0) then
    exit;

  // change angle
  exact := R_PointToAngle2(actor.x, actor.y, dest.x, dest.y);

  if exact <> actor.angle then
  begin
    if exact - actor.angle > ANG180 then
    begin
      actor.angle := actor.angle - TRACEANGLE;
      if exact - actor.angle < ANG180 then
        actor.angle := exact;
    end
    else
    begin
      actor.angle := actor.angle + TRACEANGLE;
      if exact - actor.angle > ANG180 then
        actor.angle := exact;
    end;
  end;

  {$IFDEF FPC}
  exact := _SHRW(actor.angle, ANGLETOFINESHIFT);
  {$ELSE}
  exact := actor.angle shr ANGLETOFINESHIFT;
  {$ENDIF}
  actor.momx := FixedMul(actor.info.speed, finecosine[exact]);
  actor.momy := FixedMul(actor.info.speed, finesine[exact]);

  // change slope
  dist := P_AproxDistance(dest.x - actor.x, dest.y - actor.y);

  dist := dist div actor.info.speed;

  if dist < 1 then
    dist := 1;
  slope := (dest.z + 40 * FRACUNIT - actor.z) div dist;

  if slope < actor.momz then
    actor.momz := actor.momz - FRACUNIT div 8
  else
    actor.momz := actor.momz + FRACUNIT div 8;
end;

//
// SkullAttack
// Fly at the player like a missile.
//
const
  SKULLSPEED = 20 * FRACUNIT;

//==============================================================================
//
// A_SkullAttack
//
//==============================================================================
procedure A_SkullAttack(actor: Pmobj_t);
var
  dest: Pmobj_t;
  an: angle_t;
  dist: integer;
begin
  if actor.target = nil then
    exit;

  dest := actor.target;
  actor.flags := actor.flags or MF_SKULLFLY;

  A_AttackSound(actor, actor);
  A_FaceTarget(actor);
  {$IFDEF FPC}
  an := _SHRW(actor.angle, ANGLETOFINESHIFT);
  {$ELSE}
  an := actor.angle shr ANGLETOFINESHIFT;
  {$ENDIF}
  actor.momx := FixedMul(SKULLSPEED, finecosine[an]);
  actor.momy := FixedMul(SKULLSPEED, finesine[an]);
  dist := P_AproxDistance(dest.x - actor.x, dest.y - actor.y);
  dist := dist div SKULLSPEED;

  if dist < 1 then
    dist := 1;
  actor.momz := (dest.z + _SHR1(dest.height) - actor.z) div dist;
end;

//==============================================================================
//
// A_Scream
//
//==============================================================================
procedure A_Scream(actor: Pmobj_t);
var
  sound: integer;
begin
  sound := actor.info.deathsound;

  // Check for bosses.
  if (actor.flags_ex and MF_EX_BOSS <> 0) or
     (actor.flags2_ex and MF2_EX_FULLVOLDEATH <> 0) then
    // full volume
    S_StartSound(nil, sound)
  else
    S_StartSound(actor, sound);
end;

//==============================================================================
//
// A_XScream
//
//==============================================================================
procedure A_XScream(actor: Pmobj_t);
begin
  S_StartSound(actor, Ord(sfx_slop));
end;

//==============================================================================
//
// A_Pain
//
//==============================================================================
procedure A_Pain(actor: Pmobj_t);
begin
  A_PainSound1(actor);
end;

//==============================================================================
//
// A_Explode
//
//==============================================================================
procedure A_Explode(thingy: Pmobj_t);
begin
  if thingy.flags_ex and MF_EX_CUSTOMEXPLODE <> 0 then
    P_RadiusAttackEx(thingy, thingy.target, thingy.info.explosiondamage, thingy.info.explosionradius)
  else if thingy.state.params <> nil then
    P_RadiusAttackEx(thingy, thingy.target, thingy.state.params.IntVal[0], thingy.state.params.IntVal[1])
  else
    P_RadiusAttack(thingy, thingy.target, 128);
  if thingy.z <= thingy.floorz then
    P_HitFloor(thingy);
end;

//==============================================================================
//
// A_BossDeath
// Possibly trigger special effects
// if on first boss level
//
//==============================================================================
procedure A_BossDeath(mo: Pmobj_t);
var
  th: Pthinker_t;
  mo2: Pmobj_t;
  i: integer;
begin
  case gameepisode of
    1:
      begin
        if gamemap <> num_episode_maps[1] then
          if not majorbossdeathendsdoom1level then
            exit;
      end;
    2:
      begin
        if gamemap <> num_episode_maps[2] then
          if not majorbossdeathendsdoom1level then
            exit;
      end;
    3:
      begin
        if gamemap <> num_episode_maps[3] then
          if not majorbossdeathendsdoom1level then
            exit;
      end;
  else
    exit;
  end;

  // make sure there is a player alive for victory
  i := 0;
  while i < MAXPLAYERS do
  begin
    if playeringame[i] and (players[i].health > 0) then
      break;
    inc(i);
  end;

  if i = MAXPLAYERS then
    exit;  // no one left alive, so do not end game

  // scan the remaining thinkers to see
  // if all bosses are dead
  th := thinkercap.next;
  while Pointer(th) <> Pointer(@thinkercap) do
  begin
    if @th._function.acp1 = @P_MobjThinker then
    begin
      mo2 := Pmobj_t(th);
      if (mo2 <> mo) and (mo2.health > 0) then
      begin
        // other boss not dead
        if mo2._type = mo._type then
          exit;
        if mo2.flags_ex and MF_EX_BOSS <> 0 then
          exit;
      end;
    end;
    th := th.next;
  end;

  // victory!
  G_ExitLevel;
end;

//==============================================================================
//
// A_Hoof
//
//==============================================================================
procedure A_Hoof(mo: Pmobj_t);
begin
  S_StartSound(mo, Ord(sfx_hoof));
  A_Chase(mo);
end;

//==============================================================================
//
// A_PlayerScream
//
//==============================================================================
procedure A_PlayerScream(mo: Pmobj_t);
var
  sound: integer;
begin
  // Default death sound.
  sound := Ord(sfx_pldeth);

  S_StartSound(mo, sound);
end;

//----------------------------------------------------------------------------
//
// PROC P_Massacre
//
// Kills all monsters.
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_Massacre;
var
  mo: Pmobj_t;
  think: Pthinker_t;
begin
  think := thinkercap.next;
  while think <> @thinkercap do
  begin
    if @think._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(think);
      if (mo.flags and MF_COUNTKILL <> 0) and (mo.health > 0) then
      begin
        mo.flags_ex := mo.flags_ex and not MF_EX_INVULNERABLE;
        mo.flags := mo.flags or MF_SHOOTABLE;
        P_DamageMobj(mo, nil, nil, 10000);
      end;
    end;
    think := think.next;
  end;
end;

//==============================================================================
//
// A_TurretChase
//
//==============================================================================
procedure A_TurretChase(actor: Pmobj_t);
var
  delta: integer;
  nomissile: boolean;
begin
  if actor.reactiontime <> 0 then
    actor.reactiontime := actor.reactiontime - 1;

  // modify target threshold
  if actor.threshold <> 0 then
  begin
    if (actor.target = nil) or (actor.target.health <= 0) then
      actor.threshold := 0
    else
      actor.threshold := actor.threshold - 1;
  end;

  // turn towards movement direction if not there yet
  if actor.movedir < 8 then
  begin
    actor.angle := actor.angle and $E0000000;
    delta := actor.angle - _SHLW(actor.movedir, 29);

    if delta > 0 then
      actor.angle := actor.angle - ANG90 div 2
    else if delta < 0 then
      actor.angle := actor.angle + ANG90 div 2;
  end;

  if P_BothFriends(actor, actor.target) then
  begin
    if P_LookForTargets(actor, actor.flags_ex and MF_EX_LOOKALLAROUND <> 0) then
      exit; // got a new target
    if actor.state <> @states[actor.info.spawnstate] then
      P_SetMobjStateNF(actor, actor.info.spawnstate);
    exit;
  end;

  if (actor.target = nil) or
     (actor.target.flags and MF_SHOOTABLE = 0) then
  begin
    // look for a new target
    if P_LookForTargets(actor, true) then
      exit; // got a new target

    if actor.state <> @states[actor.info.spawnstate] then
      P_SetMobjStateNF(actor, actor.info.spawnstate);
    exit;
  end;

  // do not attack twice in a row
  if actor.flags and MF_JUSTATTACKED <> 0 then
  begin
    actor.flags := actor.flags and not MF_JUSTATTACKED;
    exit;
  end;

  // check for melee attack
  if (actor.info.meleestate <> 0) and P_CheckMeleeRange(actor) then
  begin
    A_MeleeSound(actor, actor);
    if actor.state <> @states[actor.info.meleestate] then
      P_SetMobjState(actor, actor.info.meleestate);
    exit;
  end;

  nomissile := false;
  // check for missile attack
  if actor.info.missilestate <> 0 then
  begin
    if (gameskill < sk_nightmare) and not fastparm and (actor.movecount <> 0) then
      nomissile := true
    else if not P_CheckMissileRange(actor) then
      nomissile := true;
    if not nomissile then
    begin
      if actor.state <> @states[actor.info.missilestate] then
        P_SetMobjState(actor, actor.info.missilestate);
      actor.flags := actor.flags or MF_JUSTATTACKED;
      exit;
    end;
  end;

  // possibly choose another target
  if netgame and
    (actor.threshold = 0) and
    not P_CheckSight(actor, actor.target) then
  begin
    if P_LookForTargets(actor, true) then
      exit;  // got a new target
  end;

  // make active sound
  if (actor.info.activesound <> 0) and (P_Random < 3) then
    A_ActiveSound(actor, actor);
end;

end.

