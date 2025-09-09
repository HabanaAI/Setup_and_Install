
include ../common.mk

IMAGE_NAME = base-installer-${BUILD_OS}
ifdef CUSTOM_PYTHON_VERSION
	IMAGE_NAME = base-installer-${BUILD_OS}-${PYTHON_SUFFIX}
endif

ifdef REPO_NAME
	DOCKER_BUILD_ARGS := $(DOCKER_BUILD_ARGS) --build-arg REPO_NAME=$(REPO_NAME)
endif

check_base:
ifeq ($(BUILD_OS),navix9.4)
    ifneq ($(shell $(DOCKER) image inspect navix-container-base-9.4-20241121.0.x86_64 --format="image_exists" 2>/dev/null), image_exists)
		wget https://dlnavix.navercorp.com/cloud-images/Navix-Container-Base-9.4-20241121.0.x86_64.tar.xz
		docker load -i Navix-Container-Base-9.4-20241121.0.x86_64.tar.xz
		rm -f Navix-Container-Base-9.4-20241121.0.x86_64.tar.xz
    endif
endif

init: check_base
	$(HIDE)mkdir -p $(BUILD_DIR)
	$(HIDE)cp $(CURDIR)/LICENSE $(BUILD_DIR)/
	$(HIDE)cp $(CURDIR)/*.sh $(BUILD_DIR)/
	$(HIDE)cp $(CURDIR)/tencentos_efa_patch.txt $(BUILD_DIR)/
    ifdef CUSTOM_PYTHON_VERSION
		$(HIDE)cp $(CURDIR)/Dockerfile.$(BUILD_OS)-${PYTHON_SUFFIX} $(BUILD_DIR)/Dockerfile
    else
		$(HIDE)cp $(CURDIR)/Dockerfile.$(BUILD_OS) $(BUILD_DIR)/Dockerfile
    endif

build: init
