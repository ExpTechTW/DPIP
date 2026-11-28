/* Deterministic test double for the report-picture ABI. Never packaged. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifndef ABI
#define ABI 0x00010002
#endif
#ifndef CAPS
#define CAPS 0x110
#endif

static unsigned int frees;
static unsigned int invalid_frees;
static unsigned int live_renderers;
static uint8_t *outstanding_bytes;
static size_t outstanding_len;

void *eqr_renderer_new(const uint8_t *const *fonts, const size_t *lengths,
                       size_t count) {
  if (count == 0 || lengths[0] == 0 || fonts[0][0] == 0) return NULL;
  void *renderer = malloc(1);
  if (renderer) live_renderers++;
  return renderer;
}

void eqr_renderer_free(void *renderer) {
  free(renderer);
  live_renderers--;
}

int32_t eqr_render_png(const void *renderer, const uint8_t *json, size_t len,
                       float scale, uint32_t mode, uint32_t theme,
                       uint8_t **out_ptr, size_t *out_len) {
  return -1;
}

void eqr_bytes_free(uint8_t *bytes, size_t len) {
  if (!bytes || bytes != outstanding_bytes || len != outstanding_len) {
    /* A second free of the same buffer (or one with the wrong length) is a
       Dart-side ownership bug. Count it instead of masking it. */
    invalid_frees++;
    return;
  }
  outstanding_bytes = NULL;
  outstanding_len = 0;
  /* The fixture always allocates three bytes, even when simulating bad length. */
  memset(bytes, 0, 3);
  free(bytes);
  frees++;
}

const char *eqr_last_error(void) { return "fixture render error"; }
const char *eqr_version(void) { return "test fixture"; }

#ifndef OMIT_ABI
uint32_t eqr_abi_info(uint64_t *caps) {
  *caps = CAPS;
  return ABI;
}
#endif

#ifndef OMIT_RENDER
int32_t eqr_render_share_png_v2(const void *renderer, const uint8_t *json,
                                size_t len, uint32_t mode, uint32_t theme,
                                uint8_t **out_ptr, size_t *out_len) {
  *out_ptr = NULL;
  *out_len = 0;
  if (len == 0) return -1;
  if (json[0] == 0) {
    *out_len = 3; /* Malformed success: no buffer was returned. */
    return 0;
  }
  if (outstanding_bytes) return -5;
  uint8_t *bytes = malloc(3);
  if (!bytes) return -5;
  bytes[0] = json[0];
  bytes[1] = (uint8_t)mode;
  bytes[2] = (uint8_t)theme;
  *out_ptr = bytes;
  *out_len = json[0] == 1 ? SIZE_MAX : (json[0] == 255 ? 0 : 3);
  outstanding_bytes = bytes;
  outstanding_len = *out_len;
  return 0;
}
#endif

unsigned int fixture_live_renderers(void) { return live_renderers; }
unsigned int fixture_outstanding_buffers(void) { return outstanding_bytes != NULL; }
unsigned int fixture_buffer_frees(void) { return frees; }
unsigned int fixture_invalid_buffer_frees(void) { return invalid_frees; }

#ifdef WITH_OPTIONS
typedef struct {
  uint32_t size;
  uint32_t format;
  uint32_t theme;
  uint32_t mode;
} EqrShareRenderOptions;

int32_t eqr_render_share_png_with_options(
    const void *renderer, const uint8_t *json, size_t len,
    const EqrShareRenderOptions *options, uint8_t **out_ptr, size_t *out_len) {
  if (options->size != sizeof(*options) || options->format != 2) return -1;
  return eqr_render_share_png_v2(renderer, json, len, options->mode,
                                 options->theme, out_ptr, out_len);
}
#endif

#ifdef WITH_STORY
int32_t eqr_qa_render_story_png_v1(
    const void *renderer, const uint8_t *json, size_t len,
    const EqrShareRenderOptions *options, uint8_t **out_ptr, size_t *out_len) {
  if (options->size != sizeof(*options) || options->format != 3) return -1;
  return eqr_render_share_png_v2(renderer, json, len, options->mode,
                                 options->theme, out_ptr, out_len);
}
#endif

#ifdef WITH_V3
int32_t eqr_render_share_png_v3(
    const void *renderer, const uint8_t *json, size_t len,
    const EqrShareRenderOptions *options, uint8_t **out_ptr, size_t *out_len) {
  if (options->size != 16) return -2;
  if (options->format == 3) return -3;
  if (options->format != 1 && options->format != 2) return -1;
  if (len && json[0] == 2) return -2;
  return eqr_render_share_png_v2(renderer, json, len, options->mode,
                                 options->theme, out_ptr, out_len);
}
#endif

#ifdef WITH_STORY_V3
int32_t eqr_qa_render_story_png_v2(
    const void *renderer, const uint8_t *json, size_t len,
    const EqrShareRenderOptions *options, uint8_t **out_ptr, size_t *out_len) {
  if (len && json[0] == 2) return -2;
  return eqr_qa_render_story_png_v1(renderer, json, len, options, out_ptr, out_len);
}
#endif
