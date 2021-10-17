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
//  System specific interface stuff. 
// 
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$IFDEF OPENGL}
{$Error: This project uses software renderer, please undef "OPENGL"}
{$ENDIF}

{$IFNDEF DOOM}
{$Error: To compile this project you must define "DOOM"}
{$ENDIF}

{$I Mars3D.inc}
{$D Mars3D source port}

program Mars3D;

{$R *.RES}

uses
  FastMM4 in 'FASTMM4\FastMM4.pas',
  FastMM4Messages in 'FASTMM4\FastMM4Messages.pas',
  FastCode in 'FASTCODE\FastCode.pas',
  FastMove in 'FASTCODE\FastMove.pas',
  SysUtils,
  AnsiStringReplaceJOHIA32Unit12 in 'FASTCODE\AnsiStringReplaceJOHIA32Unit12.pas',
  AnsiStringReplaceJOHPASUnit12 in 'FASTCODE\AnsiStringReplaceJOHPASUnit12.pas',
  FastcodeAnsiStringReplaceUnit in 'FASTCODE\FastcodeAnsiStringReplaceUnit.pas',
  FastcodeCompareMemUnit in 'FASTCODE\FastcodeCompareMemUnit.pas',
  FastcodeCompareStrUnit in 'FASTCODE\FastcodeCompareStrUnit.pas',
  FastcodeCompareTextUnit in 'FASTCODE\FastcodeCompareTextUnit.pas',
  FastcodeCPUID in 'FASTCODE\FastcodeCPUID.pas',
  FastcodeFillCharUnit in 'FASTCODE\FastcodeFillCharUnit.pas',
  FastcodeLowerCaseUnit in 'FASTCODE\FastcodeLowerCaseUnit.pas',
  FastcodePatch in 'FASTCODE\FastcodePatch.pas',
  FastcodePosExUnit in 'FASTCODE\FastcodePosExUnit.pas',
  FastcodePosUnit in 'FASTCODE\FastcodePosUnit.pas',
  FastcodeStrCompUnit in 'FASTCODE\FastcodeStrCompUnit.pas',
  FastcodeStrCopyUnit in 'FASTCODE\FastcodeStrCopyUnit.pas',
  FastcodeStrICompUnit in 'FASTCODE\FastcodeStrICompUnit.pas',
  FastCodeStrLenUnit in 'FASTCODE\FastCodeStrLenUnit.pas',
  FastcodeStrToInt32Unit in 'FASTCODE\FastcodeStrToInt32Unit.pas',
  FastcodeUpperCaseUnit in 'FASTCODE\FastcodeUpperCaseUnit.pas',
  jpg_utils in 'JPEGLIB\jpg_utils.pas',
  jpg_comapi in 'JPEGLIB\jpg_comapi.pas',
  jpg_dapimin in 'JPEGLIB\jpg_dapimin.pas',
  jpg_dapistd in 'JPEGLIB\jpg_dapistd.pas',
  jpg_dcoefct in 'JPEGLIB\jpg_dcoefct.pas',
  jpg_dcolor in 'JPEGLIB\jpg_dcolor.pas',
  jpg_dct in 'JPEGLIB\jpg_dct.pas',
  jpg_ddctmgr in 'JPEGLIB\jpg_ddctmgr.pas',
  jpg_deferr in 'JPEGLIB\jpg_deferr.pas',
  jpg_dhuff in 'JPEGLIB\jpg_dhuff.pas',
  jpg_dinput in 'JPEGLIB\jpg_dinput.pas',
  jpg_dmainct in 'JPEGLIB\jpg_dmainct.pas',
  jpg_dmarker in 'JPEGLIB\jpg_dmarker.pas',
  jpg_dmaster in 'JPEGLIB\jpg_dmaster.pas',
  jpg_dmerge in 'JPEGLIB\jpg_dmerge.pas',
  jpg_dphuff in 'JPEGLIB\jpg_dphuff.pas',
  jpg_dpostct in 'JPEGLIB\jpg_dpostct.pas',
  jpg_dsample in 'JPEGLIB\jpg_dsample.pas',
  jpg_error in 'JPEGLIB\jpg_error.pas',
  jpg_idctasm in 'JPEGLIB\jpg_idctasm.pas',
  jpg_idctflt in 'JPEGLIB\jpg_idctflt.pas',
  jpg_idctfst in 'JPEGLIB\jpg_idctfst.pas',
  jpg_IDctRed in 'JPEGLIB\jpg_IDctRed.pas',
  jpg_lib in 'JPEGLIB\jpg_lib.pas',
  jpg_memmgr in 'JPEGLIB\jpg_memmgr.pas',
  jpg_memnobs in 'JPEGLIB\jpg_memnobs.pas',
  jpg_morecfg in 'JPEGLIB\jpg_morecfg.pas',
  jpg_quant1 in 'JPEGLIB\jpg_quant1.pas',
  jpg_quant2 in 'JPEGLIB\jpg_quant2.pas',
  mp3_SynthFilter in 'MP3LIB\mp3_SynthFilter.pas',
  mp3_Args in 'MP3LIB\mp3_Args.pas',
  mp3_BitReserve in 'MP3LIB\mp3_BitReserve.pas',
  mp3_BitStream in 'MP3LIB\mp3_BitStream.pas',
  mp3_CRC in 'MP3LIB\mp3_CRC.pas',
  mp3_Header in 'MP3LIB\mp3_Header.pas',
  mp3_Huffman in 'MP3LIB\mp3_Huffman.pas',
  mp3_InvMDT in 'MP3LIB\mp3_InvMDT.pas',
  mp3_L3Tables in 'MP3LIB\mp3_L3Tables.pas',
  mp3_L3Type in 'MP3LIB\mp3_L3Type.pas',
  mp3_Layer3 in 'MP3LIB\mp3_Layer3.pas',
  mp3_MPEGPlayer in 'MP3LIB\mp3_MPEGPlayer.pas',
  mp3_OBuffer in 'MP3LIB\mp3_OBuffer.pas',
  mp3_OBuffer_MCI in 'MP3LIB\mp3_OBuffer_MCI.pas',
  mp3_OBuffer_Wave in 'MP3LIB\mp3_OBuffer_Wave.pas',
  mp3_Player in 'MP3LIB\mp3_Player.pas',
  mp3_ScaleFac in 'MP3LIB\mp3_ScaleFac.pas',
  mp3_Shared in 'MP3LIB\mp3_Shared.pas',
  mp3_SubBand1 in 'MP3LIB\mp3_SubBand1.pas',
  mp3_SubBand2 in 'MP3LIB\mp3_SubBand2.pas',
  mp3_SubBand in 'MP3LIB\mp3_SubBand.pas',
  t_bmp in 'TEXLIB\t_bmp.pas',
  t_colors in 'TEXLIB\t_colors.pas',
  t_draw in 'TEXLIB\t_draw.pas',
  t_jpeg in 'TEXLIB\t_jpeg.pas',
  t_main in 'TEXLIB\t_main.pas',
  t_png in 'TEXLIB\t_png.pas',
  t_tga in 'TEXLIB\t_tga.pas',
  z_files in 'ZLIB\z_files.pas',
  DirectX in 'Common\DirectX.pas',
  am_map in 'Mars\am_map.pas',
  c_cmds in 'Base\c_cmds.pas',
  c_con in 'Base\c_con.pas',
  c_utils in 'Base\c_utils.pas',
  d_delphi in 'Common\d_delphi.pas',
  d_englsh in 'Mars\d_englsh.pas',
  d_event in 'Base\d_event.pas',
  d_fpc in 'Base\d_fpc.pas',
  d_items in 'Mars\d_items.pas',
  d_main in 'Mars\d_main.pas',
  d_net in 'Base\d_net.pas',
  d_net_h in 'Base\d_net_h.pas',
  d_player in 'Mars\d_player.pas',
  d_think in 'Base\d_think.pas',
  d_ticcmd in 'Base\d_ticcmd.pas',
  deh_main in 'Mars\deh_main.pas',
  doomdata in 'Mars\doomdata.pas',
  doomdef in 'Mars\doomdef.pas',
  doomstat in 'Mars\doomstat.pas',
  doomtype in 'Base\doomtype.pas',
  dstrings in 'Mars\dstrings.pas',
  e_endoom in 'Base\e_endoom.pas',
  f_finale in 'Mars\f_finale.pas',
  f_wipe in 'Base\f_wipe.pas',
  g_game in 'Mars\g_game.pas',
  hu_lib in 'Base\hu_lib.pas',
  hu_stuff in 'Mars\hu_stuff.pas',
  i_input in 'Base\i_input.pas',
  i_io in 'Base\i_io.pas',
  i_main in 'Base\i_main.pas',
  i_midi in 'Base\i_midi.pas',
  i_mp3 in 'Base\i_mp3.pas',
  i_music in 'Base\i_music.pas',
  i_net in 'Base\i_net.pas',
  i_sound in 'Base\i_sound.pas',
  i_system in 'Base\i_system.pas',
  i_video in 'Base\i_video.pas',
  info in 'Mars\info.pas',
  info_h in 'Mars\info_h.pas',
  info_rnd in 'Mars\info_rnd.pas',
  m_argv in 'Base\m_argv.pas',
  m_base in 'Base\m_base.pas',
  m_bbox in 'Base\m_bbox.pas',
  m_cheat in 'Base\m_cheat.pas',
  m_defs in 'Mars\m_defs.pas',
  m_fixed in 'Base\m_fixed.pas',
  m_menu in 'Mars\m_menu.pas',
  m_misc in 'Base\m_misc.pas',
  m_rnd in 'Base\m_rnd.pas',
  m_stack in 'Base\m_stack.pas',
  m_vectors in 'Base\m_vectors.pas',
  p_ceilng in 'Mars\p_ceilng.pas',
  p_doors in 'Mars\p_doors.pas',
  p_enemy in 'Mars\p_enemy.pas',
  p_extra in 'Mars\p_extra.pas',
  p_floor in 'Mars\p_floor.pas',
  p_genlin in 'Mars\p_genlin.pas',
  p_inter in 'Mars\p_inter.pas',
  p_lights in 'Mars\p_lights.pas',
  p_local in 'Mars\p_local.pas',
  p_map in 'Mars\p_map.pas',
  p_maputl in 'Mars\p_maputl.pas',
  p_mobj in 'Mars\p_mobj.pas',
  p_mobj_h in 'Mars\p_mobj_h.pas',
  p_plats in 'Mars\p_plats.pas',
  p_pspr in 'Mars\p_pspr.pas',
  p_pspr_h in 'Mars\p_pspr_h.pas',
  p_saveg in 'Mars\p_saveg.pas',
  p_scroll in 'Mars\p_scroll.pas',
  p_setup in 'Mars\p_setup.pas',
  p_sight in 'Mars\p_sight.pas',
  p_sounds in 'Mars\p_sounds.pas',
  p_spec in 'Mars\p_spec.pas',
  p_switch in 'Mars\p_switch.pas',
  p_telept in 'Mars\p_telept.pas',
  p_terrain in 'Mars\p_terrain.pas',
  p_tick in 'Mars\p_tick.pas',
  p_user in 'Mars\p_user.pas',
  r_bsp in 'Mars\r_bsp.pas',
  r_cache_main in 'Base\r_cache_main.pas',
  r_cache_walls in 'Base\r_cache_walls.pas',
  r_cache_flats in 'Base\r_cache_flats.pas',
  r_col_al in 'Mars\r_col_al.pas',
  r_col_av in 'Mars\r_col_av.pas',
  r_col_fz in 'Mars\r_col_fz.pas',
  r_col_l in 'Base\r_col_l.pas',
  r_col_ms in 'Mars\r_col_ms.pas',
  r_col_sk in 'Mars\r_col_sk.pas',
  r_col_tr in 'Base\r_col_tr.pas',
  r_column in 'Mars\r_column.pas',
  r_data in 'Mars\r_data.pas',
  r_defs in 'Mars\r_defs.pas',
  r_draw in 'Mars\r_draw.pas',
  r_fake3d in 'Base\r_fake3d.pas',
  r_grow in 'Base\r_grow.pas',
  r_hires in 'Base\r_hires.pas',
  r_intrpl in 'Base\r_intrpl.pas',
  r_lights in 'Base\r_lights.pas',
  r_dynlights in 'Base\r_dynlights.pas',
  r_main in 'Mars\r_main.pas',
  r_mmx in 'Base\r_mmx.pas',
  r_plane in 'Mars\r_plane.pas',
  r_segs in 'Base\r_segs.pas',
  r_sky in 'Mars\r_sky.pas',
  r_span in 'Base\r_span.pas',
  r_span32 in 'Base\r_span32.pas',
  r_things in 'Base\r_things.pas',
  rtl_types in 'Base\rtl_types.pas',
  s_sound in 'Mars\s_sound.pas',
  sc_actordef in 'Base\sc_actordef.pas',
  sc_engine in 'Base\sc_engine.pas',
  sc_params in 'Base\sc_params.pas',
  sounds in 'Mars\sounds.pas',
  st_lib in 'Mars\st_lib.pas',
  st_stuff in 'Mars\st_stuff.pas',
  tables in 'Base\tables.pas',
  v_data in 'Mars\v_data.pas',
  v_video in 'Base\v_video.pas',
  w_pak in 'Base\w_pak.pas',
  w_utils in 'Base\w_utils.pas',
  w_wad in 'Base\w_wad.pas',
  wi_stuff in 'Mars\wi_stuff.pas',
  z_zone in 'Base\z_zone.pas',
  r_trans8 in 'Base\r_trans8.pas',
  i_exec in 'Base\i_exec.pas',
  i_tmp in 'Base\i_tmp.pas',
  i_startup in 'Base\i_startup.pas' {StartUpConsoleForm},
  t_material in 'TEXLIB\t_material.pas',
  p_adjust in 'Base\p_adjust.pas',
  w_autoload in 'Base\w_autoload.pas',
  sc_tokens in 'Base\sc_tokens.pas',
  sc_states in 'Base\sc_states.pas',
  p_common in 'Base\p_common.pas',
  d_check in 'Mars\d_check.pas',
  r_precalc in 'Base\r_precalc.pas',
  r_wall32 in 'Base\r_wall32.pas',
  r_wall8 in 'Base\r_wall8.pas',
  i_threads in 'Base\i_threads.pas',
  r_aspect in 'Base\r_aspect.pas',
  r_batchcolumn in 'Base\r_batchcolumn.pas',
  r_batchsky in 'Base\r_batchsky.pas',
  r_colormaps in 'Base\r_colormaps.pas',
  r_diher in 'Mars\r_diher.pas',
  r_ripple in 'Base\r_ripple.pas',
  z_memmgr in 'Base\z_memmgr.pas',
  r_scale in 'Base\r_scale.pas',
  r_segs2 in 'Base\r_segs2.pas',
  r_voxels in 'Base\r_voxels.pas',
  r_softgl in 'Base\r_softgl.pas',
  vx_base in 'Base\vx_base.pas',
  info_fnd in 'Base\info_fnd.pas',
  r_palette in 'Base\r_palette.pas',
  r_colorcolumn in 'Base\r_colorcolumn.pas',
  r_utils in 'Base\r_utils.pas',
  m_crc32 in 'Base\m_crc32.pas',
  mt_utils in 'Base\mt_utils.pas',
  p_params in 'Base\p_params.pas',
  nd_main in 'Base\nd_main.pas',
  am_textured in 'Base\am_textured.pas',
  p_udmf in 'Base\p_udmf.pas',
  m_sshot_jpg in 'Base\m_sshot_jpg.pas',
  ps_main in 'SCRIPT\ps_main.pas',
  ps_import in 'SCRIPT\ps_import.pas',
  ps_compiler in 'SCRIPT\ps_compiler.pas',
  ps_runtime in 'SCRIPT\ps_runtime.pas',
  ps_utils in 'SCRIPT\ps_utils.pas',
  uPSC_dateutils in 'SCRIPT\uPSC_dateutils.pas',
  uPSC_dll in 'SCRIPT\uPSC_dll.pas',
  uPSR_dateutils in 'SCRIPT\uPSR_dateutils.pas',
  uPSR_dll in 'SCRIPT\uPSR_dll.pas',
  sc_thinker in 'Base\sc_thinker.pas',
  info_common in 'Base\info_common.pas',
  p_ladder in 'Base\p_ladder.pas',
  m_hash in 'Base\m_hash.pas',
  p_3dfloors in 'Base\p_3dfloors.pas',
  r_3dfloors in 'Base\r_3dfloors.pas',
  r_depthbuffer in 'Base\r_depthbuffer.pas',
  r_clipper in 'Base\r_clipper.pas',
  r_range in 'Base\r_range.pas',
  r_visplanes in 'Base\r_visplanes.pas',
  r_slopes in 'Base\r_slopes.pas',
  p_slopes in 'Base\p_slopes.pas',
  r_cliputils in 'Base\r_cliputils.pas',
  r_camera in 'Base\r_camera.pas',
  ps_proclist in 'SCRIPT\ps_proclist.pas',
  uPSPreProcessor in 'SCRIPT\uPSPreProcessor.pas',
  psi_system in 'SCRIPT\psi_system.pas',
  psi_globals in 'SCRIPT\psi_globals.pas',
  ddc_base in 'SCRIPT\ddc_base.pas',
  p_mobjlist in 'Base\p_mobjlist.pas',
  m_smartpointerlist in 'Base\m_smartpointerlist.pas',
  ps_events in 'SCRIPT\ps_events.pas',
  ps_serializer in 'SCRIPT\ps_serializer.pas',
  psi_game in 'SCRIPT\psi_game.pas',
  psi_overlay in 'SCRIPT\psi_overlay.pas',
  r_earthquake in 'Base\r_earthquake.pas',
  p_affectees in 'Base\p_affectees.pas',
  t_pcx in 'TEXLIB\t_pcx.pas',
  t_pcx4 in 'TEXLIB\t_pcx4.pas',
  ps_dll in 'SCRIPT\ps_dll.pas',
  ps_keywords in 'SCRIPT\ps_keywords.pas',
  ps_defs in 'SCRIPT\ps_defs.pas',
  p_gravity in 'Base\p_gravity.pas',
  t_patch in 'TEXLIB\t_patch.pas',
  r_patch in 'Base\r_patch.pas',
  r_flat32 in 'Base\r_flat32.pas',
  r_flat8 in 'Base\r_flat8.pas',
  p_bridge in 'Base\p_bridge.pas',
  w_sprite in 'Base\w_sprite.pas',
  r_things_sortvissprites in 'Base\r_things_sortvissprites.pas',
  i_steam in 'Base\i_steam.pas',
  i_displaymodes in 'Base\i_displaymodes.pas',
  v_displaymode in 'Base\v_displaymode.pas',
  d_notifications in 'Base\d_notifications.pas',
  sc_utils in 'base\sc_utils.pas',
  w_folders in 'Base\w_folders.pas',
  r_subsectors in 'Base\r_subsectors.pas',
  r_draw_additive in 'Base\r_draw_additive.pas',
  r_draw_subtractive in 'Base\r_draw_subtractive.pas',
  r_renderstyle in 'Base\r_renderstyle.pas',
  vx_voxelsprite in 'Base\vx_voxelsprite.pas',
  m_sha1 in 'Base\m_sha1.pas',
  w_wadwriter in 'Base\w_wadwriter.pas',
  sc_evaluate in 'Base\sc_evaluate.pas',
  sc_evaluate_actor in 'Base\sc_evaluate_actor.pas',
  sc_globals in 'Base\sc_globals.pas',
  r_zbuffer in 'Base\r_zbuffer.pas',
  r_softlights in 'Base\r_softlights.pas',
  r_vislight in 'Base\r_vislight.pas',
  p_musinfo in 'Base\p_musinfo.pas',
  p_levelinfo in 'Base\p_levelinfo.pas',
  deh_base in 'Base\deh_base.pas',
  r_sprite in 'Base\r_sprite.pas',
  r_tallcolumn in 'Base\r_tallcolumn.pas',
  p_animdefs in 'Base\p_animdefs.pas',
  p_easyslope in 'Base\p_easyslope.pas',
  r_flatinfo in 'Base\r_flatinfo.pas',
  r_span32_ripple in 'Base\r_span32_ripple.pas',
  r_flat32_ripple in 'Base\r_flat32_ripple.pas',
  p_easyangle in 'Base\p_easyangle.pas',
  mn_screenshot in 'Base\mn_screenshot.pas',
  p_aaptr in 'Base\p_aaptr.pas',
  sc_consts in 'Base\sc_consts.pas',
  libflac in 'AUDIOLIB\libflac.pas',
  libogg in 'AUDIOLIB\libogg.pas',
  libsndfile in 'AUDIOLIB\libsndfile.pas',
  libvorbis in 'AUDIOLIB\libvorbis.pas',
  c_lib in 'C_LIB\c_lib.pas',
  scanf in 'C_LIB\scanf.pas',
  scanf_c in 'C_LIB\scanf_c.pas',
  audiolib in 'AUDIOLIB\audiolib.pas',
  p_obituaries in 'Base\p_obituaries.pas',
  p_gender in 'Base\p_gender.pas',
  w_wadreader in 'Base\w_wadreader.pas',
  libs3m in 'AUDIOLIB\libs3m.pas',
  mikmod in 'Base\mikmod.pas',
  i_mikplay in 'Base\i_mikplay.pas',
  BTMemoryModule in 'Base\BTMemoryModule.pas',
  i_s3mmusic in 'Base\i_s3mmusic.pas',
  i_mainwindow in 'Base\i_mainwindow.pas',
  i_itmusic in 'Base\i_itmusic.pas',
  i_xmmusic in 'Base\i_xmmusic.pas',
  i_modmusic in 'Base\i_modmusic.pas',
  s_externalmusic in 'Base\s_externalmusic.pas';

var
  Saved8087CW: Word;

begin
  { Save the current FPU state and then disable FPU exceptions }
  Saved8087CW := Default8087CW;
  Set8087CW($133f); { Disable all fpu exceptions }

  ThousandSeparator := #0;
  DecimalSeparator := '.';

  try
    DoomMain;
  except
    I_FlashCachedOutput;
  end;

  { Reset the FPU to the previous state }
  Set8087CW(Saved8087CW);

end.

