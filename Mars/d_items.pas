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
//  Items: key cards, artifacts, weapon, ammunition.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit d_items;

interface

uses
  doomdef,
  info_h;

type
  { Weapon info: sprite frames, ammunition use. }
  weaponinfo_t = record
    ammo: ammotype_t;
    upstate: integer;
    downstate: integer;
    readystate: integer;
    atkstate: integer;
    holdatkstate: integer;
    flashstate: integer;
    flags: integer;
  end;
  Pweaponinfo_t = ^weaponinfo_t;

const
  WF_WEAPON = 1;
  WF_DEMOAVAILABLE = 2;
  WF_SEQUENCE = 4;

//
// PSPRITE ACTIONS for weapons.
// This struct controls the weapon animations.
//
// Each entry is:
//   ammo/amunition type
//   upstate
//   downstate
//   readystate
//   atkstate, i.e. attack/fire/hit frame
//   flashstate, muzzle flash
//

var
  weaponinfo: array[0..Ord(NUMWEAPONS) - 1] of weaponinfo_t = (
  // fist
    (ammo: am_noammo;           upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON or WF_DEMOAVAILABLE),
  // pistol
    (ammo: am_bullet;           upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON or WF_DEMOAVAILABLE),
  // shock gun
    (ammo: am_shockgunammo;     upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON or WF_DEMOAVAILABLE),
  // nerve gun
    (ammo: am_nervegunammo;     upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON),
  // freeze gun
    (ammo: am_freezegunammo;    upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON),
  // flame gun
     (ammo: am_flamegunammo;    upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON),
  // granade launcher
     (ammo: am_grenades;        upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON),
  // boomerang gun
     (ammo: am_disk;            upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON or WF_DEMOAVAILABLE),
  // missile launcher
     (ammo: am_misl;            upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON or WF_DEMOAVAILABLE),
  // tracking missile launcher
     (ammo: am_trackingmisl;    upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_WEAPON or WF_DEMOAVAILABLE),
  // RED KEYCARD SEQUENCE
    (ammo: am_noammo;           upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_SEQUENCE or WF_DEMOAVAILABLE),
  // BLUE KEYCARD SEQUENCE
    (ammo: am_noammo;           upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_SEQUENCE or WF_DEMOAVAILABLE),
  // YELLOW/GOLD KEYCARD SEQUENCE
    (ammo: am_noammo;           upstate: Ord(S_NULL);   downstate: Ord(S_NULL);
     readystate: Ord(S_NULL);   atkstate: Ord(S_NULL);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL);   flags: WF_SEQUENCE or WF_DEMOAVAILABLE)
  );

implementation

end.

