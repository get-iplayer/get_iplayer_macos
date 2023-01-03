# Build macOS installer for get_iplayer
# Prereqs: Packages, osxiconutils, platypus, Homebrew
# Prereqs: Xcode command line tools (xcode-select --install)
# Prereqs: conan (brew install conan)
# Build release (VERSION = tag in get_iplayer repo w/o "v" prefix"):
# VERSION=3.14 make release
# Rebuild all dependencies and build release:
# VERSION=3.14 make distclean release
# Specify installer patch number for release (default = 0):
# VERSION=3.14 PATCH=1 make release
# Flag as work in progress for development
# VERSION=3.14 PATCH=1 WIP=1 make release
# Use alternate tag/branch in get_iplayer repo
# VERSION=3.14 PATCH=1 WIP=1 TAG=develop make release

ifndef VERSION
	gip_tag := master
	VERSION := 0.0
	PATCH := 0
	WIP := 1
else
	gip_tag := v$(VERSION)
ifndef PATCH
	PATCH := 0
endif
endif
ifdef TAG
	gip_tag := $(TAG)
endif
pkg_ver := $(VERSION).$(PATCH)
ifndef WIP
	pkg_tag := $(shell git tag -l $(pkg_ver))
ifeq ($(pkg_tag), $(pkg_ver))
	WIP := 1
endif
endif

