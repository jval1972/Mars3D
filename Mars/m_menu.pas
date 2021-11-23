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
//   Menu widget stuff, episode selection and such.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit m_menu;

interface

uses
  d_delphi,
  d_event;

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
  mouseSensitivityX: integer;
  mouseSensitivityY: integer;

// Show messages has default, 0 = off, 1 = on
  showMessages: integer;

  shademenubackground: integer;

  keepsavegamename: boolean;

  menuactive: boolean;

  inhelpscreens: boolean;

  menubackgroundflat: string = 'FLORD-02';

const
  DEFMENUBACKGROUNDFLAT = 'FLORD-02';

procedure M_ShutDownMenus;

procedure M_InitMenus;

procedure M_SetKeyboardMode(const mode: integer);

// JVAL: 20211108 - Made public (MARS)
type
  PmessageRoutine = function(i: integer): pointer;

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
    leftMenu: Pmenu_t;          // left menu
    rightMenu: Pmenu_t;         // right menu
    menuitems: Pmenuitem_tArray;// menu items
    drawproc: PProcedure;       // draw routine
    x: smallint;
    y: smallint;                // x,y of menu
    lastOn: smallint;           // last item user was on in menu
    itemheight: integer;
    flags: LongWord;
  end;

procedure M_SetupNextMenu(menudef: Pmenu_t);

var
// current menudef
  currentMenu: Pmenu_t;

implementation

uses
  doomstat,
  doomdef,
  am_map,
  c_cmds,
  dstrings,
  d_englsh,
  d_main,
  d_player,
  d_notifications,
  g_game,
  mars_briefing,
  mars_intermission,
  mars_version,
  mars_hud,
  mars_sounds,
  m_argv,
  m_misc,
  m_fixed,
  mn_textwrite,
  mn_screenshot,
  mt_utils,
  i_system,
  i_threads,
  i_io,
  i_mp3,
  i_sound,
  i_displaymodes,
{$IFDEF OPENGL}
  gl_main,
  gl_defs,
  gl_models,
  gl_voxels,
  gl_lightmaps,
  gl_shadows,
  gl_tex,
{$ELSE}
  i_video,
  r_batchcolumn,
  r_scale,
  r_slopes, // JVAL: Slopes
{$ENDIF}
  e_endoom,
  p_setup,
  p_mobj_h,
  p_terrain,
  p_enemy,
  p_map,
  p_user,
  p_adjust,
  p_obituaries,
  r_aspect,
  r_data,
  r_defs,
  r_dynlights,
  r_main,
  r_hires,
  r_lights,
  r_intrpl,
{$IFNDEF OPENGL}
  r_fake3d,
  r_softlights,
{$ENDIF}
  r_camera,
  r_draw,
  t_main,
  vx_voxelsprite,
  v_data,
  v_video,
  hu_stuff,
  sc_actordef,
  s_sound,
  sounds,
  w_wad,
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

var
  messageRoutine: PmessageRoutine;

var
  gammamsg: array[0..GAMMASIZE - 1] of string;

// we are going to be entering a savegame string
  saveStringEnter: integer = 0;
  saveSlot: integer;  // which slot to save in
  saveCharIndex: integer; // which char we're editing
// old save description before edit
  saveOldString: string;

var
  p_bulletind: Ppatch_t;

const
  ARROWXOFFS = -8;
  ARROWYOFFS = -1;
  BIGLINEHEIGHT = 16;
  SAVELOADLINEHEIGHT = 15;
  SMALLLINEHEIGHT = 8;


var
  savegamestrings: array[0..Ord(load_end) - 1] of string;
  savegamelevels: array[0..Ord(load_end) - 1] of string;
  savegameshots: array[0..Ord(load_end) - 1] of menuscreenbuffer_t;

const
  FLG_MN_TEXTUREBK = 1;
  FLG_MN_DRAWITEMON = 2;

var
  itemOn: smallint;             // selected menu item 

//
//      Menu Functions
//
procedure M_HorzLine(const x1, x2, y: integer; const color: byte);
var
  i: integer;
begin
  for i := y * 320 + x1 to y * 320 + x2 do
    screens[SCN_TMP][i] := color;
end;

procedure M_VertLine(const x, y1, y2: integer; const color: byte);
var
  i: integer;
begin
  for i := y1 to y2 do
    screens[SCN_TMP][i * 320 + x] := color;
end;

procedure M_Frame3d(const x1, y1, x2, y2: integer; const color1, color2, color3: byte);
var
  i: integer;
begin
  M_HorzLine(x1, x2, y1, color1);
  M_HorzLine(x1, x2, y2, color2);
  M_VertLine(x1, y1, y2, color2);
  M_VertLine(x2, y1, y2, color1);
  for i := y1 + 1 to y2 - 1 do
    M_HorzLine(x1 + 1, x2 - 1, i, color3);
end;

var
  option_menu_font: Ppatch_tPArray;
  value_menu_font: Ppatch_tPArray;
  shade_menu_font: Ppatch_tPArray;

function M_WriteTextOption(x, y: integer; const str: string; const flags: integer): menupos_t;
begin
  Result := M_WriteText(x, y, str, flags, option_menu_font, shade_menu_font);
end;

function M_WriteTextValue(x, y: integer; const str: string; const flags: integer): menupos_t;
begin
  Result := M_WriteText(x, y, str, flags, value_menu_font, shade_menu_font);
end;

const
  FRAME_COLOR_UP = 161;
  FRAME_COLOR_DOWN = 163;
  FRAME_COLOR_FILL = 8;
  FRAME_COLOR_BRIGHT = 160;

procedure M_DrawHeadLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, FRAME_COLOR_UP);
  M_HorzLine(0, 319, y + 15, FRAME_COLOR_DOWN);
  for i := y + 1 to y + 14 do
    M_HorzLine(0, 319, i, FRAME_COLOR_FILL);

  M_WriteText(160, y, str, _MA_CENTER or _MC_UPPER, @big_fontY, @big_fontB);
end;

procedure M_DrawSubHeadLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, FRAME_COLOR_UP);
  M_HorzLine(0, 319, y + 15, FRAME_COLOR_DOWN);
  for i := y + 1 to y + 14 do
    M_HorzLine(0, 319, i, FRAME_COLOR_FILL);

  M_WriteText(25, y, str, _MA_LEFT or _MC_UPPER, @big_fontG, @big_fontB);
end;

procedure M_DrawSmallLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, FRAME_COLOR_UP);
  M_HorzLine(0, 319, y + 9, FRAME_COLOR_DOWN);
  for i := y + 1 to y + 8 do
    M_HorzLine(0, 319, i, FRAME_COLOR_FILL);

  M_WriteTextValue(160, y + 1, str, _MA_CENTER or _MC_UPPER);
end;

const
  DEF_MENU_ITEMS_START_X = 32;
  DEF_MENU_ITEMS_START_Y = 65;

procedure M_DrawThermo(x, y, thermWidth, thermDot: integer; numdots: integer = -1);
var
  i: integer;
  p: integer;
begin
  M_Frame3d(x, y, x + thermWidth * 8 + 2, y + 10, FRAME_COLOR_UP, FRAME_COLOR_DOWN, FRAME_COLOR_BRIGHT);

  if numdots <= 1 then
    numdots := thermWidth;
  if numdots < 2 then
    numdots := 2;
  p := Round(thermDot / (numdots - 1) * thermWidth * 8 + 1);
  for i := 1 to thermWidth * 8 do
    if not odd(i) then
    begin
      if i < p then
        M_VertLine(x + i, y + 2, y + 8, 161)
      else
        M_VertLine(x + i, y + 2, y + 8, 164);
    end;
end;

procedure M_StartMessage(const str: string; routine: PmessageRoutine; const input: boolean);
begin
  messageLastMenuActive := menuactive;
  messageToPrint := 1;
  messageString := str;
  if Assigned(routine) then
    @messageRoutine := @routine
  else
    messageRoutine := nil;
  messageNeedsInput := input;
  mn_makescreenshot := true;
  menuactive := true;
end;

procedure M_StopMessage;
begin
  menuactive := messageLastMenuActive;
  messageToPrint := 0;
end;

//
// M_ClearMenus
//
procedure M_ClearMenus;
begin
  menuactive := false;
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
// DOOM MENU
//
  main_e = (
    mm_newgame,
    mm_options,
    mm_loadgame,
    mm_savegame,
    mm_readthis,
    mm_quitmars,
    main_end
  );

var
  MainMenu: array[0..Ord(main_end) - 1] of menuitem_t;
  MainDef: menu_t;

type
//
// EPISODE SELECT
//
  episodes_e = (
    ep1,
    ep2,
    ep3,
    ep4,
    ep_end
  );

var
  EpisodeMenu: array[0..Ord(ep_end) - 1] of menuitem_t;
  EpiDef: menu_t;

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
    od_setvideomode,
    od_detaillevel,
    od_allowlowdetails,
    od_allowhidetails,
    optdispdetail_end
  );

var
  OptionsDisplayDetailMenu: array[0..Ord(optdispdetail_end) - 1] of menuitem_t;
  OptionsDisplayDetailDef: menu_t;

type
  optionsdisplayvideomode_e = (
    odm_fullscreen,
    odm_screensize,
    odm_filler1,
    odm_filler2,
    odm_setvideomode,
    optdispvideomode_end
  );

var
  OptionsDisplayVideoModeMenu: array[0..Ord(optdispvideomode_end) - 1] of menuitem_t;
  OptionsDisplayVideoModeDef: menu_t;

// DISPLAY APPEARANCE MENU
type
  optionsdisplayappearance_e = (
    od_drawfps,
    od_drawcrosshair,
    od_extendedstatusbar,
    od_shademenubackground,
    od_displaydiskbusyicon,
    od_displayendscreen,
    od_showdemoplaybackprogress,
    od_showobituaries,
    od_confcoloredblood,
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
    od_automapgrid,
    optdispautomap_end
  );

var
  OptionsDisplayAutomapMenu: array[0..Ord(optdispautomap_end) - 1] of menuitem_t;
  OptionsDisplayAutomapDef: menu_t;

// DISPLAY ADVANCED MENU
type
  optionsdisplayadvanced_e = (
    od_aspect,
    od_camera,
{$IFNDEF OPENGL}
    od_lightmap,
{$ENDIF}
{$IFNDEF OPENGL}
    od_bltasync,
{$ENDIF}
    od_usetransparentsprites,
{$IFNDEF OPENGL}
    od_diher8bittransparency,
{$ENDIF}
    od_interpolate,
    od_interpolateoncapped,
{$IFNDEF OPENGL}
    od_usefake3d,
{$ENDIF}
    od_fixstallhack,
    od_hidedoublicatedbarrels,
    od_autoadjustmissingtextures,
{$IFNDEF OPENGL}
    od_optimizedcolumnrendering,
    od_optimizedthingsrendering,
    od_precisescalefromglobalangle,
    od_preciseslopedrawing, // JVAL: Slopes
{$ENDIF}
    optdispadvanced_end
  );

var
  OptionsDisplayAdvancedMenu: array[0..Ord(optdispadvanced_end) - 1] of menuitem_t;
  OptionsDisplayAdvancedDef: menu_t;

// DISPLAY ASPECT RATIO MENU
type
  optionsdisplayaspectratio_e = (
    oda_widescreensupport,
    oda_excludewidescreenplayersprites,
    oda_forceaspectratio,
    oda_intermissionaspect,
    optdispaspect_end
  );

var
  OptionsDisplayAspectRatioMenu: array[0..Ord(optdispaspect_end) - 1] of menuitem_t;
  OptionsDisplayAspectRatioDef: menu_t;

//
// DISPLAY CAMERA MENU
type
  optionsdisplaycamera_e = (
    odc_zaxisshift,
    odc_chasecamera,
    odc_chasecameraxy,
    odc_filler3,
    odc_filler4,
    odc_chasecameraz,
    odc_filler5,
    odc_filler6,
    optdispcamera_end
  );

var
  OptionsDisplayCameraMenu: array[0..Ord(optdispcamera_end) - 1] of menuitem_t;
  OptionsDisplayCameraDef: menu_t;

{$IFNDEF OPENGL}
type
  optionslightmap_e = (
    ol_uselightmaps,
    ol_lightmapfunc,
    ol_colorintensity,
    ol_filler1,
    ol_filler2,
    ol_lightwidthfactor,
    ol_filler3,
    ol_filler4,
    od_resettodefaults,
    ol_lightmap_end
  );

var
  OptionsLightmapMenu: array[0..Ord(ol_lightmap_end) - 1] of menuitem_t;
  OptionsLightmapDef: menu_t;
{$ENDIF}

// DISPLAY 32 BIT RENDERING MENU
type
  optionsdisplay32bit_e = (
    od_uselightboost,
    od_uselightboostgodmode,
    od_forcecolormaps,
    od_32bittexturepaletteeffects,
    od_use32bitfuzzeffect,
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
    od_glsetvideomode,
    od_glmodels,
    od_glvoxels,
    od_filter,
    od_usefog,
    {$IFDEF DEBUG}
    od_gl_drawsky,
    {$ENDIF}
    od_gl_stencilsky,
    od_gl_renderwireframe,
    od_gl_uselightmaps,
    od_gl_drawshadows,
    od_gl_add_all_lines,
    od_gl_useglnodesifavailable,
    od_gl_autoloadgwafiles,
    od_gl_screensync,
    optdispopengl_end
  );

