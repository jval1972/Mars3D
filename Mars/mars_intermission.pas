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
//    Intermission screen
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_intermission;

interface

uses
  d_player,
  d_event;

procedure MARS_InitIntermission;

procedure MARS_ShutDownIntermission;

function MARS_IntermissionResponder(ev: Pevent_t): boolean;

// Called by main loop
procedure MARS_Intermission_Ticker;

// Called by main loop,
// draws the intermission screens directly into the screen buffer.
procedure MARS_Intermission_Drawer;

// Setup the intermission screens.
procedure MARS_Intermission_Start(wbstartstruct: Pwbstartstruct_t);

implementation

uses
  d_delphi,
  doomdef,
  doomtype,
  anm_info,
  anm_lib,
  g_game,
  hu_stuff,
  mn_textwrite,
  mars_files,
  r_data,
  sounds,
  s_sound,
  v_data,
  v_video,
  w_wad;

const
  MAX_INTERMISSION_SCREENS = 100;

const
  IN_STAGE_BRIEFING = 0;
  IN_STAGE_STATS1 = 1;
  IN_STAGE_STATS2 = 2;
  IN_STAGE_STATS3 = 3;
  IN_STAGE_STATS4 = 4;
  IN_STAGE_ANIM = 5;
  IN_STAGE_END = 6;

const
  IN_NUMSTATSANIMS = 4;

var
  in_lumps: TDNumberList;
  in_tic: integer;
  in_stage: integer;
  in_struct: Pwbstartstruct_t;
  anmfile: string;
  anm_frame: integer;
  anm_inrepeat: boolean;
  anm_autoadvance: boolean;
  anm_frametics: integer;

procedure MARS_InitIntermission;
begin
  in_lumps := TDNumberList.Create;
end;

procedure MARS_ShutDownIntermission;
begin
  in_lumps.Free;
end;

var
  in_key_down: boolean;

const
  MAXEPISODES = 6;

var
  animnames: array[0..6] of string = (
    'CHAP1.ANM',
    'CHAP2.ANM',
    'CHAP3.ANM',
    'CHAP4.ANM',
    'TIME.ANM',
    'CHAP6.ANM',
    'CHAP7.ANM'
  );

var
  animautoadvance: array[0..6] of boolean = (
    false,
    false,
    false,
    false,
    true,
    false,
    false
  );

procedure MARS_IntermissionAdvanceStage;
begin
  inc(in_stage);
  anm_frame := -1;
  anm_frametics := MAXINT;
  anmfile := '';
  anm_inrepeat := false;
  anm_autoadvance := false;
  if in_stage = IN_STAGE_END then
    G_WorldDone;
end;

procedure MARS_IntermissionAdvance;
begin
  case in_stage of
    IN_STAGE_BRIEFING:
      begin
        if in_lumps.Count > 0 then
          in_lumps.Delete(0);
        if in_lumps.Count = 0 then
        begin
          MARS_IntermissionAdvanceStage;
          anmfile := MARS_FindFile('PASS1.ANM');
          if not fexists(anmfile) then
          begin
            anmfile := '';
            MARS_IntermissionAdvance;
          end
          else
            anm_frametics := (ANM_QueryNumFrames(anmfile) - 1) * ANM_GetInfo(anmfile).tic;
        end;
      end;
    IN_STAGE_STATS1:
      begin
        MARS_IntermissionAdvanceStage;
        anmfile := MARS_FindFile('PASS2.ANM');
        if not fexists(anmfile) then
        begin
          anmfile := '';
          MARS_IntermissionAdvance;
        end
        else
          anm_frametics := (ANM_QueryNumFrames(anmfile) - 1) * ANM_GetInfo(anmfile).tic;
      end;
    IN_STAGE_STATS2:
      begin
        MARS_IntermissionAdvanceStage;
        anmfile := MARS_FindFile('PASS3.ANM');
        if not fexists(anmfile) then
        begin
          anmfile := '';
          MARS_IntermissionAdvance;
        end
        else
          anm_frametics := (ANM_QueryNumFrames(anmfile) - 1) * ANM_GetInfo(anmfile).tic;
      end;
    IN_STAGE_STATS3:
      begin
        MARS_IntermissionAdvanceStage;
        anmfile := MARS_FindFile('PASS4.ANM');
        if not fexists(anmfile) then
        begin
          anmfile := '';
          MARS_IntermissionAdvance;
        end
        else
          anm_frametics := (ANM_QueryNumFrames(anmfile) - 1) * ANM_GetInfo(anmfile).tic;
      end;
    IN_STAGE_STATS4:
      begin
        MARS_IntermissionAdvanceStage;
        if gameepisode = 1 then
        begin
          if gamemap < 7 then
          begin
            anmfile := MARS_FindFile(animnames[gamemap]);
            anm_autoadvance := animautoadvance[gamemap];
            if not fexists(anmfile) then
            begin
              anmfile := '';
              MARS_IntermissionAdvance;
            end
            else
              anm_frametics := (ANM_QueryNumFrames(anmfile) - 1) * ANM_GetInfo(anmfile).tic;
          end;
        end;
      end;
    IN_STAGE_ANIM:
      begin
        MARS_IntermissionAdvanceStage;
      end;
  else
    G_WorldDone;
  end;
