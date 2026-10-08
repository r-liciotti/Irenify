# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(whisper_flutter_library LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(W ${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp)

# Vendored whisper.cpp v1.9.1, CPU backend only. The arch/ sources are
# internally guarded per architecture, so compiling arm + x86 on every ABI
# is safe; the wrong-arch files compile to nothing.
file(GLOB GGML_SRC
    ${W}/ggml/src/*.c
    ${W}/ggml/src/*.cpp
    ${W}/ggml/src/ggml-cpu/*.c
    ${W}/ggml/src/ggml-cpu/*.cpp
    ${W}/ggml/src/ggml-cpu/arch/arm/*.c
    ${W}/ggml/src/ggml-cpu/arch/arm/*.cpp
    ${W}/ggml/src/ggml-cpu/arch/x86/*.c
    ${W}/ggml/src/ggml-cpu/arch/x86/*.cpp
    ${W}/ggml/src/ggml-cpu/amx/*.cpp
)

# Irenefy (D-65): three shared libraries from the same sources, each with
# its own static ggml/whisper compiled with its own -march, so the app can
# pick at runtime (from /proc/cpuinfo) the fastest one the CPU can run:
#   libwhisper.so          armv8-a baseline (NEON only), runs everywhere
#   libwhisper_dotprod.so  armv8.2-a+fp16+dotprod  (about 2019-2021 SoCs)
#   libwhisper_i8mm.so     armv8.2-a+fp16+dotprod+i8mm (2022+, Pixel 9 Pro)
# ggml picks its kernels at compile time from the compiler macros
# (__ARM_FEATURE_DOTPROD, __ARM_FEATURE_FP16_VECTOR_ARITHMETIC,
# __ARM_FEATURE_MATMUL_INT8) that -march sets; the GGML_USE_* runtime
# scoring in arch/arm/cpu-feats.cpp is only used by GGML_BACKEND_DL builds.
# The extra variants exist only for arm64-v8a (the only ABI we build).
function(irenefy_whisper_variant suffix march)
    set(core whisper_core${suffix})
    add_library(${core} STATIC ${GGML_SRC} ${W}/src/whisper.cpp)
    target_include_directories(${core} PUBLIC
        ${W}/include
        ${W}/ggml/include
        ${W}/ggml/src
        ${W}/ggml/src/ggml-cpu
        ${W}/src
    )
    target_compile_definitions(${core} PUBLIC GGML_USE_CPU)
    # Upstream generates these from git; we vendor a fixed release.
    target_compile_definitions(${core} PRIVATE
        GGML_VERSION="1.9.1"
        GGML_COMMIT="whisper.cpp-v1.9.1"
        WHISPER_VERSION="1.9.1"
    )
    target_compile_options(${core} PRIVATE -O3 -ffunction-sections -fdata-sections ${march})

    set(lib whisper_flutter${suffix})
    add_library(${lib} SHARED main.cpp)
    set_target_properties(${lib} PROPERTIES OUTPUT_NAME "whisper${suffix}")
    target_compile_definitions(${lib} PUBLIC DART_SHARED_LIB)
    target_compile_options(${lib} PRIVATE -O3 -ffunction-sections -fdata-sections ${march})
    target_link_options(${lib} PRIVATE -Wl,--gc-sections)
    target_link_libraries(${lib} PRIVATE ${core} ${CMAKE_THREAD_LIBS_INIT})
endfunction()

# No -march override for the baseline: armv8.2-a+fp16 flags SIGILLed on
# armv8.0 devices (upstream issue #15). Baseline armv8-a runs everywhere.
irenefy_whisper_variant("" "")
if(ANDROID_ABI STREQUAL "arm64-v8a")
    irenefy_whisper_variant("_dotprod" "-march=armv8.2-a+fp16+dotprod")
    irenefy_whisper_variant("_i8mm" "-march=armv8.2-a+fp16+dotprod+i8mm")
endif()
