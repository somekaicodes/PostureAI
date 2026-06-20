// Builds the libposture C++ core into the app target.
//
// The library lives in the Vendor/libposture submodule. Rather than add each
// source file to the Xcode target by hand, we compile them all through this
// one file. Header lookups (e.g. "libposture/geometry.h") resolve via the
// Header Search Paths build setting pointing at Vendor/libposture/include.
#include "../Vendor/libposture/src/geometry.cpp"
#include "../Vendor/libposture/src/filter.cpp"
#include "../Vendor/libposture/src/rep_counter.cpp"
#include "../Vendor/libposture/src/form.cpp"
#include "../Vendor/libposture/src/squat_analyzer.cpp"
#include "../Vendor/libposture/src/posture_c.cpp"
