# Build macOS installer for get_iplayer
# Requires: Packages, Xcode CLT, osxiconutils, platypus, unar, Homebrew
# Requires: (default): brew install conan
# Requires: BREW=1: brew install openssl libxml2 zlib libiconv
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
	VERSION := 0.00
	WIP := 1
else
	gip_tag := v$(VERSION)
endif
ifndef PATCH
	PATCH := 0
endif
ifdef TAG
	gip_tag := $(TAG)
endif

build := build
build_payload := $(build)/payload
pkg_name := get_iplayer
pkg_ver := $(VERSION).$(PATCH)
pkg_src := $(pkg_name).pkgproj
pkg_file := $(pkg_name)-$(pkg_ver).pkg
build_pkg_file := $(build)/$(pkg_file)
gip_repo := ../get_iplayer
gip_zip := get_iplayer-$(gip_tag).zip
build_gip_zip := $(build)/$(gip_zip)
pd2l := perl-darwin-2level
pd2l_ver := 5.30.1
pd2l_work := /tmp/pd2l
pd2l_tag := $(pd2l_ver).1
pd2l_macos := 10.10
pd2l_tgz := $(pd2l)-$(pd2l_tag)-macos-$(pd2l_macos).tar.gz
# pd2l_tgz_url := https://github.com/skaji/relocatable-perl/releases/download/$(pd2l_tag)/$(pd2l).tar.gz
build_pd2l_tgz = $(build)/$(pd2l_tgz)
build_pd2l := $(build)/$(pd2l)
build_pd2l_bin := $(build_pd2l)/bin
build_pd2l_lib := $(build_pd2l)/lib
build_pd2l_dylib := $(build_pd2l)/dylib
shebang_scripts := hypnotoad,lwp-download,lwp-dump,lwp-mirror,lwp-request,mojo,morbo
ssleay_bundle := $(build_pd2l_lib)/site_perl/$(pd2l_ver)/darwin-2level/auto/Net/SSLeay/SSLeay.bundle
libxml_bundle := $(build_pd2l_lib)/site_perl/$(pd2l_ver)/darwin-2level/auto/XML/LibXML/LibXML.bundle
gip_files := get_iplayer get_iplayer.cgi
gip_scripts := get_iplayer,get_iplayer.cgi
atomicparsley_zip := AtomicParsley-0.9.6-macos-bin.zip
atomicparsley_zip_url := https://sourceforge.net/projects/get-iplayer/files/utils/$(atomicparsley_zip)
build_atomicparsley_zip := $(build)/$(atomicparsley_zip)
ffmpeg_7z := ffmpeg-4.2.1.7z
ffmpeg_7z_url := https://evermeet.cx/pub/ffmpeg/$(ffmpeg_7z)
build_ffmpeg_7z := $(build)/$(ffmpeg_7z)
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
# conan_user_home := /tmp/conan
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
ulg_pd2l := $(ulg)/$(pd2l)
ulg_pd2l_bin := $(ulg_pd2l)/bin
ulg_pd2l_lib := $(ulg_pd2l)/lib
ulg_pd2l_dylib  := $(ulg_pd2l)/dylib
curr_version := $(shell /usr/libexec/PlistBuddy -c "Print :PACKAGES:0:PACKAGE_SETTINGS:VERSION" $(pkg_src))
curr_name := $(shell /usr/libexec/PlistBuddy -c "Print :PROJECT:PROJECT_SETTINGS:NAME" $(pkg_src))
ditto := ditto --norsrc --noextattr --noacl

define pb_off
	if [ ! -z $(PERLBREW_PERL) ]; then \
		if [ -z $(PERLBREW_ROOT) ]; then \
			echo $(pkg_name): "Cannot find perlbrew root: $(PERLBREW_ROOT)"; \
			exit 4; \
		fi; \
		if [ ! -f "$(PERLBREW_ROOT)/etc/bashrc" ]; then \
			echo $(pkg_name): "Cannot find perlbrew init: $(PERLBREW_ROOT)/etc/bashrc"; \
			exit 4; \
		fi; \
		source "$(PERLBREW_ROOT)/etc/bashrc"; \
		perlbrew off; \
	fi
endef

dummy:
	@echo Nothing to make