var
  OptionsDisplayOpenGLMenu: array[0..Ord(optdispopengl_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLDef: menu_t;

// OpenGL Models
type
  optionsopenglmodels_e = (
    od_glm_drawmodels,
    od_glm_smoothmodelmovement,
    od_glm_precachemodeltextures,
    optglmodels_end
  );

var
  OptionsDisplayOpenGLModelsMenu: array[0..Ord(optglmodels_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLModelsDef: menu_t;

// OpenGL Voxels
type
  optionsopenglvoxels_e = (
    od_glv_drawvoxels,
    od_glv_optimize,
    {$IFDEF DEBUG}
    od_glv_pritesfromvoxels,
    {$ENDIF}
    optglvoxels_end
  );

var
  OptionsDisplayOpenGLVoxelsMenu: array[0..Ord(optglvoxels_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLVoxelsDef: menu_t;

// OpenGL Texture Filtering
type
  optionsopenglfilter_e = (
    od_glf_texture_filter,
    od_glf_texture_filter_anisotropic,
    od_glf_linear_hud,
    optglfilter_end
  );

var
  OptionsDisplayOpenGLFilterMenu: array[0..Ord(optglfilter_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLFilterDef: menu_t;
{$ENDIF}


type
//
// Read This! MENU 1 & 2
//
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

//  https://www.doomworld.com/forum/topic/111465-boom-extended-help-screens-an-undocumented-feature/
// JVAL 20200122 - Extended help screens
var
  extrahelpscreens: TDNumberList;
  extrahelpscreens_idx: integer = -1;

type
  read_ext = (
    rdthsemptyext,
    readext_end
  );

var
  ReadMenuExt: array[0..0] of menuitem_t;
  ReadDefExt: menu_t;


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
    sfx_empty2,
    music_vol,
    sfx_empty3,
    sfx_empty4,
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
    cmp_allowplayercrouch,
    cmp_showbriefingscreen,
    cmp_showintermissionscreen,
    cmp_allowplayerbreath,
    cmp_keepcheatsinplayerrebord,
    cmp_majorbossdeathendsdoom1level,
    cmp_spawnrandommonsters,
    cmp_allowterrainsplashes,
    cmp_dogs,
    cmp_gldefs_as_lightdef,
    cmp_decorate_as_actordef,
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
    cttl_mousesensitivity,
    ctrl_usejoystic,
    ctrl_autorun,
    ctrl_keyboardmode,
    ctrl_keybindings,
    ctrl_end
  );

var
  ControlsMenu: array[0..Ord(ctrl_end) - 1] of menuitem_t;
  ControlsDef: menu_t;

type
//
// MOUSE SENSITIVITY MENU
//
  sensitivity_e = (
    sens_mousesensitivity,
    sens_empty1,
    sens_empty2,
    sens_mousesensitivityx,
    sens_empty3,
    sens_empty4,
    sens_mousesensitivityy,
    sens_empty5,
    sens_empty6,
    sens_end
  );

var
  SensitivityMenu: array[0..Ord(sens_end) - 1] of menuitem_t;
  SensitivityDef: menu_t;


type
//
// KEY BINDINGS MENU
//
  keybindings_e = (
    kb_up,
    kb_down,
    kb_left,
    kb_right,
    kb_strafeleft,
    kb_straferight,
    kb_jump,
    // JVAL: 20211101 - Crouch
    kb_crouch,
    kb_fire,
    kb_use,
    kb_strafe,
    kb_speed,

    kb_lookup,
    kb_lookdown,
    kb_lookcenter,
    kb_lookleft,
    kb_lookright,

    kb_weapon0,
    kb_weapon1,
    kb_weapon2,
    kb_weapon3,
    kb_weapon4,
    kb_weapon5,
    kb_weapon6,
    kb_weapon7,
    kb_weapon8,
    kb_weapon9,

    kb_am_gobigkey,
    kb_am_followkey,
    kb_am_gridkey,
    kb_am_rotatekey,
    kb_am_texturedautomap,
    kb_am_markkey,
    kb_am_clearmarkkey,

    kb_end
  );

var
  KeyBindingsMenu1: array[0..Ord(kb_lookup) - 1] of menuitem_t;
  KeyBindingsDef1: menu_t;
  KeyBindingsMenu2: array[0..Ord(kb_weapon0) - Ord(kb_lookup) - 1] of menuitem_t;
  KeyBindingsDef2: menu_t;
  KeyBindingsMenu3: array[0..Ord(kb_am_gobigkey) - Ord(kb_weapon0) - 1] of menuitem_t;
  KeyBindingsDef3: menu_t;
  KeyBindingsMenu4: array[0..Ord(kb_end) - Ord(kb_am_gobigkey) - 1] of menuitem_t;
  KeyBindingsDef4: menu_t;

type
  bindinginfo_t = record
    text: string[26];
    shorttext: string[20];
    pkey: PInteger;
  end;

const
  KeyBindingsInfo: array [0..Ord(kb_end) - 1] of bindinginfo_t = (
    (text: 'Move forward'; shorttext: ''; pkey: @key_up),
    (text: 'Move backward'; shorttext: ''; pkey: @key_down),
    (text: 'Turn left'; shorttext: ''; pkey: @key_left),
    (text: 'Turn right'; shorttext: ''; pkey: @key_right),
    (text: 'Strafe left'; shorttext: ''; pkey: @key_strafeleft),
    (text: 'Strafe right'; shorttext: ''; pkey: @key_straferight),
    (text: 'Jump/Fly up'; shorttext: ''; pkey: @key_jump),
    // JVAL: 20211101 - Crouch
    (text: 'Crouch/Fly down'; shorttext: ''; pkey: @key_crouch),
    (text: 'Fire'; shorttext: ''; pkey: @key_fire),
    (text: 'Use'; shorttext: ''; pkey: @key_use),
    (text: 'Strafe'; shorttext: ''; pkey: @key_strafe),
    (text: 'Run'; shorttext: ''; pkey: @key_speed),

    (text: 'Look up'; shorttext: ''; pkey: @key_lookup),
    (text: 'Look down'; shorttext: ''; pkey: @key_lookdown),
    (text: 'Look center'; shorttext: ''; pkey: @key_lookcenter),
    (text: 'Look left'; shorttext: ''; pkey: @key_lookleft),
    (text: 'Look right'; shorttext: ''; pkey: @key_lookright),

    (text: 'Fist'; shorttext: ''; pkey: @key_weapon0),
    (text: 'Pistol'; shorttext: ''; pkey: @key_weapon1),
    (text: 'Shock gun'; shorttext: ''; pkey: @key_weapon2),
    (text: 'Nerve gun'; shorttext: ''; pkey: @key_weapon3),
    (text: 'Freeze gun'; shorttext: ''; pkey: @key_weapon4),
    (text: 'Flame gun'; shorttext: ''; pkey: @key_weapon5),
    (text: 'Grenade launcher'; shorttext: ''; pkey: @key_weapon6),
    (text: 'Boomerang'; shorttext: ''; pkey: @key_weapon7),
    (text: 'Missile launcher'; shorttext: ''; pkey: @key_weapon8),
    (text: 'Tracking missile launcher'; shorttext: 'Tracking missiles'; pkey: @key_weapon9),

    (text: 'Automap max zoom'; shorttext: 'Max Zoom'; pkey: @AM_GOBIGKEY),
    (text: 'Automap follow on/off'; shorttext: 'Follow On/Off'; pkey: @AM_FOLLOWKEY),
    (text: 'Automap grid on/off'; shorttext: 'Grid On/Off'; pkey: @AM_GRIDKEY),
    (text: 'Automap rotate on/off'; shorttext: 'Rotate On/Off'; pkey: @AM_ROTATEKEY),
    (text: 'Automap texture on/off'; shorttext: 'Texture On/Off'; pkey: @AM_TEXTUREDAUTOMAP),
    (text: 'Automap add mark'; shorttext: 'Add Mark'; pkey: @AM_MARKKEY),
    (text: 'Automap clear mark'; shorttext: 'Clear Mark'; pkey: @AM_CLEARMARKKEY)
  );

var
  bindkeyEnter: boolean;
  bindkeySlot: integer;
  saveOldkey: integer;

function M_KeyToString(const k: integer): string;
begin
  if (k >= 33) and (k <= 126) then
  begin
    result := Chr(k);
    if result = '=' then
      result := '+'
    else if result = ',' then
      result := '<'
    else if result = '.' then
      result := '>';
    exit;
  end;

  case k of
    32: result := 'SPACE';
    KEY_RIGHTARROW: result := 'RIGHTARROW';
    KEY_LEFTARROW: result := 'LEFTARROW';
    KEY_UPARROW: result := 'UPARROW';
    KEY_DOWNARROW: result := 'DOWNARROW';
    KEY_ESCAPE: result := 'ESCAPE';
    KEY_ENTER: result := 'ENTER';
    KEY_TAB: result := 'TAB';
    KEY_F1: result := 'F1';
    KEY_F2: result := 'F2';
    KEY_F3: result := 'F3';
    KEY_F4: result := 'F4';
    KEY_F5: result := 'F5';
    KEY_F6: result := 'F6';
    KEY_F7: result := 'F7';
    KEY_F8: result := 'F8';
    KEY_F9: result := 'F9';
    KEY_F10: result := 'F10';
    KEY_F11: result := 'F11';
    KEY_F12: result := 'F12';
    KEY_PRNT: result := 'PRNT';
    KEY_CON: result := 'CON';
    KEY_BACKSPACE: result := 'BACKSPACE';
    KEY_PAUSE: result := 'PAUSE';
    KEY_EQUALS: result := 'EQUALS';
    KEY_MINUS: result := 'MINUS';
    KEY_RSHIFT: result := 'SHIFT';
    KEY_RCTRL: result := 'CTRL';
    KEY_RALT: result := 'ALT';
    KEY_PAGEDOWN: result := 'PAGEDOWN';
    KEY_PAGEUP: result := 'PAGEUP';
    KEY_INS: result := 'INS';
    KEY_HOME: result := 'HOME';
    KEY_END: result := 'END';
    KEY_DELETE: result := 'DELETE';
  else
    result := '';
  end;
end;

function M_SetKeyBinding(const slot: integer; key: integer): boolean;
var
  i: integer;
  oldk: integer;
begin
  if (slot < 0) or (slot >= Ord(kb_end)) then
  begin
    result := false;
    exit;
  end;

  if key = 16 then
    key := KEY_RSHIFT
  else if key = 17 then
    key := KEY_RCTRL
  else if key = 18 then
    key := KEY_RALT;

  result := key in [32..125,
    KEY_RIGHTARROW,
    KEY_LEFTARROW,
    KEY_UPARROW,
    KEY_DOWNARROW,
    KEY_BACKSPACE,
    KEY_RSHIFT,
    KEY_RCTRL,
    KEY_RALT,
    KEY_PAGEDOWN,
    KEY_PAGEUP,
    KEY_INS,
    KEY_HOME,
    KEY_END,
    KEY_DELETE
  ];

  if not result then
    exit;

  oldk := KeyBindingsInfo[slot].pkey^;
  for i := 0 to Ord(kb_end) - 1 do
    if i <> slot then
     if KeyBindingsInfo[i].pkey^ = key then
       KeyBindingsInfo[i].pkey^ := oldk;
  KeyBindingsInfo[slot].pkey^ := key;
end;

procedure M_DrawBindings(const m: menu_t; const start, stop: integer; const titl: string);
var
  i: integer;
  len: integer;
  s: string;
  drawkey: boolean;
begin
  M_DrawHeadLine(15, 'Controls');
  M_DrawSubHeadLine(40, 'Key Bindings');
  M_DrawSmallLine(DEF_MENU_ITEMS_START_Y, titl);

  for i := 0 to stop - start - 1 do
  begin
    s := KeyBindingsInfo[start + i].text + ': ';
    len := M_StringWidth(s, _MA_LEFT or _MC_UPPER, option_menu_font);
    M_WriteTextOption(m.x, m.y + m.itemheight * i, s, _MA_LEFT or _MC_UPPER);
    drawkey := true;
    if bindkeyEnter then
      if i = bindkeySlot - start then
        if (gametic div 18) mod 2 <> 0 then
          drawkey := false;
    if drawkey then
      M_WriteTextValue(m.x + len, m.y + m.itemheight * i, M_KeyToString(KeyBindingsInfo[start + i].pkey^), _MA_LEFT or _MC_UPPER);
  end;
end;

procedure M_DrawBindings1;
begin
  M_DrawBindings(KeyBindingsDef1, 0, Ord(kb_lookup), 'General');
end;

procedure M_DrawBindings2;
begin
  M_DrawBindings(KeyBindingsDef2, Ord(kb_lookup), Ord(kb_weapon0), 'Look');
end;

procedure M_DrawBindings3;
begin
  M_DrawBindings(KeyBindingsDef3, Ord(kb_weapon0), Ord(kb_am_gobigkey), 'Weapons');
end;

procedure M_DrawBindings4;
begin
  M_DrawBindings(KeyBindingsDef4, Ord(kb_am_gobigkey), Ord(kb_end), 'Automap');
end;

//
// Select key binding
//
procedure M_KeyBindingSelect1(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := choice;

  saveOldkey := KeyBindingsInfo[choice].pkey^;
end;

procedure M_KeyBindingSelect2(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := Ord(kb_lookup) + choice;

  saveOldkey := KeyBindingsInfo[Ord(kb_lookup) + choice].pkey^;
end;

procedure M_KeyBindingSelect3(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := Ord(kb_weapon0) + choice;

  saveOldkey := KeyBindingsInfo[Ord(kb_weapon0) + choice].pkey^;
end;

procedure M_KeyBindingSelect4(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := Ord(kb_am_gobigkey) + choice;

  saveOldkey := KeyBindingsInfo[Ord(kb_am_gobigkey) + choice].pkey^;
end;

type
//
// SYSTEM  MENU
//
  system_e = (
    sys_safemode,
    sys_usemmx,
    sys_criticalcpupriority,
    sys_usemultithread,
    sys_screenshottype,
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
  handle: file;
  i: integer;
  name: string;
  numread: integer;
begin
  for i := 0 to Ord(load_end) - 1 do
  begin
    sprintf(name, M_SaveFileName(MARS_GetSavePath + SAVEGAMENAME) + '%d.sav', [i]);

    if not fopen(handle, name, fOpenReadOnly) then
    begin
      savegamestrings[i] := '';
      savegamelevels[i] := '';
      ZeroMemory(@savegameshots[i], SizeOf(menuscreenbuffer_t));
      LoadMenu[i].status := 0;
      continue;
    end;
    SetLength(savegamelevels[i], SAVEMAPNAMESIZE);
    BlockRead(handle, (@savegamelevels[i][1])^, SAVEMAPNAMESIZE);
    SetLength(savegamestrings[i], SAVESTRINGSIZE);
    BlockRead(handle, (@savegamestrings[i][1])^, SAVESTRINGSIZE);
    seek(handle, SAVEMAPNAMESIZE + SAVESTRINGSIZE + SAVEVERSIONSIZE);
    BlockRead(handle, savegameshots[i], SizeOf(menuscreenbuffer_t), numread);
    if numread <> SizeOf(menuscreenbuffer_t) then
      ZeroMemory(@savegameshots[i], SizeOf(menuscreenbuffer_t));
    close(handle);
    LoadMenu[i].status := 1;
  end;
end;

//
// M_DrawSaveLoadScreenShot
// JVAL: 20200303 - Draw Game Screenshot in Load/Save screens
//
procedure M_DrawSaveLoadScreenShot(const screenshot: Pmenuscreenbuffer_t);
const
  SHOT_X = 123;
  SHOT_Y = 42;
var
  i, x, y, spos: integer;
begin
  if screenshot = nil then
    exit;

  if not MN_ValidScreenShot(screenshot) then
  begin
    for i := 0 to MN_SCREENSHOTSIZE - 1 do
      screenshot.data[i] := aprox_black;
  end
  else
  begin
    for i := 0 to MN_SCREENSHOTSIZE - 1 do
      if screenshot.data[i] = 0 then
        screenshot.data[i] := aprox_black;
  end;

  // Draw screenshot starting at (SHOT_X,SHOT_Y) position
  for y := 0 to MN_SCREENSHOTHEIGHT - 1 do
  begin
    spos := (SHOT_Y + y) * 320 + SHOT_X;
    for x := 0 to MN_SCREENSHOTWIDTH - 1 do
    begin
      screens[SCN_TMP][spos] := screenshot.data[y * MN_SCREENSHOTWIDTH + x];
      inc(spos);
    end;
  end;
end;

var
  m_detail: Ppatch_t;
  m_lgttl: Ppatch_t;
  m_sgttl: Ppatch_t;

//
// M_LoadGame & Cie.
//
procedure M_DrawLoad;
var
  i: integer;
begin
  V_DrawPatch(0, 0, SCN_TMP, m_detail, false);
  M_HorzLine(29, 109, 174, 123);  // JVAL: 20211107 - One extra save slot (9 total)
  V_DrawPatch(28 + m_lgttl.leftoffset, 19 + m_lgttl.topoffset, SCN_TMP, m_lgttl, false);
  for i := 0 to Ord(load_end) - 1 do
  begin
    M_WriteText(LoadDef.x, LoadDef.y + LoadDef.itemheight * i, savegamestrings[i], _MA_LEFT or _MC_UPPER, @green_font, @dark_font);
    if itemon = i then
    begin
      M_WriteText(LoadDef.x - 8, LoadDef.y + LoadDef.itemheight * i, '-', _MA_LEFT or _MC_UPPER, @green_font, @dark_font);
      M_DrawSaveLoadScreenShot(@savegameshots[i]);
      M_WriteText(224, 162, savegamelevels[i], _MA_LEFT or _MC_UPPER, @green_font, @dark_font);
    end;
  end;
end;

//
// User wants to load this game
//
procedure M_LoadSelect(choice: integer);
var
  name: string;
begin
  sprintf(name, M_SaveFileName(MARS_GetSavePath + SAVEGAMENAME) + '%d.sav', [choice]);
  G_LoadGame(name);
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
  V_DrawPatch(0, 0, SCN_TMP, m_detail, false);
  M_HorzLine(29, 109, 174, 123);  // JVAL: 20211107 - One extra save slot (9 total)
  V_DrawPatch(28 + m_sgttl.leftoffset, 19 + m_sgttl.topoffset, SCN_TMP, m_sgttl, false);
  for i := 0 to Ord(load_end) - 1 do
  begin
    M_WriteText(LoadDef.x, LoadDef.y + LoadDef.itemheight * i, savegamestrings[i], _MA_LEFT or _MC_UPPER, @green_font, @dark_font);
    if itemon = i then
    begin
      M_WriteText(LoadDef.x - 8, LoadDef.y + LoadDef.itemheight * i, '-', _MA_LEFT or _MC_UPPER, @green_font, @dark_font);
      M_DrawSaveLoadScreenShot(@mn_screenshotbuffer);
      M_WriteText(224, 162, savegamelevels[i], _MA_LEFT or _MC_UPPER, @green_font, @dark_font);
    end;
  end;

  if saveStringEnter <> 0 then
  begin
    i := M_StringWidth(savegamestrings[saveSlot], _MA_LEFT or _MC_UPPER, @green_font);
    if (gametic div 18) mod 2 = 0 then
      M_WriteText(LoadDef.x + i, LoadDef.y + LoadDef.itemheight * saveSlot, '_', _MA_LEFT or _MC_UPPER, @green_font, @dark_font);
  end;
end;

//
// M_Responder calls this when user is finished
//
procedure M_DoSave(slot: integer);
begin
  G_SaveGame(slot, savegamestrings[slot]);
  M_ClearMenus;

  // PICK QUICKSAVE SLOT YET?
  if quickSaveSlot = -2 then
    quickSaveSlot := slot;
end;

//
// User wants to save. Start string input for M_Responder
//
procedure M_SaveSelect(choice: integer);
var
  s: string;
  i: integer;
  c: char;
begin
  // we are going to be intercepting all chars
  saveStringEnter := 1;

  saveSlot := choice;
  saveOldString := savegamestrings[choice];
  // JVAL 21/4/2017
  if keepsavegamename then
  begin
    s := '';
    for i := 1 to Length(savegamestrings[choice]) do
    begin
      c := savegamestrings[choice][i];
      if c in [#0, #13, #10, ' '] then
        Break
      else
        s := s + c;
    end;
    savegamestrings[choice] := s;
  end
  else if savegamestrings[choice] <> '' then
    savegamestrings[choice] := '';
  saveCharIndex := Length(savegamestrings[choice]);
end;

//
// Selected from DOOM menu
//
procedure M_SaveGame(choice: integer);
begin
  if not usergame then
  begin
    M_StartMessage(SAVEDEAD + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  M_SetupNextMenu(@SaveDef);
  M_ReadSaveStrings;
end;

//
//      M_QuickSave
//

procedure M_MenuSound;
begin
  if gamestate = GS_ENDOOM then
    exit;

  MARS_StartSound(nil, snd_SWON);
end;

procedure M_QuickSaveResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_DoSave(quickSaveSlot);
    M_MenuSound;
  end;
end;

procedure M_QuickSave;
var
  tempstring: string;
begin
  if not usergame then
  begin
    M_MenuSound;
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
    M_MenuSound;
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

procedure M_DrawFlatBackground(const sflat: string);
var
  x, y: integer;
  src: PByteArray;
  dest: integer;
  iflat: integer;
begin
  iflat := R_FlatNumForName(sflat);
  if iflat < 0 then
  begin
    iflat := R_FlatNumForName(DEFMENUBACKGROUNDFLAT);
    if iflat < 0 then
      exit;
  end;

  src := W_CacheLumpNum(R_GetLumpForFlat(iflat), PU_STATIC);
  dest := 0;

  for y := 0 to 200 - 1 do
  begin
    for x := 0 to (320 div 64) - 1 do
    begin
      memcpy(@screens[SCN_TMP, dest], @src[_SHL(y and 63, 6)], 64);
      dest := dest + 64;
    end;

    if 320 and 63 <> 0 then
    begin
      memcpy(@screens[SCN_TMP, dest], @src[_SHL(y and 63, 6)], 320 and 63);
      dest := dest + (320 and 63);
    end;
  end;
  Z_ChangeTag(src, PU_CACHE);
end;

//
// Read This Menus
// Had a "quick hack to fix romero bug"
//
function M_WriteHelpText(const x, y: integer; const s1, s2: string): menupos_t;
var
  mp: menupos_t;
begin
  mp := M_WriteTextValue(x, y, s1 + ': ', _MA_LEFT or _MC_UPPER);
  result := M_WriteTextOption(mp.x, mp.y, s2, _MA_LEFT or _MC_UPPER);
end;

function M_WriteHelpControlText(const x, y: integer; const control: PInteger): menupos_t;
var
  i: integer;
  txt: string;
begin
  for i := 0 to Ord(kb_end) - 1 do
    if KeyBindingsInfo[i].pkey = control then
    begin
      txt := KeyBindingsInfo[i].shorttext;
      if txt = '' then
        txt := KeyBindingsInfo[i].text;
      result := M_WriteTextOption(x, y, txt + ': ', _MA_LEFT or _MC_UPPER);
      result := M_WriteTextValue(result.x, result.y, M_KeyToString(control^), _MA_LEFT or _MC_UPPER);
      exit;
    end;

  result.x := x;
  result.y := y;
end;

procedure M_DrawReadThis1;
var
  y: integer;
begin
  inhelpscreens := true;
  M_DrawFlatBackground(menubackgroundflat);

  M_DrawHeadLine(15, 'HELP');

  y := 34;
  M_DrawSmallLine(y, 'MISCELLANIOUS OPTIONS');

  y := y + 14;
  M_WriteHelpText(10, y, 'F1', 'HELP');
  M_WriteHelpText(160, y, 'F2', 'LOAD');

  y := y + 10;
  M_WriteHelpText(10, y, 'F3', 'SAVE');
  M_WriteHelpText(160, y, 'F4', 'SOUND VOLUME');

  y := y + 10;
  M_WriteHelpText(10, y, 'F5', 'TOGGLE DETAIL');
  M_WriteHelpText(160, y, 'F6', 'QUICKSAVE');

  y := y + 10;
  M_WriteHelpText(10, y, 'F7', 'END GAME');
  M_WriteHelpText(160, y, 'F8', 'MESSAGES');

  y := y + 10;
  M_WriteHelpText(10, y, 'F9', 'QUICKLOAD');
  M_WriteHelpText(160, y, 'F10', 'QUIT GAME');

  y := y + 10;
  M_WriteHelpText(10, y, 'F11', 'GAMMA');
  M_WriteHelpText(160, y, 'F12', 'OBJECTIVES');

  y := y + 10;
  M_WriteHelpText(10, y, 'TAB', 'AUTOMAP');
  M_WriteHelpText(160, y, 'ESC', 'MENU');

  y := y + 10;
  M_WriteHelpText(10, y, '+/-', 'VIEW SIZE');
  M_WriteHelpText(160, y, 'PRTSC', 'SCREENSHOT');

  y := y + 10;
  M_WriteHelpText(10, y, 'PAUSE', 'PAUSE GAME');

  y := y + 14;
  M_DrawSmallLine(y, 'MENU');

  y := y + 14;
  M_WriteHelpText(10, y, 'ARROWS', 'NAVIGATE');
  M_WriteHelpText(160, y, 'ENTER', 'SELECT');

  y := y + 10;
  M_WriteHelpText(10, y, 'BACKSPACE', 'GO BACK');
end;

procedure M_DrawReadThis2;
var
  y: integer;
begin
  inhelpscreens := true;
  M_DrawFlatBackground(menubackgroundflat);

  M_DrawHeadLine(15, 'HELP');

  y := 34;
  M_DrawSmallLine(y, 'MOVEMENT CONTROLS');

  y := y + 14;
  M_WriteHelpControlText(10, y, @key_up);
  M_WriteHelpControlText(160, y, @key_down);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_left);
  M_WriteHelpControlText(160, y, @key_right);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_strafeleft);
  M_WriteHelpControlText(160, y, @key_straferight);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_jump);
  M_WriteHelpControlText(160, y, @key_crouch);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_fire);
  M_WriteHelpControlText(160, y, @key_use);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_lookup);
  M_WriteHelpControlText(160, y, @key_lookdown);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_lookcenter);
  M_WriteHelpControlText(160, y, @key_lookleft);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_lookright);
  M_WriteHelpControlText(160, y, @key_strafe);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_speed);
end;

procedure M_DrawReadThis3;
var
  y: integer;
begin
  inhelpscreens := true;
  M_DrawFlatBackground(menubackgroundflat);

  M_DrawHeadLine(15, 'HELP');

  y := 34;
  M_DrawSmallLine(y, 'WEAPON SELECTION');

  y := y + 14;
  M_WriteHelpControlText(10, y, @key_weapon0);
  M_WriteHelpControlText(160, y, @key_weapon1);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_weapon2);
  M_WriteHelpControlText(160, y, @key_weapon3);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_weapon4);
  M_WriteHelpControlText(160, y, @key_weapon5);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_weapon6);
  M_WriteHelpControlText(160, y, @key_weapon7);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_weapon8);
  M_WriteHelpControlText(160, y, @key_weapon9);

  y := y + 14;
  M_DrawSmallLine(y, 'AUTOMAP');

  y := y + 14;
  M_WriteHelpControlText(10, y, @AM_FOLLOWKEY);
  M_WriteHelpControlText(160, y, @AM_MARKKEY);

  y := y + 10;
  M_WriteHelpControlText(10, y, @AM_CLEARMARKKEY);
  M_WriteHelpControlText(160, y, @AM_GRIDKEY);

  y := y + 10;
  M_WriteHelpControlText(10, y, @AM_TEXTUREDAUTOMAP);
  M_WriteHelpControlText(160, y, @AM_ROTATEKEY);

  y := y + 10;
  M_WriteHelpControlText(10, y, @AM_GOBIGKEY);
  M_WriteHelpText(160, y, '+/-', 'ZOOM SIZE');
end;

procedure M_DrawReadThisExt;
begin
  inhelpscreens := true;
  V_PageDrawer(char8tostring(W_GetNameForNum(extrahelpscreens.Numbers[extrahelpscreens_idx])));
end;

//
// Change Sfx & Music volumes
//
procedure M_DrawSoundVol;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Volume Control');

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + SoundVolDef.itemheight * (Ord(sfx_vol) + 1), 16, snd_SfxVolume);

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + SoundVolDef.itemheight * (Ord(music_vol) + 1), 16, snd_MusicVolume);
end;

