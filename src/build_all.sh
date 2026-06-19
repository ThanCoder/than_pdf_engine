#!/bin/bash

# 1. Android Paths သတ်မှတ်ခြင်း
export ANDROID_HOME=$HOME/Android/Sdk
export NDK_PATH=$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk | head -n 1)
API_LEVEL="21"

echo "----------------------------------------"
echo "🚀 Starting Full Multi-Platform Build..."
echo "----------------------------------------"

# Output folder ရှင်းလင်းဆောက်လုပ်ခြင်း
OUTPUT_DIR="dist_binaries"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# ========================================
# 🤖 PART 1: ANDROID BUILDS (ABI ၂ ခု)
# ========================================
ANDROID_ABIS=("arm64-v8a" "armeabi-v7a")

for ABI in "${ANDROID_ABIS[@]}"
do
    echo "📦 Building Android -> $ABI ..."
    BUILD_DIR="build_temp_android_${ABI}"
    rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
    
    cmake .. \
      -DCMAKE_SYSTEM_NAME=Android \
      -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI="$ABI" \
      -DANDROID_PLATFORM="android-$API_LEVEL" \
      -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1 # output ရှင်းအောင် log ခဏပိတ်ထားခြင်း
    
    cmake --build .
    cd ..
    
    TARGET_SO="$BUILD_DIR/libpdf_engine_wrapper.so"
    if [ -f "$TARGET_SO" ]; then
        cp "$TARGET_SO" "$OUTPUT_DIR/libpdf_engine_wrapper_${ABI}.so"
        echo "✅ Android ($ABI) done!"
    else
        echo "❌ Android ($ABI) build failed!"
    fi
    rm -rf "$BUILD_DIR"
done

# ========================================
# 🐧 PART 2: LINUX DESKTOP BUILD (x64 တစ်ခုတည်း)
# ========================================
echo "========================================"
echo "📦 Building Linux Desktop -> x64 ..."
echo "========================================"

BUILD_DIR="build_temp_linux"
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

# Linux Desktop အဖြစ် Build ရန် (Android toolchain မသုံးပါ)
cmake .. -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1
cmake --build .
cd ..

TARGET_SO="$BUILD_DIR/libpdf_engine_wrapper.so"
if [ -f "$TARGET_SO" ]; then
    cp "$TARGET_SO" "$OUTPUT_DIR/libpdf_engine_wrapper_x64.so"
    echo "✅ Linux (x64) done!"
else
    echo "❌ Linux (x64) build failed!"
fi
rm -rf "$BUILD_DIR"

echo "----------------------------------------"
echo "🎉 All Platform Binaries Generated successfully!"
ls -l "$OUTPUT_DIR"
echo "----------------------------------------"