$(build_pd2l_tgz): export MACOSX_DEPLOYMENT_TARGET = $(pd2l_macos)
$(build_pd2l_tgz):
ifndef NOPERL
	@mkdir -p $(build)
	@$(pb_off); \
	set -ex; \
	rm -fr $(pd2l_work); \
	mkdir -p $(pd2l_work); \
	pushd $(pd2l_work); \
		curl -fsSL https://git.io/perl-install | bash -s perl; \
		curl -fsSL --compressed -o cpm https://git.io/cpm; \
		git clone https://github.com/skaji/relocatable-perl.git; \
		pushd relocatable-perl; git checkout $(pd2l_tag); popd; \
		perl/bin/perl cpm install -g --cpanfile relocatable-perl/build/cpanfile; \
		build=$(pd2l); rm -fr $$build; mkdir -p $$build; prefix=$(pd2l_work)/$$build; \
		perl/bin/perl relocatable-perl/build/relocatable-perl-build --prefix $$prefix --perl_version $$(cat relocatable-perl/BUILD_VERSION); \
		$$build/bin/perl cpm install -g App::cpanminus App::ChangeShebang; \
		$$build/bin/change-shebang -f $$build/bin/*; \
		tar -czf $(pd2l_tgz) $$build; \
	popd; \
	cp $(pd2l_work)/$(pd2l_tgz) $(build) && rm -fr $(pd2l_work)
# 	@mkdir -p $(build)
# 	@pushd $(build); \
# 		if [ ! -f $(pd2l_tgz) ]; then \
# 			echo Downloading $(pd2l_tgz); \
# 			curl -\#fkL -o $(pd2l_tgz) $(pd2l_tgz_url) || exit 3; \
# 		fi; \
# 	popd
	@echo created $(build_pd2l_tgz)
endif

$(build_pd2l): $(build_pd2l_tgz)
ifndef NOPERL
	@mkdir -p $(build)
	@tar -C $(build) -xzf $(build_pd2l_tgz)
	@echo created $(build_pd2l)
endif

pd2l: $(build_pd2l)

$(build_brew):
ifdef BREW
	@mkdir -p $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_OPENSSL)/$(libcrypto) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_OPENSSL)/$(libssl) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_LIBXML2)/$(libxml2) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_LIBICONV)/$(libiconv) $(build_brew_dylib)
	@$(ditto) $(BREW_LIB_DIRS_ZLIB)/$(libz) $(build_brew_dylib)
	@echo created $(build_brew)
endif

brew: $(build_brew)

$(build_conan): export CONAN_USER_HOME = $(conan_user_home)
$(build_conan): export MACOSX_DEPLOYMENT_TARGET = $(pd2l_macos)
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
endif

conan: $(build_conan)

ifdef BREW
$(build_pd2l_dylib): $(build_brew)
else
$(build_pd2l_dylib): $(build_conan)
endif
$(build_pd2l_dylib): $(build_pd2l)
ifndef NOPERL
	@mkdir -p $(build_pd2l_dylib)
ifdef BREW
	@$(ditto) $(build_brew_dylib)/*.dylib $(build_pd2l_dylib)
	@chmod +w $(build_pd2l_dylib)/$(libssl)
	@install_name_tool \
		-change $(openssl_cellar)/lib/$(libcrypto) $(runtime_dylib)/$(libcrypto) \
		$(build_pd2l_dylib)/$(libssl)
	@chmod -w $(build_pd2l_dylib)/$(libssl)
	@chmod +w $(build_pd2l_dylib)/$(libxml2)
	@install_name_tool \
		-change /usr/lib/$(sys_libz) $(runtime_dylib)/$(libz) \
		-change /usr/lib/$(sys_libiconv) $(runtime_dylib)/$(libiconv) \
		$(build_pd2l_dylib)/$(libxml2)
	@chmod -w $(build_pd2l_dylib)/$(libxml2)
else
	$(eval $(shell if test -z "$(CONAN_LIB_DIRS_ZLIB)"; then echo include $(build_conan)/conanbuildinfo.mak; fi))
	@$(ditto) $(build_conan_dylib)/*.dylib $(build_pd2l_dylib)
	@chmod +w $(build_pd2l_dylib)/$(libssl)
	@install_name_tool \
		-change $(libcrypto) $(runtime_dylib)/$(libcrypto) \
		$(build_pd2l_dylib)/$(libssl)
	@chmod -w $(build_pd2l_dylib)/$(libssl)
	@chmod +w $(build_pd2l_dylib)/$(libxml2)
	@install_name_tool \
		-change $(CONAN_LIB_DIRS_LIBICONV)/$(libiconv) $(runtime_dylib)/$(libiconv) \
		-change $(CONAN_LIB_DIRS_ZLIB)/$(sys_libz) $(runtime_dylib)/$(libz) \
		$(build_pd2l_dylib)/$(libxml2)
	@chmod -w $(build_pd2l_dylib)/$(libxml2)
endif
	@chmod +w $(build_pd2l_dylib)/*.dylib
	@install_name_tool -id $(libcrypto) $(build_pd2l_dylib)/$(libcrypto)
	@install_name_tool -id $(libssl) $(build_pd2l_dylib)/$(libssl)
	@install_name_tool -id $(libxml2) $(build_pd2l_dylib)/$(libxml2)
	@install_name_tool -id $(libiconv) $(build_pd2l_dylib)/$(libiconv)
	@install_name_tool -id $(libz) $(build_pd2l_dylib)/$(libz)
	@chmod -w $(build_pd2l_dylib)/*.dylib
	@echo created $(build_pd2l_dylib)
endif

dylib: $(build_pd2l_dylib)

ifdef BREW
$(ssleay_bundle): export OPENSSL_PREFIX = $(openssl_prefix)
$(ssleay_bundle): export PKG_CONFIG_PATH = $(libxml2_prefix)/lib/pkgconfig
else
$(ssleay_bundle): export OPENSSL_PREFIX = $(PWD)/$(build_conan_openssl)
$(ssleay_bundle): export PKG_CONFIG_PATH = $(PWD)/$(build_conan)
endif
$(ssleay_bundle): export MACOSX_DEPLOYMENT_TARGET = $(pd2l_macos)
$(ssleay_bundle): $(build_pd2l) $(build_pd2l_dylib)
ifndef NOPERL
	@$(pb_off); \
	$(build_pd2l_bin)/cpanm -n --installdeps .; \
	chmod +w $(build_pd2l_bin)/{$(shebang_scripts)}; \
	$(build_pd2l_bin)/change-shebang -f -q $(build_pd2l_bin)/{$(shebang_scripts)}; \
	chmod -w $(build_pd2l_bin)/{$(shebang_scripts)}
	@find $(build_pd2l) -type f -name perllocal.pod -exec rm -f {} \;
	@find $(build_pd2l) -type f -name .packlist -exec rm -f {} \;
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
endif

$(libxml_bundle): $(ssleay_bundle)

$(ulg_pd2l): $(libxml_bundle)
ifndef NOPERL
	@mkdir -p $(ulg_pd2l)
	@$(ditto) $(build_pd2l) $(ulg_pd2l)
	@echo created $(ulg_pd2l)
endif

perl: $(ulg_pd2l)
# 	@rm -fr $(conan_user_home)

$(build_gip_zip):
ifndef NOGIP
	@mkdir -p $(build)
	@git --git-dir=$(gip_repo)/.git --work-tree=$(gip_repo) update-index --refresh --unmerged
	@git --git-dir=$(gip_repo)/.git archive --format=zip $(gip_tag) > $(build_gip_zip)
	@echo created $(build_gip_zip)
endif

$(ulg_pd2l_bin)/get_iplayer: $(ulg_pd2l_bin) $(build_gip_zip)
ifndef NOGIP
	@rm -f $(ulg_pd2l_bin)/{$(gip_scripts)}
	@unar -f -D -q -o $(ulg_pd2l_bin) $(build_gip_zip) $(gip_files)
	@sed -E -i.bak -e 's/^(my (\$$version_text|\$$VERSION_TEXT)).*/\1 = "$(pkg_ver)-$$^O";/' \
		$(ulg_pd2l_bin)/{$(gip_scripts)}
	@rm -f $(ulg_pd2l_bin)/{$(gip_scripts)}.bak
	@$(pb_off); \
	chmod +w $(ulg_pd2l_bin)/{$(gip_scripts)}; \
	$(ulg_pd2l_bin)/change-shebang -f -q $(ulg_pd2l_bin)/{$(gip_scripts)}; \
	chmod -w $(ulg_pd2l_bin)/{$(gip_scripts)}
	@echo created $(ulg_pd2l_bin)/{$(gip_scripts)}
