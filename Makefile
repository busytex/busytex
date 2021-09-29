# http://www.linuxfromscratch.org/blfs/view/svn/pst/texlive.html
# https://www.tug.org/texlive//devsrc/Master/texmf-dist/tex/latex/

URL_texlive_full_iso = http://mirrors.ctan.org/systems/texlive/Images/texlive2021-20210325.iso
URL_texlive          = https://github.com/TeX-Live/texlive-source/archive/refs/heads/tags/texlive-2021.2.tar.gz
URL_expat            = https://github.com/libexpat/libexpat/releases/download/R_2_4_1/expat-2.4.1.tar.gz
URL_fontconfig       = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.93.tar.gz
URL_UBUNTU_RELEASE   = https://packages.ubuntu.com/groovy/

TOTAL_MEMORY      = 536870912
CFLAGS_OPT_native = -O3
CFLAGS_OPT_wasm   = -Oz

ROOT         := $(CURDIR)
EMROOT       := $(dir $(shell which emcc))

BUSYTEX_native= $(abspath build/native/busytex)
TEXMF_FULL    = $(abspath build/texlive-full)
PREFIX_wasm   = $(abspath build/wasm/prefix)
PREFIX_native = $(abspath build/native/prefix)

#BINARCH_native =bin/x86_64-linux
BINARCH_native =bin/_custom

PYTHON        = python3
MAKE_wasm     = emmake $(MAKE)
CMAKE_wasm    = emcmake cmake
CONFIGURE_wasm= $(EMROOT)/emconfigure
AR_wasm       = emar
CC_wasm       = emcc
CXX_wasm      = em++
NM_wasm       = $(EMROOT)/../bin/llvm-nm
CC_native     = $(CC)
CXX_native    = $(CXX)
MAKE_native   = $(MAKE)
CMAKE_native  = cmake
AR_native     = $(AR)
NM_native     = nm
LDD_native    = ldd

CACHE_TEXLIVE_native    = $(abspath build/native-texlive.cache)
CACHE_TEXLIVE_wasm      = $(abspath build/wasm-texlive.cache)
CACHE_FONTCONFIG_native = $(abspath build/native-fontconfig.cache)
CACHE_FONTCONFIG_wasm   = $(abspath build/wasm-fontconfig.cache)
CONFIGSITE_BUSYTEX      = $(abspath busytex.site)

CPATH_BUSYTEX = texlive/libs/icu/include fontconfig

##############################################################################################################################

#OBJ_LUAHBTEX = luatexdir/luahbtex-luatex.o luatexdir/luatex-luatex.o    mplibdir/luahbtex-lmplib.o mplibdir/luatex-lmplib.o    libluahbtexspecific.a libluatexspecific.a     libluaharfbuzz.a  busytex_libluahbtex.a busytex_libluatex.a   libff.a libluamisc.a libluasocket.a libluaffi.a libmplibcore.a libmputil.a libunilib.a libmd5.a lib/lib.a
OBJ_LUAHBTEX  = luatexdir/luahbtex-luatex.o mplibdir/luahbtex-lmplib.o libluahbtexspecific.a libluaharfbuzz.a  busytex_libluahbtex.a libff.a libluamisc.a libluasocket.a libluaffi.a libmplibcore.a libmputil.a libunilib.a libmd5.a lib/lib.a
OBJ_LUATEX    = luatexdir/luatex-luatex.o   mplibdir/luatex-lmplib.o  libluatexspecific.a                     busytex_libluatex.a libff.a libluamisc.a libluasocket.a libluaffi.a libmplibcore.a libmputil.a libunilib.a libmd5.a lib/lib.a 
OBJ_PDFTEX    = synctexdir/pdftex-synctex.o pdftex-pdftexini.o pdftex-pdftex0.o pdftex-pdftex-pool.o pdftexdir/pdftex-pdftexextra.o lib/lib.a libmd5.a busytex_libpdftex.a
OBJ_XETEX     = synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o xetexdir/xetex-xetexextra.o lib/lib.a libmd5.a busytex_libxetex.a
OBJ_DVIPDF    = texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a
OBJ_MAKEINDEX = texlive/texk/makeindexk/busytex_makeindex.a
OBJ_BIBTEX    = texlive/texk/bibtex-x/busytex_bibtex8.a
OBJ_KPATHSEA  = busytex_kpsewhich.o busytex_kpsestat.o busytex_kpseaccess.o busytex_kpsereadlink.o .libs/libkpathsea.a
 
OBJ_DEPS      = $(addprefix texlive/libs/, harfbuzz/libharfbuzz.a graphite2/libgraphite2.a teckit/libTECkit.a libpng/libpng.a) fontconfig/src/.libs/libfontconfig.a $(addprefix texlive/libs/, freetype2/libfreetype.a pplib/libpplib.a zlib/libz.a zziplib/libzzip.a libpaper/libpaper.a icu/icu-build/lib/libicuuc.a icu/icu-build/lib/libicudata.a lua53/.libs/libtexlua53.a xpdf/libxpdf.a) texlive/texk/kpathsea/.libs/libkpathsea.a expat/libexpat.a

OBJ_DEPS_XETEX= fontconfig/src/.libs/libfontconfig.a $(addprefix texlive/libs/, icu/icu-build/lib/libicuuc.a icu/icu-build/lib/libicudata.a) 


##############################################################################################################################

# redefines needed until wasm-ld supports --localize-hidden: https://bugs.llvm.org/show_bug.cgi?id=51279

PDFTEX_EXTERN =   namelength nameoffile

BIBTEX_REDEFINE = initialize eoln last history bad xchr buffer close_file usage      make_string str_eq_buf str_eq_str str_ptr char_width   hash_used log_file

SYNCTEX_REDEFINE = synctex_ctxt synctex_dot_open synctex_record_node_char synctex_record_node_kern synctex_record_node_math synctex_record_node_unknown synctexabort synctexchar synctexcurrent synctexhlist synctexhorizontalruleorglue synctexinitcommand synctexkern synctexmath synctexmrofxfdp synctexnode synctexoption synctexpdfrefxform synctexpdfxform synctexsheet synctexstartinput synctexteehs synctexterminate synctextsilh synctextsilv synctexvlist synctexvoidhlist synctexvoidvlist

