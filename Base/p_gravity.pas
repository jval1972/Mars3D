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
  p_mobj_h,
  r_defs;

//==============================================================================
//
// P_GetMobjGravity
//
//==============================================================================
function P_GetMobjGravity(const mo: Pmobj_t): fixed_t;

//==============================================================================
//
// P_GetSectorGravity
//
//==============================================================================
function P_GetSectorGravity(const sec: Psector_t): fixed_t;

implementation

uses
  g_game;

//==============================================================================
//
// P_GetMobjGravity
//
//==============================================================================
function P_GetMobjGravity(const mo: Pmobj_t): fixed_t;
var
  sec: Psector_t;
begin
  sec := Psubsector_t(mo.subsector).sector;
  if (sec.renderflags and SRF_UNDERWATER <> 0) and (mo.flags4_ex and MF4_EX_FORCEUNDERWATERGRAVITY <> 0) then
    result := mo.gravity div 2
  else if (sec.renderflags and SRF_UNDERWATER <> 0) and (mo.flags4_ex and MF4_EX_FORCELOWUNDERWATERGRAVITY <> 0) then
    result := mo.gravity div 4
  else if (mo.flags and MF_DROPPED <> 0) and (sec.renderflags and SRF_UNDERWATER <> 0) then
    result := mo.gravity div 2
  else
    result := FixedMul(sec.gravity, mo.gravity);
end;

//==============================================================================
//
// P_GetSectorGravity
//
//==============================================================================
function P_GetSectorGravity(const sec: Psector_t): fixed_t;
begin
  result := sec.gravity;
end;

end.
