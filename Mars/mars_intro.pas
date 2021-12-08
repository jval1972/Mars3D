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
//  Intro animations
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_intro;

interface

uses
  d_event;

function MARS_IntroResponder(ev: Pevent_t): boolean;

// Called by main loop
procedure MARS_Intro_Ticker;

// Called by main loop,
procedure MARS_Intro_Drawer;

// Setup the intro animations
procedure MARS_Intro_Start;

implementation

uses
  doomdef,
  d_main,
  flc_lib,
  g_game,
  mars_files,
  r_hires,
  sounds,
  s_sound,
  t_draw,
  t_main,
  v_data,
  v_video;

var
  oldvideomode: videomode_t;
  intro_stage: integer;
  last_tic: integer;
  fli: TFLIFile;
  intro_finished: boolean;

const
  NUM_INTRO_ANIMS = 3;

  FLI_INTRO_ANIMS: array[0..NUM_INTRO_ANIMS - 1] of string = (
    '3DMARK.FLC',
    'MARS.FLC',
    'TIME.FLC'
  );

procedure MARS_IntroAdvance;
begin
  Inc(intro_stage);
  last_tic := gametic;
  if intro_stage = NUM_INTRO_ANIMS then
  begin
    videomode := oldvideomode;
    fli.Free;
    intro_finished := true;
    D_StartTitle;
  end
  else
  begin
    fli.FileName := MARS_FindFile(FLI_INTRO_ANIMS[intro_stage]);
    if fli.FileName <> '' then
      if intro_stage in [1, 2] then
        S_StartMusic(Ord(mus_e1m5));
  end;
end;

function MARS_IntroResponder(ev: Pevent_t): boolean;
begin
  if ev._type = ev_keydown then
    if gametic > last_tic + 10 then
      MARS_IntroAdvance;
  Result := True;
end;

// Called by main loop
procedure MARS_Intro_Ticker;
begin
  if gametic and 1 <> 0 then
  begin
    if fli.Frame < fli.FrameCount - 1 then
      fli.NextFrame
    else
      MARS_IntroAdvance;
  end;
end;

// Called by main loop,
procedure MARS_Intro_Drawer;
var
  t: PTexture;
  imgdata: Pfliscreen32_t;
begin
  if intro_finished then
    exit;

  t := new(PTexture, Create);
  t.SetWidth(FLI_WIDTH);
  t.SetHeight(FLI_HEIGHT);
  t.SetBytesPerPixel(4);
  imgdata := t.GetImage;
  fli.GetFrameImage32(fli.Frame, imgdata);
  T_DrawFullScreenPatch(t, screen32);
  dispose(t, Destroy);
  V_FullScreenStretch;
end;

// Setup the intro animations
procedure MARS_Intro_Start;
begin
  gameaction := ga_nothing;
  gamestate := GS_INTRO;
  oldvideomode := videomode;
  videomode := vm32bit;
  intro_stage := 0;
  last_tic := gametic;
  fli := TFLIFile.Create;
  fli.FileName := MARS_FindFile(FLI_INTRO_ANIMS[intro_stage]);
  if fli.FileName <> '' then
    S_StartMusic(Ord(mus_introa));
  intro_finished := false;
end;

end.
