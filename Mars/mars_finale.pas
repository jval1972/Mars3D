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
//  DESCRIPTION:
//    Game completion, final screen animation.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_finale;

interface

uses
  d_event;

//==============================================================================
//
// MARS_Finale_Responder
//
//==============================================================================
function MARS_Finale_Responder(ev: Pevent_t): boolean;

{ Called by main loop. }

//==============================================================================
//
// MARS_Finale_Ticker
//
//==============================================================================
procedure MARS_Finale_Ticker;

{ Called by main loop. }

//==============================================================================
//
// MARS_Finale_Drawer
//
//==============================================================================
procedure MARS_Finale_Drawer;

//==============================================================================
//
// MARS_StartFinale
//
//==============================================================================
procedure MARS_StartFinale;

//==============================================================================
//
// MARS_InitFinale
//
//==============================================================================
procedure MARS_InitFinale;

//==============================================================================
//
// MARS_ShutDownFinale
//
//==============================================================================
procedure MARS_ShutDownFinale;

var
  FINALE_ANIM: string = 'ENDOVER.FLC';

implementation

uses
  d_delphi,
  am_map,
  d_main,
  d_net,
  flc_lib,
  doomdef,
  hu_stuff,
  g_game,
  mars_files,
  r_hires,
  s_sound,
  sounds,
  t_main,
  t_draw,
  v_data,
  v_video,
  w_wad;

var
// Stage of animation:
//  0 = BRIEFING, 1 = ANIMATION, 2 = DRAW TEXT
  finalestage: integer;

const
  TEXTSPEED = 3;
  TEXTWAIT = 250;

const
  MAX_FINALE_SCREENS = 100;

const
  FIN_STAGE_BRIEFING = 0;
  FIN_STAGE_ANIM = 1;
  FIN_STAGE_FINISHED = 2;

var
  {$IFNDEF OPENGL}
  oldvideomode: videomode_t;
  {$ENDIF}
  fin_lumps: TDNumberList;
  fin_tic: integer;
  fin_key_down: boolean;
  last_tic: integer;
  fli: TFLIFile;
  fli_finished: boolean;
  t1, t2: PTexture;

//==============================================================================
//
// MARS_Finale_BlancScreen
//
//==============================================================================
procedure MARS_Finale_BlancScreen;
begin
  {$IFNDEF OPENGL}
  if videomode = vm32bit then
  {$ENDIF}
    ZeroMemory(screen32, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) * SizeOf(LongWord))
  {$IFNDEF OPENGL}
  else
    ZeroMemory(screens[SCN_FG], V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG));
  {$ENDIF}
end;

//==============================================================================
//
// MARS_FinaleAdvance
//
//==============================================================================
procedure MARS_FinaleAdvance;
begin
  fin_tic := gametic;
  if finalestage = FIN_STAGE_BRIEFING then
  begin
    if fin_lumps.Count > 0 then
      fin_lumps.Delete(0);
    if fin_lumps.Count = 0 then
    begin
      last_tic := gametic;
      fli_finished := false;
      fli.FileName := MARS_FindFile(FINALE_ANIM);
      Inc(finalestage);
      {$IFNDEF OPENGL}
      oldvideomode := videomode;
      videomode := vm32bit;
      {$ENDIF}
    end;
    exit;
  end
  else if finalestage = FIN_STAGE_ANIM then
  begin
    {$IFNDEF OPENGL}
    videomode := oldvideomode;
    {$ENDIF}
    MARS_Finale_BlancScreen;
    fli_finished := true;
    finalestage := FIN_STAGE_FINISHED;
    D_StartTitle;
  end
end;

//==============================================================================
//
// MARS_StartFinale
//
//==============================================================================
procedure MARS_StartFinale;
var
  i: integer;
  lump: integer;
  pg: string;
begin
  gameaction := ga_nothing;
  gamestate := GS_FINALE;
  viewactive := false;
  amstate := am_inactive;
  fin_key_down := false;
  last_tic := gametic;

  fin_lumps.Clear;

  S_ChangeMusic(Ord(mus_victor), true);

  if gameepisode = 1 then
    for i := 0 to MAX_FINALE_SCREENS - 1 do
    begin
      sprintf(pg, 'B%d%s', [gamemap, IntToStrZfill(2, i)]);
      lump := W_CheckNumForName(pg);
      if lump >= 0 then
        fin_lumps.Add(lump);
    end;

  finalestage := FIN_STAGE_BRIEFING;
  if fin_lumps.Count = 0 then
    MARS_FinaleAdvance;
