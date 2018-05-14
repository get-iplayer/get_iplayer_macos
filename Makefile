# Build macOS installer for get_iplayer
# Requires: cpanminus, p7zip, Packages, Xcode CLT
# Build release:
# VERSION=3.14 BUILD=0 make release
# Rebuild all dependencies and build release:
# VERSION=3.14 BUILD=0 make distclean release

ifdef VERSION
	gip_tag=v$(VERSION)
else
	gip_tag=master
	VERSION=0.00
	NOCHECKOUT=1
endif
ifndef BUILD
	BUILD=0
endif

gip_repo=../get_iplayer
build=build
payload=payload
work=work
pkg_name=get_iplayer
pkg_version=$(VERSION).$(BUILD)
pkg_src=$(pkg_name).pkgproj
pkg_file=$(pkg_name)-$(pkg_version).pkg
atomicparsley_zip=AtomicParsley-0.9.6-macos-bin.zip
ffmpeg_7z=ffmpeg-4.0.7z
work_get_iplayer=$(work)/$(pkg_name)-$(pkg_version)
work_licenses=$(work)/licenses
work_perl5=$(work)/perl5
work_atomicparsley=$(work)/atomicparsley
work_ffmpeg=$(work)/ffmpeg
ul = $(payload)/usr/local
ul_bin = $(ul)/bin
ul_man1 = $(ul)/share/man/man1
ulg = $(ul)/get_iplayer
ulg_bin = $(ulg)/bin
ulg_licenses = $(ulg)/licenses
ulg_perl5 = $(ulg)/perl5
src_ul_bin=src/usr/local/bin
src_ulg_bin=src/usr/local/get_iplayer/bin
perlbrew_init=~/perl5/perlbrew/etc/bashrc
ditto=ditto --norsrc --noextattr --noacl

dummy:
	@echo Nothing to make

$(ul_bin):
ifndef NOSCRIPTS
	@mkdir -p $(ul_bin)
	@$(ditto) $(src_ul_bin)/{get_iplayer,get_iplayer_web_pvr,get_iplayer_uninstall} $(ul_bin)
	@echo $(pkg_name): built $(ul_bin)
endif

checkout_get_iplayer:
ifndef NOSCRIPTS
	@git --git-dir=$(gip_repo)/.git --work-tree=$(gip_repo) update-index --refresh --unmerged
	@git --git-dir=$(gip_repo)/.git --work-tree=$(gip_repo) checkout $(gip_tag)
endif

$(work_get_iplayer): checkout_get_iplayer
ifndef NOSCRIPTS
	@mkdir -p $(work_get_iplayer)
	@git --git-dir=$(gip_repo)/.git checkout-index --force --prefix=$(work_get_iplayer)/ get_iplayer get_iplayer.cgi get_iplayer.1
	@pushd $(work_get_iplayer); \
	sed -E -i.bak -e 's/^(my (\$$version_text|\$$VERSION_TEXT)).*/\1 = "$(pkg_version)-$$^O";/' get_iplayer get_iplayer.cgi; \
	rm -f {get_iplayer,get_iplayer.cgi}.bak; \
	popd
	@echo $(pkg_name): created $(work_get_iplayer)
endif
	
$(ul_man1): $(work_get_iplayer)
ifndef NOSCRIPTS
	@mkdir -p $(ul_man1)
	@$(ditto) $(work_get_iplayer)/get_iplayer.1 $(ul_man1)
	@echo $(pkg_name): built $(ul_man1)
endif

$(ulg_bin): $(work_get_iplayer)
ifndef NOSCRIPTS
	@mkdir -p $(ulg_bin)
	@$(ditto) $(work_get_iplayer)/{get_iplayer,get_iplayer.cgi} $(ulg_bin)
	@$(ditto) $(src_ulg_bin)/get_iplayer_web_pvr $(ulg_bin)
	@echo $(pkg_name): built $(ulg_bin)
endif

$(work_licenses):
ifndef NOLICENSES
	@mkdir -p $(work_licenses)
	@pushd $(work_licenses); \
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
	@echo $(pkg_name): created $(work_licenses)
endif

$(ulg_licenses): $(work_licenses)
ifndef NOLICENSES
	@mkdir -p $(ulg_licenses);
	@$(ditto) $(work_licenses)/{gpl,lgpl,gpl-2.0,lgpl-2.1}.txt $(ulg_licenses)
	@echo $(pkg_name): built $(ulg_licenses)
endif

$(work_perl5):
ifndef NOPERL
	@mkdir -p $(work_perl5);
	@pushd $(work_perl5); \
	if [ ! -f Mozilla-CA-20180117.tar.gz ]; then \
		echo Downloading Mozilla-CA-20180117.tar.gz; \
		curl -\#fkLO https://cpan.metacpan.org/authors/id/A/AB/ABH/Mozilla-CA-20180117.tar.gz || exit 3; \
	fi; \
	if [ ! -f IO-Socket-SSL-2.056.tar.gz ]; then \
		echo Downloading IO-Socket-SSL-2.056.tar.gz; \
		curl -\#fkLO https://cpan.metacpan.org/authors/id/S/SU/SULLR/IO-Socket-SSL-2.056.tar.gz || exit 3; \
	fi; \
	if [ ! -f IO-Socket-IP-0.39.tar.gz ]; then \
		echo Downloading IO-Socket-IP-0.39.tar.gz; \
		curl -\#fkLO https://cpan.metacpan.org/authors/id/P/PE/PEVANS/IO-Socket-IP-0.39.tar.gz || exit 3; \
	fi; \
	if [ ! -f Mojolicious-7.77.tar.gz ]; then \
		echo Downloading Mojolicious-7.77.tar.gz; \
		curl -\#fkLO https://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-7.77.tar.gz || exit 3; \
	fi; \
	popd
	@echo $(pkg_name): created $(work_perl5)
