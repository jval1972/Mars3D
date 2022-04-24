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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit r_trans8;

// Description
// Transparency for 8 bit color modes

interface

uses
  d_delphi,
  m_fixed;

//==============================================================================
//
// R_InitTransparency8Tables
//
//==============================================================================
procedure R_InitTransparency8Tables;

//==============================================================================
//
// R_FreeTransparency8Tables
//
//==============================================================================
procedure R_FreeTransparency8Tables;

type
  trans8table_t = packed array[0..$FFFF] of byte;
  Ptrans8table_t = ^trans8table_t;

const
  NUMTRANS8TABLES = 8; // Actual tables are NUMTRANS8TABLES + 1

var
  trans8tablescalced: boolean = false;
  trans8tables: array[0..NUMTRANS8TABLES] of Ptrans8table_t;
  additive8tables: array[0..NUMTRANS8TABLES] of Ptrans8table_t;
  subtractive8tables: array[0..NUMTRANS8TABLES] of Ptrans8table_t;
  averagetrans8table: Ptrans8table_t = nil;
  curtrans8table: Ptrans8table_t = nil;
  curadd8table: Ptrans8table_t = nil;
  cursubtract8table: Ptrans8table_t = nil;

//==============================================================================
//
// R_GetTransparency8table
//
//==============================================================================
function R_GetTransparency8table(const factor: fixed_t = FRACUNIT div 2): Ptrans8table_t;

//==============================================================================
//
// R_GetAdditive8table
//
//==============================================================================
function R_GetAdditive8table(const factor: fixed_t = FRACUNIT div 2): Ptrans8table_t;

//==============================================================================
//
// R_GetSubtractive8table
//
//==============================================================================
function R_GetSubtractive8table(const factor: fixed_t = FRACUNIT div 2): Ptrans8table_t;

//==============================================================================
//
// R_FastApproxColorIndex
//
//==============================================================================
function R_FastApproxColorIndex(const c: LongWord): byte; overload;

//==============================================================================
//
// R_FastApproxColorIndex
//
//==============================================================================
function R_FastApproxColorIndex(const r, g, b: byte): byte; overload;

const
  FASTTABLESHIFT = 3;
  FASTTABLEBIT = 1 shl FASTTABLESHIFT;
  FASTTABLECHANNEL = 256 div FASTTABLEBIT;
  FASTTABLESIZE = FASTTABLECHANNEL * FASTTABLECHANNEL * FASTTABLECHANNEL;

type
  approxcolorindexarray_t = array[0..FASTTABLESIZE - 1] of byte;
  Papproxcolorindexarray_t = ^approxcolorindexarray_t;

var
  approxcolorindexarray: Papproxcolorindexarray_t;

//==============================================================================
//
// R_Calc8bitTables
//
//==============================================================================
procedure R_Calc8bitTables;

implementation

uses
  i_system,
  mt_utils,
  r_hires,
  v_video,
  w_wad,
  z_zone;

type
  approxcolorstructitem_t = record
    hash: array[0..GAMMASIZE - 1] of LongWord;
    palette: array[0..GAMMASIZE - 1] of array[0..255] of LongWord;
    table: array[0..GAMMASIZE - 1] of approxcolorindexarray_t;
  end;
  Papproxcolorstructitem_t = ^approxcolorstructitem_t;
  approxcolorstructitem_tArray = array[0..$FF] of approxcolorstructitem_t;
  Papproxcolorstructitem_tArray = ^approxcolorstructitem_tArray;

var
  numapproxcolorstructitem: integer = 0;
  approxcolorstruct: Papproxcolorstructitem_tArray;
  currpalettehash: LongWord;

//==============================================================================
//
// R_GetPaletteHash
//
//==============================================================================
function R_GetPaletteHash(const p: PLongWordArray): LongWord;
var
  i: integer;
begin
  result := p[0];
  for i := 1 to 255 do
    result := result xor (p[i] and $FFFFFF);
end;

//==============================================================================
//
// R_ExpandPalette
//
//==============================================================================
procedure R_ExpandPalette(const inpal: PByteArray; const outpal: PLongWordArray; const gamma: integer);
var
  dest: PLongWord;
  src: PByteArray;
begin
  src := @inpal[0];
  dest := @outpal[0];
  while src <> @inpal[256 * 3] do
  begin
    dest^ := (LongWord(gammatable[gamma][src[0]]) shl 16) or
             (LongWord(gammatable[gamma][src[1]]) shl 8) or
             (LongWord(gammatable[gamma][src[2]]));
    inc(dest);
    src := @src[3];
  end;
end;