PDFTEX_REDEFINE = initialize getstringsstarted sortavail zprimitive znewtrieop ztrienode zcompresstrie zfirstfit ztriepack ztriefix newpatterns inittrie zlinebreak newhyphexceptions zdomarks prefixedcommand storefmtfile loadfmtfile finalcleanup initprim mainbody println zprintchar zprint zprintnl zprintesc zprintthedigs zprintint zprintcs zsprintcs zprintfilename zprintsize zprintwritewhatsit zprintsanum zprintcsnames printfileline initterminal zstreqbuf zstreqstr zsearchstring zprinttwo zprinthex zprintromanint printcurrentstring zhalf zrounddecimals zprintscaled zmultandadd zxovern zxnoverd zbadness zmakefrac ztakefrac zabvscd newrandoms zinitrandoms zunifrand zshowtokenlist runaway zflushlist zfreenode zroundxnoverd zprevrightmost zflushstr getmicrointerval zshortdisplay zprintfontandchar zprintmark zprintruledimen zprintglue zprintspec zprintfamandchar zprintdelimiter zprintstyle zprintskipparam zdeletetokenref zdeleteglueref zprintmode zprintinmode popnest zprintparam begindiagnostic zenddiagnostic zprintlengthparam zprintcmdchr zprintgroup zgrouptrace pseudoclose zdeletesaref ztokenshow printmeaning showcurcmdchr showcontext groupwarning ifwarning filewarning endfilereading clearforerrorprompt zeffectivechar zaddorsub zquotient zfract beginname zpackfilename zpackbufferedname zpackjobname zeffectivecharinfo zprunemovements zshortdisplayn zcharpw zheightplusdepth zmathkern popalignment showsavegroups printtotals zfreezepagespecs youcant znormmin trapzeroglue newinteraction giveerrhelp openfmtfile closefilesandterminate zdvifour preparemag dviswap zdvifontdef zfatalerror zoverflow jumpout normalizeselector error makestring slowmakestring getavail zgetnode newnullbox zcharbox zstackintobox zvardelimiter zmakeleftright newrule znewmath znewspec znewparamglue znewglue zappendtovlist znewkern znewpenalty znewindex newnoad indentinhmode zmathglue pushalignment znewwhatsit zfractionrule fixlanguage appenditaliccorrection znewskipparam appspace pushnest zidlookup zprimlookup pseudoinput znewsavelevel zeqsave zbegintokenlist beginfilereading zstrtoks insertsrcspecial appendsrcspecial zmorename endname znewedge znewstyle newchoice znewligature znewligitem newdisc zsasave zfindsaelement zsaveforafter makenamestring zamakenamestring zzwmakenamestring zbmakenamestring zpromptfilename terminput openlogfile firmuptheline zdvipop zmovement zspecialout getnext checkoutervalidity endtokenlist gettoken zinterror pauseforinstructions zreconstitute backinput insertrelax inserror initcol zmlog backerror muerror zcharwarning znewcharacter zfetch zmakeord zfiniteshrink reportillegalcase extrarightbrace noalignerror omiterror cserror mathlimitswitch insertdollarsign offsave headforvmode alignerror zeTeXenabled normrand privileged passtext getrtoken macrocall zreadtoks zpushmath zconfusion zflushnodelist zsadestroy zeqdestroy flushmath hyphenate zcopynodelist zchangeiflimit zzreverse zmakevcenter zprunepagetop zvertbreak deletelast zjustcopy zjustreverse zfinmlist zpdferror ztokenstostring zshownodelist zprintsubsidiarydata zshowbox zvpackage zoverbar zvsplit zshoweqtb zrestoretrace zeqdefine zeqworddefine normalparagraph zinitspan initrow endgraf starteqno zgeqdefine zgeqworddefine zshowsa zsadef zsawdef zgsadef zgsawdef sarestore unsave showinfo zboxerror showactivities zensurevbox zreadfontinfo znewmarginkern zpushnode zfindprotcharleft popnode zhpack zrebox zcleanbox mlisttohlist zmakescripts zmakeover zmakeunder zmakeradical zmakemathaccent zmakefraction zmakeop zappdisplay zfindprotcharright ztotalpw ztrybreak zpostlinebreak scanfilenamebraced scanfilename getxtoken expand startinput thetoks conditional convtoks scanregisternum pseudostart zscankeyword xtoken getxorprotected fincol doassignments scanoptionalequals zsetmathchar scanleftbrace scangeneraltext appenddiscretionary builddiscretionary appendchoices buildchoices shiftcase scanfontident scanint zfindfontdimen zscansomethinginternal scancharnum zscanglue scanexpr scaneightbitint begininsertoradjust scanfourbitint scanfifteenbitint unpackage scanfourbitintor18 alterprevgraf alterinteger znewwritewhatsit makeaccent zscanmath subsup mathac mathradical zscandimen scannormalglue scanmuglue appendglue getpreambletoken appendkern insthetoks showwhatever zscantoks comparestrings zwriteout zoutwhat vlistout hlistout zshipout zfireup buildpage itsallover znewgraf appendpenalty initmath resumeafterdisplay aftermath finalign alignpeek finrow doendv zboxend zpackage handlerightbrace makemark issuemessage scanpdfexttoks scanrulespec zscanspec zbeginbox zscanbox zdoregistercommand alterpagesofar alterboxdimen initalign zscandelimiter mathfraction mathleftright alteraux znewfont openorclosein doextension maincontrol getnullstr loadpoolstrings generic_synctex_get_current_name runsystem texmf_yesno maininit topenin ipcpage open_in_or_pipe open_out_or_pipe close_file_or_pipe init_start_time get_date_and_time get_seconds_and_micros input_line calledit do_dump do_undump makefullnamestring getjobname gettexstring isnewsource remembersourceinfo makesrcspecial initstarttime find_input_file getcreationdate getfilemoddate getfilesize getfiledump convertStringToHexString getmd5sum pdftex_fail maketexstring initversionstring fixdateandtime     shellenabledp restrictedshell argv argc interactionoption dump_name filelineerrorstylep parsefirstlinep translate_filename default_translate_filename readyalready etexp TEXformatdefault formatdefaultlength outputcomment dumpoption insertsrcspecialauto insertsrcspecialeverypar srcspecialsp dumpline buffer first last strstart outputfilename strpool xchr interrupt bufsize maxbufstack inputptr inputstack inopen inputfile poolptr poolsize start_time_str   iniversion mltexp              insertsrcspecialeveryparend insertsrcspecialeverycr insertsrcspecialeverymath insertsrcspecialeveryhbox insertsrcspecialeveryvbox insertsrcspecialeverydisplay bad bounddefault boundname membot mainmemory extramembot memmin memtop extramemtop memmax errorline halferrorline maxprintline maxstrings stringsfree stringvacancies poolfree fontmemsize fontmax fontk hyphsize triesize stacksize maxinopen paramsize nestsize savesize dvibufsize expanddepth eightbitp haltonerrorp quotedfilename strptr initpoolptr initstrptr poolfile logfile selector dig tally termoffset fileoffset trickbuf trickcount firstcount interaction deletionsallowed setboxallowed history errorcount helpline helpptr useerrhelp OKtointerrupt aritherror texremainder randoms jrandom randomseed twotothe speclog tempptr yzmem zmem lomemmax himemmin varused dynused avail memend rover fontinshortdisplay depththreshold breadthmax nest nestptr maxneststack curlist shownmode oldsetting systime sysday sysmonth sysyear zeqtb zzzaa zzzab hash yhash hashused hashextra hashtop eqtbtop hashhigh nonewcontrolsequence cscount prim primused savestack saveptr maxsavestack curlevel curgroup curboundary magset curcmd curchr curcs curtok maxinstack curinput openparens line linestack sourcefilenamestack fullsourcefilenamestack scannerstatus warningindex defref paramstack paramptr maxparamstack alignstate baseptr parloc partoken forceeof isincsname curmark longstate pstack curval curvallevel radix curorder readfile readopen condptr iflimit curif ifline skipline curname curarea curext areadelimiter extdelimiter nameinprogress jobname logopened dvifile texmflogname tfmfile fontinfo fmemptr fontptr fontcheck fontsize fontdsize fontparams fontname fontarea fontbc fontec fontglue fontused hyphenchar skewchar bcharlabel fontbchar fontfalsebchar charbase widthbase heightbase depthbase italicbase ligkernbase kernbase extenbase parambase nullcharacter totalpages maxv maxh maxpush lastbop deadcycles doingleaders             discwidth bestplline bestplace minimaldemerits breakwidth background curactivewidth activewidth hliststack totalshrink totalstretch readopen readfile pstack curmark prim zzzaa speclog twotothe randoms helpline trickbuf dig xord dvibuf halfbuf dvilimit dviptr dvioffset dvigone downptr rightptr dvih dviv curh curv dvif curs epochseconds microseconds totalstretch totalshrink lastbadness adjusttail lastleftmostchar lastrightmostchar hliststack hliststacklevel preadjusttail packbeginline emptyfield nulldelimiter curmlist curstyle cursize curmu mlistpenalties curf curc curi magicoffset curalign curspan curloop alignptr curhead curtail curprehead curpretail justbox passive printednode passnumber activewidth curactivewidth background breakwidth firstp noshrinkerroryet curp secondpass finalpass threshold minimaldemerits minimumdemerits bestplace bestplline discwidth easyline lastspecialline firstwidth secondwidth firstindent secondindent bestbet fewestdemerits bestline actuallooseness linediff       trieused trieoplang trieopval trieopptr maxopused smallop triec trieo triel trier trieptr triehash trietaken triemin triemax trienotready bestheightplusdepth pagetail pagecontents pagemaxdepth bestpagebreak leastpagecost bestsize pagesofar lastglue lastpenalty lastkern lastnodetype insertpenalties outputactive mainf maini mainj maink mainp mains bchar falsebchar cancelboundary insdisc curbox aftertoken longhelpseen formatident fmtfile writefile writeopen writeloc pdflastxpos pdflastypos curpagewidth curpageheight curhoffset curvoffset eTeXmode eofseen LRptr LRproblems curdir pseudofiles grpstack ifstack maxregnum maxreghelpline saroot curptr sanull sachain salevel lastlinefill dolastlinefit activenodesize fillwidth bestplshort bestplglue hyphstart hyphindex discptr editnamestart editnamelength editline ipcon stopatspace savestrptr savepoolptr     debugformatfile expanddepthcount mltexenabledp accentc basec replacec baseslant accentslant basexheight basewidth baseheight accentwidth accentheight delta synctexoffset xord discptr bestplglue bestplshort fillwidth saroot pagesofar triemin trieopval trieoplang trieused opstart hyfnext hyfnum hyfdistance    initlhyf initrhyf hyfbchar hyf initlist initlig initlft hyphenpassed curl curr curq ligstack ligaturepresent lfthit rthit trietrl trietro trietrc hyfdistance hyfnum hyfnext opstart hyphword hyphlist hyphlink hyphcount   ruleht ruledp rulewd hyfchar curlang initcurlang     lq lr  hc hn ha hb hf hu    iac ibc    hyf   c f g k l t      writefile       lhyf rhyf hyphnext writeopen    lhyf rhyf hyphnext   writeopen     t1_line_array t1_free get_fe_entry enc_free  fe_tree t1_buf_array load_enc_file t1_line_ptr t1_length3 t1_encoding t1_length1 t1_buf_limit t1_buf_ptr t1_line_limit t1_length2

