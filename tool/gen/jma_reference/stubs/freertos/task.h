// Host stand-in. The intensity FFT calls taskYIELD() between axes.
#pragma once

#define taskYIELD() ((void)0)
