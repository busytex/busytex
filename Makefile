# http://www.linuxfromscratch.org/blfs/view/svn/pst/texlive.html

URL_texlive_full_iso = http://mirrors.ctan.org/systems/texlive/Images/texlive2021-20210325.iso
URL_texlive = https://github.com/TeX-Live/texlive-source/archive/refs/heads/tags/texlive-2021.2.tar.gz
URL_expat = https://github.com/libexpat/libexpat/releases/download/R_2_4_1/expat-2.4.1.tar.gz
URL_fontconfig = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.93.tar.gz
URL_UBUNTU_RELEASE = https://packages.ubuntu.com/groovy/

# https://packages.ubuntu.com/groovy/tex/ https://packages.ubuntu.com/source/groovy/texlive-extra

TOTAL_MEMORY = 536870912

CFLAGS_OPT_native = -O3
CFLAGS_OPT_wasm = -Oz

ROOT := $(CURDIR)
EMROOT := $(dir $(shell which emcc))
PYTHON = python3

BUSYTEX = $(ROOT)/build/native/busytex

TEXMF_FULL = $(ROOT)/build/texlive-full

PREFIX_wasm = $(ROOT)/build/wasm/prefix
PREFIX_native = $(ROOT)/build/native/prefix

MAKE_wasm = emmake $(MAKE)
CMAKE_wasm = emcmake cmake
CONFIGURE_wasm = emconfigure
AR_wasm = emar
MAKE_native = $(MAKE)
CMAKE_native = cmake
AR_native = $(AR)

SKIP = all install:

CACHE_TEXLIVE_native = $(ROOT)/build/native-texlive.cache
CACHE_TEXLIVE_wasm = $(ROOT)/build/wasm-texlive.cache
CACHE_FONTCONFIG_native = $(ROOT)/build/native-fontconfig.cache
CACHE_FONTCONFIG_wasm = $(ROOT)/build/wasm-fontconfig.cache
CONFIGSITE_BUSYTEX = $(ROOT)/busytex.site

CPATH_BUSYTEX = texlive/libs/icu/include fontconfig

##############################################################################################################################

OBJ_LUATEX = luatexdir/luatex-luatex.o mplibdir/luatex-lmplib.o libluatex.a libluatexspecific.a libluatex.a libff.a libluamisc.a libluasocket.a libluaffi.a libmplibcore.a    libmputil.a libunilib.a libmd5.a  lib/lib.a
OBJ_PDFTEX = synctexdir/pdftex-synctex.o pdftex-pdftexini.o pdftex-pdftex0.o pdftex-pdftex-pool.o pdftexdir/pdftex-pdftexextra.o lib/lib.a libmd5.a busytex_libpdftex.a
OBJ_XETEX = synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o xetexdir/xetex-xetexextra.o lib/lib.a libmd5.a busytex_libxetex.a
OBJ_DVIPDF = texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a
OBJ_BIBTEX = texlive/texk/bibtex-x/busytex_bibtex8.a
OBJ_KPATHSEA = busytex_kpsewhich.o .libs/libkpathsea.a
#texlive/libs/icu/icu-build/lib/libicuio.a texlive/libs/icu/icu-build/lib/libicui18n.a 
 
OBJ_DEPS = $(addprefix texlive/libs/, harfbuzz/libharfbuzz.a graphite2/libgraphite2.a teckit/libTECkit.a libpng/libpng.a) fontconfig/src/.libs/libfontconfig.a $(addprefix texlive/libs/, freetype2/libfreetype.a pplib/libpplib.a zlib/libz.a zziplib/libzzip.a libpaper/libpaper.a icu/icu-build/lib/libicuuc.a icu/icu-build/lib/libicudata.a lua53/.libs/libtexlua53.a xpdf/libxpdf.a) texlive/texk/kpathsea/.libs/libkpathsea.a expat/libexpat.a

##############################################################################################################################

BIBTEX_REDEFINE = initialize eoln last history bad xchr buffer close_file usage      make_string str_eq_buf str_eq_str str_ptr char_width

SYNCTEX_REDEFINE = synctex_ctxt synctex_dot_open synctex_record_node_char synctex_record_node_kern synctex_record_node_math synctex_record_node_unknown synctexabort synctexchar synctexcurrent synctexhlist synctexhorizontalruleorglue synctexinitcommand synctexkern synctexmath synctexmrofxfdp synctexnode synctexoption synctexpdfrefxform synctexpdfxform synctexsheet synctexstartinput synctexteehs synctexterminate synctextsilh synctextsilv synctexvlist synctexvoidhlist synctexvoidvlist

PDFTEX_REDEFINE = initialize getstringsstarted sortavail zprimitive znewtrieop ztrienode zcompresstrie zfirstfit ztriepack ztriefix newpatterns inittrie zlinebreak newhyphexceptions zdomarks prefixedcommand storefmtfile loadfmtfile finalcleanup initprim mainbody println zprintchar zprint zprintnl zprintesc zprintthedigs zprintint zprintcs zsprintcs zprintfilename zprintsize zprintwritewhatsit zprintsanum zprintcsnames printfileline initterminal zstreqbuf zstreqstr zsearchstring zprinttwo zprinthex zprintromanint printcurrentstring zhalf zrounddecimals zprintscaled zmultandadd zxovern zxnoverd zbadness zmakefrac ztakefrac zabvscd newrandoms zinitrandoms zunifrand zshowtokenlist runaway zflushlist zfreenode zroundxnoverd zprevrightmost zflushstr getmicrointerval zshortdisplay zprintfontandchar zprintmark zprintruledimen zprintglue zprintspec zprintfamandchar zprintdelimiter zprintstyle zprintskipparam zdeletetokenref zdeleteglueref zprintmode zprintinmode popnest zprintparam begindiagnostic zenddiagnostic zprintlengthparam zprintcmdchr zprintgroup zgrouptrace pseudoclose zdeletesaref ztokenshow printmeaning showcurcmdchr showcontext groupwarning ifwarning filewarning endfilereading clearforerrorprompt zeffectivechar zaddorsub zquotient zfract beginname zpackfilename zpackbufferedname zpackjobname zeffectivecharinfo zprunemovements zshortdisplayn zcharpw zheightplusdepth zmathkern popalignment showsavegroups printtotals zfreezepagespecs youcant znormmin trapzeroglue newinteraction giveerrhelp openfmtfile closefilesandterminate zdvifour preparemag dviswap zdvifontdef zfatalerror zoverflow jumpout normalizeselector error makestring slowmakestring getavail zgetnode newnullbox zcharbox zstackintobox zvardelimiter zmakeleftright newrule znewmath znewspec znewparamglue znewglue zappendtovlist znewkern znewpenalty znewindex newnoad indentinhmode zmathglue pushalignment znewwhatsit zfractionrule fixlanguage appenditaliccorrection znewskipparam appspace pushnest zidlookup zprimlookup pseudoinput znewsavelevel zeqsave zbegintokenlist beginfilereading zstrtoks insertsrcspecial appendsrcspecial zmorename endname znewedge znewstyle newchoice znewligature znewligitem newdisc zsasave zfindsaelement zsaveforafter makenamestring zamakenamestring zzwmakenamestring zbmakenamestring zpromptfilename terminput openlogfile firmuptheline zdvipop zmovement zspecialout getnext checkoutervalidity endtokenlist gettoken zinterror pauseforinstructions zreconstitute backinput insertrelax inserror initcol zmlog backerror muerror zcharwarning znewcharacter zfetch zmakeord zfiniteshrink reportillegalcase extrarightbrace noalignerror omiterror cserror mathlimitswitch insertdollarsign offsave headforvmode alignerror zeTeXenabled normrand privileged passtext getrtoken macrocall zreadtoks zpushmath zconfusion zflushnodelist zsadestroy zeqdestroy flushmath hyphenate zcopynodelist zchangeiflimit zzreverse zmakevcenter zprunepagetop zvertbreak deletelast zjustcopy zjustreverse zfinmlist zpdferror ztokenstostring zshownodelist zprintsubsidiarydata zshowbox zvpackage zoverbar zvsplit zshoweqtb zrestoretrace zeqdefine zeqworddefine normalparagraph zinitspan initrow endgraf starteqno zgeqdefine zgeqworddefine zshowsa zsadef zsawdef zgsadef zgsawdef sarestore unsave showinfo zboxerror showactivities zensurevbox zreadfontinfo znewmarginkern zpushnode zfindprotcharleft popnode zhpack zrebox zcleanbox mlisttohlist zmakescripts zmakeover zmakeunder zmakeradical zmakemathaccent zmakefraction zmakeop zappdisplay zfindprotcharright ztotalpw ztrybreak zpostlinebreak scanfilenamebraced scanfilename getxtoken expand startinput thetoks conditional convtoks scanregisternum pseudostart zscankeyword xtoken getxorprotected fincol doassignments scanoptionalequals zsetmathchar scanleftbrace scangeneraltext appenddiscretionary builddiscretionary appendchoices buildchoices shiftcase scanfontident scanint zfindfontdimen zscansomethinginternal scancharnum zscanglue scanexpr scaneightbitint begininsertoradjust scanfourbitint scanfifteenbitint unpackage scanfourbitintor18 alterprevgraf alterinteger znewwritewhatsit makeaccent zscanmath subsup mathac mathradical zscandimen scannormalglue scanmuglue appendglue getpreambletoken appendkern insthetoks showwhatever zscantoks comparestrings zwriteout zoutwhat vlistout hlistout zshipout zfireup buildpage itsallover znewgraf appendpenalty initmath resumeafterdisplay aftermath finalign alignpeek finrow doendv zboxend zpackage handlerightbrace makemark issuemessage scanpdfexttoks scanrulespec zscanspec zbeginbox zscanbox zdoregistercommand alterpagesofar alterboxdimen initalign zscandelimiter mathfraction mathleftright alteraux znewfont openorclosein doextension maincontrol getnullstr loadpoolstrings generic_synctex_get_current_name runsystem texmf_yesno maininit topenin ipcpage open_in_or_pipe open_out_or_pipe close_file_or_pipe init_start_time get_date_and_time get_seconds_and_micros input_line calledit do_dump do_undump makefullnamestring getjobname gettexstring isnewsource remembersourceinfo makesrcspecial initstarttime find_input_file getcreationdate getfilemoddate getfilesize getfiledump convertStringToHexString getmd5sum pdftex_fail maketexstring initversionstring fixdateandtime     shellenabledp restrictedshell argv argc interactionoption dump_name filelineerrorstylep parsefirstlinep translate_filename default_translate_filename readyalready iniversion mltexp etexp TEXformatdefault formatdefaultlength outputcomment dumpoption insertsrcspecialauto insertsrcspecialeverypar srcspecialsp dumpline buffer first last strstart outputfilename strpool xchr interrupt bufsize maxbufstack inputptr inputstack inopen inputfile poolptr poolsize start_time_str

