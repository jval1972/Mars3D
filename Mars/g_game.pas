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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit g_game;

interface

uses
  d_delphi,
  doomdef,
  m_fixed,
  d_event,
  d_player,
  d_ticcmd;

//
// GAME
//

procedure G_DeathMatchSpawnPlayer(playernum: integer);

procedure G_InitNew(skill: skill_t; episode: integer; map: integer);

// Can be called by the startup code or M_Responder.
// A normal game starts at map 1,
// but a warp test can start elsewhere
procedure G_DeferedInitNew(skill:skill_t; episode: integer; map: integer);

procedure G_CmdNewGame(const parm1, parm2: string);

procedure G_CmdTestMap;

function G_DeferedPlayDemo(const name: string): boolean;

procedure G_CmdPlayDemo(const name: string);

{ Can be called by the startup code or M_Responder, }
{ calls P_SetupLevel or W_EnterWorld. }
procedure G_LoadGame(const name: string);

procedure G_DoLoadGame;

{ Called by M_Responder. }
procedure G_SaveGame(slot: integer; const description: string);

procedure G_CmdSaveGame(const sname: string; const description: string);

{ Only called by startup code. }
procedure G_RecordDemo(const name: string);

procedure G_BeginRecording;

procedure G_TimeDemo(const name: string);

function G_CheckDemoStatus: boolean;

procedure G_ExitLevel;

procedure G_SecretExitLevel;

procedure G_WorldDone;

procedure G_Ticker;

function G_Responder(ev: Pevent_t): boolean;

procedure G_ScreenShot;

function G_IsOldDemoPlaying: boolean;

procedure G_Quit;

// 19/9/2009 JVAL: For drawing demo progress
function G_DemoProgress: fixed_t;

var
  sendpause: boolean;        // send a pause event next tic

  paused: boolean;

//
// controls (have defaults)
//
  key_right: integer;
  key_left: integer;

  key_up: integer;
  key_down: integer;

// JVAL Look Up and Down
  key_lookup: integer;
  key_lookdown: integer;
  key_lookcenter: integer;
// JVAL Look Left and Right
  key_lookright: integer;
  key_lookleft: integer;
  key_lookforward: integer;

  key_strafeleft: integer;
  key_straferight: integer;
  key_fire: integer;
  key_use: integer;
  key_strafe: integer;
  key_speed: integer;
// JVAL Jump
  key_jump: integer;
// JVAL: 20211101 - Crouch
  key_crouch: integer;

// JVAL 20191207 Key bindings for weapon change
  key_weapon0: integer = Ord('0');
  key_weapon1: integer = Ord('1');
  key_weapon2: integer = Ord('2');
  key_weapon3: integer = Ord('3');
  key_weapon4: integer = Ord('4');
  key_weapon5: integer = Ord('5');
  key_weapon6: integer = Ord('6');
  key_weapon7: integer = Ord('7');
  key_weapon8: integer = Ord('8');
  key_weapon9: integer = Ord('9');

  KEY_WEAPONS: array[0..Ord(NUMWEAPONS) - 1] of PInteger;

  usemouse: boolean;
  invertmouseturn: boolean;
  invertmouselook: boolean;
  mousebfire: integer;
  mousebstrafe: integer;
  mousebforward: integer;

  usejoystick: boolean;
  joybfire: integer;
  joybstrafe: integer;
  joybuse: integer;
  joybspeed: integer;
  joybjump: integer;
  joybcrouch: integer;  // JVAL: 20211101 - Crouch
  joyblleft: integer;
  joyblright: integer;

  demoplayback: boolean;
  showdemoplaybackprogress: boolean;
  preparingdemoplayback: boolean = false;

  gameepisode: integer;
  gamemap: integer;

  deathmatch: integer; // only if started as net death
  netgame: boolean; // only true if packets are broadcast
  playeringame: array[0..MAXPLAYERS - 1] of boolean;

  consoleplayer: integer; // player taking events and displaying
  displayplayer: integer; // view being displayed
  gametic: integer;

  // https://www.doomworld.com/forum/topic/95719-a_tracer-and-gametic/?do=findComment&comment=1788516
  demostarttic: integer; // JVAL: Thanks fabian :)

  totalkills, totalitems, totalsecret: integer; // for intermission

  wminfo: wbstartstruct_t; // parms for world map / intermission

  gameskill: skill_t;

  bodyqueslot: integer;

  precache: boolean; // if true, load all graphics at start

  respawnmonsters: boolean;

  viewactive: boolean;

  singledemo: boolean; // quit after playing a demo from cmdline

  demorecording: boolean = false;

  gameaction: gameaction_t;

  usergame: boolean; // ok to save / end game

procedure G_SetKeyboardMode(const mode: integer);

procedure G_PlayerReborn(player: integer);

procedure G_BuildTiccmd(cmd: Pticcmd_t);

var
  statcopy: pointer = nil;        // for statistics driver

var
  forwardmove: array[0..1] of shortint;
  sidemove: array[0..1] of shortint;
  angleturn: array[0..2] of smallint;

function G_NeedsCompatibilityMode: boolean;

function G_PlayingEngineVersion: integer;

var
  forcecompatibilitymode: boolean = false;
  compatibilitymode: boolean = false;
  oldcompatibilitymode: boolean = false;

type
//
// LOAD GAME MENU
//
  load_e = (
    load1,
    load2,
    load3,
    load4,
    load5,
    load6,
    load7,
    load8,
    load9,
    load_end
  );

var
  autorunmode: boolean = false;
  keepcheatsinplayerreborn: boolean = false;
  allowplayerjumps: boolean = true;
  allowplayercrouch: boolean = true;
  majorbossdeathendsdoom1level: boolean = false;

var
// DOOM Par Times
  pars: array[1..3, 1..9] of integer;

var
  p_initialbullets: integer = 100;
  allowvanillademos: boolean = false;
  vanilla_demo_off: boolean = false;

var
  dogs, default_dogs: integer;                // killough 7/19/98: Marine's best friend :)
  dog_jumping, default_dog_jumping: integer;  // killough 10/98

const
  SAVEGAMESIZE = $1000000; // Originally $2C000
  SAVESTRINGSIZE = 14;
  SAVEVERSIONSIZE = 16;
  SAVEMAPNAMESIZE = 5;

const
  NUMKEYS = 256;

var
  gamekeydown: array[0..NUMKEYS - 1] of boolean;
  mousebuttons: PBooleanArray;
  joybuttons: PBooleanArray;

implementation

uses
  c_cmds,
  z_zone,
  doomstat,
  doomdata,
  d_items,
  am_map,
  d_net,
  d_net_h,
  d_main,
  f_finale,
  info_h,
  info,
  info_rnd,
  mars_briefing,
  mars_intermission,
  mars_intro,
  mars_sounds,
  mars_version,
  m_rnd,
  i_system,
  i_io,
{$IFNDEF OPENGL}
  r_draw,
{$ENDIF}
  e_endoom,
  m_argv,
  m_misc,
  m_menu,
  p_setup,
  p_saveg,
  p_tick,
  p_local,
  p_mobj_h,
  p_mobj,
  p_inter,
  p_map,
  p_levelinfo,
  ps_main,
  hu_stuff,
  st_stuff,
  w_wad,
  s_sound,
// Data.
  dstrings,
  d_englsh,
  sounds,
  r_data,
// SKY handling - still the wrong place.
  r_sky,
  r_defs,
  r_main,
  r_intrpl,
  tables;

procedure G_ReadDemoTiccmd(cmd: Pticcmd_t); forward;
procedure G_WriteDemoTiccmd(cmd: Pticcmd_t); forward;

procedure G_DoReborn(playernum: integer); forward;

procedure G_DoLoadLevel; forward;
procedure G_DoNewGame; forward;
procedure G_DoPlayDemo; forward;
procedure G_DoCompleted; forward;
procedure G_DoWorldDone; forward;
procedure G_DoSaveGame; forward;

procedure G_FinishedDemoPlayback;
begin
  demoplayback := false;
  // Restore old compatibility mode
  compatibilitymode := oldcompatibilitymode;
end;

var
  sendsave: boolean;         // send a save event next tic
  sendcmdsave: boolean;      // send a save event next tic (console)

  timingdemo: boolean;       // if true, exit with report on completion
  starttime: integer;        // for comparative timing purposes

  demoname: string;
  netdemo: boolean;
  demobuffer: PByteArray;
  demo_p: PByteArray;
  demoend: PByte;
  olddemo: boolean;

  consistancy: array[0..MAXPLAYERS - 1] of array[0..BACKUPTICS - 1] of smallint;

  savebuffer: PByteArray;

const
  TURBOTHRESHOLD = $32;

function MAXPLMOVE: fixed_t;
begin
  result := forwardmove[1];
end;

const
  SLOWTURNTICS = 6;

var
  turnheld: integer;

  lookheld: integer;  // JVAL Look UP and DOWN
  lookheld2: integer; // JVAL Look RIGHT and LEFT

  mousearray: array[0..2] of boolean;

// mouse values are used once
  mousex: integer = 0;
  mousey: integer = 0;

  dclicktime: integer;
  dclickstate: boolean;
  dclicks: integer;
  dclicktime2: integer;
  dclickstate2: boolean;
  dclicks2: integer;

