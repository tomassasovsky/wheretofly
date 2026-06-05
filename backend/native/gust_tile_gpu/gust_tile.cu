// CUDA kernel: renders a Mercator wind-gust raster tile.
//
// Exactly mirrors DwdIconGrid.valueAt (longitudeWrap=false) and the
// precomputed-LUT colour lookup from WindColorScale.writePixel.
//
// Build (RTX 3060 / Ampere = sm_86):
//   nvcc -arch=sm_86 -shared -fPIC -O3 -o libgust_tile_gpu.so gust_tile.cu
//
// For other GPUs set CUDA_ARCH, e.g. sm_75 (Turing), sm_70 (Volta).

#include "gust_tile.h"

#include <cuda_runtime.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

// Constant memory for the RGBA LUT — 512×4 = 2 KB, well under the 64 KB cap.
#define MAX_LUT_ENTRIES 512
__constant__ static uint8_t d_lut[MAX_LUT_ENTRIES * 4];

#define LUT_MAX_MPS 64.0f
#define M_PI_F      3.14159265358979323846f

struct GustTileGpu {
    int      lut_entries;
    float*   d_vals;
    int      d_vals_cap;
    uint8_t* d_out;
    int      d_out_cap;
};

// ---------------------------------------------------------------------------
// Device helpers
// ---------------------------------------------------------------------------

// Slippy-tile pixel → geographic coordinates (Mercator, matches Dart tile2lat/lon).
__device__ static void pixel_to_latlon(
    int col, int row,
    int tile_x, int tile_y, int tile_z, int tile_size,
    float scale,
    float* out_lat, float* out_lon)
{
    float ny = tile_y + (row + 0.5f) / tile_size;
    float n  = M_PI_F - (2.0f * M_PI_F * ny) / scale;
    *out_lat = atanf(0.5f * (expf(n) - expf(-n))) * (180.0f / M_PI_F);

    float nx = tile_x + (col + 0.5f) / tile_size;
    *out_lon = fmodf(nx / scale * 360.0f + 360.0f, 360.0f) - 180.0f;
}

// Bilinear interpolation — faithful translation of Dart _interpolateLinear
// with longitudeWrap=false (always the case for DwdIconTileRead.toGrid()).
__device__ static float interp(
    const float* __restrict__ vals, int vals_len,
    int nx,
    int x, int y,
    float xf, float yf)
{
    int index      = y * nx + x;
    int atEastEdge = (x >= nx - 1) ? 1 : 0;
    int atSouth    = (index + nx >= vals_len) ? 1 : 0;

    float p0 = vals[index];

    if (atEastEdge & atSouth) return isfinite(p0) ? p0 : nanf("");
    if (atEastEdge) {
        float p2 = vals[index + nx];
        return (isfinite(p0) & isfinite(p2))
               ? p0 * (1.0f - yf) + p2 * yf
               : (isfinite(p0) ? p0 : nanf(""));
    }
    if (atSouth) {
        float p1 = vals[index + 1];
        return (isfinite(p0) & isfinite(p1))
               ? p0 * (1.0f - xf) + p1 * xf
               : (isfinite(p0) ? p0 : nanf(""));
    }

    float p1 = vals[index + 1];
    float p2 = vals[index + nx];
    float p3 = vals[index + nx + 1];

    if (isfinite(p0) & isfinite(p1) & isfinite(p2) & isfinite(p3)) {
        return p0 * (1.0f - xf) * (1.0f - yf)
             + p1 *         xf  * (1.0f - yf)
             + p2 * (1.0f - xf) *         yf
             + p3 *         xf  *         yf;
    }
    return nanf("");
}

// ---------------------------------------------------------------------------
// Kernel
// ---------------------------------------------------------------------------

