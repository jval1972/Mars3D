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
//  Ripple effects for flats
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit r_ripple;

interface

uses
  d_delphi;
  
type
  ripple_t = array[0..31, 0..127] of integer;
  Pripple_t = ^ripple_t;

var
  r_defripple: ripple_t;
  ds_ripple: PIntegerArray = nil;
  curripple: PIntegerArray = nil;

procedure R_InitRippleEffects;

implementation

uses
  m_fixed;

procedure R_InitDefaultRipple;
var
  i: integer;
  tic: integer;
  factor: Double;
begin
  factor := 4.0 * FRACUNIT;
  for i := 0 to 127 do
    for tic := 0 to 31 do
    begin
      r_defripple[tic, i] := LongWord(round(factor * sin(2 * pi * (i / 128 + tic / 32))));
    end;
end;

procedure R_InitRippleEffects;
begin
  R_InitDefaultRipple;
end;

end.
