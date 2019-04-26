# Build macOS installer for get_iplayer
# Requires: Packages, Xcode CLT, cpanminus, osxiconutils, platypus, unar
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
pkg_base := $(pkg_name)-$(pkg_ver)
pkg_file := $(pkg_base).pkg
build_pkg := $(build)
gip_repo := ../get_iplayer
gip_zip := get_iplayer-$(gip_tag).zip
build_gip := $(build)
build_gip_zip := $(build_gip)/$(gip_zip)
build_perl5 := $(build)/perl5
atomicparsley_zip := AtomicParsley-0.9.6-macos-bin.zip
atomicparsley_zip_url := https://sourceforge.net/projects/get-iplayer/files/utils/$(atomicparsley_zip)
build_atomicparsley := $(build)
build_atomicparsley_zip := $(build_atomicparsley)/$(atomicparsley_zip)
ffmpeg_7z := ffmpeg-4.1.3.7z
ffmpeg_7z_url := https://evermeet.cx/pub/ffmpeg/$(ffmpeg_7z)
build_ffmpeg := $(build)
build_ffmpeg_7z := $(build_ffmpeg)/$(ffmpeg_7z)
build_licenses := $(build)/licenses
ul := $(build_payload)/usr/local
ul_bin := $(ul)/bin
ul_man1 := $(ul)/share/man/man1
ulg := $(ul)/get_iplayer
ulg_bin := $(ulg)/bin
ulg_licenses := $(ulg)/licenses
ulg_perl5 := $(ulg)/perl5
apps := $(build_payload)/Applications
apps_gip := $(apps)/get_iplayer
mozilla-ca_tgz := Mozilla-CA-20180117.tar.gz
mozilla-ca_tgz_url := https://cpan.metacpan.org/authors/id/A/AB/ABH/$(mozilla-ca_tgz)
io-socket-ssl_tgz := IO-Socket-SSL-2.060.tar.gz
io-socket-ssl_tgz_url := https://cpan.metacpan.org/authors/id/S/SU/SULLR/$(io-socket-ssl_tgz)
io-socket-ip_tgz := IO-Socket-IP-0.39.tar.gz
io-socket-ip_tgz_url := https://cpan.metacpan.org/authors/id/P/PE/PEVANS/$(io-socket-ip_tgz)
mojolicious_tgz := Mojolicious-8.02.tar.gz
mojolicious_tgz_url := https://cpan.metacpan.org/authors/id/S/SR/SRI/$(mojolicious_tgz)
curr_version := $(shell /usr/libexec/PlistBuddy -c "Print :PACKAGES:0:PACKAGE_SETTINGS:VERSION" "$(pkg_src)")
curr_name := $(shell /usr/libexec/PlistBuddy -c "Print :PROJECT:PROJECT_SETTINGS:NAME" "$(pkg_src)")
ditto := ditto --norsrc --noextattr --noacl

dummy:
	@echo Nothing to make

$(ul_bin):
ifndef NOGIP
	@mkdir -p "$(ul_bin)"
	@$(ditto) get_iplayer get_iplayer_cgi get_iplayer_pvr get_iplayer_uninstall get_iplayer_web_pvr "$(ul_bin)"
	@echo created $(ul_bin)
endif

$(build_gip_zip):
ifndef NOGIP
	@mkdir -p "$(build_gip)"
	@git --git-dir="$(gip_repo)"/.git --work-tree="$(gip_repo)" update-index --refresh --unmerged
	@git --git-dir="$(gip_repo)"/.git archive --format=zip $(gip_tag) > "$(build_gip_zip)"
	@echo created $(build_gip_zip)
endif
	
$(ul_man1): $(build_gip_zip)
ifndef NOGIP
	@mkdir -p "$(ul_man1)"
	@unar -f -D -q -o "$(ul_man1)" "$(build_gip_zip)" get_iplayer.1
	@echo created $(ul_man1)
endif

$(ulg_bin): $(build_gip_zip)
ifndef NOGIP
	@mkdir -p "$(ulg_bin)"
	@$(ditto) sources.txt "$(ulg_bin)"
	@unar -f -D -q -o "$(ulg_bin)" "$(build_gip_zip)" get_iplayer get_iplayer.cgi
	@sed -E -i.bak -e 's/^(my (\$$version_text|\$$VERSION_TEXT)).*/\1 = "$(pkg_ver)-$$^O";/' \
		"$(ulg_bin)"/{get_iplayer,get_iplayer.cgi}
	@rm -f "$(ulg_bin)"/{get_iplayer,get_iplayer.cgi}.bak
	@mv -f "$(ulg_bin)"/get_iplayer "$(ulg_bin)"/get_iplayer.pl
	@echo created $(ulg_bin)
endif

gip: $(ul_bin) $(ul_man1) $(ulg_bin)