LUATEX_REDEFINE = init_start_time topenin get_date_and_time get_seconds_and_micros input_line getjobname err runaway unpackage privileged initialize maketexstring makecstring open_in_or_pipe open_out_or_pipe close_file_or_pipe new_fm_entry delete_fm_entry avl_do_entry mitem check_std_t1font pdfmapfile pdfmapline check_ff_exist is_subsetable fm_free glyph_unicode_free write_tounicode zip_free pdf_printf convertStringToPDFString getcreationdate matrixused getllx getlly geturx getury matrixtransformrect matrixtransformpoint matrixrecalculate libpdffinish conditional unsave expand fd_tree  fo_tree  new_fd_entry lookup_fd_entry register_fd_entry get_unsigned_byte get_unsigned_pair read_jbig2_info write_jbig2 read_jpg_info write_jpg read_png_info write_png colorstackused newcolorstack colorstackcurrent colorstackpop colorstackskippagestart ttf_free writettf writeotf read_pdf_info write_epdf epdf_free make_subset_tag tex_printf xfwrite xfflush xgetc xputc initversionstring char_array selector strstart strstart error notdef mac_glyph_names ambiguous_names cur_file_name

DVIPDFMX_REDEFINE = cff_stdstr agl_chop_suffix agl_sput_UTF16BE agl_get_unicodes agl_name_is_unicode agl_name_convert_unicode agl_suffix_to_otltag agl_lookup_list agl_select_listfile agl_init_map agl_close_map bmp_include_image check_for_bmp bmp_get_bbox cff_open cff_close cff_put_header cff_get_index cff_get_index_header cff_release_index cff_new_index cff_index_size cff_pack_index cff_get_name cff_set_name cff_read_subrs cff_read_encoding cff_pack_encoding cff_encoding_lookup cff_release_encoding cff_read_charsets cff_pack_charsets cff_glyph_lookup cff_get_glyphname cff_charsets_lookup cff_charsets_lookup_gid cff_release_charsets cff_charsets_lookup_inverse cff_read_fdselect cff_pack_fdselect cff_fdselect_lookup cff_release_fdselect cff_read_fdarray cff_read_private cff_get_string cff_get_sid cff_get_seac_sid cff_add_string cff_update_string cff_new_dict cff_release_dict cff_dict_set cff_dict_get cff_dict_add cff_dict_remove cff_dict_known cff_dict_unpack cff_dict_pack cff_dict_update CIDFont_require_version CIDFont_set_flags CIDFont_get_fontname CIDFont_get_ident CIDFont_get_opt_index CIDFont_get_flag CIDFont_get_subtype CIDFont_get_embedding CIDFont_get_resource CIDFont_get_CIDSysInfo CIDFont_attach_parent CIDFont_get_parent_id CIDFont_is_BaseFont CIDFont_is_ACCFont CIDFont_is_UCSFont CIDFont_cache_find CIDFont_cache_get CIDFont_cache_close CIDFont_type0_set_flags CIDFont_type0_open CIDFont_type0_dofont t1_load_UnicodeCMap CIDFont_type0_t1dofont CIDFont_type0_t1cdofont CIDFont_type2_set_flags CIDFont_type2_open CIDFont_type2_dofont CMap_set_silent CMap_new CMap_release CMap_is_valid CMap_is_Identity CMap_get_profile CMap_get_name CMap_get_type CMap_set_name CMap_set_type CMap_set_wmode CMap_set_CIDSysInfo CMap_add_bfchar CMap_add_cidchar CMap_add_bfrange CMap_add_notdefchar CMap_add_notdefrange CMap_add_codespacerange CMap_decode_char CMap_decode CMap_cache_init CMap_cache_get CMap_cache_find CMap_cache_close CMap_cache_add CMap_parse_check_sig CMap_parse CMap_create_stream CMap_ToCode_stream cs_copy_charstring dumppaperinfo dpx_open_file dpx_find_type1_file dpx_find_truetype_file dpx_find_opentype_file dpx_find_dfont_file dpx_file_apply_filter dpx_create_temp_file dpx_create_fix_temp_file dpx_delete_old_cache dpx_delete_temp_file dpx_util_read_length dpx_util_get_unique_time_if_given dpx_util_format_asn_date skip_white_spaces xtoi dpx_stack_init dpx_stack_pop dpx_stack_push dpx_stack_depth dpx_stack_top dpx_stack_at dpx_stack_roll ht_init_table ht_clear_table ht_table_size ht_lookup_table ht_append_table ht_remove_table ht_insert_table ht_set_iter ht_clear_iter ht_iter_getkey ht_iter_getval ht_iter_next parse_float_decimal parse_c_string parse_c_ident get_origin dvi_init dvi_close dvi_tell_mag dvi_unit_size dvi_dev_xpos dvi_dev_ypos dvi_npages dvi_comment dvi_vf_init dvi_vf_finish dvi_set_font dvi_set dvi_rule dvi_right dvi_put dvi_push dvi_pop dvi_w0 dvi_w dvi_x0 dvi_x dvi_down dvi_y dvi_y0 dvi_z dvi_z0 dvi_do_page dvi_scan_specials dvi_locate_font dvi_link_annot dvi_set_linkmode dvi_set_phantom_height dvi_tag_depth dvi_untag_depth dvi_compute_boxes dvi_do_special dvi_set_compensation pdf_copy_clip pdf_include_page error_cleanup shut_up ERROR MESG WARN pdf_init_fontmaps pdf_clear_fontmaps pdf_close_fontmaps pdf_init_fontmap_record pdf_clear_fontmap_record pdf_load_fontmap_file pdf_read_fontmap_line pdf_append_fontmap_record pdf_remove_fontmap_record pdf_insert_fontmap_record pdf_lookup_fontmap_record is_pdfm_mapline pdf_insert_native_fontmap_record check_for_jp2 jp2_include_image jp2_get_bbox check_for_jpeg jpeg_include_image jpeg_get_bbox new renew seek_absolute seek_relative seek_end tell_position file_size xfile_size mfgets mfreadln mps_set_translate_origin mps_scan_bbox mps_include_page mps_exec_inline mps_stack_depth mps_eop_cleanup mps_do_page get_unsigned_byte skip_bytes get_signed_byte get_unsigned_pair sget_unsigned_pair get_signed_pair get_unsigned_triple get_signed_triple get_signed_quad get_unsigned_quad get_unsigned_num get_positive_quad sqxfw otl_new_opt otl_release_opt otl_parse_optstring otl_match_optrule pdf_color_rgbcolor pdf_color_cmykcolor pdf_color_graycolor pdf_color_spotcolor pdf_color_copycolor pdf_color_brighten_color pdf_color_type pdf_color_compare pdf_color_set_color pdf_color_is_white iccp_get_rendering_intent iccp_check_colorspace iccp_load_profile pdf_init_colors pdf_close_colors pdf_get_colorspace_reference pdf_get_colorspace_num_components pdf_get_colorspace_subtype pdf_colorspace_load_ICCBased pdf_color_set pdf_color_push pdf_color_pop pdf_color_clear_stack pdf_color_get_current transform_info_clear pdf_sprint_matrix pdf_sprint_rect pdf_sprint_coord pdf_sprint_length pdf_sprint_number pdf_init_device pdf_close_device dev_unit_dviunit pdf_dev_set_string pdf_dev_set_rule pdf_dev_put_image pdf_dev_locate_font pdf_dev_get_font_wmode this pdf_dev_get_dirmode pdf_dev_set_dirmode pdf_dev_set_rect pdf_dev_get_param pdf_dev_set_param pdf_dev_reset_fonts pdf_dev_reset_color pdf_dev_bop pdf_dev_eop graphics_mode pdf_dev_begin_actualtext pdf_dev_end_actualtext pdf_open_document pdf_doc_set_pagelabel pdf_dev_init_gstates pdf_dev_clear_gstates pdf_dev_currentmatrix pdf_dev_currentpoint pdf_dev_setlinewidth pdf_dev_setmiterlimit pdf_dev_setlinecap pdf_dev_setlinejoin pdf_dev_setdash pdf_dev_setflat pdf_dev_moveto pdf_dev_rmoveto pdf_dev_closepath pdf_dev_lineto pdf_dev_rlineto pdf_dev_curveto pdf_dev_rcurveto pdf_dev_arc pdf_dev_arcn pdf_dev_newpath pdf_dev_clip pdf_dev_eoclip pdf_dev_rectstroke pdf_dev_rectfill pdf_dev_rectclip pdf_dev_flushpath pdf_dev_concat pdf_dev_dtransform pdf_dev_idtransform pdf_dev_transform pdf_dev_itransform pdf_dev_gsave pdf_dev_grestore pdf_dev_push_gstate pdf_dev_pop_gstate pdf_dev_arcx pdf_dev_bspline pdf_invertmatrix pdf_dev_current_depth pdf_dev_grestore_to pdf_dev_currentcolor pdf_dev_set_fixed_point pdf_dev_get_fixed_point pdf_dev_set_color pdf_dev_xgstate_push pdf_dev_xgstate_pop pdf_dev_reset_xgstate pdf_init_encodings pdf_close_encodings pdf_encoding_complete pdf_encoding_findresource pdf_get_encoding_obj pdf_encoding_is_predefined pdf_encoding_used_by_type3 pdf_encoding_get_name pdf_encoding_get_encoding pdf_create_ToUnicode_CMap pdf_encoding_add_usedchars pdf_encoding_get_tounicode pdf_load_ToUnicode_stream pdf_enc_init pdf_enc_close pdf_enc_set_label pdf_enc_set_generation pdf_encrypt_data pdf_enc_get_encrypt_dict pdf_enc_get_extension_dict pdf_font_set_dpi pdf_init_fonts pdf_close_fonts pdf_font_findresource pdf_get_font_subtype pdf_get_font_reference pdf_get_font_usedchars pdf_get_font_fontname pdf_get_font_encoding pdf_get_font_wmode pdf_font_is_in_use pdf_font_get_ident pdf_font_get_mapname pdf_font_get_fontname pdf_font_get_uniqueTag pdf_font_get_resource pdf_font_get_descriptor pdf_font_get_usedchars pdf_font_get_encoding pdf_font_get_flag pdf_font_get_flags pdf_font_get_param pdf_font_get_index pdf_font_set_fontname pdf_font_set_flags pdf_font_set_subtype pdf_font_make_uniqueTag pdf_new_name_tree pdf_delete_name_tree pdf_names_add_object pdf_names_lookup_reference pdf_names_lookup_object pdf_names_close_object pdf_names_reserve pdf_names_create_tree pdf_error_cleanup pdf_get_output_file pdf_out_init pdf_out_set_encrypt pdf_out_flush pdf_get_version pdf_get_version_major pdf_get_version_minor pdf_release_obj pdf_obj_typeof pdf_ref_obj pdf_link_obj pdf_transfer_label pdf_new_undefined pdf_new_null pdf_new_boolean pdf_boolean_value pdf_new_number pdf_set_number pdf_number_value pdf_new_string pdf_set_string pdf_string_value pdf_string_length pdf_new_name pdf_name_value pdf_new_array pdf_add_array pdf_put_array pdf_get_array pdf_array_length pdf_shift_array pdf_pop_array pdf_new_dict pdf_remove_dict pdf_merge_dict pdf_lookup_dict pdf_dict_keys pdf_add_dict pdf_put_dict pdf_foreach_dict pdf_new_stream pdf_add_stream pdf_concat_stream pdf_stream_dict pdf_stream_length pdf_stream_set_flags pdf_stream_get_flags pdf_stream_dataptr pdf_stream_set_predictor pdf_compare_reference pdf_compare_object pdf_set_info pdf_set_root pdf_files_init pdf_files_close check_for_pdf pdf_open pdf_close pdf_file_get_trailer pdf_file_get_catalog pdf_file_get_version pdf_deref_obj pdf_import_object pdfobj_escape_str pdf_new_indirect pdf_check_version dump pdfparse_skip_line skip_white parse_number parse_unsigned parse_ident parse_val_ident parse_opt_ident parse_pdf_name parse_pdf_boolean parse_pdf_number parse_pdf_null parse_pdf_string parse_pdf_dict parse_pdf_array parse_pdf_object parse_pdf_object_extended parse_pdf_tainted_dict pdf_init_resources pdf_close_resources pdf_defineresource pdf_findresource pdf_resource_exist pdf_get_resource_reference pdf_get_resource pdf_init_images pdf_close_images pdf_ximage_get_resname pdf_ximage_get_reference pdf_ximage_findresource pdf_ximage_load_image pdf_ximage_defineresource pdf_ximage_reserve pdf_ximage_init_image_info pdf_ximage_init_form_info pdf_ximage_set_image pdf_ximage_set_form pdf_ximage_get_page set_distiller_template get_distiller_template pdf_ximage_get_subtype pdf_error_cleanup_cache pdf_font_open_pkfont pdf_font_load_pkfont png_include_image check_for_png png_get_bbox pst_get_token pst_new_obj pst_new_mark pst_type_of pst_length_of pst_getIV pst_getRV pst_getSV pst_data_ptr pst_parse_null pst_parse_name pst_parse_number pst_parse_string put_big_endian sfnt_open dfont_open sfnt_close sfnt_read_table_directory sfnt_find_table_len sfnt_find_table_pos sfnt_locate_table sfnt_set_table sfnt_require_table sfnt_create_FontFile_stream spc_color_check_special spc_color_setup_handler spc_dvipdfmx_check_special spc_dvipdfmx_setup_handler spc_dvips_at_begin_document spc_dvips_at_end_document spc_dvips_at_begin_page spc_dvips_at_end_page spc_dvips_check_special spc_dvips_setup_handler spc_html_at_begin_page spc_html_at_end_page spc_html_at_begin_document spc_html_at_end_document spc_html_check_special spc_html_setup_handler spc_misc_check_special spc_misc_setup_handler spc_pdfm_at_begin_document spc_pdfm_at_end_document spc_pdfm_at_end_page spc_pdfm_check_special spc_pdfm_setup_handler tpic_set_fill_mode spc_tpic_at_begin_page spc_tpic_at_end_page spc_tpic_at_begin_document spc_tpic_at_end_document spc_tpic_check_special spc_tpic_setup_handler spc_util_read_colorspec spc_util_read_dimtrns spc_util_read_blahblah spc_util_read_numbers spc_util_read_pdfcolor spc_xtx_check_special spc_xtx_setup_handler spc_handler_xtx_do_transform spc_handler_xtx_gsave spc_handler_xtx_grestore spc_warn spc_lookup_reference spc_lookup_object spc_begin_annot spc_end_annot spc_resume_annot spc_suspend_annot spc_is_tracking_boxes spc_set_linkmode spc_set_phantom spc_push_object spc_flush_object spc_clear_objects spc_put_image spc_get_current_point spc_get_coord spc_push_coord spc_pop_coord spc_set_fixed_point spc_get_fixed_point spc_put_fixed_point spc_dup_fixed_point spc_pop_fixed_point spc_clear_fixed_point spc_exec_at_begin_page spc_exec_at_end_page spc_exec_at_begin_document spc_exec_at_end_document spc_exec_special release_sfd_record sfd_load_record sfd_get_subfont_ids t1char_get_metrics t1char_convert_charstring t1_load_font is_pfb t1_get_fontname t1_get_standard_glyph tfm_open tfm_close_all tfm_get_width tfm_get_height tfm_get_depth tfm_get_fw_width tfm_get_fw_height tfm_get_fw_depth tfm_string_width tfm_string_depth tfm_string_height tfm_get_design_size tfm_get_codingscheme tfm_is_vert tfm_is_jfm tfm_exists pdf_font_open_truetype pdf_font_load_truetype ttc_read_offset tt_get_fontdesc tt_cmap_read tt_cmap_lookup tt_cmap_release otf_create_ToUnicode_stream otf_load_Unicode_CMap otf_try_load_GID_to_CID_map tt_build_init tt_build_finish tt_add_glyph tt_get_index tt_find_glyph tt_build_tables tt_get_metrics otl_gsub_new otl_gsub_release otl_gsub_select otl_gsub_add_feat otl_gsub_apply otl_gsub_apply_alt otl_gsub_apply_lig otl_gsub_add_feat_list otl_gsub_set_chain otl_gsub_apply_chain otl_gsub_add_ToUnicode tt_read_post_table tt_release_post_table tt_lookup_post_table tt_get_glyphname tt_pack_head_table tt_read_head_table tt_pack_hhea_table tt_read_hhea_table tt_pack_maxp_table tt_read_maxp_table tt_pack_vhea_table tt_read_vhea_table tt_read_VORG_table tt_read_longMetrics tt_read_os2__table tt_get_ps_fontname Type0Font_get_wmode Type0Font_get_encoding Type0Font_get_usedchars Type0Font_get_resource Type0Font_set_ToUnicode Type0Font_cache_init Type0Font_cache_get Type0Font_cache_find Type0Font_cache_close pdf_font_open_type1 pdf_font_load_type1 pdf_font_open_type1c pdf_font_load_type1c UC_is_valid UC_UTF16BE_is_valid_string UC_UTF8_is_valid_string UC_UTF16BE_encode_char UC_UTF16BE_decode_char UC_UTF8_decode_char UC_UTF8_encode_char vf_locate_font vf_set_char    work_buffer 