# macOS target
macos_arch := x86_64
macos_min := 10.10
export MACOSX_DEPLOYMENT_TARGET = $(macos_min)
# base dir
build := build-$(macos_arch)
# installer package
pkg_name := get_iplayer
pkg_prj := $(pkg_name).pkgproj
pkg_src := $(build)/src
pkg_out := $(build)/$(pkg_name).pkg
pkg_file := $(pkg_name)-$(pkg_ver)-macos-$(macos_arch).pkg
pkg_path := $(build)/$(pkg_file)
pkg_chk_file := $(pkg_file).sha256
pkg_chk_path := $(dir $(pkg_path))/$(pkg_chk_file)
curr_ver := $(shell /usr/libexec/PlistBuddy -c "Print :PACKAGES:0:PACKAGE_SETTINGS:VERSION" $(pkg_prj))
# utilities
ditto := ditto --norsrc --noextattr --noacl
# conan
conan_dir := $(build)/conan
conan_user_home := $(conan_dir)/user_home
export CONAN_USER_HOME = $(PWD)/$(conan_user_home)
conan_install := $(conan_dir)/install
conan_imports := $(conan_dir)/imports
conan_dylib := $(conan_imports)/dylib
# shared libraries
libcrypto := libcrypto.3.dylib
libssl := libssl.3.dylib
libxml2 := libxml2.2.dylib
libiconv := libiconv.2.dylib
libcharset := libcharset.1.dylib
libz := libz.1.2.13.dylib
sys_libz := libz.1.dylib
rt_rpath := @executable_path/../dylib
# perl source
ps_ver := 5.36.0
ps_base := perl-$(ps_ver)
ps_tgz := $(build)/$(ps_base).tar.gz
ps_tgz_url := https://www.cpan.org/src/5.0/$(ps_base).tar.gz
# relocatable perl
rp_ver := $(ps_ver).1
rp_base := relocatable-perl-$(rp_ver)
rp_dir := $(build)/$(rp_base)
rp_tgz := $(build)/$(rp_base).tar.gz
rp_tgz_url := https://github.com/skaji/relocatable-perl/archive/$(rp_ver).tar.gz
# perl bootstrap
cpm_exe := $(build)/cpm
pb_base := perl-darwin-2level-$(rp_ver)
pb_dir := $(build)/$(pb_base)
pb_tgz := $(build)/$(pb_base).tar.gz
pb_tgz_url := https://github.com/skaji/relocatable-perl/releases/download/$(rp_ver)/perl-darwin-amd64.tar.gz
pb_perl := $(pb_dir)/bin/perl
# perl core
pc_base := perl-core-$(rp_ver)-macos-$(macos_min)
pc_dir := $(build)/$(pc_base)
pc_tgz := $(build)/$(pc_base).tar.gz
pc_anon := $(build)/anon_pc
# perl get_iplayer
pg_base := perl-gip-$(rp_ver)-macos-$(macos_min)
pg_dir := $(build)/$(pg_base)
pg_perl := $(pg_dir)/bin/perl
pg_dylib := $(pg_dir)/dylib
pg_tgz := $(build)/$(pg_base).tar.gz
pg_anon := $(build)/anon_pg
ssleay_bundle := $(pg_dir)/lib/site_perl/$(ps_ver)/darwin-2level/auto/Net/SSLeay/SSLeay.bundle
libxml_bundle := $(pg_dir)/lib/site_perl/$(ps_ver)/darwin-2level/auto/XML/LibXML/LibXML.bundle
# installer payload
ul := $(pkg_src)/usr/local
ul_bin := $(ul)/bin
ul_man1 := $(ul)/share/man/man1
ulg := $(ul)/get_iplayer
ulg_lic_dir := $(ulg)/licenses
ulg_bin := $(ulg)/bin
ulg_perl := $(ulg)/perl
ulg_perl_bin := $(ulg_perl)/bin
ulg_utils_bin := $(ulg)/utils/bin
# get_iplayer
gip_repo := ../get_iplayer
gip_tgz := $(build)/get_iplayer-$(gip_tag).tar.gz
gip_perl_files := get_iplayer get_iplayer.cgi
gip_perl_scripts := get_iplayer,get_iplayer.cgi
gip_bin_files := get_iplayer get_iplayer_cgi get_iplayer_pvr get_iplayer_uninstall get_iplayer_web_pvr
gip_bin_scripts := get_iplayer,get_iplayer_cgi,get_iplayer_pvr,get_iplayer_uninstall,get_iplayer_web_pvr
# atomicparsley
ap_ver := 0.9.7-get_iplayer.3
ap_base := AtomicParsley-$(ap_ver)-macos-$(macos_arch)
ap_zip_file := AtomicParsley-$(ap_ver)-macos-$(macos_arch)-shared.zip
ap_zip_path := $(build)/$(ap_zip_file)
ap_zip_url := https://github.com/get-iplayer/atomicparsley/releases/download/$(ap_ver)/$(ap_zip_file)
# ffmpeg
ff_ver := 5.0.1
ff_arch := x64
ff_base := darwin-$(ff_arch)
ff_zip_file := ffmpeg-$(ff_ver)-$(ff_base).gz
ff_zip_path := $(build)/$(ff_zip_file)
ff_zip_url := https://github.com/eugeneware/ffmpeg-static/releases/download/b$(ff_ver)/$(ff_base).gz
# licences
lic_dir := $(build)/licenses
# applications
apps := $(pkg_src)/Applications
apps_gip := $(apps)/get_iplayer

define pb_off
	if [ ! -z $(PERLBREW_PERL) ]; then \
		if [ -z $(PERLBREW_ROOT) ]; then \
			echo $(pkg_name): "Cannot find perlbrew root: $(PERLBREW_ROOT)"; \
			exit 2; \
		fi; \
		if [ ! -f "$(PERLBREW_ROOT)/etc/bashrc" ]; then \
			echo $(pkg_name): "Cannot find perlbrew init: $(PERLBREW_ROOT)/etc/bashrc"; \
			exit 2; \
		fi; \
		source "$(PERLBREW_ROOT)/etc/bashrc"; \
		perlbrew off; \
	fi
endef

dummy:
	@echo Nothing to make

$(conan_install):
ifndef NOPERL
	@conan install conanfile.txt --no-imports --install-folder $(conan_install) --build "openssl" --build "libxml2" --build "libiconv" --build "zlib"
	@echo created $(conan_install)
	@touch $(conan_install)