endif

$(ulg_pd2l_bin)/get_iplayer.cgi: $(ulg_pd2l_bin)/get_iplayer

$(ul_bin):
ifndef NOGIP
	@mkdir -p $(ul_bin)
	@$(ditto) get_iplayer get_iplayer_cgi get_iplayer_pvr get_iplayer_uninstall get_iplayer_web_pvr $(ul_bin)
	@echo created $(ul_bin)
endif

$(ul_man1): $(build_gip_zip)
ifndef NOGIP
	@mkdir -p $(ul_man1)
	@unar -f -D -q -o $(ul_man1) $(build_gip_zip) get_iplayer.1
	@echo created $(ul_man1)
endif

gip: $(ulg_pd2l_bin)/get_iplayer.cgi $(ul_bin) $(ul_man1)

$(ulg_bin):
ifndef NOUTILS
	@mkdir -p $(ulg_bin)
	@$(ditto) sources.txt $(ulg_bin)
	@echo created $(ulg_bin)
endif

$(build_atomicparsley_zip):
ifndef NOUTILS
	@mkdir -p $(build)
	@pushd $(build); \
		if [ ! -f $(atomicparsley_zip) ]; then \
			echo Downloading $(atomicparsley_zip); \
			curl -\#fkLO $(atomicparsley_zip_url) || exit 3; \
		fi; \
	popd
	@echo created $(build_atomicparsley_zip)