//==============================================================================
//
// R_MakeTrans8_thr
//
//==============================================================================
function R_MakeTrans8_thr(pal: PByteArray): Integer; stdcall;
var
  palL: array[0..255] of LongWord; // Longword palette indexes
  i, j, k: integer;
  factor: fixed_t;
  c1: LongWord;
  c: LongWord;
  ptrans8: PByte;
begin
  R_ExpandPalette(pal, @palL, 0);

  for i := 0 to NUMTRANS8TABLES do
  begin
    trans8tables[i] := malloc(SizeOf(trans8table_t));
    ptrans8 := PByte(trans8tables[i]);
    factor := i * (FRACUNIT div NUMTRANS8TABLES);
    for j := 0 to 255 do
    begin
      c1 := palL[j];
      for k := 0 to 255 do
      begin
        c := R_ColorAverage(palL[k], c1, factor);
        ptrans8^ := V_FindAproxColorIndex(@palL, c) and $FF;
        inc(ptrans8);
      end;
    end;
  end;

  averagetrans8table := trans8tables[NUMTRANS8TABLES div 2];

  Result := 0;
end;

//==============================================================================
//
// R_MakeAdd8_thr
//
//==============================================================================
function R_MakeAdd8_thr(pal: PByteArray): Integer; stdcall;
var
  palL: array[0..255] of LongWord; // Longword palette indexes
  i, j, k: integer;
  c1: LongWord;
  c: LongWord;
  ptrans8: PByte;
  r, g, b: LongWord;
begin
  R_ExpandPalette(pal, @palL, 0);

  for i := 0 to NUMTRANS8TABLES do
  begin
    additive8tables[i] := malloc(SizeOf(trans8table_t));
    ptrans8 := PByte(additive8tables[i]);
    for j := 0 to 255 do
    begin
      c1 := palL[j];
      r := ((c1 and $FF) * LongWord(i) * (FRACUNIT div NUMTRANS8TABLES)) div FRACUNIT;
      if r > 255 then
        r := 255;
      g := (((c1 shr 8) and $FF) * LongWord(i) * (FRACUNIT div NUMTRANS8TABLES)) div FRACUNIT;
      if g > 255 then
        g := 255;
      b := (((c1 shr 16) and $FF) * LongWord(i) * (FRACUNIT div NUMTRANS8TABLES)) div FRACUNIT;
      if b > 255 then
        b := 255;
      c1 := r + g shl 8 + b shl 16;
      for k := 0 to 255 do
      begin
        c := R_ColorAdd(palL[k], c1);
        if (i = 0) or (i = 8) then
          ptrans8^ := V_FindAproxColorIndex(@palL, c) and $FF
        else
          ptrans8^ := V_FindAproxColorIndexExcluding(@palL, c, 0, 255, k) and $FF;
        inc(ptrans8);
      end;
    end;
  end;

  Result := 0;
end;

//==============================================================================
//
// R_MakeSub8_thr
//
//==============================================================================
function R_MakeSub8_thr(pal: PByteArray): Integer; stdcall;
var
  palL: array[0..255] of LongWord; // Longword palette indexes
  i, j, k: integer;
  c1: LongWord;
  c: LongWord;
  ptrans8: PByte;
  r, g, b: LongWord;
begin
  R_ExpandPalette(pal, @palL, 0);

  for i := 0 to NUMTRANS8TABLES do
  begin
    subtractive8tables[i] := malloc(SizeOf(trans8table_t));
    ptrans8 := PByte(subtractive8tables[i]);
    for j := 0 to 255 do
    begin
      c1 := palL[j];
      r := ((c1 and $FF) * LongWord(i) * (FRACUNIT div NUMTRANS8TABLES)) div FRACUNIT;
      if r > 255 then
        r := 255;
      g := (((c1 shr 8) and $FF) * LongWord(i) * (FRACUNIT div NUMTRANS8TABLES)) div FRACUNIT;
      if g > 255 then
        g := 255;
      b := (((c1 shr 16) and $FF) * LongWord(i) * (FRACUNIT div NUMTRANS8TABLES)) div FRACUNIT;
      if b > 255 then
        b := 255;
      c1 := r + g shl 8 + b shl 16;
      for k := 0 to 255 do
      begin
        c := R_ColorSubtract(palL[k], c1);
        if (i = 0) or (i = 8) then
          ptrans8^ := V_FindAproxColorIndex(@palL, c) and $FF
        else
          ptrans8^ := V_FindAproxColorIndexExcluding(@palL, c, 0, 255, k) and $FF;
        inc(ptrans8);
      end;
    end;
  end;

  Result := 0;
end;

type
  approxparms_t = record
    pal: PByteArray;
    id: integer;
  end;
  Papproxparms_t = ^approxparms_t;

