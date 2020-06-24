# Build macOS installer for get_iplayer
# Prereqs: Packages, osxiconutils, platypus, Homebrew
# Prereqs: Xcode command line tools (installed w/Homebrew)
# Prereqs: #ifdef BREW: brew install libiconv libxml2 openssl zlib
# Prereqs: #else      : brew install conan
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
build := build
build_payload := $(build)/payload
pkg_name := get_iplayer
pkg_src := $(pkg_name).pkgproj
curr_version := $(shell /usr/libexec/PlistBuddy -c "Print :PACKAGES:0:PACKAGE_SETTINGS:VERSION" $(pkg_src))
ifeq ($(pkg_ver), 0.0.0)
pkg_ver := $(curr_version)
endif
next_version := $(shell echo $(pkg_ver) | awk -F. '{print $$1"."$$2"."$$3+1}')
pkg_out := $(pkg_name).pkg
build_pkg_out := $(build)/$(pkg_out)
pkg_file := $(pkg_name)-$(pkg_ver)-macos-x64.pkg
build_pkg_file := $(build)/$(pkg_file)
pd2l_base := perl-darwin-2level
pd2l_perl_ver := 5.32.0
pd2l_ver := $(pd2l_perl_ver).0
pd2l_tgz := $(pd2l_base)-$(pd2l_ver).tar.gz
pd2l_tgz_url := https://github.com/skaji/relocatable-perl/releases/download/$(pd2l_ver)/$(pd2l_base).tar.gz
build_pd2l_tgz := $(build)/$(pd2l_tgz)
build_pd2l := $(build)/$(pd2l_base)-$(pd2l_ver)
build_pd2l_bin := $(build_pd2l)/bin
build_pd2l_lib := $(build_pd2l)/lib
pd2l_exe := $(build_pd2l_bin)/perl
cpm_exe := $(build)/cpm
rlpl_base := relocatable-perl
rlpl_ver := $(pd2l_ver)
rlpl_tgz := $(rlpl_base)-$(rlpl_ver).tar.gz
rlpl_tgz_url := https://github.com/skaji/relocatable-perl/archive/$(rlpl_ver).tar.gz
build_rlpl_tgz := $(build)/$(rlpl_tgz)
build_rlpl := $(build)/$(rlpl_base)-$(rlpl_ver)
rlpl_exe := $(build_rlpl)/build/relocatable-perl-build
perl_base := perl
perl_ver := $(pd2l_ver)
perl_macos := 10.10
perl_tgz := $(perl_base)-$(perl_ver)-macos-$(perl_macos).tar.gz
build_perl_tgz = $(build)/$(perl_tgz)
build_perl := $(build)/$(perl_base)
build_perl_bin := $(build_perl)/bin
build_perl_lib := $(build_perl)/lib
build_perl_dylib := $(build_perl)/dylib
perl_exe := $(build_perl_bin)/perl
ssleay_bundle := $(build_perl_lib)/site_perl/$(pd2l_perl_ver)/darwin-2level/auto/Net/SSLeay/SSLeay.bundle
libxml_bundle := $(build_perl_lib)/site_perl/$(pd2l_perl_ver)/darwin-2level/auto/XML/LibXML/LibXML.bundle
gip_repo := ../get_iplayer
gip_zip := get_iplayer-$(gip_tag).zip
build_gip_zip := $(build)/$(gip_zip)
gip_tgz := get_iplayer-$(gip_tag).tar.gz
build_gip_tgz := $(build)/$(gip_tgz)
gip_perl_files := get_iplayer get_iplayer.cgi
gip_perl_scripts := get_iplayer,get_iplayer.cgi
gip_bin_files := get_iplayer get_iplayer_cgi get_iplayer_pvr get_iplayer_uninstall get_iplayer_web_pvr
gip_bin_scripts := get_iplayer,get_iplayer_cgi,get_iplayer_pvr,get_iplayer_uninstall,get_iplayer_web_pvr
atomicparsley_ver := 0.9.7-get_iplayer.1
atomicparsley_zip := AtomicParsley-$(atomicparsley_ver)-macos-x64.zip
atomicparsley_zip_url := https://github.com/get-iplayer/atomicparsley/releases/download/$(atomicparsley_ver)/$(atomicparsley_zip)
build_atomicparsley_zip := $(build)/$(atomicparsley_zip)
ffmpeg_ver := 4.3
ffmpeg_zip := ffmpeg-$(ffmpeg_ver)-macos64-static.zip
ffmpeg_zip_url := https://ffmpeg.zeranoe.com/builds/macos64/static/$(ffmpeg_zip)
build_ffmpeg_zip := $(build)/$(ffmpeg_zip)
build_licenses := $(build)/licenses
apps := $(build_payload)/Applications
apps_gip := $(apps)/get_iplayer
ifdef BREW
build_brew := $(build)/brew
build_brew_dylib := $(build_brew)/dylib
openssl_prefix := /usr/local/opt/openssl@1.1
libxml2_prefix := /usr/local/opt/libxml2
libiconv_prefix := /usr/local/opt/libiconv
zlib_prefix := /usr/local/opt/zlib
openssl_cellar := /usr/local/Cellar/openssl@1.1/$(shell $(openssl_prefix)/bin/openssl version | awk '{print $$2}')
BREW_LIB_DIRS_OPENSSL := $(openssl_prefix)/lib
BREW_LIB_DIRS_LIBXML2 := $(libxml2_prefix)/lib
BREW_LIB_DIRS_LIBICONV := $(libiconv_prefix)/lib
BREW_LIB_DIRS_ZLIB := $(zlib_prefix)/lib
else
build_conan := $(build)/conan
build_conan_dylib := $(build_conan)/dylib
build_conan_openssl := $(build_conan)/openssl
conan_user_home := $(PWD)/$(build_conan)/home
endif
libcrypto := libcrypto.1.1.dylib
libssl := libssl.1.1.dylib
libxml2 := libxml2.2.dylib
libiconv := libiconv.2.dylib
libz := libz.1.2.11.dylib
sys_libiconv := libiconv.2.dylib
sys_libz := libz.1.dylib
runtime_dylib := @executable_path/../dylib
ul := $(build_payload)/usr/local
ul_bin := $(ul)/bin
ul_man1 := $(ul)/share/man/man1
ulg := $(ul)/get_iplayer
ulg_bin := $(ulg)/bin
ulg_licenses := $(ulg)/licenses
ulg_perl := $(ulg)/perl
ulg_perl_bin := $(ulg_perl)/bin
ulg_perl_lib := $(ulg_perl)/lib
ulg_perl_dylib  := $(ulg_perl)/dylib
ulg_perl_exe := $(ulg_perl_bin)/perl
ulg_utils := $(ulg)/utils
ulg_utils_bin := $(ulg_utils)/bin
ditto := ditto --norsrc --noextattr --noacl

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