# TOOLS CFLAGS
# grep extern source/texlive/texk/dvipdfm-x/*.h | grep -o '[0-9a-zA-Z_]\+\s\+(' | cut -d' ' -f1 | tr '\n' ' '
#CFLAGS_XDVIPDFMX := -Dmain='__attribute__((visibility(\"default\"))) busymain_xdvipdfmx' $(shell python3 redefine_sym.py busydvipdfmx check_for_jpeg check_for_bmp check_for_png seek_absolute seek_relative seek_end tell_position file_size mfgets work_buffer get_unsigned_byte get_unsigned_pair      pdf_new_stream pdf_ref_obj pdf_add_stream pdf_release_obj ttc_read_offset cff_release_dict cff_new_dict cff_dict_unpack cff_dict_known cff_dict_get cff_dict_pack cff_dict_add cff_dict_remove cff_dict_set cff_dict_update cff_close cff_get_name cff_set_name cff_put_header cff_get_index_header cff_get_index cff_pack_index cff_index_size cff_new_index cff_release_index cff_get_string cff_stdstr cff_get_sid cff_update_string cff_add_string cff_release_encoding cff_read_charsets cff_pack_charsets cff_release_charsets cff_read_fdselect cff_pack_fdselect cff_release_fdselect cff_fdselect_lookup cff_read_fdarray cff_read_private cff_read_subrs get_signed_byte get_signed_pair get_unsigned_quad sfnt_open sfnt_close put_big_endian sfnt_set_table sfnt_find_table_len sfnt_find_table_pos sfnt_locate_table sfnt_read_table_directory sfnt_require_table sfnt_create_FontFile_stream )
 
