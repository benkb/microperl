.PHONY: rerun run all reset clean wipe download manifest regen-manifest delete-manifest install-manifest reinstall-manifest delete-installed-manifest


PERL_VERSION = 5.10.0
PERL_URL = https://www.cpan.org/src/5.0

MANIFEST_NAME = MANIFEST_perl
MANIFEST = $(MANIFEST_NAME)-$(PERL_VERSION)

rerun: reset run

microperl:
	sh ./scripts/create-microperl.sh downloads/perl-$(PERL_VERSION)

download:
	sh scripts/downloader.sh "$(PERL_URL)" "perl-$(PERL_VERSION).tar.gz"

manifest: $(MANIFEST) 

regen-manifest: delete-manifest $(MANIFEST) 

delete-manifest:
	rm -f "$(MANIFEST_NAME)-"*

$(MANIFEST): 
	sh scripts/gen-manifest.sh "downloads/perl-$(PERL_VERSION)" "includes/$(MANIFEST).inc"

manifests/$(MANIFEST): 
	@[ -f "$(MANIFEST)" ] || { echo "Err: run 'make gen-manifest' first"; exit 1; }
	mv "$(MANIFEST)" "manifests/$(MANIFEST)"

install-manifest: manifests/$(MANIFEST)

reinstall-manifest: delete-installed-manifest $(MANIFEST) install-manifest 

delete-installed-manifest: delete-manifest 
	rm -f "manifests/$(MANIFEST)"


all: 
	echo tbd



clean:
	rm -rf downloads
	rm -rf microperl-*
	rm -f MANIFEST_*