endif

$(ulg_perl5): $(work_perl5)
ifndef NOPERL
	@if [ ! -z $(PERLBREW_PERL) ]; then \
		if [ ! -f $(perlbrew_init) ]; then \
			echo "Cannot find perlbrew init script: $(perlbrew_init)"; \
			exit 4; \
		fi; \
		source $(perlbrew_init); \
		perlbrew off; \
	fi; \
	mkdir -p $(ulg_perl5); \
	cpanm -n -l $(ulg_perl5) $(work_perl5)/Mozilla-CA-20180117.tar.gz; \
	cpanm -n -l $(ulg_perl5) $(work_perl5)/IO-Socket-SSL-2.056.tar.gz; \
	cpanm -n -l $(ulg_perl5) $(work_perl5)/IO-Socket-IP-0.39.tar.gz; \
	cpanm -n -l $(ulg_perl5) $(work_perl5)/Mojolicious-7.77.tar.gz
	@echo $(pkg_name): built $(ulg_perl5)
endif

$(work_atomicparsley)/$(atomicparsley_zip):
ifndef NOUTILS
	@mkdir -p $(work_atomicparsley)
	@pushd $(work_atomicparsley); \
	if [ ! -f $(atomicparsley_zip) ]; then \
		echo Downloading $(atomicparsley_zip); \
		curl -\#fkLO https://bitbucket.org/dinkypumpkin/atomicparsley/downloads/$(atomicparsley_zip) || exit 3; \
	fi; \
	popd
	@echo $(pkg_name): created $(work_atomicparsley)/$(atomicparsley_zip)
endif

$(ulg_bin)/AtomicParsley: $(work_atomicparsley)/$(atomicparsley_zip)
ifndef NOUTILS
	@mkdir -p $(ulg_bin)
	@7za e -aoa -o$(ulg_bin) $(work_atomicparsley)/$(atomicparsley_zip) AtomicParsley
	@echo $(pkg_name): built $(ulg_bin)/AtomicParsley
endif

$(work_ffmpeg)/$(ffmpeg_7z):
ifndef NOUTILS
	@mkdir -p $(work_ffmpeg)
	@pushd $(work_ffmpeg); \
	if [ ! -f $(ffmpeg_7z) ]; then \
		echo Downloading $(ffmpeg_7z); \
		curl -\#fkLO https://evermeet.cx/pub/ffmpeg/$(ffmpeg_7z) || exit 3; \
	fi; \
	popd
	@echo $(pkg_name): created $(work_ffmpeg)/$(ffmpeg_7z)
endif

$(ulg_bin)/ffmpeg: $(work_ffmpeg)/$(ffmpeg_7z)
ifndef NOUTILS
	@mkdir -p $(ulg_bin)
	@7za e -aoa -o$(ulg_bin) $(work_ffmpeg)/$(ffmpeg_7z) ffmpeg
	@echo $(pkg_name): built $(ulg_bin)/ffmpeg
endif

$(build)/$(pkg_file): $(pkg_src) checkout
	@mkdir -p $(build)
	@mkdir -p $(payload)/usr
	@/usr/libexec/PlistBuddy -x -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $(pkg_version)" $(pkg_src)
	@/usr/libexec/PlistBuddy -x -c "Set :PROJECT:PROJECT_SETTINGS:NAME $(pkg_name)-$(pkg_version)" $(pkg_src)
	@packagesbuild $(pkg_src)
	@pushd $(build); \
	md5 -r $(pkg_file) > $(pkg_file).md5; \
	shasum -a 1 $(pkg_file) > $(pkg_file).sha1; \
	popd
	@echo $(pkg_name): built $(build)/$(pkg_file)

prepare: $(work_get_iplayer) $(work_licenses) $(work_perl5) $(work_atomicparsley)/$(atomicparsley_zip) $(work_ffmpeg)/$(ffmpeg_7z)

scripts: $(ul_bin) $(ul_man1) $(ulg_bin) $(ulg_licenses)

perl5: $(ulg_perl5)

utils: $(ulg_bin)/AtomicParsley $(ulg_bin)/ffmpeg

installer: $(build)/$(pkg_file)

checkout:
ifndef NOCHECKOUT
	@git update-index --refresh --unmerged
	@git checkout master
endif

commit:
ifndef NOCHECKOUT
	@git commit -m "$(pkg_version)" $(pkg_src)
	@git tag $(VERSION).$(BUILD)
	@git revert --no-edit HEAD
	@echo $(pkg_name): tagged $(VERSION).$(BUILD)
endif

clean:
	@rm -fr $(build)/$(pkg_file)*
	@echo $(pkg_name): removed $(build)/$(pkg_file)
	@rm -fr $(payload)
	@echo $(pkg_name): removed $(payload)

distclean: clean
	@rm -fr $(build)
	@echo $(pkg_name): removed $(build)
	@rm -fr $(work)
	@echo $(pkg_name): removed $(work)

release: checkout clean prepare scripts perl5 utils installer commit
	@echo $(pkg_name): built release

install:
	@sudo installer -pkg $(build)/$(pkg_file) -target /
	@echo $(pkg_name): installed

uninstall:
	@src/usr/local/bin/get_iplayer_uninstall