// joystick values are repeated
  joyxmove: integer;
  joyymove: integer;
  joyarray: array[0..NUMJOYBUTTONS - 1] of boolean;

  savegameslot: integer;
  savedescription: string;

const
  BODYQUESIZE  = 32;

var
  bodyque: array[0..BODYQUESIZE - 1] of Pmobj_t;

function G_CmdChecksum(cmd: Pticcmd_t): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to SizeOf(cmd^) div 4 - 2 do
    result := result + PIntegerArray(cmd)[i];
end;

//
// G_BuildTiccmd
// Builds a ticcmd from all of the available inputs
// or reads it from the demo buffer.
// If recording a demo, write it out
//
procedure G_BuildTiccmd(cmd: Pticcmd_t);
var
  i: integer;
  strafe: boolean;
  bstrafe: boolean;
  speed: integer;
  tspeed: integer;
  lspeed: integer;  // JVAL Look up and down
  lspeed2: integer; // JVAL look left and right
  _forward: integer;
  side: integer;
  look: integer;    // JVAL Look up and down
  look16: integer;  // JVAL Smooth Look Up/Down
  look2: integer;   // JVAL look left and right
  flyheight: integer;  // JVAL: 20211109 - Fly (Jet pack)
  base: Pticcmd_t;
  imousex: integer;
  imousey: integer;
  cmd_fly: integer;  // JVAL: 20211109 - Fly (Jet pack)
begin
  base := I_BaseTiccmd;    // empty, or external driver

  memcpy(cmd, base, SizeOf(cmd^));

  cmd.consistancy := consistancy[consoleplayer][maketic mod BACKUPTICS];

  strafe := gamekeydown[key_strafe] or
            (usemouse and mousebuttons[mousebstrafe]) or
            (usejoystick and joybuttons[joybstrafe]);
  speed := intval(gamekeydown[key_speed] or joybuttons[joybspeed]);
  if autorunmode then
    speed := 1 - speed;

  _forward := 0;
  side := 0;
  look := 0;
  look16 := 0; // JVAL Smooth Look Up/Down
  look2 := 0;
  flyheight := 0;

  // use two stage accelerative turning
  // on the keyboard and joystick
  if (joyxmove <> 0) or
     (gamekeydown[key_right]) or
     (gamekeydown[key_left]) then
    turnheld := turnheld + ticdup
  else
    turnheld := 0;

  if turnheld < SLOWTURNTICS then
    tspeed := 2             // slow turn
  else
    tspeed := speed;

  if gamekeydown[key_lookdown] or gamekeydown[key_lookup] then
    lookheld := lookheld + ticdup
  else
    lookheld := 0;

  if lookheld < SLOWTURNTICS then
    lspeed := 1
  else
    lspeed := 2;

  if gamekeydown[key_lookleft] or gamekeydown[key_lookright] or
    (usejoystick and (joybuttons[joyblleft] or joybuttons[joyblright])) then
    lookheld2 := lookheld2 + ticdup
  else
    lookheld2 := 0;

  if lookheld2 < SLOWTURNTICS then
    lspeed2 := 1
  else
    lspeed2 := 2;

  // let movement keys cancel each other out
  if strafe then
  begin
    if gamekeydown[key_right] then
      side := side + sidemove[speed];
    if gamekeydown[key_left] then
      side := side - sidemove[speed];
    if joyxmove > 0 then
      side := side + sidemove[speed];
    if joyxmove < 0 then
      side := side - sidemove[speed];
  end
  else
  begin
    if gamekeydown[key_right] then
      cmd.angleturn := cmd.angleturn - angleturn[tspeed];
    if gamekeydown[key_left] then
      cmd.angleturn := cmd.angleturn + angleturn[tspeed];
    if joyxmove > 0 then
      cmd.angleturn := cmd.angleturn - angleturn[tspeed];
    if joyxmove < 0 then
      cmd.angleturn := cmd.angleturn + angleturn[tspeed];
  end;

  if gamekeydown[key_up] then
    _forward := _forward + forwardmove[speed];

  if gamekeydown[key_down] then
    _forward := _forward - forwardmove[speed];

  // JVAL Look up/down/center keys
  if zaxisshift then
  begin
    if gamekeydown[key_lookup] then
      look := lspeed;

    if gamekeydown[key_lookdown] then
      look := -lspeed;

    if gamekeydown[key_lookcenter] then
      look := TOCENTER;

    look16 := 256 * look; // JVAL Smooth Look Up/Down
  end;

  // JVAL Look right/left/forward keys
  if gamekeydown[key_lookleft] or (usejoystick and joybuttons[joyblleft]) then
    look2 := lspeed2;

  if gamekeydown[key_lookright] or (usejoystick and joybuttons[joyblright]) then
    look2 := -lspeed2;

  if gamekeydown[key_lookforward] then
    look2 := TOFORWARD;

  if joyymove < 0 then
    _forward := _forward + forwardmove[speed];

  if joyymove > 0 then
    _forward := _forward - forwardmove[speed];

  if gamekeydown[key_straferight] then
    side := side + sidemove[speed];

  if gamekeydown[key_strafeleft] then
    side := side - sidemove[speed];

  // buttons
  cmd.chatchar := Ord(HU_dequeueChatChar);

  if gamekeydown[key_fire] or
     (usemouse and mousebuttons[mousebfire]) or
     (usejoystick and joybuttons[joybfire]) then
    cmd.buttons := cmd.buttons or BT_ATTACK;

  if gamekeydown[key_use] or (usejoystick and joybuttons[joybuse]) then
  begin
    cmd.buttons := cmd.buttons or BT_USE;
  // clear double clicks if hit use button
    dclicks := 0;
  end;

  // chainsaw overrides
  for i := 0 to Ord(NUMWEAPONS) - 1 do
    if weaponinfo[i].flags and WF_WEAPON <> 0 then
      if gamekeydown[KEY_WEAPONS[i]^] then
      begin
        cmd.buttons := cmd.buttons or BT_CHANGE;
        cmd.buttons := cmd.buttons or _SHL(i, BT_WEAPONSHIFT);
        break;
      end;

  // mouse
  if (usemouse and mousebuttons[mousebforward]) then
    _forward := _forward + forwardmove[speed];

  // forward double click
  if usemouse and (mousebuttons[mousebforward] <> dclickstate) and (dclicktime > 1) then
  begin
    dclickstate := mousebuttons[mousebforward];
    if dclickstate then
      inc(dclicks);
    if dclicks = 2 then
    begin
      cmd.buttons := cmd.buttons or BT_USE;
      dclicks := 0;
    end
    else
      dclicktime := 0;
  end
  else
  begin
    dclicktime := dclicktime + ticdup;
    if dclicktime > 20 then
    begin
      dclicks := 0;
      dclickstate := false;
    end
  end;

  // strafe double click
  bstrafe := (usemouse and mousebuttons[mousebstrafe]) or
             (usejoystick and joybuttons[joybstrafe]);
  if (bstrafe <> dclickstate2) and (dclicktime2 > 1) then
  begin
    dclickstate2 := bstrafe;
    if bstrafe then
      inc(dclicks2);
    if dclicks2 = 2 then
    begin
      cmd.buttons := cmd.buttons or BT_USE;
      dclicks2 := 0;
    end
    else
      dclicktime2 := 0;
  end
  else
  begin
    dclicktime2 := dclicktime2 + ticdup;
    if dclicktime2 > 20 then
    begin
      dclicks2 := 0;
      dclickstate2 := false;
    end;
  end;

  // JVAL: invert mouse
  if invertmouseturn then
    imousex := -mousex
  else
    imousex := mousex;

  if strafe then
    side := side - imousex * 2
  else
    cmd.angleturn := cmd.angleturn + imousex * $8;

  if invertmouselook then
    imousey := -mousey
  else
    imousey := mousey;

  if usemouse then
  begin
    look := look + imousey div 16;
    if imousey < 0 then
    begin
      if look < -4 then
        look := -4;
    end
    else if imousey > 0 then
    begin
      if look > 4 then
        look := 4;
    end;

    // JVAL Smooth Look Up/Down
    look16 := look16 + imousey * 16;
    if imousey < 0 then
    begin
      if look16 < -4 * 256 then
        look16 := -4 * 256;
    end
    else if imousey > 0 then
    begin
      if look16 > 4 * 256 then
        look16 := 4 * 256;
    end;
  end;

  // For smooth mouse movement
  mousex := mousex div 4;
  mousey := mousey div 4;

  if _forward > MAXPLMOVE then
    _forward := MAXPLMOVE
  else if _forward < -MAXPLMOVE then
    _forward := -MAXPLMOVE;

  if side > MAXPLMOVE then
    side := MAXPLMOVE
  else if side < -MAXPLMOVE then
    side := -MAXPLMOVE;

  cmd.forwardmove := cmd.forwardmove + _forward;
  cmd.sidemove := cmd.sidemove + side;

  if players[consoleplayer].playerstate = PST_LIVE then
  begin
    if zaxisshift then
    begin
      if look < 0 then
        look := look + 16;
      cmd.lookupdown := look;

      // JVAL Smooth Look Up/Down
      if look16 < 0 then
        look16 := look16 + 16 * 256;
      cmd.lookupdown16 := look16;
    end;
    if look2 < 0 then
      look2 := look2 + 16;
    cmd.lookleftright:= look2;
    // JVAL
    // allowplayerjumps variable controls if we accept input for jumping
    if allowplayerjumps and (gamekeydown[key_jump] or (usejoystick and joybuttons[joybjump])) then
    begin
      if players[consoleplayer].oldjump <> 0 then
        cmd.jump := 1
      else
        cmd.jump := 2
      end
    else
      cmd.jump := 0;
    players[consoleplayer].oldjump := cmd.jump;
    // JVAL: 20211101 - Crouch
    // allowplayercrouch variable controls if we accept input for crouching
    if cmd.jump = 0 then
    begin
      if allowplayercrouch and (gamekeydown[key_crouch] or (usejoystick and joybuttons[joybcrouch])) then
      begin
        if players[consoleplayer].oldcrouch <> 0 then
          cmd.crouch := 2
        else
          cmd.crouch := 1
        end
      else
        cmd.crouch := 0;
    end
    else
      cmd.crouch := 0;
    players[consoleplayer].oldcrouch := cmd.crouch;

    // JVAL: 20211116 - Swim (Underwater sectors)
    // The swim cmd is build by a compination of jump & crouch
    cmd.swim := 0;
    if gamekeydown[key_jump] or (usejoystick and joybuttons[joybjump]) then
      cmd.swim := cmd.swim + 1;
    if gamekeydown[key_crouch] or (usejoystick and joybuttons[joybcrouch]) then
      cmd.swim := cmd.swim - 1;
  end;

  // special buttons
  if sendpause then
  begin
    sendpause := false;
    cmd.buttons := BT_SPECIAL or BTS_PAUSE;
  end;

  cmd_fly := Isign(cmd.jump - cmd.crouch); // JVAL: 20211109 - Fly (Jet pack)
  // Fly up/down/drop keys
  if cmd_fly > 0 then
    flyheight := 5; // note that the actual flyheight will be twice this

  if cmd_fly < 0 then
    flyheight := -5;

  if (cmd_fly = 0) and (cmd.jump <> 0) then
    flyheight := TOCENTER;

  if flyheight < 0 then
    flyheight := flyheight + 16;

  cmd.fly := flyheight;
  if sendsave then
  begin
    sendsave := false;
    cmd.buttons := BT_SPECIAL or BTS_SAVEGAME or _SHL(savegameslot, BTS_SAVESHIFT);
  end;
  if sendcmdsave then
  begin
    sendcmdsave := false;
    cmd.commands := CM_SAVEGAME;
  end;

