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
//  DESCRIPTION:
//    Briefing screen
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_briefing;

interface

uses
  d_event;

procedure MARS_InitBriefing;

procedure MARS_ShutDownBriefing;

function MARS_BriefingResponder(ev: Pevent_t): boolean;

// Called by main loop
procedure MARS_Briefing_Ticker;

// Called by main loop,
// draws the briefing screens directly into the screen buffer.
procedure MARS_Briefing_Drawer;

// Setup the briefing screens.
procedure MARS_Briefing_Start;

var
  showbriefingscreen: boolean = true;

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  g_game,
  p_levelinfo,
  v_data,
  v_video,
  w_wad;

const
  MAX_BRIEFING_SCREENS = 100;

var
  br_lumps: TDNumberList;
  br_tic: integer;

procedure MARS_InitBriefing;
begin
  br_lumps := TDNumberList.Create;
end;

procedure MARS_ShutDownBriefing;
begin
  br_lumps.Free;
end;

var
  br_key_down: boolean;

procedure MARS_BriefingAdvance;
begin
  if br_lumps.Count > 0 then
    br_lumps.Delete(0);
  if br_lumps.Count = 0 then
    gamestate := GS_LEVEL;
end;

function MARS_BriefingResponder(ev: Pevent_t): boolean;
begin
  if ev._type <> ev_keydown then
  begin
    if ev._type = ev_keyup then
      br_key_down := false;
    result := false;
    exit;
  end;

  result := true;
  br_key_down := true;

  MARS_BriefingAdvance;
end;

var
  br_music_changed: boolean;

procedure MARS_Briefing_Ticker;
begin
  inc(br_tic);
  if br_tic = 1 then
    if not br_music_changed then
    begin
      P_LevelInfoChangeMusic;
      br_music_changed := true;
    end;

  if not br_key_down then
    br_tic := 0;

  if br_tic >= TICRATE then
  begin
    MARS_BriefingAdvance; // Briefing screens accelerated 
    br_tic := TICRATE - 4;
  end;
end;

procedure MARS_Briefing_Drawer;
begin
  if br_lumps.Count > 0 then
    V_DrawPatchFullScreenTMP320x200(br_lumps.Numbers[0]);
  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

procedure MARS_Briefing_Start;
var
  i: integer;
  pg: string;
  lump: integer;
begin
  br_lumps.Clear;
  // Only for episode 1 briefing screens
  if gameepisode = 1 then
    for i := 0 to MAX_BRIEFING_SCREENS - 1 do
    begin
      sprintf(pg, 'A%d%s', [gamemap, IntToStrZfill(2, i)]);
      lump := W_CheckNumForName(pg);
      if lump >= 0 then
        br_lumps.Add(lump);
    end;
  br_tic := 0;
  br_music_changed := false;
  br_key_down := false;
  if br_lumps.Count = 0 then
    gamestate := GS_LEVEL;
end;

end.
