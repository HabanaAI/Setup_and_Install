
include ../common.mk

IMAGE_NAME = pytorch-installer-$(BUILD_OS)-$(PT_VERSION)
ifdef CUSTOM_PYTHON_VERSION
	IMAGE_NAME = pytorch-installer-$(BUILD_OS)-$(PT_VERSION)-$(PYTHON_SUFFIX)
endif

ifdef TORCH_TYPE
    ifeq ($(TORCH_TYPE),upstream)
		IMAGE_NAME = pytorch-upstream-installer-$(BUILD_OS)-$(PT_VERSION)
    endif
endif

DOCKER_BUILD_ARGS := $(DOCKER_BUILD_ARGS) --build-arg PT_VERSION=$(PT_VERSION)

base:
ifneq ($(shell $(DOCKER) image inspect $(BASE_IMAGE_URL):$(RELEASE_VERSION)-$(RELEASE_BUILD_ID) --format="image_exists" 2>/dev/null), image_exists)
	cd ../base; \
	make build; \
	cd ../pytorch
endif

init: base
	$(HIDE)mkdir -p $(BUILD_DIR)
	$(HIDE)cp $(CURDIR)/install_packages.sh $(BUILD_DIR)/
ifneq (,$(findstring ubuntu,$(BUILD_OS)))
    ifdef CUSTOM_PYTHON_VERSION
		$(HIDE)cp $(CURDIR)/Dockerfile.$(BUILD_OS)-$(PYTHON_SUFFIX) $(BUILD_DIR)/Dockerfile
    else
		$(HIDE)cp $(CURDIR)/Dockerfile.ubuntu $(BUILD_DIR)/Dockerfile
    endif
else
    ifdef CUSTOM_PYTHON_VERSION
		$(HIDE)cp $(CURDIR)/Dockerfile.$(BUILD_OS)-${PYTHON_SUFFIX} $(BUILD_DIR)/Dockerfile
    else
		$(HIDE)cp $(CURDIR)/Dockerfile.$(BUILD_OS) $(BUILD_DIR)/Dockerfile
    endif
endif

build: init