end;

//
// G_DoLoadLevel
//
procedure G_DoLoadLevel;
var
  i: integer;
begin
  // Set the sky map.
  // First thing, we have a dummy sky texture name,
  //  a flat. The data is in the WAD only because
  //  we look for an actual index, instead of simply
  //  setting one.
  skyflatnum := R_FlatNumForName(SKYFLATNAME);

  // DOOM determines the sky texture to be used
  // depending on the current episode, and the game version.
  skytexture := R_CheckTextureNumForName('SKY' + Chr(Ord('0') + gameepisode));
  if skytexture < 0 then
    skytexture := R_TextureNumForName('SKY1');

  if demoplayback or demorecording or netgame or not showbriefingscreen then
    gamestate := GS_LEVEL
  else
  begin
    gamestate := GS_BRIEFING;
    MARS_Briefing_Start;
  end;

  if wipegamestate = Ord(gamestate) then
    wipegamestate := -1;  // force a wipe

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] and (players[i].playerstate = PST_DEAD) then
      players[i].playerstate := PST_REBORN;
    ZeroMemory(@players[i].frags, SizeOf(players[i].frags));
  end;

  PS_NewMap;
  P_SetupLevel(gameepisode, gamemap, 0, gameskill);

  // JVAL: Prevent erroneous demos
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      if players[i].mo = nil then
      begin
        I_Warning('G_DoLoadLevel(): Null player actor, is player start missing?'#13#10);
        gamestate := GS_DEMOSCREEN;
        D_StartTitle;
        exit;
      end;

  displayplayer := consoleplayer;    // view the guy you are playing
  starttime := I_GetTime;
  gameaction := ga_nothing;
  Z_CheckHeap;
  // JVAL: Extra debug check
  if debugmode then
    Z_CheckMemory;

  // clear cmd building stuff
  ZeroMemory(@gamekeydown, SizeOf(gamekeydown));
  joyxmove := 0;
  joyymove := 0;
  mousex := 0;
  mousey := 0;
  sendpause := false;
  sendsave := false;
  sendcmdsave := false;
  paused := false;
  ZeroMemory(mousebuttons, SizeOf(mousebuttons));
  ZeroMemory(joybuttons, SizeOf(joybuttons));
end;

//
// G_Responder
// Get info needed to make ticcmd_ts for the players.
//
function G_Responder(ev: Pevent_t): boolean;
var
  bmask: integer;
  i: integer;
begin
  if gamestate = GS_ENDOOM then
  begin
    result := E_Responder(ev);
    exit;
  end;
  if gamestate = GS_BRIEFING then
  begin
    result := MARS_BriefingResponder(ev);
    exit;
  end;
  if gamestate = GS_INTERMISSION then
  begin
    result := MARS_IntermissionResponder(ev);
    exit;
  end;
  // allow spy mode changes even during the demo
  if (gamestate = GS_LEVEL) and (ev._type = ev_keydown) and
     (ev.data1 = KEY_F12) and (singledemo or (deathmatch = 0)) then
  begin
  // spy mode
    repeat
      inc(displayplayer);
      if displayplayer = MAXPLAYERS then
        displayplayer := 0;
    until not ((not playeringame[displayplayer]) and (displayplayer <> consoleplayer));
    result := true;
    exit;
  end;

  // any other key pops up menu if in demos
  if (gameaction = ga_nothing) and not singledemo and
     (demoplayback or (gamestate = GS_DEMOSCREEN)) then
  begin
    if (ev._type = ev_keydown) or
       ((ev._type = ev_mouse) and (ev.data1 <> 0)) or
       ((ev._type = ev_joystick) and (ev.data1 <> 0)) then
    begin
      M_StartControlPanel;
      result := true;
      exit;
    end;
    result := false;
    exit;
  end;

  if gamestate = GS_LEVEL then
  begin
    if HU_Responder(ev) then
    begin
      result := true; // chat ate the event
      exit;
    end;
    if ST_Responder(ev) then
    begin
      result := true; // status window ate it
      exit;
    end;
    if AM_Responder(ev) then
    begin
      result := true; // automap ate it
      exit;
    end;
  end;

  if gamestate = GS_FINALE then
  begin
    if F_Responder(ev) then
    begin
      result := true; // finale ate the event
      exit;
    end;
  end;

  // For smooth mouse movement
  mousex := mousex div 2;
  mousey := mousey div 2;

  case ev._type of
    ev_keydown:
      begin
        if ev.data1 = KEY_PAUSE then
        begin
          sendpause := true;
          result := true;
          exit;
        end;

        if ev.data1 < NUMKEYS then
          gamekeydown[ev.data1] := true;

        result := true; // eat key down events
        exit;
      end;

    ev_keyup:
      begin
        if ev.data1 < NUMKEYS then
          gamekeydown[ev.data1] := false;
        result := false; // always let key up events filter down
        exit;
      end;

    ev_mouse:
      begin
        if usemouse then
        begin
          mousebuttons[0] := ev.data1 and 1 <> 0;
          mousebuttons[1] := ev.data1 and 2 <> 0;
          mousebuttons[2] := ev.data1 and 4 <> 0;
          mousex := mousex + ((ev.data2 * (mouseSensitivity + 5)) div 10) * mouseSensitivityX div 5;
          mousey := mousey + ((ev.data3 * (mouseSensitivity + 5)) div 10) * mouseSensitivityY div 5;
        end
        else
        begin
          mousebuttons[0] := false;
          mousebuttons[1] := false;
          mousebuttons[2] := false;
          mousex := 0;
          mousey := 0;
        end;
        result := true;    // eat events
        exit;
      end;

    ev_joystick:
      begin
        if usejoystick then
        begin
          bmask := 1;
          for i := 0 to NUMJOYBUTTONS - 1 do
          begin
            joybuttons[i] := (ev.data1 and bmask) <> 0;
            bmask := bmask * 2;
          end;
          joyxmove := ev.data2;
          joyymove := ev.data3;
        end
        else
        begin
          for i := 0 to NUMJOYBUTTONS - 1 do
            joybuttons[i] := false;
          joyxmove := 0;
          joyymove := 0;
        end;
        result := true;    // eat events
        exit;
      end;
  end;

  result := false;
end;

//
// G_Ticker
// Make ticcmd_ts for the players.
//
procedure G_Ticker;
var
  i: integer;
  buf: integer;
  cmd: Pticcmd_t;
  msg: string;
  pl: Pplayer_t;
begin
  // do player reborns if needed
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] and (players[i].playerstate = PST_REBORN) then
      G_DoReborn(i);

  // do things to change the game state
  while (gameaction <> ga_nothing) do
  begin
    case gameaction of
      ga_loadlevel:
        G_DoLoadLevel;
      ga_newgame:
        G_DoNewGame;
      ga_loadgame:
        G_DoLoadGame;
      ga_savegame:
        G_DoSaveGame;
      ga_playdemo:
        G_DoPlayDemo;
      ga_completed:
        G_DoCompleted;
      ga_victory:
        F_StartFinale;
      ga_worlddone:
        G_DoWorldDone;
      ga_screenshot:
        begin
          M_ScreenShot;
          gameaction := ga_nothing;
        end;
    end;
  end;

  // get commands, check consistancy,
  // and build new consistancy check
  buf := (gametic div ticdup) mod BACKUPTICS;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      pl := @players[i];
      cmd := @pl.cmd;

      memcpy(cmd, @netcmds[i][buf], SizeOf(ticcmd_t));

      if demoplayback then
        G_ReadDemoTiccmd(cmd);

      if demorecording then
        G_WriteDemoTiccmd(cmd);

      // check for turbo cheats
      if (cmd.forwardmove > TURBOTHRESHOLD) and
         ((gametic and 31) = 0) and
         (((_SHR(gametic, 5)) and 3) = i) then
      begin
        sprintf(msg, '%s is turbo!', [player_names[i]]);
        players[consoleplayer]._message := msg;
      end;

      if netgame and not netdemo and (gametic mod ticdup = 0) then
      begin
        if (gametic > BACKUPTICS) and
           (consistancy[i][buf] <> cmd.consistancy) then
          I_Error('G_Ticker(): consistency failure (%d should be %d)',
            [cmd.consistancy, consistancy[i][buf]]);

        if pl.mo <> nil then
          consistancy[i][buf] := pl.mo.x
        else
          consistancy[i][buf] := rndindex;
      end;
    end;
  end;

  // check for special buttons
  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      pl := @players[i];
      if pl.cmd.commands and CM_SAVEGAME <> 0 then
      begin
        savegameslot := Ord(load_end);
        gameaction := ga_savegame;
      end;
      if pl.cmd.buttons and BT_SPECIAL <> 0 then
      begin
        case pl.cmd.buttons and BT_SPECIALMASK of
          BTS_PAUSE:
            begin
              paused := not paused;
              if paused then
                S_PauseSound
              else
                S_ResumeSound;
            end;
          BTS_SAVEGAME:
            begin
              if savedescription = '' then
                savedescription := 'NET GAME';
              savegameslot :=
                _SHR((pl.cmd.buttons and BTS_SAVEMASK), BTS_SAVESHIFT);
              gameaction := ga_savegame;
            end;
        end;
      end;
    end;
  end;

  // do main actions
  case gamestate of
    GS_INTRO:
      MARS_Intro_Ticker;
    GS_BRIEFING:
      begin
        MARS_Briefing_Ticker;
      end;
    GS_LEVEL:
      begin
        P_Ticker;
        ST_Ticker;
        AM_Ticker;
        HU_Ticker;
      end;
    GS_INTERMISSION:
      begin
        MARS_Intermission_Ticker;
      end;
    GS_FINALE:
      begin
        F_Ticker;
      end;
    GS_DEMOSCREEN:
      begin
        D_PageTicker;
      end;
  end;
