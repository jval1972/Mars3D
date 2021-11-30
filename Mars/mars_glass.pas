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
//  DESCRIPTION:
//    Breakable glass helpers
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_glass;

interface

uses
  r_defs;

procedure MARS_SpawnBrokenGlass(line: Pline_t);

implementation

uses
  doomdata,
  info_common,
  m_fixed,
  m_rnd,
  p_local,
  p_mobj_h,
  p_mobj,
  p_setup,
  mars_sounds,
  p_maputl,
  tables;

var
  MT_GLASS1: integer = -2;
  MT_GLASS2: integer = -2;
  MT_GLASS3: integer = -2;

procedure MARS_SpawnBrokenGlass(line: Pline_t);
const
  DEBRIS_STEP = 32 * FRACUNIT;
var
  x1, y1: fixed_t;
  x2, y2: fixed_t;
  dx, dy: fixed_t;
  A: array[0..2] of integer;
  i, j: integer;
  len: fixed_t;
  cnt: integer;
  x, y: fixed_t;
  debris: Pmobj_t;
  an: angle_t;
begin
  x1 := line.v1.x;
  y1 := line.v1.y;
  x2 := line.v2.x;
  y2 := line.v2.y;

  // Break glass sound
  MARS_AmbientSound((x1 div 2) + (x2 div 2), (y1 div 2) + (y2 div 2), snd_GLASEXP);

  // Change line to no blocking and without texture
  line.flags := line.flags and not ML_BLOCKING;
  line.special := 0;
  if line.sidenum[0] >= 0 then
    sides[line.sidenum[0]].midtexture := 0;
  if line.sidenum[1] >= 0 then
    sides[line.sidenum[1]].midtexture := 0;

  // Spawn glass debris
  if MT_GLASS1 = -2 then
    MT_GLASS1 := Info_GetMobjNumForName('MT_GLASS1');

  if MT_GLASS2 = -2 then
    MT_GLASS2 := Info_GetMobjNumForName('MT_GLASS2');

  if MT_GLASS3 = -2 then
    MT_GLASS3 := Info_GetMobjNumForName('MT_GLASS2');

  A[0] := MT_GLASS1;
  A[1] := MT_GLASS2;
  A[2] := MT_GLASS3;

  // Resolve missing declarations
  for i := 0 to 2 do
    if A[i] < 0 then
      for j := 0 to 2 do
        if A[j] >= 0 then
          A[i] := A[j];

  for i := 0 to 2 do
    if A[i] < 0 then
      exit; // At this point we didn't find any glass debris :(


  dx := x2 - x1;
  dy := y2 - y1;
  len := P_AproxDistance(dx, dy);

  cnt := len div DEBRIS_STEP;
  if cnt <= 0 then
    cnt := 1;

  for i := 0 to cnt - 1 do
  begin
    x := x1 + dx div (2 * cnt) * (2 * i + 1);
    y := y1 + dy div (2 * cnt) * (2 * i + 1);
    for j := 0 to 5 do  // 6 debris in each spot
    begin
      debris := P_SpawnMobj(x + Sys_Random * DEBRIS_STEP div 512, y + Sys_Random * DEBRIS_STEP div 512, ONFLOATZ, A[P_Random mod 3]);
      an := (P_Random * 8192) div 256;

      debris.angle := an * ANGLETOFINEUNIT;
      debris.momx := FixedMul(finecosine[an], (P_Random and 3) * FRACUNIT);
      debris.momy := FixedMul(finesine[an], (P_Random and 3) * FRACUNIT);
      debris.momz := (P_Random and 7) * FRACUNIT;
      debris.tics := debris.tics + (P_Random + 7) and 7;
      debris.scale := FRACUNIT + Sys_Random * 64;
    end;
  end;
end;

end.