LUATEX_REDEFINE = init_start_time topenin get_date_and_time get_seconds_and_micros input_line getjobname err runaway unpackage privileged initialize maketexstring makecstring open_in_or_pipe open_out_or_pipe close_file_or_pipe new_fm_entry delete_fm_entry avl_do_entry mitem check_std_t1font pdfmapfile pdfmapline check_ff_exist is_subsetable fm_free glyph_unicode_free write_tounicode zip_free pdf_printf convertStringToPDFString getcreationdate matrixused getllx getlly geturx getury matrixtransformrect matrixtransformpoint matrixrecalculate libpdffinish conditional unsave expand fd_tree  fo_tree  new_fd_entry lookup_fd_entry register_fd_entry get_unsigned_byte get_unsigned_pair read_jbig2_info write_jbig2 read_jpg_info write_jpg read_png_info write_png colorstackused newcolorstack colorstackcurrent colorstackpop colorstackskippagestart ttf_free writettf writeotf read_pdf_info write_epdf epdf_free make_subset_tag tex_printf xfwrite xfflush xgetc xputc initversionstring char_array selector strstart strstart error notdef mac_glyph_names ambiguous_names cur_file_name t3_line_array     t3_file t3_line_ptr t3_line_limit ttf_length first last buffer epochseconds microseconds     argc argv dump_name interaction interactionoption history interrupt pstack synctexoffset shellenabledp restrictedshell line parsefirstlinep filelineerrorstylep haltonerrorp nest radix hash rover avail char_ptr char_limit tally dig    g nameoffile namelength   write_fontencodings writet1              mk_shellcmdlist get_start_time set_start_time init_shell_escape shell_cmd_is_allowed normalize_quotes getrandomseed luatex_revision engine_name luatex_version_string luaopen_mplib luatex_version   c_job_name luatex_banner

