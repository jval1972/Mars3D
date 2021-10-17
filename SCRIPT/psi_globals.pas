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
//  Pascal Script RTL - global variables.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit psi_globals;

interface

uses
  d_delphi,
  SysUtils,
  Classes,
  ps_compiler,
  ps_runtime;

const
  HASHSIZE = 8192;

type
  THashTable = class(TObject)
  private
    positions: array[0..HASHSIZE - 1] of TDNumberList;
    fList: TStringList;
    prevsearches: TDLimitNumberList;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure AssignStringList(const s: TStringList);
    procedure Insert(const str: string; const p: integer);
    procedure Clear;
    function GetPos(const value: string): integer;
    function CheckPos(const value: string): integer;
    property List: TStringList read fList;
  end;

type
  THashStringList = class(TStringList)
  protected
    fhash: THashTable;
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
  public
    constructor Create;
    destructor Destroy; override;
    function IndexOf(const S: string): Integer; override;
    procedure RebuiltHash;
  end;

procedure FreeHashList(var s: THashStringList);

type
  TGlobalVariablesList = class(TObject)
  private
    fStringList: THashStringList;
    fIntegerList: THashStringList;
    fFloatList: THashStringList;
  protected
    function GetInteger(name: string): integer; virtual;
    procedure PutInteger(name: string; const value: integer); virtual;
    function GetFloat(name: string): float; virtual;
    procedure PutFloat(name: string; const value: float); virtual;
    function GetString(name: string): string; virtual;
    procedure PutString(name: string; const value: string); virtual;
    function DoAddString(const name: string; const value: string): integer; virtual;
    function DoAddInteger(const name: string; const value: integer): integer; virtual;
    function DoAddFloat(const name: string; const value: float): integer; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function AddString(const name: string; const value: string): integer; virtual;
    function AddInteger(const name: string; const value: integer): integer; virtual;
    function AddFloat(const name: string; const value: float): integer; virtual;
    procedure Clear;
    function LoadFromBuffer(const pbuf: pointer): integer;
    procedure LoadFromFile(const fname: string);
    function SaveToBuffer(const pbuf: pointer): integer;
    procedure SaveToFile(const fname: string);
    function StructureSize: integer;
    property IntVal[name: string]: integer read GetInteger write PutInteger;
    property FloatVal[name: string]: float read GetFloat write PutFloat;
    property StrVal[name: string]: string read GetString write PutString;
    property Strings: THashStringList read fStringList;
    property Integers: THashStringList read fIntegerList;
    property Floats: THashStringList read fFloatList;
  end;

var
  mapvars: TGlobalVariablesList;
  worldvars: TGlobalVariablesList;

function PS_GetMapStr(const x: string): string;

procedure PS_SetMapStr(const x: string; const v: string);

function PS_GetMapInt(const x: string): integer;

procedure PS_SetMapInt(const x: string; const v: integer);

function PS_GetMapFloat(const x: string): float;

procedure PS_SetMapFloat(const x: string; const v: float);

function PS_GetWorldStr(const x: string): string;

procedure PS_SetWorldStr(const x: string; const v: string);

function PS_GetWorldInt(const x: string): integer;

procedure PS_SetWorldInt(const x: string; const v: integer);

function PS_GetWorldFloat(const x: string): float;

procedure PS_SetWorldFloat(const x: string; const v: float);

procedure PS_InitGlobals;

procedure PS_ShutDownGlobals;

// Script Runtime Helpers
// Global strings
type
  TGlobalStrings = class(TObject)
  protected
    flist: TGlobalVariablesList;
    function Get(vname: string): string; virtual;
    procedure Put(vname: string; const value: string); virtual;
  public
    constructor Create(const alist: TGlobalVariablesList); virtual;
  end;

  TMapStrings = class(TGlobalStrings)
  public
    constructor Create; reintroduce;
    property value[Name: string]: string read Get write Put; default;
  end;

  TWorldStrings = class(TGlobalStrings)
  public
    constructor Create; reintroduce;
    property value[Name: string]: string read Get write Put; default;
  end;

// Script Runtime Helpers
// Global integers
type
  TGlobalIntegers = class(TObject)
  protected
    flist: TGlobalVariablesList;
    function Get(vname: string): integer; virtual;
    procedure Put(vname: string; const value: integer); virtual;
  public
    constructor Create(const alist: TGlobalVariablesList); virtual;
  end;

  TMapIntegers = class(TGlobalIntegers)
  public
    constructor Create; reintroduce;
    property value[Name: string]: integer read Get write Put; default;
  end;

  TWorldIntegers = class(TGlobalIntegers)
  public
    constructor Create; reintroduce;
    property value[Name: string]: integer read Get write Put; default;
  end;