//==============================================================================
//
// R_MakeApprox_thr
//
//==============================================================================
function R_MakeApprox_thr(parms: Papproxparms_t): Integer; stdcall;
var
  pal: PByteArray;
  i: integer;
  gamma: integer;
  ptrans8: PByte;
  r, g, b: LongWord;
  palL: PLongWordArray;
begin
  pal := parms.pal;
  gamma := parms.id;
  for i := 0 to numapproxcolorstructitem - 1 do
  begin
    palL := @approxcolorstruct[i].palette[gamma];
    R_ExpandPalette(@pal[i * 768], palL, gamma);
    approxcolorstruct[i].hash[gamma] := R_GetPaletteHash(palL);

    ptrans8 := @approxcolorstruct[i].table[gamma];
    for r := 0 to FASTTABLECHANNEL - 1 do
      for g := 0 to FASTTABLECHANNEL - 1 do
        for b := 0 to FASTTABLECHANNEL - 1 do
        begin
          ptrans8^ := V_FindAproxColorIndex(palL,
                          r shl (16 + FASTTABLESHIFT) + g shl (8 + FASTTABLESHIFT) + b shl FASTTABLESHIFT +
                          // extra parenthesis help the compiler to precalc the whole expresion below
                          (((1 shl FASTTABLESHIFT) shr 1) shl 16 + ((1 shl FASTTABLESHIFT) shr 1) shl 8 + ((1 shl FASTTABLESHIFT) shr 1))
                    ) and $FF;
          inc(ptrans8);
        end;
  end;

  Result := 0;
end;

//==============================================================================
//
// R_InitTransparency8Tables
//
//==============================================================================
procedure R_InitTransparency8Tables;
var
  pal: PByteArray; // Palette lump data
  lump: integer;
  r1, r2, r3, r4, r5: approxparms_t;
begin
  if trans8tablescalced then
    exit;

// Expand WAD palette to longword values
  lump := W_GetNumForName('PLAYPAL');
  numapproxcolorstructitem := W_LumpLength(lump) div 768;
  approxcolorstruct := mallocz(numapproxcolorstructitem * SizeOf(approxcolorstructitem_t));

  pal := W_CacheLumpNum(lump, PU_STATIC);
  r1.pal := pal;
  r1.id := 0;
  r2.pal := pal;
  r2.id := 1;
  r3.pal := pal;
  r3.id := 2;
  r4.pal := pal;
  r4.id := 3;
  r5.pal := pal;
  r5.id := 4;

  if usemultithread then
    MT_Execute(
      @R_MakeTrans8_thr, pal,
      @R_MakeAdd8_thr, pal,
      @R_MakeSub8_thr, pal,
      @R_MakeApprox_thr, @r1,
      @R_MakeApprox_thr, @r2,
      @R_MakeApprox_thr, @r3,
      @R_MakeApprox_thr, @r4,
      @R_MakeApprox_thr, @r5
    )
  else
  begin
    R_MakeTrans8_thr(pal);
    R_MakeAdd8_thr(pal);
    R_MakeSub8_thr(pal);
    R_MakeApprox_thr(@r1);
    R_MakeApprox_thr(@r2);
    R_MakeApprox_thr(@r3);
    R_MakeApprox_thr(@r4);
    R_MakeApprox_thr(@r5);
  end;

  approxcolorindexarray := @approxcolorstruct[0].table[0];
  currpalettehash := approxcolorstruct[0].hash[0];

  Z_ChangeTag(pal, PU_CACHE);
  trans8tablescalced := true;
end;

//==============================================================================
//
// R_FreeTransparency8Tables
//
//==============================================================================
procedure R_FreeTransparency8Tables;
var
  i: integer;
begin
  for i := 0 to NUMTRANS8TABLES do
  begin
    memfree(pointer(trans8tables[i]), SizeOf(trans8table_t));
    memfree(pointer(additive8tables[i]), SizeOf(trans8table_t));
    memfree(pointer(subtractive8tables[i]), SizeOf(trans8table_t));
  end;

  memfree(pointer(approxcolorstruct), numapproxcolorstructitem * SizeOf(approxcolorstructitem_t));

  averagetrans8table := nil;

  trans8tablescalced := false;

end;

//==============================================================================
//
// R_GetTransparency8table
//
//==============================================================================
function R_GetTransparency8table(const factor: fixed_t = FRACUNIT div 2): Ptrans8table_t;
var
  idx: integer;
begin
  idx := (factor * NUMTRANS8TABLES) div FRACUNIT;
  if idx < 0 then
    result := trans8tables[0]
  else if idx > NUMTRANS8TABLES then
    result := trans8tables[NUMTRANS8TABLES]
  else
    result := trans8tables[idx];
end;