__global__ static void render_kernel(
    const float* __restrict__ vals, int vals_len,
    int nx, int ny,
    float dx, float dy,
    float lon_min, float lat_min, float lon_max, float lat_max,
    int tile_x, int tile_y, int tile_z,
    int tile_size,
    float scale,
    int lut_entries,
    uint8_t* __restrict__ out)
{
    int col = (int)(blockIdx.x * blockDim.x + threadIdx.x);
    int row = (int)(blockIdx.y * blockDim.y + threadIdx.y);
    if (col >= tile_size || row >= tile_size) return;

    float lat, lon;
    pixel_to_latlon(col, row, tile_x, tile_y, tile_z, tile_size, scale, &lat, &lon);

    int pixel_offset = (row * tile_size + col) * 4;

    // Bounds check mirrors DwdIconGrid.valueAt.
    if (lon < lon_min || lon > lon_max || lat < lat_min || lat >= lat_max) {
        out[pixel_offset]     = 0;
        out[pixel_offset + 1] = 0;
        out[pixel_offset + 2] = 0;
        out[pixel_offset + 3] = 0;
        return;
    }

    float fy = (lat - lat_min) / dy;
    int   iy = (int)floorf(fy);
    float yf = fmodf(lat - lat_min, dy) / dy;

    int   ix = min((int)floorf((lon - lon_min) / dx), nx - 1);
    float xf = fmodf(lon - lon_min, dx) / dx;

    float gust = interp(vals, vals_len, nx, ix, iy, xf, yf);

    if (!isfinite(gust)) {
        out[pixel_offset]     = 0;
        out[pixel_offset + 1] = 0;
        out[pixel_offset + 2] = 0;
        out[pixel_offset + 3] = 0;
        return;
    }

    float lut_scale = (float)lut_entries / LUT_MAX_MPS;
    int   li = (int)(gust * lut_scale);
    if (li < 0)            li = 0;
    if (li >= lut_entries) li = lut_entries - 1;
    li *= 4;

    out[pixel_offset]     = d_lut[li];
    out[pixel_offset + 1] = d_lut[li + 1];
    out[pixel_offset + 2] = d_lut[li + 2];
    out[pixel_offset + 3] = d_lut[li + 3];
}

// ---------------------------------------------------------------------------
// C API
// ---------------------------------------------------------------------------

extern "C" {

GustTileGpu* gust_tile_gpu_create(const uint8_t* lut_rgba, int lut_entries) {
    if (lut_entries < 1 || lut_entries > MAX_LUT_ENTRIES) return nullptr;

    if (cudaMemcpyToSymbol(d_lut, lut_rgba, (size_t)lut_entries * 4)
            != cudaSuccess)
        return nullptr;

    GustTileGpu* ctx = (GustTileGpu*)calloc(1, sizeof(GustTileGpu));
    if (!ctx) return nullptr;
    ctx->lut_entries = lut_entries;
    return ctx;
}

void gust_tile_gpu_destroy(GustTileGpu* ctx) {
    if (!ctx) return;
    if (ctx->d_vals) cudaFree(ctx->d_vals);
    if (ctx->d_out)  cudaFree(ctx->d_out);
    free(ctx);
}

int gust_tile_gpu_render(
    GustTileGpu* ctx,
    const float* vals, int vals_len,
    int grid_nx, int grid_ny,
    float dx, float dy,
    float lon_min, float lat_min, float lon_max, float lat_max,
    int tile_x, int tile_y, int tile_z,
    int tile_size,
    uint8_t* out_rgba)
{
    // Grow device value buffer as needed.
    size_t vals_bytes = (size_t)vals_len * sizeof(float);
    if (vals_len > ctx->d_vals_cap) {
        if (ctx->d_vals) cudaFree(ctx->d_vals);
        if (cudaMalloc(&ctx->d_vals, vals_bytes) != cudaSuccess) return 1;
        ctx->d_vals_cap = vals_len;
    }

    // Grow device output buffer as needed.
    int out_pixels = tile_size * tile_size * 4;
    if (out_pixels > ctx->d_out_cap) {
        if (ctx->d_out) cudaFree(ctx->d_out);
        if (cudaMalloc(&ctx->d_out, (size_t)out_pixels) != cudaSuccess) return 2;
        ctx->d_out_cap = out_pixels;
    }

    if (cudaMemcpy(ctx->d_vals, vals, vals_bytes, cudaMemcpyHostToDevice)
            != cudaSuccess)
        return 3;

    float scale = powf(2.0f, (float)tile_z);

    // 16×16 threads → 65 536 threads for a 256×256 tile.
    dim3 block(16, 16);
    dim3 grid((tile_size + 15) / 16, (tile_size + 15) / 16);

    render_kernel<<<grid, block>>>(
        ctx->d_vals, vals_len,
        grid_nx, grid_ny,
        dx, dy,
        lon_min, lat_min, lon_max, lat_max,
        tile_x, tile_y, tile_z,
        tile_size, scale,
        ctx->lut_entries,
        ctx->d_out);

    if (cudaGetLastError() != cudaSuccess) return 4;

    if (cudaMemcpy(out_rgba, ctx->d_out, (size_t)out_pixels,
                   cudaMemcpyDeviceToHost) != cudaSuccess)
        return 5;

    return 0;
}

} // extern "C"