// Script Runtime Helpers
// Global floats
type
  TGlobalFloats = class(TObject)
  protected
    flist: TGlobalVariablesList;
    function Get(vname: string): float; virtual;
    procedure Put(vname: string; const value: float); virtual;
  public
    constructor Create(const alist: TGlobalVariablesList); virtual;
  end;

  TMapFloats = class(TGlobalFloats)
  public
    constructor Create; reintroduce;
    property value[Name: string]: float read Get write Put; default;
  end;

  TWorldFloats = class(TGlobalFloats)
  public
    constructor Create; reintroduce;
    property value[Name: string]: float read Get write Put; default;
  end;

procedure SIRegister_GlobalVars(CL: TPSPascalCompiler);

procedure RIRegister_GlobalVars(CL: TPSRuntimeClassImporter);

procedure RIRegisterRTL_GlobalVars(Exec: TPSExec);

implementation

uses
  c_cmds,
  i_system,
  m_misc,
  z_zone;

function Hash(const name: string): integer;
var
  b: Byte;
  i: integer;
  len: integer;
begin
  len := Length(name);
  if len = 0 then
  begin
    Result := 0;
    Exit;
  end;

  b := Ord(name[1]);

  Result := 5381 * 33 + b;

  for i := 2 to len do
  begin
    b := Ord(name[i]);
    Result := Result * 33 + b;
  end;

  Result := Result and (HASHSIZE - 1);
end;

constructor THashTable.Create;
begin
  inherited;
  flist := nil;
  prevsearches := TDLimitNumberList.CreateLimited(5);
  FillChar(positions, SizeOf(positions), 0);
end;

destructor THashTable.Destroy;
var
  i: integer;
begin
  for i := 0 to HASHSIZE - 1 do
    if positions[i] <> nil then
      positions[i].Free;
  prevsearches.Free;
  inherited;
end;

procedure THashTable.Insert(const str: string; const p: integer);
var
  h: integer;
begin
  if flist = nil then
    Exit;

  h := Hash(str);
  if positions[h] = nil then
    positions[h] := TDNumberList.Create;
  positions[h].Add(p);
end;

procedure THashTable.AssignStringList(const s: TStringList);
var
  i: integer;
  h: integer;
begin
  Clear;
  flist := s;
  for i := 0 to flist.Count - 1 do
  begin
    h := Hash(flist.Strings[i]);
    if positions[h] = nil then
      positions[h] := TDNumberList.Create;
    positions[h].Add(i);
  end;
end;

procedure THashTable.Clear;
var
  i: integer;
begin
  for i := 0 to HASHSIZE - 1 do
    if positions[i] <> nil then
      positions[i].Clear;
end;

function THashTable.GetPos(const value: string): integer;
var
  h: integer;
  i: integer;
  n: integer;
begin
  if flist = nil then
  begin
    Result := -1;
    Exit;
  end;

  if flist.Count = 0 then
  begin
    Result := -1;
    Exit;
  end;

  for i := prevsearches.Count - 1 downto 0 do
  begin
    n := prevsearches[i];
    if (n > -1) and (n < fList.Count) then
      if flist.Strings[n] = value then
      begin
        Result := n;
        Exit;
      end;
  end;

  h := Hash(value);
  if positions[h] = nil then
  begin
    Result := fList.IndexOf(value);
    prevsearches.Add(Result);
    Exit;
  end;

  for i := 0 to positions[h].Count - 1 do
  begin
    n := positions[h].Numbers[i];
    if (n > -1) and (n < fList.Count) then
      if flist.Strings[n] = value then
      begin
        Result := n;
        prevsearches.Add(Result);
        Exit;
      end;
  end;

  Result := fList.IndexOf(value);
end;

function THashTable.CheckPos(const value: string): integer;
var
  h: integer;
  i: integer;
  n: integer;
begin
  for i := prevsearches.Count - 1 downto 0 do
  begin
    n := prevsearches[i];
    if (n > -1) and (n < fList.Count) then
      if flist.Strings[n] = value then
      begin
        Result := n;
        Exit;
      end;
  end;

  h := Hash(value);
  if positions[h] = nil then
  begin
    Result := -1;
    Exit;
  end;

  for i := 0 to positions[h].Count - 1 do
  begin
    n := positions[h].Numbers[i];
    if (n > -1) and (n < fList.Count) then
      if flist.Strings[n] = value then
      begin
        Result := n;
        prevsearches.Add(Result);
        Exit;
      end;
  end;

  Result := -1;
