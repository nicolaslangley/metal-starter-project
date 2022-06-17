#ifndef Profiling_h
#define Profiling_h

#include <os/signpost.h>

static os_log_t kLogHandlePointsOfInterest;
#define SAMPLE_BEGIN(name) if (kLogHandlePointsOfInterest == nil) {\
        kLogHandlePointsOfInterest = os_log_create("com.langley.signpost", OS_LOG_CATEGORY_POINTS_OF_INTEREST);} \
        os_signpost_interval_begin(kLogHandlePointsOfInterest, OS_SIGNPOST_ID_EXCLUSIVE, name);
#define SAMPLE_END(name) os_signpost_interval_end(kLogHandlePointsOfInterest, OS_SIGNPOST_ID_EXCLUSIVE, name);

#endif /* Profiling_h */