$(build_pd2l_tgz):
ifndef NOPERL
	@mkdir -p $(build)
	@curl -\#fkL -o $(build_pd2l_tgz) $(pd2l_tgz_url)
	@echo downloaded $(build_pd2l_tgz)
	@touch $(build_pd2l_tgz)
endif

$(build_pd2l): $(build_pd2l_tgz)
ifndef NOPERL
	@mkdir -p $(build_pd2l)
	@tar -xzf $(build_pd2l_tgz) --strip-components=1 -C $(build_pd2l)
	@echo created $(build_pd2l)
	@touch $(build_pd2l)
endif

pd2l: $(build_pd2l)

$(cpm_exe): $(build_pd2l)
ifndef NOPERL
	@mkdir -p $(build)
	@curl -fsSL --compressed -o $(cpm_exe) https://git.io/cpm
	@echo downloaded $(cpm_exe)
	@touch $(cpm_exe)
endif

$(build_rlpl_tgz): $(cpm_exe)
ifndef NOPERL
	@mkdir -p $(build)
	@curl -\#fkL -o $(build_rlpl_tgz) $(rlpl_tgz_url)
	@echo downloaded $(build_rlpl_tgz)
	@touch $(build_rlpl_tgz)
endif

$(build_rlpl): export MACOSX_DEPLOYMENT_TARGET = $(perl_macos)
$(build_rlpl): $(build_rlpl_tgz)
ifndef NOPERL
	@mkdir -p $(build_rlpl)
	@tar -xzf $(build_rlpl_tgz) --strip-components=1 -C $(build_rlpl)
	@$(pb_off); \
		$(pd2l_exe) $(cpm_exe) install -g --cpanfile $(build_rlpl)/build/cpanfile;
	@echo created $(build_rlpl)
	@touch $(build_rlpl)
