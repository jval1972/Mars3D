//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2020 by Jim Valavanis
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
//    Thing frame/state LUT,
//    generated by multigen utilitiy.
//    This one is the original DOOM version, preserved.
//
//------------------------------------------------------------------------------
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

// JVAL: Needed for model definition

unit sc_states;

interface

uses
  p_mobj_h,
  sc_tokens;

var
  statenames: TTokenList;

procedure SC_ParseStatedefLump;

procedure SC_DefaultStatedefLump;

function P_GetStateFromName(const actor: Pmobj_t; const s: string): integer;

function P_GetStateFromNameWithOffsetCheck(const actor: Pmobj_t; const s: string): integer;

implementation

uses
  TypInfo,
  d_delphi,
  info_h,
  info,
  info_common,
  sc_engine,
  w_wad;

const
  STATEDEFLUMPNAME = 'STATEDEF';

procedure SC_DefaultStatedefLump;
var
  st: statenum_t;
begin
  for st := statenum_t(0) to statenum_t(Ord(DO_NUMSTATES) - 1) do
    statenames.Add(strupper(GetENumName(TypeInfo(statenum_t), Ord(st))));
end;

procedure SC_ParseStatedefLump;
var
  i: integer;
  sc: TScriptEngine;
  found: boolean;
begin
  found := false;
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = STATEDEFLUMPNAME then
    begin
      found := true;
      sc := TScriptEngine.Create(W_TextLumpNum(i));
      while sc.GetString do
        statenames.Add(strupper(sc._String));
      sc.Free;
      break;
    end;

  // JVAL: Patch for stand alone script compiler
  if not found then
    SC_DefaultStatedefLump;
end;

function P_GetStateFromName(const actor: Pmobj_t; const s: string): integer;
var
  st: string;
  fw, sw: string;
  pps, ppp, ppb: integer;

  function _stindex(const sss: string): integer;
  var
    sss1, sss2: string;
    p, idx: integer;
    inf: Pmobjinfo_t;
  begin
    result := statenames.IndexOfToken(sss);
    if result >= 0 then
      exit;

    sss1 := strupper(sss);

    p := Pos('::', sss1);
    if p < 2 then // eg allow "goto ::spawn"
      inf := actor.info
    else
    begin
      sss2 := strtrim(Copy(sss1, 1, p - 1));
      sss1 := Copy(sss1, p + 2, Length(sss1) - p - 3);
      if sss2 = 'SUPER' then
        idx := actor.info.inheritsfrom
      else
        idx := Info_GetMobjNumForName(sss2);
      if (idx >= 0) and (idx < nummobjtypes) then
        inf := @mobjinfo[idx]
      else if sss2 = 'SELF' then // eg allow "goto self::spawn"
        inf := actor.info
      else
        inf := nil;
    end;

    if inf <> nil then
    begin
      if sss1 = 'SPAWN' then
      begin
        result := inf.spawnstate;
        exit;
      end
      else if sss1 = 'SEE' then
      begin
        result := inf.seestate;
        exit;
      end
      else if sss1 = 'MELEE' then
      begin
        result := inf.meleestate;
        exit;
      end
      else if sss1 = 'MISSILE' then
      begin
        result := inf.missilestate;
        exit;
      end
      else if sss1 = 'MISSILE' then
      begin
        result := inf.missilestate;
        exit;
      end
      else if sss1 = 'PAIN' then
      begin
        result := inf.painstate;
        exit;
      end
      else if sss1 = 'DEATH' then
      begin
        result := inf.deathstate;
        exit;
      end
      else if sss1 = 'XDEATH' then
      begin
        result := inf.xdeathstate;
        exit;
      end
      else if sss1 = 'RAISE' then
      begin
        result := inf.raisestate;
        exit;
      end
      else if sss1 = 'CRASH' then
      begin
        result := inf.crashstate;
        exit;
      end
      {$IFDEF DOOM_OR_STRIFE}
      else if sss1 = 'INTERACT' then
      begin
        result := inf.interactstate;
        exit;
      end
      {$ENDIF};
    end;

    sss1 := 'S_' + strupper(actor.info.name) + '_' + sss;
    result := statenames.IndexOfToken(sss1);
  end;

begin
  st := strtrim(strupper(strtrim(s)));
  pps := Pos('+', st);
  ppp := Pos('-', st);
  ppb := Pos(' ', st);
  if (ppb = 0) and (ppp = 0) and (pps = 0) then
  begin
    Result := _stindex(st);
    Exit;
  end
  else
  // JVAL: 20170927 evaluate small expressions
  //       20191003 rewritten, fixed
  begin
    st := strremovespaces(st);
    pps := Pos('+', st);
    ppp := Pos('-', st);
    if pps > 0 then
    begin
      splitstring(st, fw, sw, '+');
      Result := _stindex(fw) + atoi(sw, 0);
      Exit;
    end;
    if ppp > 0 then
    begin
      splitstring(st, fw, sw, '-');
      Result := _stindex(fw) - atoi(sw, 0);
      Exit;
    end;
  end;
  Result := -1; // JVAL: No match
end;

function P_GetStateFromNameWithOffsetCheck(const actor: Pmobj_t; const s: string): integer;
var
  check: string;
begin
  check := s;
  if check = '' then
  begin
    Result := 0;
    Exit;
  end;

  if check[1] in ['-', '+'] then
    Delete(check, 1, 1);

  if StrIsLongWord(check) then
    Result := ((integer(actor.state) - integer(states)) div SizeOf(state_t)) + atoi(s)
  else
    Result := P_GetStateFromName(actor, s);
end;

end.

