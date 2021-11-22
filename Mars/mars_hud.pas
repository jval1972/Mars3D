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
// DESCRIPTION
//  HUD stuff
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_hud;

interface

procedure MARS_InitHud;

procedure MARS_ShutDownHud;

procedure MARS_HudDrawer;

var
  drawcrosshair: boolean = true;

implementation

uses
  d_delphi,
  am_map,
  doomdef,
  d_player,
  d_items,
  d_net,
  g_game,
  mt_utils,
  p_tick,
  r_data,
  r_defs,
  r_main,
  tables,
  v_data,
  v_video,
  w_wad,
  z_zone;

const
  STATUSBAR_HEIGHT = 40;

var
  hud_player: Pplayer_t;
  statusbarimage: Ppatch_t;
  WeaponNumOn: array[0..9] of Ppatch_t;
  WeaponNumOff: array[0..9] of Ppatch_t;
  bignums: array[0..9] of Ppatch_t;
  stkeys: array[0..2] of Ppatch_t;
  compass: array[0..7] of Ppatch_t;
  crosshairs: array[0..4] of Ppatch_t;

const
  AMMOIMGNAMES: array[0..Ord(NUMAMMO) - 1] of string = (
    'GUN1A0',
    'ELESA0',
    'FUZSA0',
    'FRESA0',
    'FLASA0',
    'BOMSA0',
    'CDR1A0',
    'MIS2A0',
    'MIS1A0'
  );

var
  ammoimglumps: array[0..Ord(NUMAMMO) - 1] of integer;
  healthimglump: integer;

type
  weaponpos_t = record
    x, y: integer;
  end;

const
  weaponpositions: array[0..9] of weaponpos_t = (
    (x: 0; y: 0),
    (x: 22; y: 19),
    (x: 33; y: 19),
    (x: 44; y: 19),
    (x: 55; y: 19),
    (x: 11; y: 30),
    (x: 22; y: 30),
    (x: 33; y: 30),
    (x: 44; y: 30),
    (x: 55; y: 30)
  );

var
  hud_translation: PByteArray;

procedure MARS_InitHud;
var
  i: integer;
begin
  statusbarimage := W_CacheLumpName('STBAR', PU_STATIC);

  for i := 0 to 9 do
  begin
    WeaponNumOff[i] := W_CacheLumpName('STGNUM' + itoa(i), PU_STATIC);
    WeaponNumOn[i] := W_CacheLumpName('STYSNUM' + itoa(i), PU_STATIC);
    bignums[i] := W_CacheLumpName('WINUM' + itoa(i), PU_STATIC);
  end;

  for i := 0 to 2 do
    stkeys[i] := W_CacheLumpName('STKEYS' + itoa(i + 1), PU_STATIC);

  for i := 0 to 7 do
    compass[i] := W_CacheLumpName('WILV0' + itoa(i), PU_STATIC);

  for i := 0 to 4 do
    crosshairs[i] := W_CacheLumpName('CROSS' + itoa(i), PU_STATIC);

  for i := 0 to Ord(NUMAMMO) - 1 do
    ammoimglumps[i] := W_GetNumForName(AMMOIMGNAMES[i]);

  healthimglump := W_GetNumForName('HSP1A0');

  hud_translation := malloc(256 * SizeOf(Byte));
  for i := 0 to 255 do
    hud_translation[i] := i;
  hud_translation[0] := aprox_black;
end;

procedure MARS_ShutDownHud;
begin
  memfree(Pointer(hud_translation), 256 * SizeOf(Byte));
end;

procedure MARS_HudDrawPatch(const x, y: integer; const patch: Ppatch_t);
begin
  V_DrawPatch(x + patch.leftoffset, y + patch.topoffset, SCN_HUD, patch, false);
end;

procedure MARS_HudDrawCrossHair;
var
  cidx: integer;
  p: Ppatch_t;
begin
  if not drawcrosshair then
    exit;

  if (amstate = am_only) or (amstate = am_overlay) then
    exit;

  if hud_player.playerstate = PST_DEAD then
    exit;

  if hud_player.plinetarget = nil then
    cidx := 0
  else
    cidx := (((leveltime - hud_player.pcrosstic) div 8) mod 4) + 1;

  p := crosshairs[cidx];
  if screenblocks > 10 then
    V_DrawPatch(160, 100, SCN_HUD, p, false)
  else
    V_DrawPatch(160, 100 - STATUSBAR_HEIGHT div 2, SCN_HUD, p, false);
end;

procedure MARS_HudDrawCompass(const x, y: integer);
var
  an: angle_t;
begin
  if hud_player.health <= 0 then
    Exit;

  an := (hud_player.mo.angle - ANG90 - ANG45 div 2) div ANG45;
  if an > 7 then
    an := 0;
  an := 7 - an;

  MARS_HudDrawPatch(x, y, compass[an]);
end;

function MARS_HudDrawBigNumberR(const x, y: integer; const num: integer): integer;
var
  num1: integer;
  xpos, ypos: integer;
  p: Ppatch_t;
