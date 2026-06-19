#!/bin/bash

# 1. Android SDK နှင့် NDK လမ်းကြောင်း သတ်မှတ်ခြင်း
export ANDROID_HOME=$HOME/Android/Sdk
export NDK_PATH=$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk | head -n 1)
API_LEVEL="21" # Base API level

echo "----------------------------------------"
echo "🚀 Starting Multi-ABI Android Build..."
echo "Using NDK from: $NDK_PATH"
echo "----------------------------------------"

# ထုတ်လုပ်မည့် ABI ၂ ခု စာရင်း
ABIS=("arm64-v8a" "armeabi-v7a")

# output ဖိုဒါအသစ် ဆောက်မယ်
OUTPUT_DIR="dist_android"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# ABI တစ်ခုချင်းစီကို ပတ်ပြီး Build မယ်
for ABI in "${ABIS[@]}"
do
    echo "========================================"
    echo "📦 Building for ABI: $ABI"
    echo "========================================"
    
    # ယာယီ Build ဖိုဒါ ဆောက်ခြင်း
    BUILD_DIR="build_temp_${ABI}"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
    
    # CMake Configuration
    cmake .. \
      -DCMAKE_SYSTEM_NAME=Android \
      -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI="$ABI" \
      -DANDROID_PLATFORM="android-$API_LEVEL" \
      -DCMAKE_BUILD_TYPE=Release
    
    # Compile လုပ်ခြင်း
    cmake --build .
    
    # မူလ root ဖိုဒါကို ပြန်သွားခြင်း
    cd ..
    
    # ပြုလုပ်ပြီးသား .so ဖိုင် ရှိမရှိ စစ်ဆေးပြီး နာမည်ပြောင်းသိမ်းဆည်းခြင်း
    # (CMake ထဲက output target name က pdf_engine_wrapper ဖြစ်လို့ libpdf_engine_wrapper.so အဖြစ် ထွက်လာပါတယ်)
    TARGET_SO="$BUILD_DIR/libpdf_engine_wrapper.so"
    
    if [ -f "$TARGET_SO" ]; then
        NEW_NAME="libpdf_engine_wrapper_${ABI}.so"
        cp "$TARGET_SO" "$OUTPUT_DIR/$NEW_NAME"
        echo "✅ Successfully created: $OUTPUT_DIR/$NEW_NAME"
    else
        echo "❌ Error: Build failed for $ABI"
    fi
    
    # ယာယီဆောက်ခဲ့တဲ့ build folder ကို ရှင်းလင်းခြင်း
    rm -rf "$BUILD_DIR"
done

echo "----------------------------------------"
echo "🎉 All Done! Check your optimized binaries in '$OUTPUT_DIR/' folder:"
ls -l "$OUTPUT_DIR"
echo "----------------------------------------"