endif

rlpl: $(build_rlpl)

$(build_perl): export MACOSX_DEPLOYMENT_TARGET = $(perl_macos)
$(build_perl): $(build_rlpl)
ifndef NOPERL
	@mkdir -p $(build_perl)
	@$(pd2l_exe) $(build_rlpl)/build/relocatable-perl-build --prefix "$(PWD)/$(build_perl)" --perl_version $$(cat $(build_rlpl)/BUILD_VERSION)
	@$(pb_off); \
		$(perl_exe) $(cpm_exe) install -g App::ChangeShebang LWP LWP::Protocol::https XML::LibXML Mojolicious CGI; \
		$(build_perl_bin)/change-shebang -f -q $(build_perl_bin)/*;
	@find $(build_perl) -type f -name perllocal.pod -exec rm -f {} \;
	@find $(build_perl) -type f -name .packlist -exec rm -f {} \;
	@echo created $(build_perl)
	@touch $(build_perl)
endif

$(build_brew):
ifdef BREW
	@mkdir -p $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_OPENSSL)/$(libcrypto) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_OPENSSL)/$(libssl) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_LIBXML2)/$(libxml2) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_LIBICONV)/$(libiconv) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_ZLIB)/$(libz) $(build_brew_dylib)
	@echo created $(build_brew)
	@touch $(build_brew)
endif

brew: $(build_brew)

$(build_conan): export CONAN_USER_HOME = $(conan_user_home)
$(build_conan): export MACOSX_DEPLOYMENT_TARGET = $(perl_macos)
$(build_conan):
ifndef BREW
	@mkdir -p $(build_conan)
	@conan install conanfile_dylib.txt --no-imports --install-folder $(build_conan) --build
	@conan imports conanfile_dylib.txt --install-folder $(build_conan) --import-folder $(build_conan_dylib)
	@conan imports conanfile_openssl.txt --install-folder $(build_conan) --import-folder $(build_conan_openssl)
	@$(ditto) $(build_conan)/libxml2.pc $(build_conan)/libxml-2.0.pc
	@chmod +w $(build_conan_openssl)/lib/$(libssl)
	@install_name_tool \
		-change $(libcrypto) @executable_path/../lib/$(libcrypto) \
		$(build_conan_openssl)/lib/$(libssl)
	@chmod -w $(build_conan_openssl)/lib/$(libssl)
	@chmod +w $(build_conan_openssl)/bin/openssl
	@install_name_tool \
		-change $(libssl) @executable_path/../lib/$(libssl) \
		-change $(libcrypto) @executable_path/../lib/$(libcrypto) \
		$(build_conan_openssl)/bin/openssl
	@chmod -w $(build_conan_openssl)/bin/openssl
	@echo created $(build_conan)
	@touch $(build_conan)
endif

conan: $(build_conan)

ifdef BREW
$(build_perl_dylib): $(build_brew)
else
$(build_perl_dylib): $(build_conan)
endif
ifndef NOPERL
	@mkdir -p $(build_perl_dylib)
ifdef BREW
	@$(ditto) $(build_brew_dylib)/*.dylib $(build_perl_dylib)
	@chmod +w $(build_perl_dylib)/$(libssl)
	@install_name_tool \
		-change $(openssl_cellar)/lib/$(libcrypto) $(runtime_dylib)/$(libcrypto) \
		$(build_perl_dylib)/$(libssl)
	@chmod -w $(build_perl_dylib)/$(libssl)
	@chmod +w $(build_perl_dylib)/$(libxml2)
	@install_name_tool \
		-change /usr/lib/$(sys_libz) $(runtime_dylib)/$(libz) \
		-change /usr/lib/$(sys_libiconv) $(runtime_dylib)/$(libiconv) \
		$(build_perl_dylib)/$(libxml2)
	@chmod -w $(build_perl_dylib)/$(libxml2)
else
	$(eval $(shell if test -z "$(CONAN_LIB_DIRS_ZLIB)"; then echo include $(build_conan)/conanbuildinfo.mak; fi))
	@$(ditto) $(build_conan_dylib)/*.dylib $(build_perl_dylib)
	@chmod +w $(build_perl_dylib)/$(libssl)
	@install_name_tool \
		-change $(libcrypto) $(runtime_dylib)/$(libcrypto) \
		$(build_perl_dylib)/$(libssl)
	@chmod -w $(build_perl_dylib)/$(libssl)
	@chmod +w $(build_perl_dylib)/$(libxml2)
	@install_name_tool \
		-change $(CONAN_LIB_DIRS_LIBICONV)/$(libiconv) $(runtime_dylib)/$(libiconv) \
		-change $(CONAN_LIB_DIRS_ZLIB)/$(sys_libz) $(runtime_dylib)/$(libz) \
		$(build_perl_dylib)/$(libxml2)
	@chmod -w $(build_perl_dylib)/$(libxml2)
endif
	@chmod +w $(build_perl_dylib)/*.dylib
	@install_name_tool -id $(libcrypto) $(build_perl_dylib)/$(libcrypto)
	@install_name_tool -id $(libssl) $(build_perl_dylib)/$(libssl)
	@install_name_tool -id $(libxml2) $(build_perl_dylib)/$(libxml2)
	@install_name_tool -id $(libiconv) $(build_perl_dylib)/$(libiconv)
	@install_name_tool -id $(libz) $(build_perl_dylib)/$(libz)
	@chmod -w $(build_perl_dylib)/*.dylib
	@echo created $(build_perl_dylib)
	@touch $(build_perl_dylib)
endif

dylib: $(build_perl_dylib)

ifdef BREW
$(ssleay_bundle): export OPENSSL_PREFIX = $(openssl_prefix)
$(ssleay_bundle): export PKG_CONFIG_PATH = $(libxml2_prefix)/lib/pkgconfig
else
$(ssleay_bundle): export OPENSSL_PREFIX = $(PWD)/$(build_conan_openssl)
$(ssleay_bundle): export PKG_CONFIG_PATH = $(PWD)/$(build_conan)
endif
$(ssleay_bundle): export MACOSX_DEPLOYMENT_TARGET = $(perl_macos)
$(ssleay_bundle): $(build_perl) $(build_perl_dylib)
ifndef NOPERL
	@chmod +w $(ssleay_bundle) $(libxml_bundle)
ifdef BREW
	@install_name_tool \
		-change $(BREW_LIB_DIRS_OPENSSL)/$(libcrypto) $(runtime_dylib)/$(libcrypto) \
		-change $(BREW_LIB_DIRS_OPENSSL)/$(libssl) $(runtime_dylib)/$(libssl) \
		-change /usr/lib/$(sys_libz) $(runtime_dylib)/$(libz) \
		$(ssleay_bundle)
	@install_name_tool \
		-change $(BREW_LIB_DIRS_LIBXML2)/$(libxml2) $(runtime_dylib)/$(libxml2) \
		$(libxml_bundle)
else
	$(eval $(shell if test -z "$(CONAN_LIB_DIRS_ZLIB)"; then echo include $(build_conan)/conanbuildinfo.mak; fi))
	@install_name_tool \
		-change $(libcrypto) $(runtime_dylib)/$(libcrypto) \
		-change $(libssl) $(runtime_dylib)/$(libssl) \
		-change $(CONAN_LIB_DIRS_ZLIB)/$(sys_libz) $(runtime_dylib)/$(libz) \
		$(ssleay_bundle)
	@install_name_tool \
		-change $(libxml2) $(runtime_dylib)/$(libxml2) \
		-change $(CONAN_LIB_DIRS_LIBICONV)/$(libiconv) $(runtime_dylib)/$(libiconv) \
		-change $(CONAN_LIB_DIRS_ZLIB)/$(sys_libz) $(runtime_dylib)/$(libz) \
		$(libxml_bundle)
endif
	@chmod -w $(ssleay_bundle) $(libxml_bundle)
	@echo created $(ssleay_bundle)
	@echo created $(libxml_bundle)
	@touch $(ssleay_bundle)
	@touch $(libxml_bundle)
endif

$(libxml_bundle): $(ssleay_bundle)

$(build_perl_tgz): $(ssleay_bundle)
ifndef NOPERL
	@mkdir -p $(build)
	@tar -czf $(build_perl_tgz) -C $(build) $(perl_base)
	@echo created $(build_perl_tgz)
	@touch $(build_perl_tgz)
endif

$(ulg_perl): $(build_perl_tgz)
ifndef NOPERL
	@mkdir -p $(ulg_perl)
	@tar -xzf $(build_perl_tgz) --strip-components=1 -C $(ulg_perl) perl/bin/perl perl/lib perl/dylib
	@echo created $(ulg_perl)
	@touch $(ulg_perl)
endif

perl: $(ulg_perl)

perlclean:
	@rm -fr $(ulg_perl)
	@echo removed $(ulg_perl)

$(build_gip_tgz):
ifndef NOGIP
	@mkdir -p $(build)
	@git --git-dir=$(gip_repo)/.git --work-tree=$(gip_repo) update-index --refresh --unmerged
	@git --git-dir=$(gip_repo)/.git archive --format=tgz $(gip_tag) > $(build_gip_tgz)
	@echo created $(build_gip_tgz)
	@touch $(build_gip_tgz)
endif

$(ulg_perl_bin)/get_iplayer: $(build_gip_tgz)
ifndef NOGIP
	@mkdir -p $(ulg_perl_bin)
	@tar -xzf $(build_gip_tgz) -C $(ulg_perl_bin) $(gip_perl_files)
	@sed -E -i.bak -e 's/^(my (\$$version_text|\$$VERSION_TEXT)).*/\1 = "$(pkg_ver)-$$^O";/' \
		$(ulg_perl_bin)/{$(gip_perl_scripts)}
	@rm -f $(ulg_perl_bin)/{$(gip_perl_scripts)}.bak
	@$(pb_off); \
		chmod +w $(ulg_perl_bin)/{$(gip_perl_scripts)}; \
		$(build_perl_bin)/change-shebang -f -q $(ulg_perl_bin)/{$(gip_perl_scripts)}; \
		chmod -w $(ulg_perl_bin)/{$(gip_perl_scripts)}
	@echo created $(ulg_perl_bin)/{$(gip_perl_scripts)}
	@touch $(ulg_perl_bin)/{$(gip_perl_scripts)}