procedure M_ChangeDogs(choice: integer);
begin
  dogs := GetIntegerInRange(dogs, 0, MAXPLAYERS - 1);
  inc(dogs);
  if dogs >= MAXPLAYERS then
    dogs := 0;
end;

procedure M_DrawCompatibility;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Compatibility');

  dogs := GetIntegerInRange(dogs, 0, MAXPLAYERS - 1);
  ppos := M_WriteTextOption(CompatibilityDef.x, CompatibilityDef.y + CompatibilityDef.itemheight * Ord(cmp_dogs), 'Dogs (Marine Best Friend): ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, itoa(dogs), _MA_LEFT or _MC_UPPER);
end;

const
  mkeyboardmodes: array[0..3] of string = ('ARROWS', 'WASD', 'ESDF', 'CUSTOM');

procedure M_SetKeyboardMode(const mode: integer);
begin
  if mode = 0 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 173;
    key_down := 175;
    key_strafeleft := 44;
    key_straferight := 46;
    key_jump := 97;
    // JVAL: 20211101 - Crouch
    key_crouch := 122;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('0');
    key_weapon1 := Ord('1');
    key_weapon2 := Ord('2');
    key_weapon3 := Ord('3');
    key_weapon4 := Ord('4');
    key_weapon5 := Ord('5');
    key_weapon6 := Ord('6');
    key_weapon7 := Ord('7');
    key_weapon8 := Ord('8');
    key_weapon9 := Ord('9');
    AM_FOLLOWKEY := Ord('f');
    AM_GRIDKEY := Ord('g');
    AM_ROTATEKEY := Ord('r');
    AM_TEXTUREDAUTOMAP := Ord('t');
    AM_MARKKEY := Ord('m');
    AM_CLEARMARKKEY := Ord('c');
  end
  else if mode = 1 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 119;
    key_down := 115;
    key_strafeleft := 97;
    key_straferight := 100;
    key_jump := 101;
    // JVAL: 20211101 - Crouch
    key_crouch := 113;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('0');
    key_weapon1 := Ord('1');
    key_weapon2 := Ord('2');
    key_weapon3 := Ord('3');
    key_weapon4 := Ord('4');
    key_weapon5 := Ord('5');
    key_weapon6 := Ord('6');
    key_weapon7 := Ord('7');
    key_weapon8 := Ord('8');
    key_weapon9 := Ord('9');
    AM_GOBIGKEY := Ord('o');
    AM_FOLLOWKEY := Ord('f');
    AM_GRIDKEY := Ord('g');
    AM_ROTATEKEY := Ord('r');
    AM_TEXTUREDAUTOMAP := Ord('t');
    AM_MARKKEY := Ord('m');
    AM_CLEARMARKKEY := Ord('c');
  end
  else if mode = 2 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 101;
    key_down := 100;
    key_strafeleft := 115;
    key_straferight := 102;
    key_jump := 97;
    // JVAL: 20211101 - Crouch
    key_crouch := 122;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('0');
    key_weapon1 := Ord('1');
    key_weapon2 := Ord('2');
    key_weapon3 := Ord('3');
    key_weapon4 := Ord('4');
    key_weapon5 := Ord('5');
    key_weapon6 := Ord('6');
    key_weapon7 := Ord('7');
    key_weapon8 := Ord('8');
    key_weapon9 := Ord('9');
    AM_GOBIGKEY := Ord('o');
    AM_FOLLOWKEY := Ord('f');
    AM_GRIDKEY := Ord('g');
    AM_ROTATEKEY := Ord('r');
    AM_TEXTUREDAUTOMAP := Ord('t');
    AM_MARKKEY := Ord('m');
    AM_CLEARMARKKEY := Ord('c');
  end;
end;

function M_GetKeyboardMode: integer;
begin
  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 173) and
     (key_down = 175) and
     (key_strafeleft = 44) and
     (key_straferight = 46) and
     (key_jump = 97) and
    // JVAL: 20211101 - Crouch
     (key_crouch = 122) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('0')) and
     (key_weapon1 = Ord('1')) and
     (key_weapon2 = Ord('2')) and
     (key_weapon3 = Ord('3')) and
     (key_weapon4 = Ord('4')) and
     (key_weapon5 = Ord('5')) and
     (key_weapon6 = Ord('6')) and
     (key_weapon7 = Ord('7')) and
     (key_weapon8 = Ord('8')) and
     (key_weapon9 = Ord('9')) and
     (AM_GOBIGKEY = Ord('o')) and
     (AM_FOLLOWKEY = Ord('f')) and
     (AM_GRIDKEY = Ord('g')) and
     (AM_ROTATEKEY = Ord('r')) and
     (AM_TEXTUREDAUTOMAP = Ord('t')) and
     (AM_MARKKEY = Ord('m')) and
     (AM_CLEARMARKKEY = Ord('c')) then
  begin
    result := 0;
    exit;
  end;

  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 119) and
     (key_down = 115) and
     (key_strafeleft = 97) and
     (key_straferight = 100) and
     (key_jump = 101) and
    // JVAL: 20211101 - Crouch
     (key_crouch = 113) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('0')) and
     (key_weapon1 = Ord('1')) and
     (key_weapon2 = Ord('2')) and
     (key_weapon3 = Ord('3')) and
     (key_weapon4 = Ord('4')) and
     (key_weapon5 = Ord('5')) and
     (key_weapon6 = Ord('6')) and
     (key_weapon7 = Ord('7')) and
     (key_weapon8 = Ord('8')) and
     (key_weapon9 = Ord('9')) and
     (AM_GOBIGKEY = Ord('o')) and
     (AM_FOLLOWKEY = Ord('f')) and
     (AM_GRIDKEY = Ord('g')) and
     (AM_ROTATEKEY = Ord('r')) and
     (AM_TEXTUREDAUTOMAP = Ord('t')) and
     (AM_MARKKEY = Ord('m')) and
     (AM_CLEARMARKKEY = Ord('c')) then
  begin
    result := 1;
    exit;
  end;

  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 101) and
     (key_down = 100) and
     (key_strafeleft = 115) and
     (key_straferight = 102) and
     (key_jump = 97) and
    // JVAL: 20211101 - Crouch
     (key_crouch = 122) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('0')) and
     (key_weapon1 = Ord('1')) and
     (key_weapon2 = Ord('2')) and
     (key_weapon3 = Ord('3')) and
     (key_weapon4 = Ord('4')) and
     (key_weapon5 = Ord('5')) and
     (key_weapon6 = Ord('6')) and
     (key_weapon7 = Ord('7')) and
     (key_weapon8 = Ord('8')) and
     (key_weapon9 = Ord('9')) and
     (AM_GOBIGKEY = Ord('o')) and
     (AM_FOLLOWKEY = Ord('f')) and
     (AM_GRIDKEY = Ord('g')) and
     (AM_ROTATEKEY = Ord('r')) and
     (AM_TEXTUREDAUTOMAP = Ord('t')) and
     (AM_MARKKEY = Ord('m')) and
     (AM_CLEARMARKKEY = Ord('c')) then
  begin
    result := 2;
    exit;
  end;

  result := 3;
