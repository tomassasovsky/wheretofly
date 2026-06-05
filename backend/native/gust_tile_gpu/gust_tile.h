#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GustTileGpu GustTileGpu;

/**
 * Creates a GPU tile renderer, uploading the RGBA LUT to CUDA constant memory.
 * Returns NULL if GPU initialisation fails.
 */
GustTileGpu* gust_tile_gpu_create(const uint8_t* lut_rgba, int lut_entries);

/** Frees all GPU and host resources allocated by gust_tile_gpu_create. */
void gust_tile_gpu_destroy(GustTileGpu* ctx);

/**
 * Renders a tile_size × tile_size RGBA raster using the CUDA kernel.
 *
 * vals       Flat row-major float32 grid (grid_ny × grid_nx).
 * vals_len   Total element count of vals.
 * grid_nx/ny Grid dimensions.
 * dx / dy    Cell size in degrees (typically 0.125).
 * lon/lat_*  Geographic bounds of the grid in degrees.
 * tile_x/y/z Slippy-tile indices.
 * tile_size  Pixel width/height (typically 256).
 * out_rgba   Caller-allocated output buffer (tile_size × tile_size × 4 bytes).
 *
 * Returns 0 on success, non-zero on CUDA error.
 */
int gust_tile_gpu_render(
    GustTileGpu* ctx,
    const float* vals, int vals_len,
    int grid_nx, int grid_ny,
    float dx, float dy,
    float lon_min, float lat_min, float lon_max, float lat_max,
    int tile_x, int tile_y, int tile_z,
    int tile_size,
    uint8_t* out_rgba);

#ifdef __cplusplus
}
#endif
