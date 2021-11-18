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
//  Custom gravity
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_gravity;

interface

uses
  m_fixed,
  p_local,
  p_mobj_h,
  r_defs;

function P_GetMobjGravity(const mo: Pmobj_t): fixed_t;

function P_GetSectorGravity(const sec: Psector_t): fixed_t;

implementation

uses
  doomdef,
  g_game;

function P_GetMobjGravity(const mo: Pmobj_t): fixed_t;
var
  sec: Psector_t;
begin
  sec := Psubsector_t(mo.subsector).sector;
  if (mo.flags and MF_DROPPED <> 0) and (sec.renderflags and SRF_UNDERWATER <> 0) then
    result := mo.gravity div 2
  else
    result := FixedMul(sec.gravity, mo.gravity);
end;

function P_GetSectorGravity(const sec: Psector_t): fixed_t;
begin
  if G_PlayingEngineVersion < VERSION204 then
    result := GRAVITY
  else
    result := sec.gravity;
end;

end.