end;

procedure M_KeyboardModeArrows(choice: integer);
begin
  M_SetKeyboardMode(0);
end;

procedure M_KeyboardModeWASD(choice: integer);
begin
  M_SetKeyboardMode(1);
end;

procedure M_KeyboardModeESDF(choice: integer);
begin
  M_SetKeyboardMode(2);
end;

procedure M_SwitchKeyboardMode(choice: integer);
var
  old: integer;
begin
  old := M_GetKeyboardMode;
  case old of
    0: M_KeyboardModeWASD(choice);
    1: M_KeyboardModeESDF(choice);
  else
    M_KeyboardModeArrows(choice);
  end;
end;

procedure M_CmdKeyboardMode(const parm1, parm2: string);
var
  wrongparms: boolean;
  sparm1: string;
begin
  wrongparms := false;

  if (parm1 = '') or (parm2 <> '') then
    wrongparms := true;

  sparm1 := strupper(parm1);

  if (parm1 <> '0') and (parm1 <> '1') and (parm1 <> '2') and
     (sparm1 <> 'ARROWS') and (sparm1 <> 'WASD') and (sparm1 <> 'ESDF') then
    wrongparms := true;

  if wrongparms then
  begin
    printf('Specify the keyboard mode:'#13#10);
    printf('  0: Arrows'#13#10);
    printf('  1: WASD'#13#10);
    printf('  2: ESDF'#13#10);
    exit;
  end;

  if (parm1 = '0') or (sparm1 = 'ARROWS') then
    M_SetKeyboardMode(0)
  else if (parm1 = '1') or (sparm1 = 'WASD') then
    M_SetKeyboardMode(1)
  else
    M_SetKeyboardMode(2);
end;

procedure M_DrawControls;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Controls');

  ppos := M_WriteTextOption(ControlsDef.x, ControlsDef.y + ControlsDef.itemheight * Ord(ctrl_keyboardmode), 'Keyboard preset: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, mkeyboardmodes[M_GetKeyboardMode], _MA_LEFT or _MC_UPPER);
end;

procedure M_DrawSound;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Sound');
end;

procedure M_DrawSystem;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'System');

  M_FixScreenshotFormat;
  ppos := M_WriteTextOption(SystemDef.x, SystemDef.y + SystemDef.itemheight * Ord(sys_screenshottype), 'Screenshot format: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, screenshotformat, _MA_LEFT or _MC_UPPER);
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

procedure M_OptionsSensitivity(choice: integer);
begin
  M_SetupNextMenu(@SensitivityDef);
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

var
  mdisplaymode_idx: integer = 0;

procedure M_SetVideoMode(choice: integer);
var
  idx: integer;
begin
  idx := I_NearestDisplayModeIndex(SCREENWIDTH, SCREENHEIGHT);
  if idx >= 0 then
    mdisplaymode_idx := idx;
  OptionsDisplayVideoModeDef.lastOn := 0;
  itemOn := 0;
  M_SetupNextMenu(@OptionsDisplayVideoModeDef);
end;

procedure M_OptionsDisplayAutomap(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAutomapDef);
end;

procedure M_OptionsDisplayAppearance(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAppearanceDef);
end;

procedure M_OptionAspectRatio(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAspectRatioDef);
end;

procedure M_OptionCameraShift(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayCameraDef);
end;

{$IFNDEF OPENGL}
procedure M_OptionsDisplayLightmap(choice: integer);
begin
  M_SetupNextMenu(@OptionsLightmapDef);
end;
{$ENDIF}

procedure M_ChangeCameraXY(choice: integer);
begin
  case choice of
    0: chasecamera_viewxy := chasecamera_viewxy - 8;
    1: chasecamera_viewxy := chasecamera_viewxy + 8;
  end;
  chasecamera_viewxy := ibetween(chasecamera_viewxy, CHASECAMERA_XY_MIN, CHASECAMERA_XY_MAX);
end;

procedure M_ChangeCameraZ(choice: integer);
begin
  case choice of
    0: chasecamera_viewz := chasecamera_viewz - 4;
    1: chasecamera_viewz := chasecamera_viewz + 4;
  end;
  chasecamera_viewz := ibetween(chasecamera_viewz, CHASECAMERA_Z_MIN, CHASECAMERA_Z_MAX);
end;

const
  NUMSTRASPECTRATIOS = 5;
  straspectratios: array[0..NUMSTRASPECTRATIOS - 1] of string =
    ('AUTO', '4:3', '16:10', '16:9', '1.85:1');

var
  aspectratioidx: integer;

procedure M_SwitchForcedAspectRatio(choice: integer);
begin
  aspectratioidx := (aspectratioidx + 1) mod NUMSTRASPECTRATIOS;
  if aspectratioidx = 0 then
    forcedaspectstr := '0'
  else
  begin
    widescreensupport := true;
    forcedaspectstr := straspectratios[aspectratioidx];
  end;
  setsizeneeded := true;
end;

function _nearest_aspect_index: integer;
var
  asp: single;
  i: integer;
  diff, test, mx: single;
  ar, par: string;
begin
  result := 0;

  asp := R_ForcedAspect;
  if asp < 1.0 then
    exit;

  mx := 100000000.0;

  for i := 1 to NUMSTRASPECTRATIOS - 1 do
  begin
    splitstring(straspectratios[i], ar, par, [':', '/']);
    if par = '' then
      test := atof(ar)
    else
      test := atof(ar) / atof(par);
    diff := fabs(test - asp);
    if diff = 0 then
    begin
      result := i;
      exit;
    end;
    if diff < mx then
    begin
      result := i;
      mx := diff;
    end;
  end;
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

procedure M_OptionsDisplayOpenGLModels(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLModelsDef);
end;

procedure M_OptionsDisplayOpenGLVoxels(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLVoxelsDef);
end;

procedure M_OptionsDisplayOpenGLFilter(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLFilterDef);
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

//
// M_DrawMainMenu
//
procedure M_DrawMainMenu;
var
  p: Ppatch_t;
  i, y: integer;
begin
  p := W_CacheLumpName('M_MARS', PU_STATIC);
  V_DrawPatch((320 - p.width) div 2, 6, SCN_TMP, p, false);
  Z_ChangeTag(p, PU_CACHE);

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(mm_newgame) to Ord(mm_quitmars) do
  begin
    if itemOn = i then
      M_WriteText(160, y, MainMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, MainMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontG, @big_fontB);
    y := y + 14;
  end;
end;

//
// M_NewGame
//
procedure M_DrawNewGame;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'New Game');
  M_DrawSubHeadLine(40, 'Select Skill');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(newg_killthings) to Ord(newg_end) - 1 do
  begin
    if itemOn = i then
      M_WriteText(160, y, NewGameMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, NewGameMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontG, @big_fontB);
    y := y + 14;
  end;
end;

procedure M_NewGame(choice: integer);
begin
  if netgame and not demoplayback then
  begin
    M_StartMessage(SNEWGAME + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if gamemode = commercial then
  begin
    if oldsharewareversion then
      NewDef.numitems := Ord(newg_nightmare); // No nightmare in old shareware
    M_SetupNextMenu(@NewDef);
  end
  else
  begin
      // JVAL: Chex Support
    if customgame in [cg_chex, cg_chex2] then
      M_SetupNextMenu(@NewDef)
    else
      M_SetupNextMenu(@EpiDef);
  end;
end;

//
//      M_Episode
//
var
  epi: integer;

procedure M_DrawEpisode;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'New Game');
  M_DrawSubHeadLine(40, 'Select Episode');

  y := DEF_MENU_ITEMS_START_Y;
  for i := 0 to EpiDef.numitems - 1 do
  begin
    if itemOn = i then
      M_WriteText(160, y, EpisodeMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, EpisodeMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontG, @big_fontB);
    y := y + 14;
  end;
end;

procedure M_VerifyNightmare(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  G_DeferedInitNew(sk_nightmare, epi + 1, 1); // JVAL nightmare become sk_nightmare
  M_ClearMenus;
end;

procedure M_ChooseSkill(choice: integer);
begin
  if choice = Ord(newg_nightmare) then
  begin
    M_StartMessage(SNIGHTMARE + #13#10 + PRESSYN, @M_VerifyNightmare, true);
    exit;
  end;

  G_DeferedInitNew(skill_t(choice), epi + 1, 1);
  M_ClearMenus;
end;

procedure M_Episode(choice: integer);
begin
  if (gamemode = shareware) and (choice <> 0) then
  begin
    M_StartMessage(SWSTRING + #13#10 + PRESSKEY, nil, false);
    M_SetupNextMenu(@ReadDef1);
    exit;
  end;

  // Yet another hack...
  if (gamemode = registered) and (choice > 2) then
  begin
    I_Warning('M_Episode(): 4th episode requires UltimateDOOM'#13#10);
    choice := 0;
  end;

  epi := choice;

  if oldsharewareversion then
    NewDef.numitems := Ord(newg_nightmare); // No nightmare in old shareware shareware
  M_SetupNextMenu(@NewDef);
end;

//
// M_Options
//
procedure M_DrawOptions;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'Options');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(opt_general) to Ord(opt_system) do
  begin
    if itemOn = i then
      M_WriteText(160, y, OptionsMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, OptionsMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontG, @big_fontB);
    y := y + 14;
  end;
end;

procedure M_DrawGeneralOptions;
var
  i, y: integer;
  str: string;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'General');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(endgame) to Ord(mousesens) do
  begin
    str := OptionsGeneralMenu[i].name;
    if i = Ord(messages) then
      if showMessages = 1 then
        str := str + ': ON'
      else
        str := str + ': OFF';
    if itemOn = i then
      M_WriteText(160, y, str, _MA_CENTER or _MC_UPPER, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, str, _MA_CENTER or _MC_UPPER, @big_fontG, @big_fontB);
    y := y + 14;
  end;

  M_DrawThermo(
    78, DEF_MENU_ITEMS_START_Y + 14 * (Ord(scrnsize) + 1) + 2, 20, m_screensize, 11);

  M_DrawThermo(
    78, DEF_MENU_ITEMS_START_Y + 14 * (Ord(mousesens) + 1) + 2, 20, mouseSensitivity, 20);
end;

procedure M_DrawSensitivity;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Mouse Sensitivity');

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivity) + 1), 20, mouseSensitivity);

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivityx) + 1), 11, mouseSensitivityX);

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivityy) + 1), 11, mouseSensitivityY);
end;

procedure M_DrawDisplayOptions;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Display Options');

  y := DEF_MENU_ITEMS_START_Y;
  for i := 0 to Ord(optdisp_end) - 1 do
  begin
    if itemOn = i then
      M_WriteText(160, y, OptionsDisplayMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, OptionsDisplayMenu[i].name, _MA_CENTER or _MC_UPPER, @big_fontG, @big_fontB);
    y := y + 14;
  end;
end;

var
  colordepths: array[boolean] of string = ('8bit', '32bit');

