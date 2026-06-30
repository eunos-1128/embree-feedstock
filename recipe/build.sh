#!/bin/bash
set -exo pipefail

# Specify location of TBB
export TBBROOT=${PREFIX}

extra_cmake_args=()

if [[ "${target_platform}" == *"linux-64" ]] ; then
    max_isa="AVX512"
elif [[ "${target_platform}" == "osx-64" ]]; then
    max_isa="AVX2"
elif [[ "${target_platform}" == "linux-aarch64" || "${target_platform}" == "osx-arm64" ]]; then
    max_isa="NEON2X"
elif [[ "${target_platform}" == "linux-ppc64le" ]]; then
    max_isa="NONE"
    extra_cmake_args+=(
        -DEMBREE_ISA_SSE2=OFF
        -DEMBREE_ISA_SSE42=OFF
        -DEMBREE_ISA_AVX=OFF
        -DEMBREE_ISA_AVX2=OFF
        -DEMBREE_ISA_AVX512=OFF
    )
else
    echo "Unsupported target_platform: ${target_platform}" >&2
    exit 1
fi

# Configure
cmake -S . -B build -G Ninja \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=ON \
    -DEMBREE_IGNORE_CMAKE_CXX_FLAGS=OFF \
    -DEMBREE_TUTORIALS=OFF \
    -DEMBREE_MAX_ISA="${max_isa}" \
    -DEMBREE_ISPC_SUPPORT=ON \
    "${extra_cmake_args[@]}"

# Compile
cmake --build build --parallel ${CPU_COUNT}

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
    ctest -V --test-dir build --parallel ${CPU_COUNT}
fi

cmake --install build --parallel ${CPU_COUNT}

# remove unnecessary embree-vars files
rm -rf ${PREFIX}/embree-vars.*
