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
//  Printed strings for translation. 
//  English language support (default). 
// 
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit d_englsh;

interface

//
//  Printed strings for translation
//

//
// D_Main.C
//

var
  D_DEVSTR: string =
    'Development mode ON.' + #13#10;
  D_CDROM: string =
    'CD-ROM Version: Mars3D.ini from c:\marsdata' + #13#10;

//
//  M_Menu.C
//
  PRESSKEY: string =
    'press a key.';
  PRESSYN: string =
    'press y or n.';

  QUITMSG: string =
    'are you sure you want to' + #13#10 +
    'quit this great game?';

  LOADNET: string =
    'you can''t do load while in a net game!' + #13#10;

  QLOADNET: string =
    'you can''t quickload during a netgame!' + #13#10;

  QSAVESPOT: string =
    'you haven''t picked a quicksave slot yet!' + #13#10;

  SAVEDEAD: string =
    'you can''t save if you aren''t playing!' + #13#10;

  QSPROMPT: string =
    'quicksave over your game named' + #13#10 + #13#10 +
    '''%s''?' + #13#10;

  QLPROMPT: string =
    'do you want to quickload the game named' + #13#10 + #13#10 +
    '''%s''?' + #13#10;

  SNEWGAME: string =
    'you can''t start a new game' + #13#10 +
    'while in a network game.' + #13#10;

  SNIGHTMARE: string =
    'are you sure? this skill level' + #13#10 +
    'isn''t even remotely fair.';

  SWSTRING: string =
    'this is the shareware version of doom.' + #13#10 +
    'you need to order the entire trilogy.';

  MSGOFF: string =
    'Messages OFF';
  MSGON: string =
    'Messages ON';

  NETEND: string =
    'you can''t end a netgame!' + #13#10;
  SENDGAME : string =
    'are you sure you want to end the game?' + #13#10;

  DOSY: string =
    '(press y to quit)';

var
  DETAILULTRA: string = 'Ultra detail';
  DETAILHI: string = 'High detail';
  DETAILNORM: string = 'Normal detail';
  DETAILMED: string = 'Medium detail';
  DETAILLOW: string = 'Low detail';
  DETAILLOWEST: string = 'Lowest detail';
  GAMMALVL0: string = 'Gamma correction OFF';
  GAMMALVL1: string = 'Gamma correction level 1';
  GAMMALVL2: string = 'Gamma correction level 2';
  GAMMALVL3: string = 'Gamma correction level 3';
  GAMMALVL4: string = 'Gamma correction level 4';

//
//  P_inter.C
//
var
  GOTARMOR: string = 'Picked up the armor shield.';
  GOTMEGA: string = 'Picked up the bulletproof vest!';
  GOTARMBONUS: string = 'Picked up an armor bonus.';
  GOTSUPER: string = 'Supercharge!';

  GOTBLUECARD: string = 'Blue keycard.';
  GOTYELWCARD: string = 'Gold keycard.';
  GOTREDCARD: string = 'Red keycard.';
  GOTBLUESKUL: string = 'Picked up a blue skull key.';
  GOTYELWSKUL: string = 'Picked up a yellow skull key.';
  GOTREDSKULL: string = 'Picked up a red skull key.';

  GOTINVUL: string = 'Invulnerability!';
  GOTBERSERK: string = 'Berserk!';
  GOTINVIS: string = 'Partial Invisibility';
  GOTSUIT: string = 'Radiation Shielding Suit';
  GOTMAP: string = 'Computer Area Map';
  GOTJETPACK: string = 'Jet pack';
  GOTVISOR: string = 'Light Amplification Visor';
  GOTMSPHERE: string = 'MegaSphere!';

  // Weapons
  GOTWEAPON1: string = 'Pistol';
  GOTWEAPON2: string = 'Shock gun';
  GOTWEAPON3: string = 'Nerve gun';
  GOTWEAPON4: string = 'Freeze gun';
  GOTWEAPON5: string = 'Flame gun';
  GOTWEAPON6: string = 'Grenade launcher';
  GOTWEAPON7: string = 'Boomerang gun';
  GOTWEAPON8: string = 'Missile launcher';
  GOTWEAPON9: string = 'Tracking Missile launcher';

  // Ammo
  GOTBULLETS: string = 'Pistol Clip';
  GOTTRACKINGMISSILES: string = 'Tracking Missiles';
  GOTMISSILESBOX: string = 'Box of Missiles';
  GOTBOXOFBULLETS: string = 'Box of bullets';
  GOTGRENADES: string = 'Grenades';
  GOTDISK: string = 'Boomerang disk';
  GOTDISKS: string = 'Box of boomerang disks';
  RETURNDISK: string = 'Boomerang disk returned!';
  GOTFREEZEGUNAMMO: string = 'Freeze gun ammo';
  GOTSCHOCKGUNAMMO: string = 'Shock gun ammo';

  // Health
  GOTHEALTH15: string = 'Got the Medkit pack';
  GOTHEALTH25: string = 'Got the Medkit potion';
  GOTHEALTH200: string = 'Got the Tianshan Ganoderma';

  MSGSECRETSECTOR: string = 'You found a secret area.';

