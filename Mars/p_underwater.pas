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
// DESCRIPTION:
//   Underwater logic
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_underwater;

interface

uses
  d_player,
  m_fixed,
  p_mobj_h;

procedure P_SetupUnderwaterSectors;

procedure P_ResolveSwimmSurface(const thing: Pmobj_t);

function P_ResolveSwimmFloorHeight(const thing: Pmobj_t; const oldfloorz: fixed_t): fixed_t;

procedure P_GlobalAdjustSwimming;

procedure P_CheckPlayerWaterSector(const p: Pplayer_t);

const
  UNDERWATER_COLORMAP = 'WATERMAP';

var
  cm_underwater: integer = -1;

const
  U_INTERVAL_FACTOR = 3;
  U_DISP_STRENGTH_PCT = 2; // SOS: For value > 2 R_UnderwaterCalcX & R_UnderwaterCalcY will overflow in 4k unless we use floating point

implementation

uses
  doomdef,
  d_think,
  info_common,
  info_rnd,
  m_bbox,
  mars_sounds,
  p_3dfloors,
  p_common,
  p_local,
  p_inter,
  p_map,
  p_maputl,
  p_mobj,
  p_setup,
  p_slopes,
  p_tick,
  p_user,
  r_defs,
  r_intrpl,
  r_main;

procedure P_RecursiveUnderwaterSector(const sec: Psector_t);
var
  i: integer;
  line: Pline_t;
begin
  if sec.renderflags and SRF_UNDERWATER <> 0 then
    Exit;
  sec.renderflags := sec.renderflags or SRF_UNDERWATER;
  sec.gravity := 0;
  for i := 0 to sec.linecount - 1 do
  begin
    line := sec.lines[i];
    if line.frontsector <> nil then
      if line.frontsector <> sec then
        P_RecursiveUnderwaterSector(line.frontsector);
    if line.backsector <> nil then
      if line.backsector <> sec then
        P_RecursiveUnderwaterSector(line.backsector);
  end;
end;

procedure P_SetupUnderwaterSectors;
var
  i: integer;
  sec: Psector_t;
begin
  sec := @sectors[0];
  for i := 0 to numsectors - 1 do
  begin
    if sec.special = 10 then
      P_RecursiveUnderwaterSector(sec);
    Inc(sec);
  end;
end;

//
// P_ResolveSwimmSurface
// JVAL: 20211115 - New function, checks the MF4_EX_CANSWIMMONFAKESURFACE flag
//
procedure P_ResolveSwimmSurface(const thing: Pmobj_t);
var
  sec, hsec: Psector_t;
begin
  if thing.flags4_ex and MF4_EX_CANSWIMMONFAKESURFACE = 0 then
    exit;

  sec := Psubsector_t(thing.subsector).sector;
  if sec.heightsec < 0 then
    exit;

  hsec := @sectors[sec.heightsec];
  if hsec.floorheight > sec.floorheight then
  begin
    thing.floorz := hsec.floorheight;
    if thing.z < thing.floorz then
      thing.z := thing.floorz;
  end;
end;

//
// P_ResolveSwimmFloorHeight
// JVAL: 20211115 - New function, checks the MF4_EX_CANSWIMMONFAKESURFACE flag
//
function P_ResolveSwimmFloorHeight(const thing: Pmobj_t; const oldfloorz: fixed_t): fixed_t;
var
  sec, hsec: Psector_t;
begin
  result := oldfloorz;

  if thing.flags4_ex and MF4_EX_CANSWIMMONFAKESURFACE = 0 then
    exit;

  sec := Psubsector_t(thing.subsector).sector;
  if sec.heightsec < 0 then
    exit;

  hsec := @sectors[sec.heightsec];
  if hsec.floorheight > oldfloorz then
    result := hsec.floorheight;
end;

//
// P_GlobalAdjustSwimming
// JVAL: 20211115 - New function, checks the MF4_EX_CANSWIMMONFAKESURFACE flag
//       for all mobj's at loading level
//
procedure P_GlobalAdjustSwimming;
var
  th: Pthinker_t;
  mo: Pmobj_t;
