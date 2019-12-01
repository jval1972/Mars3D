//------------------------------------------------------------------------------
//
//  DelphiStrife: A modified and improved Strife source port for Windows.
//
//  Based on:
//    - Linux Doom by "id Software"
//    - Chocolate Strife by "Simon Howard"
//    - DelphiDoom by "Jim Valavanis"
//
//  Copyright (C) 2004-2016 by Jim Valavanis
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
//   Menu widget stuff, episode selection and such.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_menu;

interface

uses
  d_delphi,
  d_event,
  m_fixed;

//
// MENUS
//

{ Called by main loop, }
{ saves config file and calls I_Quit when user exits. }
{ Even when the menu is not displayed, }
{ this can resize the view and change game parameters. }
{ Does all the real work of the menu interaction. }

function M_Responder(ev: Pevent_t): boolean;

{ Called by main loop, }
{ only used for menu (skull cursor) animation. }
procedure M_Ticker;

{ Called by main loop, }
{ draws the menus directly into the screen buffer. }
procedure M_Drawer;

{ Called by D_DoomMain, }
{ loads the config file. }
procedure M_Init;

{ Called by intro code to force menu up upon a keypress, }
{ does nothing if menu is already up. }
procedure M_StartControlPanel;

var
//
// defaulted values
//
  mouseSensitivity: integer;  // has default

// Show messages has default, 0 = off, 1 = on
  showMessages: integer;

  shademenubackground: boolean;

  menuactive: boolean;

  inhelpscreens: boolean;

var
  menupause: boolean;     // haleyjd 08/29/10: [STRIFE] New global
  menupausetime: integer; // haleyjd 09/04/10: [STRIFE] New global
  menuindialog: boolean;  // haleyjd 09/04/10: ditto

procedure M_ShutDownMenus;

procedure M_InitMenus;

function M_WriteText(x, y: integer; const _string: string; const fraczoom: fixed_t = FRACUNIT): integer;

procedure M_WriteText2(x, y: integer; const _string: string; const fraczoom: fixed_t = FRACUNIT);

procedure M_WriteText3(x, y: integer; const _string: string; fraczoom: fixed_t = FRACUNIT);

function M_StringWidth(const _string: string): integer;

function M_StringWidth2(const _string: string): integer;

function M_StringWidth3(const _string: string): integer;

type
  PmessageRoutine = function(i: integer): pointer;

var
  messageRoutine: PmessageRoutine;

type
  menuitem_t = record
    // 0 = no cursor here, 1 = ok, 2 = arrows ok
    status: smallint;

    name: string;
    cmd: string;

    // choice = menu item #.
    // if status = 2,
    //   choice=0:leftarrow,1:rightarrow
    routine: PmessageRoutine;

    // Yes/No location
    pBoolVal: PBoolean;
    // hotkey in menu
    alphaKey: char;
  end;
  Pmenuitem_t = ^menuitem_t;
  menuitem_tArray = packed array[0..$FFFF] of menuitem_t;
  Pmenuitem_tArray = ^menuitem_tArray;

type
  Pmenu_t = ^menu_t;
  menu_t = record
    numitems: smallint;         // # of menu items
    prevMenu: Pmenu_t;          // previous menu
    menuitems: Pmenuitem_tArray;// menu items
    routine: PProcedure;        // draw routine
    x: smallint;
    y: smallint;                // x,y of menu
    lastOn: smallint;           // last item user was on in menu
    itemheight: integer;
  end;

procedure M_ClearMenus;

function M_DialogDimMsg(x, y: integer; str: string; useyfont: boolean): string;

var
  itemOn: smallint;             // menu item skull is on
// current menudef
  currentMenu: Pmenu_t;

type
//
// DOOM MENU
//
  main_e = (
    mm_newgame,
    mm_options,
    mm_gamefiles,
    mm_readthis,
    mm_quitgame,
    main_end
  );

var
  MainMenu: array[0..5] of menuitem_t;
  MainDef: menu_t;

procedure M_SizeDisplay(choice: integer);

implementation

uses
  deh_main,
  mt_utils,
  doomdef,
  d_englsh,
  am_map,
  c_cmds,
  d_main,
  d_player,
  g_game,
  m_argv,
  m_misc,
  i_system,
  i_threads,
{$IFDEF OPENGL}
  gl_main,
  gl_defs,
  gl_models,
  gl_voxels,
  gl_lightmaps,
  gl_shadows,
  p_setup,
{$ELSE}
  i_video,
  r_batchcolumn,
  r_scale,
  r_slopes, // JVAL: Slopes
{$ENDIF}
  i_mp3,
  i_sound,
  p_mobj_h,
  p_adjust,
  r_aspect,
  r_main,
  r_hires,
  r_lights,
  r_intrpl,
{$IFNDEF OPENGL}
  r_fake3d,
{$ENDIF}
  r_camera,
  r_draw,
  t_main,
  v_data,
  v_video,
  hu_stuff,
  s_sound,
  sounds,
  m_saves,
  z_zone;

var
// temp for screenblocks (0-9)
  m_screensize: integer;

// -1 = no quicksave slot picked!
  quickSaveSlot: integer;

 // 1 = message to be printed
  messageToPrint: integer;
// ...and here is the message string!
  messageString: string;

  messageLastMenuActive: boolean;

// timed message = no input from user
  messageNeedsInput: boolean;


const
  SAVESTRINGSIZE = 24;

var
  gammamsg: array[0..GAMMASIZE - 1] of string;

  cursorname: array[0..7] of string;

// we are going to be entering a savegame string
  saveStringEnter: integer;
  saveSlot: integer;  // which slot to save in
  saveCharIndex: integer; // which char we're editing
// old save description before edit
  saveOldString: string;

const
  CURSORXOFF = -32;
  CURSORYOFF = -5;
  ARROWXOFF = -24;
  ARROWYOFF = -8;
  LINEHEIGHT = 22;
  LINEHEIGHT2 = 12;


var
  savegamestrings: array[0..9] of string;
  endstring: string;

// haleyjd 08/27/10: [STRIFE] skull* stuff changed to cursor* stuff
var
  cursorAnimCounter: smallint;  // skull animation counter
  whichCursor: smallint;        // which skull to draw

//
//      Menu Functions
//
procedure M_DrawThermo(x, y, thermWidth, thermDot: integer);
var
  xx: integer;
  yy: integer;
  i: integer;
begin
  xx := x;
  yy := y + 6;
  V_DrawPatch(xx, yy, SCN_TMP, 'M_THERML', false);
  xx := xx + 8;
  for i := 0 to thermWidth - 1 do
  begin
    V_DrawPatch(xx, yy, SCN_TMP, 'M_THERMM', false);
    xx := xx + 8;
  end;
  V_DrawPatch(xx, yy, SCN_TMP, 'M_THERMR', false);

  V_DrawPatch((x + 8) + thermDot * 8, y + 2, SCN_TMP, 'M_THERMO', false);
end;

procedure M_StartMessage(const _string: string; routine: PmessageRoutine; const input: boolean);
begin
  messageLastMenuActive := menuactive;
  messageToPrint := 1;
  messageString := _string;
  if Assigned(routine) then
    @messageRoutine := @routine
  else
    messageRoutine := nil;
  messageNeedsInput := input;
  menuactive := true;
end;

procedure M_StopMessage;
begin
  menuactive := messageLastMenuActive;
  messageToPrint := 0;
end;

//
// Find string width from hu_font chars
//
function M_StringWidth(const _string: string): integer;
var
  i: integer;
  c: integer;
begin
  result := 0;
  for i := 1 to Length(_string) do
  begin
    c := Ord(toupper(_string[i])) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
      result := result + 4
    else
      result := result + hu_font[c].width;
  end;
end;

//
//      Find string height from hu_font chars
//
function M_StringHeight(const _string: string): integer;
var
  i: integer;
  height: integer;
begin
  height := hu_font[0].height;

  result := height;
  for i := 1 to Length(_string) do
    if _string[i] = #13 then
      result := result + height;
end;

//
//      Write a string using the hu_font
//
function M_WriteText(x, y: integer; const _string: string; const fraczoom: fixed_t = FRACUNIT): integer;
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
begin
  len := Length(_string);
  if len = 0 then
  begin
    result := y;
    exit;
  end;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;

    c := Ord(_string[ch]);
    inc(ch);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + 12 * fraczoom div FRACUNIT;
      continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
    begin
      cx := cx + 4 * fraczoom div FRACUNIT;
      continue;
    end;

    w := hu_font[c].width;
    if (cx + w) > 320 then
      break;
    V_DrawPatchZoomed(cx, cy, SCN_TMP, hu_font[c], false, fraczoom);
    cx := cx + w * fraczoom div FRACUNIT;
  end;
  result := cy + 12;
end;

//
// Find string width from yfont chars
//
function M_StringWidth2(const _string: string): integer;
var
  i: integer;
  c: integer;
begin
  result := 0;
  for i := 1 to Length(_string) do
  begin
    c := Ord(toupper(_string[i])) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
      result := result + 8
    else
      result := result + yfont[c].width;
  end;
end;

procedure M_WriteText2(x, y: integer; const _string: string; const fraczoom: fixed_t = FRACUNIT);
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
begin
  len := Length(_string);
  if len = 0 then
    exit;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;

    c := Ord(_string[ch]);
    inc(ch);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + 24 * fraczoom div FRACUNIT;
      continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
    begin
      cx := cx + 8 * fraczoom div FRACUNIT;
      continue;
    end;

    w := yfont[c].width;
    if (cx + w) > 320 then
      break;
    V_DrawPatchZoomed(cx, cy, SCN_TMP, yfont[c], false, fraczoom);
    cx := cx + w * fraczoom div FRACUNIT;
  end;
end;

procedure M_WriteCenterText2(const s: string; y: integer);
begin
  M_WriteText2((320 - M_StringWidth2(s)) div 2, y, s);
end;

//
// Find string width from yfont chars
//
function M_StringWidth3(const _string: string): integer;
var
  i: integer;
  c: char;
begin
  result := 0;
  for i := 1 to Length(_string) do
  begin
    c := toupper(_string[i]);
    if c = '!' then
      c := Chr(Ord('Z') + 1)
    else if (Ord(c) > Ord('Z')) or (Ord(c) < Ord('A')) then
    begin
      result := result + 12;
      continue;
    end;
    result := result + m_font3[c].width;
  end;
end;

procedure M_WriteText3(x, y: integer; const _string: string; fraczoom: fixed_t = FRACUNIT);
var
  w: integer;
  ch: integer;
  c: char;
  cx: integer;
  cy: integer;
  len: integer;
