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
OUTPUT_LIB_NAME="libpdf_engine"

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
    
    # 💡 CMAKE_BUILD_TYPE ကို MinSizeRel (Minimum Size Release) သို့ ပြောင်းလဲထားသည်
    cmake .. \
      -DCMAKE_SYSTEM_NAME=Android \
      -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI="$ABI" \
      -DANDROID_PLATFORM="android-$API_LEVEL" \
      -DCMAKE_BUILD_TYPE=MinSizeRel > /dev/null 2>&1
    
    cmake --build .
    cd ..
    
    TARGET_SO="$BUILD_DIR/${OUTPUT_LIB_NAME}.so"
    ANDROID_OUT_DIR="${OUTPUT_DIR}/android/${ABI}"

    if [ -f "$TARGET_SO" ]; then
        mkdir -p "${ANDROID_OUT_DIR}"
        cp "$TARGET_SO" "${ANDROID_OUT_DIR}/${OUTPUT_LIB_NAME}.so"
        
        # 💡 Android NDK toolchain ထဲက strip tool ကို သုံးပြီး size ထပ်လျှော့ခြင်း
        # (CMake configuration အပေါ်မူတည်ပြီး အလိုအလျောက် strip မဖြစ်သွားပါက ဤအဆင့်က အသုံးဝင်သည်)
        "$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" --strip-unneeded "${ANDROID_OUT_DIR}/${OUTPUT_LIB_NAME}.so" 2>/dev/null || \
        strip --strip-unneeded "${ANDROID_OUT_DIR}/${OUTPUT_LIB_NAME}.so" 2>/dev/null

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

# 💡 Linux အတွက်လည်း MinSizeRel သို့ ပြောင်းလဲထားသည်
cmake .. -DCMAKE_BUILD_TYPE=MinSizeRel > /dev/null 2>&1
cmake --build .
cd ..

TARGET_SO="$BUILD_DIR/${OUTPUT_LIB_NAME}.so"
LINUX_OUT_DIR="$OUTPUT_DIR/linux"

if [ -f "$TARGET_SO" ]; then
    mkdir -p "${LINUX_OUT_DIR}"
    cp "$TARGET_SO" "$LINUX_OUT_DIR/${OUTPUT_LIB_NAME}.so"
    
    # 💡 Linux native strip ကိုသုံးပြီး မလိုအပ်တဲ့ Symbol များကို ဖယ်ရှားခြင်း
    strip --strip-all "$LINUX_OUT_DIR/${OUTPUT_LIB_NAME}.so"

    echo "✅ Linux (x64) done!"
else
    echo "❌ Linux (x64) build failed!"
fi
rm -rf "$BUILD_DIR"

echo "----------------------------------------"
echo "🎉 All Platform Binaries Generated successfully!"
echo "📍 Output Details:"
ls -lh "$OUTPUT_DIR"/android/*/*.so "$OUTPUT_DIR"/linux/*.so 2>/dev/null
echo "----------------------------------------"