begin
  th := thinkercap.next;
  while th <> @thinkercap do
  begin
    if @th._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(th);
      P_ResolveSwimmSurface(mo);
    end;
    th := th.next;
  end;
end;

//
// PIT_CheckWaterPortalThing
//
function PIT_CheckWaterPortalThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
// Can't shoot it? Can't stomp it!
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUACTORS flag - does not colide with actors
  if (tmthing.flags3_ex and MF3_EX_THRUACTORS <> 0) or (thing.flags3_ex and MF3_EX_THRUACTORS <> 0) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (tmthing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(thing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (thing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(tmthing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUSPECIES flag - does not colide with same species (also inheritance)
  if tmthing.flags3_ex and MF3_EX_THRUSPECIES <> 0 then
  begin
    if tmthing._type = thing._type then
    begin
      result := true;
      exit;
    end;
    if Info_GetInheritance(tmthing.info) = Info_GetInheritance(thing.info) then
    begin
      result := true;
      exit;
    end;
  end;

  blockdist := thing.radius + tmthing.radius;

  if (abs(thing.x - tmx) >= blockdist) or (abs(thing.y - tmy) >= blockdist) then
  begin
    // didn't hit it
    result := true;
    exit;
  end;

  // don't clip against self
  if thing = tmthing then
  begin
    result := true;
    exit;
  end;

  P_DamageMobj(thing, tmthing, tmthing, 10000);

  result := true;
end;

//
// P_WaterPortalMove
//
function P_WaterPortalMove(thing: Pmobj_t; newsec: Psector_t; x, y, z: fixed_t): boolean;
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  r: fixed_t;
begin
  // kill anything occupying the position
  tmthing := thing;

  tmx := x;
  tmy := y;

  r := tmthing.radius;
  tmbbox[BOXTOP] := y + r;
  tmbbox[BOXBOTTOM] := y - r;
  tmbbox[BOXRIGHT] := x + r;
  tmbbox[BOXLEFT] := x - r;

  ceilingline := nil;

  // The base floor/ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  //**tmdropoffz := newsubsec.sector.floorheight;
  tmdropoffz := P_FloorHeight(newsec, x, y); // JVAL: Slopes
  tmdropoffz := P_ResolveSwimmFloorHeight(thing, tmdropoffz);
  tmfloorz := tmdropoffz;

  tmceilingz := P_CeilingHeight(newsec, x, y);  // JVAL: Slopes
  tmfloorpic := newsec.floorpic;

  inc(validcount);
  numspechit := 0;

  // stomp on any things contacted
  if internalblockmapformat then
  begin
    xl := MapBlockIntX(int64(tmbbox[BOXLEFT]) - int64(bmaporgx) - MAXRADIUS);
    xh := MapBlockIntX(int64(tmbbox[BOXRIGHT]) - int64(bmaporgx) + MAXRADIUS);
    yl := MapBlockIntY(int64(tmbbox[BOXBOTTOM]) - int64(bmaporgy) - MAXRADIUS);
    yh := MapBlockIntY(int64(tmbbox[BOXTOP]) - int64(bmaporgy) + MAXRADIUS);
  end
  else
  begin
    xl := MapBlockInt(tmbbox[BOXLEFT] - bmaporgx - MAXRADIUS);
    xh := MapBlockInt(tmbbox[BOXRIGHT] - bmaporgx + MAXRADIUS);
    yl := MapBlockInt(tmbbox[BOXBOTTOM] - bmaporgy - MAXRADIUS);
    yh := MapBlockInt(tmbbox[BOXTOP] - bmaporgy + MAXRADIUS);
  end;

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_CheckWaterPortalThing) then
      begin
        result := false;
        exit;
      end;

  // the move is ok,
  // so link the thing into its new position
  P_UnsetThingPosition(thing);

  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;
  thing.x := x;
  thing.y := y;
  thing.z := z;

  P_SetThingPosition(thing);
  P_ResolveSwimmSurface(thing);

  // JVAL: 20200507 - Do not report false velocity
  thing.oldx := thing.x;
  thing.oldy := thing.y;
  thing.oldz := thing.z;

  thing.soundorg1.x := thing.x;
  thing.soundorg1.y := thing.y;
  thing.soundorg1.z := thing.z;

  if thing.player = viewplayer then
    R_SetInterpolateSkipTicks(1);

  thing.flags := thing.flags or MF_JUSTAPPEARED;

  if thing.player <> nil then
    thing.flags4_ex := thing.flags4_ex and not MF4_EX_VIEWZCALCED;

  thing.intrplcnt := 0;

  result := true;
end;

procedure P_PlayerSwimFlag(const p: Pplayer_t);
begin
  if Psubsector_t(p.mo.subsector).sector.renderflags and SRF_UNDERWATER <> 0 then
    p.mo.flags4_ex := p.mo.flags4_ex or MF4_EX_SWIM
  else
    p.mo.flags4_ex := p.mo.flags4_ex and not MF4_EX_SWIM;
end;

procedure P_CheckPlayerWaterSector(const p: Pplayer_t);
var
  pmo: Pmobj_t;
  sec1, sec2: Psector_t;
  i: integer;
  cheight: fixed_t;
  oldx, oldy: fixed_t;
  newx, newy, newz: fixed_t;
begin
  pmo := p.mo;
  if pmo = nil then
    exit;

  P_PlayerSwimFlag(p);

  if p.nextunderwaterportaltic > leveltime then
    if p.playerstate <> PST_DEAD then
      exit; // not allowed to jump yet

  sec1 := Psubsector_t(pmo.subsector).sector;
  sec2 := nil;

  if sec1.special = 14 then // Player is in upwater portal
  begin
    if p.viewz <= P_3DFloorHeight(pmo) + PUNDERWATERPORTALHEIGHT then
      for i := 0 to numsectors - 1 do
        if sectors[i].tag = sec1.tag then
          if sectors[i].special = 10 then
          begin
            sec2 := @sectors[i];
            break;
          end;
  end
  else if sec1.special = 10 then // Player is in underwater portal
  begin
    cheight := P_3DCeilingHeight(pmo);
    if (p.viewz >= cheight - PUNDERWATERSECTORCHEIGHT) or
       (pmo.z + pmo.height >= cheight) then
      for i := 0 to numsectors - 1 do
        if sectors[i].tag = sec1.tag then
          if sectors[i].special = 14 then
          begin
            sec2 := @sectors[i];
            break;
          end;
  end;

  if sec2 = nil then
    exit; // No matching sector to move


  newx := pmo.x - sec1.bbox[BOXLEFT] + sec2.bbox[BOXLEFT];
  newy := pmo.y - sec1.bbox[BOXTOP] + sec2.bbox[BOXTOP];

  if sec1.special = 14 then
  // Player is upwater, newz is at the top of sec2
    newz := P_CeilingHeight(sec2, newx, newy) - pmo.height
  else
  // Player is underwater, newz is at the bottom of sec2
    newz := P_FloorHeight(sec2, newx, newy);

  oldx := pmo.x;
  oldy := pmo.y;

  if not P_WaterPortalMove(pmo, sec2, newx, newy, newz) then
    exit;

  p.deltaviewheight := 0;
  p.crouchheight := 0;

  P_PlayerSwimFlag(p);

  if pmo.flags4_ex and MF4_EX_SWIM <> 0 then
    pmo.momz := - MAX_PLAYERSWIMZMOVE div 2
  else
  begin
    pmo.momz := MAX_PLAYERSWIMZMOVE div 2;
    p.deltaviewheight := pmo.momz;
  end;

  MARS_AmbientSound(oldx, oldy, snd_WATERIN1);
  MARS_AmbientSound(pmo.x, pmo.y, snd_WATERIN1);

  p.nextunderwaterportaltic := leveltime + TICRATE div 2;
end;

end.