CFLAGS_KPSEWHICH := -Dmain='__attribute__((visibility(\"default\"))) busymain_kpsewhich'
CFLAGS_XETEX := -Dmain='__attribute__((visibility(\"default\"))) busymain_xetex'
CFLAGS_BIBTEX := -Dmain='__attribute__((visibility(\"default\"))) busymain_bibtex8' $(shell python3 redefine_sym.py busybibtex $(BIBTEX_REDEFINE) )
CFLAGS_XDVIPDFMX := -Dmain='__attribute__((visibility(\"default\"))) busymain_xdvipdfmx' $(shell python3 redefine_sym.py busydvipdfmx $(DVIPDFMX_REDEFINE) )
CFLAGS_PDFTEX := -Dmain='__attribute__((visibility(\"default\"))) busymain_pdftex' $(shell python3 redefine_sym.py busypdftex $(PDFTEX_REDEFINE) $(SYNCTEX_REDEFINE))
CFLAGS_LUATEX := -Dmain='__attribute__((visibility(\"default\"))) busymain_luatex' $(shell python3 redefine_sym.py busyluatex $(LUATEX_REDEFINE) $(SYNCTEX_REDEFINE))

##############################################################################################################################

# uuid_generate_random feature request: https://github.com/emscripten-core/emscripten/issues/12093
CFLAGS_FONTCONFIG_wasm = -Duuid_generate_random=uuid_generate $(CFLAGS_OPT_wasm)
CFLAGS_FONTCONFIG_native = $(CFLAGS_OPT_native)
CFLAGS_XDVIPDFMX_wasm = $(CFLAGS_XDVIPDFMX) $(CFLAGS_OPT_wasm)
CFLAGS_BIBTEX_wasm = $(CFLAGS_BIBTEX) $(CFLAGS_OPT_wasm) -s TOTAL_MEMORY=$(TOTAL_MEMORY) $(CFLAGS_OPT_wasm)
CFLAGS_XETEX_wasm = $(CFLAGS_XETEX) $(CFLAGS_OPT_wasm)
CFLAGS_PDFTEX_wasm = $(CFLAGS_PDFTEX) $(CFLAGS_OPT_wasm)
CFLAGS_XDVIPDFMX_native = $(CFLAGS_XDVIPDFMX) $(CFLAGS_OPT_native)
CFLAGS_BIBTEX_native = $(CFLAGS_BIBTEX) $(CFLAGS_OPT_native)
CFLAGS_XETEX_native = $(CFLAGS_XETEX) $(CFLAGS_OPT_native)
CFLAGS_PDFTEX_native = $(CFLAGS_PDFTEX) $(CFLAGS_OPT_native)
CFLAGS_LUATEX_native = $(CFLAGS_LUATEX) $(CFLAGS_OPT_native)
CFLAGS_KPSEWHICH_wasm = $(CFLAGS_KPSEWHICH) $(CFLAGS_OPT_wasm)
CFLAGS_KPSEWHICH_native = $(CFLAGS_KPSEWHICH) $(CFLAGS_OPT_native)
CFLAGS_TEXLIVE_wasm = -I$(ROOT)/build/wasm/texlive/libs/icu/include -I$(ROOT)/source/fontconfig $(CFLAGS_OPT_wasm) -s ERROR_ON_UNDEFINED_SYMBOLS=0 -Wno-error=unused-but-set-variable
CFLAGS_TEXLIVE_native = -I$(ROOT)/build/native/texlive/libs/icu/include -I$(ROOT)/source/fontconfig $(CFLAGS_OPT_native)
CFLAGS_ICU_wasm = $(CFLAGS_OPT_wasm) -s ERROR_ON_UNDEFINED_SYMBOLS=0 
CFLAGS_FONTCONFIGFREETYPE_wasm = $(addprefix -I$(ROOT)/build/wasm/texlive/libs/, freetype2/ freetype2/freetype2/)
CFLAGS_FONTCONFIGFREETYPE_native = $(addprefix -I$(ROOT)/build/native/texlive/libs/, freetype2/ freetype2/freetype2/)
LIBS_FONTCONFIGFREETYPE_wasm = -L$(ROOT)/build/wasm/texlive/libs/freetype2/ -lfreetype
LIBS_FONTCONFIGFREETYPE_native = -L$(ROOT)/build/native/texlive/libs/freetype2/ -lfreetype
PKGDATAFLAGS_ICU_wasm = --without-assembly -O $(ROOT)/build/wasm/texlive/libs/icu/icu-build/data/icupkg.inc

