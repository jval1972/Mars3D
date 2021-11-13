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
//   Underwater software rendering
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit r_underwater;

interface

uses
  d_player;

procedure R_InitUnderwater;

procedure R_ShutDownUnderwater;

procedure R_UnderwaterExecute(const p: Pplayer_t);

implementation

uses
  d_delphi,
  doomdef,
  m_fixed,
  r_draw,
  r_hires,
  tables,
  z_zone;

type
  underwater_t = record
    XDisp, YDisp: PIntegerArray;
    screen8: PByteArray;
    screen32: PLongWordArray;
  end;
  Punderwater_t = ^underwater_t;

var
  u: underwater_t;
  uviewheight: integer;
  uviewwidth: integer;

const
  DISP_STRENGTH_PCT = 1; // SOS: For value > 2 R_UnderwaterCalcX & R_UnderwaterCalcY will overflow in 4k
  U_CALC_INTERVAL = FRACUNIT div LONGTICS_FACTOR;

procedure R_UnderwaterCalcX;
var
  i: integer;
begin
  for i := 0 to LONGTICS_FACTOR * uviewwidth - 1 do
    u.XDisp[i] := fixedsine[(i * U_CALC_INTERVAL) div uviewwidth] * DISP_STRENGTH_PCT * uviewwidth div 100;
end;

procedure R_UnderwaterCalcY;
var
  i: integer;
begin
  for i := 0 to LONGTICS_FACTOR * uviewheight - 1 do
    u.YDisp[i] := fixedcosine[(i * U_CALC_INTERVAL) div uviewheight] * DISP_STRENGTH_PCT * uviewheight div 100;
end;

procedure R_InitUnderwater;
begin
  uviewwidth := SCREENWIDTH;  // JVAL: normally viewwidth, but in case it is not calced
  uviewheight := SCREENHEIGHT;  // JVAL: normally viewheight, but in case it is not calced
  u.XDisp := malloc(SCREENWIDTH * LONGTICS_FACTOR * SizeOf(integer));
  R_UnderwaterCalcX;
  u.YDisp := malloc(SCREENHEIGHT * LONGTICS_FACTOR * SizeOf(integer));
  R_UnderwaterCalcY;
  u.screen8 := malloc(SCREENWIDTH * SCREENHEIGHT * SizeOf(byte));
  u.screen32 := malloc(SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
end;

procedure R_ShutDownUnderwater;
begin
  memfree(pointer(u.XDisp), SCREENWIDTH * SizeOf(integer));
  memfree(pointer(u.YDisp), SCREENHEIGHT * SizeOf(integer));
  memfree(pointer(u.screen8), SCREENWIDTH * SCREENHEIGHT * SizeOf(byte));
  memfree(pointer(u.screen32), SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
end;

procedure R_UnderwaterReadScreen8;
var
  i: integer;
  p: PByteArray;
begin
  p := @u.screen8[0];
  for i := 0 to uviewheight - 1 do
  begin
    memcpy(p, @ylookup[i][viewwindowx], uviewwidth * SizeOf(byte));
    p := @p[uviewwidth];
  end;
end;

procedure R_UnderwaterReadScreen32;
var
  i: integer;
  p: PLongWordArray;
begin
  p := @u.screen32[0];
  for i := 0 to uviewheight - 1 do
  begin
    memcpy(p, @ylookupl[i][viewwindowx], uviewwidth * SizeOf(LongWord));
    p := @p[uviewwidth];
  end;
end;

procedure R_UnderwaterExecute(const p: Pplayer_t);
var
  tic: integer;
  pL: PLongWordArray;
  pB: PByteArray;
  x, y: integer;
  newx, newy: integer;
begin
  tic := p.underwatertics;
  if tic = 0 then
    Exit;

  if uviewwidth <> viewwidth then
  begin
    uviewwidth := viewwidth;
    R_UnderwaterCalcX;
  end;
  if uviewheight <> viewheight then
  begin
    uviewheight := viewheight;
    R_UnderwaterCalcY;
  end;

  if videomode = vm32bit then
  begin
    R_UnderwaterReadScreen32;
    for y := 0 to uviewheight - 1 do
    begin
      pL := @ylookupl[y][viewwindowx];
      for x := 0 to uviewwidth - 1 do
      begin
        newx := x + u.XDisp[2 * (y * LONGTICS_FACTOR + tic) mod (LONGTICS_FACTOR * uviewwidth)] div FRACUNIT;
        if newx < 0 then newx := 0;
        if newx >= uviewwidth then newx := uviewwidth - 1;
        newy := y + u.YDisp[3 * (x * LONGTICS_FACTOR + tic) mod (LONGTICS_FACTOR * uviewheight)] div FRACUNIT;
        if newy < 0 then newy := 0;
        if newy >= uviewheight then newy := uviewheight - 1;
        pL[x] := u.screen32[newy * uviewwidth + newx];
      end;
    end;
  end
  else
  begin
    R_UnderwaterReadScreen8;
    for y := 0 to uviewheight - 1 do
    begin
      pB := @ylookup[y][viewwindowx];
      for x := 0 to uviewwidth - 1 do
      begin
        newx := x + u.XDisp[2 * (y * LONGTICS_FACTOR + tic) mod (LONGTICS_FACTOR * uviewwidth)] div FRACUNIT;
        if newx < 0 then newx := 0;
        if newx >= uviewwidth then newx := uviewwidth - 1;
        newy := y + u.YDisp[3 * (x * LONGTICS_FACTOR + tic) mod (LONGTICS_FACTOR * uviewheight)] div FRACUNIT;
        if newy < 0 then newy := 0;
        if newy >= uviewheight then newy := uviewheight - 1;
        pB[x] := u.screen8[newy * uviewwidth + newx];
      end;
    end;
  end;

end;

end.