end;

//
// PLAYER STRUCTURE FUNCTIONS
// also see P_SpawnPlayer in P_Things
//

//
// G_PlayerFinishLevel
// Can when a player completes a level.
//
procedure G_PlayerFinishLevel(p: Pplayer_t);
begin
  ZeroMemory(@p.powers, SizeOf(p.powers));
  ZeroMemory(@p.cards, SizeOf(p.cards));
  if p.mo <> nil then
    p.mo.flags := p.mo.flags and not MF_SHADOW; // cancel invisibility
  p.lookdir := 0;       // JVAL cancel lookdir Up/Down
  p.lookdir16 := 0;     // JVAL Smooth Look Up/Down
  p.centering := false;
  p.lookdir2 := 0;      // JVAL cancel lookdir Left/Right
  p.forwarding := false;
  p.extralight := 0;    // cancel gun flashes
  p.fixedcolormap := 0; // cancel ir gogles
  p.damagecount := 0;   // no palette changes
  p.damagetype := 0;  // JVAL: Posion damage
  p.bonuscount := 0;
end;

procedure G_SetKeyboardMode(const mode: integer);
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
    AM_GOBIGKEY := Ord('o');
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
  end;
end;

//
// G_PlayerReborn
// Called after a player dies
// almost everything is cleared and initialized
//
procedure G_PlayerReborn(player: integer);
var
  p: Pplayer_t;
  i: integer;
  frags: array[0..MAXPLAYERS - 1] of integer;
  killcount: integer;
  itemcount: integer;
  secretcount: integer;
  cheats: integer;
begin
  p := @players[player];
  memcpy(@frags, @p.frags, SizeOf(frags));
  killcount := p.killcount;
  itemcount := p.itemcount;
  secretcount := p.secretcount;

  // JVAL: added option to keep cheats
  if keepcheatsinplayerreborn and not preparingdemoplayback then
  begin
    cheats := p.cheats;
    ZeroMemory(p, SizeOf(player_t));
    p.cheats := cheats;
  end
  else
    ZeroMemory(p, SizeOf(player_t));

  memcpy(@p.frags, @frags, SizeOf(players[player].frags));
  p.killcount := killcount;
  p.itemcount := itemcount;
  p.secretcount := secretcount;

  p.usedown := true;
  p.attackdown := true;  // don't do anything immediately
  p.playerstate := PST_LIVE;
  p.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;
  p.readyweapon := wp_pistol;
  p.pendingweapon := wp_pistol;
  p.oldreadyweapon := wp_pistol;
  p.weaponowned[Ord(wp_fist)] := 1;
  p.weaponowned[Ord(wp_pistol)] := 1;
  p.ammo[Ord(am_bullet)] := p_initialbullets;

  for i := 0 to Ord(NUMAMMO) - 1 do
    p.maxammo[i] := maxammo[i];
end;

//
// G_CheckSpot
// Returns false if the player cannot be respawned
// at the given mapthing_t spot
// because something is occupying it
//
function G_CheckSpot(playernum: integer; mthing: Pmapthing_t): boolean;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t; // JVAL: 3d floor
  ss: Psector_t;
  an: angle_t; // JVAL was u long
  mo: Pmobj_t;
  i: integer;
begin
  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  if players[playernum].mo = nil then
  begin
    // first spawn of level, before corpses
    for i := 0 to playernum - 1 do
      if (players[i].mo.x = x) and
         (players[i].mo.y = y) then
      begin
        result := false;
        exit;
      end;
    result := true;
    exit;
  end;

  players[playernum].mo.flags2_ex := players[playernum].mo.flags2_ex and not MF2_EX_PASSMOBJ;

  // JVAL: 3d floors
  ss := P_PointInSector(x, y);
  z := ss.floorheight;
  if ss.midsec >= 0 then
    if players[playernum].mo.spawnpoint.options and MTF_ONMIDSECTOR <> 0 then
      z := sectors[ss.midsec].ceilingheight;

  if not P_CheckPosition(players[playernum].mo, x, y) then
  begin
    players[playernum].mo.flags2_ex := players[playernum].mo.flags2_ex or MF2_EX_PASSMOBJ;
    result := false;
    exit;
  end;

  players[playernum].mo.flags2_ex := players[playernum].mo.flags2_ex or MF2_EX_PASSMOBJ;

  // flush an old corpse if needed
  if bodyqueslot >= BODYQUESIZE then
    P_RemoveMobj(bodyque[bodyqueslot mod BODYQUESIZE]);
  bodyque[bodyqueslot mod BODYQUESIZE] := players[playernum].mo;
  inc(bodyqueslot);

  // spawn a teleport fog
  {$IFDEF FPC}
  an := _SHRW(ANG45 * (mthing.angle div 45), ANGLETOFINESHIFT);
  {$ELSE}
  an := (ANG45 * (mthing.angle div 45)) shr ANGLETOFINESHIFT;
  {$ENDIF}

  mo := P_SpawnMobj(x + 20 * finecosine[an], y + 20 * finesine[an],
          z, Ord(MT_TFOG));

  if players[consoleplayer].viewz <> 1 then
    MARS_StartSound(mo, snd_TELEPORT);  // don't start sound on first frame

  result := true;
end;

//
// G_DeathMatchSpawnPlayer
// Spawns a player at one of the random death match spots
// called at level load and each death
//
procedure G_DeathMatchSpawnPlayer(playernum: integer);
var
  i, j: integer;
  selections: integer;
begin
  selections := deathmatch_p; // JVAL - deathmatchstarts;
  if selections < 4 then
  begin
    I_Warning('G_DeathMatchSpawnPlayer(): Only %d deathmatch spots, 4 required', [selections]);
    exit;
  end;

  for j := 0 to 19 do
  begin
    i := P_Random mod selections;
    if G_CheckSpot(playernum, @deathmatchstarts[i]) then
    begin
      deathmatchstarts[i]._type := playernum + 1;
      P_SpawnPlayer(@deathmatchstarts[i]);
      exit;
    end;
  end;

  // no good spot, so the player will probably get stuck
  P_SpawnPlayer(@playerstarts[playernum]);
end;

//
// G_DoReborn
//
procedure G_DoReborn(playernum: integer);
var
  i: integer;