procedure M_DrawDisplayDetailOptions;
var
  stmp: string;
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Detail');

  ppos := M_WriteTextOption(OptionsDisplayDetailDef.x, OptionsDisplayDetailDef.y + OptionsDisplayDetailDef.itemheight * Ord(od_detaillevel), 'Detail level: ', _MA_LEFT or _MC_UPPER);
  {$IFDEF OPENGL}
  sprintf(stmp, '%s (%dx%dx32)', [detailStrings[detailLevel], SCREENWIDTH, SCREENHEIGHT]);
  {$ELSE}
  sprintf(stmp, '%s (%dx%dx%s)', [detailStrings[detailLevel], SCREENWIDTH, SCREENHEIGHT, colordepths[videomode = vm32bit]]);
  {$ENDIF}
  M_WriteTextValue(ppos.x, ppos.y, stmp, _MA_LEFT);
end;

procedure M_ChangeFullScreen(choice: integer);
begin
  {$IFDEF OPENGL}
  GL_ChangeFullScreen(not fullscreen);
  {$ELSE}
  I_ChangeFullScreen((fullscreen + 1) mod NUMFULLSCREEN_MODES);
  {$ENDIF}
end;

const
  strfullscreenmodes: array[0..NUMFULLSCREEN_MODES - 1] of string = (
    'SHARED', 'EXCLUSIVE', 'OFF'
  );

procedure M_DrawDisplaySetVideoMode;
var
  stmp: string;
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Set Video Mode');

  {$IFNDEF OPENGL}
  fullscreen := fullscreen mod NUMFULLSCREEN_MODES;
  {$ENDIF}
  ppos := M_WriteTextOption(OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_fullscreen), 'FullScreen: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, {$IFDEF OPENGL}yesnoStrings[fullscreen]{$ELSE}strfullscreenmodes[fullscreen]{$ENDIF}, _MA_LEFT or _MC_UPPER);

  if mdisplaymode_idx < 0 then
    mdisplaymode_idx := 0
  else if mdisplaymode_idx >= numdisplaymodes then
    mdisplaymode_idx := numdisplaymodes - 1;
  ppos := M_WriteTextOption(OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_screensize), 'Screen Size: ', _MA_LEFT or _MC_UPPER);
  sprintf(stmp, '(%dx%d)', [displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height]);
  M_WriteTextValue(ppos.x, ppos.y, stmp, _MA_LEFT);

  M_DrawThermo(
    OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * (Ord(odm_screensize) + 1), 30, mdisplaymode_idx, numdisplaymodes);

  if (displaymodes[mdisplaymode_idx].width = SCREENWIDTH) and (displaymodes[mdisplaymode_idx].height = SCREENHEIGHT) then
    stmp := 'No change'
  else
    sprintf(stmp, 'Set video mode to %dx%d...', [displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height]);
  M_WriteTextOption(OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_setvideomode), stmp, _MA_LEFT or _MC_UPPER);
end;

procedure M_SwitchShadeMode(choice: integer);
begin
  shademenubackground := (shademenubackground + 1) mod 3;
end;

const
  menubackrounds: array[0..2] of string =
    ('NONE', 'SHADOW', 'TEXTURE');

