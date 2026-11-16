// Host stand-in for the FreeRTOS types Sensor.h declares.
#pragma once

#include <stdint.h>

typedef void *QueueHandle_t;

typedef struct StaticQueue {
  uint8_t unused;
} StaticQueue_t;