$(build_perl5):
ifndef NOPERL
	@mkdir -p "$(build_perl5)"
	@pushd "$(build_perl5)"; \
		if [ ! -f $(mozilla-ca_tgz) ]; then \
			echo Downloading $(mozilla-ca_tgz); \
			curl -\#fkLO $(mozilla-ca_tgz_url) || exit 3; \
		fi; \
		if [ ! -f $(io-socket-ssl_tgz) ]; then \
			echo Downloading $(io-socket-ssl_tgz); \
			curl -\#fkLO $(io-socket-ssl_tgz_url) || exit 3; \
		fi; \
		if [ ! -f $(io-socket-ip_tgz) ]; then \
			echo Downloading $(io-socket-ip_tgz); \
			curl -\#fkLO $(io-socket-ip_tgz_url) || exit 3; \
		fi; \
		if [ ! -f $(mojolicious_tgz) ]; then \
			echo Downloading $(mojolicious_tgz); \
			curl -\#fkLO $(mojolicious_tgz_url) || exit 3; \
		fi; \
	popd
	@echo created $(build_perl5)
endif

$(ulg_perl5): $(build_perl5)
ifndef NOPERL
	@if [ ! -z "$(PERLBREW_PERL)" ]; then \
		if [ -z "$(PERLBREW_ROOT)" ]; then \
			echo $(pkg_name): "Cannot find perlbrew root: $(PERLBREW_ROOT)"; \
			exit 4; \
		fi; \
		if [ ! -f "$(PERLBREW_ROOT)/etc/bashrc" ]; then \
			echo $(pkg_name): "Cannot find perlbrew init: $(PERLBREW_ROOT)/etc/bashrc"; \
			exit 4; \
		fi; \
		source "$(PERLBREW_ROOT)/etc/bashrc"; \
		perlbrew off; \
	fi; \
	mkdir -p "$(ulg_perl5)"; \
	cpanm -n -l "$(ulg_perl5)" "$(build_perl5)"/$(mozilla-ca_tgz) || exit 5; \
	cpanm -n -l "$(ulg_perl5)" "$(build_perl5)"/$(io-socket-ssl_tgz) || exit 5; \
	cpanm -n -l "$(ulg_perl5)" "$(build_perl5)"/$(io-socket-ip_tgz) || exit 5; \
	cpanm -n -l "$(ulg_perl5)" "$(build_perl5)"/$(mojolicious_tgz) || exit 5
	@rm -f "$(ulg_perl5)"/lib/perl5/darwin-thread-multi-2level/perllocal.pod
	@find "$(ulg_perl5)"/lib/perl5/darwin-thread-multi-2level/auto -type f -name .packlist -exec rm -f {} \;
	@echo created $(ulg_perl5)
endif

perl5: $(ulg_perl5)

$(build_atomicparsley_zip):
ifndef NOUTILS
	@mkdir -p "$(build_atomicparsley)"
	@pushd "$(build_atomicparsley)"; \
		if [ ! -f $(atomicparsley_zip) ]; then \
			echo Downloading $(atomicparsley_zip); \
			curl -\#fkLO "$(atomicparsley_zip_url)" || exit 3; \
		fi; \
	popd
	@echo created $(build_atomicparsley_zip)
endif

$(ulg_bin)/AtomicParsley: $(build_atomicparsley_zip)
ifndef NOUTILS
	@mkdir -p "$(ulg_bin)"
	@unar -f -D -q -o "$(ulg_bin)" "$(build_atomicparsley_zip)" AtomicParsley
	@echo created $(ulg_bin)/AtomicParsley
endif

atomicparsley: $(ulg_bin)/AtomicParsley

$(build_ffmpeg_7z):
ifndef NOUTILS
	@mkdir -p "$(build_ffmpeg)"
	@pushd "$(build_ffmpeg)"; \
		if [ ! -f $(ffmpeg_7z) ]; then \
			echo Downloading $(ffmpeg_7z); \
			curl -\#fkLO "$(ffmpeg_7z_url)" || exit 3; \
		fi; \
	popd
	@echo created $(build_ffmpeg_7z)
endif

$(ulg_bin)/ffmpeg: $(build_ffmpeg_7z)
ifndef NOUTILS
	@mkdir -p "$(ulg_bin)"
	@unar -f -D -q -o "$(ulg_bin)" "$(build_ffmpeg_7z)" ffmpeg
	@echo created $(ulg_bin)/ffmpeg
endif

ffmpeg: $(ulg_bin)/ffmpeg

$(build_licenses):
ifndef NOLICENSES
	@mkdir -p "$(build_licenses)"
	@pushd "$(build_licenses)"; \
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
	popd
	@echo created $(build_licenses)
endif

$(ulg_licenses): $(build_licenses)
ifndef NOLICENSES
	@mkdir -p "$(ulg_licenses)"
	@$(ditto) "$(build_licenses)"/gpl.txt "$(ulg_licenses)"/get_iplayer.txt
	@$(ditto) "$(build_licenses)"/gpl-2.0.txt "$(ulg_licenses)"/atomicparsley.txt
	@$(ditto) "$(build_licenses)"/lgpl-2.1.txt "$(ulg_licenses)"/ffmpeg1.txt
	@$(ditto) "$(build_licenses)"/lgpl.txt "$(ulg_licenses)"/ffmpeg2.txt
	@$(ditto) "$(build_licenses)"/gpl-2.0.txt "$(ulg_licenses)"/ffmpeg3.txt
	@$(ditto) "$(build_licenses)"/gpl.txt "$(ulg_licenses)"/ffmpeg4.txt
	@echo created $(ulg_licenses)