endif

$(ulg_perl_bin)/get_iplayer.cgi: $(ulg_perl_bin)/get_iplayer

$(ulg)/sources.txt: $(ulg_perl_bin)/get_iplayer
ifndef NOGIP
	@mkdir -p $(ulg)
	@$(ditto) sources.txt $(ulg)
	@echo created $(ulg)/sources.txt
	@touch $(ulg)/sources.txt
endif

$(ul_man1): $(ulg)/sources.txt
ifndef NOGIP
	@mkdir -p $(ul_man1)
	@tar -xzf $(build_gip_tgz) -C $(ul_man1) get_iplayer.1
	@echo created $(ul_man1)
	@touch $(ul_man1)
endif

$(ul_bin): $(ul_man1)
ifndef NOGIP
	@mkdir -p $(ul_bin)
	@$(ditto) $(gip_bin_files) $(ul_bin)
	@echo created $(ul_bin)
	@touch $(ul_bin)
endif

gip: $(ul_bin)

gipclean:
	@rm -f $(ul_bin)/{$(gip_bin_scripts)}
	@echo removed $(ul_bin)/{$(gip_bin_scripts)}
	@rm -fr $(ul_man1)
	@echo removed $(ul_man1)
	@rm -f $(ulg)/sources.txt
	@echo removed $(ulg)/sources.txt
	@rm -f $(ulg_perl_bin)/{$(gip_perl_scripts)}
	@echo removed $(ulg_perl_bin)/{$(gip_perl_scripts)}

