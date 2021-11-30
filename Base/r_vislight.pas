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
//  vislight_t struct
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit r_vislight;

interface

uses
  m_fixed;

type
  Pvislight_t = ^vislight_t;
  vislight_t = record
    x1: integer;
    x2: integer;

    // for line side calculation
    gx: fixed_t;
    gy: fixed_t;

    // global bottom / top for silhouette clipping
    gz: fixed_t;

    // horizontal position of x1
    startfrac: fixed_t;

    scale: fixed_t;
    xiscale: fixed_t;

    dbmin: LongWord;
    dbmax: LongWord;
    dbdmin: LongWord;
    dbdmax: LongWord;

    texturemid: fixed_t;

    color32: LongWord;
  end;

const
  MAXVISLIGHTS = 1024;

var
  vislight_p: integer = 0;
  vislights: array[0..MAXVISLIGHTS - 1] of vislight_t;

function R_NewVisLight: Pvislight_t;

implementation

function R_NewVisLight: Pvislight_t;
begin
  if vislight_p = MAXVISLIGHTS then
    result := @vislights[MAXVISLIGHTS - 1]
  else
  begin
    result := @vislights[vislight_p];
    inc(vislight_p);
  end;
end;

end.
 