endif

licenses: $(ulg_licenses)

$(apps_gip):
ifndef NOAPPS
	@mkdir -p "$(apps_gip)"
	@$(ditto) {get_iplayer,get_iplayer_cgi,"Run PVR Scheduler","Web PVR Manager","Uninstall get_iplayer"}.command "$(apps_gip)"
	@SetFile -a E "$(apps_gip)"/{get_iplayer,get_iplayer_cgi,"Run PVR Scheduler","Web PVR Manager","Uninstall get_iplayer"}.command
	@seticon get_iplayer.icns "$(apps_gip)"/get_iplayer.command
	@seticon get_iplayer_pvr.icns "$(apps_gip)"/{get_iplayer_cgi,"Run PVR Scheduler","Web PVR Manager"}.command
	@seticon get_iplayer_uninstall.icns "$(apps_gip)"/"Uninstall get_iplayer".command
	@mkdir -p "$(apps_gip)"/Help
	@$(ditto) {get_iplayer,AtomicParsley,FFmpeg,Perl}" Documentation".webloc "$(apps_gip)"/Help
	@SetFile -a E "$(apps_gip)"/Help/{get_iplayer,AtomicParsley,FFmpeg,Perl}" Documentation".webloc
	@mkdir -p "$(apps_gip)"/Update
	@$(ditto) "Check for Update.webloc" "$(apps_gip)"/Update
	@SetFile -a E "$(apps_gip)"/Update/"Check for Update.webloc"
	@platypus --app-icon "get_iplayer.icns" --app-version "$(pkg_ver)" --author "get_iplayer"  \
		--bundle-identifier "com.github.get-iplayer.QuickURLRecord"  --droppable \
		--interface-type "Progress Bar" --interpreter "/bin/bash" --name "Quick URL Record" \
		--service --suffixes "webloc" --text-droppable --text-font "Monaco 10" \
		"Quick URL Record.bash" "$(apps_gip)/Quick URL Record.app"
	@seticon get_iplayer.icns "$(apps_gip)/Quick URL Record.app"
	@SetFile -a E "$(apps_gip)/Quick URL Record.app"
	@echo created $(apps_gip)
endif

apps: $(apps_gip)

deps: gip perl5 atomicparsley ffmpeg licenses apps

$(build_pkg)/$(pkg_file): $(pkg_src)
ifndef NOPKG
	@mkdir -p "$(build_pkg)" 
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(pkg_ver)" "$(pkg_src)"
	@/usr/libexec/PlistBuddy -c "Set :PROJECT:PROJECT_SETTINGS:NAME $(pkg_name)-$(pkg_ver)" "$(pkg_src)"
	@packagesbuild --build-folder "$$(pwd)/$(build_pkg)" "$(pkg_src)"
	@pushd "$(build_pkg)"; \
		md5 -r $(pkg_file) > $(pkg_file).md5 || exit 6; \
		shasum -a 1 $(pkg_file) > $(pkg_file).sha1 || exit 6; \
		shasum -a 256 $(pkg_file) > $(pkg_file).sha256 || exit 6; \
	popd
	@echo built $(build_pkg)/$(pkg_file)
endif

pkg: $(build_pkg)/$(pkg_file)

checkout:
ifndef WIP
	@git update-index --refresh --unmerged
	@git checkout master
endif

commit:
ifndef WIP
	@git commit -m "$(pkg_ver)" "$(pkg_src)"
	@git tag $(pkg_ver)
	@git checkout contribute
	@git merge master
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(curr_version)" "$(pkg_src)"
	@/usr/libexec/PlistBuddy -c "Set :PROJECT:PROJECT_SETTINGS:NAME $(curr_name)" "$(pkg_src)"
	@git commit -m "revert dev version" "$(pkg_src)"
	@git checkout master
	@echo tagged $(pkg_ver)
else
	@/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(curr_version)" "$(pkg_src)"
	@/usr/libexec/PlistBuddy -c "Set :PROJECT:PROJECT_SETTINGS:NAME $(curr_name)" "$(pkg_src)"
endif

clean:
	@rm -f "$(build_pkg)"/$(pkg_file)
	@rm -f "$(build_pkg)"/$(pkg_file).{md5,sha1}
	@echo removed $(build_pkg)/$(pkg_file)
	@rm -fr "$(build_payload)"
	@echo removed $(build_payload)

distclean: clean
	@rm -fr "$(build)"
	@echo removed $(build)

release: clean checkout deps pkg commit
	@echo built release $(pkg_ver)

install:
	@sudo installer -pkg "$(build_pkg)"/$(pkg_file) -target /

uninstall:
	@/usr/local/bin/get_iplayer_uninstall