begin
  if not netgame then
    // reload the level from scratch
    gameaction := ga_loadlevel
  else
  begin
    // respawn at the start

    // first dissasociate the corpse
    players[playernum].mo.player := nil;

    // spawn at random spot if in death match
    if deathmatch <> 0 then
    begin
      G_DeathMatchSpawnPlayer(playernum);
      exit;
    end;

    if G_CheckSpot(playernum, @playerstarts[playernum]) then
    begin
      P_SpawnPlayer(@playerstarts[playernum]);
      exit;
    end;

    // try to spawn at one of the other players spots
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if G_CheckSpot (playernum, @playerstarts[i]) then
      begin
        playerstarts[i]._type := playernum + 1; // fake as other player
        P_SpawnPlayer(@playerstarts[i]);
        playerstarts[i]._type := i + 1; // restore
        exit;
      end;
      // he's going to be inside something.  Too bad.
    end;
    P_SpawnPlayer(@playerstarts[playernum]);
  end;
end;

procedure G_ScreenShot;
begin
  gameaction := ga_screenshot;
end;

//
// G_DoCompleted
//
var
  secretexit: boolean;

procedure G_ExitLevel;
begin
  secretexit := false;
  gameaction := ga_completed;
end;

// Here's for the german edition.
procedure G_SecretExitLevel;
begin
  secretexit := false;
  gameaction := ga_completed;
end;

procedure G_DoCompleted;
var
  i: integer;
begin
  gameaction := ga_nothing;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      G_PlayerFinishLevel(@players[i]); // take away cards and stuff

  if amstate <> am_inactive then
  begin
    amstate := am_inactive;
    AM_Stop;
  end;

  if W_CheckNumForName('E' + itoa(gameepisode) + 'M' + itoa(gamemap)) < 0 then
  begin
    gameaction := ga_victory;
    exit;
  end;

  wminfo.didsecret := players[consoleplayer].didsecret;
  wminfo.epsd := gameepisode - 1;
  wminfo.last := gamemap - 1;

  // wminfo.next is 0 biased, unlike gamemap
{  if gamemode = commercial then
  begin
    if secretexit then
    begin
      case gamemap of
         2: if customgame = cg_bfg2 then wminfo.next := 32 else wminfo.next := gamemap;
        15: wminfo.next := 30;
        31: wminfo.next := 31;
      end
    end
    else
    begin
      case gamemap of
        31,
        32: wminfo.next := 15;
        33: if customgame = cg_bfg2 then wminfo.next := 2 else wminfo.next := gamemap;
      else
        wminfo.next := gamemap;
      end;
    end
  end
  else}
  begin
      wminfo.next := gamemap; // go to next level
  end;

  wminfo.maxkills := totalkills;
  wminfo.maxitems := totalitems;
  wminfo.maxsecret := totalsecret;
  wminfo.maxfrags := 0;
  wminfo.partime := TICRATE * pars[gameepisode][gamemap];
  wminfo.pnum := consoleplayer;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    wminfo.plyr[i]._in := playeringame[i];
    wminfo.plyr[i].skills := players[i].killcount;
    wminfo.plyr[i].sitems := players[i].itemcount;
    wminfo.plyr[i].ssecret := players[i].secretcount;
    wminfo.plyr[i].stime := leveltime;
    memcpy(@wminfo.plyr[i].frags, @players[i].frags, SizeOf(wminfo.plyr[i].frags));
  end;

  viewactive := false;
  amstate := am_inactive;

  if statcopy <> nil then
    memcpy(statcopy, @wminfo, SizeOf(wminfo));

  if demoplayback or demorecording or netgame or not showintermissionscreen then
  begin
    wipegamestate := -1;  // Force a wipe
    G_WorldDone;
  end
  else
  begin
    gamestate := GS_INTERMISSION;
    MARS_Intermission_Start(@wminfo);
  end;
end;

//
// G_WorldDone
//
procedure G_WorldDone;
begin
  gameaction := ga_worlddone;

  if secretexit then
    players[consoleplayer].didsecret := true;
end;

procedure G_DoWorldDone;
begin
  if demoplayback or demorecording or netgame or not showbriefingscreen then
    gamestate := GS_LEVEL
  else
  begin
    gamestate := GS_BRIEFING;
    MARS_Briefing_Start;
  end;
  gamemap := wminfo.next + 1;
  G_DoLoadLevel;
  gameaction := ga_nothing;
  viewactive := true;
end;

function G_GetSaveName(name: string): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to Ord(load_end) - 1 do
  begin
    if name = itoa(i) then
    begin
      sprintf(result, MARS_GetSavePath + SAVEGAMENAME + '%s.sav', [name]);
      exit;
    end;
  end;
  
  if strupper(Copy(name, length(name) - 3, 4)) <> '.SAV' then
    result := name + '.SAV'
  else
    result := name;
end;

//
// G_InitFromSavegame
// Can be called by the startup code or the menu task.
//
var
  savename: string;

procedure G_LoadGame(const name: string);
begin
  savename := name;
  gameaction := ga_loadgame;
end;

procedure G_DoLoadGame;
var
  len: integer;
  i, j: integer;
  a, b, c: integer;
  vcheck: string;
  vsaved: string;
