//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2019 by Jim Valavanis
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
//  Multithreading flat rendering - 32 bit color
//
//------------------------------------------------------------------------------
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_flat32;

interface

uses
  d_delphi,
  m_fixed,
  r_span;

type
  flatrenderinfo32_t = record
    ds_source32: PLongWordArray;
    ds_lightlevel: fixed_t;
    ds_y, ds_x1, ds_x2: integer;
    ds_xfrac: fixed_t;
    ds_yfrac: fixed_t;
    ds_xstep: fixed_t;
    ds_ystep: fixed_t;
    ds_ripple: PIntegerArray;
    ds_scale: dsscale_t;
    func: PPointerParmProcedure;
  end;
  Pflatrenderinfo32_t = ^flatrenderinfo32_t;

  flatrenderinfo32_tArray = array[0..$FFF] of flatrenderinfo32_t;
  Pflatrenderinfo32_tArray = ^flatrenderinfo32_tArray;

procedure R_StoreFlatSpan32;

procedure R_InitFlatsCache32;

procedure R_ShutDownFlatsCache32;

procedure R_RenderSingleThreadFlats32;

procedure R_RenderMultiThreadFlats32;

procedure R_RenderMultiThreadFFloors32;


var
  force_numflatrenderingthreads_32bit: integer = 0;

procedure R_DrawSpanNormalMT(const fi: pointer);

procedure R_DrawSpanNormal_RippleMT(const fi: pointer);

implementation

uses
  i_system,
  mt_utils,
  r_draw,
  r_main,
  r_precalc,
  r_ripple,
  r_span32;

var
  flatcache32: Pflatrenderinfo32_tArray;
  flatcachesize32: integer;
  flatcacherealsize32: integer;

procedure R_GrowFlatsCache32;
begin
  if flatcachesize32 >= flatcacherealsize32 then
  begin
    realloc(Pointer(flatcache32), flatcacherealsize32 * SizeOf(flatrenderinfo32_t), (64 + flatcacherealsize32) * SizeOf(flatrenderinfo32_t));
    flatcacherealsize32 := flatcacherealsize32 + 64;
  end;
end;

procedure R_StoreFlatSpan32;
var
  flat: Pflatrenderinfo32_t;
begin
  if ds_x2 - ds_x1 < 0 then
    exit;

  R_GrowFlatsCache32;
  flat := @flatcache32[flatcachesize32];
  flat.ds_source32 := ds_source32;
  flat.ds_lightlevel := ds_lightlevel;
  flat.ds_y := ds_y;
  flat.ds_x1 := ds_x1;
  flat.ds_x2 := ds_x2;
  flat.ds_xfrac := ds_xfrac;
  flat.ds_yfrac := ds_yfrac;
  flat.ds_xstep := ds_xstep;
  flat.ds_ystep := ds_ystep;
  flat.ds_ripple := ds_ripple;
  flat.ds_scale := ds_scale;
  flat.func := spanfuncMT;
  inc(flatcachesize32);
end;

procedure R_InitFlatsCache32;
begin
  flatcache32 := nil;
  flatcachesize32 := 0;
  flatcacherealsize32 := 0;
end;

procedure R_ShutDownFlatsCache32;
begin
  if flatcacherealsize32 <> 0 then
  begin
    memfree(pointer(flatcache32), flatcacherealsize32 * SizeOf(flatrenderinfo32_t));
    flatcacherealsize32 := 0;
  end;
end;

procedure R_RenderSingleThreadFlats32;
var
  item1, item2: Pflatrenderinfo32_t;
begin
  if flatcachesize32 = 0 then
    exit;

  item1 := @flatcache32[0];
  item2 := @flatcache32[flatcachesize32 - 1];
  while integer(item1) <= integer(item2) do
  begin
    item1.func(item1);
    inc(item1);
  end;
  flatcachesize32 := 0;
end;

const
  MAXFLATRENDERINGTHREADS32 = 16;

