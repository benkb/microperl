.PHONY: microperl download manifest gen-manifest clean


PERL_VERSION = 5.10.0
PERL_URL = https://www.cpan.org/src/5.0
COMPILER = gcc-10

PERL_TITLE = perl-$(PERL_VERSION)
PERL_DOWNLOAD_DIR = downloads/$(PERL_TITLE)
PERL_DOWNLOAD_FILE = $(PERL_DOWNLOAD_DIR).tar.gz

MICROPERL_DIR = microperl-$(PERL_VERSION)

MANIFEST_NAME = MANIFEST_perl
MANIFEST_TITLE = $(MANIFEST_NAME)-$(PERL_VERSION)
MANIFEST_BASEFILE = $(MANIFEST_TITLE).txt
MANIFEST_FILE = manifests/$(MANIFEST_BASEFILE)
MANIFEST_INC = manifests/$(MANIFEST_TITLE).inc

$(PERL_DOWNLOAD_FILE):
	sh scripts/downloader.sh "$(PERL_URL)" "$(PERL_TITLE).tar.gz"

$(PERL_DOWNLOAD_DIR): $(PERL_DOWNLOAD_FILE)

$(MANIFEST_BASEFILE):
	sh scripts/gen-manifest.sh "$(PERL_DOWNLOAD_DIR)" "$(MANIFEST_INC)"

$(MANIFEST_FILE):
	@[ -f "$(MANIFEST_BASEFILE)" ] || { echo "Err: run 'make gen-manifest' first"; exit 1; }
	mv "$(MANIFEST_BASEFILE)" "$(MANIFEST_FILE)"

$(MICROPERL_DIR): $(MANIFEST) $(PERL_DOWNLOAD_DIR)
	sh ./scripts/create-microperl.sh -m "$(MANIFEST_FILE)" "$(PERL_DOWNLOAD_DIR)"

microperl: $(MICROPERL_DIR)

download: $(PERL_DOWNLOAD_DIR)

manifest: $(MANIFEST_FILE) 

install-manifest: $(MANIFEST_FILE)

gen-manifest: $(MANIFEST_BASEFILE)


regen-manifest: delete-manifest $(MANIFEST) 

delete-manifest:
	rm -f "$(MANIFEST_NAME)-"*



reinstall-manifest: delete-installed-manifest $(MANIFEST_BASEFILE) install-manifest 

delete-installed-manifest: delete-manifest 
	rm -f $(MANIFEST_FILE)


$(MICROPERL_DIR)/makefile_micro.mk:
	sh ./scripts/makeconf.sh $(MICROPERL_DIR)  $(COMPILER) 

configure: $(MICROPERL_DIR)/makefile_micro.mk

all: 
	echo tbd

clean:
	rm -rf downloads
	rm -rf microperl-*
	rm -f MANIFEST_*
