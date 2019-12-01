//------------------------------------------------------------------------------
//
//  DelphiHeretic: A modified and improved Heretic port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2019 by Jim Valavanis
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
//------------------------------------------------------------------------------
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit info_rnd;

// JVAL: Random items

interface

uses
  info_h;

function Info_SelectRandomMonster(_type: integer): integer;

procedure Info_InitRandom;

procedure Info_ShutDownRandom;

function Info_IsMonster(_type: integer): boolean;

var
  rnd_monster_seed: integer = 0;

implementation

uses
  d_delphi,
  doomdef,
  g_game,
  info,
  m_rnd,
  p_setup, p_mobj, p_mobj_h;

type
  randompool_t = record
    check: integer;
    list: TDNumberList;
  end;

const
  NUMMONSTERSCATEGORIES = 5;

var
  rnd_monsters: array[0..NUMMONSTERSCATEGORIES - 1] of randompool_t;
  rnd_monstersinitialized: boolean = false;

procedure Info_InitRandomMonsters;
var
  i: integer;
  idx: integer;
  check: integer;
begin
  if rnd_monstersinitialized then
    exit;

  if G_PlayingEngineVersion > VERSION110 then
  begin
    rnd_monsters[0].check := 90;
    rnd_monsters[1].check := 120;
    rnd_monsters[2].check := 220;
    rnd_monsters[3].check := 1000;
  end
  else
  begin
    rnd_monsters[0].check := 80;
    rnd_monsters[1].check := 400;
    rnd_monsters[2].check := 1200;
    rnd_monsters[3].check := 2500;
  end;
  rnd_monsters[4].check := MAXINT;

  for i := 0 to NUMMONSTERSCATEGORIES - 1 do
    rnd_monsters[i].list := TDNumberList.Create;

  rnd_monstersinitialized := true;

  for i := 0 to nummobjtypes - 1 do
    if Info_IsMonster(i) and P_GameValidThing(mobjinfo[i].doomednum) then
    begin
      check := mobjinfo[i].spawnhealth;
      idx := 0;
      while (idx < NUMMONSTERSCATEGORIES) and (check >= rnd_monsters[idx].check) do
        inc(idx);
      rnd_monsters[idx].list.Add(i);
    end;
end;

procedure Info_ShutDownRandomMonsters;
var
  i: integer;
begin
  if not rnd_monstersinitialized then
    exit;

  for i := 0 to NUMMONSTERSCATEGORIES - 1 do
    FreeAndNil(rnd_monsters[i].list);

  rnd_monstersinitialized := false;
end;

function Info_SelectRandomMonster(_type: integer): integer;
var
  idx: integer;
  check: integer;
  i: integer;
begin
  check := mobjinfo[_type].spawnhealth;
  idx := 0;
  while (idx < NUMMONSTERSCATEGORIES) and (check >= rnd_monsters[idx].check) do
    inc(idx);

  for i := 0 to rnd_monster_seed - 1 do
    N_Random;

  result := rnd_monsters[idx].list[N_Random mod rnd_monsters[idx].list.Count];
end;

procedure Info_InitRandom;
begin
  Info_InitRandomMonsters
end;

procedure Info_ShutDownRandom;
begin
  Info_ShutDownRandomMonsters
end;

function Info_IsMonster(_type: integer): boolean;
begin
  result := (mobjinfo[_type].doomednum > MAXPLAYERS) and // Not player
            (mobjinfo[_type].flags and MF_SHOOTABLE <> 0) and  // Shootable
            ((mobjinfo[_type].flags and MF_COUNTKILL <> 0) or (mobjinfo[_type].missilestate <> 0) or (mobjinfo[_type].meleestate <> 0));  // Count kill or can attack
end;


end.