end;

constructor THashStringList.Create;
begin
  fhash := THashTable.Create;
  Inherited Create;
  fhash.AssignStringList(self);
end;

destructor THashStringList.Destroy;
begin
  Inherited;
  fhash.Free;
end;

procedure THashStringList.InsertItem(Index: Integer; const S: string; AObject: TObject);
var
  rebuildhash: boolean;
begin
  rebuildhash := Index < Count;
  inherited InsertItem(Index, S, AObject);
  if rebuildhash then
  begin
    if not Sorted then
      fhash.AssignStringList(self);
  end
  else
    fhash.Insert(s, Index);
end;

function THashStringList.IndexOf(const S: string): Integer;
begin
  if Count = 0 then
  begin
    Result := -1;
    Exit;
  end;

  if Sorted then
  begin
    if not Find(S, Result) then
      Result := -1;
    Exit;
  end;

  Result := fhash.CheckPos(S);
end;

procedure FreeHashList(var s: THashStringList);
var
  i: integer;
begin
  if s = nil then
    Exit;
  for i := 0 to s.Count - 1 do
    if s.Objects[i] <> nil then
      s.Objects[i].Free;
  s.Free;
  s := nil;
end;

procedure THashStringList.RebuiltHash;
begin
  fhash.AssignStringList(self);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TGlobalVariablesList.Create;
begin
  inherited Create;
  fStringList := THashStringList.Create;
  fIntegerList := THashStringList.Create;
  fFloatList := THashStringList.Create;
end;

destructor TGlobalVariablesList.Destroy;
begin
  FreeHashList(fStringList);
  FreeHashList(fIntegerList);
  FreeHashList(fFloatList);
  inherited;
end;

procedure TGlobalVariablesList.Clear;
begin
  FreeHashList(fStringList);
  FreeHashList(fIntegerList);
  FreeHashList(fFloatList);
  fStringList := THashStringList.Create;
  fIntegerList := THashStringList.Create;
  fFloatList := THashStringList.Create;
end;

function TGlobalVariablesList.GetInteger(name: string): integer;
var
  uname: string;
  idx: integer;
begin
  uname := UpperCase(name);
  idx := fIntegerList.IndexOf(uname);
  if idx < 0 then
  begin
    idx := fFloatList.IndexOf(uname);
    if idx < 0 then
    begin
      Result := 0;
      Exit;
    end;
    Result := Round((fFloatList.Objects[idx] as TFloat).floatnum);
    Exit;
  end;
  Result := (fIntegerList.Objects[idx] as TInteger).intnum;
end;

procedure TGlobalVariablesList.PutInteger(name: string; const value: integer);
var
  uname: string;
  idx: integer;
begin
  uname := UpperCase(name);
  idx := fIntegerList.IndexOf(uname);
  if idx < 0 then
    DoAddInteger(uname, value)
  else
    (fIntegerList.Objects[idx] as TInteger).intnum := value;
end;

function TGlobalVariablesList.GetFloat(name: string): float;
var
  uname: string;
  idx: integer;
begin
  uname := UpperCase(name);
  idx := fFloatList.IndexOf(uname);
  if idx < 0 then
  begin
    idx := fIntegerList.IndexOf(uname);
    if idx < 0 then
    begin
      Result := 0.0;
      Exit;
    end;
    Result := (fIntegerList.Objects[idx] as TInteger).intnum;
    Exit;
  end;
  Result := (fFloatList.Objects[idx] as TFloat).floatnum;
end;

procedure TGlobalVariablesList.PutFloat(name: string; const value: float);
var
  uname: string;
  idx: integer;
begin
  uname := UpperCase(name);
  idx := fFloatList.IndexOf(uname);
  if idx < 0 then
    DoAddFloat(uname, value)
  else
    (fFloatList.Objects[idx] as TFloat).floatnum := value;
end;

function TGlobalVariablesList.GetString(name: string): string;
var
  uname: string;
  idx: integer;
begin
  uname := UpperCase(name);
  idx := fStringList.IndexOf(uname);
  if idx < 0 then
  begin
    Result := '';
    Exit;
  end;
  Result := (fStringList.Objects[idx] as TString).str;
end;

procedure TGlobalVariablesList.PutString(name: string; const value: string);
var
  uname: string;
  idx: integer;
