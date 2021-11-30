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
//  Ceiling aninmation (lowering, crushing, raising)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mn_textwrite;

interface

uses
  r_defs;

type
  menupos_t = record
    x, y: integer;
  end;

const
  _MA_LEFT = 0;
  _MA_RIGHT = 1;
  _MA_CENTER = 2;
  _MALIGN_MASK = 3;
  _MC_UPPER = 4;
  _MC_LOWER = 8;
  _MC_NOCASE = 0;
  _MCASE_MASK = 12;

function M_WriteText(x, y: integer; const str: string; const flags: integer;
  const font: Ppatch_tPArray; const shadefont: Ppatch_tPArray = nil): menupos_t;

function M_StringWidth(const str: string; const flags: integer; const font: Ppatch_tPArray): integer;

function M_StringHeight(const str: string; const font: Ppatch_tPArray): integer;

implementation

uses
  d_delphi,
  hu_stuff,
  v_data,
  v_video;

type
  casefunc_t = function (ch: Char): Char;

function nocase(ch: Char): Char;
begin
  Result := ch;
end;

//
// Write a string using the font
//
function M_WriteText(x, y: integer; const str: string; const flags: integer;
  const font: Ppatch_tPArray; const shadefont: Ppatch_tPArray = nil): menupos_t;
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
  align: integer;
  ccase: integer;
  casefunc: casefunc_t;
begin
  len := Length(str);
  if len = 0 then
  begin
    result.x := x;
    result.y := y;
    exit;
  end;

  ch := 1;
  align := flags and _MALIGN_MASK;
  case align of
    _MA_LEFT: cx := x;
    _MA_RIGHT: cx := x - M_StringWidth(str, flags, font);
  else
    cx := x - M_StringWidth(str, flags, font) div 2;
  end;
  cy := y;

  ccase := flags and _MCASE_MASK;
  case ccase of
    _MC_UPPER: casefunc := @toupper;
    _MC_LOWER: casefunc := @tolower;
  else
    casefunc := @nocase;
  end;

  while true do
  begin
    if ch > len then
      break;

    c := Ord(str[ch]);
    inc(ch);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + font[0].height + 2;
      continue;
    end;

    c := Ord(casefunc(Chr(c))) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
    begin
      cx := cx + 4;
      continue;
    end;

    w := font[c].width;
    if (cx + w + 1) > 320 then
      break;
    if shadefont <> nil then
      V_DrawPatch(cx + 1, cy + 1, SCN_TMP, shadefont[c], false);
    V_DrawPatch(cx, cy, SCN_TMP, font[c], false);
    cx := cx + w;
  end;

  result.x := cx;
  result.y := cy;
end;

//
// Find string width
//
function M_StringWidth(const str: string; const flags: integer; const font: Ppatch_tPArray): integer;
var
  i: integer;
  c: integer;
  ccase: integer;
  casefunc: casefunc_t;
begin
  ccase := flags and _MCASE_MASK;
  case ccase of
    _MC_UPPER: casefunc := @toupper;
    _MC_LOWER: casefunc := @tolower;
  else
    casefunc := @nocase;
  end;

  result := 0;
  for i := 1 to Length(str) do
  begin
    c := Ord(casefunc(str[i])) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
      result := result + 4
    else
      result := result + font[c].width;
  end;
end;

//
// Find string height from hu_fontY chars
//
function M_StringHeight(const str: string; const font: Ppatch_tPArray): integer;
var
  i: integer;
  height: integer;
begin
  height := font[0].height;

  result := height;
  for i := 1 to Length(str) do
    if str[i] = #13 then
      result := result + height;
end;

end.
