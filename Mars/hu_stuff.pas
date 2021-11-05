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
//    Head up display
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit hu_stuff;

interface

uses
  doomdef,
  d_event,
  r_defs;

const
//
// Globally visible constants.
//
  HU_FONTSTART = '!'; // the first font characters
  HU_FONTEND = #127; // the last font characters

// Calculate # of glyphs in font.
  HU_FONTSIZE = (Ord(HU_FONTEND) - Ord(HU_FONTSTART)) + 1;

  HU_BROADCAST = 5;

  HU_MSGREFRESH = KEY_ENTER;
  HU_MSGX = 0;
  HU_MSGY = 0;
  HU_MSGHEIGHT = 1; // in lines

  HU_MSGTIMEOUT = 4 * TICRATE;

//
// HEADS UP TEXT
//
procedure HU_Init;

procedure HU_Start;

function HU_Responder(ev: Pevent_t): boolean;

procedure HU_Ticker;

procedure HU_Drawer;

{$IFDEF OPENGL}
function HU_Height: integer;
{$ENDIF}

function HU_dequeueChatChar: char;

procedure HU_Erase;

var
  hu_fontY: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Small Yellow Text
  hu_fontW: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Small White Text
  hu_fontB: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Small Black Text
  hu_fontR: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Small Red Text
  hu_fontG: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Small gray Text

  big_fontY: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Big Yellow Text
  big_fontW: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Big White Text
  big_fontB: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Big Black Text
  big_fontR: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Big Red Text
  big_fontG: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Big gray Text

  dos_fontG: array[0..HU_FONTSIZE - 1] of Ppatch_t; // Green DOS font
  dos_fontW: array[0..HU_FONTSIZE - 1] of Ppatch_t; // White DOS font

  mars_fontLG: array[0..HU_FONTSIZE - 1] of Ppatch_t; // Light Green MARS font
  mars_fontDG: array[0..HU_FONTSIZE - 1] of Ppatch_t; // Dark Green MARS font

  chat_on: boolean;

  message_on: boolean;
  message_dontfuckwithme: boolean;
  message_nottobefuckedwith: boolean;

const
  NUM_MAPNAMES = 45;
  NUM_MAPNAMES2 = 33;
  NUM_MAPNAMESP = 32;
  NUM_MAPNAMEST = 32;

var
// DOOM shareware/registered/retail (Ultimate) names.
  mapnames: array[0..NUM_MAPNAMES - 1] of string;

// DOOM 2 map names.
  mapnames2: array[0..NUM_MAPNAMES2 - 1] of string;

// Plutonia WAD map names.
  mapnamesp: array[0..NUM_MAPNAMESP - 1] of string;

// TNT WAD map names.
  mapnamest: array[0..NUM_MAPNAMEST - 1] of string;

  player_names: array[0..3] of string;

var
  chat_macros: array[0..9] of string;

var
  destination_keys: array[0..MAXPLAYERS - 1] of string;
    
var
  shiftxform: array[0..127] of char;

procedure HU_DoFPSStuff;

function HU_FPS: integer;

var
  drawfps: boolean;

implementation

uses
  d_delphi,
  c_cmds,
  z_zone,
  w_wad,
  i_system,
  doomstat,
  am_map,
  dstrings,
  d_englsh,
  d_player,
  g_game,
  hu_lib,
  m_menu,
  m_fixed,
  p_tick,
  r_draw,
  s_sound,
  sounds,
  v_data,
  v_video;

// FPS Stuff

const
  FPSSIZE = 128;
  FPSSIZE2 = 512;

var
  FPSHISTORY: array[0..FPSSIZE - 1] of integer;
  FPSHISTORY2: array[0..FPSSIZE2 - 1] of integer;
  fpshead: integer = -1;
  fpshead2: integer = -1;

procedure HU_DoFPSStuff;
var
  ftime: integer;
begin
  ftime := I_GetFracTime;
  fpshead := (fpshead + 1) mod FPSSIZE;
  FPSHISTORY[fpshead] := ftime;
  fpshead2 := (fpshead2 + 1) mod FPSSIZE2;
  FPSHISTORY2[fpshead2] := ftime;
end;

function HU_FPS: integer;
var
  fpsdiff: integer;
