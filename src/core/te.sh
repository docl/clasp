    "clang++" -P -E -x c++ -O1 -Warray-bounds -Wframe-larger-than=16 -Wlarger-than=4 -Wno-deprecated-register -std=c++11 -stdlib=libc++ -O0 -g -O0 -fno-inline -Wall -g -DDEBUG_ASSERTS -DDEBUG_MPS -DEXPAT -DINCLUDED_FROM_BRCL -DINHERITED_FROM_SRC -DREADLINE -D_ADDRESS_MODEL_64 -D_DEBUG_BUILD -D_TARGET_OS_DARWIN -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -I"../../build/cando.app/Contents/Resources/externals/gmp-5.0.5" -I"../../src" -I"../../src/core" -I"../../src/core/bin/clang-darwin-4.2.1/debug/link-static" -I"/Library/Frameworks/EPD64.framework/Versions/7.2/include/python2.7" -I"/Users/meister/Development/cando/brcl/build/cando.app/Contents/Resources/externals/common/include" -I"/Users/meister/Development/cando/brcl/build/cando.app/Contents/Resources/externals/release/include" -c -o "../../src/core/evaluator.i" "../../src/core/evaluator.cc"
