//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars - The Ultimate Fighter"
//
//  Copyright (C) 1997 by Engine Technology CO. LTD
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2018 by Retro Fans of Mars3D
//  Copyright (C) 2004-2022 by Jim Valavanis
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
// DESCRIPTION:
//  Status bar code.
//  Does the face/direction indicator animatin.
//  Does palette indicators as well (red pain/berserk, bright pickup)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit st_stuff;

interface

uses
  d_event;

// Size of statusbar.
// Now sensitive for scaling.
const
  ST_HEIGHT = 31;
  ST_Y = 200 - ST_HEIGHT;

var
  st_palette: integer;
  st_gamma: integer = -1;
// lump number for PLAYPAL
  lu_palette: integer;

//==============================================================================
// ST_Responder
//
// STATUS BAR
//
// Called by main loop.
//
//==============================================================================
function ST_Responder(ev: Pevent_t): boolean;

//==============================================================================
// ST_Ticker
//
// Called by main loop.
//
//==============================================================================
procedure ST_Ticker;

//==============================================================================
//
// ST_DoPaletteStuff
//
//==============================================================================
procedure ST_DoPaletteStuff;

//==============================================================================
// ST_Start
//
// Called when the console player is spawned on each level.
//
//==============================================================================
procedure ST_Start;

//==============================================================================
// ST_Init
//
// Called by startup code.
//
//==============================================================================
procedure ST_Init;

// States for status bar code.
type
  st_stateenum_t = (
    st_automapstate,
    st_firstpersonstate
  );

// States for the chat code.
  st_chatstateenum_t = (
    StartChatState,
    WaitDestState,
    GetChatState
  );

var
  p_idfaarmor: integer = 200;
  p_idfaarmorclass: integer = 2;
  p_idkfaarmor: integer = 200;
  p_idkfaarmorclass: integer = 2;

implementation

uses
  d_delphi,
  doomdef,
  c_cmds,
  d_items,
  z_zone,
  w_wad,
  info,
  info_h,
{$IFDEF OPENGL}
  gl_main,
  gl_render,
  v_video,
{$ELSE}
  r_hires,
  i_video,
{$ENDIF}
  g_game,
  p_inter,
  p_setup,
  p_enemy,
  d_player,
  r_defs,
  am_map,
  m_cheat,
  m_fixed,
  s_sound,
// Needs access to LFB.
  v_data,
  v_video,
// State.
  doomstat,
// Data.
  d_englsh,
  sounds;

//
// STATUS BAR DATA
//

const
// Palette indices.
// For damage/bonus red-/gold-shifts
  STARTREDPALS = 1;
  STARTBONUSPALS = 9;
  NUMREDPALS = 8;
  NUMBONUSPALS = 4;
// Radiation suit, green shift.
  RADIATIONPAL = 13;
// Green palettes (Poison damage) - Mars
  STARTGREENPALS = 14;
  NUMGREENPALS = 8;

var
  plyr: Pplayer_t;                  // main player in game
  st_firsttime: boolean;            // ST_Start() has just been called
  st_clock: LongWord;               // used for timing
  st_msgcounter: integer;           // used for making messages go away
  st_chatstate: st_chatstateenum_t; // used when in chat
  st_gamestate: st_stateenum_t;     // whether in automap or first-person
  st_statusbaron: boolean;          // whether left-side main status bar is active
  st_chat: boolean;                 // whether status bar chat is active
  st_oldchat: boolean;              // value of st_chat before message popped up
  st_cursoron: boolean;             // whether chat window has the cursor on
  st_oldhealth: integer;            // used to use appopriately pained face
  st_facecount: integer;            // count until face changes
  st_faceindex: integer;            // current face index, used by w_faces
  keyboxes: array[0..2] of integer; // holds key-type for each key box on bar