procedure M_DrawDisplayAppearanceOptions;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Appearence');

  ppos := M_WriteTextOption(OptionsDisplayAppearanceDef.x, OptionsDisplayAppearanceDef.y + OptionsDisplayAppearanceDef.itemheight * Ord(od_shademenubackground), 'Menu background: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, menubackrounds[shademenubackground mod 3], _MA_LEFT or _MC_UPPER);
end;

procedure M_DrawDisplayAutomapOptions;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Automap');
end;

procedure M_DrawOptionsDisplayAdvanced;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Advanced');
end;

procedure M_DrawOptionsDisplayAspectRatio;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Aspect Ratio');

  aspectratioidx := _nearest_aspect_index;
  ppos := M_WriteTextOption(OptionsDisplayAspectRatioDef.x, OptionsDisplayAspectRatioDef.y + OptionsDisplayAspectRatioDef.itemheight * Ord(oda_forceaspectratio), 'Force Aspect Ratio: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, straspectratios[_nearest_aspect_index], _MA_LEFT or _MC_UPPER);
end;

procedure M_DrawOptionsDisplayCamera;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Camera');

  chasecamera_viewxy := ibetween(chasecamera_viewxy, CHASECAMERA_XY_MIN, CHASECAMERA_XY_MAX);
  ppos := M_WriteTextOption(OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * Ord(odc_chasecameraxy), 'Chase Camera XY position: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, itoa(chasecamera_viewxy), _MA_LEFT or _MC_UPPER);

  chasecamera_viewz := ibetween(chasecamera_viewz, CHASECAMERA_Z_MIN, CHASECAMERA_Z_MAX);
  ppos := M_WriteTextOption(OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * Ord(odc_chasecameraz), 'Chase Camera Z position: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, itoa(chasecamera_viewz), _MA_LEFT or _MC_UPPER);

  M_DrawThermo(
    OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * (Ord(odc_chasecameraxy) + 1), 21, (chasecamera_viewxy - CHASECAMERA_XY_MIN) div 8, (CHASECAMERA_XY_MAX - CHASECAMERA_XY_MIN) div 8 + 1);

  M_DrawThermo(
    OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * (Ord(odc_chasecameraz) + 1), 21, (chasecamera_viewz - CHASECAMERA_Z_MIN) div 4, (CHASECAMERA_Z_MAX - CHASECAMERA_Z_MIN) div 4 + 1);
end;

{$IFNDEF OPENGL}
var
  lightmapcolorintensityidx: integer = DEFLMCOLORSENSITIVITY div 8;

procedure M_ChangeLightmapColorIntensity(choice: integer);
begin
  case choice of
    0: if lightmapcolorintensityidx > 0 then
         dec(lightmapcolorintensityidx);
    1: if lightmapcolorintensityidx < (MAXLMCOLORSENSITIVITY - MINLMCOLORSENSITIVITY) div 8 then
         inc(lightmapcolorintensityidx);
  end;
  lightmapcolorintensity := MINLMCOLORSENSITIVITY + lightmapcolorintensityidx * 8;
end;

procedure M_ChangeLightmapFadeoutFunc(choice: integer);
begin
  r_lightmapfadeoutfunc :=  (r_lightmapfadeoutfunc + 1) mod NUMLIGHTMAPFADEOUTFUNCS;
end;

procedure M_ChangeLightmapLightWidthFactor(choice: integer);
begin
  case choice of
    0: if lightwidthfactor > MINLIGHTWIDTHFACTOR then
         dec(lightwidthfactor);
    1: if lightwidthfactor < MAXLIGHTWIDTHFACTOR then
         inc(lightwidthfactor);
  end;
end;

procedure M_LightmapDefaults(choice: integer);
begin
  lightmapcolorintensity := DEFLMCOLORSENSITIVITY;
  lightwidthfactor := DEFLIGHTWIDTHFACTOR;
  r_lightmapfadeoutfunc := 0;
end;

const
  strlightmapfadefunc: array[0..NUMLIGHTMAPFADEOUTFUNCS - 1] of string =
    ('LINEAR', 'CURVED', 'PERSIST', 'COSINE', 'SIGMOID');

procedure M_DrawOptionsLightmap;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Lightmap');

  r_lightmapfadeoutfunc := ibetween(r_lightmapfadeoutfunc, 0, NUMLIGHTMAPFADEOUTFUNCS - 1);
  lightmapcolorintensityidx := (lightmapcolorintensity - 32) div 8;

  ppos := M_WriteTextOption(OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * Ord(ol_lightmapfunc), 'Fadeout function: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, strlightmapfadefunc[r_lightmapfadeoutfunc], _MA_LEFT or _MC_UPPER);

  ppos := M_WriteTextOption(OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * Ord(ol_colorintensity), 'Color intensity: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, itoa((lightmapcolorintensity * 100) div DEFLMCOLORSENSITIVITY) + '%', _MA_LEFT or _MC_UPPER);
  M_DrawThermo(
    OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * (Ord(ol_colorintensity) + 1), 21, lightmapcolorintensityidx, (MAXLMCOLORSENSITIVITY - MINLMCOLORSENSITIVITY) div 8 + 1);

  ppos := M_WriteTextOption(OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * Ord(ol_lightwidthfactor), 'Distance from source: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, itoa((lightwidthfactor * 100) div DEFLIGHTWIDTHFACTOR) + '%', _MA_LEFT or _MC_UPPER);
  M_DrawThermo(
    OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * (Ord(ol_lightwidthfactor) + 1), 21, lightwidthfactor, MAXLIGHTWIDTHFACTOR + 1);
end;
{$ENDIF}

procedure M_DrawOptionsDisplay32bit;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'True Color Options');

  ppos := M_WriteTextOption(OptionsDisplay32bitDef.x, OptionsDisplay32bitDef.y + OptionsDisplay32bitDef.itemheight * Ord(od_flatfiltering),
    'Flat filtering: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, flatfilteringstrings[extremeflatfiltering], _MA_LEFT or _MC_UPPER);
end;

{$IFDEF OPENGL}
procedure M_DrawOptionsDisplayOpenGL;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'OpenGL');
end;

procedure M_DrawOptionsDisplayOpenGLModels;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Models');
end;

procedure M_ChangeVoxelOptimization(choice: integer);
begin
  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);
  if vx_maxoptimizerpasscount = MAX_VX_OPTIMIZE then
    vx_maxoptimizerpasscount := 0
  else
    vx_maxoptimizerpasscount := vx_maxoptimizerpasscount + 1;
end;

const
  str_voxeloptimizemethod: array[0..MAX_VX_OPTIMIZE] of string = (
    'FAST', 'GOOD', 'BETTER', 'BEST'
  );

procedure M_DrawOptionsDisplayOpenGLVoxels;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Voxels');

  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);
  ppos := M_WriteTextOption(OptionsDisplayOpenGLVoxelsDef.x, OptionsDisplayOpenGLVoxelsDef.y + OptionsDisplayOpenGLVoxelsDef.itemheight * Ord(od_glv_optimize), 'Voxel mesh optimization: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, str_voxeloptimizemethod[vx_maxoptimizerpasscount], _MA_LEFT or _MC_UPPER);
end;

procedure M_ChangeTextureFiltering(choice: integer);
begin
  gld_SetCurrTexFiltering(gl_filter_t((Ord(gld_GetCurrTexFiltering) + 1) mod Ord(NUM_GL_FILTERS)));
  gld_ClearTextureMemory;
end;

procedure M_DrawOptionsDisplayOpenGLFilter;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Texture Filtering');

  ppos := M_WriteTextOption(OptionsDisplayOpenGLFilterDef.x, OptionsDisplayOpenGLFilterDef.y + OptionsDisplayOpenGLFilterDef.itemheight * Ord(od_glf_texture_filter), 'Filter: ', _MA_LEFT or _MC_UPPER);
  M_WriteTextValue(ppos.x, ppos.y, gl_tex_filter_string, _MA_LEFT or _MC_UPPER);
end;
{$ENDIF}

procedure M_Options(choice: integer);
begin
  M_SetupNextMenu(@OptionsDef);
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
    M_MenuSound;
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
  if extrahelpscreens.Count > 0 then
  begin
    extrahelpscreens_idx := 0;
    M_SetupNextMenu(@ReadDefExt);
  end
  else
    M_SetupNextMenu(@MainDef);
end;

procedure M_FinishReadExtThis(choice: integer);
begin
  inc(extrahelpscreens_idx);
  if extrahelpscreens_idx >= extrahelpscreens.Count then
  begin
    extrahelpscreens_idx := 0;
    M_SetupNextMenu(@MainDef);
  end;
end;

//
// M_QuitMARS
//
procedure M_CmdQuit;
begin
  MARS_StartSound(nil, snd_TELEPORT);
  I_WaitVBL(1000);
  G_Quit;
end;


procedure M_QuitResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  M_CmdQuit;
end;

procedure M_QuitMARS(choice: integer);
var
  endstring: string;
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
      if mouseSensitivity < 19 then
        inc(mouseSensitivity);
  end;
end;

procedure M_ChangeSensitivityX(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivityX > 0 then
        dec(mouseSensitivityX);
    1:
      if mouseSensitivityX < 10 then
        inc(mouseSensitivityX);
  end;
end;

procedure M_ChangeSensitivityY(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivityY > 0 then
        dec(mouseSensitivityY);
    1:
      if mouseSensitivityY < 10 then
        inc(mouseSensitivityY);
  end;
end;

procedure M_KeyBindings(choice: integer);
begin
  M_SetupNextMenu(@KeyBindingsDef1);
end;

procedure M_ScreenShotCmd(choice: integer);
begin
  M_FixScreenshotFormat;
  if strupper(screenshotformat) = 'PNG' then
    screenshotformat := 'JPG'
  else if strupper(screenshotformat) = 'JPG' then
    screenshotformat := 'TGA'
  else if strupper(screenshotformat) = 'TGA' then
    screenshotformat := 'PNG'
  else
    screenshotformat := 'PNG';
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

procedure M_ChangeScreenSize(choice: integer);
begin
  case choice of
    0:
      if mdisplaymode_idx > 0 then
        dec(mdisplaymode_idx);
    1:
      if mdisplaymode_idx < numdisplaymodes - 1 then
        inc(mdisplaymode_idx);
  end;
end;

procedure M_ApplyScreenSize(choice: integer);
begin
  if mdisplaymode_idx < 0 then
    mdisplaymode_idx := 0
  else if mdisplaymode_idx >= numdisplaymodes then
    mdisplaymode_idx := numdisplaymodes - 1;

  OptionsDisplayVideoModeDef.lastOn := 0;
  itemOn := 0;

  D_NotifyVideoModeChange(displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height);
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

procedure M_BoolCmdSetSize(choice: integer);
begin
  M_BoolCmd(choice);
  setsizeneeded := true;
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
  if gamestate = GS_ENDOOM then
  begin
    result := false;
    exit;
  end;

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
             (M_StringWidth(savegamestrings[saveSlot], _MA_LEFT or _MC_UPPER, @mars_fontDG) < (SAVESTRINGSIZE - 2) * 8) then
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

  // Key bindings
  if bindkeyEnter then
  begin
    case ch of
      KEY_ESCAPE:
        begin
          bindkeyEnter := false;
          KeyBindingsInfo[bindkeySlot].pkey^ := saveOldkey;
        end;
      KEY_ENTER:
        begin
          bindkeyEnter := false;
        end;
    else
      M_SetKeyBinding(bindkeySlot, ch);
      bindkeyEnter := false;
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

    menuactive := false;
    M_MenuSound;
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
          MARS_StartSound(nil, snd_ITEMUP);
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
          MARS_StartSound(nil, snd_ITEMUP);
          result := true;
          exit;
        end;
      KEY_F1:      // Help key
        begin
          M_StartControlPanel;
          if gamemode = retail then
            currentMenu := @ReadDef2
          else
            currentMenu := @ReadDef1;

          itemOn := 0;
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F2:  // Save
        begin
          M_StartControlPanel;
          M_MenuSound;
          M_SaveGame(0);
          result := true;
          exit;
        end;
      KEY_F3:  // Load
        begin
          M_StartControlPanel;
          M_MenuSound;
          M_LoadGame(0);
          result := true;
          exit;
        end;
      KEY_F4:   // Sound Volume
        begin
          M_StartControlPanel;
          currentMenu := @SoundVolDef;
          itemOn := Ord(sfx_vol);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F5:   // Detail toggle
        begin
          M_ChangeDetail(0);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F6:   // Quicksave
        begin
          M_MenuSound;
          M_QuickSave;
          result := true;
          exit;
        end;
      KEY_F7:   // End game
        begin
          M_MenuSound;
          M_EndGame(0);
          result := true;
          exit;
        end;
      KEY_F8:   // Toggle messages
        begin
          M_ChangeMessages(0);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F9:   // Quickload
        begin
          M_MenuSound;
          M_QuickLoad;
          result := true;
          exit;
        end;
      KEY_F10:  // Quit DOOM
        begin
          M_MenuSound;
          M_QuitMARS(0);
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
          {$IFDEF OPENGL}
          I_SetPalette(palette);
          V_SetPalette(palette);
          {$ELSE}
          IV_SetPalette(palette);
          {$ENDIF}
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
            I_ChangeFullScreen((fullscreen + 1) mod NUMFULLSCREEN_MODES);
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
      M_MenuSound;
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
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_PAGEDOWN:
      begin
        itemOn := currentMenu.numitems;
        repeat
          dec(itemOn);
          M_MenuSound;
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
          M_MenuSound;
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
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_LEFTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          M_MenuSound;
          currentMenu.menuitems[itemOn].routine(0);
        end
        else if (currentMenu.leftMenu <> nil) and not (ev._type in [ev_mouse, ev_joystick]) then
        begin
          currentMenu.lastOn := itemOn;
          currentMenu := currentMenu.leftMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
    KEY_RIGHTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          M_MenuSound;
          currentMenu.menuitems[itemOn].routine(1);
        end
        else if (currentMenu.rightMenu <> nil) and not (ev._type in [ev_mouse, ev_joystick]) then
        begin
          currentMenu.lastOn := itemOn;
          currentMenu := currentMenu.rightMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
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
            M_MenuSound;
          end
          else
          begin
            currentMenu.menuitems[itemOn].routine(itemOn);
            M_MenuSound;
          end;
        end;
        result := true;
        exit;
      end;
    KEY_ESCAPE:
      begin
        currentMenu.lastOn := itemOn;
        M_ClearMenus;
        M_MenuSound;
        result := true;
        exit;
      end;
    KEY_BACKSPACE:
      begin
        currentMenu.lastOn := itemOn;
        // JVAL 20200122 - Extended help screens
        if (currentMenu = @ReadDefExt) and (extrahelpscreens_idx > 0) then
        begin
          dec(extrahelpscreens_idx);
          M_MenuSound;
        end
        else if currentMenu.prevMenu <> nil then
        begin
          currentMenu := currentMenu.prevMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
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
          M_MenuSound;
          result := true;
          exit;
        end;
      for i := 0 to itemOn do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          M_MenuSound;
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

  mn_makescreenshot := true;
  menuactive := true;
  currentMenu := @MainDef;// JDC
  itemOn := currentMenu.lastOn; // JDC
end;

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
  threadmenushader: TDThread;

procedure M_MenuShader;
begin
  shademenubackground := shademenubackground mod 3;
  if not wipedisplay and (shademenubackground >= 1) then
  begin
    if usemultithread then
    begin
    // JVAL
      threadmenushader.Activate(nil);
      {$IFDEF OPENGL}
      V_ShadeBackground(0, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) div 2);
      {$ELSE}
      V_ShadeScreen(SCN_FG, 0, SCREENWIDTH * SCREENHEIGHT div 2);
      {$ENDIF}
      // Wait for extra thread to terminate.
      threadmenushader.Wait;
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

//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//
procedure M_Drawer;
var
  i: integer;
  max: integer;
  str: string;
  len: integer;
  x, y: integer;
  mheight: integer;
  ppos: menupos_t;
  rstr: string;
  msgfont: Ppatch_tPArray;
begin
  // Horiz. & Vertically center string and print it.
  if messageToPrint <> 0 then
  begin
    msgfont := @yellow_font; //@mars_fontLG;
    mheight := M_StringHeight(messageString, msgfont) + 2;
    y := (200 - mheight) div 2;
    mheight := y + mheight + 20;
    MT_ZeroMemory(screens[SCN_TMP], 320 * mheight);
    len := Length(messageString);
    str := '';
    for i := 1 to len do
    begin
      if messageString[i] = #13 then
      else if messageString[i] = #10 then
      begin
        y := y + msgfont[0].height;
        M_WriteText(160, y, str, _MA_CENTER or _MC_UPPER, msgfont);
        str := '';
      end
      else
        str := str + messageString[i];
    end;
    if str <> '' then
    begin
      y := y + msgfont[0].height;
      M_WriteText(160, y, str, _MA_CENTER or _MC_UPPER, msgfont);
    end;

    M_FinishUpdate(mheight);
    exit;
  end;

  if not menuactive then
    exit;

  MT_ZeroMemory(screens[SCN_TMP], 320 * 200);

  if (shademenubackground = 2) and (currentMenu.flags and FLG_MN_TEXTUREBK <> 0) then
    M_DrawFlatBackground(menubackgroundflat);

  if Assigned(currentMenu.drawproc) then
    currentMenu.drawproc; // call Draw routine

  // DRAW MENU
  x := DEF_MENU_ITEMS_START_X;
  y := DEF_MENU_ITEMS_START_Y;

  max := currentMenu.numitems;

  for i := 0 to max - 1 do
  begin
    str := currentMenu.menuitems[i].name;
    if str <> '' then
    begin
      if str[1] = '!' then // Draw text with Yes/No
      begin
        delete(str, 1, 1);
        if currentMenu.menuitems[i].pBoolVal <> nil then
        begin
          ppos := M_WriteTextOption(x, y, str + ': ', _MA_LEFT or _MC_UPPER);
          M_WriteTextValue(ppos.x, ppos.y, yesnoStrings[currentMenu.menuitems[i].pBoolVal^], _MA_LEFT or _MC_UPPER);
        end
        else
          M_WriteTextOption(x, y, str, _MA_LEFT or _MC_UPPER);
      end;
    end;
    y := y + currentMenu.itemheight;
  end;

  if Assigned(currentMenu.drawproc) then
    currentMenu.drawproc; // call Draw routine

  if currentMenu.leftMenu <> nil then
    M_WriteTextValue(5, 44, '<<', _MA_LEFT or _MC_UPPER);

  if currentMenu.rightMenu <> nil then
  begin
    rstr := '>>';
    M_WriteTextValue(315, 44, rstr, _MA_RIGHT or _MC_UPPER);
  end;

  if currentMenu.flags and FLG_MN_DRAWITEMON <> 0 then
    V_DrawPatch(x + ARROWXOFFS, currentMenu.y + itemOn * currentMenu.itemheight + ARROWYOFFS, SCN_TMP, p_bulletind, false);

  M_FinishUpdate(200);
end;

//
// M_Ticker
//
procedure M_Ticker;
begin
//  dec(skullAnimCounter);
//  if skullAnimCounter <= 0 then
//  begin
//    whichSkull := whichSkull xor 1;
//    skullAnimCounter := 8;
//  end;
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

//
// M_Init
//
procedure M_Init;
var
  i: integer;
  lump: integer;
begin
  option_menu_font := @yellow_font;
  value_menu_font := @white_font;
  shade_menu_font := @dark_font;

  m_detail := W_CacheLumpName('M_DETAIL', PU_STATIC);
  m_lgttl := W_CacheLumpName('M_LGTTL', PU_STATIC);
  m_sgttl := W_CacheLumpName('M_SGTTL', PU_STATIC);

  currentMenu := @MainDef;
  menuactive := false;
  itemOn := currentMenu.lastOn;
//  whichSkull := 0;
//  skullAnimCounter := 10;
  m_screensize := screenblocks - 4;
  messageToPrint := 0;
  messageString := '';
  messageLastMenuActive := menuactive;
  quickSaveSlot := -1;

  // Here we could catch other version dependencies,
  //  like HELP1/2, and four episodes.

  case gamemode of
    commercial:
      begin
        // This is used because DOOM 2 had only one HELP
        //  page. I use CREDIT as second page now, but
        //  kept this hack for educational purposes.
        MainMenu[Ord(mm_readthis)] := MainMenu[Ord(mm_quitmars)];
        dec(MainDef.numitems);
        MainDef.y := MainDef.y + 8;
        NewDef.prevMenu := @MainDef;
        ReadDef1.drawproc := M_DrawReadThis1;
        ReadDef1.x := 330;
        ReadDef1.y := 165;
        ReadMenu1[0].routine := @M_FinishReadThis;
      end;
    shareware:
      begin
        ReadDef2.x := 280;
        ReadDef2.y := 185; // x,y of menu
        // We need to remove the fourth episode.
        // Episode 2 and 3 are handled,
        // branching to an ad screen.
        dec(EpiDef.numitems);
      end;
    registered:
      begin
        // We need to remove the fourth episode.
        dec(EpiDef.numitems);
      end;
  end;

  // JVAL 20200122 - Extended help screens
  extrahelpscreens := TDNumberList.Create;
  for i := 1 to 99 do
  begin
    lump := W_CheckNumForName('HELP' + IntToStrzFill(2, i));
    if lump >= 0 then
      extrahelpscreens.Add(lump);
  end;
  extrahelpscreens_idx := 0;

  C_AddCmd('keyboardmode', @M_CmdKeyboardMode);
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
end;

procedure M_ShutDownMenus;
begin
  threadmenushader.Free;
  extrahelpscreens.Free;
end;

procedure M_InitMenus;
var
  i: integer;
  pmi: Pmenuitem_t;
begin
  threadmenushader := TDThread.Create(@M_Thr_ShadeScreen);

////////////////////////////////////////////////////////////////////////////////
//gammamsg
  gammamsg[0] := GAMMALVL0;
  gammamsg[1] := GAMMALVL1;
  gammamsg[2] := GAMMALVL2;
  gammamsg[3] := GAMMALVL3;
  gammamsg[4] := GAMMALVL4;

////////////////////////////////////////////////////////////////////////////////
  p_bulletind := W_CacheLumpName('SFNTB045', PU_STATIC);

////////////////////////////////////////////////////////////////////////////////
// MainMenu
  pmi := @MainMenu[0];
  pmi.status := 1;
  pmi.name := 'New Game';
  pmi.cmd := '';
  pmi.routine := @M_NewGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'n';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Options';
  pmi.cmd := '';
  pmi.routine := @M_Options;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Load Game';
  pmi.cmd := '';
  pmi.routine := @M_LoadGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Save Game';
  pmi.cmd := '';
  pmi.routine := @M_SaveGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  // Another hickup with Special edition.
  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Help';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Quit';
  pmi.cmd := '';
  pmi.routine := @M_QuitMARS;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'q';

////////////////////////////////////////////////////////////////////////////////
//MainDef
  MainDef.numitems := Ord(main_end);
  MainDef.prevMenu := nil;
  MainDef.menuitems := Pmenuitem_tArray(@MainMenu);
  MainDef.drawproc := @M_DrawMainMenu;  // draw routine
  MainDef.x := DEF_MENU_ITEMS_START_X;
  MainDef.y := DEF_MENU_ITEMS_START_Y;
  MainDef.lastOn := 0;
  MainDef.itemheight := BIGLINEHEIGHT;
  MainDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//EpisodeMenu
  pmi := @EpisodeMenu[0];
  pmi.status := 1;
  pmi.name := 'Episode 1';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '1';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Episode 2';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '2';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Episode 3';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Episode 4';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '4';

////////////////////////////////////////////////////////////////////////////////
//EpiDef
  EpiDef.numitems := Ord(ep_end); // # of menu items
  EpiDef.prevMenu := @MainDef; // previous menu
  EpiDef.menuitems := Pmenuitem_tArray(@EpisodeMenu);  // menu items
  EpiDef.drawproc := @M_DrawEpisode;  // draw routine
  EpiDef.x := DEF_MENU_ITEMS_START_X;
  EpiDef.y := DEF_MENU_ITEMS_START_Y;
  EpiDef.lastOn := Ord(ep1); // last item user was on in menu
  EpiDef.itemheight := BIGLINEHEIGHT;
  EpiDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//NewGameMenu
  pmi := @NewGameMenu[0];
  pmi.status := 1;
  pmi.name := 'Beginner';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Easy';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'h';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Normal';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'h';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Hard';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Nightmare';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'n';

////////////////////////////////////////////////////////////////////////////////
//NewDef
  NewDef.numitems := Ord(newg_end); // # of menu items
  NewDef.prevMenu := @EpiDef; // previous menu
  NewDef.menuitems := Pmenuitem_tArray(@NewGameMenu);  // menu items
  NewDef.drawproc := @M_DrawNewGame;  // draw routine
  NewDef.x := DEF_MENU_ITEMS_START_X;
  NewDef.y := DEF_MENU_ITEMS_START_Y;
  NewDef.lastOn := Ord(newg_hurtme); // last item user was on in menu
  NewDef.itemheight := BIGLINEHEIGHT;
  NewDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//OptionsMenu
  pmi := @OptionsMenu[0];
  pmi.status := 1;
  pmi.name := 'General';
  pmi.cmd := '';
  pmi.routine := @M_OptionsGeneral;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Display';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Sound';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSound;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Compatibility';
  pmi.cmd := '';
  pmi.routine := @M_OptionsCompatibility;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Controls';
  pmi.cmd := '';
  pmi.routine := @M_OptionsConrols;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'System';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSystem;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDef
  OptionsDef.numitems := Ord(opt_end); // # of menu items
  OptionsDef.prevMenu := @MainDef; // previous menu
  OptionsDef.menuitems := Pmenuitem_tArray(@OptionsMenu);  // menu items
  OptionsDef.drawproc := @M_DrawOptions;  // draw routine
  OptionsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDef.lastOn := 0; // last item user was on in menu
  OptionsDef.itemheight := BIGLINEHEIGHT;
  OptionsDef.flags := FLG_MN_TEXTUREBK;

////////////////////////////////////////////////////////////////////////////////
//OptionsGeneralMenu
  pmi := @OptionsGeneralMenu[0];
  pmi.status := 1;
  pmi.name := 'End Game';
  pmi.cmd := '';
  pmi.routine := @M_EndGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Messages';
  pmi.cmd := '';
  pmi.routine := @M_ChangeMessages;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 2;
  pmi.name := 'Screen Size';
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
  pmi.name := 'Mouse Sensitivity';
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
  OptionsGeneralDef.leftMenu := @SystemDef;
  OptionsGeneralDef.rightMenu := @OptionsDisplayDef;
  OptionsGeneralDef.menuitems := Pmenuitem_tArray(@OptionsGeneralMenu);  // menu items
  OptionsGeneralDef.drawproc := @M_DrawGeneralOptions;  // draw routine
  OptionsGeneralDef.x := DEF_MENU_ITEMS_START_X;
  OptionsGeneralDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsGeneralDef.lastOn := 0; // last item user was on in menu
  OptionsGeneralDef.itemheight := BIGLINEHEIGHT;
  OptionsGeneralDef.flags := FLG_MN_TEXTUREBK;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayMenu
  pmi := @OptionsDisplayMenu[0];
  pmi.status := 1;
{$IFDEF OPENGL}
  pmi.name := 'OpenGL';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGL;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';
{$ELSE}
  pmi.name := 'Detail';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayDetail;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';
{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Automap';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAutomap;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Appearence';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAppearance;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Advanced';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAdvanced;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'True Color Options';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay32bit;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDef
  OptionsDisplayDef.numitems := Ord(optdisp_end); // # of menu items
  OptionsDisplayDef.prevMenu := @OptionsDef; // previous menu
  OptionsDisplayDef.leftMenu := @OptionsGeneralDef; // previous menu
  OptionsDisplayDef.rightMenu := @SoundDef; // previous menu
  OptionsDisplayDef.menuitems := Pmenuitem_tArray(@OptionsDisplayMenu);  // menu items
  OptionsDisplayDef.drawproc := @M_DrawDisplayOptions;  // draw routine
  OptionsDisplayDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDef.itemheight := BIGLINEHEIGHT;
  OptionsDisplayDef.flags := FLG_MN_TEXTUREBK;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailMenu
  pmi := @OptionsDisplayDetailMenu[0];
  pmi.status := 1;
  pmi.name := '!Set video mode...';
  pmi.cmd := '';
  pmi.routine := @M_SetVideoMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeDetail;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow low details';
  pmi.cmd := 'allowlowdetails';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowlowdetails;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow high details';
  pmi.cmd := 'allowhidetails';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowhidetails;
  pmi.alphaKey := 'h';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailDef
  OptionsDisplayDetailDef.numitems := Ord(optdispdetail_end); // # of menu items
  OptionsDisplayDetailDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayDetailDef.leftMenu := @OptionsDisplay32bitDef; // left menu
  OptionsDisplayDetailDef.rightMenu := @OptionsDisplayAutomapDef; // right menu
  OptionsDisplayDetailDef.menuitems := Pmenuitem_tArray(@OptionsDisplayDetailMenu);  // menu items
  OptionsDisplayDetailDef.drawproc := @M_DrawDisplayDetailOptions;  // draw routine
  OptionsDisplayDetailDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayDetailDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayDetailDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDetailDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayDetailDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayVideoModeMenu
  pmi := @OptionsDisplayVideoModeMenu[0];
  pmi.status := 1;
  pmi.name := '!Fullscreen';
  pmi.cmd := '';
  pmi.routine := @M_ChangeFullScreen;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeScreenSize;
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
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ApplyScreenSize;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayVideoModeDef
  OptionsDisplayVideoModeDef.numitems := Ord(optdispvideomode_end); // # of menu items
  OptionsDisplayVideoModeDef.prevMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // previous menu
  OptionsDisplayVideoModeDef.leftMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // left menu
  OptionsDisplayVideoModeDef.menuitems := Pmenuitem_tArray(@OptionsDisplayVideoModeMenu);  // menu items
  OptionsDisplayVideoModeDef.drawproc := @M_DrawDisplaySetVideoMode;  // draw routine
  OptionsDisplayVideoModeDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayVideoModeDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayVideoModeDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayVideoModeDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayVideoModeDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

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

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Automap grid';
  pmi.cmd := 'automapgrid';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @automapgrid;
  pmi.alphaKey := 'g';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAutomapDef
  OptionsDisplayAutomapDef.numitems := Ord(optdispautomap_end); // # of menu items
  OptionsDisplayAutomapDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAutomapDef.leftMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // left menu
  OptionsDisplayAutomapDef.rightMenu := @OptionsDisplayAppearanceDef; // right menu
  OptionsDisplayAutomapDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAutomapMenu);  // menu items
  OptionsDisplayAutomapDef.drawproc := @M_DrawDisplayAutomapOptions;  // draw routine
  OptionsDisplayAutomapDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAutomapDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAutomapDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAutomapDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAutomapDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

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
  pmi.name := '!Draw Crosshair';
  pmi.cmd := 'drawfps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @drawcrosshair;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Extended Statusbar';
  pmi.cmd := 'extendedstatusbar';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @extendedstatusbar;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Menu background';
  pmi.cmd := '';
  pmi.routine := @M_SwitchShadeMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display disk busy icon';
  pmi.cmd := 'displaydiskbusyicon';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @displaydiskbusyicon;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display ENDOOM screen';
  pmi.cmd := 'displayendscreen';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @displayendscreen;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display demo playback progress';
  pmi.cmd := 'showdemoplaybackprogress';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @showdemoplaybackprogress;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Show obituaries';
  pmi.cmd := 'show_obituaries';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @show_obituaries;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Colored blood for vanilla monsters';
  pmi.cmd := 'p_confcoloredblood';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @p_confcoloredblood;
  pmi.alphaKey := 'c';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAppearanceDef
  OptionsDisplayAppearanceDef.numitems := Ord(optdispappearance_end); // # of menu items
  OptionsDisplayAppearanceDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAppearanceDef.leftMenu := @OptionsDisplayAutomapDef; // left menu
  OptionsDisplayAppearanceDef.rightMenu := @OptionsDisplayAdvancedDef; // rightmenu
  OptionsDisplayAppearanceDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAppearanceMenu);  // menu items
  OptionsDisplayAppearanceDef.drawproc := @M_DrawDisplayAppearanceOptions;  // draw routine
  OptionsDisplayAppearanceDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAppearanceDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAppearanceDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAppearanceDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAppearanceDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedMenu
  pmi := @OptionsDisplayAdvancedMenu[0];
  pmi.status := 1;
  pmi.name := '!Aspect Ratio...';
  pmi.cmd := '';
  pmi.routine := @M_OptionAspectRatio;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Camera...';
  pmi.cmd := '';
  pmi.routine := @M_OptionCameraShift;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  {$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Lightmap...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayLightmap;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'l';
  {$ENDIF}

  {$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Asynchronous DirectX blit';
  pmi.cmd := 'r_bltasync';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @r_bltasync;
  pmi.alphaKey := 'a';
  {$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Transparent sprites';
  pmi.cmd := 'usetransparentsprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usetransparentsprites;
  pmi.alphaKey := 's';

{$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Diher 8 bit transparency';
  pmi.cmd := 'diher8bittransparency';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @diher8bittransparency;
  pmi.alphaKey := 'd';
{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Uncapped framerate';
  pmi.cmd := 'interpolate';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @interpolate;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Interpolate on capped';
  pmi.cmd := 'interpolateoncapped';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @interpolateoncapped;
  pmi.alphaKey := 'i';

{$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!True 3d emulation';
  pmi.cmd := 'usefake3d';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usefake3d;
  pmi.alphaKey := 'f';
{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Auto fix memory stall';
  pmi.cmd := 'fixstallhack';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @fixstallhack;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Hide duplicated barrels';
  pmi.cmd := 'hidedoublicatedbarrels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @hidedoublicatedbarrels;
  pmi.alphaKey := 'b';

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
  pmi.name := '!Precise R_ScaleFromGlobalAngle';
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

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedDef
  OptionsDisplayAdvancedDef.numitems := Ord(optdispadvanced_end); // # of menu items
  OptionsDisplayAdvancedDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAdvancedDef.leftMenu := @OptionsDisplayAppearanceDef; // left menu
  OptionsDisplayAdvancedDef.rightMenu := @OptionsDisplay32bitDef; // right menu
  OptionsDisplayAdvancedDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAdvancedMenu);  // menu items
  OptionsDisplayAdvancedDef.drawproc := @M_DrawOptionsDisplayAdvanced;  // draw routine
  OptionsDisplayAdvancedDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAdvancedDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAdvancedDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAdvancedDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAdvancedDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAspectRatioMenu
  pmi := @OptionsDisplayAspectRatioMenu[0];
  pmi.status := 1;
  pmi.name := '!Widescreen support';
  pmi.cmd := 'widescreensupport';
  pmi.routine := @M_BoolCmdSetSize;
  pmi.pBoolVal := @widescreensupport;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Player Sprites Stretch';
  pmi.cmd := 'excludewidescreenplayersprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @excludewidescreenplayersprites;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Force Aspect Ratio';
  pmi.cmd := '';
  pmi.routine := @M_SwitchForcedAspectRatio;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Intermission screens resize';
  pmi.cmd := 'intermissionstretch';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @intermissionstretch;
  pmi.alphaKey := 'i';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAspectRatioDef
  OptionsDisplayAspectRatioDef.numitems := Ord(optdispaspect_end); // # of menu items
  OptionsDisplayAspectRatioDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsDisplayAspectRatioDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplayAspectRatioDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAspectRatioMenu);  // menu items
  OptionsDisplayAspectRatioDef.drawproc := @M_DrawOptionsDisplayAspectRatio;  // draw routine
  OptionsDisplayAspectRatioDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAspectRatioDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAspectRatioDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAspectRatioDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAspectRatioDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayCameraMenu
  pmi := @OptionsDisplayCameraMenu[0];
  pmi.status := 1;
  pmi.name := '!Look Up/Down';
  pmi.cmd := 'zaxisshift';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @zaxisshift;
  pmi.alphaKey := 'z';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Chase camera';
  pmi.cmd := 'chasecamera';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @chasecamera;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Chase Camera XY position';
  pmi.cmd := '';
  pmi.routine := @M_ChangeCameraXY;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Chase Camera Z position';
  pmi.cmd := '';
  pmi.routine := @M_ChangeCameraZ;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'z';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;


////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayCameraDef
  OptionsDisplayCameraDef.numitems := Ord(optdispcamera_end); // # of menu items
  OptionsDisplayCameraDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsDisplayCameraDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplayCameraDef.menuitems := Pmenuitem_tArray(@OptionsDisplayCameraMenu);  // menu items
  OptionsDisplayCameraDef.drawproc := @M_DrawOptionsDisplayCamera;  // draw routine
  OptionsDisplayCameraDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayCameraDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayCameraDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayCameraDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayCameraDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

{$IFNDEF OPENGL}
////////////////////////////////////////////////////////////////////////////////
//OptionsLightmapMenu
  pmi := @OptionsLightmapMenu[0];

  pmi.status := 1;
  pmi.name := '!Light effects';
  pmi.cmd := 'r_uselightmaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @r_uselightmaps;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Fadeout function';
  pmi.cmd := '';
  pmi.routine := @M_ChangeLightmapFadeoutFunc;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Color intensity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeLightmapColorIntensity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Distance from source';
  pmi.cmd := '';
  pmi.routine := @M_ChangeLightmapLightWidthFactor;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Reset to default...';
  pmi.cmd := '';
  pmi.routine := @M_LightmapDefaults;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

////////////////////////////////////////////////////////////////////////////////
//OptionsLightmapDef
  OptionsLightmapDef.numitems := Ord(ol_lightmap_end); // # of menu items
  OptionsLightmapDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsLightmapDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsLightmapDef.menuitems := Pmenuitem_tArray(@OptionsLightmapMenu);  // menu items
  OptionsLightmapDef.drawproc := @M_DrawOptionsLightmap;  // draw routine
  OptionsLightmapDef.x := DEF_MENU_ITEMS_START_X;
  OptionsLightmapDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsLightmapDef.lastOn := 0; // last item user was on in menu
  OptionsLightmapDef.itemheight := SMALLLINEHEIGHT;
  OptionsLightmapDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;
{$ENDIF}
////////////////////////////////////////////////////////////////////////////////
//OptionsDisplay32bitMenu
  pmi := @OptionsDisplay32bitMenu[0];
  pmi.status := 1;
  pmi.name := '!Glow light effects';
  pmi.cmd := 'uselightboost';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @uselightboost;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Glow light in invulnerability';
  pmi.cmd := 'uselightboostgodmode';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @uselightboostgodmode;
  pmi.alphaKey := 'i';

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
  pmi.name := '!Use classic fuzz effect in 32 bit';
  pmi.cmd := 'use32bitfuzzeffect';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @use32bitfuzzeffect;
  pmi.alphaKey := 'f';

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
//OptionsDisplay32bitDef
  OptionsDisplay32bitDef.numitems := Ord(optdisp32bit_end); // # of menu items
  OptionsDisplay32bitDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplay32bitDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplay32bitDef.rightMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // right menu
  OptionsDisplay32bitDef.menuitems := Pmenuitem_tArray(@OptionsDisplay32bitMenu);  // menu items
  OptionsDisplay32bitDef.drawproc := @M_DrawOptionsDisplay32bit;  // draw routine
  OptionsDisplay32bitDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplay32bitDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplay32bitDef.lastOn := 0; // last item user was on in menu
  OptionsDisplay32bitDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplay32bitDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

{$IFDEF OPENGL}
////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLMenu
  pmi := @OptionsDisplayOpenGLMenu[0];
  pmi.status := 1;
  pmi.name := '!Set video mode...';
  pmi.cmd := '';
  pmi.routine := @M_SetVideoMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Models...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLModels;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Voxels...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLVoxels;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Texture filtering...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLFilter;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use fog';
  pmi.cmd := 'use_fog';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @use_fog;
  pmi.alphaKey := 'u';

  {$IFDEF DEBUG}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw Sky';
  pmi.cmd := 'gl_drawsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawsky;
  pmi.alphaKey := 's';
  {$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use stencil buffer for sky';
  pmi.cmd := 'gl_stencilsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_stencilsky;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Render wireframe';
  pmi.cmd := 'gl_renderwireframe';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_renderwireframe;
  pmi.alphaKey := 'w';

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
  pmi.name := '!Limit framerate to screen sync';
  pmi.cmd := 'gl_screensync';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_screensync;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLDef
  OptionsDisplayOpenGLDef.numitems := Ord(optdispopengl_end); // # of menu items
  OptionsDisplayOpenGLDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayOpenGLDef.leftMenu := @OptionsDisplay32bitDef; // left menu
  OptionsDisplayOpenGLDef.rightMenu := @OptionsDisplayAutomapDef; // right menu
  OptionsDisplayOpenGLDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLMenu);  // menu items
  OptionsDisplayOpenGLDef.drawproc := @M_DrawOptionsDisplayOpenGL;  // draw routine
  OptionsDisplayOpenGLDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLModelsMenu
  pmi := @OptionsDisplayOpenGLModelsMenu[0];
  pmi.status := 1;
  pmi.name := '!Draw models instead of sprites';
  pmi.cmd := 'gl_drawmodels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawmodels;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Smooth md2 model movement';
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

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLModelsDef
  OptionsDisplayOpenGLModelsDef.numitems := Ord(optglmodels_end); // # of menu items
  OptionsDisplayOpenGLModelsDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLModelsDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLModelsDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLModelsMenu);  // menu items
  OptionsDisplayOpenGLModelsDef.drawproc := @M_DrawOptionsDisplayOpenGLModels;  // draw routine
  OptionsDisplayOpenGLModelsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLModelsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLModelsDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLModelsDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLModelsDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLVoxelsMenu
  pmi := @OptionsDisplayOpenGLVoxelsMenu[0];
  pmi.status := 1;
  pmi.name := '!Draw voxels instead of sprites';
  pmi.cmd := 'gl_drawvoxels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawvoxels;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Voxel mesh optimization';
  pmi.cmd := '';
  pmi.routine := @M_ChangeVoxelOptimization;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  {$IFDEF DEBUG}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Generate sprites from voxels';
  pmi.cmd := 'r_generatespritesfromvoxels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @r_generatespritesfromvoxels;
  pmi.alphaKey := 'g';
  {$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLVoxelsDef
  OptionsDisplayOpenGLVoxelsDef.numitems := Ord(optglvoxels_end); // # of menu items
  OptionsDisplayOpenGLVoxelsDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLVoxelsDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLVoxelsDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLVoxelsMenu);  // menu items
  OptionsDisplayOpenGLVoxelsDef.drawproc := @M_DrawOptionsDisplayOpenGLVoxels;  // draw routine
  OptionsDisplayOpenGLVoxelsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLVoxelsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLVoxelsDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLVoxelsDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLVoxelsDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLFilterMenu
  pmi := @OptionsDisplayOpenGLFilterMenu[0];
  pmi.status := 1;
  pmi.name := '!Filter';
  pmi.cmd := '';
  pmi.routine := @M_ChangeTextureFiltering;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Anisotropic texture filtering';
  pmi.cmd := 'gl_texture_filter_anisotropic';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_texture_filter_anisotropic;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Linear HUD filtering';
  pmi.cmd := 'gl_linear_hud';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_linear_hud;
  pmi.alphaKey := 'l';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLFilterDef
  OptionsDisplayOpenGLFilterDef.numitems := Ord(optglfilter_end); // # of menu items
  OptionsDisplayOpenGLFilterDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLFilterDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLFilterDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLFilterMenu);  // menu items
  OptionsDisplayOpenGLFilterDef.drawproc := @M_DrawOptionsDisplayOpenGLFilter;  // draw routine
  OptionsDisplayOpenGLFilterDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLFilterDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLFilterDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLFilterDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLFilterDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;
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
  ReadDef1.drawproc := @M_DrawReadThis1;  // draw routine
  ReadDef1.x := 330;
  ReadDef1.y := 165; // x,y of menu
  ReadDef1.lastOn := 0; // last item user was on in menu
  ReadDef1.itemheight := BIGLINEHEIGHT;
  ReadDef1.flags := 0;

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
  ReadDef2.drawproc := @M_DrawReadThis2;  // draw routine
  ReadDef2.x := 330;
  ReadDef2.y := 165; // x,y of menu
  ReadDef2.lastOn := 0; // last item user was on in menu
  ReadDef2.itemheight := BIGLINEHEIGHT;
  ReadDef2.flags := 0;

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
//ReadDef2
  ReadDef3.numitems := Ord(read3_end); // # of menu items
  ReadDef3.prevMenu := @ReadDef2; // previous menu
  ReadDef3.menuitems := Pmenuitem_tArray(@ReadMenu3);  // menu items
  ReadDef3.drawproc := @M_DrawReadThis3;  // draw routine
  ReadDef3.x := 330;
  ReadDef3.y := 165; // x,y of menu
  ReadDef3.lastOn := 0; // last item user was on in menu
  ReadDef3.itemheight := BIGLINEHEIGHT;
  ReadDef3.flags := 0;

// JVAL 20200122 - Extended help screens
////////////////////////////////////////////////////////////////////////////////
//ReadMenuExt
  pmi := @ReadMenuExt[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_FinishReadExtThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDefExt
  ReadDefExt.numitems := Ord(readext_end); // # of menu items
  ReadDefExt.prevMenu := @ReadDef3; // previous menu
  ReadDefExt.menuitems := Pmenuitem_tArray(@ReadMenuExt);  // menu items
  ReadDefExt.drawproc := @M_DrawReadThisExt;  // draw routine
  ReadDefExt.x := 330;
  ReadDefExt.y := 165; // x,y of menu
  ReadDefExt.lastOn := 0; // last item user was on in menu
  ReadDefExt.itemheight := BIGLINEHEIGHT;
  ReadDefExt.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//SoundMenu
  pmi := @SoundMenu[0];
  pmi.status := 1;
  pmi.name := '!Volume Control...';
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
  SoundDef.leftMenu := @OptionsDisplayDef; // left menu
  SoundDef.rightMenu := @CompatibilityDef; // left menu
  SoundDef.menuitems := Pmenuitem_tArray(@SoundMenu);  // menu items
  SoundDef.drawproc := @M_DrawSound;  // draw routine
  SoundDef.x := DEF_MENU_ITEMS_START_X;
  SoundDef.y := DEF_MENU_ITEMS_START_Y;
  SoundDef.lastOn := 0; // last item user was on in menu
  SoundDef.itemheight := SMALLLINEHEIGHT;
  SoundDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//SoundVolMenu
  pmi := @SoundVolMenu[0];
  pmi.status := 2;
  pmi.name := '!Sound FX Volume';
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
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Music Volume';
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
  SoundVolDef.drawproc := @M_DrawSoundVol;  // draw routine
  SoundVolDef.x := DEF_MENU_ITEMS_START_X;
  SoundVolDef.y := DEF_MENU_ITEMS_START_Y;
  SoundVolDef.lastOn := 0; // last item user was on in menu
  SoundVolDef.itemheight := SMALLLINEHEIGHT;
  SoundVolDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

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
  pmi.name := '!Allow player crouching';
  pmi.cmd := 'allowplayercrouch';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowplayercrouch;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Show briefing screen';
  pmi.cmd := 'showbriefingscreen';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @showbriefingscreen;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Show intermission screen';
  pmi.cmd := 'showintermissionscreen';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @showintermissionscreen;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow player breath';
  pmi.cmd := 'allowplayerbreath';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowplayerbreath;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Keep cheats when reborn';
  pmi.cmd := 'keepcheatsinplayerreborn';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @keepcheatsinplayerreborn;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Boss death ends level';
  pmi.cmd := 'majorbossdeathendsdoom1level';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @majorbossdeathendsdoom1level;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Spawn random monsters';
  pmi.cmd := 'spawnrandommonsters';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @spawnrandommonsters;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Splashes on special terrains';
  pmi.cmd := 'allowterrainsplashes';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowterrainsplashes;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Dogs (Marine Best Friend)';
  pmi.cmd := '';
  pmi.routine := @M_ChangeDogs;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Treat gldefs as lightdef';
  pmi.cmd := 'gldefs_as_lightdef';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gldefs_as_lightdef;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Treat decorate as actordef';
  pmi.cmd := 'decorate_as_actordef';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @decorate_as_actordef;
  pmi.alphaKey := 'd';

////////////////////////////////////////////////////////////////////////////////
//CompatibilityDef
  CompatibilityDef.numitems := Ord(cmp_end); // # of menu items
  CompatibilityDef.prevMenu := @OptionsDef; // previous menu
  CompatibilityDef.leftMenu := @SoundDef; // left menu
  CompatibilityDef.rightMenu := @ControlsDef; // right menu
  CompatibilityDef.menuitems := Pmenuitem_tArray(@CompatibilityMenu);  // menu items
  CompatibilityDef.drawproc := @M_DrawCompatibility;  // draw routine
  CompatibilityDef.x := DEF_MENU_ITEMS_START_X;
  CompatibilityDef.y := DEF_MENU_ITEMS_START_Y;
  CompatibilityDef.lastOn := 0; // last item user was on in menu
  CompatibilityDef.itemheight := SMALLLINEHEIGHT;
  CompatibilityDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

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
  pmi.name := '!Mouse sensitivity...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

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

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_SwitchKeyboardMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'k';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Key bindings...';
  pmi.cmd := '';
  pmi.routine := @M_KeyBindings;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'b';

////////////////////////////////////////////////////////////////////////////////
//ControlsDef
  ControlsDef.numitems := Ord(ctrl_end); // # of menu items
  ControlsDef.prevMenu := @OptionsDef; // previous menu
  ControlsDef.leftMenu := @CompatibilityDef; // left menu
  ControlsDef.rightMenu := @SystemDef; // left menu
  ControlsDef.menuitems := Pmenuitem_tArray(@ControlsMenu);  // menu items
  ControlsDef.drawproc := @M_DrawControls;  // draw routine
  ControlsDef.x := DEF_MENU_ITEMS_START_X;
  ControlsDef.y := DEF_MENU_ITEMS_START_Y;
  ControlsDef.lastOn := 0; // last item user was on in menu
  ControlsDef.itemheight := SMALLLINEHEIGHT;
  ControlsDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//SensitivityMenu
  pmi := @SensitivityMenu[0];
  pmi.status := 2;
  pmi.name := '!Global sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!X Axis sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivityX;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Y Axis sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivityY;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'y';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//SensitivityDef
  SensitivityDef.numitems := Ord(sens_end); // # of menu items
  SensitivityDef.prevMenu := @ControlsDef; // previous menu
  SensitivityDef.menuitems := Pmenuitem_tArray(@SensitivityMenu);  // menu items
  SensitivityDef.drawproc := @M_DrawSensitivity;  // draw routine
  SensitivityDef.x := DEF_MENU_ITEMS_START_X;
  SensitivityDef.y := DEF_MENU_ITEMS_START_Y;
  SensitivityDef.lastOn := 0; // last item user was on in menu
  SensitivityDef.itemheight := SMALLLINEHEIGHT;
  SensitivityDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

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

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Screenshot format';
  pmi.cmd := '';
  pmi.routine := @M_ScreenShotCmd;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//SystemDef
  SystemDef.numitems := Ord(sys_end); // # of menu items
  SystemDef.prevMenu := @OptionsDef; // previous menu
  SystemDef.leftMenu := @ControlsDef; // left menu
  SystemDef.rightMenu := @OptionsGeneralDef; // right menu
  SystemDef.menuitems := Pmenuitem_tArray(@SystemMenu);  // menu items
  SystemDef.drawproc := @M_DrawSystem;  // draw routine
  SystemDef.x := DEF_MENU_ITEMS_START_X;
  SystemDef.y := DEF_MENU_ITEMS_START_Y;
  SystemDef.lastOn := 0; // last item user was on in menu
  SystemDef.itemheight := SMALLLINEHEIGHT;
  SystemDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu1
  pmi := @KeyBindingsMenu1[0];
  for i := 0 to Ord(kb_lookup) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect1;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef1
  KeyBindingsDef1.numitems := Ord(kb_lookup); // # of menu items
  KeyBindingsDef1.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef1.leftMenu := @KeyBindingsDef4; // left menu
  KeyBindingsDef1.rightMenu := @KeyBindingsDef2; // right menu
  KeyBindingsDef1.menuitems := Pmenuitem_tArray(@KeyBindingsMenu1);  // menu items
  KeyBindingsDef1.drawproc := @M_DrawBindings1;  // draw routine
  KeyBindingsDef1.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef1.y := DEF_MENU_ITEMS_START_Y + 2 * SMALLLINEHEIGHT;
  KeyBindingsDef1.lastOn := 0; // last item user was on in menu
  KeyBindingsDef1.itemheight := SMALLLINEHEIGHT;
  KeyBindingsDef1.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu2
  pmi := @KeyBindingsMenu2[0];
  for i := 0 to Ord(kb_weapon0) - Ord(kb_lookup) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect2;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef2
  KeyBindingsDef2.numitems := Ord(kb_weapon0) - Ord(kb_lookup); // # of menu items
  KeyBindingsDef2.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef2.leftMenu := @KeyBindingsDef1; // left menu
  KeyBindingsDef2.rightMenu := @KeyBindingsDef3; // right menu
  KeyBindingsDef2.menuitems := Pmenuitem_tArray(@KeyBindingsMenu2);  // menu items
  KeyBindingsDef2.drawproc := @M_DrawBindings2;  // draw routine
  KeyBindingsDef2.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef2.y := DEF_MENU_ITEMS_START_Y + 2 * SMALLLINEHEIGHT;
  KeyBindingsDef2.lastOn := 0; // last item user was on in menu
  KeyBindingsDef2.itemheight := SMALLLINEHEIGHT;
  KeyBindingsDef2.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu3
  pmi := @KeyBindingsMenu3[0];
  for i := 0 to Ord(kb_am_gobigkey) - Ord(kb_weapon0) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect3;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef3
  KeyBindingsDef3.numitems := Ord(kb_am_gobigkey) - Ord(kb_weapon0); // # of menu items
  KeyBindingsDef3.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef3.leftMenu := @KeyBindingsDef2; // left menu
  KeyBindingsDef3.rightMenu := @KeyBindingsDef4; // right menu
  KeyBindingsDef3.menuitems := Pmenuitem_tArray(@KeyBindingsMenu3);  // menu items
  KeyBindingsDef3.drawproc := @M_DrawBindings3;  // draw routine
  KeyBindingsDef3.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef3.y := DEF_MENU_ITEMS_START_Y + 2 * SMALLLINEHEIGHT;
  KeyBindingsDef3.lastOn := 0; // last item user was on in menu
  KeyBindingsDef3.itemheight := SMALLLINEHEIGHT;
  KeyBindingsDef3.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;
////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu4
  pmi := @KeyBindingsMenu4[0];
  for i := 0 to Ord(kb_end) - Ord(kb_am_gobigkey) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect4;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef4
  KeyBindingsDef4.numitems := Ord(kb_end) - Ord(kb_am_gobigkey); // # of menu items
  KeyBindingsDef4.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef4.leftMenu := @KeyBindingsDef3; // left menu
  KeyBindingsDef4.rightMenu := @KeyBindingsDef1; // right menu
  KeyBindingsDef4.menuitems := Pmenuitem_tArray(@KeyBindingsMenu4);  // menu items
  KeyBindingsDef4.drawproc := @M_DrawBindings4;  // draw routine
  KeyBindingsDef4.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef4.y := DEF_MENU_ITEMS_START_Y + 2 * SMALLLINEHEIGHT;
  KeyBindingsDef4.lastOn := 0; // last item user was on in menu
  KeyBindingsDef4.itemheight := SMALLLINEHEIGHT;
  KeyBindingsDef4.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;
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
  LoadDef.drawproc := @M_DrawLoad;  // draw routine
  LoadDef.x := 28;
  LoadDef.y := 44; // x,y of menu
  LoadDef.lastOn := 0; // last item user was on in menu
  LoadDef.itemheight := SAVELOADLINEHEIGHT;
  LoadDef.flags := 0;

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
  SaveDef.drawproc := M_DrawSave;  // draw routine
  SaveDef.x := 28;
  SaveDef.y := 44; // x,y of menu
  SaveDef.lastOn := 0; // last item user was on in menu
  SaveDef.itemheight := SAVELOADLINEHEIGHT;
  SaveDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
  joywait := 0;
  mousewait := 0;
  mmousex := 0;
  mmousey := 0;
  mlastx := 0;
  mlasty := 0;

end;

end.