DVIPDFMX_REDEFINE = cff_stdstr agl_chop_suffix agl_sput_UTF16BE agl_get_unicodes agl_name_is_unicode agl_name_convert_unicode agl_suffix_to_otltag agl_lookup_list agl_select_listfile agl_init_map agl_close_map bmp_include_image check_for_bmp bmp_get_bbox cff_open cff_close cff_put_header cff_get_index cff_get_index_header cff_release_index cff_new_index cff_index_size cff_pack_index cff_get_name cff_set_name cff_read_subrs cff_read_encoding cff_pack_encoding cff_encoding_lookup cff_release_encoding cff_read_charsets cff_pack_charsets cff_glyph_lookup cff_get_glyphname cff_charsets_lookup cff_charsets_lookup_gid cff_release_charsets cff_charsets_lookup_inverse cff_read_fdselect cff_pack_fdselect cff_fdselect_lookup cff_release_fdselect cff_read_fdarray cff_read_private cff_get_string cff_get_sid cff_get_seac_sid cff_add_string cff_update_string cff_new_dict cff_release_dict cff_dict_set cff_dict_get cff_dict_add cff_dict_remove cff_dict_known cff_dict_unpack cff_dict_pack cff_dict_update CIDFont_require_version CIDFont_set_flags CIDFont_get_fontname CIDFont_get_ident CIDFont_get_opt_index CIDFont_get_flag CIDFont_get_subtype CIDFont_get_embedding CIDFont_get_resource CIDFont_get_CIDSysInfo CIDFont_attach_parent CIDFont_get_parent_id CIDFont_is_BaseFont CIDFont_is_ACCFont CIDFont_is_UCSFont CIDFont_cache_find CIDFont_cache_get CIDFont_cache_close CIDFont_type0_set_flags CIDFont_type0_open CIDFont_type0_dofont t1_load_UnicodeCMap CIDFont_type0_t1dofont CIDFont_type0_t1cdofont CIDFont_type2_set_flags CIDFont_type2_open CIDFont_type2_dofont CMap_set_silent CMap_new CMap_release CMap_is_valid CMap_is_Identity CMap_get_profile CMap_get_name CMap_get_type CMap_set_name CMap_set_type CMap_set_wmode CMap_set_CIDSysInfo CMap_add_bfchar CMap_add_cidchar CMap_add_bfrange CMap_add_notdefchar CMap_add_notdefrange CMap_add_codespacerange CMap_decode_char CMap_decode CMap_cache_init CMap_cache_get CMap_cache_find CMap_cache_close CMap_cache_add CMap_parse_check_sig CMap_parse CMap_create_stream CMap_ToCode_stream cs_copy_charstring dumppaperinfo dpx_open_file dpx_find_type1_file dpx_find_truetype_file dpx_find_opentype_file dpx_find_dfont_file dpx_file_apply_filter dpx_create_temp_file dpx_create_fix_temp_file dpx_delete_old_cache dpx_delete_temp_file dpx_util_read_length dpx_util_get_unique_time_if_given dpx_util_format_asn_date skip_white_spaces xtoi dpx_stack_init dpx_stack_pop dpx_stack_push dpx_stack_depth dpx_stack_top dpx_stack_at dpx_stack_roll ht_init_table ht_clear_table ht_table_size ht_lookup_table ht_append_table ht_remove_table ht_insert_table ht_set_iter ht_clear_iter ht_iter_getkey ht_iter_getval ht_iter_next parse_float_decimal parse_c_string parse_c_ident get_origin dvi_init dvi_close dvi_tell_mag dvi_unit_size dvi_dev_xpos dvi_dev_ypos dvi_npages dvi_comment dvi_vf_init dvi_vf_finish dvi_set_font dvi_set dvi_rule dvi_right dvi_put dvi_push dvi_pop dvi_w0 dvi_w dvi_x0 dvi_x dvi_down dvi_y dvi_y0 dvi_z dvi_z0 dvi_do_page dvi_scan_specials dvi_locate_font dvi_link_annot dvi_set_linkmode dvi_set_phantom_height dvi_tag_depth dvi_untag_depth dvi_compute_boxes dvi_do_special dvi_set_compensation pdf_copy_clip pdf_include_page error_cleanup shut_up ERROR MESG WARN pdf_init_fontmaps pdf_clear_fontmaps pdf_close_fontmaps pdf_init_fontmap_record pdf_clear_fontmap_record pdf_load_fontmap_file pdf_read_fontmap_line pdf_append_fontmap_record pdf_remove_fontmap_record pdf_insert_fontmap_record pdf_lookup_fontmap_record is_pdfm_mapline pdf_insert_native_fontmap_record check_for_jp2 jp2_include_image jp2_get_bbox check_for_jpeg jpeg_include_image jpeg_get_bbox new renew seek_absolute seek_relative seek_end tell_position file_size xfile_size mfgets mfreadln mps_set_translate_origin mps_scan_bbox mps_include_page mps_exec_inline mps_stack_depth mps_eop_cleanup mps_do_page get_unsigned_byte skip_bytes get_signed_byte get_unsigned_pair sget_unsigned_pair get_signed_pair get_unsigned_triple get_signed_triple get_signed_quad get_unsigned_quad get_unsigned_num get_positive_quad sqxfw otl_new_opt otl_release_opt otl_parse_optstring otl_match_optrule pdf_color_rgbcolor pdf_color_cmykcolor pdf_color_graycolor pdf_color_spotcolor pdf_color_copycolor pdf_color_brighten_color pdf_color_type pdf_color_compare pdf_color_set_color pdf_color_is_white iccp_get_rendering_intent iccp_check_colorspace iccp_load_profile pdf_init_colors pdf_close_colors pdf_get_colorspace_reference pdf_get_colorspace_num_components pdf_get_colorspace_subtype pdf_colorspace_load_ICCBased pdf_color_set pdf_color_push pdf_color_pop pdf_color_clear_stack pdf_color_get_current transform_info_clear pdf_sprint_matrix pdf_sprint_rect pdf_sprint_coord pdf_sprint_length pdf_sprint_number pdf_init_device pdf_close_device dev_unit_dviunit pdf_dev_set_string pdf_dev_set_rule pdf_dev_put_image pdf_dev_locate_font pdf_dev_get_font_wmode this pdf_dev_get_dirmode pdf_dev_set_dirmode pdf_dev_set_rect pdf_dev_get_param pdf_dev_set_param pdf_dev_reset_fonts pdf_dev_reset_color pdf_dev_bop pdf_dev_eop graphics_mode pdf_dev_begin_actualtext pdf_dev_end_actualtext pdf_open_document pdf_doc_set_pagelabel pdf_dev_init_gstates pdf_dev_clear_gstates pdf_dev_currentmatrix pdf_dev_currentpoint pdf_dev_setlinewidth pdf_dev_setmiterlimit pdf_dev_setlinecap pdf_dev_setlinejoin pdf_dev_setdash pdf_dev_setflat pdf_dev_moveto pdf_dev_rmoveto pdf_dev_closepath pdf_dev_lineto pdf_dev_rlineto pdf_dev_curveto pdf_dev_rcurveto pdf_dev_arc pdf_dev_arcn pdf_dev_newpath pdf_dev_clip pdf_dev_eoclip pdf_dev_rectstroke pdf_dev_rectfill pdf_dev_rectclip pdf_dev_flushpath pdf_dev_concat pdf_dev_dtransform pdf_dev_idtransform pdf_dev_transform pdf_dev_itransform pdf_dev_gsave pdf_dev_grestore pdf_dev_push_gstate pdf_dev_pop_gstate pdf_dev_arcx pdf_dev_bspline pdf_invertmatrix pdf_dev_current_depth pdf_dev_grestore_to pdf_dev_currentcolor pdf_dev_set_fixed_point pdf_dev_get_fixed_point pdf_dev_set_color pdf_dev_xgstate_push pdf_dev_xgstate_pop pdf_dev_reset_xgstate pdf_init_encodings pdf_close_encodings pdf_encoding_complete pdf_encoding_findresource pdf_get_encoding_obj pdf_encoding_is_predefined pdf_encoding_used_by_type3 pdf_encoding_get_name pdf_encoding_get_encoding pdf_create_ToUnicode_CMap pdf_encoding_add_usedchars pdf_encoding_get_tounicode pdf_load_ToUnicode_stream pdf_enc_init pdf_enc_close pdf_enc_set_label pdf_enc_set_generation pdf_encrypt_data pdf_enc_get_encrypt_dict pdf_enc_get_extension_dict pdf_font_set_dpi pdf_init_fonts pdf_close_fonts pdf_font_findresource pdf_get_font_subtype pdf_get_font_reference pdf_get_font_usedchars pdf_get_font_fontname pdf_get_font_encoding pdf_get_font_wmode pdf_font_is_in_use pdf_font_get_ident pdf_font_get_mapname pdf_font_get_fontname pdf_font_get_uniqueTag pdf_font_get_resource pdf_font_get_descriptor pdf_font_get_usedchars pdf_font_get_encoding pdf_font_get_flag pdf_font_get_flags pdf_font_get_param pdf_font_get_index pdf_font_set_fontname pdf_font_set_flags pdf_font_set_subtype pdf_font_make_uniqueTag pdf_new_name_tree pdf_delete_name_tree pdf_names_add_object pdf_names_lookup_reference pdf_names_lookup_object pdf_names_close_object pdf_names_reserve pdf_names_create_tree pdf_error_cleanup pdf_get_output_file pdf_out_init pdf_out_set_encrypt pdf_out_flush pdf_get_version pdf_get_version_major pdf_get_version_minor pdf_release_obj pdf_obj_typeof pdf_ref_obj pdf_link_obj pdf_transfer_label pdf_new_undefined pdf_new_null pdf_new_boolean pdf_boolean_value pdf_new_number pdf_set_number pdf_number_value pdf_new_string pdf_set_string pdf_string_value pdf_string_length pdf_new_name pdf_name_value pdf_new_array pdf_add_array pdf_put_array pdf_get_array pdf_array_length pdf_shift_array pdf_pop_array pdf_new_dict pdf_remove_dict pdf_merge_dict pdf_lookup_dict pdf_dict_keys pdf_add_dict pdf_put_dict pdf_foreach_dict pdf_new_stream pdf_add_stream pdf_concat_stream pdf_stream_dict pdf_stream_length pdf_stream_set_flags pdf_stream_get_flags pdf_stream_dataptr pdf_stream_set_predictor pdf_compare_reference pdf_compare_object pdf_set_info pdf_set_root pdf_files_init pdf_files_close check_for_pdf pdf_open pdf_close pdf_file_get_trailer pdf_file_get_catalog pdf_file_get_version pdf_deref_obj pdf_import_object pdfobj_escape_str pdf_new_indirect pdf_check_version dump pdfparse_skip_line skip_white parse_number parse_unsigned parse_ident parse_val_ident parse_opt_ident parse_pdf_name parse_pdf_boolean parse_pdf_number parse_pdf_null parse_pdf_string parse_pdf_dict parse_pdf_array parse_pdf_object parse_pdf_object_extended parse_pdf_tainted_dict pdf_init_resources pdf_close_resources pdf_defineresource pdf_findresource pdf_resource_exist pdf_get_resource_reference pdf_get_resource pdf_init_images pdf_close_images pdf_ximage_get_resname pdf_ximage_get_reference pdf_ximage_findresource pdf_ximage_load_image pdf_ximage_defineresource pdf_ximage_reserve pdf_ximage_init_image_info pdf_ximage_init_form_info pdf_ximage_set_image pdf_ximage_set_form pdf_ximage_get_page set_distiller_template get_distiller_template pdf_ximage_get_subtype pdf_error_cleanup_cache pdf_font_open_pkfont pdf_font_load_pkfont png_include_image check_for_png png_get_bbox pst_get_token pst_new_obj pst_new_mark pst_type_of pst_length_of pst_getIV pst_getRV pst_getSV pst_data_ptr pst_parse_null pst_parse_name pst_parse_number pst_parse_string put_big_endian sfnt_open dfont_open sfnt_close sfnt_read_table_directory sfnt_find_table_len sfnt_find_table_pos sfnt_locate_table sfnt_set_table sfnt_require_table sfnt_create_FontFile_stream spc_color_check_special spc_color_setup_handler spc_dvipdfmx_check_special spc_dvipdfmx_setup_handler spc_dvips_at_begin_document spc_dvips_at_end_document spc_dvips_at_begin_page spc_dvips_at_end_page spc_dvips_check_special spc_dvips_setup_handler spc_html_at_begin_page spc_html_at_end_page spc_html_at_begin_document spc_html_at_end_document spc_html_check_special spc_html_setup_handler spc_misc_check_special spc_misc_setup_handler spc_pdfm_at_begin_document spc_pdfm_at_end_document spc_pdfm_at_end_page spc_pdfm_check_special spc_pdfm_setup_handler tpic_set_fill_mode spc_tpic_at_begin_page spc_tpic_at_end_page spc_tpic_at_begin_document spc_tpic_at_end_document spc_tpic_check_special spc_tpic_setup_handler spc_util_read_colorspec spc_util_read_dimtrns spc_util_read_blahblah spc_util_read_numbers spc_util_read_pdfcolor spc_xtx_check_special spc_xtx_setup_handler spc_handler_xtx_do_transform spc_handler_xtx_gsave spc_handler_xtx_grestore spc_warn spc_lookup_reference spc_lookup_object spc_begin_annot spc_end_annot spc_resume_annot spc_suspend_annot spc_is_tracking_boxes spc_set_linkmode spc_set_phantom spc_push_object spc_flush_object spc_clear_objects spc_put_image spc_get_current_point spc_get_coord spc_push_coord spc_pop_coord spc_set_fixed_point spc_get_fixed_point spc_put_fixed_point spc_dup_fixed_point spc_pop_fixed_point spc_clear_fixed_point spc_exec_at_begin_page spc_exec_at_end_page spc_exec_at_begin_document spc_exec_at_end_document spc_exec_special release_sfd_record sfd_load_record sfd_get_subfont_ids t1char_get_metrics t1char_convert_charstring t1_load_font is_pfb t1_get_fontname t1_get_standard_glyph tfm_open tfm_close_all tfm_get_width tfm_get_height tfm_get_depth tfm_get_fw_width tfm_get_fw_height tfm_get_fw_depth tfm_string_width tfm_string_depth tfm_string_height tfm_get_design_size tfm_get_codingscheme tfm_is_vert tfm_is_jfm tfm_exists pdf_font_open_truetype pdf_font_load_truetype ttc_read_offset tt_get_fontdesc tt_cmap_read tt_cmap_lookup tt_cmap_release otf_create_ToUnicode_stream otf_load_Unicode_CMap otf_try_load_GID_to_CID_map tt_build_init tt_build_finish tt_add_glyph tt_get_index tt_find_glyph tt_build_tables tt_get_metrics otl_gsub_new otl_gsub_release otl_gsub_select otl_gsub_add_feat otl_gsub_apply otl_gsub_apply_alt otl_gsub_apply_lig otl_gsub_add_feat_list otl_gsub_set_chain otl_gsub_apply_chain otl_gsub_add_ToUnicode tt_read_post_table tt_release_post_table tt_lookup_post_table tt_get_glyphname tt_pack_head_table tt_read_head_table tt_pack_hhea_table tt_read_hhea_table tt_pack_maxp_table tt_read_maxp_table tt_pack_vhea_table tt_read_vhea_table tt_read_VORG_table tt_read_longMetrics tt_read_os2__table tt_get_ps_fontname Type0Font_get_wmode Type0Font_get_encoding Type0Font_get_usedchars Type0Font_get_resource Type0Font_set_ToUnicode Type0Font_cache_init Type0Font_cache_get Type0Font_cache_find Type0Font_cache_close pdf_font_open_type1 pdf_font_load_type1 pdf_font_open_type1c pdf_font_load_type1c UC_is_valid UC_UTF16BE_is_valid_string UC_UTF8_is_valid_string UC_UTF16BE_encode_char UC_UTF16BE_decode_char UC_UTF8_decode_char UC_UTF8_encode_char vf_locate_font vf_set_char    work_buffer 

EXTERN_SYM           = $(PYTHON) -c "import sys; syms = set(filter(bool, sys.argv[2:])); f = open(sys.argv[1], 'r+'); lines = list(f); f.seek(0); f.writelines(l.replace('EXTERN', 'extern') if any((' ' + sym + ' ') in l for sym in syms) and l.startswith('EXTERN') else l for l in lines)"
REDEFINE_SYM        := $(PYTHON) -c "import sys; print(' '.join('-D{func}={prefix}_{func}'.format(func = func, prefix = sys.argv[1]) for func in sys.argv[2:]))"

