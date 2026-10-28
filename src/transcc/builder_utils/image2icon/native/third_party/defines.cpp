#define NANOSVG_ALL_COLOR_KEYWORDS

#define NANOSVG_IMPLEMENTATION
#include "nanosvg.h"

#define NANOSVGRAST_IMPLEMENTATION
#include "nanosvgrast.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION

#if defined(__clang__)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wc99-extensions"
#endif

#include "stb_image_resize2.h"

#if defined(__clang__)
    #pragma clang diagnostic pop
#endif

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"