begin
  uname := UpperCase(name);
  idx := fStringList.IndexOf(uname);
  if idx < 0 then
    DoAddString(uname, value)
  else
    (fStringList.Objects[idx] as TString).str := value;
end;

// Assumes name is in Uppercase and is not duplicate
function TGlobalVariablesList.DoAddString(const name: string; const value: string): integer;
begin
  Result := fStringList.AddObject(name, TString.Create(value));
end;

// Assumes name is in Uppercase and is not duplicate
function TGlobalVariablesList.DoAddInteger(const name: string; const value: integer): integer;
begin
  Result := fIntegerList.AddObject(name, TInteger.Create(value));
end;

// Assumes name is in Uppercase and is not duplicate
function TGlobalVariablesList.DoAddFloat(const name: string; const value: float): integer;
begin
  Result := fFloatList.AddObject(name, TFloat.Create(value));
end;

function TGlobalVariablesList.AddString(const name: string; const value: string): integer;
var
  uname: string;
begin
  uname := UpperCase(name);
  Result := fStringList.IndexOf(uname);
  if Result < 0 then
    Result := DoAddString(uname, value)
  else
    (fStringList.Objects[Result] as TString).str := value;
end;

function TGlobalVariablesList.AddInteger(const name: string; const value: integer): integer;
var
  uname: string;
begin
  uname := UpperCase(name);
  Result := fIntegerList.IndexOf(uname);
  if Result < 0 then
    Result := DoAddInteger(uname, value)
  else
    (fIntegerList.Objects[Result] as TInteger).intnum := value;
end;

function TGlobalVariablesList.AddFloat(const name: string; const value: float): integer;
var
  uname: string;
begin
  uname := UpperCase(name);
  Result := fFloatList.IndexOf(uname);
  if Result < 0 then
    Result := DoAddFloat(uname, value)
  else
    (fFloatList.Objects[Result] as TFloat).floatnum := value;
end;

function TGlobalVariablesList.LoadFromBuffer(const pbuf: pointer): integer;
var
  p: integer;
  buf: PByteArray;

  function GET_INTEGER: integer;
  begin
    Result := PInteger(@buf[p])^;
    Inc(p, SizeOf(integer));
  end;

  function GET_FLOAT: float;
  begin
    Result := PFloat(@buf[p])^;
    Inc(p, SizeOf(float));
  end;

  function GET_CHAR: char;
  begin
    Result := PChar(@buf[p])^;
    Inc(p, SizeOf(char));
  end;

  function GET_STRING: string;
  var
    x: integer;
    len: integer;
  begin
    len := GET_INTEGER;
    SetLength(Result, len);
    for x := 1 to len do
      Result[x] := GET_CHAR;
  end;

var
  i, num: integer;
  tmpn: string;
begin
  Clear;
  p := 0;
  buf := pbuf;

  // Load strings
  num := GET_INTEGER;
  for i := 0 to num - 1 do
  begin
    tmpn := GET_STRING;
    AddString(tmpn, GET_STRING);
  end;

  // Load integers
  num := GET_INTEGER;
  for i := 0 to num - 1 do
  begin
    tmpn := GET_STRING;
    AddInteger(tmpn, GET_INTEGER);
  end;

  // Load integers
  num := GET_INTEGER;
  for i := 0 to num - 1 do
  begin
    tmpn := GET_STRING;
    AddFloat(tmpn, GET_FLOAT);
  end;

  Result := p;
end;

procedure TGlobalVariablesList.LoadFromFile(const fname: string);
var
  len: integer;
  buf: Pointer;
  buf1: Pointer;
begin
  len := M_ReadFile(fname, buf);
  buf1 := buf;
  incp(pointer(buf1), SizeOf(Integer));
  LoadFromBuffer(buf1);
  if len - SizeOf(integer) <> StructureSize then
    I_Error('TGlobalVariablesList.LoadFromFile(): Can not load from file %s', [fname]);
  Z_Free(buf);
end;

// Returns the bytes written
function TGlobalVariablesList.SaveToBuffer(const pbuf: pointer): integer;
var
  p: integer;
  buf: PByteArray;

  procedure PUT_INTEGER(const v: integer);
  begin
    PInteger(@buf[p])^ := v;
    p := p + SizeOf(integer);
  end;

  procedure PUT_FLOAT(const v: float);
  begin
    PFloat(@buf[p])^ := v;
    p := p + SizeOf(float);
  end;

  procedure PUT_CHAR(const v: char);
  begin
    PChar(@buf[p])^ := v;
    p := p + SizeOf(char);
  end;

  procedure PUT_STRING(const v: string);
  var
    x: integer;
    len: integer;
  begin
    len := Length(v);
    PUT_INTEGER(len);
    for x := 1 to len do
      PUT_CHAR(v[x]);
  end;