begin
  fraczoom := FRACUNIT;
  len := Length(_string);
  if len = 0 then
    exit;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;

    c := toupper(_string[ch]);

    inc(ch);

    if c = #0 then
      break;

    if c = #10 then
    begin
      cx := x;
      continue;
    end;

    if c = #13 then
    begin
      cy := cy + 24 * fraczoom div FRACUNIT;
      continue;
    end;

    if c = '!' then
      c := Chr(Ord('Z') + 1)
    else
    begin
      if (Ord(c) > Ord('Z')) or (Ord(c) < Ord('A')) then
      begin
        cx := cx + 12 * fraczoom div FRACUNIT;
        continue;
      end;
    end;

    w := m_font3[c].width;
    if (cx + w) > 320 then
      break;
    V_DrawPatchZoomed(cx, cy, SCN_TMP, m_font3[c], false, fraczoom);
    cx := cx + w * fraczoom div FRACUNIT;
  end;
end;

procedure M_WriteCenterText3(const s: string; y: integer);
begin
  M_WriteText3((320 - M_StringWidth3(s)) div 2, y, s);
end;


//
// M_ClearMenus
//
procedure M_ClearMenus;
begin
  menuactive := false;
  menupause := false;
end;

//
// M_SetupNextMenu
//
procedure M_SetupNextMenu(menudef: Pmenu_t);
begin
  currentMenu := menudef;
  itemOn := currentMenu.lastOn;
end;

//
// MENU DEFINITIONS
//
type
//
// NEW GAME
//
  newgame_e = (
    newg_killthings,
    newg_toorough,
    newg_hurtme,
    newg_violence,
    newg_nightmare,
    newg_end
  );

var
  NewGameMenu: array[0..Ord(newg_end) - 1] of menuitem_t;
  NewDef: menu_t;

type
//
// GAME FILES MENU
//
  gamefiles_e = (
    gf_loadgame,
    gf_savegame,
    gf_end
  );

var
  GameFilesMenu: array[0..Ord(gf_end) - 1] of menuitem_t;
  GameFilesDef: menu_t;


type
//
// OPTIONS MENU
//
  options_e = (
    opt_general,
    opt_display,
    opt_sound,
    opt_compatibility,
    opt_controls,
    opt_system,
    opt_end
  );

var
  OptionsMenu: array[0..Ord(opt_end) - 1] of menuitem_t;
  OptionsDef: menu_t;

// GENERAL MENU
type
  optionsgeneral_e = (
    endgame,
    messages,
    scrnsize,
    option_empty1,
    mousesens,
    option_empty2,
    optgen_end
  );

var
  OptionsGeneralMenu: array[0..Ord(optgen_end) - 1] of menuitem_t;
  OptionsGeneralDef: menu_t;

// DISPLAY MENU
type
  optionsdisplay_e = (
{$IFDEF OPENGL}
    od_opengl,
{$ELSE}
    od_detail,
{$ENDIF}
    od_automap,
    od_appearance,
    od_advanced,
    od_32bitsetup,
    optdisp_end
  );

var
  OptionsDisplayMenu: array[0..Ord(optdisp_end) - 1] of menuitem_t;
  OptionsDisplayDef: menu_t;

// DISPLAY DETAIL MENU
type
  optionsdisplaydetail_e = (
    od_detaillevel,
    od_allowlowdetails,
    od_allowhidetails,
    optdispdetail_end
  );

var
  OptionsDisplayDetailMenu: array[0..Ord(optdispdetail_end) - 1] of menuitem_t;
  OptionsDisplayDetailDef: menu_t;

// DISPLAY APPEARANCE MENU
type
  optionsdisplayappearance_e = (
    od_drawfps,
    od_shademenubackground,
    od_displaydiskbuzyicon,
    optdispappearance_end
  );

var
  OptionsDisplayAppearanceMenu: array[0..Ord(optdispappearance_end) - 1] of menuitem_t;
  OptionsDisplayAppearanceDef: menu_t;

// DISPLAY AUTOMAP MENU
type
  optionsdisplayautomap_e = (
    od_allowautomapoverlay,
    od_allowautomaprotate,
    od_texturedautomap,
    optdispautomap_end
  );

var
  OptionsDisplayAutomapMenu: array[0..Ord(optdispautomap_end) - 1] of menuitem_t;
  OptionsDisplayAutomapDef: menu_t;

// DISPLAY ADVANCED MENU
type
  optionsdisplayadvanced_e = (
    od_fullscreen,
    od_interpolate,
    od_zaxisshift,
{$IFNDEF OPENGL}
    od_usefake3d,
{$ENDIF}
    od_chasecamera,
    od_fixstallhack,
    od_autoadjustmissingtextures,
{$IFNDEF OPENGL}
    od_optimizedcolumnrendering,
    od_optimizedthingsrendering,
    od_precisescalefromglobalangle,
    od_preciseslopedrawing, // JVAL: Slopes
{$ENDIF}
    od_widescreensupport,
    od_excludewidescreenplayersprites,
    optdispadvanced_end
  );

var
  OptionsDisplayAdvancedMenu: array[0..Ord(optdispadvanced_end) - 1] of menuitem_t;
  OptionsDisplayAdvancedDef: menu_t;

// DISPLAY 32 BIT RENDERING MENU
type
  optionsdisplay32bit_e = (
    od_usetransparentsprites,
    od_uselightboost,
    od_forcecolormaps,
    od_32bittexturepaletteeffects,
    od_useexternaltextures,
    od_preferetexturesnamesingamedirectory,
    od_flatfiltering,
    optdisp32bit_end
  );

var
  OptionsDisplay32bitMenu: array[0..Ord(optdisp32bit_end) - 1] of menuitem_t;
  OptionsDisplay32bitDef: menu_t;

{$IFDEF OPENGL}
// DISPLAY OPENGL RENDERING MENU
type
  optionsdisplayopengl_e = (
    od_usefog,
    od_gl_texture_filter_anisotropic,
    od_gl_drawsky,
    od_gl_stencilsky,
    od_gl_renderwireframe,
    od_gl_drawmodels,
    od_gl_smoothmodelmovement,
    od_gl_precachemodeltextures,
    od_gl_drawvoxels,
    od_gl_uselightmaps,
    od_gl_drawshadows,
    od_gl_linear_hud,
    od_gl_add_all_lines,
    od_gl_useglnodesifavailable,
    od_gl_autoloadgwafiles,
    od_gl_screensync,
    optdispopengl_end
  );