endif

$(conan_dylib): $(conan_install)
ifndef NOPERL
	@conan imports conanfile.txt --install-folder $(conan_install) --import-folder $(conan_imports)
	@echo created $(conan_dylib)
	@touch $(conan_dylib)
endif

conan-all: $(conan_dylib)

conan-clean:
	@rm -fr $(conan_dir)
	@echo removed $(conan_dir)

$(ps_tgz):
ifndef NOPERL
	@mkdir -p $(dir $(ps_tgz))
	@curl -\#fkL -o $(ps_tgz) $(ps_tgz_url)
	@echo downloaded $(ps_tgz)
	@touch $(ps_tgz)
endif

ps-all: $(ps_tgz)

$(rp_tgz):
ifndef NOPERL
	@mkdir -p $(dir $(rp_tgz))
	@curl -\#fkL -o $(rp_tgz) $(rp_tgz_url)
	@echo downloaded $(rp_tgz)
	@touch $(rp_tgz)
endif

$(rp_dir): $(rp_tgz)
ifndef NOPERL
	@mkdir -p $(rp_dir)
	@tar -xzf $(rp_tgz) --strip-components=1 -C $(rp_dir)
	@patch $(rp_dir)/build/relocatable-perl-build revert_do_not_add_macosx_version_min.patch
	@echo created $(rp_dir)
	@touch $(rp_dir)
endif

rp-all: $(rp_dir)

rp-clean:
	@rm -fr $(rp_dir)
	@echo removed $(rp_dir)

$(cpm_exe):
ifndef NOPERL
	@mkdir -p $(dir $(cpm_exe))
	@curl -fsSL --compressed -o $(cpm_exe) https://git.io/cpm
	@echo downloaded $(cpm_exe)
	@touch $(cpm_exe)
endif

$(pb_tgz):
ifndef NOPERL
	@mkdir -p $(dir $(pb_tgz))
	@curl -\#fkL -o $(pb_tgz) $(pb_tgz_url)
	@echo downloaded $(pb_tgz)
	@touch $(pb_tgz)
endif

$(pb_dir): $(rp_dir) $(cpm_exe) $(pb_tgz)
ifndef NOPERL
	@mkdir -p $(pb_dir)
	@tar -xzf $(pb_tgz) --strip-components=1 -C $(pb_dir)
	@$(pb_off); \
		$(pb_perl) $(cpm_exe) install -g --cpmfile $(rp_dir)/build/cpm.yml
	@echo created $(pb_dir)
	@touch $(pb_dir)
endif

pb-all: $(pb_dir)

pb-clean:
	@rm -fr $(pb_dir)
	@echo removed $(pb_dir)