$(build_atomicparsley_zip):
ifndef NOUTILS
	@mkdir -p $(build)
	@curl -\#fkL -o $(build_atomicparsley_zip) $(atomicparsley_zip_url)
	@echo created $(build_atomicparsley_zip)
	@touch $(build_atomicparsley_zip)
endif

$(ulg_utils_bin)/AtomicParsley: $(build_atomicparsley_zip)
ifndef NOUTILS
	@mkdir -p $(ulg_utils_bin)
	@unzip -j -o -q $(build_atomicparsley_zip) AtomicParsley -d $(ulg_utils_bin)
	@echo created $(ulg_utils_bin)/AtomicParsley
	@touch $(ulg_utils_bin)/AtomicParsley
endif

atomicparsley: $(ulg_utils_bin)/AtomicParsley

atomicparsleyclean:
	@rm -f $(ulg_utils_bin)/AtomicParsley
	@echo removed $(ulg_utils_bin)/AtomicParsley

$(build_ffmpeg_zip):
ifndef NOUTILS
	@mkdir -p $(build)
	curl -\#fkL -o $(build_ffmpeg_zip) $(ffmpeg_zip_url)
	@echo created $(build_ffmpeg_zip)
	@touch $(build_ffmpeg_zip)
endif

$(ulg_utils_bin)/ffmpeg: $(build_ffmpeg_zip)
ifndef NOUTILS
	@mkdir -p $(ulg_utils_bin)
	@unzip -j -o -q $(build_ffmpeg_zip) */bin/ffmpeg -d $(ulg_utils_bin)
	@echo created $(ulg_utils_bin)/ffmpeg
	@touch $(ulg_utils_bin)/ffmpeg
