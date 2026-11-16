// Host stand-in for heap_caps_malloc: ordinary malloc of the same byte count.
#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MALLOC_CAP_8BIT (1u << 2)
#define MALLOC_CAP_INTERNAL (1u << 11)

static inline void *heap_caps_malloc(size_t size, uint32_t caps) {
  (void)caps;
  return malloc(size);
}
