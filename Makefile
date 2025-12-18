
ALPINE_VER := $(shell grep -v '#' argfile.conf | grep ALPINE_VER | tail -n 1 | awk -F '=' '{print $$2}')
GITOLITE_TAG := $(shell grep -v '#' argfile.conf | grep GITOLITE_TAG | tail -n 1 | awk -F '=' '{print $$2}')

rev := $(shell git show --no-patch --date=format:%y%m%d --pretty=format:%cd.%h HEAD)
tag := $(subst v,,$(GITOLITE_TAG))-alpine$(ALPINE_VER)-rev$(rev)
img := iolet/gitolite:$(tag)

src := $(shell find etc -type f -path 'etc/*') argfile.conf entrypoint.sh gl-export.sh gl-import.sh Containerfile
dst := $(subst :,@,$(subst /,--,$(img))).tar.zst


.PHONY: tarball
tarball: $(dst)

$(dst): $(src)
	podman build \
            --build-arg-file argfile.conf \
            --annotation org.opencontainers.image.base.name=$(shell awk -f image.awk Containerfile):$(ALPINE_VER) \
            --annotation org.opencontainers.image.created=$(shell date --utc '+%FT%H:%M:%SZ') \
            --annotation org.opencontainers.image.revision=$(shell git rev-parse HEAD) \
            --tag $(img) \
            .
	podman save $(img) | zstd - > $(dst)

.PHONY: clean
clean:
	-rm --force *.tar.gz *.tar.zst *.log
	podman image exists $(img) && podman image rm $(img)