$(pc_dir): $(ps_tgz) $(rp_dir) $(pb_dir)
ifndef NOPERL
	@$(pb_off); \
		$(pb_perl) $(rp_dir)/build/relocatable-perl-build --tarball "$(ps_tgz)" --prefix "$(PWD)/$(pc_dir)" --perl_version $(rp_ver); \
		$(pb_dir)/bin/change-shebang -q -f $(pc_dir)/bin/*;
	@echo created $(pc_dir)
	@touch $(pc_dir)
endif

$(pc_anon): $(pc_dir)
ifndef NOPERL
	@find $(pc_dir) -type f -name perllocal.pod -exec rm -f {} \;
	@find $(pc_dir) -type f -name .packlist -exec rm -f {} \;
	@sed -i.bak -e "s/$$USER/nobody/g" $(pc_dir)/bin/perlivp
	@rm -f $(pc_dir)/bin/perlivp.bak
	@sed -i.bak -e "s/$$USER/nobody/g" $(pc_dir)/lib/$(ps_ver)/darwin-2level/CORE/config.h
	@rm -f $(pc_dir)/lib/$(ps_ver)/darwin-2level/CORE/config.h.bak
	@sed -i.bak -e "s/$$USER/nobody/g" $(pc_dir)/lib/$(ps_ver)/darwin-2level/Config_heavy.pl
	@rm -f $(pc_dir)/lib/$(ps_ver)/darwin-2level/Config_heavy.pl.bak
	@echo anonymised $(pc_dir)
	@touch $(pc_anon)
endif

$(pc_tgz): $(pc_anon)
ifndef NOPERL
	@tar -czf $(pc_tgz) -C $(build) $(pc_base)
	@test -f $(pc_tgz) || exit 1
	@echo created $(pc_tgz)
	@touch $(pc_tgz)
endif

pc-all: $(pc_tgz)

pc-clean:
	@rm -fr $(pc_dir) $(pc_tgz) $(pc_anon)
	@echo removed $(pc_dir) $(pc_tgz) $(pc_anon)

$(pg_dir): $(conan_install) $(cpm_exe) $(pb_dir) $(pc_tgz)
ifndef NOPERL
	$(eval $(shell if test -z "$(CONAN_ROOT_OPENSSL)"; then echo include $(conan_install)/conanbuildinfo.mak; fi))
	@mkdir -p $(pg_dir)
	@tar -xzf $(pc_tgz) --strip-components=1 -C $(pg_dir)
	@$(pb_off); \
		PATH="$(CONAN_BIN_DIRS_LIBXML2):$(PATH)" \
		OPENSSL_PREFIX="$(CONAN_ROOT_OPENSSL)" \
		$(pg_perl) $(cpm_exe) install -g --no-prebuilt --cpanfile cpanfile; \
		$(pb_dir)/bin/change-shebang -q -f $(pg_dir)/bin/*;
	@echo created $(pg_dir)
	@touch $(pg_dir)
endif

$(pg_anon): $(pg_dir)
ifndef NOPERL
	@find $(pg_dir) -type f -name perllocal.pod -exec rm -f {} \;
	@find $(pg_dir) -type f -name .packlist -exec rm -f {} \;
	@sed -i.bak -e "s/$$USER/nobody/g" $(pg_dir)/lib/site_perl/$(ps_ver)/darwin-2level/auto/share/dist/Alien-Libxml2/_alien/alien.json
	@rm -f $(pg_dir)/lib/site_perl/$(ps_ver)/darwin-2level/auto/share/dist/Alien-Libxml2/_alien/alien.json.bak
	@echo anonymised $(pg_dir)
	@touch $(pg_anon)
endif

$(pg_dylib): $(conan_dylib) $(pg_dir)
ifndef NOPERL
	$(eval $(shell if test -z "$(CONAN_LIB_DIRS_OPENSSL)"; then echo include $(conan_install)/conanbuildinfo.mak; fi))
	@mkdir -p $(pg_dylib)
	@$(ditto) $(conan_dylib)/*.dylib $(pg_dylib)
	@chmod +w $(pg_dylib)/*.dylib
	@install_name_tool \
		-id @rpath/$(libcrypto ) \
		$(pg_dylib)/$(libcrypto)
	@install_name_tool \
		-id @rpath/$(libssl) \
		-change "$(CONAN_LIB_DIRS_OPENSSL)/$(libcrypto)" @rpath/$(libcrypto) \
		$(pg_dylib)/$(libssl)
	@install_name_tool \
		-add_rpath $(rt_rpath) \
		$(pg_dylib)/$(libcharset)
	@install_name_tool \
		-add_rpath $(rt_rpath) \
		$(pg_dylib)/$(libiconv)
	@install_name_tool \
		-add_rpath $(rt_rpath) \
		$(pg_dylib)/$(libz)
	@install_name_tool \
		-delete_rpath "$(CONAN_LIB_DIRS_LIBICONV)" \
		-delete_rpath "$(CONAN_LIB_DIRS_ZLIB)" \
		-add_rpath $(rt_rpath) \
		$(pg_dylib)/$(libxml2)
	@chmod -w $(pg_dylib)/*.dylib
	@echo created $(pg_dylib)
	@touch $(pg_dylib)
endif

$(ssleay_bundle): $(pg_dylib)
ifndef NOPERL
	$(eval $(shell if test -z "$(CONAN_LIB_DIRS_OPENSSL)"; then echo include $(conan_install)/conanbuildinfo.mak; fi))
	@chmod +w $(ssleay_bundle)
	@install_name_tool \
		-change "$(CONAN_LIB_DIRS_OPENSSL)/$(libcrypto)" @rpath/$(libcrypto) \
		-change "$(CONAN_LIB_DIRS_OPENSSL)/$(libssl)" @rpath/$(libssl) \
		-change /usr/lib/$(sys_libz) @rpath/$(sys_libz) \
		-delete_rpath "$(CONAN_LIB_DIRS_OPENSSL):/usr/lib" \
		-add_rpath $(rt_rpath) \
		$(ssleay_bundle)
	@chmod -w $(ssleay_bundle)
	@echo edited $(ssleay_bundle)
	@touch $(ssleay_bundle)
endif

$(libxml_bundle): $(pg_dylib)
ifndef NOPERL
	$(eval $(shell if test -z "$(CONAN_LIB_DIRS_ZLIB)"; then echo include $(conan_install)/conanbuildinfo.mak; fi))
	@chmod +w $(libxml_bundle)
	@install_name_tool \
		-change /usr/lib/$(libxml2) @rpath/$(libxml2) \
		-change /usr/lib/$(libiconv) @rpath/$(libiconv) \
		-change /usr/lib/$(libcharset) @rpath/$(libcharset) \
		-delete_rpath "/usr/lib:$(CONAN_LIB_DIRS_ZLIB)" \
		-add_rpath $(rt_rpath) \
		$(libxml_bundle)
	@chmod -w $(libxml_bundle)
	@echo edited $(libxml_bundle)
	@touch $(libxml_bundle)
endif

$(pg_tgz): $(pg_anon) $(ssleay_bundle) $(libxml_bundle)
ifndef NOPERL
	@mkdir -p $(dir $(pg_tgz))
	@tar -czf $(pg_tgz) -C $(build) $(pg_base)
	@echo created $(pg_tgz)
	@touch $(pg_tgz)
endif

pg-all: $(pg_tgz)

pg-clean:
	@rm -fr $(pg_dir) $(pg_tgz) $(pg_anon)
	@echo removed $(pg_dir) $(pg_tgz) $(pg_anon)

$(ulg_perl): $(pg_tgz)
ifndef NOPERL
	@mkdir -p $(ulg_perl)
	@tar -xzf $(pg_tgz) --strip-components=1 -C $(ulg_perl) $(pg_base)/bin/perl $(pg_base)/lib $(pg_base)/dylib
	@echo created $(ulg_perl)
	@touch $(ulg_perl)
endif

perl-all: $(ulg_perl)

perl-clean:
	@rm -fr $(ulg_perl)
	@echo removed $(ulg_perl)

$(gip_tgz):
ifndef NOGIP
	@mkdir -p $(dir $(gip_tgz))
	@git --git-dir=$(gip_repo)/.git --work-tree=$(gip_repo) update-index --refresh --unmerged
	@git --git-dir=$(gip_repo)/.git archive --format=tgz $(gip_tag) > $(gip_tgz)
	@echo created $(gip_tgz)
	@touch $(gip_tgz)
endif

$(ulg_perl_bin): $(gip_tgz)
ifndef NOGIP
	@mkdir -p $(ulg_perl_bin)
	@tar -xzf $(gip_tgz) -C $(ulg_perl_bin) $(gip_perl_files)
	@sed -i.bak -E -e 's/^(my (\$$version_text|\$$VERSION_TEXT)).*/\1 = "$(pkg_ver)-$$^O";/' $(ulg_perl_bin)/{$(gip_perl_scripts)}
	@rm -f $(ulg_perl_bin)/{$(gip_perl_scripts)}.bak
	@$(pb_off); \
		chmod +w $(ulg_perl_bin)/{$(gip_perl_scripts)}; \
		$(pb_dir)/bin/change-shebang -q -f $(ulg_perl_bin)/{$(gip_perl_scripts)}}; \
		chmod -w $(ulg_perl_bin)/{$(gip_perl_scripts)}
	@echo created $(ulg_perl_bin)/{$(gip_perl_scripts)}
	@touch $(ulg_perl_bin)
