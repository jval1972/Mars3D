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

const
  UNDERWATER_COLORMAP = 'WATERMAP';

var
  cm_underwater: integer = -1;

implementation

uses
  d_delphi,
  doomdef,
  i_system,
  m_fixed,
  mt_utils,
  r_colormaps,
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
  DISP_STRENGTH_PCT = 2; // SOS: For value > 2 R_UnderwaterCalcX & R_UnderwaterCalcY will overflow in 4k unless we use floating point
  U_CALC_INTERVAL = FRACUNIT div LONGTICS_FACTOR;

procedure R_UnderwaterCalcX;
var
  i: integer;
begin
  for i := 0 to LONGTICS_FACTOR * uviewwidth - 1 do
    u.XDisp[i] := Trunc(fixedsine[(i * U_CALC_INTERVAL) div uviewwidth] / FRACUNIT * DISP_STRENGTH_PCT * uviewwidth / 100);
end;

procedure R_UnderwaterCalcY;
var
  i: integer;
begin
  for i := 0 to LONGTICS_FACTOR * uviewheight - 1 do
    u.YDisp[i] := Trunc(fixedcosine[(i * U_CALC_INTERVAL) div uviewheight] / FRACUNIT * DISP_STRENGTH_PCT * uviewheight / 100);
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
  cm_underwater := R_CustomColorMapForName(UNDERWATER_COLORMAP);
  if cm_underwater < 0 then
    I_Error('R_InitUnderwater(): Underwater palette not found');
end;

procedure R_ShutDownUnderwater;
begin
  memfree(pointer(u.XDisp), SCREENWIDTH * LONGTICS_FACTOR * SizeOf(integer));
  memfree(pointer(u.YDisp), SCREENHEIGHT * LONGTICS_FACTOR * SizeOf(integer));
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

const
  INTERVAL_FACTOR = 3;

var
  underwatertic: integer;

procedure R_UnderwaterDoExecute(const threadid, numlthreads: integer);
var
  tic: integer;
  pL: PLongWord;
  pB: PByte;
  x, xstart, xend, y: integer;
  newx, newy: integer;
  llwidth, llheight: integer;
  lx, ly: integer;
begin
  tic := underwatertic;
  llwidth := LONGTICS_FACTOR * uviewwidth;
  llheight := LONGTICS_FACTOR * uviewheight;
  if videomode = vm32bit then
  begin
    ly := tic;
    for y := 0 to uviewheight - 1 do
    begin
      if y mod numlthreads = threadid then
      begin
        lx := tic mod llheight;
        pL := @ylookupl[y][viewwindowx];
        xstart := u.XDisp[ly mod llwidth];
        xend := xstart + uviewwidth - 1;
        for x := xstart to xend do
        begin
          newx := x;
          if newx < 0 then
            newx := 0
          else if newx >= uviewwidth then
            newx := uviewwidth - 1;

          newy := y + u.YDisp[lx];
          if newy < 0 then
            newy := 0
          else if newy >= uviewheight then
            newy := uviewheight - 1;

          pL^ := u.screen32[newy * uviewwidth + newx];
          Inc(pL);
          Inc(lx, LONGTICS_FACTOR);
          if lx >= llheight then
            lx := lx - llheight;
        end;
      end;
      Inc(ly, LONGTICS_FACTOR);
    end;
  end
  else
  begin
    ly := tic;
    for y := 0 to uviewheight - 1 do
    begin
      if y mod numlthreads = threadid then
      begin
        lx := tic mod llheight;
        pB := @ylookup[y][viewwindowx];
        xstart := u.XDisp[ly mod llwidth];
        xend := xstart + uviewwidth - 1;
        for x := xstart to xend do
        begin
          newx := x;
          if newx < 0 then
            newx := 0
          else if newx >= uviewwidth then
            newx := uviewwidth - 1;

          newy := y + u.YDisp[lx];
          if newy < 0 then
            newy := 0
          else if newy >= uviewheight then
            newy := uviewheight - 1;

          pB^ := u.screen8[newy * uviewwidth + newx];
          Inc(pB);
          Inc(lx, LONGTICS_FACTOR);
          if lx >= llheight then
            lx := lx - llheight;
        end;
      end;
      Inc(ly, LONGTICS_FACTOR);
    end;
  end;
end;

function _UnderwaterExecute_thr(p: iterator_p): integer; stdcall;
begin
  R_UnderwaterDoExecute(p.idx, p.numidxs);
  result := 0;
end;

procedure R_UnderwaterExecute(const p: Pplayer_t);
var
  tic64: int64;
begin
  tic64 := p.underwatertics;
  if tic64 = 0 then
    Exit;
  tic64 := INTERVAL_FACTOR * tic64 * uviewwidth div (LONGTICS_FACTOR * TICRATE);
  underwatertic := tic64;

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
    R_UnderwaterReadScreen32
  else
    R_UnderwaterReadScreen8;

  if usemultithread then
    MT_Iterate(@_UnderwaterExecute_thr, nil)
  else
    R_UnderwaterDoExecute(0, 1);
end;

end.