##############################################################################################################################

# EM_COMPILER_WRAPPER / EM_COMPILER_LAUNCHER feature request: https://github.com/emscripten-core/emscripten/issues/12340
CCSKIP_ICU_wasm = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(addprefix $(ROOT)/build/native/texlive/libs/icu/icu-build/bin/, icupkg pkgdata) --
CCSKIP_FREETYPE_wasm = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(ROOT)/build/native/texlive/libs/freetype2/ft-build/apinames --
CCSKIP_XETEX_wasm = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(addprefix $(ROOT)/build/native/texlive/texk/web2c/, ctangle otangle tangle tangleboot ctangleboot tie xetex) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/web2c/, fixwrites makecpool splitup web2c) --
OPTS_ICU_configure_wasm = CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_ICU_make_wasm = -e PKGDATA_OPTS="$(PKGDATAFLAGS_ICU_wasm)" -e CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" -e CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_ICU_configure_make_wasm = $(OPTS_ICU_make_wasm) -e abs_srcdir="'$(EMROOT)/emconfigure $(ROOT)/source/texlive/libs/icu'"
OPTS_BIBTEX_wasm = -e CFLAGS="$(CFLAGS_BIBTEX_wasm)" -e CXXFLAGS="$(CFLAGS_BIBTEX_wasm)"
OPTS_FREETYPE_wasm = CC="$(CCSKIP_FREETYPE_wasm) emcc"
OPTS_XETEX_wasm = CC="$(CCSKIP_XETEX_wasm) emcc $(CFLAGS_XETEX_wasm)" CXX="$(CCSKIP_XETEX_wasm) em++ $(CFLAGS_XETEX_wasm)"
OPTS_PDFTEX_wasm = CC="$(CCSKIP_XETEX_wasm) emcc $(CFLAGS_PDFTEX_wasm)" CXX="$(CCSKIP_XETEX_wasm) em++ $(CFLAGS_PDFTEX_wasm)"
OPTS_XDVIPDFMX_wasm = CC="emcc $(CFLAGS_XDVIPDFMX_wasm)" CXX="em++ $(CFLAGS_XDVIPDFMX_wasm)"
OPTS_XDVIPDFMX_native = -e CFLAGS="$(CFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX_native)" -e CPPFLAGS="$(CFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX_native)"
OPTS_BIBTEX_native = -e CFLAGS="$(CFLAGS_BIBTEX_native)" -e CXXFLAGS="$(CFLAGS_BIBTEX_native)"
OPTS_XETEX_native = CC="$(CC) $(CFLAGS_XETEX_native)" CXX="$(CXX) $(CFLAGS_XETEX_native)"
OPTS_PDFTEX_native = CC="$(CC) $(CFLAGS_PDFTEX_native)" CXX="$(CXX) $(CFLAGS_PDFTEX_native)"
OPTS_LUATEX_native = CC="$(CC) $(CFLAGS_LUATEX_native)" CXX="$(CXX) $(CFLAGS_LUATEX_native)"
OPTS_KPSEWHICH_native = CFLAGS="$(CFLAGS_KPSEWHICH_native)"
OPTS_KPSEWHICH_wasm = CFLAGS="$(CFLAGS_KPSEWHICH_wasm)"

##############################################################################################################################

.PHONY: all
all:
	$(MAKE) build/versions.txt
	$(MAKE) texlive
	$(MAKE) native
	$(MAKE) tds-basic
	$(MAKE) wasm
	$(MAKE) build/wasm/fonts.conf
	$(MAKE) build/wasm/texlive-basic.js
	#$(MAKE) tds-full
	#$(MAKE) ubuntu-wasm

source/texlive.downloaded source/expat.downloaded source/fontconfig.downloaded:
	mkdir -p $(basename $@)
	wget --no-verbose --no-clobber $(URL_$(notdir $(basename $@))) -O "$(basename $@).tar.gz" || true
	tar -xf "$(basename $@).tar.gz" --strip-components=1 --directory="$(basename $@)"
	touch $@

source/fontconfig.patched: source/fontconfig.downloaded
	patch -d $(basename $<) -Np1 -i $(ROOT)/fontconfig_emcc.patch
	echo "$(SKIP)" > source/fontconfig/test/Makefile.in 
	touch $@

source/texlive.patched: source/texlive.downloaded
	#rm -rf $(addprefix source/texlive/, texk/upmendex texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools) || true
	rm -rf source/texlive/texk/upmendex
	#wget -O source/texlive/texk/upmendex/configure https://raw.githubusercontent.com/t-tk/upmendex-package/autoconf-fix/source/configure 
	touch $@

build/%/texlive.configured: source/texlive.patched
	mkdir -p $(basename $@)
	echo '' > $(CACHE_TEXLIVE_$*)
	cd $(basename $@) &&                        \
	CONFIG_SITE=$(CONFIGSITE_BUSYTEX) $(CONFIGURE_$*) $(ROOT)/source/texlive/configure		\
	  --cache-file=$(CACHE_TEXLIVE_$*)  		\
	  --prefix="$(PREFIX_$*)"					\
	  --enable-dump-share						\
	  --enable-static							\
	  --enable-freetype2						\
	  --disable-shared							\
	  --disable-multiplatform					\
	  --disable-native-texlive-build			\
	  --disable-all-pkgs						\
	  --without-x								\
	  --without-system-cairo					\
	  --without-system-gmp						\
	  --without-system-graphite2				\
	  --without-system-harfbuzz					\
	  --without-system-libgs					\
	  --without-system-libpaper					\
	  --without-system-mpfr						\
	  --without-system-pixman					\
	  --without-system-poppler					\
	  --without-system-xpdf						\
	  --without-system-icu						\
	  --without-system-fontconfig				\
	  --without-system-freetype2				\
	  --without-system-libpng					\
	  --without-system-zlib						\
	  --without-system-zziplib					\
	  --with-banner-add="_busytex$*"			\
		CFLAGS="$(CFLAGS_TEXLIVE_$*)"	     	\
	  CPPFLAGS="$(CFLAGS_TEXLIVE_$*)"           \
	  CXXFLAGS="$(CFLAGS_TEXLIVE_$*)"
	$(MAKE_$*) -C $(basename $@)
	touch $@

build/native/texlive/libs/icu/icu-build/lib/libicuuc.a build/native/texlive/libs/icu/icu-build/lib/libicudata.a build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata : build/native/texlive.configured
	$(MAKE_native) -C build/native/texlive/libs/icu 
	$(MAKE_native) -C build/native/texlive/libs/icu/icu-build 

build/native/texlive/libs/freetype2/libfreetype.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) 

build/wasm/texlive/libs/freetype2/libfreetype.a: build/wasm/texlive.configured build/native/texlive/libs/freetype2/libfreetype.a
	$(MAKE_wasm) -C $(dir $@) $(OPTS_FREETYPE_wasm)

build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a: build/wasm/texlive.configured build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata
	cd build/wasm/texlive/libs/icu && \
	$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu/configure $(OPTS_ICU_configure_wasm)
	$(MAKE_wasm) -C build/wasm/texlive/libs/icu $(OPTS_ICU_configure_make_wasm)
	echo "$(SKIP)" > build/wasm/texlive/libs/icu/icu-build/test/Makefile
	$(MAKE_wasm) -C build/wasm/texlive/libs/icu/icu-build $(OPTS_ICU_make_wasm) 