endif

$(ulg)/credits.txt:
ifndef NOGIP
	@mkdir -p $(ulg)
	@$(ditto) credits.txt $(ulg)
	@echo created $(ulg)/credits.txt
	@touch $(ulg)/credits.txt
endif

$(ul_man1):
ifndef NOGIP
	@mkdir -p $(ul_man1)
	@tar -xzf $(gip_tgz) -C $(ul_man1) get_iplayer.1
	@echo created $(ul_man1)
	@touch $(ul_man1)
endif

$(ul_bin):
ifndef NOGIP
	@mkdir -p $(ul_bin)
	@$(ditto) $(gip_bin_files) $(ul_bin)
	@echo created $(ul_bin)
	@touch $(ul_bin)
endif

gip-all: $(ulg_perl_bin) $(ulg)/credits.txt $(ul_man1) $(ul_bin)

gip-clean:
	@rm -f $(ul_bin)/{$(gip_bin_scripts)}
	@echo removed $(ul_bin)/{$(gip_bin_scripts)}
	@rm -fr $(ul_man1)
	@echo removed $(ul_man1)
	@rm -f $(ulg)/credits.txt
	@echo removed $(ulg)/credits.txt
	@rm -f $(ulg_perl_bin)/{$(gip_perl_scripts)}
	@echo removed $(ulg_perl_bin)/{$(gip_perl_scripts)}