CFLAGS_KPSESTAT     := -Dmain='__attribute__((visibility(\"default\"))) busymain_kpsestat'
CFLAGS_KPSEACCESS   := -Dmain='__attribute__((visibility(\"default\"))) busymain_kpseaccess'
CFLAGS_KPSEREADLINK := -Dmain='__attribute__((visibility(\"default\"))) busymain_kpsereadlink'
CFLAGS_KPSEWHICH    := -Dmain='__attribute__((visibility(\"default\"))) busymain_kpsewhich'
CFLAGS_MAKEINDEX    := -Dmain='__attribute__((visibility(\"default\"))) busymain_makeindex'
CFLAGS_XETEX        := -Dmain='__attribute__((visibility(\"default\"))) busymain_xetex'
CFLAGS_BIBTEX       := -Dmain='__attribute__((visibility(\"default\"))) busymain_bibtex8'   $(shell $(REDEFINE_SYM) busybibtex     $(BIBTEX_REDEFINE) )
CFLAGS_XDVIPDFMX    := -Dmain='__attribute__((visibility(\"default\"))) busymain_xdvipdfmx' $(shell $(REDEFINE_SYM) busydvipdfmx $(DVIPDFMX_REDEFINE) )
CFLAGS_PDFTEX       := -Dmain='__attribute__((visibility(\"default\"))) busymain_pdftex'    $(shell $(REDEFINE_SYM) busypdftex     $(PDFTEX_REDEFINE) $(SYNCTEX_REDEFINE))
CFLAGS_LUAHBTEX     := -Dmain='__attribute__((visibility(\"default\"))) busymain_luahbtex'  $(shell $(REDEFINE_SYM) busyluahbtex   $(LUATEX_REDEFINE) $(SYNCTEX_REDEFINE))
CFLAGS_LUATEX       := -Dmain='__attribute__((visibility(\"default\"))) busymain_luatex'    $(shell $(REDEFINE_SYM) busyluatex     $(LUATEX_REDEFINE) $(SYNCTEX_REDEFINE))

##############################################################################################################################

# uuid_generate_random feature request: https://github.com/emscripten-core/emscripten/issues/12093
CFLAGS_FONTCONFIG_wasm= -Duuid_generate_random=uuid_generate
CFLAGS_BIBTEX_wasm    = $(CFLAGS_BIBTEX) -sTOTAL_MEMORY=$(TOTAL_MEMORY)
CFLAGS_ICU_wasm       = $(CFLAGS_OPT_wasm) -sERROR_ON_UNDEFINED_SYMBOLS=0 
CFLAGS_TEXLIVE_wasm   = -I$(abspath build/wasm/texlive/libs/icu/include)   -I$(abspath source/fontconfig) $(CFLAGS_OPT_wasm) -sERROR_ON_UNDEFINED_SYMBOLS=0 -Wno-error=unused-but-set-variable
CFLAGS_TEXLIVE_native = -I$(abspath build/native/texlive/libs/icu/include) -I$(abspath source/fontconfig) $(CFLAGS_OPT_native)
# https://tug.org/pipermail/tlbuild/2021q1/004774.html
#-static-libstdc++ -static-libgcc
# -nodefaultlibs -Wl,-Bstatic -lstdc++ -Wl,-Bdynamic -lgcc
#-fno-common 
PKGDATAFLAGS_ICU_wasm = --without-assembly -O $(ROOT)/build/wasm/texlive/libs/icu/icu-build/data/icupkg.inc

##############################################################################################################################

# EM_COMPILER_WRAPPER / EM_COMPILER_LAUNCHER feature request: https://github.com/emscripten-core/emscripten/issues/12340
CCSKIP_ICU_wasm          = $(PYTHON) $(abspath emcc_wrapper.py) $(addprefix $(ROOT)/build/native/texlive/libs/icu/icu-build/bin/, icupkg pkgdata) --
CCSKIP_FREETYPE_wasm     = $(PYTHON) $(abspath emcc_wrapper.py) $(abspath build/native/texlive/libs/freetype2/ft-build/apinames) --
CCSKIP_TEX_wasm          = $(PYTHON) $(abspath emcc_wrapper.py) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/, ctangle otangle tangle tangleboot ctangleboot tie xetex) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/web2c/, fixwrites makecpool splitup web2c) --
OPTS_ICU_configure_wasm  = CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_ICU_make_wasm       = -e PKGDATA_OPTS="$(PKGDATAFLAGS_ICU_wasm)" -e CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" -e CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_ICU_configure_make_wasm = $(OPTS_ICU_make_wasm) -e abs_srcdir="'$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu'"
OPTS_BIBTEX_wasm         = -e CFLAGS="$(CFLAGS_OPT_wasm) $(CFLAGS_BIBTEX_wasm)" -e CXXFLAGS="$(CFLAGS_OPT_wasm) $(CFLAGS_BIBTEX_wasm)"
OPTS_libfreetype_wasm    = CC="$(CCSKIP_FREETYPE_wasm) emcc"
OPTS_XETEX_wasm          = CC="$(CCSKIP_TEX_wasm)      emcc $(CFLAGS_XETEX)  $(CFLAGS_OPT_wasm)" CXX="$(CCSKIP_TEX_wasm) em++ $(CFLAGS_XETEX)  $(CFLAGS_OPT_wasm)"
OPTS_PDFTEX_wasm         = CC="$(CCSKIP_TEX_wasm)      emcc $(CFLAGS_PDFTEX) $(CFLAGS_OPT_wasm)" CXX="$(CCSKIP_TEX_wasm) em++ $(CFLAGS_PDFTEX) $(CFLAGS_OPT_wasm)"
OPTS_XDVIPDFMX_wasm      = CC="emcc $(CFLAGS_XDVIPDFMX)    $(CFLAGS_OPT_wasm)" CXX="em++          $(CFLAGS_XDVIPDFMX)    $(CFLAGS_OPT_wasm)"
OPTS_XDVIPDFMX_native    = -e CFLAGS="$(CFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX)    $(CFLAGS_OPT_native)" -e CPPFLAGS="$(CFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX)    $(CFLAGS_OPT_native)"
OPTS_BIBTEX_native       = -e CFLAGS="$(CFLAGS_BIBTEX)         $(CFLAGS_OPT_native)" -e CXXFLAGS="$(CFLAGS_BIBTEX)       $(CFLAGS_OPT_native)"
OPTS_XETEX_native        = CC="$(CC_native) $(CFLAGS_XETEX)    $(CFLAGS_OPT_native) $(addprefix $(abspath build/native)/, $(OBJ_DEPS_XETEX))" CXX="$(CXX_native) $(CFLAGS_XETEX)  $(CFLAGS_OPT_native) $(addprefix $(abspath build/native)/, $(OBJ_DEPS_XETEX))"
OPTS_PDFTEX_native       = CC="$(CC_native) $(CFLAGS_PDFTEX)   $(CFLAGS_OPT_native)" CXX="$(CXX_native) $(CFLAGS_PDFTEX) $(CFLAGS_OPT_native)"
OPTS_LUAHBTEX_native     = CC="$(CC_native) $(CFLAGS_LUAHBTEX) $(CFLAGS_OPT_native)" CXX="$(CXX_native) $(CFLAGS_LUAHBTEX) $(CFLAGS_OPT_native)"
OPTS_LUAHBTEX_wasm       = CC="$(CCSKIP_TEX_wasm) emcc $(CFLAGS_LUAHBTEX)   $(CFLAGS_OPT_wasm)" CXX="$(CCSKIP_TEX_wasm) em++ $(CFLAGS_LUAHBTEX)       $(CFLAGS_OPT_wasm)"
OPTS_LUATEX_native       = CC="$(CC_native) $(CFLAGS_LUATEX) $(CFLAGS_OPT_native)" CXX="$(CXX_native) $(CFLAGS_LUATEX) $(CFLAGS_OPT_native)"
OPTS_LUATEX_wasm         = CC="$(CCSKIP_TEX_wasm) emcc $(CFLAGS_LUATEX)       $(CFLAGS_OPT_wasm)" CXX="$(CCSKIP_TEX_wasm) em++ $(CFLAGS_LUATEX)       $(CFLAGS_OPT_wasm)"
OPTS_KPSEWHICH_native    = CFLAGS="$(CFLAGS_KPSEWHICH)    $(CFLAGS_OPT_native)"
OPTS_KPSEWHICH_wasm      = CFLAGS="$(CFLAGS_KPSEWHICH)    $(CFLAGS_OPT_wasm)"
OPTS_KPSESTAT_native     = CFLAGS="$(CFLAGS_KPSESTAT)     $(CFLAGS_OPT_native)"
OPTS_KPSESTAT_wasm       = CFLAGS="$(CFLAGS_KPSESTAT)     $(CFLAGS_OPT_wasm)"
OPTS_KPSEACCESS_native   = CFLAGS="$(CFLAGS_KPSEACCESS)   $(CFLAGS_OPT_native)"
OPTS_KPSEACCESS_wasm     = CFLAGS="$(CFLAGS_KPSEACCESS)   $(CFLAGS_OPT_wasm)"
OPTS_KPSEREADLINK_native = CFLAGS="$(CFLAGS_KPSEREADLINK) $(CFLAGS_OPT_native)"
OPTS_KPSEREADLINK_wasm   = CFLAGS="$(CFLAGS_KPSEREADLINK) $(CFLAGS_OPT_wasm)"
OPTS_MAKEINDEX_native    = CFLAGS="$(CFLAGS_MAKEINDEX)    $(CFLAGS_OPT_native)"
OPTS_MAKEINDEX_wasm      = CFLAGS="$(CFLAGS_MAKEINDEX)    $(CFLAGS_OPT_wasm)"