build/%/texlive/libs/teckit/libTECkit.a build/%/texlive/libs/harfbuzz/libharfbuzz.a build/%/texlive/libs/graphite2/libgraphite2.a build/%/texlive/libs/libpng/libpng.a build/%/texlive/libs/libpaper/libpaper.a build/%/texlive/libs/zlib/libz.a build/%/texlive/libs/pplib/libpplib.a build/%/texlive/libs/xpdf/libxpdf.a build/%/texlive/libs/zziplib/libzzip.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) 

build/%/expat/libexpat.a: source/expat.downloaded
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CMAKE_$*) \
	   -DCMAKE_C_FLAGS="$(CFLAGS_$*_OPT)" \
	   -DEXPAT_BUILD_DOCS=off \
	   -DEXPAT_SHARED_LIBS=off \
	   -DEXPAT_BUILD_EXAMPLES=off \
	   -DEXPAT_BUILD_FUZZERS=off \
	   -DEXPAT_BUILD_TESTS=off \
	   -DEXPAT_BUILD_TOOLS=off \
	   $(ROOT)/$(basename $<) 
	$(MAKE_$*) -C $(dir $@)

build/%/fontconfig/src/.libs/libfontconfig.a: source/fontconfig.patched build/%/expat/libexpat.a build/%/texlive/libs/freetype2/libfreetype.a
	echo '' > $(CACHE_FONTCONFIG_$*)
	mkdir -p build/$*/fontconfig
	cd build/$*/fontconfig && \
	$(CONFIGURE_$*) $(ROOT)/$(basename $<)/configure \
	   --cache-file=$(CACHE_FONTCONFIG_$*)		 \
	   --prefix=$(PREFIX_$*) \
	   --sysconfdir=/etc     \
	   --localstatedir=/var  \
	   --enable-static \
	   --disable-shared \
	   --disable-docs \
	   --with-expat-includes="$(ROOT)/source/expat/lib" \
	   --with-expat-lib="$(ROOT)/build/$*/expat" \
	   CFLAGS="$(CFLAGS_FONTCONFIG_$*) -v" FREETYPE_CFLAGS="$(CFLAGS_FONTCONFIGFREETYPE_$*)" FREETYPE_LIBS="$(LIBS_FONTCONFIGFREETYPE_$*)"
	$(MAKE_$*) -C build/$*/fontconfig

build/%/texlive/texk/web2c/lib/lib.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(notdir $@)

build/%/texlive/texk/kpathsea/.libs/libkpathsea.a: build/%/texlive.configured
	$(MAKE_$*) -C build/$*/texlive/texk/kpathsea

build/%/texlive/texk/kpathsea/busytex_kpsewhich.o: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) kpsewhich.o $(OPTS_KPSEWHICH_$*)
	cp $(dir $@)/kpsewhich.o $@

build/%/texlive/libs/lua53/.libs/libtexlua53.a: build/%/texlive.configured
	$(MAKE_$*) -C build/$*/texlive/libs/lua53

################################################################################################################

build/native/texlive/texk/bibtex-x/busytex_bibtex8.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) $(subst -Dmain=, -Dbusymain=, $(OPTS_BIBTEX_native))
	rm $(dir $@)/bibtex8-bibtex.o
	$(MAKE_native) -C $(dir $@) bibtex8-bibtex.o $(OPTS_BIBTEX_native)
	$(AR_native) -crs $@ $(dir $@)/bibtex8-*.o