$(ap_zip_path):
ifndef NOUTILS
	@mkdir -p $(dir $(ap_zip_path))
	@curl -\#fkL -o $(ap_zip_path) $(ap_zip_url)
	@echo created $(ap_zip_path)
	@touch $(ap_zip_path)
endif

$(ulg_utils_bin)/AtomicParsley: $(ap_zip_path)
ifndef NOUTILS
	@mkdir -p $(ulg_utils_bin)
	@unzip -j -o -q $(ap_zip_path) AtomicParsley -d $(ulg_utils_bin)
	@chmod 755 $(ulg_utils_bin)/AtomicParsley
	@echo created $(ulg_utils_bin)/AtomicParsley
	@touch $(ulg_utils_bin)/AtomicParsley
endif

ap-all: $(ulg_utils_bin)/AtomicParsley

ap-clean:
	@rm -f $(ulg_utils_bin)/AtomicParsley
	@echo removed $(ulg_utils_bin)/AtomicParsley

$(ff_zip_path):
ifndef NOUTILS
	@mkdir -p $(dir $(ff_zip_path))
	curl -\#fkL -o $(ff_zip_path) $(ff_zip_url)
	@echo created $(ff_zip_path)
	@touch $(ff_zip_path)
endif

$(ulg_utils_bin)/ffmpeg: $(ff_zip_path)
ifndef NOUTILS
	@mkdir -p $(ulg_utils_bin)
	@gunzip -c $(ff_zip_path) > $(ulg_utils_bin)/ffmpeg
	@chmod 755 $(ulg_utils_bin)/ffmpeg
	@echo created $(ulg_utils_bin)/ffmpeg
	@touch $(ulg_utils_bin)/ffmpeg
endif

ff-all: $(ulg_utils_bin)/ffmpeg

ff-clean:
	@rm -f $(ulg_utils_bin)/ffmpeg
	@echo removed $(ulg_utils_bin)/ffmpeg

utils-all: ap-all ff-all

utils-clean: ap-clean ff-clean