endif

$(ulg_bin)/AtomicParsley: $(ulg_bin) $(build_atomicparsley_zip)
ifndef NOUTILS
	@unar -f -D -q -o $(ulg_bin) $(build_atomicparsley_zip) AtomicParsley
	@echo created $(ulg_bin)/AtomicParsley
endif

atomicparsley: $(ulg_bin)/AtomicParsley

$(build_ffmpeg_7z):
ifndef NOUTILS
	@mkdir -p $(build)
	@pushd $(build); \
		if [ ! -f $(ffmpeg_7z) ]; then \
			echo Downloading $(ffmpeg_7z); \
			curl -\#fkLO $(ffmpeg_7z_url) || exit 3; \
		fi; \
	popd
	@echo created $(build_ffmpeg_7z)
endif

$(ulg_bin)/ffmpeg: $(ulg_bin) $(build_ffmpeg_7z)
ifndef NOUTILS
	@unar -f -D -q -o $(ulg_bin) $(build_ffmpeg_7z) ffmpeg
	@echo created $(ulg_bin)/ffmpeg
endif

ffmpeg: $(ulg_bin)/ffmpeg

$(build_licenses):
ifndef NOLICENSES
	@mkdir -p $(build_licenses)
	@pushd $(build_licenses); \
		if [ ! -f gpl.txt ]; then \
			echo Downloading gpl.txt; \
			curl -\#fkLO https://www.gnu.org/licenses/gpl.txt || exit 3; \
		fi; \
		if [ ! -f lgpl.txt ]; then \
			echo Downloading lgpl.txt; \
			curl -\#fkLO https://www.gnu.org/licenses/lgpl.txt || exit 3; \
		fi; \
		if [ ! -f gpl-2.0.txt ]; then \
			echo Downloading gpl-2.0.txt; \
			curl -\#fkLO https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt || exit 3; \
		fi; \
		if [ ! -f lgpl-2.1.txt ]; then \
			echo Downloading lgpl-2.1.txt; \
			curl -\#fkLO https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt || exit 3; \
		fi; \
		if [ ! -f openssl.txt ]; then \
			echo Downloading openssl.txt; \
			curl -\#fkL -o openssl.txt https://www.openssl.org/source/license-openssl-ssleay.txt || exit 3; \
		fi; \
		if [ ! -f gpl-1.0.txt ]; then \
			echo Downloading gpl-1.0.txt; \
			curl -\#fkLO https://www.gnu.org/licenses/old-licenses/gpl-1.0.txt || exit 3; \
		fi; \
		if [ ! -f artistic.txt ]; then \
			echo Downloading artistic.txt; \
			curl -\#fkL -o artistic.txt https://raw.githubusercontent.com/Perl/perl5/blead/Artistic || exit 3; \
		fi; \
		if [ ! -f libxml2.txt ]; then \
			echo Downloading libxml2.txt; \
			curl -\#fkL -o libxml2.txt https://raw.githubusercontent.com/GNOME/libxml2/mainline/Copyright || exit 3; \
		fi; \
		if [ ! -f zlib.html ]; then \
			echo Downloading zlib.html; \
			curl -\#fkL -o zlib.html https://zlib.net/zlib_license.html || exit 3; \
		fi; \
	popd
	@echo created $(build_licenses)