procedure _flat_thread_worker32(const p: pointer) stdcall;
var
  item1, item2: Pflatrenderinfo32_t;
begin
  item1 := @flatcache32[mt_range_p(p).start];
  item2 := @flatcache32[mt_range_p(p).finish];
  while integer(item1) <= integer(item2) do
  begin
    item1.func(item1);
    inc(item1);
  end;
end;

procedure R_RenderMultiThreadFlats32;
var
  R: array[0..MAXFLATRENDERINGTHREADS32 - 1] of mt_range_t;
  numthreads: integer;
  i: integer;
begin
  if flatcachesize32 = 0 then
    exit;

  if force_numflatrenderingthreads_32bit > 0 then
  begin
    numthreads := force_numflatrenderingthreads_32bit;
    if numthreads < 2 then
    begin
      numthreads := 2;
      force_numflatrenderingthreads_32bit := 2;
    end
    else if numthreads > MAXFLATRENDERINGTHREADS32 then
    begin
      numthreads := MAXFLATRENDERINGTHREADS32;
      force_numflatrenderingthreads_32bit := MAXFLATRENDERINGTHREADS32;
    end;
  end
  else
  begin
    numthreads := I_GetNumCPUs;
    if numthreads < 2 then
      numthreads := 2
    else if numthreads > MAXFLATRENDERINGTHREADS32 then
      numthreads := MAXFLATRENDERINGTHREADS32;
  end;

  if flatcachesize32 < numthreads then
  begin
    R[0].start := 0;
    R[0].finish := flatcachesize32 - 1;
    _flat_thread_worker32(@R[0]);
    flatcachesize32 := 0;
    exit;
  end;

  R[0].start := 0;
  for i := 1 to numthreads - 1 do
    R[i].start := Round((flatcachesize32 / numthreads) * i);
  for i := 0 to numthreads - 2 do
    R[i].finish := R[i + 1].start - 1;
  R[numthreads - 1].finish := flatcachesize32 - 1;

  case numthreads of
   2:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1]
    );
   3:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2]
    );
   4:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3]
    );
   5:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4]
    );
   6:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5]
    );
   7:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6]
    );
   8:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7]
    );
   9:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8]
    );
  10:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8],
      @_flat_thread_worker32, @R[9]
    );
  11:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8],
      @_flat_thread_worker32, @R[9],
      @_flat_thread_worker32, @R[10]
    );
  12:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8],
      @_flat_thread_worker32, @R[9],
      @_flat_thread_worker32, @R[10],
      @_flat_thread_worker32, @R[11]
    );
  13:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8],
      @_flat_thread_worker32, @R[9],
      @_flat_thread_worker32, @R[10],
      @_flat_thread_worker32, @R[11],
      @_flat_thread_worker32, @R[12]
    );
  14:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8],
      @_flat_thread_worker32, @R[9],
      @_flat_thread_worker32, @R[10],
      @_flat_thread_worker32, @R[11],
      @_flat_thread_worker32, @R[12],
      @_flat_thread_worker32, @R[13]
    );
  15:
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8],
      @_flat_thread_worker32, @R[9],
      @_flat_thread_worker32, @R[10],
      @_flat_thread_worker32, @R[11],
      @_flat_thread_worker32, @R[12],
      @_flat_thread_worker32, @R[13],
      @_flat_thread_worker32, @R[14]
    );
  else
    MT_Execute(
      @_flat_thread_worker32, @R[0],
      @_flat_thread_worker32, @R[1],
      @_flat_thread_worker32, @R[2],
      @_flat_thread_worker32, @R[3],
      @_flat_thread_worker32, @R[4],
      @_flat_thread_worker32, @R[5],
      @_flat_thread_worker32, @R[6],
      @_flat_thread_worker32, @R[7],
      @_flat_thread_worker32, @R[8],
      @_flat_thread_worker32, @R[9],
      @_flat_thread_worker32, @R[10],
      @_flat_thread_worker32, @R[11],
      @_flat_thread_worker32, @R[12],
      @_flat_thread_worker32, @R[13],
      @_flat_thread_worker32, @R[14],
      @_flat_thread_worker32, @R[15]
    );
  end;

  flatcachesize32 := 0;