endif

ffmpeg: $(ulg_utils_bin)/ffmpeg

ffmpegclean:
	@rm -f $(ulg_utils_bin)/ffmpeg
	@echo removed $(ulg_bin)/ffmpeg

utils: atomicparsley ffmpeg

utilsclean: atomicparsleyclean ffmpegclean

$(build_licenses):
ifndef NOLICENSES
	@mkdir -p $(build_licenses)
	@curl -\#fkL -o $(build_licenses)/gpl.txt https://www.gnu.org/licenses/gpl.txt
	@curl -\#fkL -o $(build_licenses)/lgpl.txt https://www.gnu.org/licenses/lgpl.txt
	@curl -\#fkL -o $(build_licenses)/gpl-2.0.txt https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
	@curl -\#fkL -o $(build_licenses)/lgpl-2.1.txt https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt
	@curl -\#fkL -o $(build_licenses)/openssl.txt https://www.openssl.org/source/license-openssl-ssleay.txt
	@curl -\#fkL -o $(build_licenses)/gpl-1.0.txt https://www.gnu.org/licenses/old-licenses/gpl-1.0.txt
	@curl -\#fkL -o $(build_licenses)/artistic.txt https://raw.githubusercontent.com/Perl/perl5/blead/Artistic
	@curl -\#fkL -o $(build_licenses)/libxml2.txt https://raw.githubusercontent.com/GNOME/libxml2/mainline/Copyright
	@curl -\#fkL -o $(build_licenses)/zlib.html https://zlib.net/zlib_license.html
	@echo created $(build_licenses)
	@touch $(build_licenses)
endif