//
// P_Doors.C
//
var
  PD_BLUEO: string = 'You need a blue key to activate this object';
  PD_REDO: string = 'You need a red key to activate this object';
  PD_YELLOWO: string = 'You need a gold key to activate this object';
  PD_BLUEK: string = 'You need a blue key to open this door';
  PD_REDK: string = 'You need a red key to open this door';
  PD_YELLOWK: string = 'You need a gold key to open this door';
//jff 02/05/98 Create messages specific to card and skull keys
  PD_BLUEC: string = 'You need a blue card to open this door';
  PD_REDC: string = 'You need a red card to open this door';
  PD_YELLOWC: string = 'You need a gold card to open this door';
  PD_BLUES: string = 'You need a blue skull to open this door';
  PD_REDS: string = 'You need a red skull to open this door';
  PD_YELLOWS: string = 'You need a gold skull to open this door';
  PD_ANY: string = 'Any key will open this door';
  PD_ALL3: string = 'You need all three keys to open this door';
  PD_ALL6: string = 'You need all six keys to open this door';

//
// G_game.C
//
var
  GGSAVED: string = 'game saved.';

const
//
//  HU_stuff.C
//

  HUSTR_E1M1 = 'E1M1: Resistance';
  HUSTR_E1M2 = 'E1M2: Enviroment Control';
  HUSTR_E1M3 = 'E1M3: Base City';
  HUSTR_E1M4 = 'E1M4: Conspiracy';
  HUSTR_E1M5 = 'E1M5: Back to the past';
  HUSTR_E1M6 = 'E1M6: Zaker';
  HUSTR_E1M7 = 'E1M7: Skynet City';
  HUSTR_E1M8 = 'Episode 1 - Mission 8';
  HUSTR_E1M9 = 'Episode 1 - Mission 9';

  HUSTR_E2M1 = 'Episode 2 - Mission 1';
  HUSTR_E2M2 = 'Episode 2 - Mission 2';
  HUSTR_E2M3 = 'Episode 2 - Mission 3';
  HUSTR_E2M4 = 'Episode 2 - Mission 4';
  HUSTR_E2M5 = 'Episode 2 - Mission 5';
  HUSTR_E2M6 = 'Episode 2 - Mission 6';
  HUSTR_E2M7 = 'Episode 2 - Mission 7';
  HUSTR_E2M8 = 'Episode 2 - Mission 8';
  HUSTR_E2M9 = 'Episode 2 - Mission 9';

  HUSTR_E3M1 = 'Episode 3 - Mission 1';
  HUSTR_E3M2 = 'Episode 3 - Mission 2';
  HUSTR_E3M3 = 'Episode 3 - Mission 3';
  HUSTR_E3M4 = 'Episode 3 - Mission 4';
  HUSTR_E3M5 = 'Episode 3 - Mission 5';
  HUSTR_E3M6 = 'Episode 3 - Mission 6';
  HUSTR_E3M7 = 'Episode 3 - Mission 7';
  HUSTR_E3M8 = 'Episode 3 - Mission 8';
  HUSTR_E3M9 = 'Episode 3 - Mission 9';

  HUSTR_E4M1 = 'Episode 4 - Mission 1';
  HUSTR_E4M2 = 'Episode 4 - Mission 2';
  HUSTR_E4M3 = 'Episode 4 - Mission 3';
  HUSTR_E4M4 = 'Episode 4 - Mission 4';
  HUSTR_E4M5 = 'Episode 4 - Mission 5';
  HUSTR_E4M6 = 'Episode 4 - Mission 6';
  HUSTR_E4M7 = 'Episode 4 - Mission 7';
  HUSTR_E4M8 = 'Episode 4 - Mission 8';
  HUSTR_E4M9 = 'Episode 4 - Mission 9';

  HUSTR_CHATMACRO1 = 'I''m ready to kick butt!';
  HUSTR_CHATMACRO2 = 'I''m OK.';
  HUSTR_CHATMACRO3 = 'I''m not looking too good!';
  HUSTR_CHATMACRO4 = 'Help!';
  HUSTR_CHATMACRO5 = 'You suck!';
  HUSTR_CHATMACRO6 = 'Next time, scumbag...';
  HUSTR_CHATMACRO7 = 'Come here!';
  HUSTR_CHATMACRO8 = 'I''ll take care of it.';
  HUSTR_CHATMACRO9 = 'Yes';
  HUSTR_CHATMACRO0 = 'No';