end;

function MARS_IntermissionResponder(ev: Pevent_t): boolean;
begin
  if ev._type <> ev_keydown then
  begin
    if ev._type = ev_keyup then
      in_key_down := false;
    result := false;
    exit;
  end;

  result := true;
  in_key_down := true;

  MARS_IntermissionAdvance;
end;

var
  in_music_changed: boolean;

procedure MARS_Intermission_Ticker;
begin
  inc(in_tic);
  if in_tic = 1 then
    if not in_music_changed then
    begin
      S_ChangeMusic(Ord(mus_inter), true);
      in_music_changed := true;
    end;

  if not in_key_down then
    in_tic := 0;

  if in_stage in [IN_STAGE_BRIEFING, IN_STAGE_ANIM] then
    if in_tic >= TICRATE then
    begin
      MARS_IntermissionAdvance; // Briefing screens accelerated
      in_tic := TICRATE - 4;
    end;

  if in_stage in [IN_STAGE_STATS1..IN_STAGE_ANIM] then
    if anm_frametics < MAXINT then
      Inc(anm_frame);
  printf('%d'#13#10, [anm_frame]);
  if anm_autoadvance then
    if in_stage = IN_STAGE_ANIM then
      if anm_frame >= anm_frametics then
        MARS_IntermissionAdvance;
end;

procedure MARS_Intermission_Drawer1;
begin
  if in_lumps.Count > 0 then
    V_DrawPatchFullScreenTMP320x200(in_lumps.Numbers[0]);
end;

procedure MI_CheckANMInfo(const anm: TANMFile; const inf: Panminfo_t);
begin
  if (inf.maxframe < 0) or (inf.maxframe >= anm.FrameCount) then
    inf.maxframe := anm.FrameCount - 1;
  if inf.tic < 1 then
    inf.tic := 1;
  if (inf.repeatframe < 0) or (inf.repeatframe >= inf.maxframe) then
    inf.repeatframe := 0;
end;

procedure MI_DrawAnim;
var
  anm: TANMFile;
  anmstrm: TFile;
  inf: anminfo_t;
  frm: integer;
begin
  if anmfile = '' then
    Exit;

  if not fexists(anmfile) then
    Exit;

  anmstrm := TFile.Create(anmfile, fOpenReadOnly);
  anm := TANMFile.Create(anmstrm);

  inf := ANM_GetInfo(anmfile);
  MI_CheckANMInfo(anm, @inf);

  frm := anm_frame div inf.tic;

  if frm < 0 then
  begin
    frm := 0;
    anm_frame := -1;
  end
  else if frm >= inf.maxframe then
  begin
    frm := inf.repeatframe;
    anm_frame := frm * inf.tic;
    anm_inrepeat := true;
  end;

  anm.GetFrameImage8(frm, Panmscreen8_t(screens[SCN_TMP]));

  anm.Free;
  anmstrm.Free;
end;

procedure MARS_Intermission_Drawer2;
begin
  MI_DrawAnim;
end;

procedure MARS_Intermission_Drawer3;
var
  c1, c2, c3, c4: Byte;
  s: string;

  function _check_stage(const st: integer): boolean;
  begin
    Result := (in_stage > st) or ((in_stage = st) and anm_inrepeat);
  end;

  function _tics_to_timestr(const t: integer): string;
  var
    shour, smin, ssec: string;
    t1: integer;
    tmp: integer;
  begin
    t1 := t div TICRATE;
    tmp := t1 mod 60;
    t1 := t1 div 60;
    ssec := IntToStrzFill(2, tmp);
    tmp := t1 mod 60;
    t1 := t1 div 60;
    if t1 <> 0 then
    begin
      smin := IntToStrzFill(2, tmp);
      shour := itoa(t1);
      Result := shour + ':' + smin + ':' + ssec;
    end
    else
    begin
      smin := itoa(tmp);
      Result := smin + ':' + ssec;
    end;
  end;

  procedure _write_line(ypos: integer; const txt: string);
  var
    w: integer;
  begin
    w := M_StringWidth(txt, _MA_RIGHT or _MC_UPPER, @mars_fontLG);
    memset(@screens[SCN_TMP][320 * (9 + ypos) + 7], c1, 165 - w - 7 - 5);
    memset(@screens[SCN_TMP][320 * (10 + ypos) + 7], c2, 165 - w - 7 - 5);
    memset(@screens[SCN_TMP][320 * (11 + ypos) + 7], c3, 165 - w - 7 - 5);
    memset(@screens[SCN_TMP][320 * (12 + ypos) + 7], c4, 165 - w - 7 - 5);
    M_WriteText(165, ypos + 1, txt, _MA_RIGHT or _MC_UPPER, @mars_fontLG);
  end;

begin
  MI_DrawAnim;

  if _check_stage(IN_STAGE_STATS1) then
  begin
    c1 := V_FindAproxColorIndex(@videopal, $322500);
    c2 := V_FindAproxColorIndex(@videopal, $CEA732);
    c3 := V_FindAproxColorIndex(@videopal, $AB6E1D);
    c4 := V_FindAproxColorIndex(@videopal, $5F2000);
    s := _tics_to_timestr(in_struct.plyr[in_struct.pnum].stime);
    _write_line(22, s);
    if _check_stage(IN_STAGE_STATS2) then
    begin
      s := _tics_to_timestr(in_struct.partime);
      _write_line(59, s);
      if _check_stage(IN_STAGE_STATS3) then
      begin
        if in_struct.maxkills = 0 then
          s := 'None'
        else
          s := itoa(in_struct.plyr[in_struct.pnum].skills div in_struct.maxkills) + '%';
        _write_line(96, s);
        if _check_stage(IN_STAGE_STATS4) then
        begin
          s := itoa(in_struct.plyr[in_struct.pnum].ssecret) + '/' + itoa(in_struct.maxsecret);
          _write_line(135, s);
        end;
      end;
    end;
  end;
end;

procedure MARS_Intermission_Drawer;
begin
  case in_stage of
    IN_STAGE_BRIEFING:
      MARS_Intermission_Drawer1;
    IN_STAGE_ANIM:
      MARS_Intermission_Drawer2;
    IN_STAGE_STATS1..IN_STAGE_STATS4:
      MARS_Intermission_Drawer3;
  else
    memset(screens[SCN_TMP], aprox_black, 320 * 200);
  end;
  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  V_FullScreenStretch;
end;

procedure MARS_Intermission_Start(wbstartstruct: Pwbstartstruct_t);
var
  i: integer;
  pg: string;
  lump: integer;
begin
  in_struct := wbstartstruct;
  in_lumps.Clear;
  // Only for episode 1 briefing screens
  if gameepisode = 1 then
    for i := 0 to MAX_INTERMISSION_SCREENS - 1 do
    begin
      sprintf(pg, 'B%d%s', [gamemap, IntToStrZfill(2, i)]);
      lump := W_CheckNumForName(pg);
      if lump >= 0 then
        in_lumps.Add(lump);
    end;
  in_tic := 0;
  in_stage := IN_STAGE_BRIEFING;
  in_music_changed := false;
  in_key_down := false;
  anm_frame := -1;
  anm_frametics := MAXINT;
  anmfile := '';
  anm_inrepeat := false;
  if in_lumps.Count = 0 then
    MARS_IntermissionAdvanceStage;
end;

end.

