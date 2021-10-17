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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

//
// JVAL
//
// Simple shadows using existing lightmap texture
//

unit gl_shadows;

interface

uses
  m_fixed,
  r_dynlights;

var
  gl_drawshadows: boolean = true;

procedure gld_InitDynamicShadows;

procedure gld_DynamicShadowsDone;

function gld_GetDynamicShadow(const radious: integer): PGLDRenderLight;

const
  SHADOWSDRAWRANGE = 2048 * FRACUNIT;

implementation

uses
  d_delphi,
  gl_defs;

const
  SHADOWSTEP = 16;
  NUMSHADOWS = 16;

var
  shadows: array[0..NUMSHADOWS - 1] of GLDRenderLight;

procedure gld_InitDynamicShadows;
var
  i: integer;
begin
  ZeroMemory(@shadows, SizeOf(shadows));
  for i := 0 to NUMSHADOWS - 1 do
  begin
    shadows[i].r := 0.0;
    shadows[i].g := 0.0;
    shadows[i].b := 0.0;
    shadows[i].radius := (1 + i) * SHADOWSTEP / MAP_COEFF;
    shadows[i].x := 0.0;
    shadows[i].y := 0.0;
    shadows[i].z := 0.0;
    shadows[i].shadow := true;
  end;
end;

procedure gld_DynamicShadowsDone;
begin
end;

function gld_GetDynamicShadow(const radious: integer): PGLDRenderLight;
var
  idx: integer;
begin
  idx := radious div SHADOWSTEP;
  if idx < 0 then
    idx := 0
  else if idx >= NUMSHADOWS then
    idx := NUMSHADOWS - 1;
  result := @shadows[idx];
end;

end.
