
include .env
export $(shell sed 's/=.*//' .env)

src := $(shell find etc -type f -path 'etc/*') entrypoint.sh Dockerfile

rev := $(shell git show --no-patch --date=format:%Y%m%d --pretty=format:%cd.%h $$(git rev-parse HEAD))
tag := iolet/gitolite:$(subst v,,$(GITOLITE_TAG))-alpine$(ALPINE_VER)-rev$(rev)

img := $(shell podman image ls $(tag) --format 'table {{.Repository}}:{{.Tag}}' --noheading)
zst := $(subst :,@,$(subst /,_,$(tag))).tar.zst


.PHONY: tar
tar: $(zst)

$(zst): $(src) .env
	podman build \
           --build-arg ALPINE_VER=$(ALPINE_VER) \
           --build-arg APK_MIRROR=$(APK_MIRROR) \
           --build-arg GITOLITE_TAG=$(GITOLITE_TAG) \
           --build-arg S6_OVERLAY_TAG=$(S6_OVERLAY_TAG) \
           --annotation org.opencontainers.image.base.name=$(shell awk -f program.awk Dockerfile):$(ALPINE_VER) \
           --annotation org.opencontainers.image.created=$(shell date --utc '+%FT%H:%M:%SZ') \
           --annotation org.opencontainers.image.revision=$(shell git rev-parse HEAD) \
           --tag $(tag) \
           .
	podman save --format oci-archive $(tag) | zstd - > $(zst)

.PHONY: clean
clean:
	-rm --force *.tar.gz *.tar.zst *.log
	[ -z "$(img)" ] || podman image rm "$(img)"