OPTS_BUSYTEX_COMPILE = -static-libstdc++ -static-libgcc
OPTS_BUSYTEX_LINK_native =  $(OPTS_BUSYTEX_COMPILE) -static -Wl,--unresolved-symbols=ignore-all -Wimplicit -Wreturn-type -pthread
# https://tug.org/pipermail/tex-live-commits/2021-June/018270.html
OPTS_BUSYTEX_LINK_wasm   =  $(OPTS_BUSYTEX_COMPILE) -Wl,--unresolved-symbols=ignore-all -Wl,-error-limit=0 -sTOTAL_MEMORY=$(TOTAL_MEMORY) -sEXIT_RUNTIME=0 -sINVOKE_RUN=0 -sASSERTIONS=1 -sERROR_ON_UNDEFINED_SYMBOLS=0 -sFORCE_FILESYSTEM=1 -sLZ4=1 -sMODULARIZE=1 -sEXPORT_NAME=busytex -sEXPORTED_FUNCTIONS='["_main", "_flush_streams"]' -sEXPORTED_RUNTIME_METHODS='["callMain", "FS", "ENV", "LZ4", "PATH"]'

##############################################################################################################################

.PHONY: all
all: build/versions.txt
	$(MAKE) texlive
	$(MAKE) native
	$(MAKE) test
	$(MAKE) tds-basic
	$(MAKE) wasm
	$(MAKE) build/wasm/texlive-basic.js
	#$(MAKE) tds-full
	#$(MAKE) ubuntu-wasm

source/texlive.downloaded source/expat.downloaded source/fontconfig.downloaded:
	mkdir -p $(basename $@)
	-wget --no-verbose --no-clobber $(URL_$(notdir $(basename $@))) -O $(basename $@).tar.gz 
	tar -xf "$(basename $@).tar.gz" --strip-components=1 --directory=$(basename $@)
	touch $@

source/fontconfig.patched: source/fontconfig.downloaded
	#TODO: https://superuser.com/questions/493640/how-to-retry-connections-with-wget
	#wget -O $(basename $<)/src/fcstat.c https://gitlab.freedesktop.org/fontconfig/fontconfig/-/raw/fd393c53d816653e525950b742d49b02d599260b/src/fcstat.c
	cp fcstat.c $(basename $<)/src/fcstat.c
	touch $@

source/texlive.patched: source/texlive.downloaded
	#wget -O source/texlive/texk/upmendex/configure https://raw.githubusercontent.com/t-tk/upmendex-package/207d40e/source/configure 
	#wget -O source/texlive/libs/harfbuzz/harfbuzz-src/src/hb-subset-cff1.cc https://raw.githubusercontent.com/harfbuzz/harfbuzz/2.8.2/src/hb-subset-cff1.cc
	cp configure source/texlive/texk/upmendex/configure
	cp hb-subset-cff1.cc source/texlive/libs/harfbuzz/harfbuzz-src/src/hb-subset-cff1.cc
	touch $@

build/%/texlive.configured: source/texlive.patched
	mkdir -p $(basename $@)
	echo '' > $(CACHE_TEXLIVE_$*)
	cd $(basename $@) &&                        \
	CONFIG_SITE=$(CONFIGSITE_BUSYTEX) $(CONFIGURE_$*) $(abspath source/texlive/configure)		\
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
	  --enable-cxx-runtime-hack=yes             \
		CFLAGS="$(CFLAGS_TEXLIVE_$*)"	     	\
	  CPPFLAGS="$(CFLAGS_TEXLIVE_$*)"           \
	  CXXFLAGS="$(CFLAGS_TEXLIVE_$*)"
	$(MAKE_$*) -C $(basename $@)
	touch $@

build/%/texlive/libs/teckit/libTECkit.a build/%/texlive/libs/harfbuzz/libharfbuzz.a build/%/texlive/libs/graphite2/libgraphite2.a build/%/texlive/libs/libpng/libpng.a build/%/texlive/libs/libpaper/libpaper.a build/%/texlive/libs/zlib/libz.a build/%/texlive/libs/pplib/libpplib.a build/%/texlive/libs/xpdf/libxpdf.a build/%/texlive/libs/zziplib/libzzip.a build/%/texlive/libs/freetype2/libfreetype.a build/%/texlive/texk/web2c/lib/lib.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(OPTS_$(notdir $(basename $@))_$*) 

build/%/texlive/libs/lua53/.libs/libtexlua53.a build/%/texlive/texk/kpathsea/.libs/libkpathsea.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $(abspath $(dir $@)))

build/%/expat/libexpat.a: source/expat.downloaded
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CMAKE_$*)                           \
	   -DCMAKE_C_FLAGS="$(CFLAGS_$*_OPT)" \
	   -DEXPAT_BUILD_DOCS=off             \
	   -DEXPAT_SHARED_LIBS=off            \
	   -DEXPAT_BUILD_EXAMPLES=off         \
	   -DEXPAT_BUILD_FUZZERS=off          \
	   -DEXPAT_BUILD_TESTS=off            \
	   -DEXPAT_BUILD_TOOLS=off            \
	   $(abspath $(basename $<)) 
	$(MAKE_$*) -C $(dir $@)

build/%/fontconfig/src/.libs/libfontconfig.a: source/fontconfig.patched build/%/expat/libexpat.a build/%/texlive/libs/freetype2/libfreetype.a
	echo > $(CACHE_FONTCONFIG_$*)
	mkdir -p build/$*/fontconfig
	cd build/$*/fontconfig && \
	$(CONFIGURE_$*) $(abspath $(basename $<)/configure) \
	   --cache-file=$(CACHE_FONTCONFIG_$*)	            \
	   --prefix=$(PREFIX_$*)                            \
	   --sysconfdir=/etc                                \
	   --localstatedir=/var                             \
	   --enable-static                                  \
	   --disable-shared                                 \
	   --disable-docs                                   \
	   --with-expat-includes="$(abspath source/expat/lib)" \
	   --with-expat-lib="$(abspath build/$*/expat)"        \
	   CFLAGS="$(CFLAGS_OPT_$*) $(CFLAGS_FONTCONFIG_$*) -v" FREETYPE_CFLAGS="$(addprefix -I$(ROOT)/build/$*/texlive/libs/, freetype2/ freetype2/freetype2/)" FREETYPE_LIBS="-L$(ROOT)/build/$*/texlive/libs/freetype2/ -lfreetype"
	$(MAKE_$*) -C build/$*/fontconfig

build/%/texlive/texk/makeindexk/busytex_makeindex.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) genind.o mkind.o qsort.o scanid.o scanst.o sortid.o $(OPTS_MAKEINDEX_$*)
	$(AR_$*) -crs $@ $(dir $@)/*.o

build/%/texlive/texk/kpathsea/busytex_kpsewhich.o: build/%/texlive.configured
	-rm build/$*/texlive/texk/kpathsea/kpsewhich.o 
	$(MAKE_$*) -C $(dir $@) kpsewhich.o $(OPTS_KPSEWHICH_$*)
	cp $(dir $@)/kpsewhich.o $@

build/%/texlive/texk/kpathsea/busytex_kpsestat.o: build/%/texlive.configured
	-rm build/$*/texlive/texk/kpathsea/kpsestat.o 
	$(MAKE_$*) -C $(dir $@) kpsestat.o $(OPTS_KPSESTAT_$*)
	cp $(dir $@)/kpsestat.o $@

build/%/texlive/texk/kpathsea/busytex_kpseaccess.o: build/%/texlive.configured
	-rm build/$*/texlive/texk/kpathsea/access.o 
	$(MAKE_$*) -C $(dir $@) access.o $(OPTS_KPSEACCESS_$*)
	cp $(dir $@)/access.o $@

build/%/texlive/texk/kpathsea/busytex_kpsereadlink.o: build/%/texlive.configured
	-rm build/$*/texlive/texk/kpathsea/readlink.o 
	$(MAKE_$*) -C $(dir $@) readlink.o $(OPTS_KPSEREADLINK_$*)
	cp $(dir $@)/readlink.o $@

