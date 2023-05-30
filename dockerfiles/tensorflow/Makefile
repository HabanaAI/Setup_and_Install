
include ../common.mk

IMAGE_NAME = tensorflow-installer-${BUILD_OS}-tf-cpu-$(TF_VERSION)
DOCKER_BUILD_ARGS := $(DOCKER_BUILD_ARGS) --build-arg TF_VERSION=$(TF_VERSION)


base:
ifneq ($(shell docker image inspect $(BASE_IMAGE_URL):$(RELEASE_VERSION)-$(RELEASE_BUILD_ID) --format="image_exists" 2>/dev/null), image_exists)
	cd ../base; \
	make build; \
	cd ../tensorflow
endif


init: base
	$(HIDE)mkdir -p $(BUILD_DIR)
ifneq (,$(findstring ubuntu,$(BUILD_OS)))
	$(HIDE)cp $(CURDIR)/Dockerfile.ubuntu $(BUILD_DIR)/Dockerfile
else
	$(HIDE)cp $(CURDIR)/Dockerfile.$(BUILD_OS) $(BUILD_DIR)/Dockerfile
endif
	$(HIDE)cp $(CURDIR)/requirements-tensorflow-cpu-$(shell echo -n $(TF_VERSION) | awk -F'-' '{print $$1}').txt $(BUILD_DIR)/requirements.txt

build: init