build/native/texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) $(subst -Dmain=, -Dbusymain=, $(OPTS_XDVIPDFMX_native))
	rm $(dir $@)/dvipdfmx.o
	$(MAKE_native) -C $(dir $@) dvipdfmx.o $(OPTS_XDVIPDFMX_native)
	$(AR_native) -crs $@ $(dir $@)/*.o

build/native/texlive/texk/web2c/busytex_libxetex.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) synctexdir/xetex-synctex.o xetex $(subst -Dmain=, -Dbusymain=, $(OPTS_XETEX_native))
	rm $(dir $@)/xetexdir/xetex-xetexextra.o
	$(MAKE_native) -C $(dir $@) xetexdir/xetex-xetexextra.o $(OPTS_XETEX_native)
	$(MAKE_native) -C $(dir $@) libxetex.a $(OPTS_XETEX_native)
	mv $(dir $@)/libxetex.a $@

build/native/texlive/texk/web2c/busytex_libpdftex.a: build/native/texlive.configured build/native/texlive/libs/xpdf/libxpdf.a
	$(MAKE_native) -C $(dir $@) synctexdir/pdftex-synctex.o pdftex $(subst -Dmain=, -Dbusymain=, $(OPTS_PDFTEX_native))
	rm $(dir $@)/pdftexdir/pdftex-pdftexextra.o
	$(MAKE_native) -C $(dir $@) pdftexdir/pdftex-pdftexextra.o $(OPTS_PDFTEX_native)
	$(MAKE_native) -C $(dir $@) libpdftex.a $(OPTS_PDFTEX_native)
	mv $(dir $@)/libpdftex.a $@

build/native/texlive/texk/web2c/libluatex.a: build/native/texlive.configured build/native/texlive/libs/zziplib/libzzip.a build/native/texlive/libs/lua53/.libs/libtexlua53.a
	$(MAKE_native) -C $(dir $@) luatexdir/luatex-luatex.o mplibdir/luatex-lmplib.o libluatexspecific.a libmputil.a $(OPTS_LUATEX_native)
	$(MAKE_native) -C $(dir $@) $(notdir $@) $(OPTS_LUATEX_native)

build/native/busytex_luatex: 
	mkdir -p $(dir $@)
	$(CC) -c busytex.c -o $@.o  -DBUSYTEX_KPSEWHICH -DBUSYTEX_LUATEX -DBUSYTEX_BIBTEX8
	$(CXX) $(CFLAGS_OPT_native) -o $@ $@.o -Wimplicit -Wreturn-type -Ibuild/native/texlive/libs/icu/include -Isource/fontconfig -export-dynamic    $(addprefix build/native/texlive/texk/web2c/, $(OBJ_LUATEX)) $(addprefix build/native/, $(OBJ_BIBTEX) $(OBJ_DVIPDF) $(OBJ_DEPS))  $(addprefix build/native/texlive/libs/, ) $(addprefix build/native/texlive/texk/kpathsea/, $(OBJ_KPATHSEA)) -ldl -lm -pthread
	
build/native/busytex: 
	mkdir -p $(dir $@)
	$(CC) -c busytex.c -o $@.o -DBUSYTEX_KPSEWHICH -DBUSYTEX_BIBTEX8 -DBUSYTEX_XDVIPDFMX -DBUSYTEX_XETEX  -DBUSYTEX_PDFTEX # -DBUSYTEX_LUATEX
	$(CXX) -Wl,--unresolved-symbols=ignore-all $(CFLAGS_OPT_native) -o $@ $@.o -Wimplicit -Wreturn-type  -export-dynamic    $(addprefix build/native/texlive/texk/web2c/, $(OBJ_XETEX) $(OBJ_PDFTEX)) $(addprefix build/native/, $(OBJ_BIBTEX) $(OBJ_DVIPDF) $(OBJ_DEPS)) $(addprefix -Ibuild/native/, $(CPATH_BUSYTEX)) $(addprefix build/native/texlive/texk/kpathsea/, $(OBJ_KPATHSEA)) -ldl -lm -pthread 
	#$(CXX) -Wl,--unresolved-symbols=ignore-all $(CFLAGS_OPT_native) -o $@ $@.o -Wimplicit -Wreturn-type  -export-dynamic    $(addprefix build/native/texlive/texk/web2c/, $(OBJ_XETEX) $(OBJ_PDFTEX) $(OBJ_LUATEX)) $(addprefix build/native/, $(OBJ_BIBTEX) $(OBJ_DVIPDF) $(OBJ_DEPS)) $(addprefix -Ibuild/native/, $(CPATH_BUSYTEX)) $(addprefix build/native/texlive/texk/kpathsea/, $(OBJ_KPATHSEA)) -ldl -lm -pthread 

################################################################################################################

build/wasm/texlive/texk/bibtex-x/busytex_bibtex8.a: build/wasm/texlive.configured
	$(MAKE_wasm) -C $(dir $@) $(OPTS_BIBTEX_wasm)
	$(AR_wasm) -crs $@ $(dir $@)/bibtex8-*.o

build/wasm/texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a: build/wasm/texlive.configured
	$(MAKE_wasm) -C $(dir $@) $(OPTS_XDVIPDFMX_wasm)
	$(AR_wasm) -crs $@ $(dir $@)/*.o

build/wasm/texlive/texk/web2c/busytex_libxetex.a: build/wasm/texlive.configured build/native/busytex
	# copying generated C files from native version, since string offsets are off
	mkdir -p $(dir $@)
	cp build/native/texlive/texk/web2c/*.c $(dir $@)
	$(MAKE_wasm) -C $(dir $@) synctexdir/xetex-synctex.o xetex $(OPTS_XETEX_wasm)
	mv $(dir $@)/libxetex.a $@

build/wasm/texlive/texk/web2c/busytex_libpdftex.a: build/wasm/texlive.configured build/native/busytex
	# copying generated C files from native version, since string offsets are off
	mkdir -p $(dir $@)
	cp build/native/texlive/texk/web2c/*.c $(dir $@)
	$(MAKE_wasm) -C $(dir $@) synctexdir/pdftex-synctex.o pdftex $(subst -Dmain=, -Dbusymain=, $(OPTS_PDFTEX_wasm))
	rm $(dir $@)/pdftexdir/pdftex-pdftexextra.o
	$(MAKE_wasm) -C $(dir $@) pdftexdir/pdftex-pdftexextra.o $(OPTS_PDFTEX_wasm)
	$(MAKE_wasm) -C $(dir $@) libpdftex.a $(OPTS_PDFTEX_wasm)
	mv $(dir $@)/libpdftex.a $@
	#cp build/native/texlive/texk/web2c/*.c $(dir $@)
	#$(MAKE_wasm) -C $(dir $@) synctexdir/pdftex-synctex.o pdftex $(OPTS_PDFTEX_wasm)

build/wasm/busytex.js: 
	mkdir -p $(dir $@)
	emcc -Wl,-error-limit=0 $(CFLAGS_OPT) -s TOTAL_MEMORY=$(TOTAL_MEMORY) -s EXIT_RUNTIME=0 -s INVOKE_RUN=0  -s ASSERTIONS=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s FORCE_FILESYSTEM=1 -s LZ4=1 -s MODULARIZE=1 -s EXPORT_NAME=$(notdir $(basename $@)) -s EXPORTED_FUNCTIONS='["_main", "_fflush", "_putchar", "_fopen", "_fputc", "_flush_streams"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS", "ENV", "allocateUTF8OnStack", "LZ4", "PATH"]' -o $@ -lm $(addprefix build/wasm/texlive/texk/web2c/, $(OBJ_XETEX)) $(addprefix build/wasm/, $(OBJ_DVIPDF) $(OBJ_BIBTEX) $(OBJ_DEPS)) $(addprefix -Ibuild/wasm/, $(CPATH_BUSYTEX)) $(addprefix build/wasm/texlive/texk/kpathsea/, $(OBJ_KPATHSEA)) -DBUSYTEX_KPSEWHICH -DBUSYTEX_BIBTEX8 -DBUSYTEX_XDVIPDFMX -DBUSYTEX_XETEX busytex.c
	#emcc -ferror-limit=0 $(CFLAGS_OPT) -s TOTAL_MEMORY=$(TOTAL_MEMORY) -s EXIT_RUNTIME=0 -s INVOKE_RUN=0  -s ASSERTIONS=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s FORCE_FILESYSTEM=1 -s LZ4=1 -s MODULARIZE=1 -s EXPORT_NAME=$(notdir $(basename $@)) -s EXPORTED_FUNCTIONS='["_main", "_fflush"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS", "ENV", "allocateUTF8OnStack", "LZ4", "PATH"]' -o $@ -lm $(addprefix build/wasm/texlive/texk/web2c/, $(OBJ_XETEX) $(OBJ_PDFTEX)) $(addprefix build/wasm/, $(OBJ_DVIPDF) $(OBJ_BIBTEX) $(OBJ_DEPS)) $(addprefix -Ibuild/wasm/, $(CPATH_BUSYTEX)) -DBUSYTEX_BIBTEX8 -DBUSYTEX_XDVIPDFMX -DBUSYTEX_XETEX -DBUSYTEX_PDFTEX busytex.c
	#$(CXX) -Wl,--unresolved-symbols=ignore-all $(CFLAGS_OPT_native) -o $@ $@.o -Wimplicit -Wreturn-type  -export-dynamic    $(addprefix build/native/texlive/texk/web2c/, $(OBJ_XETEX) $(OBJ_PDFTEX)) $(addprefix build/native/, $(OBJ_BIBTEX) $(OBJ_DVIPDF) $(OBJ_DEPS)) $(addprefix -Ibuild/native/, $(CPATH_BUSYTEX)) $(addprefix build/native/texlive/texk/kpathsea/, $(OBJ_KPATHSEA)) -ldl -lm -pthread 

################################################################################################################

source/texmfrepo/install-tl:
	mkdir -p source/texmfrepo
	wget --no-verbose --no-clobber $(URL_texlive_full_iso) -P source
	7z x source/$(notdir $(URL_texlive_full_iso)) -osource/texmfrepo
	rm source/$(notdir $(URL_texlive_full_iso))
	chmod +x ./source/texmfrepo/install-tl
	find source/texmfrepo > source/texmfrepo.txt

build/texlive-%.txt: source/texmfrepo/install-tl
	mkdir -p $(basename $@)
	echo selected_scheme scheme-$* > build/texlive-$*.profile
	echo TEXDIR $(ROOT)/$(basename $@) >> build/texlive-$*.profile
	echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-dist/texmf-local >> build/texlive-$*.profile
	echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-dist/texmf-var >> build/texlive-$*.profile
	echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-dist/texmf-config >> build/texlive-$*.profile
	#echo collection-xetex 1 >> build/texlive-$*.profile
	#echo TEXMFVAR $(ROOT)/$(basename $@)/home/texmf-var >> build/texlive-$*.profile
	TEXLIVE_INSTALL_NO_RESUME=1 strace -f -e trace=execve ./source/texmfrepo/install-tl --repository source/texmfrepo --profile build/texlive-$*.profile
	rm -rf $(addprefix $(basename $@)/, bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/doc texmf-var/web2c) || true
	find $(ROOT)/$(basename $@) > $@
	#find $(ROOT)/$(basename $@) -executable -type f -delete
	# grep 'texlive-basic/bin' 8_Install\ TexLive.txt | grep -v 'No such' | grep -oP 'execve\(".+?",' | sort | uniq

build/format-%/xelatex.fmt build/format-%/pdflatex.fmt: build/native/busytex build/texlive-%.txt 
	mkdir -p $(basename $@)
	rm $(basename $@)/* || true
	TEXINPUTS=build/texlive-basic/texmf-dist/source/latex/base TEXMFCNF=build/texlive-$*/texmf-dist/web2c TEXMFDIST=build/texlive-$*/texmf-dist $(BUSYTEX) $(subst latex.fmt,tex,$(notdir $@)) --interaction=nonstopmode --halt-on-error --output-directory=$(basename $@) -ini -etex unpack.ins
	TEXINPUTS=build/texlive-basic/texmf-dist/source/latex/base:build/texlive-basic/texmf-dist/tex/generic/unicode-data:build/texlive-basic/texmf-dist/tex/latex/base:build/texlive-basic/texmf-dist/tex/generic/hyphen:build/texlive-basic/texmf-dist/tex/latex/l3kernel:build/texlive-basic/texmf-dist/tex/latex/l3packages/xparse TEXMFCNF=build/texlive-$*/texmf-dist/web2c TEXMFDIST=build/texlive-$*/texmf-dist $(BUSYTEX) $(subst latex.fmt,tex,$(notdir $@)) --interaction=nonstopmode --halt-on-error --output-directory=$(basename $@) -ini -etex latex.ltx
	mv $(basename $@)/latex.fmt $@

build/format-%/lualatex.fmt: build/native/busytex build/texlive-%.txt
	mkdir -p $(basename $@)
	rm $(basename $@)/* || true
	TEXMFCNF=build/texlive-$*/texmf-dist/web2c TEXMFDIST=build/texlive-$*/texmf-dist $(BUSYTEX) $(subst latex.fmt,tex,$(notdir $@)) --interaction=nonstopmode --halt-on-error --output-directory=$(basename $@) -ini lualatex.ini
	mv $(basename $@)/lualatex.fmt $@