begin
  fpsdiff := FPSHISTORY[fpshead] - FPSHISTORY[(fpshead + 1) mod FPSSIZE] + 1;
  if fpsdiff > 0 then
  begin
    result :=  TICRATE * FPSSIZE * FRACUNIT div fpsdiff;
    if result > FPSSIZE then
    begin
      fpsdiff := FPSHISTORY2[fpshead2] - FPSHISTORY2[(fpshead2 + 1) mod FPSSIZE2] + 1;
      if fpsdiff > 0 then
        result :=  TICRATE * FPSSIZE2 * FRACUNIT div fpsdiff;
    end;
  end
  else
    result := TICRATE;
end;

procedure HU_CmdFPS;
begin
  printf('%d fps'#13#10, [HU_FPS]);
end;

procedure HU_CmdPlayerMessage(const parm1, parm2: string);
begin
  players[consoleplayer]._message := parm1 + ' ' + parm2;
end;

function HU_TITLE: string;
var
  x: integer;
begin
  x := (gameepisode - 1) * 9 + gamemap - 1;
  if IsIntegerInRange(x, 0, NUM_MAPNAMES - 1) then
    result := mapnames[x]
  else
    sprintf(result, 'Episode %d - Map %d', [gameepisode, gamemap]);
end;

function HU_TITLE2: string;
begin
  if IsIntegerInRange(gamemap, 1, NUM_MAPNAMES2) then
    result := mapnames2[gamemap - 1]
  else
    sprintf(result, 'Map %d', [gamemap]);
end;

function HU_TITLEP: string;
begin
  if IsIntegerInRange(gamemap, 1, NUM_MAPNAMESP) then
    result := mapnamesp[gamemap - 1]
  else
    sprintf(result, 'Map %d', [gamemap]);
end;

function HU_TITLET: string;
begin
  if IsIntegerInRange(gamemap, 1, NUM_MAPNAMEST) then
    result := mapnamest[gamemap - 1]
  else
    sprintf(result, 'Map %d', [gamemap]);
end;

var
  plr: Pplayer_t;
  w_title: hu_textline_t;
  w_leveltime: hu_textline_t;
  w_chat: hu_itext_t;
  always_off: boolean = false;
  chat_dest: array[0..MAXPLAYERS - 1] of char;
  w_inputbuffer: array[0..MAXPLAYERS - 1] of hu_itext_t;

  w_message: hu_stext_t;
  message_counter: integer;

  headsupactive: boolean = false;


const
  HU_TITLEHEIGHT = 1;
  HU_TITLEX = 0;
  HU_LEVELTIMEX = 0;

function HU_TITLEY: integer;
begin
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 167 div 200{$ELSE}167{$ENDIF} - hu_fontY[0].height;
end;

function HU_LEVELTIMEY: integer;
begin
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 167 div 200{$ELSE}167{$ENDIF} - 2 * hu_fontY[0].height;
end;

const
  HU_INPUTTOGGLE: char = 't';

function HU_INPUTX: integer;
begin
  result := HU_MSGX;
end;

function HU_INPUTY: integer;
begin
  result := HU_MSGY + HU_MSGHEIGHT * (hu_fontY[0].height + 1)
end;

const
  HU_INPUTWIDTH = 64;
  HU_INPUTHEIGHT = 1;

const
  french_shiftxform: array[0..127] of char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '?', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    '0', // shift-0
    '1', // shift-1
    '2', // shift-2
    '3', // shift-3
    '4', // shift-4
    '5', // shift-5
    '6', // shift-6
    '7', // shift-7
    '8', // shift-8
    '9', // shift-9
    '/',
    '.', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  english_shiftxform: array[0..127] of char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '<', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    ')', // shift-0
    '!', // shift-1
    '@', // shift-2
    '#', // shift-3
    '$', // shift-4
    '%', // shift-5
    '^', // shift-6
    '&', // shift-7
    '*', // shift-8
    '(', // shift-9
    ':',
    ':', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  frenchKeyMap: array[0..127] of char = (
    #0,
    #1,#2,#3,#4,#5,#6,#7,#8,#9,#10,
    #11,#12,#13,#14,#15,#16,#17,#18,#19,#20,
    #21,#22,#23,#24,#25,#26,#27,#28,#29,#30,
    #31,
    ' ','!','"','#','$','%','&','%','(',')','*','+',';','-',':','!',
    '0','1','2','3','4','5','6','7','8','9',':','M','<','=','>','?',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^','_',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^',#127
  );

function ForeignTranslation(ch: char): char;
begin
  if ch < #128 then
    result := frenchKeyMap[Ord(ch)]
  else
    result := ch;
end;

var
  tnt1a0_lump: Integer;

function HU_CacheLumpName(const name: string; const tag: integer): Ppatch_t;
var
  lump: integer;
begin
  lump := W_CheckNumForName(name);
  if lump < 0 then
    Result := W_CacheLumpNum(tnt1a0_lump, tag)
  else
    Result := W_CacheLumpNum(lump, tag);
end;

procedure HU_Init;
var
  i: integer;
  j: integer;
  buffer: string;
  lump: integer;
begin
  if language = french then
  begin
    for i := 0 to 127 do
      shiftxform[i] := french_shiftxform[i];
  end
  else
  begin
    for i := 0 to 127 do
      shiftxform[i] := english_shiftxform[i];
  end;

  tnt1a0_lump := W_GetNumForName('TNT1A0');

  // load the heads-up font
  j := Ord(HU_FONTSTART);
  for i := 0 to HU_FONTSIZE - 1 do
  begin
    buffer := IntToStrZfill(3, j);
    inc(j);

    hu_fontY[i] := HU_CacheLumpName('SFNTA' + buffer, PU_STATIC);
    hu_fontW[i] := HU_CacheLumpName('SFNTB' + buffer, PU_STATIC);
    hu_fontB[i] := HU_CacheLumpName('SFNTC' + buffer, PU_STATIC);
    hu_fontR[i] := HU_CacheLumpName('SFNTD' + buffer, PU_STATIC);
    hu_fontG[i] := HU_CacheLumpName('SFNTE' + buffer, PU_STATIC);

    big_fontY[i] := HU_CacheLumpName('BFNTA' + buffer, PU_STATIC);
    big_fontW[i] := HU_CacheLumpName('BFNTB' + buffer, PU_STATIC);
    big_fontB[i] := HU_CacheLumpName('BFNTC' + buffer, PU_STATIC);
    big_fontR[i] := HU_CacheLumpName('BFNTD' + buffer, PU_STATIC);
    big_fontG[i] := HU_CacheLumpName('BFNTE' + buffer, PU_STATIC);

    dos_fontG[i] := HU_CacheLumpName('DFNTA' + buffer, PU_STATIC);
    dos_fontW[i] := HU_CacheLumpName('DFNTB' + buffer, PU_STATIC);

    mars_fontLG[i] := HU_CacheLumpName('MFNTA' + buffer, PU_STATIC);
    mars_fontDG[i] := HU_CacheLumpName('MFNTB' + buffer, PU_STATIC);
  end;

  for i := 0 to FPSSIZE - 1 do
    FPSHISTORY[i] := 0;

  for i := 0 to FPSSIZE2 - 1 do
    FPSHISTORY2[i] := 0;

  C_AddCmd('fps', @HU_CmdFPS);
  C_AddCmd('playermessage', @HU_CmdPlayerMessage);
end;

procedure HU_Stop;
begin
  headsupactive := false;
end;

procedure HU_Start;
var
  i: integer;
  s: string;
begin
  if headsupactive then
    HU_Stop;

  plr := @players[consoleplayer];
  message_on := false;
  message_dontfuckwithme := false;
  message_nottobefuckedwith := false;
  chat_on := false;

  // create the message widget
  HUlib_initSText(@w_message,
    HU_MSGX, HU_MSGY, HU_MSGHEIGHT,
    @hu_fontG,
    Ord(HU_FONTSTART), @message_on);

  // create the map title widget
  HUlib_initTextLine(@w_title,
    HU_TITLEX, HU_TITLEY,
    @hu_fontG,
    Ord(HU_FONTSTART));

  HUlib_initTextLine(@w_leveltime,
    HU_LEVELTIMEX, HU_LEVELTIMEY,
    @hu_fontG,
    Ord(HU_FONTSTART));

  case gamemode of
    shareware,
    registered,
    retail: s := HU_TITLE;
  else
    begin
      case gamemission of
        pack_tnt: s := HU_TITLET;
        pack_plutonia: s := HU_TITLEP;
      else
        s := HU_TITLE2;
      end;
    end;
  end;

  for i := 1 to Length(s) do
    HUlib_addCharToTextLine(@w_title, s[i]);

  // create the chat widget
  HUlib_initIText(@w_chat,
    HU_INPUTX, HU_INPUTY,
    @hu_fontG,
    Ord(HU_FONTSTART), @chat_on);

  // create the inputbuffer widgets
  for i := 0 to MAXPLAYERS - 1 do
    HUlib_initIText(@w_inputbuffer[i], 0, 0, nil, 0, @always_off);

  headsupactive := true;
end;

{$IFDEF OPENGL}
var
  hu_h: integer = 0;

function HU_Height: integer;
begin
  result := hu_h;
end;
{$ENDIF}

var
  m_fps: string = '';
  fps_ticker: integer = 0;

procedure HU_DrawFPS;
var
  i: integer;
  x, y: integer;
  c: integer;
begin
{$IFDEF OPENGL}
  x := V_GetScreenWidth(SCN_FG) - 9;
  y := 1;
  for i := length(m_fps) downto 1 do
  begin
    if m_fps[i] <> ' ' then
    begin
      c := Ord(toupper(m_fps[i])) - Ord(HU_FONTSTART);
      V_DrawPatch(x, y, SCN_FG, hu_fontG[c], false);
      x := x - 8;
    end
    else
      x := x - 4;
  end;
  hu_h := hu_h + 9;
{$ELSE}
  if amstate = am_only then
  begin
    x := 311;
    y := 1;
  end
  else
  begin
    x := (viewwindowx + viewwidth) * 320 div SCREENWIDTH - 9;
    y := viewwindowy * 200 div SCREENHEIGHT + 1;
  end;
  for i := length(m_fps) downto 1 do
  begin
    if m_fps[i] <> ' ' then
    begin
      c := Ord(toupper(m_fps[i])) - Ord(HU_FONTSTART);
      V_DrawPatch(x, y, SCN_FG, hu_fontG[c], true);
      x := x - 8;
    end
    else
      x := x - 4;
  end;
{$ENDIF}  
end;

// 19/9/2009 JVAL: For drawing demo progress
procedure HU_DrawDemoProgress;
var
  dp: Ppatch_t;
  i: integer;
  x, y: integer;
begin
  dp := W_CacheLumpName('DEMOTIME', PU_STATIC);
  x := viewwindowx{$IFDEF OPENGL} * 320 div SCREENWIDTH{$ENDIF};
  y := (viewwindowy + viewheight){$IFDEF OPENGL} * 200 div SCREENHEIGHT{$ENDIF};
{$IFDEF OPENGL}
  i := round(G_DemoProgress * viewwidth / SCREENWIDTH * 320 / FRACUNIT);
{$ELSE}
  i := G_DemoProgress * viewwidth div FRACUNIT;
{$ENDIF}  
  while i > 0 do
  begin
    V_DrawPatchTransparent(x, y, SCN_FG, dp, {$IFDEF OPENGL}true{$ELSE}false{$ENDIF});
    i := i - dp.width;
    x := x + dp.width;
  end;
  Z_ChangeTag(dp, PU_CACHE);
end;

procedure HU_Drawer;
var
  i, t: integer;
{$IFDEF OPENGL}
  i2, idx, lines: integer;
{$ENDIF}
  lt: string;
begin
{$IFDEF OPENGL}
  hu_h := 0;
{$ENDIF}
  if drawfps then
    HU_DrawFPS;
  if demoplayback and showdemoplaybackprogress then
    HU_DrawDemoProgress;

  HUlib_drawSText(@w_message);
  {$IFDEF OPENGL}
  if w_message._on^ then
    for i := 0 to w_message.height - 1 do
    begin
      idx := w_message.curline - i;
      if idx < 0 then
        idx := idx + w_message.height; // handle queue of lines
      lines := 0;
      for i2 := 0 to w_message.lines[idx].len - 1 do
        if w_message.lines[idx].line[i2] = #10 then
          inc(lines);
      if lines * 10 > hu_h then
        hu_h := lines * 10;
    end;
  {$ENDIF}
  HUlib_drawIText(@w_chat);
  if amstate = am_only then
  begin
    repeat
    until not HUlib_delCharFromTextLine(@w_leveltime);
    t := leveltime div TICRATE;
    lt := IntToStrZFill(2, t mod 60);
    t := t div 60;
    lt := IntToStrZFill(2, t mod 60) + ':' + lt;
    t := t div 60;
    lt := 'Time: ' + IntToStrZFill(2, t) + ':' + lt;

    for i := 1 to Length(lt) do
      HUlib_addCharToTextLine(@w_leveltime, lt[i]);
    HUlib_drawTextLine(@w_leveltime, false);
    HUlib_drawTextLine(@w_title, false);
  end;
end;

procedure HU_Erase;
begin
  HUlib_eraseSText(@w_message);
  HUlib_eraseIText(@w_chat);
  HUlib_eraseTextLine(@w_title);
end;

procedure HU_Ticker;
var
  i: integer;
  rc: boolean;
  c: char;
begin
  dec(fps_ticker);
  if fps_ticker <= 0 then
  begin
    m_fps := itoa(HU_FPS) + ' fps';
    fps_ticker := TICRATE div 2;
  end;

  // tick down message counter if message is up
  if message_counter <> 0 then
  begin
    dec(message_counter);
    if message_counter = 0 then
    begin
      HUlib_removeLineFromSText(@w_message);
      message_on := w_message.lines[w_message.curline].len > 0;
      if message_on then
        message_counter := HU_MSGTIMEOUT;
      message_nottobefuckedwith := false;
    end;
  end;

  if (showMessages <> 0) or message_dontfuckwithme then
  begin
    // display message if necessary
    if plr <> nil then
      if ((plr._message <> '') and not message_nottobefuckedwith) or
         ((plr._message <> '') and message_dontfuckwithme) then
      begin
        HUlib_addMessageToSText2(@w_message, '', plr._message);
        plr._message := '';
        message_on := true;
        message_counter := HU_MSGTIMEOUT;
        message_nottobefuckedwith := message_dontfuckwithme;
        message_dontfuckwithme := false;
      end;
  end; // else message_on = false;

  // check for incoming chat characters
  if netgame then
  begin
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if not playeringame[i] then
        continue;
      c := Chr(players[i].cmd.chatchar);
      if (i <> consoleplayer) and (c <> #0) then
      begin
        if c <= Chr(HU_BROADCAST) then
          chat_dest[i] := c
        else
        begin
          if (c >= 'a') and (c <= 'z') then
            c := shiftxform[Ord(c)];
          rc := HUlib_keyInIText(@w_inputbuffer[i], Ord(c));
          if rc and (Ord(c) = KEY_ENTER) then
          begin
            if (w_inputbuffer[i].line.len <> 0) and
               ((Ord(chat_dest[i]) = consoleplayer + 1) or (Ord(chat_dest[i]) = HU_BROADCAST)) then
            begin
              HUlib_addMessageToSText(@w_message,
                player_names[i],
                w_inputbuffer[i].line.line);

              message_nottobefuckedwith := true;
              message_on := true;
              message_counter := HU_MSGTIMEOUT;
              if gamemode = commercial then
                S_StartSound(nil, Ord(sfx_radio))
              else
                S_StartSound(nil, Ord(sfx_tink));
            end;
            HUlib_resetIText(@w_inputbuffer[i]);
          end;
        end;
        players[i].cmd.chatchar := 0;
      end;
    end;
  end;
end;

const
  QUEUESIZE = 128;

var
  chatchars: array[0..QUEUESIZE - 1] of char;
  head: integer = 0;
  tail: integer = 0;

procedure HU_queueChatChar(c: char);
begin
  if ((head + 1) and (QUEUESIZE - 1)) = tail then
    plr._message := HUSTR_MSGU
  else
  begin
    chatchars[head] := c;
    head := (head + 1) and (QUEUESIZE - 1);
  end;
end;

function HU_dequeueChatChar: char;
begin
  if head <> tail then
  begin
    result := chatchars[tail];
    tail := (tail + 1) and (QUEUESIZE - 1);
  end
  else
    result := #0;
end;

var
  lastmessage: string;
  shiftdown: boolean = false;
  altdown: boolean = false;
  num_nobrainers: integer = 0;

function HU_Responder(ev: Pevent_t): boolean;
var
  macromessage: string;
  c: char;
  i: integer;
  numplayers: integer;
begin
  result := false;

  if ev.data1 = KEY_RSHIFT then
  begin
    shiftdown := ev._type = ev_keydown;
    exit;
  end
  else if (ev.data1 = KEY_RALT) or (ev.data1 = KEY_LALT) then
  begin
    altdown := ev._type = ev_keydown;
    exit;
  end;

  if ev._type <> ev_keydown then
    exit;

  numplayers := 0;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      inc(numplayers);

  if not chat_on then
  begin
    if ev.data1 = HU_MSGREFRESH then
    begin
      message_on := true;
      message_counter := HU_MSGTIMEOUT;
      result := true;
    end
    else if netgame and (ev.data1 = Ord(HU_INPUTTOGGLE)) then
    begin
      result := true;
      chat_on := true;
      HUlib_resetIText(@w_chat);
      HU_queueChatChar(Chr(HU_BROADCAST));
    end
    else if netgame and (numplayers > 2) then
    begin
      for i := 0 to MAXPLAYERS - 1 do
      begin
        if destination_keys[i] <> '' then
        begin
          if ev.data1 = Ord(destination_keys[i][1]) then
          begin
            if playeringame[i] and (i <> consoleplayer) then
            begin
              result := true;
              chat_on := true;
              HUlib_resetIText(@w_chat);
              HU_queueChatChar(Chr(i + 1));
              break;
            end
            else if i = consoleplayer then
            begin
              inc(num_nobrainers);
              if num_nobrainers < 3 then
                plr._message := HUSTR_TALKTOSELF1
              else if num_nobrainers < 6 then
                plr._message := HUSTR_TALKTOSELF2
              else if num_nobrainers < 9 then
                plr._message := HUSTR_TALKTOSELF3
              else if num_nobrainers < 32 then
                plr._message := HUSTR_TALKTOSELF4
              else
                plr._message := HUSTR_TALKTOSELF5;
            end
          end;
        end;
      end;
    end;
  end
  else
  begin
    c := Chr(ev.data1);
    // send a macro
    if altdown then
    begin
      c := Chr(Ord(c) - Ord('0'));
      if c > Chr(9) then
        exit;
      macromessage := chat_macros[Ord(c)];

      // kill last message with a '\n'
      HU_queueChatChar(Chr(KEY_ENTER)); // DEBUG!!!

      // send the macro message
      for i := 1 to Length(macromessage) do
        HU_queueChatChar(macromessage[i]);
      HU_queueChatChar(Chr(KEY_ENTER));

      // leave chat mode and notify that it was sent
      chat_on := false;
      lastmessage := chat_macros[Ord(c)];
      plr._message := lastmessage;
      result := true;
    end
    else
    begin
      if language = french then
        c := ForeignTranslation(c);
      if shiftdown or ((c >= 'a') and (c <= 'z')) then
        c := shiftxform[Ord(c)];
      result := HUlib_keyInIText(@w_chat, Ord(c));
      if result then
        HU_queueChatChar(c);
      if Ord(c) = KEY_ENTER then
      begin
        chat_on := false;
        if w_chat.line.len <> 0 then
        begin
          lastmessage := w_chat.line.line;
          plr._message := lastmessage;
        end
      end
      else if Ord(c) = KEY_ESCAPE then
        chat_on := false;
    end;
  end;
end;

initialization
  chat_macros[0] := HUSTR_CHATMACRO0;
  chat_macros[1] := HUSTR_CHATMACRO1;
  chat_macros[2] := HUSTR_CHATMACRO2;
  chat_macros[3] := HUSTR_CHATMACRO3;
  chat_macros[4] := HUSTR_CHATMACRO4;
  chat_macros[5] := HUSTR_CHATMACRO5;
  chat_macros[6] := HUSTR_CHATMACRO6;
  chat_macros[7] := HUSTR_CHATMACRO7;
  chat_macros[8] := HUSTR_CHATMACRO8;
  chat_macros[9] := HUSTR_CHATMACRO9;

  player_names[0] := HUSTR_PLRGREEN;
  player_names[1] := HUSTR_PLRINDIGO;
  player_names[2] := HUSTR_PLRBROWN;
  player_names[3] := HUSTR_PLRRED;

////////////////////////////////////////////////////////////////////////////////
//
// Builtin map names.
// The actual names can be found in DStrings.h.
//
////////////////////////////////////////////////////////////////////////////////

// DOOM shareware/registered/retail (Ultimate) names.

  mapnames[0] := HUSTR_E1M1;
  mapnames[1] := HUSTR_E1M2;
  mapnames[2] := HUSTR_E1M3;
  mapnames[3] := HUSTR_E1M4;
  mapnames[4] := HUSTR_E1M5;
  mapnames[5] := HUSTR_E1M6;
  mapnames[6] := HUSTR_E1M7;
  mapnames[7] := HUSTR_E1M8;
  mapnames[8] := HUSTR_E1M9;

  mapnames[9] := HUSTR_E2M1;
  mapnames[10] := HUSTR_E2M2;
  mapnames[11] := HUSTR_E2M3;
  mapnames[12] := HUSTR_E2M4;
  mapnames[13] := HUSTR_E2M5;
  mapnames[14] := HUSTR_E2M6;
  mapnames[15] := HUSTR_E2M7;
  mapnames[16] := HUSTR_E2M8;
  mapnames[17] := HUSTR_E2M9;

  mapnames[18] := HUSTR_E3M1;
  mapnames[19] := HUSTR_E3M2;
  mapnames[20] := HUSTR_E3M3;
  mapnames[21] := HUSTR_E3M4;
  mapnames[22] := HUSTR_E3M5;
  mapnames[23] := HUSTR_E3M6;
  mapnames[24] := HUSTR_E3M7;
  mapnames[25] := HUSTR_E3M8;
  mapnames[26] := HUSTR_E3M9;

  mapnames[27] := HUSTR_E4M1;
  mapnames[28] := HUSTR_E4M2;
  mapnames[29] := HUSTR_E4M3;
  mapnames[30] := HUSTR_E4M4;
  mapnames[31] := HUSTR_E4M5;
  mapnames[32] := HUSTR_E4M6;
  mapnames[33] := HUSTR_E4M7;
  mapnames[34] := HUSTR_E4M8;
  mapnames[35] := HUSTR_E4M9;

  mapnames[36] := 'NEWLEVEL';
  mapnames[37] := mapnames[36];
  mapnames[38] := mapnames[36];
  mapnames[39] := mapnames[36];
  mapnames[40] := mapnames[36];
  mapnames[41] := mapnames[36];
  mapnames[42] := mapnames[36];
  mapnames[43] := mapnames[36];
  mapnames[44] := mapnames[36];

////////////////////////////////////////////////////////////////////////////////

// DOOM 2 map names.

  mapnames2[0] := HUSTR_1;
  mapnames2[1] := HUSTR_2;
  mapnames2[2] := HUSTR_3;
  mapnames2[3] := HUSTR_4;
  mapnames2[4] := HUSTR_5;
  mapnames2[5] := HUSTR_6;
  mapnames2[6] := HUSTR_7;
  mapnames2[7] := HUSTR_8;
  mapnames2[8] := HUSTR_9;
  mapnames2[9] := HUSTR_10;
  mapnames2[10] := HUSTR_11;

  mapnames2[11] := HUSTR_12;
  mapnames2[12] := HUSTR_13;
  mapnames2[13] := HUSTR_14;
  mapnames2[14] := HUSTR_15;
  mapnames2[15] := HUSTR_16;
  mapnames2[16] := HUSTR_17;
  mapnames2[17] := HUSTR_18;
  mapnames2[18] := HUSTR_19;
  mapnames2[19] := HUSTR_20;

  mapnames2[20] := HUSTR_21;
  mapnames2[21] := HUSTR_22;
  mapnames2[22] := HUSTR_23;
  mapnames2[23] := HUSTR_24;
  mapnames2[24] := HUSTR_25;
  mapnames2[25] := HUSTR_26;
  mapnames2[26] := HUSTR_27;
  mapnames2[27] := HUSTR_28;
  mapnames2[28] := HUSTR_29;
  mapnames2[29] := HUSTR_30;
  mapnames2[30] := HUSTR_31;
  mapnames2[31] := HUSTR_32;
  mapnames2[32] := HUSTR_33;

////////////////////////////////////////////////////////////////////////////////

// Plutonia WAD map names.

  mapnamesp[0] := PHUSTR_1;
  mapnamesp[1] := PHUSTR_2;
  mapnamesp[2] := PHUSTR_3;
  mapnamesp[3] := PHUSTR_4;
  mapnamesp[4] := PHUSTR_5;
  mapnamesp[5] := PHUSTR_6;
  mapnamesp[6] := PHUSTR_7;
  mapnamesp[7] := PHUSTR_8;
  mapnamesp[8] := PHUSTR_9;
  mapnamesp[9] := PHUSTR_10;
  mapnamesp[10] := PHUSTR_11;

  mapnamesp[11] := PHUSTR_12;
  mapnamesp[12] := PHUSTR_13;
  mapnamesp[13] := PHUSTR_14;
  mapnamesp[14] := PHUSTR_15;
  mapnamesp[15] := PHUSTR_16;
  mapnamesp[16] := PHUSTR_17;
  mapnamesp[17] := PHUSTR_18;
  mapnamesp[18] := PHUSTR_19;
  mapnamesp[19] := PHUSTR_20;

  mapnamesp[20] := PHUSTR_21;
  mapnamesp[21] := PHUSTR_22;
  mapnamesp[22] := PHUSTR_23;
  mapnamesp[23] := PHUSTR_24;
  mapnamesp[24] := PHUSTR_25;
  mapnamesp[25] := PHUSTR_26;
  mapnamesp[26] := PHUSTR_27;
  mapnamesp[27] := PHUSTR_28;
  mapnamesp[28] := PHUSTR_29;
  mapnamesp[29] := PHUSTR_30;
  mapnamesp[30] := PHUSTR_31;
  mapnamesp[31] := PHUSTR_32;

////////////////////////////////////////////////////////////////////////////////

// TNT WAD map names.

  mapnamest[0] := THUSTR_1;
  mapnamest[1] := THUSTR_2;
  mapnamest[2] := THUSTR_3;
  mapnamest[3] := THUSTR_4;
  mapnamest[4] := THUSTR_5;
  mapnamest[5] := THUSTR_6;
  mapnamest[6] := THUSTR_7;
  mapnamest[7] := THUSTR_8;
  mapnamest[8] := THUSTR_9;
  mapnamest[9] := THUSTR_10;
  mapnamest[10] := THUSTR_11;

  mapnamest[11] := THUSTR_12;
  mapnamest[12] := THUSTR_13;
  mapnamest[13] := THUSTR_14;
  mapnamest[14] := THUSTR_15;
  mapnamest[15] := THUSTR_16;
  mapnamest[16] := THUSTR_17;
  mapnamest[17] := THUSTR_18;
  mapnamest[18] := THUSTR_19;
  mapnamest[19] := THUSTR_20;

  mapnamest[20] := THUSTR_21;
  mapnamest[21] := THUSTR_22;
  mapnamest[22] := THUSTR_23;
  mapnamest[23] := THUSTR_24;
  mapnamest[24] := THUSTR_25;
  mapnamest[25] := THUSTR_26;
  mapnamest[26] := THUSTR_27;
  mapnamest[27] := THUSTR_28;
  mapnamest[28] := THUSTR_29;
  mapnamest[29] := THUSTR_30;
  mapnamest[30] := THUSTR_31;
  mapnamest[31] := THUSTR_32;

////////////////////////////////////////////////////////////////////////////////

  destination_keys[0] := HUSTR_KEYGREEN;
  destination_keys[1] := HUSTR_KEYINDIGO;
  destination_keys[2] := HUSTR_KEYBROWN;
  destination_keys[3] := HUSTR_KEYRED;

end.

