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
//   Mars dialogs
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_dialog;

interface

uses
  p_mobj_h;

procedure A_Dialog(actor: Pmobj_t);

implementation

uses
  d_delphi,
  g_game,
  hu_stuff,
  m_menu,
  mn_textwrite,
  p_common,
  r_defs,
  v_data,
  v_video,
  w_pak,
  w_wad,
  z_zone;

const
  FOLDER_DIALOGS = 'DIALOGS';

var
  dialog_font: Ppatch_tPArray;
  dialog_shade: Ppatch_tPArray;

function MARS_DialogLoadText(const lumpname: string): string;
var
  lump: integer;
  strm: TPakStream;
  sl: TDStringList;
begin
  if Length(lumpname) <= 8 then
  begin
    lump := W_CheckNumForName(lumpname);
    if lump >= 0 then
    begin
      Result := W_TextLumpNum(lump);
      Exit;
    end;
  end;

  strm := TPakStream.Create(lumpname, pm_short, '', FOLDER_DIALOGS);
  if strm.IOResult <> 0 then
  begin
    strm.Free;
    Result := '';
    Exit;
  end;

  sl := TDStringList.Create;
  sl.LoadFromStream(strm);
  Result := sl.Text;
  sl.Free;
  strm.Free;
end;

function M_DialogDimMsg(x, y: integer; str: string; const fnt: Ppatch_tPArray): string;
var
  maxwidth: integer;
  i, j: integer;
  lst, lst2: TDStringList;
  line, s, s1, s2: string;

  function _StringWidth(const s: string): integer;
  begin
    Result := M_StringWidth(s, _MA_LEFT or _MC_UPPER, dialog_font);
  end;

begin
  maxwidth := 320 - 2 * x;

  result := '';

  if str = '' then
    exit;

  lst := TDStringList.Create;

  lst.Text := strupper(str);

  for i := 0 to lst.Count - 1 do
  begin
    lst2 := TDStringList.Create;
    s := lst.Strings[i];
    repeat
      splitstring(s, s1, s2);
      lst2.Add(s1);
      s := s2;
    until s = '';

    line := '';
    for j := 0 to lst2.Count - 1 do
    begin
      if (_StringWidth(line + lst2.Strings[j]) <= maxwidth) or (line = '') then
      begin
        if line = '' then
          line := lst2.Strings[j]
        else
          line := line + ' ' + lst2.Strings[j];
      end
      else
      begin
        result := result + line + #13#10;
        line := lst2.Strings[j];
      end;
    end;
    lst2.Free;
    if line <> '' then
    begin
      result := result + line;
    end;
      if i <> lst.Count - 1 then
        result := result + #13#10;
  end;
  lst.Free;
end;

const
  MAXDIALOGMENUITEMS = 16;

var
  dialogmenuitems: array[0..MAXDIALOGMENUITEMS - 1] of menuitem_t;
  dialogmenus: array[0..MAXDIALOGMENUITEMS - 1] of menu_t;
  dialoglumps: array[0..MAXDIALOGMENUITEMS - 1] of string;
  numdialogs: Integer;
  currentdialog: Integer;

procedure Mars_DialogChoice(choice: Integer);
begin
  Inc(currentdialog);
  if currentdialog = numdialogs then
    menuactive := False
  else
    M_SetupNextMenu(@dialogmenus[currentdialog]);
end;

procedure MARS_DialogDrawer;
var
  str: string;
begin
  V_DrawPatchTransparent(20, 10, SCN_FG, W_CacheLumpName('M_DIALOG', PU_STATIC), true);
  str := M_DialogDimMsg(39, 17, MARS_DialogLoadText(dialoglumps[currentdialog]), dialog_font);
  M_WriteText(39, 17, str, _MA_LEFT or _MC_UPPER, dialog_font, dialog_shade);
end;

procedure A_Dialog(actor: Pmobj_t);
var
  i, cnt: integer;
  pmi: Pmenuitem_t;
begin
  if menuactive or netgame then
    exit;

  if demoplayback or demorecording then
    exit;

  if not P_CheckStateParams(actor, 1, CSP_AT_LEAST) then
    exit;

  cnt := actor.state.params.Count;
  if cnt > MAXDIALOGMENUITEMS then
    cnt := MAXDIALOGMENUITEMS;

  numdialogs := cnt;
  currentdialog := 0;

  dialog_font := @ltgreen_font;
  dialog_shade :=  @dark_font;

  // Generate the menu sequence
  pmi := @dialogmenuitems[0];
  for i := 0 to cnt - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @Mars_DialogChoice;
    pmi.pBoolVal := nil;
    pmi.alphaKey := ' ';
    Inc(pmi);

    dialoglumps[i] := actor.state.params.StrVal[i];

    dialogmenus[i].numitems := 1;
    dialogmenus[i].prevMenu := nil;
    dialogmenus[i].leftMenu := nil;
    dialogmenus[i].rightMenu := nil;
    dialogmenus[i].menuitems := Pmenuitem_tArray(@dialogmenuitems[i]);
    dialogmenus[i].drawproc := @MARS_DialogDrawer;  // draw routine
    dialogmenus[i].x := 0;
    dialogmenus[i].y := 0;
    dialogmenus[i].lastOn := 0;
    dialogmenus[i].itemheight := 10;
    dialogmenus[i].flags := FLG_MN_RUNONSELECT;
  end;

  M_StartControlPanel;
  M_MenuSound;
  currentMenu := @dialogmenus[0];
end;

end.