const
// Massive bunches of cheat shit
//  to keep it from being easy to figure them out.
// Yeah, right...
  cheat_mus_seq: array[0..8] of char = (
    Chr($b2), Chr($26), Chr($b6), Chr($ae), Chr($ea),
    Chr($1),  Chr($0),  Chr($0),  Chr($ff)
  ); // idmus

  cheat_god_seq: array[0..5] of char = (
    Chr($b2), Chr($26), Chr($26), Chr($aa), Chr($26),
    Chr($ff)  // iddqd
  );

  cheat_ammo_seq: array[0..5] of char = (
    Chr($b2), Chr($26), Chr($f2), Chr($66), Chr($a2),
    Chr($ff)  // idkfa
  );

  cheat_ammonokey_seq: array[0..4] of char = (
    Chr($b2), Chr($26), Chr($66), Chr($a2), Chr($ff) // idfa
  );

// Smashing Pumpkins Into Samml Piles Of Putried Debris.
  cheat_noclip_seq: array[0..10] of char = (
    Chr($b2), Chr($26), Chr($ea), Chr($2a), Chr($b2), // idspispopd
    Chr($ea), Chr($2a), Chr($f6), Chr($2a), Chr($26),
    Chr($ff)
  );

//
  cheat_commercial_noclip_seq: array[0..6] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($36), Chr($b2),
    Chr($2a), Chr($ff)  // idclip
  );

  cheat_powerup_seq0: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($6e), Chr($ff)  // beholdv
  );

  cheat_powerup_seq1: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($ea), Chr($ff)  // beholds
  );

  cheat_powerup_seq2: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($b2), Chr($ff)  // beholdi
  );

  cheat_powerup_seq3: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($6a), Chr($ff)  // beholdr
  );

  cheat_powerup_seq4: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($a2), Chr($ff)  // beholda
  );

  cheat_powerup_seq5: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($36), Chr($ff)  // beholdl
  );

  cheat_powerup_seq6: array[0..8] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($ff)  // behold
  );

  cheat_clev_seq: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($36), Chr($a6),
    Chr($6e), Chr($1),  Chr($0),  Chr($0),  Chr($ff)  // idclev
  );

// my position cheat
  cheat_mypos_seq: array[0..7] of char = (
    Chr($b2), Chr($26), Chr($b6), Chr($ba), Chr($2a),
    Chr($f6), Chr($ea), Chr($ff) // idmypos
  );

// JVAL: Give All Keys cheat
  cheat_idkeys_seq: array[0..6] of char = (
    Chr($b2), Chr($26), Chr($f2), Chr($a6), Chr($ba),
    Chr($ea), Chr($ff) // idkeys
  );

var
// Now what?
  cheat_mus: cheatseq_t;
  cheat_god: cheatseq_t;
  cheat_ammo: cheatseq_t;
  cheat_ammonokey: cheatseq_t;
  cheat_keys: cheatseq_t;
  cheat_noclip: cheatseq_t;
  cheat_commercial_noclip: cheatseq_t;

  cheat_powerup: array[0..6] of cheatseq_t;

  cheat_clev: cheatseq_t;
  cheat_mypos: cheatseq_t;