end;


procedure _flat3D_thread_worker32(const p: pointer) stdcall;
var
  item1, item2: Pflatrenderinfo32_t;
  start, finish: integer;
begin
  item1 := @flatcache32[0];
  item2 := @flatcache32[flatcachesize32 - 1];
  start := mt_range_p(p).start;
  finish := mt_range_p(p).finish;
  while integer(item1) <= integer(item2) do
  begin
    if item1.ds_y >= start then
      if item1.ds_y <= finish then
        item1.func(item1);
    inc(item1);
  end;
end;

procedure R_RenderMultiThreadFFloors32;
var
  R: array[0..MAXFLATRENDERINGTHREADS32 - 1] of mt_range_t;
  numthreads: integer;
  i: integer;
begin
  if flatcachesize32 = 0 then
    exit;

  if force_numflatrenderingthreads_32bit > 0 then
  begin
    numthreads := force_numflatrenderingthreads_32bit;
    if numthreads < 2 then
    begin
      numthreads := 2;
      force_numflatrenderingthreads_32bit := 2;
    end
    else if numthreads > MAXFLATRENDERINGTHREADS32 then
    begin
      numthreads := MAXFLATRENDERINGTHREADS32;
      force_numflatrenderingthreads_32bit := MAXFLATRENDERINGTHREADS32;
    end;
  end
  else
  begin
    numthreads := I_GetNumCPUs;
    if numthreads < 2 then
      numthreads := 2
    else if numthreads > MAXFLATRENDERINGTHREADS32 then
      numthreads := MAXFLATRENDERINGTHREADS32;
  end;

  if viewheight < numthreads then
  begin
    R[0].start := 0;
    R[0].finish := viewheight - 1;
    _flat3D_thread_worker32(@R[0]);
    flatcachesize32 := 0;
    exit;
  end;

  R[0].start := 0;
  for i := 1 to numthreads - 1 do
    R[i].start := Round((viewheight / numthreads) * i);
  for i := 0 to numthreads - 2 do
    R[i].finish := R[i + 1].start - 1;
  R[numthreads - 1].finish := viewheight - 1;

  case numthreads of
   2:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1]
    );
   3:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2]
    );
   4:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3]
    );
   5:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4]
    );
   6:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5]
    );
   7:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6]
    );
   8:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7]
    );
   9:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8]
    );
  10:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8],
      @_flat3D_thread_worker32, @R[9]
    );
  11:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8],
      @_flat3D_thread_worker32, @R[9],
      @_flat3D_thread_worker32, @R[10]
    );
  12:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8],
      @_flat3D_thread_worker32, @R[9],
      @_flat3D_thread_worker32, @R[10],
      @_flat3D_thread_worker32, @R[11]
    );
  13:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8],
      @_flat3D_thread_worker32, @R[9],
      @_flat3D_thread_worker32, @R[10],
      @_flat3D_thread_worker32, @R[11],
      @_flat3D_thread_worker32, @R[12]
    );
  14:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8],
      @_flat3D_thread_worker32, @R[9],
      @_flat3D_thread_worker32, @R[10],
      @_flat3D_thread_worker32, @R[11],
      @_flat3D_thread_worker32, @R[12],
      @_flat3D_thread_worker32, @R[13]
    );
  15:
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8],
      @_flat3D_thread_worker32, @R[9],
      @_flat3D_thread_worker32, @R[10],
      @_flat3D_thread_worker32, @R[11],
      @_flat3D_thread_worker32, @R[12],
      @_flat3D_thread_worker32, @R[13],
      @_flat3D_thread_worker32, @R[14]
    );
  else
    MT_Execute(
      @_flat3D_thread_worker32, @R[0],
      @_flat3D_thread_worker32, @R[1],
      @_flat3D_thread_worker32, @R[2],
      @_flat3D_thread_worker32, @R[3],
      @_flat3D_thread_worker32, @R[4],
      @_flat3D_thread_worker32, @R[5],
      @_flat3D_thread_worker32, @R[6],
      @_flat3D_thread_worker32, @R[7],
      @_flat3D_thread_worker32, @R[8],
      @_flat3D_thread_worker32, @R[9],
      @_flat3D_thread_worker32, @R[10],
      @_flat3D_thread_worker32, @R[11],
      @_flat3D_thread_worker32, @R[12],
      @_flat3D_thread_worker32, @R[13],
      @_flat3D_thread_worker32, @R[14],
      @_flat3D_thread_worker32, @R[15]
    );
  end;

  flatcachesize32 := 0;