$(ulg_licenses): $(build_licenses)
ifndef NOLICENSES
	@mkdir -p $(ulg_licenses)/{get_iplayer,perl,atomicparsley,ffmpeg,openssl,libiconv,libxml2,zlib}
	@$(ditto) $(build_licenses)/gpl.txt $(ulg_licenses)/get_iplayer
	@$(ditto) $(build_licenses)/gpl-1.0.txt $(ulg_licenses)/perl
	@$(ditto) $(build_licenses)/gpl-2.0.txt $(ulg_licenses)/perl
	@$(ditto) $(build_licenses)/gpl.txt $(ulg_licenses)/perl
	@$(ditto) $(build_licenses)/artistic.txt $(ulg_licenses)/perl
	@$(ditto) $(build_licenses)/gpl-2.0.txt $(ulg_licenses)/atomicparsley
	@$(ditto) $(build_licenses)/lgpl-2.1.txt $(ulg_licenses)/ffmpeg
	@$(ditto) $(build_licenses)/lgpl.txt $(ulg_licenses)/ffmpeg
	@$(ditto) $(build_licenses)/gpl-2.0.txt $(ulg_licenses)/ffmpeg
	@$(ditto) $(build_licenses)/gpl.txt $(ulg_licenses)/ffmpeg
	@$(ditto) $(build_licenses)/openssl.txt $(ulg_licenses)/openssl
	@$(ditto) $(build_licenses)/libxml2.txt $(ulg_licenses)/libxml2
	@$(ditto) $(build_licenses)/lgpl-2.1.txt $(ulg_licenses)/libiconv
	@$(ditto) $(build_licenses)/zlib.html $(ulg_licenses)/zlib
	@echo created $(ulg_licenses)
	@touch $(ulg_licenses)
endif

licenses: $(ulg_licenses)

licensesclean:
	@rm -fr $(ulg_licenses)
	@echo removed $(ulg_licenses)

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
		--bundle-identifier "com.github.get-iplayer.QuickURLRecord"  --droppable \
		--interface-type "Progress Bar" --interpreter "/bin/bash" --name "Quick URL Record" \
		--service --suffixes "webloc" --text-droppable --text-font "Monaco 10" \
		"Quick URL Record.bash" "$(apps_gip)/Quick URL Record.app"
	@SetFile -a E "$(apps_gip)/Quick URL Record.app"
	@seticon get_iplayer.icns "$(apps_gip)/Quick URL Record.app"
	@$(ditto) "Download get_iplayer".webloc $(apps_gip)
	@echo created $(apps_gip)
	@touch $(apps_gip)
endif

apps: $(apps_gip)

appsclean:
	@rm -fr $(apps_gip)
	@echo removed $(apps_gip)

deps: perl gip atomicparsley ffmpeg licenses apps

depsclean: perlclean gipclean atomicparsleyclean ffmpegclean licensesclean appsclean

$(build_pkg_file): $(pkg_src)
ifndef NOPKG
	@echo building $(build_pkg_file)
	@mkdir -p $(build)
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(pkg_ver)" $(pkg_src)
	@packagesbuild --build-folder "$(PWD)/$(build)" $(pkg_src)
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(curr_version)" $(pkg_src)
	@mv -f $(build_pkg_out) $(build_pkg_file)
	@pushd $(build) > /dev/null; \
		shasum -a 256 $(pkg_file) > $(pkg_file).sha256 || exit 2; \
	popd > /dev/null;
	@echo built $(build_pkg_file)
endif

pkg: $(build_pkg_file)

pkgclean:
	@rm -f $(build_pkg_out) $(build_pkg_file) $(build_pkg_file).sha256
	@echo removed $(build_pkg_file)

checkout:
ifndef WIP
	@git update-index --refresh --unmerged
	@git checkout master
endif

commit:
ifndef WIP
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(pkg_ver)" $(pkg_src)
	@git commit -m $(pkg_ver) $(pkg_src)
	@git tag $(pkg_ver)
	@git checkout contribute
	@git merge master
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(next_version)" $(pkg_src)
	@git commit -m "bump dev version" $(pkg_src)
	@git checkout master
	@echo tagged $(pkg_ver)
endif

clean:
	@rm -f $(build_pkg_file) $(build_pkg_file).sha256
	@echo removed $(build_pkg_file)
	@rm -fr $(build_payload)
	@echo removed $(build_payload)

distclean: clean
	@rm -fr $(build)
	@echo removed $(build)

release: clean checkout deps pkg commit
	@echo built release $(pkg_ver)

install:
	@sudo installer -pkg $(build_pkg_file) -target /

installgui:
	@open $(build_pkg_file)

uninstall:
	@/usr/local/bin/get_iplayer_uninstall