end;

//==============================================================================
//
// MARS_Finale_Responder
//
//==============================================================================
function MARS_Finale_Responder(ev: Pevent_t): boolean;
begin
  if finalestage = FIN_STAGE_BRIEFING then
  begin
    if ev._type <> ev_keydown then
    begin
      if ev._type = ev_keyup then
        fin_key_down := false;
      result := false;
      exit;
    end;

    result := true;
    fin_key_down := true;

    MARS_FinaleAdvance;

    exit;
  end;

  if finalestage = FIN_STAGE_ANIM then
  begin
    if ev._type = ev_keydown then
      if gametic > fin_tic + 10 then
        MARS_FinaleAdvance;

    result := true;

    exit;
  end;

  result := false;
end;

//==============================================================================
//
// MARS_Finale_DrawAnim
//
//==============================================================================
procedure MARS_Finale_DrawAnim;
begin
  if fli_finished then
    exit;

  if firstinterpolation then
    T_DrawFullScreenPatch(t1, screen32)
  else
    T_DrawFullScreenPatch(t2, screen32);

  V_FullScreenStretch;
end;

//==============================================================================
//
// MARS_Finale_BriefingDrawer
//
//==============================================================================
procedure MARS_Finale_BriefingDrawer;
begin
  if fin_lumps.Count > 0 then
    V_DrawPatchFullScreenTMP320x200(fin_lumps.Numbers[0]);
  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  V_FullScreenStretch;
end;

//==============================================================================
//
// MARS_Finale_Drawer
//
//==============================================================================
procedure MARS_Finale_Drawer;
begin
  case finalestage of
    FIN_STAGE_BRIEFING: MARS_Finale_BriefingDrawer;
    FIN_STAGE_ANIM: MARS_Finale_DrawAnim;
  else
    MARS_Finale_BlancScreen; // ? Mars?
  end;
end;

//==============================================================================
//
// MARS_Finale_Ticker
//
//==============================================================================
procedure MARS_Finale_Ticker;
var
  imgdata: Pfliscreen32_t;
  fli_speed: integer;
  fli_stop: integer;
begin
  case finalestage of
    FIN_STAGE_ANIM:
      begin
        if fli.FrameCount = 4116 then
        begin
          fli_speed := 2;
          fli_stop := 4094;
        end
        else if fli.FrameCount = 959 then
        begin
          fli_speed := 0;
          fli_stop := 957;
        end
        else
        begin
          fli_speed := 1;
          fli_stop := fli.FrameCount - 1;
        end;

        if fli.Frame < fli_stop then
        begin
          case fli_speed of
            0:
              begin
                if Odd(gametic) then
                  fli.NextFrame;
                imgdata := t1.GetImage;
                fli.GetFrameImage32(fli.Frame, imgdata);
                imgdata := t2.GetImage;
                fli.GetFrameImage32(fli.Frame, imgdata);
              end;
            1:
              begin
                fli.NextFrame;
                imgdata := t1.GetImage;
                fli.GetFrameImage32(fli.Frame, imgdata);
                imgdata := t2.GetImage;
                fli.GetFrameImage32(fli.Frame, imgdata);
              end;
            2:
              begin
                fli.NextFrame;
                imgdata := t1.GetImage;
                fli.GetFrameImage32(fli.Frame, imgdata);
                fli.NextFrame;
                imgdata := t2.GetImage;
                fli.GetFrameImage32(fli.Frame, imgdata);
              end;
          end;
        end;
      end;
    FIN_STAGE_FINISHED:
      D_StartTitle;
  end;
end;

//==============================================================================
//
// MARS_InitFinale
//
//==============================================================================
procedure MARS_InitFinale;
begin
  fin_lumps := TDNumberList.Create;
  fli := TFLIFile.Create;

  t1 := new(PTexture, Create);
  t1.SetWidth(FLI_WIDTH);
  t1.SetHeight(FLI_HEIGHT);
  t1.SetBytesPerPixel(4);

  t2 := new(PTexture, Create);
  t2.SetWidth(FLI_WIDTH);
  t2.SetHeight(FLI_HEIGHT);
  t2.SetBytesPerPixel(4);
end;

//==============================================================================
//
// MARS_ShutDownFinale
//
//==============================================================================
procedure MARS_ShutDownFinale;
begin
  fin_lumps.Free;
  fli.Free;

  dispose(t1, Destroy);
  dispose(t2, Destroy);
end;

end.