var
  HUSTR_TALKTOSELF1: string = 'You mumble to yourself';
  HUSTR_TALKTOSELF2: string = 'Who''s there?';
  HUSTR_TALKTOSELF3: string = 'You scare yourself';
  HUSTR_TALKTOSELF4: string = 'You start to rave';
  HUSTR_TALKTOSELF5: string = 'You''ve lost it...';

  HUSTR_MESSAGESENT: string = '[Message Sent]';
  HUSTR_MSGU: string = '[Message unsent]';

  { The following should NOT be changed unless it seems }
  { just AWFULLY necessary }
  HUSTR_PLRGREEN: string = 'Green:';
  HUSTR_PLRINDIGO: string = 'Indigo:';
  HUSTR_PLRBROWN: string = 'Brown:';
  HUSTR_PLRRED: string = 'Red:';

  HUSTR_KEYGREEN: string = 'g';
  HUSTR_KEYINDIGO: string = 'i';
  HUSTR_KEYBROWN: string = 'b';
  HUSTR_KEYRED: string = 'r';

//
//  AM_map.C
//
  AMSTR_FOLLOWON: string = 'Follow Mode ON';
  AMSTR_FOLLOWOFF: string = 'Follow Mode OFF';
  AMSTR_GRIDON: string = 'Grid ON';
  AMSTR_GRIDOFF: string = 'Grid OFF';
  AMSTR_ROTATEON: string = 'Rotate ON';
  AMSTR_ROTATEOFF: string = 'Rotate OFF';
  AMSTR_MARKEDSPOT: string = 'Marked Spot';
  AMSTR_MARKSCLEARED: string = 'All Marks Cleared';

//
//  ST_stuff.C
//
  STSTR_MUS: string = 'Music Change';
  STSTR_NOMUS: string = 'IMPOSSIBLE SELECTION';
  STSTR_DQDON: string = 'Degreelessness Mode On';
  STSTR_DQDOFF: string = 'Degreelessness Mode Off';
  STSTR_LGON: string = 'Low Gravity Mode On';
  STSTR_LGOFF: string = 'Low Gravity Mode Off';

  STSTR_KEYSADDED: string = 'Keys Added';
  STSTR_KFAADDED: string = 'Very Happy Ammo Added';
  STSTR_FAADDED: string = 'Ammo (no keys) Added';

  STSTR_NCON: string = 'No Clipping Mode ON';
  STSTR_NCOFF: string = 'No Clipping Mode OFF';

  STSTR_BEHOLD: string = 'inVuln, Str, Inviso, Rad, Allmap, or Lite-amp';
  STSTR_BEHOLDX: string = 'Power-up Toggled';

  STSTR_CLEV: string = 'Changing Level...';

  STSTR_WLEV: string = 'Level specified not found';

  STSTR_MASSACRE: string = 'Massacre';

const
  CC_HERO = 'OUR HERO';

var
  MSG_MODIFIEDGAME: string =
      '===========================================================================' + #13#10 +
      '            ATTENTION:  This version of MARS has been modified.            ' + #13#10 +
      '                      Press enter to continue' + #13#10 +
      '===========================================================================' + #13#10;

  MSG_SHAREWARE: string =
      '===========================================================================' + #13#10 +
      '                                Shareware                                  ' + #13#10 +
      '===========================================================================' + #13#10;

  MSG_COMMERCIAL: string =
      '===========================================================================' + #13#10 +
      '                                Commercial                                 ' + #13#10 +
      '===========================================================================' + #13#10;

  MSG_UNDETERMINED: string =
        '===========================================================================' + #13#10 +
        '                       Undetermined version! (Ouch)' + #13#10 +
        '===========================================================================' + #13#10;


implementation

end.