begin
  gameaction := ga_nothing;

  savename := G_GetSaveName(savename);
  if not fexists(savename) then
  begin
    I_Warning('Can not open %s'#13#10, [savename]);
    exit;
  end;

  len := M_ReadFile(savename, pointer(savebuffer));
  save_p := PByteArray(integer(savebuffer) + SAVESTRINGSIZE + SAVEMAPNAMESIZE);

  savegameversion := VERSION; // Assume current version

  // skip the description field
  vcheck := '';
  sprintf(vcheck, 'version %d', [VERSION]);

  if len < Length(vcheck) then
  begin
    I_Warning('G_DoLoadGame(): Saved game is from an unsupported version.'#13#10);
    Z_Free(savebuffer);
    exit; // bad version // by JVAL extra checking
  end;

  for i := 0 to Length(vcheck) - 1 do
    if save_p[i] <> Ord(vcheck[i + 1]) then
    begin
      vsaved := '';
      for j := 0 to Length(vcheck) - 1 do
        vsaved := vsaved + Chr(save_p[j]);
      // JVAL
      // Check for compatible game versions here
      if vsaved = 'version 113' then
        savegameversion := VERSION113
      else if vsaved = 'version 114' then
        savegameversion := VERSION114
      else if vsaved = 'version 115' then
        savegameversion := VERSION115
      else if vsaved = 'version 116' then
        savegameversion := VERSION116
      else if vsaved = 'version 117' then
        savegameversion := VERSION117
      else if vsaved = 'version 118' then
        savegameversion := VERSION118
      else if vsaved = 'version 119' then
        savegameversion := VERSION119
      else if vsaved = 'version 120' then
        savegameversion := VERSION120
      else if vsaved = 'version 121' then
        savegameversion := VERSION121
      else if vsaved = 'version 122' then
        savegameversion := VERSION122
      else if vsaved = 'version 203' then
        savegameversion := VERSION203
      else if vsaved = 'version 204' then
        savegameversion := VERSION204
      else if vsaved = 'version 204' then
        savegameversion := VERSION204
      else if vsaved = 'version 205' then
        savegameversion := VERSION205
      else
      begin
        I_Warning('G_DoLoadGame(): Saved game is from an unsupported version: %s!'#13#10, [vsaved]);
        Z_Free(savebuffer);
        exit; // bad version
      end;
      break;
    end;

  save_p := PByteArray(integer(save_p) + SAVEVERSIONSIZE);

  P_UnArchiveScreenShot;

  gameskill := skill_t(save_p[0]);
  save_p := PByteArray(integer(save_p) + 1);

  gameepisode := save_p[0];
  save_p := PByteArray(integer(save_p) + 1);

  gamemap := save_p[0];
  save_p := PByteArray(integer(save_p) + 1);

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := save_p[0] <> 0;
    save_p := PByteArray(integer(save_p) + 1);
  end;

  // load a base level
  G_InitNew(gameskill, gameepisode, gamemap);

  // get the times
  a := save_p[0];
  save_p := PByteArray(integer(save_p) + 1);

  b := save_p[0];
  save_p := PByteArray(integer(save_p) + 1);

  c := save_p[0];
  save_p := PByteArray(integer(save_p) + 1);

  leveltime := _SHL(a, 16) + _SHL(b, 8) + c;

  // dearchive all the modifications
  P_UnArchivePlayers;
  P_UnArchiveWorld;
  P_UnArchiveThinkers;
  P_UnArchiveSpecials;
  P_UnArchiveVariables;
  P_UnArchivePSMapScript;
  P_UnArchiveOverlay;

  if save_p[0] <> $1d then
    I_Error('G_DoLoadGame(): Bad savegame');

  // done
  Z_Free(savebuffer);

  if setsizeneeded then
    R_ExecuteSetViewSize;

  P_LevelInfoChangeMusic;

  // draw the pattern into the back screen
{$IFNDEF OPENGL}
  R_FillBackScreen;
{$ENDIF}
end;

//
// G_SaveGame
// Called by the menu task.
// Description is a 24 byte text string
//
procedure G_SaveGame(slot: integer; const description: string);
begin
  savegameslot := slot;
  savedescription := description;
  sendsave := true;
end;

procedure G_DoSaveGameInFile(name: string);
var
  name2: string;
  mapname: string;
  description: string;
  len: integer;
  i: integer;
  maxsize: integer;
begin
  name := G_GetSaveName(name);

  description := savedescription;

  maxsize := SAVEGAMESIZE + PS_MapScriptSaveSize;
  repeat
    savebuffer := Z_Malloc2(maxsize, PU_STATIC, nil);
    if savebuffer = nil then
      maxsize := maxsize * 3 div 4;
  until savebuffer <> nil;

  save_p := savebuffer;

  mapname := P_GetMapName(gameepisode, gamemap);
  while Length(mapname) < SAVEMAPNAMESIZE do
    mapname := mapname + ' ';
  for i := 1 to SAVEMAPNAMESIZE do
    save_p[i - 1] := Ord(mapname[i]);
  save_p := PByteArray(integer(save_p) + SAVEMAPNAMESIZE);

  memcpy(save_p, @description[1], SAVESTRINGSIZE);

  save_p := PByteArray(integer(save_p) + SAVESTRINGSIZE);
  name2 := '';

  savegameversion := VERSION;
  sprintf(name2, 'version %d', [VERSION]);
  while length(name2) < SAVEVERSIONSIZE do
    name2 := name2 + ' ';

  memcpy(save_p, @name2[1], SAVEVERSIONSIZE);
  save_p := PByteArray(integer(save_p) + SAVEVERSIONSIZE);
  P_ArchiveScreenShot;

  save_p[0] := Ord(gameskill);
  save_p := PByteArray(integer(save_p) + 1);

  save_p[0] := gameepisode;
  save_p := PByteArray(integer(save_p) + 1);

  save_p[0] := gamemap;
  save_p := PByteArray(integer(save_p) + 1);

  for i := 0 to MAXPLAYERS - 1 do
  begin
    save_p[0] := intval(playeringame[i]);
    save_p := PByteArray(integer(save_p) + 1);
  end;

  save_p[0] := _SHR(leveltime, 16);
  save_p := PByteArray(integer(save_p) + 1);

  save_p[0] := _SHR(leveltime, 8);
  save_p := PByteArray(integer(save_p) + 1);

  save_p[0] := leveltime;
  save_p := PByteArray(integer(save_p) + 1);

  len := integer(save_p) - integer(savebuffer);
  M_WriteFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchivePlayers;

  len := integer(save_p) - integer(savebuffer);
  M_AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveWorld;

  len := integer(save_p) - integer(savebuffer);
  M_AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveThinkers;

  len := integer(save_p) - integer(savebuffer);
  M_AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveSpecials;

  len := integer(save_p) - integer(savebuffer);
  M_AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveVariables;

  len := integer(save_p) - integer(savebuffer);
  M_AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchivePSMapScript;

  len := integer(save_p) - integer(savebuffer);
  M_AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveOverlay;

  save_p[0] := $1d; // consistancy marker

  len := integer(save_p) - integer(savebuffer) + 1;
  if len > maxsize then
    I_Error('G_DoSaveGame(): Savegame buffer overrun');
  M_AppendFile(name, savebuffer, len);

  Z_Free(savebuffer);
  gameaction := ga_nothing;
  savedescription := '';

  players[consoleplayer]._message := GGSAVED;

  // draw the pattern into the back screen
{$IFNDEF OPENGL}
  R_FillBackScreen;
{$ENDIF}
end;

procedure G_DoSaveGame;
var
  name: string;
begin
  if savegameslot = Ord(load_end) then
    name := savename
  else
  begin
    sprintf(name, M_SaveFileName(MARS_GetSavePath + SAVEGAMENAME) + '%d.sav', [savegameslot]);
  end;

  G_DoSaveGameInFile(name);

end;

procedure G_CmdSaveGame(const sname: string; const description: string);
begin
  if not usergame or (gamestate <> GS_LEVEL) then
  begin
    printf('You can''t save if you aren''t playing!'#13#10);
    exit;
  end;

  if sname <> '' then
  begin
    savename := sname;
    if description <> '' then
      savedescription := description
    else
      savedescription := savename;
    sendcmdsave := true;
  end
  else
    printf('Usage: savegame [slot(integer)] [description(string)]');
end;

//
// G_InitNew
// Can be called by the startup code or the menu task,
// consoleplayer, displayplayer, playeringame[] should be set.
//
var
  d_skill: skill_t;
  d_episode: integer;
  d_map: integer;

procedure G_DeferedInitNew(skill: skill_t; episode, map: integer);
begin
  d_skill := skill;
  d_episode := episode;
  d_map := map;
  gameaction := ga_newgame;
end;

procedure G_CmdNewGame(const parm1, parm2: string);
var
  epsd, map: integer;
  mapname: string;
begin
  if parm1 = '' then
  begin
    printf('Please specify the level to play'#13#10);
    exit;
  end;

  mapname := strupper(parm1);

  epsd := atoi(parm1);
  map := atoi(parm2);
  if parm2 = '' then
    if (mapname[1] = 'E') then
      if length(mapname) = 4 then
        if (mapname[3] = 'M') then
        begin
          epsd := atoi(mapname[2]);
          map := atoi(mapname[4]);
        end;

  if W_CheckNumForName(P_GetMapName(epsd, map)) > -1 then
  begin
    players[consoleplayer]._message := STSTR_CLEV;
    G_DeferedInitNew(gameskill, epsd, map);
    C_ExecuteCmd('closeconsole', '1');
  end
  else
    I_Warning('G_CmdNewGame(): Can not load map.'#13#10);
end;

procedure G_CmdTestMap;
var
  epsd, map: integer;
begin
  if gamemode = shareware then
  begin
    I_Warning('G_CmdTestMap(): Can not use this command with the shareware version.'#13#10);
    exit;
  end;

  epsd := 9;
  map := 9;

  if W_CheckNumForName(P_GetMapName(epsd, map)) > -1 then
  begin
    players[consoleplayer]._message := STSTR_CLEV;
    G_DeferedInitNew(gameskill, epsd, map);
    C_ExecuteCmd('closeconsole', '1');
  end
  else
    I_Warning('G_CmdNewGame(): Can not load map.'#13#10);
end;

procedure G_DoNewGame;
var
  i: integer;
begin
  G_FinishedDemoPlayback; // JVAL: remove???
  netdemo := false;
  netgame := false;
  deathmatch := 0;
  for i := 1 to MAXPLAYERS - 1 do
    playeringame[i] := false;
  respawnparm := false;
  fastparm := false;
  nomonsters := false;
  consoleplayer := 0;
  G_InitNew(d_skill, d_episode, d_map);
  gameaction := ga_nothing;
end;

procedure G_InitNew(skill: skill_t; episode, map: integer);
var
  i: integer;
  levelinf: Plevelinfo_t;
begin
  if paused then
  begin
    paused := false;
    S_ResumeSound;
  end;

  if skill > sk_nightmare then
    skill := sk_nightmare;

  if (episode <> 9) or (map <> 9) then
  begin
    // This was quite messy with SPECIAL and commented parts.
    // Supposedly hacks to make the latest edition work.
    // It might not work properly.
    if episode < 1 then
      episode := 1;

    if episode > 3 then
      episode := 3;

    if map < 1 then
      map := 1;

    if episode = 1 then
      if map > 7 then
        map := 7;

    if episode = 2 then
      if map > 9 then
        map := 9;

    if episode = 3 then
      if map > 4 then
        map := 4;
  end;

  levelinf := P_GetLevelInfo(P_GetMapName(episode, map));
  levelinf.musname := stringtochar8('');
  levelinf.skyflat := stringtochar8('');

  R_ResetInterpolationBuffer;

  M_ClearRandom;
  PS_NewWorld;

  if (skill = sk_nightmare) or respawnparm then
    respawnmonsters := true
  else
    respawnmonsters := false;

  if fastparm or ((skill = sk_nightmare) and (gameskill <> sk_nightmare)) then
  begin
    for i := 0 to nummobjtypes - 1 do
      if mobjinfo[i].fastspeed <> 0 then
        mobjinfo[i].speed := mobjinfo[i].fastspeed;
  end
  else if (skill <> sk_nightmare) and (gameskill = sk_nightmare) then
  begin
    for i := 0 to nummobjtypes - 1 do
      if mobjinfo[i].normalspeed <> 0 then
        mobjinfo[i].speed := mobjinfo[i].normalspeed;
  end;

  // force players to be initialized upon first level load
  for i := 0 to MAXPLAYERS - 1 do
    players[i].playerstate := PST_REBORN;

  usergame := true;  // will be set false if a demo
  paused := false;
  G_FinishedDemoPlayback;
  amstate := am_inactive;
  viewactive := true;
  gameepisode := episode;
  gamemap := map;
  gameskill := skill;

  viewactive := true;
  demostarttic := 0;

  G_DoLoadLevel;
end;

//
// DEMO PLAYBACK
//
const
  DEMOMARKER = $80;

var
  compatibility_done: boolean;

//
// Old game versions compatibility
//
procedure G_SafeCompatibilityDemo;
var
  i: integer;
begin
  if compatibility_done then
    exit;

  if players[consoleplayer].playerstate = PST_DEAD then
  begin
    compatibility_done := true;
    i := 4;
    while (integer(@demo_p[i]) < integer(demoend) - 4) and (demo_p[i] <> DEMOMARKER) do
      inc(i, 4);
    // JVAL: Leave maximum 4 seconds after player death
    if i > 4 * TICRATE * 4 then
    begin
      i := 4 * TICRATE * 4;
      demo_p[i] := DEMOMARKER;
    end;
    ZeroMemory(demo_p, i);
  end;
end;

var
  demoversion: byte;

procedure G_ReadDemoTiccmd(cmd: Pticcmd_t);
begin
  if demo_p[0] = DEMOMARKER then
  begin
    // end of demo data stream
    G_CheckDemoStatus;
    exit;
  end;

  if olddemo then
    G_SafeCompatibilityDemo;

  cmd.forwardmove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  cmd.sidemove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  if olddemo then
  begin
    cmd.angleturn := shortint(demo_p[0]) * 256;
    demo_p := @demo_p[1];
  end
  else
  begin
    cmd.angleturn := PSmallInt(demo_p)^;
    demo_p := @demo_p[2];
  end;

  cmd.buttons := demo_p[0] and not BT_SPECIAL;
  demo_p := @demo_p[1];

  if olddemo then
  begin
    cmd.lookupdown := 0;
    cmd.lookupdown16 := 0; // JVAL Smooth Look Up/Down
    cmd.lookleftright := 0;
    cmd.jump := 0;
    cmd.crouch := 0; // JVAL: 20211101 - Crouch
    cmd.fly := 0; // JVAL: 20211109 - Fly (Jet pack)
  end
  else
  begin
    cmd.lookupdown := demo_p[0];
    demo_p := @demo_p[1];

    // JVAL Smooth Look Up/Down
    if demoversion >= VERSION203 then
    begin
      cmd.lookupdown16 := PWord(demo_p)^;
      demo_p := @demo_p[2];
    end
    else
      cmd.lookupdown16 := 256 * cmd.lookupdown;

    cmd.lookleftright := demo_p[0];
    demo_p := @demo_p[1];
    cmd.jump := demo_p[0];
    demo_p := @demo_p[1];
    // JVAL: 20211101 - Crouch
    if demoversion >= VERSION206 then
    begin
      cmd.crouch := demo_p[0];
      demo_p := @demo_p[1];
      // JVAL: 20211109 - Fly (Jet pack)
      cmd.fly := demo_p[0];
      demo_p := @demo_p[1];
    end
    else
    begin
      cmd.crouch := 0;
      cmd.fly := 0;
    end; // JVAL: 20211109 - Fly (Jet pack)
  end;
end;

//
// DEMO RECORDING
//
// Increase the size of the demo buffer to allow unlimited demos
procedure G_IncreaseDemoBuffer;
var
  current_length: integer;
  new_demobuffer: PByteArray;
  new_demop: PByteArray;
  new_length: integer;
begin
  // Find the current size

  current_length := integer(demoend) - integer(demobuffer);

  // Generate a new buffer twice the size
  new_length := current_length + $80000;

  new_demobuffer := Z_Malloc2(new_length, PU_STATIC, nil);
  if new_demobuffer = nil then
    G_CheckDemoStatus;

  new_demop := @new_demobuffer[integer(demo_p) - integer(demobuffer)];

  // Copy over the old data

  memcpy(new_demobuffer, demobuffer, current_length);

  // Free the old buffer and point the demo pointers at the new buffer.

  Z_Free(demobuffer);

  demobuffer := new_demobuffer;
  demo_p := new_demop;
  demoend := @demobuffer[new_length];
end;

//
// DEMO RECORDING
//
procedure G_WriteDemoTiccmd(cmd: Pticcmd_t);
var
  demo_start: PByteArray;
begin
  if gamekeydown[Ord('q')] then // press q to end demo recording
    G_CheckDemoStatus;

  demo_start := demo_p;

  demo_p[0] := Ord(cmd.forwardmove);
  demo_p := @demo_p[1];

  demo_p[0] := Ord(cmd.sidemove);
  demo_p := @demo_p[1];

  PSmallInt(demo_p)^ := cmd.angleturn;
  demo_p := @demo_p[2];

  demo_p[0] := cmd.buttons and not BT_SPECIAL;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.lookupdown;
  demo_p := @demo_p[1];

  // JVAL Smooth Look Up/Down
  PWord(demo_p)^ := cmd.lookupdown16;
  demo_p := @demo_p[2];

  demo_p[0] := cmd.lookleftright;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.jump;
  // JVAL: 20211101 - Crouch
  demo_p := @demo_p[1];
  // JVAL: 20211101 - Crouch
  demo_p[0] := cmd.crouch;
  // JVAL: 20211109 - Fly (Jet pack)
  demo_p := @demo_p[1];
  // JVAL: 20211109 - Fly (Jet pack)
  demo_p[0] := cmd.fly;

  demo_p := demo_start;

  if integer(demo_p) >= integer(demoend) - 2 * SizeOf(ticcmd_t) then
    G_IncreaseDemoBuffer;

  G_ReadDemoTiccmd(cmd);  // make SURE it is exactly the same
end;

//
// G_RecordDemo
//
procedure G_RecordDemo(const name: string);
var
  i: integer;
  maxsize: integer;
begin
  usergame := false;
  demoname := name;
  if Pos('.', demoname) = 0 then
    demoname := demoname + '.lmp';


  i := M_CheckParm ('-maxdemo');
  if (i <> 0) and (i < myargc - 1) then
    maxsize := atoi(myargv[i + 1]) * 1024
  else
    maxsize := $80000; // JVAL Originally was $20000

  repeat
    demobuffer := Z_Malloc2(maxsize, PU_STATIC, nil);
    if demobuffer = nil then
      maxsize := maxsize * 3 div 4;
  until demobuffer <> nil;

  demoend := @demobuffer[maxsize];

  demorecording := true;
  Info_Init(true); // JVAL: Start thinkers
end;

const
  DEMOHDR: integer = $4F4D4544; // JVAL: DEMO in hex

procedure G_BeginRecording;
var
  i: integer;
begin
  demo_p := demobuffer;
  demoversion := VERSION;

  PInteger(demo_p)^ := DEMOHDR;
  demo_p := @demo_p[4];

  demo_p[0] := VERSION;
  demo_p := @demo_p[1];

  demo_p[0] := Ord(gameskill);
  demo_p := @demo_p[1];

  demo_p[0] := gameepisode;
  demo_p := @demo_p[1];

  demo_p[0] := gamemap;
  demo_p := @demo_p[1];

  demo_p[0] := deathmatch;
  demo_p := @demo_p[1];

  demo_p[0] := intval(respawnparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(fastparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(nomonsters);
  demo_p := @demo_p[1];

  demo_p[0] := intval(compatibilitymode);
  demo_p := @demo_p[1];

  demo_p[0] := intval(spawnrandommonsters);
  demo_p := @demo_p[1];

  demo_p[0] := sysrndseed;
  demo_p := @demo_p[1];

  // JVAL: Version 205 - Dogs
  demo_p[0] := dogs;
  demo_p := @demo_p[1];

  demo_p[0] := dog_jumping;
  demo_p := @demo_p[1];

  demo_p[0] := consoleplayer;
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    demo_p[0] := intval(playeringame[i]);
    demo_p := @demo_p[1];
  end;

end;

//
// G_PlayDemo
//
var
  defdemoname: string;
  externaldemo: boolean = false;

function G_DoPlayExternalDemo(const name: string): boolean;
var
  dmname: string;
begin
  dmname := name;
  if not fexists(dmname) then
    if M_CheckParmCDROM then
      dmname := CD_WORKDIR + dmname;
  if fexists(dmname) then
  begin
    externaldemo := true;
    defdemoname := dmname;
    gameaction := ga_playdemo;
    printf('Playing demo %s'#13#10, [defdemoname]);
    result := true;
    exit;
  end;
  result := false;
end;

function G_DeferedPlayDemo(const name: string): boolean;
var
  dmname: string;
  dmname2: string;
  defdemoname8: char8_t;
  i: integer;
  pdot: integer;
begin
  dmname := name;
  for i := 0 to 9 do
    if itoa(i) = name then
    begin
      sprintf(dmname, 'demo%d', [i]);
      break;
    end;

  pdot := Pos('.', dmname);
  if ((Length(dmname) <= 8) and (pdot = 0)) or ((pdot < 9) and (pdot <> 0)) then
  begin
    ExtractFileBase8(dmname, defdemoname8);
    defdemoname := char8tostring(defdemoname8);
    if W_CheckNumForName(defdemoname) >= 0 then
    begin
      externaldemo := false;
      gameaction := ga_playdemo;
      printf('Playing demo %s'#13#10, [defdemoname]);
      result := true;
      exit;
    end;
  end;

  // JVAL
  // Playdemo command also looks for a filename in current or CD_WORK directory
  dmname2 := dmname;
  if pdot = 0 then
    dmname := dmname + '.lmp';
  if G_DoPlayExternalDemo(dmname) then
  begin
    result := true;
    exit;
  end;

  if pdot = 0 then
  begin
    dmname := dmname2 + '.dem';
    if G_DoPlayExternalDemo(dmname) then
    begin
      result := true;
      exit;
    end;
  end;

  I_Warning('G_DeferedPlayDemo(): Can not find demo %s.'#13#10, [defdemoname]);
  result := false;
end;

procedure G_CmdPlayDemo(const name: string);
begin
  if G_DeferedPlayDemo(name) then
    C_ExecuteCmd('closeconsole', '1');
end;

var
  demotickstart: pointer = nil;

procedure G_DoPlayDemo;
var
  skill: skill_t;
  i, episode, map: integer;
  lump: integer;
  len: integer;
  oldspawnrandommonsters: boolean;
  olddogs, olddog_jumping: integer;
begin
  gameaction := ga_nothing;
  if externaldemo then
    len := M_ReadFile(defdemoname, pointer(demobuffer))
  else
  begin
    lump := W_GetNumForName(defdemoname);
    demobuffer := W_CacheLumpNum(lump, PU_STATIC);
    len := W_LumpLength(lump);
  end;

  demo_p := demobuffer;
  demoend := @demo_p[len];

  if oldsharewareversion then
  begin
    I_Warning('G_DoPlayDemo(): Demo is from an unsupported game version = 0.99'#13#10);
    exit;
  end;

  if PInteger(demo_p)^ = DEMOHDR then
  begin
    demo_p := @demo_p[4];
    demoversion := demo_p[0];
  end
  else
  begin
    demoversion := demobuffer[0];
    olddemo := (demoversion <= 110) and (demoversion >= 109);
    if olddemo then
    begin
      if allowvanillademos and not vanilla_demo_off then
        I_Warning('G_DoPlayDemo(): Playing demo from partial compatible version = %d.%d'#13#10,
          [demo_p[0] div 100, demo_p[0] mod 100])
      else
      begin
        if vanilla_demo_off then
          printf('  vanilla demo playback has been disabled'#13#10);
        exit;
      end;
    end
    else if demo_p[0] <> VERSION then
    begin
      I_Warning('G_DoPlayDemo(): Demo is from an unsupported game version = %d.%d'#13#10,
        [demo_p[0] div 100, demo_p[0] mod 100]);
      gameaction := ga_nothing;
      exit;
    end;
  end;

  demo_p := @demo_p[1];

  skill := skill_t(demo_p[0]);
  demo_p := @demo_p[1];

  episode := demo_p[0];
  demo_p := @demo_p[1];

  map := demo_p[0];
  demo_p := @demo_p[1];

  deathmatch := demo_p[0];
  demo_p := @demo_p[1];

  respawnparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  fastparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  nomonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  oldcompatibilitymode := compatibilitymode;
  if olddemo then
    compatibilitymode := true // force old compatibility mode
  else
  begin
    compatibilitymode := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;

  oldspawnrandommonsters := spawnrandommonsters;
  if demoversion >= VERSION114 then
  begin
    spawnrandommonsters := demo_p[0] <> 0;
    demo_p := @demo_p[1];
    if demoversion >= VERSION120 then
    begin
      sysrndseed := demo_p[0];
      demo_p := @demo_p[1];
    end;
  end
  else
  begin
    spawnrandommonsters := false;
  end;

  // JVAL: Version 205 - Dogs
  olddogs := dogs;
  olddog_jumping := dog_jumping;
  if demoversion >= VERSION205 then
  begin
    dogs := demo_p[0];
    demo_p := @demo_p[1];
    dog_jumping := demo_p[0];
    demo_p := @demo_p[1];
  end
  else
  begin
    dogs := 0;
    dog_jumping := 0;
  end;

  consoleplayer := demo_p[0];
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;

  if playeringame[1] then
  begin
    netgame := true;
    netdemo := true;
  end;

  preparingdemoplayback := true;
  // don't spend a lot of time in loadlevel if not singledemo
  precache := singledemo; // JVAL original code: precache := false
  G_InitNew(skill, episode, map);
  preparingdemoplayback := false;
  spawnrandommonsters := oldspawnrandommonsters;  // Back to default
  dogs := olddogs;
  dog_jumping := olddog_jumping;
  precache := true;
  demostarttic := gametic; // [crispy] fix revenant internal demo bug
  usergame := false;
  demoplayback := true;
  demotickstart := demo_p;
  Info_Init(true); // JVAL: Start thinkers

  compatibility_done := false;
end;

// 19/9/2009 JVAL: For drawing demo progress
function G_DemoProgress: fixed_t;
begin
  result := round((integer(demo_p) - integer(demotickstart)) / (integer(demoend) - integer(demotickstart)) * FRACUNIT);
  if result > FRACUNIT then
    result := FRACUNIT
  else if result < 0 then
    result := 0;
end;

//
// G_TimeDemo
//
procedure G_TimeDemo(const name: string);
begin
  timingdemo := true;
  singletics := true;

  defdemoname := name;
  gameaction := ga_playdemo;
end;

(*
===================
=
= G_CheckDemoStatus
=
= Called after a death or level completion to allow demos to be cleaned up
= Returns true if a new demo loop action will take place
===================
*)

function G_CheckDemoStatus: boolean;
var
  realtics: integer;
  i: integer;
begin
  if timingdemo then
  begin
    realtics := I_GetTime - starttime;
    if realtics > 0 then
      I_Error('G_CheckDemoStatus(): timed %d gametics in %d realtics'#13#10'(%3.2ffps)',
        [gametic, realtics, gametic / realtics * TICRATE])
    else
      I_Error('G_CheckDemoStatus(): timed %d gametics in %d realtics',
        [gametic, realtics]);
  end;

  if demoplayback then
  begin
    if singledemo then
      I_Quit;

    Z_Free(demoBuffer);
    G_FinishedDemoPlayback;
    netdemo := false;
    netgame := false;
    deathmatch := 0;
    for i := 1 to MAXPLAYERS - 1 do
      playeringame[i] := false;
    respawnparm := false;
    fastparm := false;
    nomonsters := false;
    consoleplayer := 0;
    D_AdvanceDemo;
    result := true;
    exit;
  end;

  if demorecording then
  begin
    demo_p[0] := DEMOMARKER;
    demo_p := @demo_p[1];

    M_WriteFile(demoname, demobuffer, pDiff(demo_p, demobuffer, SizeOf(byte)));
    Z_Free(demobuffer);
    demorecording := false;
    I_Error('G_CheckDemoStatus(): Demo %s recorded', [demoname]);
  end;

  result := false;
end;

function G_IsOldDemoPlaying: boolean;
begin
  result := (preparingdemoplayback or demoplayback) and olddemo;
end;

function G_NeedsCompatibilityMode: boolean;
begin
  result := compatibilitymode or ((preparingdemoplayback or demoplayback) and olddemo) or forcecompatibilitymode;
end;

function G_PlayingEngineVersion: integer;
begin
  if demoplayback or preparingdemoplayback then
    result := demoversion
  else
    result := VERSION;
end;

procedure G_Quit;
begin
  if displayendscreen then
  begin
    gamestate := GS_ENDOOM;
    S_PauseSound; // Stop music in ENDOOM screen
    printf('E_Init: Initializing ENDOOM screen.'#13#10);
    E_Init;
  end
  else
    I_Quit;
end;

initialization

  forwardmove[0] := $19;
  forwardmove[1] := $32;
  sidemove[0] := $18;
  sidemove[1] := $28;
  angleturn[0] := 640;
  angleturn[1] := 1280;
  angleturn[2] := 320;

  mousebuttons := PBooleanArray(@mousearray[0]);
  joybuttons := PBooleanArray(@joyarray[0]);


  ZeroMemory(@pars, SizeOf(pars));

  pars[1, 1] := 20 * 60 + 29;
  pars[1, 2] := 23 * 60 + 3;
  pars[1, 3] := 20 * 60 + 58;
  pars[1, 4] := 14 * 60 + 10;
  pars[1, 5] := 17 * 60 + 22;
  pars[1, 6] := 10 * 60;
  pars[1, 7] := 180;
  pars[1, 8] := 30;
  pars[1, 9] := 165;

  pars[2, 1] := 90;
  pars[2, 2] := 90;
  pars[2, 3] := 90;
  pars[2, 4] := 120;
  pars[2, 5] := 90;
  pars[2, 6] := 360;
  pars[2, 7] := 240;
  pars[2, 8] := 30;
  pars[2, 9] := 170;

  pars[3, 1] := 90;
  pars[3, 2] := 45;
  pars[3, 3] := 90;
  pars[3, 4] := 150;
  pars[3, 5] := 90;
  pars[3, 6] := 90;
  pars[3, 7] := 165;
  pars[3, 8] := 30;
  pars[3, 9] := 135;

  precache := true;

  KEY_WEAPONS[0] := @key_weapon0;
  KEY_WEAPONS[1] := @key_weapon1;
  KEY_WEAPONS[2] := @key_weapon2;
  KEY_WEAPONS[3] := @key_weapon3;
  KEY_WEAPONS[4] := @key_weapon4;
  KEY_WEAPONS[5] := @key_weapon5;
  KEY_WEAPONS[6] := @key_weapon6;
  KEY_WEAPONS[7] := @key_weapon7;
  KEY_WEAPONS[8] := @key_weapon8;
  KEY_WEAPONS[9] := @key_weapon9;

end.