endif

$(ulg_licenses): $(build_licenses)
ifndef NOLICENSES
	@mkdir -p $(ulg_licenses)
	@$(ditto) $(build_licenses)/gpl.txt $(ulg_licenses)/get_iplayer.txt
	@$(ditto) $(build_licenses)/gpl-2.0.txt $(ulg_licenses)/atomicparsley.txt
	@$(ditto) $(build_licenses)/lgpl-2.1.txt $(ulg_licenses)/ffmpeg1.txt
	@$(ditto) $(build_licenses)/lgpl.txt $(ulg_licenses)/ffmpeg2.txt
	@$(ditto) $(build_licenses)/gpl-2.0.txt $(ulg_licenses)/ffmpeg3.txt
	@$(ditto) $(build_licenses)/gpl.txt $(ulg_licenses)/ffmpeg4.txt
	@$(ditto) $(build_licenses)/openssl.txt $(ulg_licenses)/openssl.txt
	@$(ditto) $(build_licenses)/gpl-1.0.txt $(ulg_licenses)/perl1.txt
	@$(ditto) $(build_licenses)/gpl-2.0.txt $(ulg_licenses)/perl2.txt
	@$(ditto) $(build_licenses)/gpl.txt $(ulg_licenses)/perl3.txt
	@$(ditto) $(build_licenses)/artistic.txt $(ulg_licenses)/perl4.txt
	@$(ditto) $(build_licenses)/libxml2.txt $(ulg_licenses)/libxml2.txt
	@$(ditto) $(build_licenses)/lgpl-2.1.txt $(ulg_licenses)/libiconv.txt
	@$(ditto) $(build_licenses)/zlib.html $(ulg_licenses)/zlib.html
	@echo created $(ulg_licenses)
endif

licenses: $(ulg_licenses)

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
endif

apps: $(apps_gip)

deps: perl gip atomicparsley ffmpeg licenses apps

$(build_pkg_file): $(pkg_src)
ifndef NOPKG
	@mkdir -p $(build)
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(pkg_ver)" $(pkg_src)
	@/usr/libexec/PlistBuddy -c "Set :PROJECT:PROJECT_SETTINGS:NAME $(pkg_name)-$(pkg_ver)" $(pkg_src)
	@packagesbuild --build-folder "$$(pwd)/$(build)" $(pkg_src)
	@pushd $(build); \
		md5 -r $(pkg_file) > $(pkg_file).md5 || exit 6; \
		shasum -a 1 $(pkg_file) > $(pkg_file).sha1 || exit 6; \
		shasum -a 256 $(pkg_file) > $(pkg_file).sha256 || exit 6; \
	popd
	@echo built $(build_pkg_file)
endif

pkg: $(build_pkg_file)

checkout:
ifndef WIP
	@git update-index --refresh --unmerged
	@git checkout master
endif

commit:
ifndef WIP
	@git commit -m $(pkg_ver) $(pkg_src)
	@git tag $(pkg_ver)
	@git checkout contribute
	@git merge master
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(curr_version)" $(pkg_src)
	@/usr/libexec/PlistBuddy -c "Set :PROJECT:PROJECT_SETTINGS:NAME $(curr_name)" $(pkg_src)
	@git commit -m "revert dev version" $(pkg_src)
	@git checkout master
	@echo tagged $(pkg_ver)
else
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(curr_version)" $(pkg_src)
	@/usr/libexec/PlistBuddy -c "Set :PROJECT:PROJECT_SETTINGS:NAME $(curr_name)" $(pkg_src)
endif

clean:
	@rm -f $(build_pkg_file)
	@rm -f $(build_pkg_file).{md5,sha1,sha256}
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

uninstall:
	@/usr/local/bin/get_iplayer_uninstall

