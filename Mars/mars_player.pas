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
//  Player related stuff.
//  Bobbing POV/weapon, movement.
//  Pending weapon.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_player;

interface

uses
  d_player;

procedure MARS_PlayerThink(player: Pplayer_t);

implementation

uses
  mars_sounds,
  m_fixed,
  p_map,
  p_mobj_h,
  p_tick,
  r_defs,
  s_sound;

procedure MARS_PlayerThink(player: Pplayer_t);
var
  needsjetsound: boolean;
begin
  if player.mo = nil then
    exit;

  if player.mo.player = player then
  begin
    // JVAL: For underwater
    if Psubsector_t(player.mo.subsector).sector.renderflags and SRF_UNDERWATER <> 0 then
      player.underwatertics := player.underwatertics + LONGTICS_FACTOR
    else
      player.underwatertics := 0;
  end;

  // JVAL: MARS - Retrieve Linetarget
  P_AimLineAttack(player.mo, player.mo.angle, 16 * 64 * FRACUNIT);
  if (player.plinetarget = nil) and (linetarget <> nil) then
    player.pcrosstic := leveltime;
  player.plinetarget := linetarget;

  // JVAL: MARS - Jet sound
  player.jetpacksoundorg.x := player.mo.x;
  player.jetpacksoundorg.y := player.mo.y;
  player.jetpacksoundorg.z := player.mo.z;
  needsjetsound := (player.mo.z > player.mo.floorz) and (player.mo.flags4_ex and MF4_EX_FLY <> 0);
  if needsjetsound then
  begin
    if player.jetpacksoundtic <= leveltime then
    begin
      player.jetpacksoundtic := leveltime + S_MARSSoundDuration(Ord(snd_JET));
      MARS_StartSound(@player.jetpacksoundorg, snd_JET);
    end;
  end
  else
  begin
    if player.jetpacksoundtic > leveltime then
    begin
      S_StopSound(@player.jetpacksoundorg);
    end;
  end;

  if player.mo.z <= player.mo.floorz then
    if player.jetpacksoundtic <= leveltime then
    begin
      player.mo.flags4_ex := player.mo.flags4_ex and not MF4_EX_FLY;
      player.mo.flags := player.mo.flags and not MF_NOGRAVITY;
    end;
end;

end.
