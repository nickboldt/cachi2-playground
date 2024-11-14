#!/bin/bash
for INPUT in input3-gomod.env; do # input1-yarn.env input2-pip.env input3-gomod.env
	# shellcheck disable=SC1090
	source $INPUT

	TMP_DIR=$(mktemp -d "/tmp/cachi2.$(echo "${GIT_REPO}_${REF}_${PREFETCH_INPUT}" | tr ":/@" "-").XXXXXXXXXX")

	set -ex

	# clone source code
	cd $TMP_DIR
	git clone "$GIT_REPO" sources

	cd sources
	git checkout "$REF"
	cd ..

	mkdir output

	# prefetch dependencies
	podman run --rm \
		-v $(realpath ./sources):/tmp/sources:z \
		-v $(realpath ./output):/tmp/output:z \
		"$CACHI2_IMAGE" \
		--log-level "DEBUG" \
		fetch-deps "$MODULES_JSON" \
		--source "/tmp/sources" \
		--output "/tmp/output" \
		--dev-package-managers

	# generate environmnent variables
	podman run --rm \
		-v $(realpath ./sources):/tmp/sources:z \
		-v $(realpath ./output):/tmp/output:z \
		"$CACHI2_IMAGE" \
		generate-env /tmp/output \
		--format env \
		--output /tmp/output/cachi2.env

	mv ./output/cachi2.env .

	# inject project files
	podman run --rm \
		-v $(realpath ./sources):/tmp/sources:z \
		-v $(realpath ./output):/tmp/output:z \
		"$CACHI2_IMAGE" \
		inject-files /tmp/output

	# use the cachi2 env variables in all RUN instructions in the Containerfile
	sed -i 's|^\s*run |RUN . /tmp/cachi2.env \&\& \\\n    |i' "./sources/$CONTAINERFILE_PATH/$CONTAINERFILE"

	# in case RPMs for x86_64 were prefetched, mount the repofiles during the container build
	if [ -d "./output/deps/rpm/x86_64/repos.d" ]; then
		echo "rpms found"
		MOUNT_RPM_REPOS="-v $(realpath ./output/deps/rpm/x86_64/repos.d):/etc/yum.repos.d"
	fi

	du -shc "$TMP_DIR/"*

	# build hermetically
	podman build -t "$OUTPUT_IMAGE" \
		-v $(realpath ./output):/tmp/output:Z \
		-v $(realpath ./cachi2.env):/tmp/cachi2.env \
		$MOUNT_RPM_REPOS \
		-f "./sources/$CONTAINERFILE_PATH/$CONTAINERFILE" \
		"sources/$CONTAINERFILE_PATH"
		# --no-cache \
		# --network=none \
done