var
  i: integer;
begin
  p := 0;
  buf := pbuf;

  PUT_INTEGER(fStringList.Count);
  for i := 0 to fStringList.Count - 1 do
  begin
    PUT_STRING(fStringList.Strings[i]);
    PUT_STRING((fStringList.Objects[i] as TString).str);
  end;

  PUT_INTEGER(fIntegerList.Count);
  for i := 0 to fIntegerList.Count - 1 do
  begin
    PUT_STRING(fIntegerList.Strings[i]);
    PUT_INTEGER((fIntegerList.Objects[i] as TInteger).intnum);
  end;

  PUT_INTEGER(fFloatList.Count);
  for i := 0 to fFloatList.Count - 1 do
  begin
    PUT_STRING(fFloatList.Strings[i]);
    PUT_FLOAT((fFloatList.Objects[i] as TFloat).floatnum);
  end;

  Result := p;
end;

procedure TGlobalVariablesList.SaveToFile(const fname: string);
var
  len: integer;
  buf: Pointer;
  buf1: Pointer;
begin
  len := StructureSize;
  buf := malloc(len + SizeOf(Integer));
  PInteger(buf)^ := len;
  buf1 := buf;
  incp(buf1, SizeOf(Integer));
  SaveToBuffer(buf1);
  M_WriteFile(fname, buf, len + SizeOf(integer));
  memfree(buf, len + SizeOf(Integer));
end;

function TGlobalVariablesList.StructureSize: integer;
var
  i: integer;
begin
  Result := SizeOf(integer);

  for i := 0 to fStringList.Count - 1 do
  begin
    Result := Result + SizeOf(integer) + Length(fStringList.Strings[i]);
    Result := Result + SizeOf(integer) + Length((fStringList.Objects[i] as TString).str);
  end;

  Result := Result + SizeOf(integer);
  for i := 0 to fIntegerList.Count - 1 do
  begin
    Result := Result + SizeOf(integer) + Length(fIntegerList.Strings[i]);
    Result := Result + SizeOf(integer);
  end;

  Result := Result + SizeOf(integer);
  for i := 0 to fFloatList.Count - 1 do
  begin
    Result := Result + SizeOf(integer) + Length(fFloatList.Strings[i]);
    Result := Result + SizeOf(float);
  end;
end;

function PS_GetMapStr(const x: string): string;
begin
  Result := mapvars.StrVal[x];
end;

procedure PS_SetMapStr(const x: string; const v: string);
begin
  mapvars.StrVal[x] := v;
end;

function PS_GetMapInt(const x: string): integer;
begin
  Result := mapvars.IntVal[x];
end;

procedure PS_SetMapInt(const x: string; const v: integer);
begin
  mapvars.IntVal[x] := v;
end;

function PS_GetMapFloat(const x: string): float;
begin
  Result := mapvars.FloatVal[x];
end;

procedure PS_SetMapFloat(const x: string; const v: float);
begin
  mapvars.FloatVal[x] := v;
end;

function PS_GetWorldStr(const x: string): string;
begin
  Result := worldvars.StrVal[x];
end;

procedure PS_SetWorldStr(const x: string; const v: string);
begin
  worldvars.StrVal[x] := v;
end;

function PS_GetWorldInt(const x: string): integer;
begin
  Result := worldvars.IntVal[x];
end;

procedure PS_SetWorldInt(const x: string; const v: integer);
begin
  worldvars.IntVal[x] := v;
end;

function PS_GetWorldFloat(const x: string): float;
begin
  Result := worldvars.FloatVal[x];
end;

procedure PS_SetWorldFloat(const x: string; const v: float);
begin
  worldvars.FloatVal[x] := v;
end;

procedure CmdGetVar(const s1, s2: string; vars: TGlobalVariablesList;
  const desc: string);
var
  s: string;
  v1, v2: string;