################################################################################################################

build/wasm/texlive-%.js: build/format-%/xelatex.fmt build/texlive-%/texmf-dist build/wasm/fonts.conf 
	mkdir -p $(dir $@)
	echo > build/empty
	echo 'web_user:x:0:0:emscripten:/home/web_user:/bin/false' > build/passwd
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		--preload build/passwd@/etc/passwd \
		--preload build/empty@/bin/busytex \
		--preload build/wasm/fonts.conf@/etc/fonts/fonts.conf \
		--preload build/texlive-$*@/texlive \
		--preload build/format-$*/xelatex.fmt@/xelatex.fmt

build/wasm/ubuntu-%.js: $(TEXMF_FULL)
	mkdir -p $(dir $@)
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data \
		--js-output=$@ \
		--export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		$(shell $(PYTHON) ubuntu_package_preload.py --texmf $(TEXMF_FULL) --url $(URL_UBUNTU_RELEASE) --skip-log $(basename $@).skipped.txt --package $*)

build/wasm/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>' > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' >> $@
	echo '<fontconfig>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/opentype</dir>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/type1</dir>' >> $@
	echo '</fontconfig>' >> $@

build/native/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>' > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' >> $@
	echo '<fontconfig>' >> $@
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/opentype</dir>
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/type1</dir>
	#<cachedir prefix="relative">./cache</cachedir>
	echo '</fontconfig>' >> $@

################################################################################################################


.PHONY: texlive
texlive:
	$(MAKE) source/texlive.downloaded source/texlive.patched

tds-%:
	$(MAKE) source/texmfrepo/install-tl
	$(MAKE) build/texlive-$*.txt
	$(MAKE) build/format-$*/xelatex.fmt
	$(MAKE) build/format-$*/pdflatex.fmt
	#$(MAKE) build/format-$*/lualatex.fmt

################################################################################################################

.PHONY: native
native:
	echo MAKE=$(MAKE) MAKEFLAGS=$(MAKEFLAGS)
	$(MAKE) $(MAKEFLAGS) build/native/texlive.configured
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/zziplib/libzzip.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/libpng/libpng.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/libpaper/libpaper.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/zlib/libz.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/teckit/libTECkit.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/harfbuzz/libharfbuzz.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/graphite2/libgraphite2.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/pplib/libpplib.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/lua53/.libs/libtexlua53.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/freetype2/libfreetype.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/xpdf/libxpdf.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/icu/icu-build/lib/libicuuc.a 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/icu/icu-build/lib/libicudata.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/icu/icu-build/bin/icupkg 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/libs/icu/icu-build/bin/pkgdata 
	$(MAKE) $(MAKEFLAGS) build/native/expat/libexpat.a
	$(MAKE) $(MAKEFLAGS) build/native/fontconfig/src/.libs/libfontconfig.a
	# 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/kpathsea/.libs/libkpathsea.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/web2c/lib/lib.a
	rm build/native/texlive/texk/kpathsea/kpsewhich.o || true
	$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/kpathsea/busytex_kpsewhich.o 
	$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/bibtex-x/busytex_bibtex8.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/web2c/busytex_libxetex.a
	$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/web2c/busytex_libpdftex.a
	#$(MAKE) $(MAKEFLAGS) build/native/texlive/texk/web2c/libluatex.a
	$(MAKE) $(MAKEFLAGS) build/native/busytex

.PHONY: wasm
wasm:
	$(MAKE) build/wasm/texlive.configured
	$(MAKE) build/wasm/texlive/libs/zziplib/libzzip.a
	$(MAKE) build/wasm/texlive/libs/libpng/libpng.a 
	$(MAKE) build/wasm/texlive/libs/libpaper/libpaper.a 
	$(MAKE) build/wasm/texlive/libs/zlib/libz.a 
	$(MAKE) build/wasm/texlive/libs/teckit/libTECkit.a 
	$(MAKE) build/wasm/texlive/libs/harfbuzz/libharfbuzz.a 
	$(MAKE) build/wasm/texlive/libs/graphite2/libgraphite2.a 
	$(MAKE) build/wasm/texlive/libs/pplib/libpplib.a 
	$(MAKE) build/wasm/texlive/libs/lua53/.libs/libtexlua53.a
	$(MAKE) build/wasm/texlive/libs/freetype2/libfreetype.a 
	$(MAKE) build/wasm/texlive/libs/xpdf/libxpdf.a
	$(MAKE) build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a 
	$(MAKE) build/wasm/texlive/libs/icu/icu-build/lib/libicudata.a
	$(MAKE) build/wasm/expat/libexpat.a
	$(MAKE) build/wasm/fontconfig/src/.libs/libfontconfig.a
	#
	$(MAKE) build/wasm/texlive/texk/kpathsea/.libs/libkpathsea.a
	$(MAKE) build/wasm/texlive/texk/web2c/lib/lib.a
	rm build/wasm/texlive/texk/kpathsea/kpsewhich.o || true
	$(MAKE) build/wasm/texlive/texk/kpathsea/busytex_kpsewhich.o 
	$(MAKE) build/wasm/texlive/texk/bibtex-x/busytex_bibtex8.a
	$(MAKE) build/wasm/texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a
	$(MAKE) build/wasm/texlive/texk/web2c/busytex_libxetex.a
	$(MAKE) build/wasm/texlive/texk/web2c/busytex_libpdftex.a
	#$(MAKE) build/wasm/texlive/texk/web2c/libluatex.a
	$(MAKE) build/wasm/busytex.js

.PHONY: ubuntu-wasm
ubuntu-wasm: build/wasm/ubuntu-texlive-latex-base.js build/wasm/ubuntu-texlive-latex-extra.js build/wasm/ubuntu-texlive-latex-recommended.js build/wasm/ubuntu-texlive-science.js

################################################################################################################

.PHONY: example
example:
	mkdir -p example/assets/large
	echo "console.log('Hello world now')" > example/assets/test.txt
	wget --no-clobber -O example/assets/test.png https://www.google.fr/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png
	wget --no-clobber -O example/assets/test.svg https://upload.wikimedia.org/wikipedia/commons/c/c3/Flag_of_France.svg
	wget --no-clobber -O example/assets/large/test.pdf https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf

build/versions.txt:
	mkdir -p build
	echo 'busytex dependencies:' > $@
	echo texlive: \\url{$(URL_texlive)} \\url{$(URL_texlive_full_iso)} >> $@
	echo ubuntu packages: \\url{$(URL_UBUNTU_RELEASE)} >> $@
	echo expat: \\url{$(URL_expat)} >> $@
	echo fontconfig: \\url{$(URL_fontconfig)} >> $@
	echo emscripten: $(EMSCRIPTEN_VERSION) >> $@

################################################################################################################

.PHONY: clean_tds
clean_tds:
	rm -rf build/texlive-*

.PHONY: clean_native
clean_native:
	rm -rf build/native

.PHONY: clean_wasm
clean_wasm:
	rm -rf build/wasm

.PHONY: clean_format
clean_format:
	rm -rf build/format-*

.PHONY: clean_dist
clean_dist:
	rm -rf dist-wasm dist-native

.PHONY: clean_build
clean_build:
	rm -rf build

.PHONY: clean_example
clean_example:
	rm -rf example/*.aux example/*.bbl example/*.blg example/*.log example/*.xdv

.PHONY: clean
clean:
	rm -rf build source

################################################################################################################

.PHONY: dist-wasm
dist-wasm:
	mkdir -p $@
	cp build/wasm/busytex.js build/wasm/busytex.wasm $@ || true
	cp build/wasm/texlive-basic.js build/wasm/texlive-basic.data $@ || true
	cp build/wasm/ubuntu-*.js build/wasm/ubuntu-*.data $@ || true

.PHONY: dist-native
dist-native: build/native/busytex build/native/fonts.conf
	mkdir -p $@
	cp $(addprefix build/native/, busytex fonts.conf ../format-basic/xelatex.fmt ../format-basic/pdflatex.fmt ../format-basic/lualatex.fmt) $@ || true
	cp -r build/texlive-basic $@/texlive || true

.PHONY: dist
dist:
	mkdir -p $@
	wget -P dist --no-clobber $(addprefix $(URL_RELEASE)/, busytex.wasm busytex.js texlive-basic.js texlive-basic.data)