build/%/texlive/texk/web2c/busytex_libluahbtex.a: build/%/texlive.configured build/%/texlive/libs/zziplib/libzzip.a build/%/texlive/libs/lua53/.libs/libtexlua53.a
	$(MAKE_$*) -C $(dir $@) luatexdir/luahbtex-luatex.o mplibdir/luahbtex-lmplib.o libluahbtexspecific.a libluaharfbuzz.a libmputil.a $(OPTS_LUAHBTEX_$*)
	$(MAKE_$*) -C $(dir $@) libluatex.a $(OPTS_LUAHBTEX_$*)
	mv $(dir $@)/libluatex.a $@
	#echo AR1; $(AR_$*) t $@; echo NM1; $(NM_$*) $@
	#$(MAKE_$*) -C $(dir $@) luatexdir/luatex-luatex.o mplibdir/luatex-lmplib.o libluatexspecific.a $(OPTS_LUATEX_$*)
	#$(MAKE_$*) -C $(dir $@) libluatex.a $(OPTS_LUATEX_$*)
	#mv $(dir $@)/libluatex.a $(dir $@)/busytex_libluatex.a
	#echo AR2; $(AR_$*) t $(dir $@)/busytex_libluatex.a; echo NM2; $(NM_$*) $(dir $@)/busytex_libluatex.a

build/%/texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(subst -Dmain=, -Dbusymain=, $(OPTS_XDVIPDFMX_$*))
	rm $(dir $@)/dvipdfmx.o
	$(MAKE_$*) -C $(dir $@) dvipdfmx.o $(OPTS_XDVIPDFMX_$*)
	$(AR_$*) -crs $@ $(dir $@)/*.o

build/%/texlive/texk/bibtex-x/busytex_bibtex8.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(subst -Dmain=, -Dbusymain=, $(OPTS_BIBTEX_$*))
	rm $(dir $@)/bibtex8-bibtex.o
	$(MAKE_$*) -C $(dir $@) bibtex8-bibtex.o $(OPTS_BIBTEX_$*)
	$(AR_$*) -crs $@ $(dir $@)/bibtex8-*.o

build/%/busytex build/%/busytex.js: 
	mkdir -p $(dir $@)
	$(CC_$*) -c busytex.c -o $(basename $@).o -DBUSYTEX_MAKEINDEX -DBUSYTEX_KPSE -DBUSYTEX_BIBTEX8 -DBUSYTEX_XDVIPDFMX -DBUSYTEX_XETEX -DBUSYTEX_PDFTEX -DBUSYTEX_LUATEX $(OPTS_BUSYTEX_COMPILE)
	$(CXX_$*) $(OPTS_BUSYTEX_LINK_$*) $(CFLAGS_OPT_$*) -o $@ $(basename $@).o $(addprefix build/$*/texlive/texk/web2c/, $(OBJ_XETEX) $(OBJ_PDFTEX) $(OBJ_LUAHBTEX)) $(addprefix build/$*/, $(OBJ_BIBTEX) $(OBJ_DVIPDF) $(OBJ_DEPS) $(OBJ_MAKEINDEX)) $(addprefix -Ibuild/$*/, $(CPATH_BUSYTEX)) $(addprefix build/$*/texlive/texk/kpathsea/, $(OBJ_KPATHSEA)) -ldl -lm

build/%/texlive/libs/icu/icu-build/lib/libicuuc.a build/%/texlive/libs/icu/icu-build/lib/libicudata.a build/%/texlive/libs/icu/icu-build/bin/icupkg build/%/texlive/libs/icu/icu-build/bin/pkgdata : build/%/texlive.configured
	# WASM build depends on build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata
	cd                    build/$*/texlive/libs/icu && $(CONFIGURE_$*) $(abspath source/texlive/libs/icu/configure) $(OPTS_ICU_configure_$*)
	$(MAKE_$*)         -C build/$*/texlive/libs/icu 
	echo "all install:" > build/$*/texlive/libs/icu/icu-build/test/Makefile
	$(MAKE_$*)         -C build/$*/texlive/libs/icu/icu-build
	$(MAKE_$*)         -C build/$*/texlive/libs/icu/include/unicode

################################################################################################################

