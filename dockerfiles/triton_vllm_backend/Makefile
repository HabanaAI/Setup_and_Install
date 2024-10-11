
include ../common.mk

IMAGE_NAME = triton-installer-$(PT_VERSION)-${BUILD_OS}
DOCKER_BUILD_ARGS := $(DOCKER_BUILD_ARGS) --build-arg PT_VERSION=$(PT_VERSION)

init:
ifneq ($(BUILD_OS), ubuntu22.04)
	$(error triton is only supported on ubuntu22.04)
endif
	$(HIDE)mkdir -p $(BUILD_DIR)
	$(HIDE)cp $(CURDIR)/Dockerfile $(BUILD_DIR)/Dockerfile
	$(HIDE)cp $(CURDIR)/model.py $(BUILD_DIR)/model.py

build: init
