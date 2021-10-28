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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_weapons;

interface

uses
  d_player,
  p_pspr_h;

procedure A_BulletCartridgeDrop(player: Pplayer_t; psp: Ppspdef_t);

implementation

uses
  info_common,
  m_fixed,
  tables,
  p_mobj,
  p_mobj_h,
  p_local;

var
  MT_BULLETCARTRIDGE: integer = -2;

procedure A_BulletCartridgeDrop(player: Pplayer_t; psp: Ppspdef_t);
var
  x, y, z: fixed_t;
  ang: angle_t;
  mo: Pmobj_t;
begin
  if MT_BULLETCARTRIDGE = -2 then
    MT_BULLETCARTRIDGE := Info_GetMobjNumForName('MT_BULLETCARTRIDGE');

  if MT_BULLETCARTRIDGE < 0 then
    Exit;

  x := player.mo.x;
  y := player.mo.y;
  z := player.mo.z + PVIEWHEIGHT;

  ang := player.mo.angle;
  x := x + finecosine[ang shr ANGLETOFINESHIFT] * 24;
  y := y + finesine[ang shr ANGLETOFINESHIFT] * 24;

  mo := P_SpawnMobj(x, y, z, MT_BULLETCARTRIDGE);
  ang := ang + ANG90;
  mo.angle := ang;

  mo.momx := player.mo.momx + finecosine[ang shr ANGLETOFINESHIFT] * 4;
  mo.momy := player.mo.momy + finesine[ang shr ANGLETOFINESHIFT] * 4;
  mo.momz := player.mo.momz + 3 * FRACUNIT;
end;

end.