$(lic_dir):
ifndef NOLICENSES
	@mkdir -p $(lic_dir)
	@curl -\#fkL -o $(lic_dir)/gpl.txt https://www.gnu.org/licenses/gpl.txt
	@curl -\#fkL -o $(lic_dir)/lgpl.txt https://www.gnu.org/licenses/lgpl.txt
	@curl -\#fkL -o $(lic_dir)/gpl-2.0.txt https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
	@curl -\#fkL -o $(lic_dir)/lgpl-2.1.txt https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt
	@curl -\#fkL -o $(lic_dir)/openssl.txt https://www.openssl.org/source/license-openssl-ssleay.txt
	@curl -\#fkL -o $(lic_dir)/gpl-1.0.txt https://www.gnu.org/licenses/old-licenses/gpl-1.0.txt
	@curl -\#fkL -o $(lic_dir)/artistic.txt https://raw.githubusercontent.com/Perl/perl5/blead/Artistic
	@curl -\#fkL -o $(lic_dir)/libxml2.txt https://raw.githubusercontent.com/GNOME/libxml2/master/Copyright
	@curl -\#fkL -o $(lic_dir)/zlib.html https://zlib.net/zlib_license.html
	@echo created $(lic_dir)
	@touch $(lic_dir)
endif

$(ulg_lic_dir): $(lic_dir)
ifndef NOLICENSES
	@mkdir -p $(ulg_lic_dir)/{get_iplayer,perl,atomicparsley,ffmpeg,openssl,libiconv,libxml2,zlib}
	@$(ditto) $(lic_dir)/gpl.txt $(ulg_lic_dir)/get_iplayer
	@$(ditto) $(lic_dir)/gpl-1.0.txt $(ulg_lic_dir)/perl
	@$(ditto) $(lic_dir)/gpl-2.0.txt $(ulg_lic_dir)/perl
	@$(ditto) $(lic_dir)/gpl.txt $(ulg_lic_dir)/perl
	@$(ditto) $(lic_dir)/artistic.txt $(ulg_lic_dir)/perl
	@$(ditto) $(lic_dir)/gpl-2.0.txt $(ulg_lic_dir)/atomicparsley
	@$(ditto) $(lic_dir)/lgpl-2.1.txt $(ulg_lic_dir)/ffmpeg
	@$(ditto) $(lic_dir)/lgpl.txt $(ulg_lic_dir)/ffmpeg
	@$(ditto) $(lic_dir)/gpl-2.0.txt $(ulg_lic_dir)/ffmpeg
	@$(ditto) $(lic_dir)/gpl.txt $(ulg_lic_dir)/ffmpeg
	@$(ditto) $(lic_dir)/openssl.txt $(ulg_lic_dir)/openssl
	@$(ditto) $(lic_dir)/libxml2.txt $(ulg_lic_dir)/libxml2
	@$(ditto) $(lic_dir)/lgpl-2.1.txt $(ulg_lic_dir)/libiconv
	@$(ditto) $(lic_dir)/zlib.html $(ulg_lic_dir)/zlib
	@echo created $(ulg_lic_dir)
	@touch $(ulg_lic_dir)
endif

lic-all: $(ulg_lic_dir)

lic-clean:
	@rm -fr $(ulg_lic_dir)
	@echo removed $(ulg_lic_dir)