end;

//
// Draws the actual span (Normal resolution).
//
procedure R_DrawSpanNormalMT(const fi: pointer);
var
  ds_source32: PLongWordArray;
  ds_y, ds_x1, ds_x2: integer;
  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;
  ds_scale: dsscale_t;
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  destl: PLongWord;
  count: integer;
  i: integer;
  spot: integer;

  r1, g1, b1: byte;
  c: LongWord;
  lfactor: integer;
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
begin
  ds_source32 := Pflatrenderinfo32_t(fi).ds_source32;
  ds_y := Pflatrenderinfo32_t(fi).ds_y;
  ds_x1 := Pflatrenderinfo32_t(fi).ds_x1;
  ds_x2 := Pflatrenderinfo32_t(fi).ds_x2;
  ds_xfrac := Pflatrenderinfo32_t(fi).ds_xfrac;
  ds_yfrac := Pflatrenderinfo32_t(fi).ds_yfrac;
  ds_xstep := Pflatrenderinfo32_t(fi).ds_xstep;
  ds_ystep := Pflatrenderinfo32_t(fi).ds_ystep;
  ds_scale := Pflatrenderinfo32_t(fi).ds_scale;

  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);

  count := ds_x2 - ds_x1;

  lfactor := Pflatrenderinfo32_t(fi).ds_lightlevel;

  if lfactor >= 0 then // Use hi detail lightlevel
  begin
    R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
    {$UNDEF RIPPLE}
    {$UNDEF INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
  else // Use inversecolormap
  begin
    {$UNDEF RIPPLE}
    {$DEFINE INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
end;

procedure R_DrawSpanNormal_RippleMT(const fi: pointer);
var
  ds_source32: PLongWordArray;
  ds_y, ds_x1, ds_x2: integer;
  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;
  ds_scale: dsscale_t;
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  destl: PLongWord;
  count: integer;
  i: integer;
  spot: integer;

  r1, g1, b1: byte;
  c: LongWord;
  lfactor: integer;
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
  rpl: PIntegerArray;
begin
  ds_source32 := Pflatrenderinfo32_t(fi).ds_source32;
  ds_y := Pflatrenderinfo32_t(fi).ds_y;
  ds_x1 := Pflatrenderinfo32_t(fi).ds_x1;
  ds_x2 := Pflatrenderinfo32_t(fi).ds_x2;
  ds_xfrac := Pflatrenderinfo32_t(fi).ds_xfrac;
  ds_yfrac := Pflatrenderinfo32_t(fi).ds_yfrac;
  ds_xstep := Pflatrenderinfo32_t(fi).ds_xstep;
  ds_ystep := Pflatrenderinfo32_t(fi).ds_ystep;
  ds_scale := Pflatrenderinfo32_t(fi).ds_scale;

  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;

  rpl := Pflatrenderinfo32_t(fi).ds_ripple;
  lfactor := Pflatrenderinfo32_t(fi).ds_lightlevel;
  if lfactor >= 0 then // Use hi detail lightlevel
  begin
    R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
    {$DEFINE RIPPLE}
    {$UNDEF INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
  else // Use inversecolormap
  begin
    {$DEFINE RIPPLE}
    {$DEFINE INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end;
end;

end.