begin
  if s1 = '' then
  begin
    printf('Please specify the names of the %s variables to display.'#13#10, [desc]);
    Exit;
  end;

  s := UpperCase(Trim(s1 + ' ' + s2));
  repeat
    splitstring(s, v1, v2);
    if v1 <> '' then
    begin
      if vars.fStringList.IndexOf(v1) >= 0 then
        printf('[%s]=%s'#13#10, [v1, vars.StrVal[v1]])
      else if vars.fIntegerList.IndexOf(v1) >= 0 then
        printf('[%s]=%d'#13#10, [v1, vars.IntVal[v1]])
      else if vars.fFloatList.IndexOf(v1) >= 0 then
        printf('[%s]=%2.3f'#13#10, [v1, vars.FloatVal[v1]])
      else
        printf('[%s] - (undeclared %s variable)'#13#10, [v1, desc]);
    end;
    s := strtrim(v2);
  until s = '';
end;

procedure CmdGetWorldVar(const s1, s2: string);
begin
  CmdGetVar(s1, s2, worldvars, 'world');
end;

procedure CmdGetMapVar(const s1, s2: string);
begin
  CmdGetVar(s1, s2, mapvars, 'map');
end;

procedure CmdSetVar(const s1, s2: string; vars: TGlobalVariablesList;
  const desc: string);
begin
  if s1 = '' then
  begin
    printf('Please specify the names of the %s variable to set.'#13#10, [desc]);
    Exit;
  end;

  if s2 = '' then
  begin
    vars.StrVal[s1] := '';
    Exit;
  end;

  if Pos(' ', s2) > 0 then
  begin
    vars.StrVal[s1] := s2;
    Exit;
  end;

  if vars.fStringList.IndexOf(s1) >= 0 then
    vars.StrVal[s1] := s2
  else if vars.fIntegerList.IndexOf(s1) >= 0 then
    vars.IntVal[s1] := atoi(s2)
  else if vars.fFloatList.IndexOf(s1) >= 0 then
    vars.FloatVal[s1] := atof(s2)
  else
  begin
    if StrIsInteger(s2) then
      vars.IntVal[s1] := atoi(s2)
    else if StrIsFloat(s2) then
      vars.FloatVal[s1] := atof(s2)
    else
      vars.StrVal[s1] := s2
  end;
end;

procedure CmdSetWorldVar(const s1, s2: string);
begin
  CmdSetVar(s1, s2, worldvars, 'world');
end;

procedure CmdSetMapVar(const s1, s2: string);
begin
  CmdSetVar(s1, s2, mapvars, 'map');
end;


var
  RTL_MapVarS: TMapStrings;
  RTL_WorldVarS: TWorldStrings;
  RTL_MapVarI: TMapIntegers;
  RTL_WorldVarI: TWorldIntegers;
  RTL_MapVarF: TMapFloats;
  RTL_WorldVarF: TWorldFloats;

procedure PS_InitGlobals;
begin
  mapvars := TGlobalVariablesList.Create;
  worldvars := TGlobalVariablesList.Create;

  RTL_MapVarS := TMapStrings.Create;
  RTL_WorldVarS := TWorldStrings.Create;
  RTL_MapVarI := TMapIntegers.Create;
  RTL_WorldVarI := TWorldIntegers.Create;
  RTL_MapVarF := TMapFloats.Create;
  RTL_WorldVarF := TWorldFloats.Create;

  C_AddCmd('getworldvar', @CmdGetWorldVar);
  C_AddCmd('getmapvar', @CmdGetMapVar);
  C_AddCmd('setworldvar', @CmdSetWorldVar);
  C_AddCmd('setmapvar', @CmdSetMapVar);
end;

procedure PS_ShutDownGlobals;
begin
  RTL_MapVarS.Free;
  RTL_WorldVarS.Free;
  RTL_MapVarI.Free;
  RTL_WorldVarI.Free;
  RTL_MapVarF.Free;
  RTL_WorldVarF.Free;

  mapvars.Free;
  worldvars.Free;
end;

// Script Runtime Helpers
// Global strings
constructor TGlobalStrings.Create(const alist: TGlobalVariablesList);
begin
  fList := alist;
  inherited Create;
end;

function TGlobalStrings.Get(vname: string): string;
begin
  Result := flist.GetString(vname);
end;

procedure TGlobalStrings.Put(vname: string; const value: string);
begin
  flist.PutString(vname, value);
end;

constructor TMapStrings.Create;
begin
  inherited Create(mapvars);
end;

constructor TWorldStrings.Create;
begin
  inherited Create(worldvars);
end;

// Script Runtime Helpers
// Global integers
constructor TGlobalIntegers.Create(const alist: TGlobalVariablesList);
begin
  fList := alist;
  inherited Create;
end;

function TGlobalIntegers.Get(vname: string): integer;
begin
  Result := flist.GetInteger(vname);
end;

procedure TGlobalIntegers.Put(vname: string; const value: integer);
begin
  flist.PutInteger(vname, value);
end;

constructor TMapIntegers.Create;
begin
  inherited Create(mapvars);
end;

constructor TWorldIntegers.Create;
begin
  inherited Create(worldvars);
end;

// Script Runtime Helpers
// Global floats
constructor TGlobalFloats.Create(const alist: TGlobalVariablesList);
begin
  fList := alist;
  inherited Create;
end;

function TGlobalFloats.Get(vname: string): float;
begin
  Result := flist.GetFloat(vname);
end;

procedure TGlobalFloats.Put(vname: string; const value: float);
begin
  flist.PutFloat(vname, value);
end;

constructor TMapFloats.Create;
begin
  inherited Create(mapvars);
end;

constructor TWorldFloats.Create;
begin
  inherited Create(worldvars);
end;

procedure SIRegister_TWorldFloats(CL: TPSPascalCompiler);
begin
  with CL.AddClassN(CL.FindClass('!TOBJECT'), '!TWorldFloats') do
  begin
    RegisterMethod('Constructor Create');
    RegisterProperty('value', 'single string', iptRW);
    SetDefaultPropery('value');
  end;
  AddImportedClassVariable(CL, 'WorldFloats', '!TWorldFloats');
end;

procedure SIRegister_TMapFloats(CL: TPSPascalCompiler);
begin
  with CL.AddClassN(CL.FindClass('!TOBJECT'), '!TMapFloats') do
  begin
    RegisterMethod('Constructor Create');
    RegisterProperty('value', 'single string', iptRW);
    SetDefaultPropery('value');
  end;
  AddImportedClassVariable(CL, 'MapFloats', '!TMapFloats');
end;

procedure SIRegister_TWorldIntegers(CL: TPSPascalCompiler);
begin
  with CL.AddClassN(CL.FindClass('!TOBJECT'), '!TWorldIntegers') do
  begin
    RegisterMethod('Constructor Create');
    RegisterProperty('value', 'integer string', iptRW);
    SetDefaultPropery('value');
  end;
  AddImportedClassVariable(CL, 'WorldIntegers', '!TWorldIntegers');
end;

procedure SIRegister_TMapIntegers(CL: TPSPascalCompiler);
begin
  with CL.AddClassN(CL.FindClass('!TOBJECT'), '!TMapIntegers') do
  begin
    RegisterMethod('Constructor Create');
    RegisterProperty('value', 'integer string', iptRW);
    SetDefaultPropery('value');
  end;
  AddImportedClassVariable(CL, 'MapIntegers', '!TMapIntegers');
end;

procedure SIRegister_TWorldStrings(CL: TPSPascalCompiler);
begin
  with CL.AddClassN(CL.FindClass('!TOBJECT'), '!TWorldStrings') do
  begin
    RegisterMethod('Constructor Create');
    RegisterProperty('value', 'string string', iptRW);
    SetDefaultPropery('value');
  end;
  AddImportedClassVariable(CL, 'WorldStrings', '!TWorldStrings');
end;

procedure SIRegister_TMapStrings(CL: TPSPascalCompiler);
begin
  with CL.AddClassN(CL.FindClass('!TOBJECT'), '!TMapStrings') do
  begin
    RegisterMethod('Constructor Create');
    RegisterProperty('value', 'string string', iptRW);
    SetDefaultPropery('value');
  end;
  AddImportedClassVariable(CL, 'MapStrings', '!TMapStrings');
end;

procedure SIRegister_GlobalVars(CL: TPSPascalCompiler);
begin
  SIRegister_TMapStrings(CL);
  SIRegister_TWorldStrings(CL);
  SIRegister_TMapIntegers(CL);
  SIRegister_TWorldIntegers(CL);
  SIRegister_TMapFloats(CL);
  SIRegister_TWorldFloats(CL);
end;

(* === run-time registration functions === *)
procedure TWorldFloatsvalue_W(Self: TWorldFloats; const T: single; const t1: string);
begin
  Self.value[t1] := T;
end;

procedure TWorldFloatsvalue_R(Self: TWorldFloats; var T: single; const t1: string);
begin
  T := Self.value[t1];
end;

procedure TMapFloatsvalue_W(Self: TMapFloats; const T: single; const t1: string);
begin
  Self.value[t1] := T;
end;

procedure TMapFloatsvalue_R(Self: TMapFloats; var T: single; const t1: string);
begin
  T := Self.value[t1];
end;

procedure TWorldIntegersvalue_W(Self: TWorldIntegers; const T: integer; const t1: string);
begin
  Self.value[t1] := T;
end;

procedure TWorldIntegersvalue_R(Self: TWorldIntegers; var T: integer; const t1: string);
begin
  T := Self.value[t1];
end;

procedure TMapIntegersvalue_W(Self: TMapIntegers; const T: integer; const t1: string);
begin
  Self.value[t1] := T;
end;

procedure TMapIntegersvalue_R(Self: TMapIntegers; var T: integer; const t1: string);
begin
  T := Self.value[t1];
end;

procedure TWorldStringsvalue_W(Self: TWorldStrings; const T: string; const t1: string);
begin
  Self.value[t1] := T;
end;

procedure TWorldStringsvalue_R(Self: TWorldStrings; var T: string; const t1: string);
begin
  T := Self.value[t1];
end;

procedure TMapStringsvalue_W(Self: TMapStrings; const T: string; const t1: string);
begin
  Self.value[t1] := T;
end;

procedure TMapStringsvalue_R(Self: TMapStrings; var T: string; const t1: string);
begin
  T := Self.value[t1];
end;

procedure RIRegister_TWorldFloats(CL: TPSRuntimeClassImporter);
begin
  with CL.Add2(TWorldFloats, '!TWORLDFLOATS') do
  begin
    RegisterConstructor(@TWorldFloats.Create, 'Create');
    RegisterPropertyHelper(@TWorldFloatsvalue_R, @TWorldFloatsvalue_W, 'value');
  end;
end;

procedure RIRegister_TMapFloats(CL: TPSRuntimeClassImporter);
begin
  with CL.Add2(TMapFloats, '!TMAPFLOATS') do
  begin
    RegisterConstructor(@TMapFloats.Create, 'Create');
    RegisterPropertyHelper(@TMapFloatsvalue_R, @TMapFloatsvalue_W, 'value');
  end;
end;

procedure RIRegister_TWorldIntegers(CL: TPSRuntimeClassImporter);
begin
  with CL.Add2(TWorldIntegers, '!TWORLDINTEGERS') do
  begin
    RegisterConstructor(@TWorldIntegers.Create, 'Create');
    RegisterPropertyHelper(@TWorldIntegersvalue_R, @TWorldIntegersvalue_W, 'value');
  end;
end;

procedure RIRegister_TMapIntegers(CL: TPSRuntimeClassImporter);
begin
  with CL.Add2(TMapIntegers, '!TMAPINTEGERS') do
  begin
    RegisterConstructor(@TMapIntegers.Create, 'Create');
    RegisterPropertyHelper(@TMapIntegersvalue_R, @TMapIntegersvalue_W, 'value');
  end;
end;

procedure RIRegister_TWorldStrings(CL: TPSRuntimeClassImporter);
begin
  with CL.Add2(TWorldStrings, '!TWORLDSTRINGS') do
  begin
    RegisterConstructor(@TWorldStrings.Create, 'Create');
    RegisterPropertyHelper(@TWorldStringsvalue_R, @TWorldStringsvalue_W, 'value');
  end;
end;

procedure RIRegister_TMapStrings(CL: TPSRuntimeClassImporter);
begin
  with CL.Add2(TMapStrings, '!TMAPSTRINGS') do
  begin
    RegisterConstructor(@TMapStrings.Create, 'Create');
    RegisterPropertyHelper(@TMapStringsvalue_R, @TMapStringsvalue_W, 'value');
  end;
end;

procedure RIRegister_GlobalVars(CL: TPSRuntimeClassImporter);
begin
  RIRegister_TMapStrings(CL);
  RIRegister_TWorldStrings(CL);
  RIRegister_TMapIntegers(CL);
  RIRegister_TWorldIntegers(CL);
  RIRegister_TMapFloats(CL);
  RIRegister_TWorldFloats(CL);
end;

// JVAL: Must be called after Loading data.
procedure RIRegisterRTL_GlobalVars(Exec: TPSExec);
begin
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('MapStrings')), RTL_MapVarS);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('WorldStrings')), RTL_WorldVarS);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('MapIntegers')), RTL_MapVarI);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('WorldIntegers')), RTL_WorldVarI);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('MapFloats')), RTL_MapVarF);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('WorldFloats')), RTL_WorldVarF);
end;

end.

