#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <iostream>

static CFMachPortRef g_tap = nullptr;

static CGEventRef scrollCallback(CGEventTapProxy, CGEventType type, CGEventRef e, void*)
{
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        if (g_tap) CGEventTapEnable(g_tap, true);
        return e;
    }
    if (type != kCGEventScrollWheel) return e;

    const int64_t isContinuous =
        CGEventGetIntegerValueField(e, kCGScrollWheelEventIsContinuous);
    const int64_t phase =
        CGEventGetIntegerValueField(e, kCGScrollWheelEventScrollPhase);
    const int64_t mphase =
        CGEventGetIntegerValueField(e, kCGScrollWheelEventMomentumPhase);

    // Heuristic: treat as "mouse wheel" if either:
    //  - it's non-continuous (legacy line-based), OR
    //  - there are no scroll phases (typical for mouse wheels in many apps, including VS Code)
    const bool looksLikeMouse =
        (isContinuous == 0) || (phase == 0 && mphase == 0);

    if (looksLikeMouse) {
        // Flip all relevant fields so apps that read different deltas stay consistent
        double fp = CGEventGetDoubleValueField(e, kCGScrollWheelEventFixedPtDeltaAxis1);
        double pt = CGEventGetDoubleValueField(e, kCGScrollWheelEventPointDeltaAxis1);
        double ln = CGEventGetDoubleValueField(e, kCGScrollWheelEventDeltaAxis1);

        CGEventSetDoubleValueField(e, kCGScrollWheelEventFixedPtDeltaAxis1, -fp);
        CGEventSetDoubleValueField(e, kCGScrollWheelEventPointDeltaAxis1,  -pt);
        CGEventSetDoubleValueField(e, kCGScrollWheelEventDeltaAxis1,       -ln);
    }

    return e;
}

int main()
{
    // Real, modifiable scroll tap (requires Accessibility when not ListenOnly)
    CGEventMask m = CGEventMaskBit(kCGEventScrollWheel);
    g_tap = CGEventTapCreate(
        kCGHIDEventTap,
        kCGHeadInsertEventTap,
        kCGEventTapOptionDefault,   // modifiable
        m,
        scrollCallback,
        nullptr);

    if (!g_tap) {
        // Accessibility not granted (or wrong context); tell launchd via exit 10
        std::cerr << "[scrollfix] Failed to create tap; Accessibility likely not granted.\n";
        return 10;
    }

    CFRunLoopSourceRef src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, g_tap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), src, kCFRunLoopCommonModes);
    CGEventTapEnable(g_tap, true);
    std::cerr << "[scrollfix] tap enabled; running.\n";
    CFRunLoopRun();

    CFRelease(src);
    CFRelease(g_tap);
    g_tap = nullptr;
    return 0;
}