var
  OptionsDisplayOpenGLMenu: array[0..Ord(optdispopengl_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLDef: menu_t;
{$ENDIF}


//
// Read This! MENU 1, 2 & 3
//
type
  read_e = (
    rdthsempty1,
    read1_end
  );

var
  ReadMenu1: array[0..0] of menuitem_t;
  ReadDef1: menu_t;

type
  read_e2 = (
    rdthsempty2,
    read2_end
  );

var
  ReadMenu2: array[0..0] of menuitem_t;
  ReadDef2: menu_t;

type
  read_e3 = (
    rdthsempty3,
    read3_end
  );

var
  ReadMenu3: array[0..0] of menuitem_t;
  ReadDef3: menu_t;

type
//
// SOUND MENU
//
  sound_e = (
    snd_volume,
    snd_usemp3,
    snd_preferemp3namesingamedirectory,
    snd_usewav,
    snd_preferewavnamesingamedirectory,
    sound_end
  );

var
  SoundMenu: array[0..Ord(sound_end) - 1] of menuitem_t;
  SoundDef: menu_t;

type
//
// SOUND VOLUME MENU
//
  soundvol_e = (
    sfx_vol,
    sfx_empty1,
    music_vol,
    sfx_empty2,
    voice_vol,
    sfx_empty3,
    soundvol_end
  );

var
  SoundVolMenu: array[0..Ord(soundvol_end) - 1] of menuitem_t;
  SoundVolDef: menu_t;

type
//
// COMPATIBILITY MENU
//
  compatibility_e = (
    cmp_allowplayerjumps,
    cmp_keepcheatsinplayerrebord,
    cmp_spawnrandommonsters,
    cmp_end
  );

var
  CompatibilityMenu: array[0..Ord(cmp_end) - 1] of menuitem_t;
  CompatibilityDef: menu_t;

type
//
// CONTROLS MENU
//
  controls_e = (
    ctrl_usemouse,
    ctrl_invertmouselook,
    ctrl_invertmouseturn,
    ctrl_usejoystic,
    ctrl_autorun,
    ctrl_end
  );

var
  ControlsMenu: array[0..Ord(ctrl_end) - 1] of menuitem_t;
  ControlsDef: menu_t;

type
//
// SYSTEM  MENU
//
  system_e = (
    sys_safemode,
    sys_usemmx,
    sys_criticalcpupriority,
    sys_usemultithread,
    sys_end
  );

var
  SystemMenu: array[0..Ord(sys_end) - 1] of menuitem_t;
  SystemDef: menu_t;

var
  LoadMenu: array[0..Ord(load_end) - 1] of menuitem_t;
  LoadDef: menu_t;
  SaveMenu: array[0..Ord(load_end) - 1] of menuitem_t;
  SaveDef: menu_t;

//
// M_ReadSaveStrings
//  read the strings from the savegame files
//
procedure M_ReadSaveStrings;
var
  i, j, len: integer;
  buf: PByteArray;
  fname: string;
begin
  for i := 0 to Ord(load_end) - 1 do
  begin

    fname := M_SafeFilePath(M_SaveFileName(''), M_MakeStrifeSaveDir(i, '\name'));
    LoadMenu[i].status := 0;
    if fexists(fname) then
    begin
      len := M_ReadFile(fname, pointer(buf));
      if len = 32 then
      begin
        savegamestrings[i] := '';
        for j := 0 to 31 do
          if buf[j] = 0 then
            break
          else
            savegamestrings[i] := savegamestrings[i] + Chr(buf[j]);
        LoadMenu[i].status := 1;
      end;
      Z_Free(buf);
    end;
  end;
end;

//
// Draw border for the savegame description
//
procedure M_DrawSaveLoadBorder(x, y: integer);
var
  i: integer;
begin
  V_DrawPatch(x - 8, y + 7, SCN_TMP, 'M_LSLEFT', false);

  for i := 0 to 23 do
  begin
    V_DrawPatch (x, y + 7, SCN_TMP, 'M_LSCNTR', false);
    x := x + 8;
  end;

  V_DrawPatch(x, y + 7, SCN_TMP, 'M_LSRGHT', false);
end;

//
// M_LoadGame & Cie.
//
procedure M_DrawLoad;
var
  i: integer;
begin
  V_DrawPatch(72, 8, SCN_TMP, 'M_LOADG', false);

  for i := 0 to Ord(load_end) - 1 do
  begin
    M_DrawSaveLoadBorder(LoadDef.x, LoadDef.y + 18 * i);
    M_WriteText(LoadDef.x, LoadDef.y + 18 * i, savegamestrings[i]);
  end;
end;

//
// User wants to load this game
//
procedure M_LoadSelect(choice: integer);
var
  name: string;
begin
  G_WriteSaveName(choice, savegamestrings[choice]);
  M_ToCurr();

  // use safe & portable filepath concatenation for Choco
  name := M_SafeFilePath(M_SaveFileName(''), M_MakeStrifeSaveDir(choice, ''));

  G_ReadCurrent(name);
  quickSaveSlot := choice;
  M_ClearMenus;
end;

//
// Selected from DOOM menu
//
procedure M_LoadGame(choice: integer);
begin
  if netgame then
  begin
    M_StartMessage(LOADNET + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_SetupNextMenu(@LoadDef);
  M_ReadSaveStrings;
end;

//
//  M_SaveGame & Cie.
//
procedure M_DrawSave;
var
  i: integer;
begin
  V_DrawPatch(72, 8, SCN_TMP, 'M_SAVEG', false);
  for i := 0 to Ord(load_end) - 1 do
  begin
    M_DrawSaveLoadBorder(LoadDef.x, LoadDef.y + 18 * i);
    M_WriteText(LoadDef.x, LoadDef.y + 18 * i, savegamestrings[i]);
  end;

  if saveStringEnter <> 0 then
  begin
    i := M_StringWidth(savegamestrings[saveSlot]);
    if (gametic div 18) mod 2 = 0 then
      M_WriteText(LoadDef.x + i, LoadDef.y + LoadDef.itemheight * saveSlot, '_');
  end;
end;

//
// M_Responder calls this when user is finished
//
procedure M_DoSave(slot: integer);
begin
  if slot >= 0 then
  begin
    sendsave := true;
    G_WriteSaveName(slot, savegamestrings[slot]);
    M_ClearMenus;
    quickSaveSlot := slot;
    M_ClearSlot;
    M_FromCurr;
  end
  else
    M_StartMessage(DEH_GetString(QSAVESPOT), nil, false);
end;

//
// User wants to save. Start string input for M_Responder
//
procedure M_SaveSelect(choice: integer);
begin
  // we are going to be intercepting all chars
  saveStringEnter := 1;

  saveSlot := choice;
  quickSaveSlot := choice;
  saveOldString := savegamestrings[choice];
  if savegamestrings[choice] <> '' then
    savegamestrings[choice] := '';
  saveCharIndex := Length(savegamestrings[choice]);
end;

//
// Selected from DOOM menu
//
procedure M_SaveGame(choice: integer);
begin
  // [STRIFE]
  if netgame then
  begin
    // haleyjd 20110211: Hooray for Rogue's awesome multiplayer support...
    M_StartMessage(DEH_GetString('You can''t save a netgame'), nil, false);
    exit;
  end;

  if not usergame then
  begin
    M_StartMessage(SAVEDEAD + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  // haleyjd 20130301: in 1.31, we can choose a slot again.
  M_SetupNextMenu(@SaveDef);
  M_ReadSaveStrings;

end;

//
//      M_QuickSave
//
procedure M_QuickSaveResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_DoSave(quickSaveSlot);
    S_StartSound(nil, Ord(sfx_mtalht)); // [STRIFE] sound
  end;
end;

procedure M_QuickSave;
var
  tempstring: string;
begin
  if netgame then
  begin
    M_StartMessage(DEH_GetString('You can''t save a netgame'), nil, false);
    exit;
  end;

  if not usergame then
  begin
    S_StartSound(nil, Ord(sfx_oof));
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  if quickSaveSlot < 0 then
  begin
    M_StartControlPanel;
    M_ReadSaveStrings;
    M_SetupNextMenu(@SaveDef);
    quickSaveSlot := -2;  // means to pick a slot now
    exit;
  end;

  sprintf(tempstring, QSPROMPT + #13#10 + PRESSYN, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickSaveResponse, true);
end;

//
// M_QuickLoad
//
procedure M_QuickLoadResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_LoadSelect(quickSaveSlot);
    S_StartSound(nil, Ord(sfx_mtalht)); // [STRIFE] sound
  end;
end;

procedure M_QuickLoad;
var
  tempstring: string;
begin
  if netgame then
  begin
    M_StartMessage(QLOADNET + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if quickSaveSlot < 0 then
  begin
    M_StartMessage(QSAVESPOT + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  sprintf(tempstring, QLPROMPT + #13#10 + PRESSYN, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickLoadResponse, true);
end;

//
// Read This Menus
// Had a "quick hack to fix romero bug"
//
procedure M_DrawReadThis1;
begin
  inhelpscreens := true;
  V_PageDrawer(pg_HELP1);
end;

//
// Read This Menus - optional second page.
//
procedure M_DrawReadThis2;
begin
  inhelpscreens := true;
  V_PageDrawer(pg_HELP2);
end;

//
// Read This Menus - third page.
// haleyjd 08/28/10: [STRIFE] New function to draw HELP3.
//
procedure M_DrawReadThis3;
begin
  inhelpscreens := true;
  V_PageDrawer(pg_HELP3);
end;

//
// Change Sfx & Music volumes
//
procedure M_DrawSoundVol;
begin
  V_DrawPatch(60, 34, SCN_TMP, 'M_SVOL', false);

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + LINEHEIGHT * (Ord(sfx_vol) + 1), 16, snd_SfxVolume);

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + LINEHEIGHT * (Ord(music_vol) + 1), 16, snd_MusicVolume);

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + LINEHEIGHT * (Ord(voice_vol) + 1), 16, snd_VoiceVolume);

end;

procedure M_DrawCompatibility;
begin
  M_WriteCenterText3('Compatibility', 48);
end;

procedure M_DrawControls;
begin
  M_WriteCenterText3('Controls', 48);
end;

procedure M_DrawSound;
begin
  M_WriteCenterText3('Sound', 48);
end;

procedure M_DrawSystem;
begin
  M_WriteCenterText3('System', 48);
end;

procedure M_OptionsSound(choice: integer);
begin
  M_SetupNextMenu(@SoundDef);
end;

procedure M_SoundVolume(choice: integer);
begin
  M_SetupNextMenu(@SoundVolDef);
end;

procedure M_OptionsConrols(choice: integer);
begin
  M_SetupNextMenu(@ControlsDef);
end;

procedure M_OptionsCompatibility(choice: integer);
begin
  M_SetupNextMenu(@CompatibilityDef);
end;

procedure M_OptionsSystem(choice: integer);
begin
  M_SetupNextMenu(@SystemDef);
end;

procedure M_OptionsGeneral(choice: integer);
begin
  M_SetupNextMenu(@OptionsGeneralDef);
end;

procedure M_OptionsDisplay(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayDef);
end;

procedure M_OptionsDisplayDetail(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayDetailDef);
end;

procedure M_OptionsDisplayAutomap(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAutomapDef);
end;

procedure M_OptionsDisplayAppearance(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAppearanceDef);
end;

procedure M_OptionsDisplayAdvanced(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAdvancedDef);
end;

procedure M_OptionsDisplay32bit(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplay32bitDef);
end;

{$IFDEF OPENGL}
procedure M_OptionsDisplayOpenGL(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLDef);
end;
{$ENDIF}

procedure M_SfxVol(choice: integer);
begin
  case choice of
    0: if snd_SfxVolume <> 0 then dec(snd_SfxVolume);
    1: if snd_SfxVolume < 15 then inc(snd_SfxVolume);
  end;
  S_SetSfxVolume(snd_SfxVolume);
end;

procedure M_MusicVol(choice: integer);
begin
  case choice of
    0: if snd_MusicVolume <> 0 then dec(snd_MusicVolume);
    1: if snd_MusicVolume < 15 then inc(snd_MusicVolume);
  end;
  S_SetMusicVolume(snd_MusicVolume);
end;

procedure M_VoiceVol(choice: integer);
begin
  case choice of
    0: if snd_VoiceVolume > 0 then dec(snd_VoiceVolume);
    1: if snd_VoiceVolume < 15 then inc(snd_VoiceVolume);
  end;
  S_SetVoiceVolume(snd_VoiceVolume);
end;

//
// M_DrawMainMenu
//
procedure M_DrawMainMenu;
begin
  V_DrawPatch(84, 2, SCN_TMP, 'M_STRIFE', false);
end;

//
// M_NewGame
//
// haleyjd 08/31/10: [STRIFE] Changed M_NEWG -> M_NGAME
//
procedure M_DrawNewGame;
begin
  V_DrawPatch(96, 14, SCN_TMP, DEH_GetSTring('M_NGAME'), false);
  V_DrawPatch(54, 38, SCN_TMP, DEH_GetSTring('M_SKILL'), false);
end;

procedure M_NewGame(choice: integer);
begin
  if netgame and (not demoplayback) then
  begin
    M_StartMessage(SNEWGAME + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_SetupNextMenu(@NewDef);
end;

procedure M_DrawGameFiles;
begin
  M_WriteCenterText3('Game Files', 24);
end;

procedure M_VerifyNightmare(ch: integer);
var
  map: integer;
begin
  if ch <> Ord('y') then
    exit;

  if isdemoversion then
    map := 33
  else
    map := 2;

  G_DeferedInitNew(sk_nightmare, map); // JVAL nightmare become sk_nightmare
  M_ClearMenus;
end;

procedure M_ChooseSkill(choice: integer);
var
  map: integer;
begin
  if choice = Ord(newg_nightmare) then
  begin
    M_StartMessage(SNIGHTMARE + #13#10 + PRESSYN, @M_VerifyNightmare, true);
    exit;
  end;

  if isdemoversion then
    map := 33
  else
    map := 2;

  G_DeferedInitNew(skill_t(choice), map);
  M_ClearMenus;
end;

//
// M_Options
//
var
  msgstatus: array[0..1] of string = ('OFF', 'ON');

procedure M_DrawOptions;
begin
  V_DrawPatch(108, 15, SCN_TMP, 'M_OPTION', false);
end;

procedure M_DrawGeneralOptions;
var
  stmp: string;
begin
  V_DrawPatch(108, 15, SCN_TMP, 'M_OPTION', false);

  sprintf(stmp, 'Messages: %s', [msgstatus[showMessages]]);
  M_WriteText3(OptionsGeneralDef.x + 12, OptionsGeneralDef.y + OptionsGeneralDef.itemheight * Ord(messages), stmp);

  M_DrawThermo(
    OptionsGeneralDef.x + 34, OptionsGeneralDef.y + OptionsGeneralDef.itemheight * (Ord(scrnsize) + 1), 9, m_screensize);

  M_DrawThermo(
    OptionsGeneralDef.x + 32, OptionsGeneralDef.y + OptionsGeneralDef.itemheight * (Ord(mousesens) + 1), 10, mouseSensitivity);

end;

procedure M_DrawDisplayOptions;
begin
  M_WriteCenterText3('Display Options', 15);
end;

var
  colordepths: array[boolean] of string = ('8', '32');

procedure M_DrawDisplayDetailOptions;
var
  stmp: string;
begin
  M_DrawDisplayOptions;

  {$IFDEF OPENGL}
  sprintf(stmp, 'Detail level: %s (%dx%dx32)', [detailStrings[detailLevel], SCREENWIDTH, SCREENHEIGHT]);
  {$ELSE}
  sprintf(stmp, 'Detail level: %s (%dx%dx%s)', [detailStrings[detailLevel], WINDOWWIDTH, WINDOWHEIGHT, colordepths[videomode = vm32bit]]);
  {$ENDIF}
  M_WriteText(OptionsDisplayDetailDef.x, OptionsDisplayDetailDef.y + OptionsDisplayDetailDef.itemheight * Ord(od_detaillevel), stmp);
end;

procedure M_DrawDisplayAppearanceOptions;
begin
  M_DrawDisplayOptions;
end;

procedure M_DrawDisplayAutomapOptions;
begin
  M_DrawDisplayOptions;
end;

procedure M_DrawOptionsDisplayAdvanced;
begin
  M_DrawDisplayOptions;
end;

procedure M_DrawOptionsDisplay32bit;
begin
  M_DrawDisplayOptions;

  M_WriteText(OptionsDisplay32bitDef.x, OptionsDisplay32bitDef.y + OptionsDisplay32bitDef.itemheight * Ord(od_flatfiltering),
    'Flat filtering: ' + flatfilteringstrings[extremeflatfiltering]);
end;

{$IFDEF OPENGL}
procedure M_DrawOptionsDisplayOpenGL;
begin
  M_DrawDisplayOptions;
end;
{$ENDIF}

procedure M_Options(choice: integer);
begin
  M_SetupNextMenu(@OptionsDef);
end;

procedure M_GameFiles(choice: integer);
begin
  M_SetupNextMenu(@GameFilesDef);
end;

//
//      Toggle messages on/off
//
procedure M_ChangeMessages(choice: integer);
begin
  showMessages := 1 - showMessages;

  if showMessages = 0 then
    players[consoleplayer]._message := MSGOFF
  else
    players[consoleplayer]._message := MSGON;

  message_dontfuckwithme := true;

  S_StartSound(nil, Ord(sfx_swtchn));
end;

//
// M_EndGame
//
procedure M_EndGameResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  currentMenu.lastOn := itemOn;
  M_ClearMenus;
  D_StartTitle;
end;

procedure M_CmdEndGame;
begin
  if not usergame then
  begin
    S_StartSound(nil, Ord(sfx_oof));
    exit;
  end;

  if netgame then
  begin
    M_StartMessage(NETEND + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_StartMessage(SENDGAME + #13#10 + PRESSYN, @M_EndGameResponse, true);
  C_ExecuteCmd('closeconsole', '1');
end;

procedure M_EndGame(choice: integer);
begin
  M_CmdEndGame;
end;

//
// M_ReadThis
//
procedure M_ReadThis(choice: integer);
begin
  M_SetupNextMenu(@ReadDef1);
end;

procedure M_ReadThis2(choice: integer);
begin
  M_SetupNextMenu(@ReadDef2);
end;

procedure M_ReadThis3(choice: integer);
begin
  M_SetupNextMenu(@ReadDef3);
end;

procedure M_FinishReadThis(choice: integer);
begin
  M_SetupNextMenu(@MainDef);
end;

//
// M_QuitGame
//

procedure M_CmdQuit;
begin
  if not netgame then
  begin
    S_StartSound(nil, Ord(sfx_swtchn));
    I_WaitVBL(1000);
  end;
  G_Quit;
end;


procedure M_QuitResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  M_CmdQuit;
end;

procedure M_QuitGame(choice: integer);
begin
  sprintf(endstring, '%s'#13#10#13#10 + DOSY, [QUITMSG]);

  M_StartMessage(endstring, @M_QuitResponse, true);
end;

procedure M_ChangeSensitivity(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivity > 0 then
        dec(mouseSensitivity);
    1:
      if mouseSensitivity < 9 then
        inc(mouseSensitivity);
  end;
end;

procedure M_ChangeDetail(choice: integer);
begin
  detailLevel := (detailLevel + 1) mod DL_NUMRESOLUTIONS;

  R_SetViewSize;

  case detailLevel of
    DL_LOWEST:
      players[consoleplayer]._message := DETAILLOWEST;
    DL_LOW:
      players[consoleplayer]._message := DETAILLOW;
    DL_MEDIUM:
      players[consoleplayer]._message := DETAILMED;
    DL_NORMAL:
      players[consoleplayer]._message := DETAILNORM;
    DL_HIRES:
      players[consoleplayer]._message := DETAILHI;
    DL_ULTRARES:
      players[consoleplayer]._message := DETAILULTRA;
  end;

end;

procedure M_ChangeFlatFiltering(choice: integer);
begin
  C_ExecuteCmd('extremeflatfiltering', yesnoStrings[not extremeflatfiltering]);
end;

procedure M_BoolCmd(choice: integer);
var
  s: string;
begin
  s := currentMenu.menuitems[choice].cmd;
  if length(s) = 0 then
    I_Error('M_BoolCmd(): Unknown option');
  C_ExecuteCmd(s, yesnoStrings[not currentMenu.menuitems[choice].pBoolVal^]);
end;

procedure M_SizeDisplay(choice: integer);
begin
  case choice of
    0:
      begin
        if m_screensize > 0 then
        begin
          dec(screenblocks);
          dec(m_screensize);
        end;
      end;
    1:
      begin
        if m_screensize < 8 then
        begin
          inc(screenblocks);
          inc(m_screensize);
        end;
      end;
  end;

  R_SetViewSize;
end;

//
// CONTROL PANEL
//

//
// M_Responder
//
var
  joywait: integer;
  mousewait: integer;
  mmousex: integer;
  mmousey: integer;
  mlastx: integer;
  mlasty: integer;
  m_altdown: boolean = false;

function M_Responder(ev: Pevent_t): boolean;
var
  ch: integer;
  i: integer;
  palette: PByteArray;
begin
  if (ev.data1 = KEY_RALT) or (ev.data1 = KEY_LALT) then
  begin
    m_altdown := ev._type = ev_keydown;
    result := false;
    exit;
  end;

  ch := -1;

  if (ev._type = ev_joystick) and (joywait < I_GetTime) then
  begin
    if ev.data3 < 0 then
    begin
      ch := KEY_UPARROW;
      joywait := I_GetTime + 5;
    end
    else if ev.data3 > 0 then
    begin
      ch := KEY_DOWNARROW;
      joywait := I_GetTime + 5;
    end;

    if ev.data2 < 0 then
    begin
      ch := KEY_LEFTARROW;
      joywait := I_GetTime + 2;
    end
    else if ev.data2 > 0 then
    begin
      ch := KEY_RIGHTARROW;
      joywait := I_GetTime + 2;
    end;

    if ev.data1 and 1 <> 0 then
    begin
      ch := KEY_ENTER;
      joywait := I_GetTime + 5;
    end;
    if ev.data1 and 2 <> 0 then
    begin
      ch := KEY_BACKSPACE;
      joywait := I_GetTime + 5;
    end;
  end
  else if (ev._type = ev_mouse) and (mousewait < I_GetTime) then
  begin
    mmousey := mmousey + ev.data3;
    if mmousey < mlasty - 30 then
    begin
      ch := KEY_DOWNARROW;
      mousewait := I_GetTime + 5;
      mlasty := mlasty - 30;
      mmousey := mlasty;
    end
    else if mmousey > mlasty + 30 then
    begin
      ch := KEY_UPARROW;
      mousewait := I_GetTime + 5;
      mlasty := mlasty + 30;
      mmousey := mlasty;
    end;

    mmousex := mmousex + ev.data2;
    if mmousex < mlastx - 30 then
    begin
      ch := KEY_LEFTARROW;
      mousewait := I_GetTime + 5;
      mlastx := mlastx - 30;
      mmousex := mlastx;
    end
    else if mmousex > mlastx + 30 then
    begin
      ch := KEY_RIGHTARROW;
      mousewait := I_GetTime + 5;
      mlastx := mlastx + 30;
      mmousex := mlastx;
    end;

    if ev.data1 and 1 <> 0 then
    begin
      ch := KEY_ENTER;
      mousewait := I_GetTime + 15;
    end;

    if ev.data1 and 2 <> 0 then
    begin
      ch := KEY_BACKSPACE;
      mousewait := I_GetTime + 15;
    end
  end
  else if ev._type = ev_keydown then
    ch := ev.data1;

  if ch = -1 then
  begin
    result := false;
    exit;
  end;

  // Save Game string input
  if saveStringEnter <> 0 then
  begin
    case ch of
      KEY_BACKSPACE:
        begin
          if saveCharIndex > 0 then
          begin
            dec(saveCharIndex);
            SetLength(savegamestrings[saveSlot], saveCharIndex);
          end;
        end;
      KEY_ESCAPE:
        begin
          saveStringEnter := 0;
          savegamestrings[saveSlot] := saveOldString;
        end;
      KEY_ENTER:
        begin
          saveStringEnter := 0;
          if savegamestrings[saveSlot] <> '' then
            M_DoSave(saveSlot);
        end
    else
      begin
        ch := Ord(toupper(Chr(ch)));
        if ch <> 32 then
        if (ch - Ord(HU_FONTSTART) < 0) or (ch - Ord(HU_FONTSTART) >= HU_FONTSIZE) then
        else
        begin
          if (ch >= 32) and (ch <= 127) and
             (saveCharIndex < SAVESTRINGSIZE - 1) and
             (M_StringWidth(savegamestrings[saveSlot]) < (SAVESTRINGSIZE - 2) * 8) then
          begin
            inc(saveCharIndex);
            savegamestrings[saveSlot] := savegamestrings[saveSlot] + Chr(ch);
          end;
        end;
      end;
    end;
    result := true;
    exit;
  end;

  // Take care of any messages that need input
  if messageToPrint <> 0 then
  begin
    if messageNeedsInput and ( not(
      (ch = Ord(' ')) or (ch = Ord('n')) or (ch = Ord('y')) or (ch = KEY_ESCAPE))) then
    begin
      result := false;
      exit;
    end;

    menuactive := messageLastMenuActive;
    messageToPrint := 0;
    if Assigned(messageRoutine) then
      messageRoutine(ch);

    result := true;

    if I_GameFinished then
      exit;

    menupause := false;
    menuactive := false;
    S_StartSound(nil, Ord(sfx_swtchn));
    exit;
  end;

  // F-Keys
  if not menuactive then
    case ch of
      KEY_MINUS:    // Screen size down
        begin
          if (amstate = am_only) or chat_on then
          begin
            result := false;
            exit;
          end;
          M_SizeDisplay(0);
          S_StartSound(nil, Ord(sfx_stnmov));
          result := true;
          exit;
        end;
      KEY_EQUALS, Ord('+'):   // Screen size up
        begin
          if (amstate = am_only) or chat_on then
          begin
            result := false;
            exit;
          end;
          M_SizeDisplay(1);
          S_StartSound(nil, Ord(sfx_stnmov));
          result := true;
          exit;
        end;
      KEY_F1:      // Help key
        begin
          M_StartControlPanel;
          currentMenu := @ReadDef1;
          itemOn := 0;
          result := true;
          exit;
        end;
      KEY_F2:  // Save
        begin
          M_StartControlPanel;
          S_StartSound(nil, Ord(sfx_swtchn));
          M_SaveGame(0);
          result := true;
          exit;
        end;
      KEY_F3:  // Load
        begin
          M_StartControlPanel;
          S_StartSound(nil, Ord(sfx_swtchn));
          M_LoadGame(0);
          result := true;
          exit;
        end;
      KEY_F4:   // Sound Volume
        begin
          M_StartControlPanel;
          currentMenu := @SoundVolDef;
          itemOn := Ord(sfx_vol);
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
      KEY_F5:   // Detail toggle
        begin
          M_ChangeDetail(0);
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
      KEY_F6:   // Quicksave
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          M_QuickSave;
          result := true;
          exit;
        end;
      KEY_F7:   // End game
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          M_EndGame(0);
          result := true;
          exit;
        end;
      KEY_F8:   // Toggle messages
        begin
          M_ChangeMessages(0);
          result := true;
          exit;
        end;
      KEY_F9:   // Quickload
        begin
          S_StartSound(nil, Ord(sfx_mtalht));
          M_QuickLoad;
          result := true;
          exit;
        end;
      KEY_F10:  // Quit Strife
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          M_QuitGame(0);
          result := true;
          exit;
        end;
      KEY_F11:  // gamma toggle
        begin
          inc(usegamma);
          if usegamma >= GAMMASIZE then
            usegamma := 0;
          players[consoleplayer]._message := gammamsg[usegamma];
          palette := V_ReadPalette(PU_STATIC);
          I_SetPalette(palette);
          V_SetPalette(palette);
          Z_ChangeTag(palette, PU_CACHE);
          result := true;
          exit;
        end;
      KEY_ENTER:
        begin
          if m_altdown then
          begin
          {$IFDEF OPENGL}
            GL_ChangeFullScreen(not fullscreen);
          {$ELSE}
            I_ChangeFullScreen;
          {$ENDIF}
            result := true;
            exit;
          end;
        end;
    end;

  // Pop-up menu?
  if not menuactive then
  begin
    if ch = KEY_ESCAPE then
    begin
      M_StartControlPanel;
      S_StartSound(nil, Ord(sfx_swtchn));
      result := true;
      exit;
    end;
    result := false;
    exit;
  end;

  // Keys usable within menu
  case ch of
    KEY_PAGEUP:
      begin
        itemOn := -1;
        repeat
          inc(itemOn);
          S_StartSound(nil, Ord(sfx_swtchn));
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_PAGEDOWN:
      begin
        itemOn := currentMenu.numitems;
        repeat
          dec(itemOn);
          S_StartSound(nil, Ord(sfx_swtchn));
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_DOWNARROW:
      begin
        repeat
          if itemOn + 1 > currentMenu.numitems - 1 then
            itemOn := 0
          else
            inc(itemOn);
          S_StartSound(nil, Ord(sfx_swtchn));
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_UPARROW:
      begin
        repeat
          if itemOn = 0 then
            itemOn := currentMenu.numitems - 1
          else
            dec(itemOn);
          S_StartSound(nil, Ord(sfx_swtchn));
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_LEFTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          currentMenu.menuitems[itemOn].routine(0);
        end;
        result := true;
        exit;
      end;
    KEY_RIGHTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          currentMenu.menuitems[itemOn].routine(1);
        end;
        result := true;
        exit;
      end;
    KEY_ENTER:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status <> 0) then
        begin
          currentMenu.lastOn := itemOn;
          if currentMenu.menuitems[itemOn].status = 2 then
          begin
            currentMenu.menuitems[itemOn].routine(1); // right arrow
          end
          else
          begin
            currentMenu.menuitems[itemOn].routine(itemOn);
          end;
          S_StartSound(nil, Ord(sfx_swtchn));
        end;
        result := true;
        exit;
      end;
    KEY_ESCAPE:
      begin
        currentMenu.lastOn := itemOn;
        M_ClearMenus;
        S_StartSound(nil, Ord(sfx_swtchn));
        result := true;
        exit;
      end;
    KEY_BACKSPACE:
      begin
        currentMenu.lastOn := itemOn;
        if currentMenu.prevMenu <> nil then
        begin
          currentMenu := currentMenu.prevMenu;
          itemOn := currentMenu.lastOn;
          S_StartSound(nil, Ord(sfx_swtchn));
        end;
        result := true;
        exit;
      end;
  else
    begin
      for i := itemOn + 1 to currentMenu.numitems - 1 do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
      for i := 0 to itemOn do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
    end;
  end;

  result := false;
end;

//
// M_StartControlPanel
//
procedure M_StartControlPanel;
begin
  // intro might call this repeatedly
  if menuactive then
    exit;

  menuactive := true;
  menupause := true;
  currentMenu := @MainDef;// JDC
  itemOn := currentMenu.lastOn; // JDC
end;

//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//

//
// JVAL
// Threaded shades the half screen
//
function M_Thr_ShadeScreen(p: pointer): integer; stdcall;
var
  half: integer;
begin
{$IFDEF OPENGL}
  half := V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) div 2;
  V_ShadeBackground(half, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) - half);
{$ELSE}
  half := SCREENWIDTH * SCREENHEIGHT div 2;
  V_ShadeScreen(SCN_FG, half, SCREENWIDTH * SCREENHEIGHT - half);
{$ENDIF}
  result := 0;
end;

var
  trd_shade: TDThread;

procedure M_MenuShader;
begin
  if (not wipedisplay) and shademenubackground then
  begin
    if usemultithread then
    begin
    // JVAL
      trd_shade.Activate(nil);
      {$IFDEF OPENGL}
      V_ShadeBackground(0, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) div 2);
      {$ELSE}
      V_ShadeScreen(SCN_FG, 0, SCREENWIDTH * SCREENHEIGHT div 2);
      {$ENDIF}
      // Wait for extra thread to terminate.
      trd_shade.Wait;
    end
    else
      {$IFDEF OPENGL}
      V_ShadeBackground;
      {$ELSE}
      V_ShadeScreen(SCN_FG);
      {$ENDIF}
  end;
end;

procedure M_FinishUpdate(const height: integer);
begin
  // JVAL
  // Menu is no longer drawn to primary surface,
  // Instead we use SCN_TMP and after the drawing we blit to primary surface
  if inhelpscreens then
  begin
    V_CopyRectTransparent(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
    inhelpscreens := false;
  end
  else
  begin
    M_MenuShader;
    V_CopyRectTransparent(0, 0, SCN_TMP, 320, height, 0, 0, SCN_FG, true);
  end;
end;

procedure M_Drawer;
var
  i: integer;
  max: integer;
  _string: string;
  len: integer;
  x, y: integer;
  mheight: integer;
begin
  // Horiz. & Vertically center string and print it.
  if messageToPrint <> 0 then
  begin

    mheight := M_StringHeight(messageString);
    y := (200 - mheight) div 2;
    mheight := y + mheight + 20;
    if mheight < 132 then
      mheight := 132;

    MT_ZeroMemory(screens[SCN_TMP], 320 * mheight);

    len := Length(messageString);
    _string := '';
    for i := 1 to len do
    begin
      if messageString[i] = #13 then
        y := y + hu_font[0].height
      else if messageString[i] = #10 then
      begin
        x := (320 - M_StringWidth(_string)) div 2;
        M_WriteText(x, y, _string);
        _string := '';
      end
      else
        _string := _string + messageString[i];
    end;
    if _string <> '' then
    begin
      x := (320 - M_StringWidth(_string)) div 2;
      y := y + hu_font[0].height;
      M_WriteText(x, y, _string);
    end;

    M_FinishUpdate(mheight);
    exit;
  end;

  if not menuactive then
    exit;

  MT_ZeroMemory(screens[SCN_TMP], 320 * 200);

  if Assigned(currentMenu.routine) then
    currentMenu.routine; // call Draw routine

  // DRAW MENU
  x := currentMenu.x;
  y := currentMenu.y;
  max := currentMenu.numitems;

  for i := 0 to max - 1 do
  begin
    _string := currentMenu.menuitems[i].name;
    if _string <> '' then
    begin
      if _string[1] = '@' then // Draw text
      begin
        delete(_string, 1, 1);
        M_WriteText(x, y, _string, 2 * FRACUNIT);
      end
      else if _string[1] = '%' then // Draw center big text
      begin
        delete(_string, 1, 1);
        M_WriteCenterText3(_string, y);
      end
      else if _string[1] = '/' then // Draw not centered big text
      begin
        delete(_string, 1, 1);
        M_WriteText3(x, y, _string);
      end
      else if _string[1] = '!' then // Draw small text with Yes/No
      begin
        delete(_string, 1, 1);
        if currentMenu.menuitems[i].pBoolVal <> nil then
          M_WriteText(x, y, _string + ': ' + yesnoStrings[currentMenu.menuitems[i].pBoolVal^])
        else
          M_WriteText(x, y, _string);
      end
      else // Else name holds the patch name of the menu item
        V_DrawPatch(x, y, SCN_TMP,
          currentMenu.menuitems[i].name, false);
    end;
    y := y + currentMenu.itemheight;
  end;

  if currentMenu.itemheight <= LINEHEIGHT2 then
    V_DrawPatch(x + ARROWXOFF, currentMenu.y + ARROWYOFF + itemOn * currentMenu.itemheight, SCN_TMP,
      cursorname[whichCursor], false)
  else
    // DRAW SKULL
    V_DrawPatch(x + CURSORXOFF, currentMenu.y + CURSORYOFF + itemOn * currentMenu.itemheight, SCN_TMP,
      cursorname[whichCursor], false);

  M_FinishUpdate(200);
end;

//
// M_Ticker
//
procedure M_Ticker;
begin
  dec(cursorAnimCounter);
  if cursorAnimCounter <= 0 then
  begin
    whichCursor := (whichCursor + 1) mod 8;
    cursorAnimCounter := 5;
  end;
end;

procedure M_CmdSetupNextMenu(menudef: Pmenu_t);
begin
  menuactive := true;
  if (menudef = @LoadDef) or (menudef = @SaveDef) then
    M_ReadSaveStrings;
  M_SetupNextMenu(menudef);
  C_ExecuteCmd('closeconsole');
end;

procedure M_CmdMenuMainDef;
begin
  M_CmdSetupNextMenu(@MainDef);
end;

procedure M_CmdMenuNewDef;
begin
  M_CmdSetupNextMenu(@NewDef);
end;

procedure M_CmdMenuOptionsDef;
begin
  M_CmdSetupNextMenu(@OptionsDef);
end;

procedure M_CmdMenuOptionsGeneralDef;
begin
  M_CmdSetupNextMenu(@OptionsGeneralDef);
end;

procedure M_CmdMenuOptionsDisplayDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayDef);
end;

procedure M_CmdMenuOptionsDisplayDetailDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayDetailDef);
end;

procedure M_CmdMenuOptionsDisplayAppearanceDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayAppearanceDef);
end;

procedure M_CmdMenuOptionsDisplayAdvancedDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayAdvancedDef);
end;

procedure M_CmdMenuOptionsDisplay32bitDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplay32bitDef);
end;

{$IFDEF OPENGL}
procedure M_CmdOptionsDisplayOpenGL;
begin
  M_CmdSetupNextMenu(@OptionsDisplayOpenGLDef);
end;
{$ENDIF}

procedure M_CmdMenuSoundDef;
begin
  M_CmdSetupNextMenu(@SoundDef);
end;

procedure M_CmdMenuSoundVolDef;
begin
  M_CmdSetupNextMenu(@SoundVolDef);
end;

procedure M_CmdMenuCompatibilityDef;
begin
  M_CmdSetupNextMenu(@CompatibilityDef);
end;

procedure M_CmdMenuControlsDef;
begin
  M_CmdSetupNextMenu(@ControlsDef);
end;

procedure M_CmdMenuSystemDef;
begin
  M_CmdSetupNextMenu(@SystemDef);
end;

procedure M_CmdMenuLoadDef;
begin
  M_CmdSetupNextMenu(@LoadDef);
end;

procedure M_CmdMenuSaveDef;
begin
  M_CmdSetupNextMenu(@SaveDef);
end;

procedure M_CmdMenuGameFiles;
begin
  M_CmdSetupNextMenu(@GameFilesDef);
end;

//
// M_Init
//
procedure M_Init;
begin
  currentMenu := @MainDef;
  menuactive := false;
  itemOn := currentMenu.lastOn;
  whichCursor := 0;
  m_screensize := screenblocks - 4;
  messageToPrint := 0;
  messageString := '';
  messageLastMenuActive := menuactive;
  quickSaveSlot := -1;

  // Here we could catch other version dependencies,
  //  like five episodes extended version.

  C_AddCmd('exit, quit', @M_CmdQuit);
  C_AddCmd('halt', @I_Quit);
  C_AddCmd('set', @Cmd_Set);
  C_AddCmd('get', @Cmd_Get);
  C_AddCmd('typeof', @Cmd_TypeOf);
  C_AddCmd('endgame', @M_CmdEndGame);
  C_AddCmd('defaults, setdefaults', @M_SetDefaults);
  C_AddCmd('default, setdefault', @M_SetDefaults);
  C_AddCmd('menu_main', @M_CmdMenuMainDef);
  C_AddCmd('menu_newgame, menu_new', @M_CmdMenuNewDef);
  C_AddCmd('menu_options', @M_CmdMenuOptionsDef);
  C_AddCmd('menu_optionsgeneral, menu_generaloptions', @M_CmdMenuOptionsGeneralDef);
  C_AddCmd('menu_optionsdisplay, menu_displayoptions, menu_display', @M_CmdMenuOptionsDisplayDef);
{$IFDEF OPENGL}
  C_AddCmd('menu_optionsdisplayopengl, menu_optionsopengl, menu_opengl', @M_CmdOptionsDisplayOpenGL);
{$ELSE}
  C_AddCmd('menu_optionsdisplaydetail, menu_displaydetailoptions', @M_CmdMenuOptionsDisplayDetailDef);
{$ENDIF}
  C_AddCmd('menu_optionsdisplayappearence, menu_displayappearenceoptions, menu_displayappearence', @M_CmdMenuOptionsDisplayAppearanceDef);
  C_AddCmd('menu_optionsdisplayadvanced, menu_displayadvancedoptions, menu_displayadvanced', @M_CmdMenuOptionsDisplayAdvancedDef);
  C_AddCmd('menu_optionsdisplay32bit, menu_display32bitoptions, menu_display32bit', @M_CmdMenuOptionsDisplay32bitDef);
  C_AddCmd('menu_optionssound, menu_soundoptions, menu_sound', @M_CmdMenuSoundDef);
  C_AddCmd('menu_optionssoundvol, menu_soundvoloptions, menu_soundvol', @M_CmdMenuSoundVolDef);
  C_AddCmd('menu_optionscompatibility, menu_compatibilityoptions, menu_compatibility', @M_CmdMenuCompatibilityDef);
  C_AddCmd('menu_optionscontrols, menu_controlsoptions, menu_controls', @M_CmdMenuControlsDef);
  C_AddCmd('menu_optionssystem, menu_systemoptions, menu_system', @M_CmdMenuSystemDef);
  C_AddCmd('menu_load, menu_loadgame', @M_CmdMenuLoadDef);
  C_AddCmd('menu_save, menu_savegame', @M_CmdMenuSaveDef);
  C_AddCmd('menu_gamefiles', @M_CmdMenuGameFiles);
end;

procedure M_ShutDownMenus;
begin
  trd_shade.Free;
end;

procedure M_InitMenus;
var
  i: integer;
  pmi: Pmenuitem_t;
begin
  trd_shade := TDThread.Create(M_Thr_ShadeScreen);

////////////////////////////////////////////////////////////////////////////////
//gammamsg
  gammamsg[0] := GAMMALVL0;
  gammamsg[1] := GAMMALVL1;
  gammamsg[2] := GAMMALVL2;
  gammamsg[3] := GAMMALVL3;
  gammamsg[4] := GAMMALVL4;

////////////////////////////////////////////////////////////////////////////////
//cursorName
  cursorName[0] := 'M_CURS1';
  cursorName[1] := 'M_CURS2';
  cursorName[2] := 'M_CURS3';
  cursorName[3] := 'M_CURS4';
  cursorName[4] := 'M_CURS5';
  cursorName[5] := 'M_CURS6';
  cursorName[6] := 'M_CURS7';
  cursorName[7] := 'M_CURS8';

////////////////////////////////////////////////////////////////////////////////
// MainMenu
  pmi := @MainMenu[0];
  pmi.status := 1;
  pmi.name := '/New Game';
  pmi.cmd := '';
  pmi.routine := @M_NewGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'n';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Options';
  pmi.cmd := '';
  pmi.routine := @M_Options;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Game Files';
  pmi.cmd := '';
  pmi.routine := @M_GameFiles;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'g';

  // Another hickup with Special edition.
  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Help!';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Quit Game';
  pmi.cmd := '';
  pmi.routine := @M_QuitGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'q';

////////////////////////////////////////////////////////////////////////////////
//MainDef
  MainDef.numitems := Ord(main_end);
  MainDef.prevMenu := nil;
  MainDef.menuitems := Pmenuitem_tArray(@MainMenu);
  MainDef.routine := @M_DrawMainMenu;  // draw routine
  MainDef.x := 80;
  MainDef.y := 56;
  MainDef.lastOn := 0;
  MainDef.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//GameFilesMenu
  pmi := @GameFilesMenu[0];
  pmi.status := 1;
  pmi.name := '%Load Game';
  pmi.cmd := '';
  pmi.routine := @M_LoadGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '%Save Game';
  pmi.cmd := '';
  pmi.routine := @M_SaveGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  GameFilesDef.numitems := Ord(gf_end); // # of menu items
  GameFilesDef.prevMenu := @MainDef; // previous menu
  GameFilesDef.menuitems := Pmenuitem_tArray(@GameFilesMenu);  // menu items
  GameFilesDef.routine := @M_DrawGameFiles;  // draw routine
  GameFilesDef.x := 80;
  GameFilesDef.y := 56; // x,y of menu
  GameFilesDef.lastOn := Ord(gf_loadgame); // last item user was on in menu
  GameFilesDef.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//NewGameMenu
  pmi := @NewGameMenu[0];
  pmi.status := 1;
  pmi.name := 'M_JKILL';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '1';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'M_ROUGH';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '2';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'M_HURT';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'M_ULTRA';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '4';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'M_NMARE';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '5';

////////////////////////////////////////////////////////////////////////////////
//NewDef
  NewDef.numitems := Ord(newg_end); // # of menu items
  NewDef.prevMenu := @MainDef; // previous menu
  NewDef.menuitems := Pmenuitem_tArray(@NewGameMenu);  // menu items
  NewDef.routine := @M_DrawNewGame;  // draw routine
  NewDef.x := 48;
  NewDef.y := 63; // x,y of menu
  NewDef.lastOn := Ord(newg_toorough); // lastOn - haleyjd [STRIFE]: default to skill 1
  NewDef.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//OptionsMenu
  pmi := @OptionsMenu[0];
  pmi.status := 1;
  pmi.name := '/General';
  pmi.cmd := '';
  pmi.routine := @M_OptionsGeneral;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Display';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Sound';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSound;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Compatibility';
  pmi.cmd := '';
  pmi.routine := @M_OptionsCompatibility;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Controls';
  pmi.cmd := '';
  pmi.routine := @M_OptionsConrols;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/System';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSystem;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDef
  OptionsDef.numitems := Ord(opt_end); // # of menu items
  OptionsDef.prevMenu := @MainDef; // previous menu
  OptionsDef.menuitems := Pmenuitem_tArray(@OptionsMenu);  // menu items
  OptionsDef.routine := @M_DrawOptions;  // draw routine
  OptionsDef.x := 80;
  OptionsDef.y := 56; // x,y of menu
  OptionsDef.lastOn := 0; // last item user was on in menu
  OptionsDef.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//OptionsGeneralMenu
  pmi := @OptionsGeneralMenu[0];
  pmi.status := 1;
  pmi.name := '%End Game';
  pmi.cmd := '';
  pmi.routine := @M_EndGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '%';  // Messages
  pmi.cmd := '';
  pmi.routine := @M_ChangeMessages;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '%Screen Size';
  pmi.cmd := '';
  pmi.routine := @M_SizeDisplay;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '%Mouse';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//OptionsGeneralDef
  OptionsGeneralDef.numitems := Ord(optgen_end); // # of menu items
  OptionsGeneralDef.prevMenu := @OptionsDef; // previous menu
  OptionsGeneralDef.menuitems := Pmenuitem_tArray(@OptionsGeneralMenu);  // menu items
  OptionsGeneralDef.routine := @M_DrawGeneralOptions;  // draw routine
  OptionsGeneralDef.x := 40;
  OptionsGeneralDef.y := 56; // x,y of menu
  OptionsGeneralDef.lastOn := 0; // last item user was on in menu
  OptionsGeneralDef.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayMenu
  pmi := @OptionsDisplayMenu[0];
  pmi.status := 1;
{$IFDEF OPENGL}
  pmi.name := '/OpenGL';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGL;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';
{$ELSE}
  pmi.name := '/Detail';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayDetail;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';
{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Automap';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAutomap;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Appearance';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAppearance;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/Advanced';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAdvanced;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '/True Color';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay32bit;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDef
  OptionsDisplayDef.numitems := Ord(optdisp_end); // # of menu items
  OptionsDisplayDef.prevMenu := @OptionsDef; // previous menu
  OptionsDisplayDef.menuitems := Pmenuitem_tArray(@OptionsDisplayMenu);  // menu items
  OptionsDisplayDef.routine := @M_DrawDisplayOptions;  // draw routine
  OptionsDisplayDef.x := 48;
  OptionsDisplayDef.y := 63; // x,y of menu
  OptionsDisplayDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDef.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailMenu
  pmi := @OptionsDisplayDetailMenu[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeDetail;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Low details';
  pmi.cmd := 'allowlowdetails';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowlowdetails;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!High details';
  pmi.cmd := 'allowhidetails';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowhidetails;
  pmi.alphaKey := 'h';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailDef
  OptionsDisplayDetailDef.numitems := Ord(optdispdetail_end); // # of menu items
  OptionsDisplayDetailDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayDetailDef.menuitems := Pmenuitem_tArray(@OptionsDisplayDetailMenu);  // menu items
  OptionsDisplayDetailDef.routine := @M_DrawDisplayDetailOptions;  // draw routine
  OptionsDisplayDetailDef.x := 30;
  OptionsDisplayDetailDef.y := 40; // x,y of menu
  OptionsDisplayDetailDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDetailDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAutomapMenu
  pmi := @OptionsDisplayAutomapMenu[0];
  pmi.status := 1;
  pmi.name := '!Allow automap overlay';
  pmi.cmd := 'allowautomapoverlay';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowautomapoverlay;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow automap rotation';
  pmi.cmd := 'allowautomaprotate';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowautomaprotate;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Textured Automap';
  pmi.cmd := 'texturedautomap';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @texturedautomap;
  pmi.alphaKey := 't';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAutomapDef
  OptionsDisplayAutomapDef.numitems := Ord(optdispautomap_end); // # of menu items
  OptionsDisplayAutomapDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAutomapDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAutomapMenu);  // menu items
  OptionsDisplayAutomapDef.routine := @M_DrawDisplayAutomapOptions;  // draw routine
  OptionsDisplayAutomapDef.x := 30;
  OptionsDisplayAutomapDef.y := 40; // x,y of menu
  OptionsDisplayAutomapDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAutomapDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAppearanceMenu
  pmi := @OptionsDisplayAppearanceMenu[0];
  pmi.status := 1;
  pmi.name := '!Display fps';
  pmi.cmd := 'drawfps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @drawfps;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Shade menu background';
  pmi.cmd := 'shademenubackground';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @shademenubackground;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display disk buzy icon';
  pmi.cmd := 'displaydiskbusyicon';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @displaydiskbusyicon;
  pmi.alphaKey := 'b';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAppearanceDef
  OptionsDisplayAppearanceDef.numitems := Ord(optdispappearance_end); // # of menu items
  OptionsDisplayAppearanceDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAppearanceDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAppearanceMenu);  // menu items
  OptionsDisplayAppearanceDef.routine := @M_DrawDisplayAppearanceOptions;  // draw routine
  OptionsDisplayAppearanceDef.x := 30;
  OptionsDisplayAppearanceDef.y := 40; // x,y of menu
  OptionsDisplayAppearanceDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAppearanceDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedMenu
  pmi := @OptionsDisplayAdvancedMenu[0];
  pmi.status := 1;
  pmi.name := '!Fullscreen';
  pmi.cmd := 'fullscreen';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @fullscreen;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Interpolate';
  pmi.cmd := 'interpolate';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @interpolate;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Z-Axis Shift';
  pmi.cmd := 'zaxisshift';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @zaxisshift;
  pmi.alphaKey := 'z';

{$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!True 3d emulation';
  pmi.cmd := 'usefake3d';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usefake3d;
  pmi.alphaKey := 'e';
{$ENDIF}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Chase camera';
  pmi.cmd := 'chasecamera';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @chasecamera;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Stretch to fix memory stall';
  pmi.cmd := 'fixstallhack';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @fixstallhack;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Auto-adjust missing textures';
  pmi.cmd := 'autoadjustmissingtextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autoadjustmissingtextures;
  pmi.alphaKey := 'a';

{$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Optimized column rendering';
  pmi.cmd := 'optimizedcolumnrendering';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @optimizedcolumnrendering;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Optimized things rendering';
  pmi.cmd := 'optimizedthingsrendering';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @optimizedthingsrendering;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Precise ScaleFromGlobalAngle';
  pmi.cmd := 'precisescalefromglobalangle';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @precisescalefromglobalangle;
  pmi.alphaKey := 'p';

  // JVAL: Slopes
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Precise but slow slope drawing';
  pmi.cmd := 'preciseslopedrawing';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preciseslopedrawing;
  pmi.alphaKey := 's';

{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Widescreen support';
  pmi.cmd := 'widescreensupport';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @widescreensupport;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Player Sprites Stretch';
  pmi.cmd := 'excludewidescreenplayersprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @excludewidescreenplayersprites;
  pmi.alphaKey := 'p';
  
////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedDef
  OptionsDisplayAdvancedDef.numitems := Ord(optdispadvanced_end); // # of menu items
  OptionsDisplayAdvancedDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAdvancedDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAdvancedMenu);  // menu items
  OptionsDisplayAdvancedDef.routine := @M_DrawOptionsDisplayAdvanced;  // draw routine
  OptionsDisplayAdvancedDef.x := 30;
  OptionsDisplayAdvancedDef.y := 40; // x,y of menu
  OptionsDisplayAdvancedDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAdvancedDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplay32bitMenu
  pmi := @OptionsDisplay32bitMenu[0];
  pmi.status := 1;
  pmi.name := '!Transparent sprites';
  pmi.cmd := 'usetransparentsprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usetransparentsprites;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Light effects';
  pmi.cmd := 'uselightboost';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @uselightboost;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use 32 bit colormaps';
  pmi.cmd := 'forcecolormaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @forcecolormaps;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!32 bit palette effect simulation';
  pmi.cmd := '32bittexturepaletteeffects';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @dc_32bittexturepaletteeffects;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external textures';
  pmi.cmd := 'useexternaltextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useexternaltextures;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search texture paths in PK3';
  pmi.cmd := 'preferetexturesnamesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferetexturesnamesingamedirectory;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeFlatFiltering;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedDef
  OptionsDisplay32bitDef.numitems := Ord(optdisp32bit_end); // # of menu items
  OptionsDisplay32bitDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplay32bitDef.menuitems := Pmenuitem_tArray(@OptionsDisplay32bitMenu);  // menu items
  OptionsDisplay32bitDef.routine := @M_DrawOptionsDisplay32bit;  // draw routine
  OptionsDisplay32bitDef.x := 30;
  OptionsDisplay32bitDef.y := 40; // x,y of menu
  OptionsDisplay32bitDef.lastOn := 0; // last item user was on in menu
  OptionsDisplay32bitDef.itemheight := LINEHEIGHT2;

{$IFDEF OPENGL}
////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLMenu
  pmi := @OptionsDisplayOpenGLMenu[0];
  pmi.status := 1;
  pmi.name := '!Use fog';
  pmi.cmd := 'use_fog';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @use_fog;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Anisotropic texture filtering';
  pmi.cmd := 'gl_texture_filter_anisotropic';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_texture_filter_anisotropic;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw Sky';
  pmi.cmd := 'gl_drawsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawsky;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use stencil buffer for sky';
  pmi.cmd := 'gl_stencilsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_stencilsky;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Render wireframe';
  pmi.cmd := 'gl_renderwireframe';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_renderwireframe;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw models instead of sprites';
  pmi.cmd := 'gl_drawmodels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawmodels;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Smooth model movement';
  pmi.cmd := 'gl_smoothmodelmovement';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_smoothmodelmovement;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Precache model textures';
  pmi.cmd := 'gl_precachemodeltextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_precachemodeltextures;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw voxels instead of sprites';
  pmi.cmd := 'gl_drawvoxels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawvoxels;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use lightmaps';
  pmi.cmd := 'gl_uselightmaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_uselightmaps;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw shadows';
  pmi.cmd := 'gl_drawshadows';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawshadows;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Linear HUD filtering';
  pmi.cmd := 'gl_linear_hud';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_linear_hud;
  pmi.alphaKey := 'h';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw all linedefs';
  pmi.cmd := 'gl_add_all_lines';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_add_all_lines;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use GL_NODES if available';
  pmi.cmd := 'useglnodesifavailable';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useglnodesifavailable;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Automatically load GWA files';
  pmi.cmd := 'autoloadgwafiles';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autoloadgwafiles;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Limit framerate to screen syncronization';
  pmi.cmd := 'gl_screensync';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_screensync;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLDef
  OptionsDisplayOpenGLDef.numitems := Ord(optdispopengl_end); // # of menu items
  OptionsDisplayOpenGLDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayOpenGLDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLMenu);  // menu items
  OptionsDisplayOpenGLDef.routine := @M_DrawOptionsDisplayOpenGL;  // draw routine
  OptionsDisplayOpenGLDef.x := 30;
  OptionsDisplayOpenGLDef.y := 38; // x,y of menu
  OptionsDisplayOpenGLDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLDef.itemheight := LINEHEIGHT2;
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//ReadMenu1
  pmi := @ReadMenu1[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis2;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef1
  ReadDef1.numitems := Ord(read1_end); // # of menu items
  ReadDef1.prevMenu := @MainDef; // previous menu
  ReadDef1.menuitems := Pmenuitem_tArray(@ReadMenu1);  // menu items
  ReadDef1.routine := @M_DrawReadThis1;  // draw routine
  ReadDef1.x := 310;
  ReadDef1.y := 175; // x,y of menu
  ReadDef1.lastOn := 0; // last item user was on in menu
  ReadDef1.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//ReadMenu2
  pmi := @ReadMenu2[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis3;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef2
  ReadDef2.numitems := Ord(read2_end); // # of menu items
  ReadDef2.prevMenu := @ReadDef1; // previous menu
  ReadDef2.menuitems := Pmenuitem_tArray(@ReadMenu2);  // menu items
  ReadDef2.routine := @M_DrawReadThis2;  // draw routine
  ReadDef2.x := 310;
  ReadDef2.y := 175; // x,y of menu
  ReadDef2.lastOn := 0; // last item user was on in menu
  ReadDef2.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//ReadMenu3
  pmi := @ReadMenu3[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_FinishReadThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef3
  ReadDef3.numitems := Ord(read3_end); // # of menu items
  ReadDef3.prevMenu := @ReadDef2; // previous menu
  ReadDef3.menuitems := Pmenuitem_tArray(@ReadMenu3);  // menu items
  ReadDef3.routine := @M_DrawReadThis3;  // draw routine
  ReadDef3.x := 310;
  ReadDef3.y := 175; // x,y of menu
  ReadDef3.lastOn := 0; // last item user was on in menu
  ReadDef3.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//SoundMenu
  pmi := @SoundMenu[0];
  pmi.status := 1;
  pmi.name := '!Volume Control';
  pmi.cmd := '';
  pmi.routine := @M_SoundVolume;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external MP3 files';
  pmi.cmd := 'usemp3';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemp3;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search MP3 paths in PK3';
  pmi.cmd := 'preferemp3namesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferemp3namesingamedirectory;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external WAV files';
  pmi.cmd := 'useexternalwav';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useexternalwav;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search WAV paths in PK3';
  pmi.cmd := 'preferewavnamesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferewavnamesingamedirectory;
  pmi.alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//SoundDef
  SoundDef.numitems := Ord(sound_end); // # of menu items
  SoundDef.prevMenu := @OptionsDef; // previous menu
  SoundDef.menuitems := Pmenuitem_tArray(@SoundMenu);  // menu items
  SoundDef.routine := @M_DrawSound;  // draw routine
  SoundDef.x := 32;
  SoundDef.y := 68; // x,y of menu
  SoundDef.lastOn := 0; // last item user was on in menu
  SoundDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//SoundVolMenu
  pmi := @SoundVolMenu[0];
  pmi.status := 2;
  pmi.name := '%SFX VOLUME';
  pmi.cmd := '';
  pmi.routine := @M_SfxVol;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '%MUSIC VOLUME';
  pmi.cmd := '';
  pmi.routine := @M_MusicVol;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '%VOICE VOLUME';
  pmi.cmd := '';
  pmi.routine := @M_VoiceVol;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//SoundVolDef
  SoundVolDef.numitems := Ord(soundvol_end); // # of menu items
  SoundVolDef.prevMenu := @SoundDef; // previous menu
  SoundVolDef.menuitems := Pmenuitem_tArray(@SoundVolMenu);  // menu items
  SoundVolDef.routine := @M_DrawSoundVol;  // draw routine
  SoundVolDef.x := 80;
  SoundVolDef.y := 64; // x,y of menu
  SoundVolDef.lastOn := 0; // last item user was on in menu
  SoundVolDef.itemheight := LINEHEIGHT;

////////////////////////////////////////////////////////////////////////////////
//CompatibilityMenu
  pmi := @CompatibilityMenu[0];
  pmi.status := 1;
  pmi.name := '!Allow player jumps';
  pmi.cmd := 'allowplayerjumps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowplayerjumps;
  pmi.alphaKey := 'j';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Keep cheats when reborn';
  pmi.cmd := 'keepcheatsinplayerreborn';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @keepcheatsinplayerreborn;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Spawn random monsters';
  pmi.cmd := 'spawnrandommonsters';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @spawnrandommonsters;
  pmi.alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//CompatibilityDef
  CompatibilityDef.numitems := Ord(cmp_end); // # of menu items
  CompatibilityDef.prevMenu := @OptionsDef; // previous menu
  CompatibilityDef.menuitems := Pmenuitem_tArray(@CompatibilityMenu);  // menu items
  CompatibilityDef.routine := @M_DrawCompatibility;  // draw routine
  CompatibilityDef.x := 32;
  CompatibilityDef.y := 68; // x,y of menu
  CompatibilityDef.lastOn := 0; // last item user was on in menu
  CompatibilityDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//ControlsMenu
  pmi := @ControlsMenu[0];
  pmi.status := 1;
  pmi.name := '!Use mouse';
  pmi.cmd := 'use_mouse';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemouse;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Invert mouse up/down look';
  pmi.cmd := 'invertmouselook';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @invertmouselook;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Invert mouse turn left/right';
  pmi.cmd := 'invertmouseturn';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @invertmouseturn;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use joystic';
  pmi.cmd := 'use_joystick';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usejoystick;
  pmi.alphaKey := 'j';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Always run';
  pmi.cmd := 'autorunmode';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autorunmode;
  pmi.alphaKey := 'a';

////////////////////////////////////////////////////////////////////////////////
//ControlsDef
  ControlsDef.numitems := Ord(ctrl_end); // # of menu items
  ControlsDef.prevMenu := @OptionsDef; // previous menu
  ControlsDef.menuitems := Pmenuitem_tArray(@ControlsMenu);  // menu items
  ControlsDef.routine := @M_DrawControls;  // draw routine
  ControlsDef.x := 32;
  ControlsDef.y := 68; // x,y of menu
  ControlsDef.lastOn := 0; // last item user was on in menu
  ControlsDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//SystemMenu
  pmi := @SystemMenu[0];
  pmi.status := 1;
  pmi.name := '!Safe mode';
  pmi.cmd := 'safemode';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @safemode;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use mmx/AMD 3D-Now';
  pmi.cmd := 'mmx';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemmx;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Time critical CPU priority';
  pmi.cmd := 'criticalcpupriority';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @criticalcpupriority;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Multithreading functions';
  pmi.cmd := 'usemultithread';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemultithread;
  pmi.alphaKey := 't';

////////////////////////////////////////////////////////////////////////////////
//ControlsDef
  SystemDef.numitems := Ord(sys_end); // # of menu items
  SystemDef.prevMenu := @OptionsDef; // previous menu
  SystemDef.menuitems := Pmenuitem_tArray(@SystemMenu);  // menu items
  SystemDef.routine := @M_DrawSystem;  // draw routine
  SystemDef.x := 32;
  SystemDef.y := 68; // x,y of menu
  SystemDef.lastOn := 0; // last item user was on in menu
  SystemDef.itemheight := LINEHEIGHT2;

////////////////////////////////////////////////////////////////////////////////
//LoadMenu
  pmi := @LoadMenu[0];
  for i := 0 to Ord(load_end) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_LoadSelect;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//LoadDef
  LoadDef.numitems := Ord(load_end); // # of menu items
  LoadDef.prevMenu := @MainDef; // previous menu
  LoadDef.menuitems := Pmenuitem_tArray(@LoadMenu);  // menu items
  LoadDef.routine := @M_DrawLoad;  // draw routine
  LoadDef.x := 80;
  LoadDef.y := 34; // x,y of menu
  LoadDef.lastOn := 0; // last item user was on in menu
  LoadDef.itemheight := 18;

////////////////////////////////////////////////////////////////////////////////
//SaveMenu
  pmi := @SaveMenu[0];
  for i := 0 to Ord(load_end) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_SaveSelect;
    pmi.alphaKey := Chr(Ord('1') + i);
    pmi.pBoolVal := nil;
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//SaveDef
  SaveDef.numitems := Ord(load_end); // # of menu items
  SaveDef.prevMenu := @MainDef; // previous menu
  SaveDef.menuitems := Pmenuitem_tArray(@SaveMenu);  // menu items
  SaveDef.routine := M_DrawSave;  // draw routine
  SaveDef.x := 80;
  SaveDef.y := 34; // x,y of menu
  SaveDef.lastOn := 0; // last item user was on in menu
  SaveDef.itemheight := 18;

////////////////////////////////////////////////////////////////////////////////
  joywait := 0;
  mousewait := 0;
  mmousex := 0;
  mmousey := 0;
  mlastx := 0;
  mlasty := 0;

end;


//
// M_DialogDimMsg
//
// [STRIFE] New function
// haleyjd 09/04/10: Painstakingly transformed from the assembly code, as the
// decompiler could not touch it. Redimensions a string to fit on screen, leaving
// at least a 20 pixel margin on the right side. The string passed in must be
// writable.
//
// jval: rewritten
function M_DialogDimMsg(x, y: integer; str: string; useyfont: boolean): string;
var
  maxwidth: integer;
  i, j: integer;
  lst, lst2: TDStringList;
  line, s, s1, s2: string;

  function _StringWidth(const s: string): integer;
  begin
    if useyfont then
      result := M_StringWidth2(s) // yfont
    else
      result := M_StringWidth(s);
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
      if i <> lst.Count - 1 then
        result := result + #13#10;
    end;
  end;
  lst.Free;
end;

end.