$(apps_gip):
ifndef NOAPPS
	@mkdir -p $(apps_gip)
	@$(ditto) {get_iplayer,get_iplayer_cgi,"Check for Update","Run PVR Scheduler","Web PVR Manager","Uninstall get_iplayer"}.command $(apps_gip)
	@SetFile -a E $(apps_gip)/{get_iplayer,get_iplayer_cgi,"Check for Update","Run PVR Scheduler","Web PVR Manager","Uninstall get_iplayer"}.command
	@seticon get_iplayer.icns $(apps_gip)/get_iplayer.command
	@seticon get_iplayer_pvr.icns $(apps_gip)/{get_iplayer_cgi,"Run PVR Scheduler","Web PVR Manager"}.command
	@seticon get_iplayer_uninstall.icns $(apps_gip)/{"Check for Update","Uninstall get_iplayer"}.command
	@mkdir -p $(apps_gip)/Help
	@$(ditto) {get_iplayer,AtomicParsley,FFmpeg,Perl}" Documentation".webloc $(apps_gip)/Help
	@SetFile -a E $(apps_gip)/Help/{get_iplayer,AtomicParsley,FFmpeg,Perl}" Documentation".webloc
	@platypus --app-icon "get_iplayer.icns" --app-version $(pkg_ver) --author "get_iplayer"  \
		--bundle-identifier "com.github.get-iplayer.QuickURLRecord" --droppable \
		--interface-type "Progress Bar" --interpreter "/bin/bash" --name "Quick URL Record" \
		--service --suffixes "webloc" --text-droppable --text-font "Monaco 10" \
		"Quick URL Record.bash" "$(apps_gip)/Quick URL Record.app"
	@SetFile -a E "$(apps_gip)/Quick URL Record.app"
	@seticon get_iplayer.icns "$(apps_gip)/Quick URL Record.app"
	@$(ditto) "Download get_iplayer".webloc $(apps_gip)
	@echo created $(apps_gip)
	@touch $(apps_gip)
endif

apps-all: $(apps_gip)

apps-clean:
	@rm -fr $(apps_gip)
	@echo removed $(apps_gip)

deps-all: perl-all gip-all ap-all ff-all lic-all apps-all

deps-clean: perl-clean gip-clean ap-clean ff-clean lic-clean apps-clean

$(pkg_path): $(pkg_prj) $(ulg_perl) $(ulg_perl_bin) $(ulg)/credits.txt $(ul_man1) $(ul_bin) $(ulg_utils_bin)/AtomicParsley $(ulg_utils_bin)/ffmpeg $(ulg_lic_dir) $(apps_gip)
ifndef NOPKG
	@echo building $(pkg_path)
	@mkdir -p $(dir $(pkg_path))
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(pkg_ver)" $(pkg_prj)
	@packagesbuild --build-folder "$(PWD)/$(build)" --reference-folder "$(PWD)/$(pkg_src)" $(pkg_prj)
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(curr_ver)" $(pkg_prj)
	@mv -f $(pkg_out) $(pkg_path)
	@echo built $(pkg_path)
endif

$(pkg_chk_path): $(pkg_path)
ifndef NOPKG
	@pushd $(dir $(pkg_path)) > /dev/null; \
		shasum -a 256 $(pkg_file) > $(pkg_chk_file) || exit 2; \
	popd > /dev/null;
	@echo created $(pkg_chk_path)
endif

pkg-all: $(pkg_path) $(pkg_chk_path)

pkg-clean:
	@rm -f $(pkg_out) $(pkg_path) $(pkg_chk_path)
	@echo removed $(pkg_out) $(pkg_path) $(pkg_chk_path)

checkout:
ifndef WIP
	@git update-index --refresh --unmerged
	@git checkout master
endif

commit:
ifndef WIP
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(pkg_ver)" $(pkg_prj)
	@git commit -m $(pkg_ver) $(pkg_prj)
	@git tag $(pkg_ver)
	@echo tagged $(pkg_ver)
else
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(curr_ver)" $(pkg_prj)
	@echo reverted $(curr_ver)
endif

clean: pkg-clean deps-clean
	@rm -fr $(pkg_src)
	@echo removed $(pkg_src)

distclean: clean
	@rm -fr $(build)
	@echo removed $(build)

release: checkout pkg-all commit
	@echo built release $(pkg_ver)

install:
	@sudo installer -pkg $(pkg_path) -target /

install-gui:
	@open $(pkg_path)

uninstall:
	@/usr/local/bin/get_iplayer_uninstall