//==============================================================================
// ST_CmdCheckPlayerStatus
//
// Commands
//
//==============================================================================
function ST_CmdCheckPlayerStatus: boolean;
begin
  if (plyr = nil) or (plyr.mo = nil) or (gamestate <> GS_LEVEL) or demoplayback or netgame then
  begin
    printf('You can''t specify the command at this time.'#13#10);
    result := false;
  end
  else
    result := true;
end;

//==============================================================================
//
// ST_CmdGod
//
//==============================================================================
procedure ST_CmdGod;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  if plyr.playerstate <> PST_DEAD then
  begin
    plyr.cheats := plyr.cheats xor CF_GODMODE;
    if plyr.cheats and CF_GODMODE <> 0 then
    begin
      if plyr.mo <> nil then
        plyr.mo.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;

      plyr.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;
      plyr._message := STSTR_DQDON;
    end
    else
      plyr._message := STSTR_DQDOFF;
  end
  else
  begin
    C_ExecuteCmd('closeconsole');
    plyr.playerstate := PST_REBORN;
  end;
end;

//==============================================================================
//
// ST_CmdMassacre
//
//==============================================================================
procedure ST_CmdMassacre;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  if (gamestate = GS_LEVEL) and (plyr.mo <> nil) then
  begin
    P_Massacre;
    plyr._message := STSTR_MASSACRE;
  end;
end;

//==============================================================================
//
// ST_CmdLowGravity
//
//==============================================================================
procedure ST_CmdLowGravity;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.cheats := plyr.cheats xor CF_LOWGRAVITY;
  if plyr.cheats and CF_LOWGRAVITY <> 0 then
    plyr._message := STSTR_LGON
  else
    plyr._message := STSTR_LGOFF;
end;

//==============================================================================
//
// ST_CmdIDFA
//
//==============================================================================
procedure ST_CmdIDFA;
var
  i: integer;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.armorpoints := p_idfaarmor;
  plyr.armortype := p_idfaarmorclass;

  for i := 0 to Ord(NUMWEAPONS) - 1 do
    if weaponinfo[i].flags and WF_WEAPON <> 0 then
      if (gamemode <> shareware) or (weaponinfo[i].flags and WF_DEMOAVAILABLE <> 0) then
        plyr.weaponowned[i] := 1;

  for i := 0 to Ord(NUMAMMO) - 1 do
    plyr.ammo[i] := plyr.maxammo[i];

  plyr._message := STSTR_FAADDED;
end;

//==============================================================================
//
// ST_CmdIDKFA
//
//==============================================================================
procedure ST_CmdIDKFA;
var
  i: integer;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.armorpoints := p_idkfaarmor;
  plyr.armortype := p_idkfaarmorclass;

  for i := 0 to Ord(NUMWEAPONS) - 1 do
    if weaponinfo[i].flags and WF_WEAPON <> 0 then
      if (gamemode <> shareware) or (weaponinfo[i].flags and WF_DEMOAVAILABLE <> 0) then
        plyr.weaponowned[i] := 1;

  for i := 0 to Ord(NUMAMMO) - 1 do
    plyr.ammo[i] := plyr.maxammo[i];

  for i := 0 to Ord(NUMCARDS) - 1 do
    plyr.cards[i] := true;

  plyr._message := STSTR_KFAADDED;
end;

//==============================================================================
//
// ST_CmdIDKEYS
//
//==============================================================================
procedure ST_CmdIDKEYS;
var
  i: integer;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  for i := 0 to Ord(NUMCARDS) - 1 do
    plyr.cards[i] := true;

  plyr._message := STSTR_KEYSADDED;
end;

//==============================================================================
//
// ST_CmdIDDT
//
//==============================================================================
procedure ST_CmdIDDT;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  am_cheating := (am_cheating + 1) mod 3;
end;

//==============================================================================
//
// ST_CmdIDNoClip
//
//==============================================================================
procedure ST_CmdIDNoClip;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.cheats := plyr.cheats xor CF_NOCLIP;

  if plyr.cheats and CF_NOCLIP <> 0 then
    plyr._message := STSTR_NCON
  else
    plyr._message := STSTR_NCOFF;
end;

//==============================================================================
//
// ST_CmdIDMyPos
//
//==============================================================================
procedure ST_CmdIDMyPos;
var
  buf: string;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  sprintf(buf, 'ang = %d, (x, y, z) = (%d, %d, %d)', [
          plyr.mo.angle div $B60B60,
          plyr.mo.x div FRACUNIT,
          plyr.mo.y div FRACUNIT,
          plyr.mo.z div FRACUNIT]);
  plyr._message := buf;
end;

//==============================================================================
// ST_Responder
//
// STATUS BAR CODE
//
// Respond to keyboard input events,
//  intercept cheats.
//
//==============================================================================
function ST_Responder(ev: Pevent_t): boolean;
var
  i: integer;
  buf: string;
  musnum: integer;
  epsd: integer;
  map: integer;
  ateit: boolean; // JVAL Cheats ate the event

  function check_cheat(cht: Pcheatseq_t; key: char): boolean;
  var
    cht_ret: cheatstatus_t;
  begin
    cht_ret := cht_CheckCheat(cht, key);
    result := cht_ret = cht_acquired;
    if not ateit then
      ateit := (cht_ret in [cht_pending, cht_acquired])
  end;

begin
  result := false;
  ateit := false;
  // Filter automap on/off.
  if (ev._type = ev_keyup) and
     ((ev.data1 and $ffff0000) = AM_MSGHEADER) then
  begin
    case ev.data1 of
      AM_MSGENTERED:
        begin
          st_gamestate := st_automapstate;
          st_firsttime := true;
        end;

      AM_MSGEXITED:
        begin
          //  fprintf(stderr, "AM exited\n");
          st_gamestate := st_firstpersonstate;
        end;
    end;
  end
  // if a user keypress...
  else if ev._type = ev_keydown then
  begin
    if plyr = nil then
    begin
      result := false;
      exit;
    end;

    if plyr.mo = nil then
    begin
      result := false;
      exit;
    end;

    if not netgame then
    begin
      // b. - enabled for more debug fun.
      // if (gameskill != sk_nightmare) {

      // 'dqd' cheat for toggleable god mode
      if check_cheat(@cheat_god, Chr(ev.data1)) then
      begin
        ST_CmdGod;
      end
      // 'fa' cheat for killer fucking arsenal
      else if check_cheat(@cheat_ammonokey, Chr(ev.data1)) then
      begin
        ST_CmdIDFA;
      end
      // JVAL: 'keys' cheat
      else if check_cheat(@cheat_keys, Chr(ev.data1)) then
      begin
        ST_CmdIDKEYS;
      end
      // 'kfa' cheat for key full ammo
      else if check_cheat(@cheat_ammo, Chr(ev.data1)) then
      begin
        ST_CmdIDKFA;
      end
      else if check_cheat(@cheat_amap, Chr(ev.data1)) then
      begin
        ST_CmdIDDT;
      end
      // 'mus' cheat for changing music
      else if check_cheat(@cheat_mus, Chr(ev.data1)) then
      begin
        plyr._message := STSTR_MUS;
        cht_GetParam(@cheat_mus, buf);

        musnum := Ord(mus_e1m1) + (Ord(buf[1]) - Ord('1')) * 9 + Ord(buf[2]) - Ord('1');

        if (musnum > 0) and (buf[2] <> '0') and
           ( ((musnum < 28) and (gamemode <> shareware)) or
             ((musnum < 10) and (gamemode = shareware))) then
          S_ChangeMusic(musnum, true)
        else
          plyr._message := STSTR_NOMUS;
      end
      // Simplified, accepting both "noclip" and "idspispopd".
      // no clipping mode cheat
      else if check_cheat(@cheat_noclip, Chr(ev.data1)) or
              check_cheat(@cheat_commercial_noclip, Chr(ev.data1)) then
      begin
        ST_CmdIDNoClip;
      end;
      // 'behold?' power-up cheats
      for i := 0 to 5 do
      begin
        if check_cheat(@cheat_powerup[i], Chr(ev.data1)) then
        begin
          if plyr.powers[i] = 0 then
            P_GivePower(plyr, i)
          else if i <> Ord(pw_strength) then
            plyr.powers[i] := 1
          else
            plyr.powers[i] := 0;

          plyr._message := STSTR_BEHOLDX;
        end;
      end;

      // 'behold' power-up menu
      if check_cheat(@cheat_powerup[6], Chr(ev.data1)) then
      begin
        plyr._message := STSTR_BEHOLD;
      end
      // 'mypos' for player position
      else if check_cheat(@cheat_mypos, Chr(ev.data1)) then
      begin
        ST_CmdIDMyPos;
      end;
    end;

    // 'clev' change-level cheat
    if check_cheat(@cheat_clev, Chr(ev.data1)) then
    begin
      cht_GetParam(@cheat_clev, buf);
      plyr._message := STSTR_WLEV;

      epsd := Ord(buf[1]) - Ord('0');
      map := Ord(buf[2]) - Ord('0');
      // Catch invalid maps.
      if epsd < 1 then
        exit;

      if map < 1 then
        exit;

      // Ohmygod - this is not going to work.
      if gamemode = shareware then
      begin
        if epsd = 1 then
        begin
          if not IsIntegerInRange(map, 1, 2) then
            exit;
        end
        else if epsd = 2 then
        begin
          if not IsIntegerInRange(map, 1, 3) then
            exit;
        end
        else
          exit;
      end
      else
      begin
        if epsd = 1 then
        begin
          if not IsIntegerInRange(map, 1, 7) then
            exit;
        end
        else if epsd = 2 then
        begin
          if not IsIntegerInRange(map, 1, 9) then
            exit;
        end
        else if epsd = 3 then
        begin
          if not IsIntegerInRange(map, 1, 4) then
            exit;
        end
        else
          exit;
      end;

      // So be it.
      if W_CheckNumForName(P_GetMapName(epsd, map)) > -1 then
      begin
        plyr._message := STSTR_CLEV;
        G_DeferedInitNew(gameskill, epsd, map);
      end;
    end;
  end;
  result := result or ateit;
end;

//==============================================================================
//
// ST_Ticker
//
//==============================================================================
procedure ST_Ticker;
begin
  inc(st_clock);
  if plyr <> nil then
    st_oldhealth := plyr.health;
end;

//==============================================================================
//
// ST_DoPaletteStuff
//
//==============================================================================
procedure ST_DoPaletteStuff;
var
  palette: integer;
  pal: PByteArray;
  cnt: integer;
  bzc: integer;
  p: pointer;
begin
  if plyr = nil then
    exit;

  cnt := plyr.damagecount;

  if plyr.powers[Ord(pw_strength)] <> 0 then
  begin
    // slowly fade the berzerk out
    bzc := 12 - _SHR(plyr.powers[Ord(pw_strength)], 6);

    if bzc > cnt then
      cnt := bzc;
  end;

  if cnt <> 0 then
  begin
    palette := _SHR(cnt + 7, 3);

    if plyr.damagetype = DAMAGE_POISON then
    begin
      if palette >= NUMGREENPALS then
        palette := NUMGREENPALS - 1;

      palette := palette + STARTGREENPALS;
    end
    else
    begin
      if palette >= NUMREDPALS then
        palette := NUMREDPALS - 1;

      palette := palette + STARTREDPALS;
    end;
  end
  else if plyr.bonuscount <> 0 then
  begin
    palette := _SHR(plyr.bonuscount + 7, 3);

    if palette >= NUMBONUSPALS then
      palette := NUMBONUSPALS - 1;

    palette := palette + STARTBONUSPALS;
  end
  else if (plyr.powers[Ord(pw_ironfeet)] > 4 * 32) or
          (plyr.powers[Ord(pw_ironfeet)] and 8 <> 0) then
    palette := RADIATIONPAL
  else
    palette := 0;

  if Psubsector_t(plyr.mo.subsector).sector.renderflags and SRF_UNDERWATER <> 0 then
    palette := palette + 14;

  if (palette <> st_palette) or (usegamma <> st_gamma) then
  begin
    st_palette := palette;
    st_gamma := usegamma;
    {$IFDEF OPENGL}
    gld_SetPalette(palette);
    {$ELSE}
    R_SetPalette(palette);
    {$ENDIF}
    p := W_CacheLumpNum(lu_palette, PU_STATIC);
    pal := PByteArray(integer(p) + palette * 768);
    {$IFDEF OPENGL}
    I_SetPalette(pal);
    V_SetPalette(pal);
    {$ELSE}
    IV_SetPalette(pal);
    {$ENDIF}
    Z_ChangeTag(p, PU_CACHE);
  end;
end;

//==============================================================================
//
// ST_LoadData
//
//==============================================================================
procedure ST_LoadData;
begin
  lu_palette := W_GetNumForName(PLAYPAL);
end;

//==============================================================================
//
// ST_InitData
//
//==============================================================================
procedure ST_InitData;
var
  i: integer;
begin
  st_firsttime := true;
  plyr := @players[consoleplayer];

  st_clock := 0;
  st_chatstate := StartChatState;
  st_gamestate := st_firstpersonstate;

  st_statusbaron := true;
  st_oldchat := false;
  st_chat := false;
  st_cursoron := false;

  st_faceindex := 0;
  st_palette := -1;

  st_oldhealth := -1;

  for i := 0 to 2 do
    keyboxes[i] := -1;
end;

var
  st_stopped: boolean;

//==============================================================================
//
// ST_Stop
//
//==============================================================================
procedure ST_Stop;
var
  pal: PByteArray;
begin
  if st_stopped then
    exit;

  pal := W_CacheLumpNum(lu_palette, PU_STATIC);
  {$IFDEF OPENGL}
  I_SetPalette(pal);
  V_SetPalette(pal);
  {$ELSE}
  IV_SetPalette(pal);
  {$ENDIF}
  Z_ChangeTag(pal, PU_CACHE);

  st_stopped := true;
end;

//==============================================================================
//
// ST_Start
//
//==============================================================================
procedure ST_Start;
begin
  if not st_stopped then
    ST_Stop;

  ST_InitData;
  st_stopped := false;
end;

//==============================================================================
//
// ST_Init
//
//==============================================================================
procedure ST_Init;
begin
////////////////////////////////////////////////////////////////////////////////
  st_msgcounter := 0;
  st_oldhealth := -1;
  st_facecount := 0;
  st_faceindex := 0;

////////////////////////////////////////////////////////////////////////////////
// Now what?
  cheat_mus.sequence := get_cheatseq_string(cheat_mus_seq);
  cheat_mus.p := get_cheatseq_string(0);
  cheat_god.sequence := get_cheatseq_string(cheat_god_seq);
  cheat_god.p := get_cheatseq_string(0);
  cheat_ammo.sequence := get_cheatseq_string(cheat_ammo_seq);
  cheat_ammo.p := get_cheatseq_string(0);
  cheat_ammonokey.sequence := get_cheatseq_string(cheat_ammonokey_seq);
  cheat_ammonokey.p := get_cheatseq_string(0);
  cheat_keys.sequence := get_cheatseq_string(cheat_idkeys_seq);
  cheat_keys.p := get_cheatseq_string(0);
  cheat_noclip.sequence := get_cheatseq_string(cheat_noclip_seq);
  cheat_noclip.p := get_cheatseq_string(0);
  cheat_commercial_noclip.sequence := get_cheatseq_string(cheat_commercial_noclip_seq);
  cheat_commercial_noclip.p := get_cheatseq_string(0);

  cheat_powerup[0].sequence := get_cheatseq_string(cheat_powerup_seq0);
  cheat_powerup[0].p := get_cheatseq_string(0);
  cheat_powerup[1].sequence := get_cheatseq_string(cheat_powerup_seq1);
  cheat_powerup[1].p := get_cheatseq_string(0);
  cheat_powerup[2].sequence := get_cheatseq_string(cheat_powerup_seq2);
  cheat_powerup[2].p := get_cheatseq_string(0);
  cheat_powerup[3].sequence := get_cheatseq_string(cheat_powerup_seq3);
  cheat_powerup[3].p := get_cheatseq_string(0);
  cheat_powerup[4].sequence := get_cheatseq_string(cheat_powerup_seq4);
  cheat_powerup[4].p := get_cheatseq_string(0);
  cheat_powerup[5].sequence := get_cheatseq_string(cheat_powerup_seq5);
  cheat_powerup[5].p := get_cheatseq_string(0);
  cheat_powerup[6].sequence := get_cheatseq_string(cheat_powerup_seq6);
  cheat_powerup[6].p := get_cheatseq_string(0);

  cheat_clev.sequence := get_cheatseq_string(cheat_clev_seq);
  cheat_clev.p := get_cheatseq_string(0);
  cheat_mypos.sequence := get_cheatseq_string(cheat_mypos_seq);
  cheat_mypos.p := get_cheatseq_string(0);

  st_palette := 0;

  st_stopped := true;
////////////////////////////////////////////////////////////////////////////////

  ST_LoadData;
  C_AddCmd('god, iddqd', @ST_CmdGod);
  C_AddCmd('massacre', @ST_CmdMassacre);
  C_AddCmd('givefullammo, rambo, idfa', @ST_CmdIDFA);
  C_AddCmd('giveallkeys, idkeys', @ST_CmdIDKEYS);
  C_AddCmd('lowgravity', @ST_CmdLowGravity);
  C_AddCmd('givefullammoandkeys, idkfa', @ST_CmdIDKFA);
  C_AddCmd('iddt', @ST_CmdIDDT);
  C_AddCmd('idspispopd, idclip', @ST_CmdIDNoClip);
  C_AddCmd('idmypos', @ST_CmdIDMyPos);
end;

end.