//==============================================================================
//
// R_GetAdditive8table
//
//==============================================================================
function R_GetAdditive8table(const factor: fixed_t = FRACUNIT div 2): Ptrans8table_t;
var
  idx: integer;
begin
  idx := (factor * NUMTRANS8TABLES) div FRACUNIT;
  if idx < 0 then
    result := additive8tables[0]
  else if idx > NUMTRANS8TABLES then
    result := additive8tables[NUMTRANS8TABLES]
  else
    result := additive8tables[idx];
end;

//==============================================================================
//
// R_GetSubtractive8table
//
//==============================================================================
function R_GetSubtractive8table(const factor: fixed_t = FRACUNIT div 2): Ptrans8table_t;
var
  idx: integer;
begin
  idx := (factor * NUMTRANS8TABLES) div FRACUNIT;
  if idx < 0 then
    result := subtractive8tables[0]
  else if idx > NUMTRANS8TABLES then
    result := subtractive8tables[NUMTRANS8TABLES]
  else
    result := subtractive8tables[idx];
end;

//==============================================================================
//
// R_FastApproxColorIndex
//
//==============================================================================
function R_FastApproxColorIndex(const c: LongWord): byte; overload;
var
  r, g, b: LongWord;
begin
  b := (c shr FASTTABLESHIFT) and $FF;
  g := (c shr (FASTTABLESHIFT + 8)) and $FF;
  r := (c shr (FASTTABLESHIFT + 16)) and $FF;
  result := approxcolorindexarray[r shl (16 - FASTTABLESHIFT - FASTTABLESHIFT) + g shl (8 - FASTTABLESHIFT) + b];
end;

//==============================================================================
//
// R_FastApproxColorIndex
//
//==============================================================================
function R_FastApproxColorIndex(const r, g, b: byte): byte; overload;
var
  r1, g1, b1: LongWord;
begin
  b1 := b shr FASTTABLESHIFT;
  g1 := g shr FASTTABLESHIFT;
  r1 := r shr FASTTABLESHIFT;
  result := approxcolorindexarray[r1 shl (16 - FASTTABLESHIFT - FASTTABLESHIFT) + g1 shl (8 - FASTTABLESHIFT) + b1];
end;

var
  last8pal: array[0..255] of LongWord;
  overflowapproxcolorindexarray: approxcolorindexarray_t;

//==============================================================================
//
// R_PaletteEquals
//
//==============================================================================
function R_PaletteEquals(const p1, p2: PLongWordArray): Boolean;
var
  i: integer;
begin
  for i := 0 to 255 do
    if p1[i] <> p2[i] then
    begin
      Result := False;
      Exit;
    end;

  Result := True;
end;

//==============================================================================
//
// R_Calc8bitTables
//
//==============================================================================
procedure R_Calc8bitTables;
var
  i: integer;
  ptrans8: PByte;
  r, g, b: LongWord;
  pal: PLongWordArray;
  changed: integer;
begin
  if videomode = vm32bit then
    exit;

  {$IFDEF DOOM_OR_STRIFE}
  pal := @cvideopal;
  {$ELSE}
  pal := @curpal;
  {$ENDIF}

  changed := -1;
  for i := 0 to 255 do
    if pal[i] <> last8pal[i] then
    begin
      changed := i;
      break;
    end;

  if changed < 0 then
    exit;

  for i := changed to 255 do
    last8pal[i] := pal[i];

  currpalettehash := R_GetPaletteHash(pal);

  for i := 0 to numapproxcolorstructitem - 1 do
    if currpalettehash = approxcolorstruct[i].hash[usegamma] then
      if R_PaletteEquals(pal, @approxcolorstruct[i].palette[usegamma]) then
      begin
        approxcolorindexarray := @approxcolorstruct[i].table[usegamma];
        exit;
      end;

  approxcolorindexarray := @overflowapproxcolorindexarray;

  ptrans8 := @approxcolorindexarray[0];
  for r := 0 to FASTTABLECHANNEL - 1 do
    for g := 0 to FASTTABLECHANNEL - 1 do
      for b := 0 to FASTTABLECHANNEL - 1 do
      begin
        ptrans8^ := V_FindAproxColorIndex(pal,
                          r shl (16 + FASTTABLESHIFT) + g shl (8 + FASTTABLESHIFT) + b shl FASTTABLESHIFT +
                          // extra parenthesis help the compiler to precalc the whole expresion below
                          (((1 shl FASTTABLESHIFT) shr 1) shl 16 + ((1 shl FASTTABLESHIFT) shr 1) shl 8 + ((1 shl FASTTABLESHIFT) shr 1))
                    ) and $FF;
        inc(ptrans8);
      end;
end;

end.