begin
  num1 := num;
  if num1 < 0 then
    num1 := 0;

  xpos := x;
  ypos := y;

  // Draw the number (right justified)
  repeat
    p := bignums[num1 mod 10];
    MARS_HudDrawPatch(xpos - p.width, ypos, p);
    xpos := xpos - p.width - 1;
    num1 := num1 div 10;
  until num1 = 0;

  Result := x - xpos;
end;

function MARS_HudDrawBigNumberL(const x, y: integer; const num: integer): integer;
var
  num1: integer;
  xpos, ypos: integer;
  p: Ppatch_t;
  s: string;
  i: integer;
begin
  num1 := num;
  if num1 < 0 then
    num1 := 0;

  xpos := x;
  ypos := y;

  s := itoa(num1);

  // Draw the number (left justified)
  for i := 1 to Length(s) do
  begin
    p := bignums[Ord(s[i]) - Ord('0')];
    MARS_HudDrawPatch(xpos, ypos, p);
    xpos := xpos + p.width + 1;
  end;

  Result := xpos - x;
end;

procedure MARS_HudDrawerSmallHealth;
var
  p: Ppatch_t;
begin
  p := W_CacheLumpNum(healthimglump, PU_STATIC);
  V_DrawPatch(1 + p.leftoffset, 200 - p.height - 1 + p.topoffset, SCN_HUD, p, false);
  MARS_HudDrawBigNumberL(1 + p.width + 1, 200 - bignums[0].height - 1, hud_player.health);
end;

procedure MARS_HudDrawerSmallAmmo;
var
  p: Ppatch_t;
begin
  if weaponinfo[Ord(hud_player.readyweapon)].ammo < NUMAMMO then
  begin
    p := W_CacheLumpNum(ammoimglumps[Ord(weaponinfo[Ord(hud_player.readyweapon)].ammo)], PU_STATIC);
    V_DrawPatch(319 - p.width + p.leftoffset, 200 - p.height - 1 + p.topoffset, SCN_HUD, p, false);
    MARS_HudDrawBigNumberR(319 - p.width - 1, 200 - bignums[0].height - 1, hud_player.ammo[Ord(weaponinfo[Ord(hud_player.readyweapon)].ammo)]);
  end;
end;


procedure MARS_HudDrawerSmall;
begin
  // Draw crosshair
  MARS_HudDrawCrossHair;

  // Health (bottom left)
  MARS_HudDrawerSmallHealth;

  // Ammo (bottom right)
  MARS_HudDrawerSmallAmmo;
end;

procedure MARS_HudDrawerStatusBar;
var
  i: integer;
  x, y: integer;
begin
  // Draw crosshair
  MARS_HudDrawCrossHair;

  // Draw statusbar
  MARS_HudDrawPatch(0, 200 - STATUSBAR_HEIGHT, statusbarimage);

  // Draw weapons
  for i := 1 to 9 do
    if hud_player.weaponowned[i] <> 0 then
    begin
      x := weaponpositions[i].x;
      y := 200 + weaponpositions[i].y - STATUSBAR_HEIGHT;
      if Ord(hud_player.readyweapon) = i then
        MARS_HudDrawPatch(x, y, WeaponNumOn[i])
      else
        MARS_HudDrawPatch(x, y, WeaponNumOff[i]);

      if weaponinfo[Ord(hud_player.readyweapon)].ammo <> am_noammo then
        MARS_HudDrawBigNumberR(100, 200 + 15 - STATUSBAR_HEIGHT, hud_player.ammo[Ord(weaponinfo[Ord(hud_player.readyweapon)].ammo)]);
    end;

  MARS_HudDrawCompass(132, 200 + 7 - STATUSBAR_HEIGHT);

  MARS_HudDrawBigNumberR(292, 200 + 22 - STATUSBAR_HEIGHT, hud_player.mo.health);

  if hud_player.cards[0] then
    MARS_HudDrawPatch(198, 200 + 21 - STATUSBAR_HEIGHT, stkeys[0]);
  if hud_player.cards[1] then
    MARS_HudDrawPatch(209, 200 + 21 - STATUSBAR_HEIGHT, stkeys[1]);
  if hud_player.cards[2] then
    MARS_HudDrawPatch(220, 200 + 21 - STATUSBAR_HEIGHT, stkeys[2]);
end;

procedure MARS_HudDrawer;
var
  oldtr: PByteArray;
begin
  hud_player := @players[consoleplayer];

  if firstinterpolation then
  begin
    // Clear screen
    MT_ZeroMemory(screens[SCN_HUD], 320 * 200);

    oldtr := v_translation;
    v_translation := hud_translation;
    if (amstate = am_only) or (screenblocks <= 10) then
      MARS_HudDrawerStatusBar
    else if screenblocks = 11 then
      MARS_HudDrawerSmall
    else if screenblocks = 12 then
      MARS_HudDrawCrossHair;
    v_translation := oldtr;
  end;

  V_CopyRectTransparent(0, 0, SCN_HUD, 320, 200, 0, 0, SCN_FG, true);
end;

end.