build/%/texlive/texk/web2c/busytex_libxetex.a: build/%/texlive.configured
	mkdir -p $(dir $@)
	-cp $(subst wasm, native, $(dir $@)/*.c $(dir $@)
	$(MAKE_$*) -C $(dir $@) synctexdir/xetex-synctex.o      xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o  $(subst -Dmain=, -Dbusymain=, $(OPTS_XETEX_$*))
	$(MAKE_$*) -C $(dir $@) xetexdir/xetex-xetexextra.o     $(OPTS_XETEX_$*)
	$(MAKE_$*) -C $(dir $@) libxetex.a                      $(OPTS_XETEX_$*)
	mv $(dir $@)/libxetex.a $@

#build/native/texlive/texk/web2c/busytex_libxetex.a: build/native/texlive.configured
#	mkdir -p $(dir $@)
#	$(MAKE_native) -C $(dir $@) synctexdir/xetex-synctex.o      xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o  $(subst -Dmain=, -Dbusymain=, $(OPTS_XETEX_native))
#	$(MAKE_native) -C $(dir $@) xetexdir/xetex-xetexextra.o     $(OPTS_XETEX_native)
#	$(MAKE_native) -C $(dir $@) libxetex.a                      $(OPTS_XETEX_native)
#	mv $(dir $@)/libxetex.a $@
#
#build/wasm/texlive/texk/web2c/busytex_libxetex.a: build/wasm/texlive.configured build/native/busytex
#	# copying generated C files from native version, since string offsets are off
#	mkdir -p $(dir $@)
#	cp build/native/texlive/texk/web2c/*.c $(dir $@)
#	#$(MAKE_wasm) -C $(dir $@) synctexdir/xetex-synctex.o xetex  $(OPTS_XETEX_wasm)
#	$(MAKE_wasm) -C $(dir $@) synctexdir/xetex-synctex.o      xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o  $(subst -Dmain=, -Dbusymain=, $(OPTS_XETEX_wasm))
#	$(MAKE_wasm) -C $(dir $@) xetexdir/xetex-xetexextra.o     $(OPTS_XETEX_wasm)
#	$(MAKE_wasm) -C $(dir $@) libxetex.a                      $(OPTS_XETEX_wasm)
#	mv $(dir $@)/libxetex.a $@


build/native/texlive/texk/web2c/busytex_libpdftex.a: build/native/texlive.configured build/native/texlive/libs/xpdf/libxpdf.a
	$(MAKE_native) -C $(dir $@) pdftexd.h synctexdir/pdftex-synctex.o     pdftex-pdftexini.o pdftex-pdftex0.o pdftex-pdftex-pool.o $(subst -Dmain=, -Dbusymain=, $(OPTS_PDFTEX_native))
	$(EXTERN_SYM)     $(dir $@)/pdftexd.h     $(PDFTEX_EXTERN)
	$(MAKE_native) -C $(dir $@) pdftexdir/pdftex-pdftexextra.o  $(OPTS_PDFTEX_native)
	$(MAKE_native) -C $(dir $@) libpdftex.a                     $(OPTS_PDFTEX_native)
	mv $(dir $@)/libpdftex.a $@

build/wasm/texlive/texk/web2c/busytex_libpdftex.a: build/wasm/texlive.configured build/native/busytex
	# copying generated C files from native version, since string offsets are off
	mkdir -p $(dir $@)
	cp build/native/texlive/texk/web2c/*.c $(dir $@)
	$(MAKE_wasm) -C $(dir $@) synctexdir/pdftex-synctex.o pdftex $(subst -Dmain=, -Dbusymain=, $(OPTS_PDFTEX_wasm))
	rm $(dir $@)/pdftexdir/pdftex-pdftexextra.o
	$(EXTERN_SYM) build/wasm/texlive/texk/web2c/pdftexd.h       $(PDFTEX_EXTERN)
	$(MAKE_wasm) -C $(dir $@) pdftexdir/pdftex-pdftexextra.o    $(OPTS_PDFTEX_wasm)
	$(MAKE_wasm) -C $(dir $@) libpdftex.a                       $(OPTS_PDFTEX_wasm)
	mv $(dir $@)/libpdftex.a $@

.PHONY: build/wasm/texlive/libs/icu/icu-build/bin/icupkg build/wasm/texlive/libs/icu/icu-build/bin/pkgdata
build/wasm/texlive/libs/icu/icu-build/bin/icupkg build/wasm/texlive/libs/icu/icu-build/bin/pkgdata:

################################################################################################################

source/texmfrepo.txt:
	mkdir -p source/texmfrepo
	wget --no-verbose --no-clobber $(URL_texlive_full_iso) -P source
	7z x source/$(notdir $(URL_texlive_full_iso)) -osource/texmfrepo
	rm source/$(notdir $(URL_texlive_full_iso))
	chmod +x ./source/texmfrepo/install-tl
	find     ./source/texmfrepo > source/texmfrepo.txt

build/texlive-basic.profile:
	mkdir -p $(dir $@)
	echo selected_scheme scheme-basic                                   > $@
	echo TEXDIR $(ROOT)/$(basename $@)                                 >> $@ 
	echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-dist/texmf-local      >> $@
	echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-dist/texmf-var       >> $@ 
	echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-dist/texmf-config >> $@ 
	echo "collection-xetex  1"                                         >> $@ 
	echo "collection-luatex 1"                                         >> $@ 
	echo "collection-latex  1"                                         >> $@ 

build/texlive-full.profile:
	mkdir -p $(dir $@)
	echo selected_scheme scheme-full                                    > $@
	echo TEXDIR $(ROOT)/$(basename $@)                                 >> $@ 
	echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-dist/texmf-local      >> $@
	echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-dist/texmf-var       >> $@ 
	echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-dist/texmf-config >> $@ 
	#echo TEXMFVAR $(ROOT)/$(basename $@)/home/texmf-var >> build/texlive-$*.profile

build/texlive-%.txt: build/texlive-%.profile source/texmfrepo.txt
	mkdir -p $(basename $@)/$(BINARCH_native)
	cp $(BUSYTEX_native)                                                  $(basename $@)/$(BINARCH_native)
	$(foreach name,texlive-scripts latexconfig tex-ini-files,tar -xf source/texmfrepo/archive/$(name).r*.tar.xz -C $(basename $@); )
	$(foreach name,xetex luahbtex pdftex xelatex luahblatex pdflatex kpsewhich kpseaccess kpsestat kpsereadlink,printf "#!/bin/sh\n$(ROOT)/$(basename $@)/$(BINARCH_native)/busytex $(name)   $$"@ > $(basename $@)/$(BINARCH_native)/$(name) ; chmod +x $(basename $@)/$(BINARCH_native)/$(name); )
	$(foreach name,mktexlsr.pl updmap-sys.sh updmap.pl fmtutil-sys.sh fmtutil.pl,mv $(basename $@)/texmf-dist/scripts/texlive/$(name) $(basename $@)/$(BINARCH_native)/$(basename $(name)); )
	#   -v -e trace=execve strace -v -s 1000 -f
	source/texmfrepo/install-tl --help 
	TEXLIVE_INSTALL_NO_RESUME=1 source/texmfrepo/install-tl --repository source/texmfrepo --profile build/texlive-$*.profile --custom-bin $(ROOT)/$(basename $@)/$(BINARCH_native) 
	# 
	mv $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/lualatex.fmt $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/luahblatex.fmt
	#printf "#!/bin/sh\n$(ROOT)/$(basename $@)/$(BINARCH_native)/busytex lualatex   $$"@ > $(basename $@)/$(BINARCH_native)/luahbtex
	#$(basename $@)/$(BINARCH_native)/fmtutil-sys --byengine luahbtex
	echo FINDLOG; cat  $(basename $@)/texmf-dist/texmf-var/web2c/*/*.log                                || true
	echo FINDFMT; ls   $(basename $@)/texmf-dist/texmf-var/web2c/*/*.fmt                                || true
	rm -rf $(addprefix $(basename $@)/, bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/doc) || true
	find $(basename $@) > $@

################################################################################################################

build/wasm/texlive-%.js: build/texlive-%/texmf-dist build/wasm/fonts.conf 
	mkdir -p $(dir $@)
	echo > build/empty
	echo 'web_user:x:0:0:emscripten:/home/web_user:/bin/false' > build/passwd
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		--preload build/passwd@/etc/passwd \
		--preload build/empty@/bin/busytex \
		--preload build/wasm/fonts.conf@/etc/fonts/fonts.conf \
		--preload build/texlive-$*@/texlive

build/wasm/ubuntu-%.js: $(TEXMF_FULL)
	mkdir -p $(dir $@)
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data \
		--js-output=$@ \
		--export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		$(shell $(PYTHON) ubuntu_package_preload.py --texmf $(TEXMF_FULL) --url $(URL_UBUNTU_RELEASE) --skip-log $(basename $@).skip.txt --good-log $(basename $@).good.txt --package $*)

build/wasm/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>'                          > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'      >> $@
	echo '<fontconfig>'                                  >> $@
	echo '<dir>/texlive/texmf-dist/fonts/opentype</dir>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/type1</dir>'    >> $@
	echo '</fontconfig>'                                 >> $@

build/native/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>'                          > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'      >> $@
	echo '<fontconfig>'                                  >> $@
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/opentype</dir>
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/type1</dir>
	#<cachedir prefix="relative">./cache</cachedir>
	echo '</fontconfig>'                                 >> $@

################################################################################################################

.PHONY: build/native/texlivedependencies build/wasm/texlivedependencies
build/native/texlivedependencies build/wasm/texlivedependencies:
	$(MAKE) $(dir $@)expat/libexpat.a
	$(MAKE) $(dir $@)texlive/libs/zziplib/libzzip.a
	$(MAKE) $(dir $@)texlive/libs/libpng/libpng.a 
	$(MAKE) $(dir $@)texlive/libs/libpaper/libpaper.a 
	$(MAKE) $(dir $@)texlive/libs/zlib/libz.a 
	$(MAKE) $(dir $@)texlive/libs/teckit/libTECkit.a 
	$(MAKE) $(dir $@)texlive/libs/harfbuzz/libharfbuzz.a 
	$(MAKE) $(dir $@)texlive/libs/graphite2/libgraphite2.a 
	$(MAKE) $(dir $@)texlive/libs/pplib/libpplib.a 
	$(MAKE) $(dir $@)texlive/libs/lua53/.libs/libtexlua53.a
	$(MAKE) $(dir $@)texlive/libs/freetype2/libfreetype.a 
	$(MAKE) $(dir $@)texlive/libs/xpdf/libxpdf.a
	$(MAKE) $(dir $@)texlive/libs/icu/icu-build/lib/libicuuc.a 
	$(MAKE) $(dir $@)texlive/libs/icu/icu-build/lib/libicudata.a
	$(MAKE) $(dir $@)texlive/libs/icu/icu-build/bin/icupkg 
	$(MAKE) $(dir $@)texlive/libs/icu/icu-build/bin/pkgdata 
	$(MAKE) $(dir $@)fontconfig/src/.libs/libfontconfig.a

.PHONY: build/native/busytexapplets build/wasm/busytexapplets
build/native/busytexapplets build/wasm/busytexapplets:
	$(MAKE) $(dir $@)texlive/texk/kpathsea/.libs/libkpathsea.a
	$(MAKE) $(dir $@)texlive/texk/web2c/lib/lib.a
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpsewhich.o 
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpsestat.o 
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpseaccess.o 
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpsereadlink.o 
	$(MAKE) $(dir $@)texlive/texk/makeindexk/busytex_makeindex.a
	$(MAKE) $(dir $@)texlive/texk/dvipdfm-x/busytex_xdvipdfmx.a
	$(MAKE) $(dir $@)texlive/texk/bibtex-x/busytex_bibtex8.a
	$(MAKE) $(dir $@)texlive/texk/web2c/busytex_libxetex.a
	$(MAKE) $(dir $@)texlive/texk/web2c/busytex_libpdftex.a
	$(MAKE) $(dir $@)texlive/texk/web2c/busytex_libluahbtex.a

.PHONY: native
native: build/native/fonts.conf
	$(MAKE) build/native/texlive.configured
	$(MAKE) build/native/texlivedependencies
	$(MAKE) build/native/busytexapplets
	$(MAKE) build/native/busytex

.PHONY: wasm
wasm: build/wasm/fonts.conf
	$(MAKE) build/wasm/texlive.configured
	$(MAKE) build/wasm/texlivedependencies
	$(MAKE) build/wasm/busytexapplets
	$(MAKE) build/wasm/busytex.js

################################################################################################################

.PHONY: texlive
texlive: source/texlive.downloaded source/texlive.patched

.PHONY: ubuntu-wasm
ubuntu-wasm: build/wasm/ubuntu-texlive-latex-base.js build/wasm/ubuntu-texlive-latex-extra.js build/wasm/ubuntu-texlive-latex-recommended.js build/wasm/ubuntu-texlive-science.js

tds-%:
	$(MAKE) source/texmfrepo.txt build/texlive-$*.txt

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

.PHONY: test
test: build/native/busytex
	-$(LDD_native) $(BUSYTEX_native)
	$(BUSYTEX_native)
	$(foreach applet,xelatex pdflatex luahblatex lualatex bibtex8 xdvipdfmx kpsewhich kpsestat kpseaccess kpsereadlink,echo $(BUSYTEX_native) $(applet) --version; $(BUSYTEX_native) $(applet) --version; )

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

.PHONY: clean_build
clean_build:
	rm -rf build

.PHONY: clean_dist
clean_dist:
	rm -rf dist-*

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
	-cp build/wasm/busytex.js       build/wasm/busytex.wasm       $@ 
	-cp build/wasm/texlive-basic.js build/wasm/texlive-basic.data $@ 
	-cp build/wasm/ubuntu-*.js      build/wasm/ubuntu-*.data      $@ 

.PHONY: dist-native
dist-native: build/native/busytex build/native/fonts.conf
	mkdir -p $@
	cp $(addprefix build/native/, busytex fonts.conf) $@
	#  luahbtex/lualatex.fmt
	cp $(addprefix build/texlive-basic/texmf-dist/texmf-var/web2c/, pdftex/pdflatex.fmt xetex/xelatex.fmt luahbtex/luahblatex.fmt) $@
	cp -r build/texlive-basic $@/texlive
