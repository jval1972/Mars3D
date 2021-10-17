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
//  Holds a list with current mobjs
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_mobjlist;

interface

uses
  m_smartpointerlist,
  p_mobj_h;

const
  MOBJHASHSIZE = 8192;

type
  TMobjList = class(TObject)
  private
    containers: array[0..MOBJHASHSIZE - 1] of TSmartPointerList;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure Add(const m: Pmobj_t); virtual;
    procedure Remove(const m: Pmobj_t); virtual;
    function FindMobj(const m: Pmobj_t): Boolean;
    function FindMobjFromKey(const key: LongWord): Pmobj_t;
  end;

var
  mobjlist: TMobjList;

const
  MAXKEY = 2147483647;

function P_GenGlobalMobjKey: LongWord;

procedure P_NotifyMobjKey(const m: Pmobj_t);

implementation

constructor TMobjList.Create;
var
  i: integer;
begin
  inherited;
  for i := 0 to MOBJHASHSIZE - 1 do
    containers[i] := TSmartPointerList.Create;
end;

destructor TMobjList.Destroy;
var
  i: integer;
begin
  for i := 0 to MOBJHASHSIZE - 1 do
    containers[i].Free;
  inherited;
end;

procedure TMobjList.Clear;
var
  i: integer;
begin
  for i := 0 to MOBJHASHSIZE - 1 do
    containers[i].Clear;
end;

// Must be called from P_AddThinker
procedure TMobjList.Add(const m: Pmobj_t);
var
  hash: LongWord;
begin
  hash := m.key and (MOBJHASHSIZE - 1);
  containers[hash].AddItem(m);
end;

// Must be called from P_RemoveThinker
procedure TMobjList.Remove(const m: Pmobj_t);
var
  hash: LongWord;
begin
  hash := m.key and (MOBJHASHSIZE - 1);
  containers[hash].DeleteItem(m);
end;

function TMobjList.FindMobj(const m: Pmobj_t): Boolean;
var
  hash: LongWord;
begin
  hash := m.key and (MOBJHASHSIZE - 1);
  Result := containers[hash].ItemExists(m);
end;

function TMobjList.FindMobjFromKey(const key: LongWord): Pmobj_t;
var
  hash: LongWord;
  i: integer;
  L: TSmartPointerList;
begin
  hash := key and (MOBJHASHSIZE - 1);
  L := containers[hash];
  for i := 0 to L.Count - 1 do
    if Pmobj_t(L.List[i]).key = key then
    begin
      Result := L.List[i];
      L.Priority(i);  // JVAL: Increase priority for last found item
      Exit;
    end;
  Result := nil;
end;

var
  mobjkeycnt: LongWord = 1;

function P_GenGlobalMobjKey: LongWord;
begin
  Result := mobjkeycnt;
  if (Result < 1) or (Result >= MAXKEY) then
  begin
    mobjkeycnt := 1;
    Result := 1;
  end;
  inc(mobjkeycnt);
  if mobjkeycnt >= MAXKEY then
    mobjkeycnt := 1;
end;

procedure P_NotifyMobjKey(const m: Pmobj_t);
begin
  if m <> nil then
    if mobjkeycnt <= m.key then
    begin
      if m.key >= MAXKEY then
        m.key := P_GenGlobalMobjKey
      else
        mobjkeycnt := m.key + 1;
    end;
end;

end.
