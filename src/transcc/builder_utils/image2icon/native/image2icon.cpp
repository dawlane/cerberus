/*
 * Image converter: consolidated project implementation.
 * Project declarations are kept here in dependency order so that every type
 * is complete before any function signature that uses it.
 */

// The generated Cerberus runtime defines these POSIX-to-Windows compatibility
// macros globally. They must not leak into this implementation or its headers.
#if defined(_MSC_VER) && defined(_WIN32)

	#pragma push_macro("mkdir")
	#pragma push_macro("rmdir")
	#pragma push_macro("remove")
	#pragma push_macro("rename")
	#pragma push_macro("stat")
	#pragma push_macro("_fopen")
	#pragma push_macro("system")
	#pragma push_macro("realpath")
	#pragma push_macro("opendir")
	#pragma push_macro("readdir")
	#pragma push_macro("closedir")
	#pragma push_macro("DIR")
	#pragma push_macro("dirent")
	#pragma push_macro("min")
	#pragma push_macro("max")
	
	#undef mkdir
	#undef rmdir
	#undef remove
	#undef rename
	#undef stat
	#undef _fopen
	#undef system
	#undef realpath
	#undef opendir
	#undef readdir
	#undef closedir
	#undef DIR
	#undef dirent
	#undef min
	#undef max
#endif

#include <algorithm>
#include <array>
#include <cctype>
#include <cerrno>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <exception>
#include <fstream>
#include <limits>
#include <memory>
#include <set>
#include <stdexcept>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <utility>
#include <vector>

#if defined(_WIN32)
#include <direct.h>
#include <io.h>
#endif

#if defined(_WIN32)
#define STAT_STRUCT struct _stat
#define STAT_FUNC _stat
#define S_ISDIR_MACRO(m) (((m) & _S_IFMT) == _S_IFDIR)
#define S_ISREG_MACRO(m) (((m) & _S_IFMT) == _S_IFREG)
#define PATH_SEPARATOR '\\'
#else
#define STAT_STRUCT struct stat
#define STAT_FUNC stat
#define S_ISDIR_MACRO(m) S_ISDIR(m)
#define S_ISREG_MACRO(m) S_ISREG(m)
#define PATH_SEPARATOR '/'
#endif

// START:  Data definitions
enum class IconTarget { Windows, MacOS, Android, IOS, NONE };
struct ImageData {
    int width = 0;
    int height = 0;
    std::vector<std::uint8_t> pixels;
};

enum class ImageSourceType { Raster, SVG };

struct ImageSource {
    ImageSourceType type = ImageSourceType::Raster;
    std::string filename;
    ImageData raster;
};

struct ImageVariant {
    int size = 0;
    bool retina = false;
    ImageData image;
};

struct IcnsChunk {
    std::string type;
    std::vector<std::uint8_t> data;
};

struct IconsetEntry {
    int size;
    bool retina;
    const char *filename;
};

struct PngWriteContext {
    std::vector<std::uint8_t> data;
    bool failed = false;
};

struct PreparedImage {
    int size;
    const char *filename;
};

struct AndroidIconDensity {
    const char *mipmap_directory;
    const char *drawable_directory;
    int legacy_size;
    int adaptive_canvas_size;
    int adaptive_foreground_size;
};

// END:  Data definitions

// START:  Function declarations
void InvalidArgumentError(const std::string message1, const std::string message2 = "");
void RuntimeError(const std::string message1, const std::string message2 = "");
void OverFlowError(const std::string message1, const std::string message2 = "");
std::size_t GetPixelBufferSize(int width, int height);
std::string ToLower(std::string str);
bool HasSvgExtension(const std::string &filename);
bool IsDirectory(const char *path);
bool IsRegularFile(const char *path);
bool EndsWidth(const char *str, const char *suffix);
bool HasExtension(const char *path);
bool FileExists(const char *path, STAT_STRUCT *out_st = nullptr);
bool IsconsetDirectory(const char *path);
bool IsWindowsDirectory(const char *path);
std::string JointPath(const char *dir, const char *file);
void PathValidation(const char *input_path, const char *output_path);
void ValidateImageDimensions(int width, int height, const char *error_message);

IconTarget ParseIconTarget(const char *value);
std::string GetIconTargetName(IconTarget target);
std::vector<int> GetIconTargetIconSizes(IconTarget target);
const char *GetOutputExtension(IconTarget target);

ImageSource LoadImageSource(const std::string &filename);
void ValidateImageData(const ImageData &image);
ImageData LoadRasterImage(const std::string &filename);
ImageData LoadSvgImage(const std::string &filename, int width, int height);
ImageData ResizeImage(const ImageData &source, int width, int height);
void ApplyCircularMask(ImageData &image);
std::vector<ImageVariant> CreateImageVariants(const ImageSource &source, const std::vector<int> &sizes,
                                              bool circular = false);

std::vector<ImageVariant> LoadIconset(const char *directory);
std::vector<ImageVariant> LoadWindowIconDirectoryImages(const char *directory);

void WriteIco(const std::string &filename, const ImageSource &source, const std::vector<int> &sizes,
              bool circular = false);
void WriteIco(const std::string &filename, const std::vector<ImageVariant> &variants);
void WriteIcns(const std::string &filename, const ImageSource &source, const std::vector<int> &sizes,
               bool circular = false);
void WriteIcns(const std::string &filename, const std::vector<ImageVariant> &variants);
void WriteAndroidIcons(const char *output_directory, const ImageSource &source,
                       const char *background_colour = "#3F51B5", bool circular_mask = false);
void WriteIosIcons(const char *output_directory, const ImageSource &source, const char *background_colour = "#3F51B5");
std::vector<std::uint8_t> EncodePng(const ImageData &image);

int BuildOutputPath(char *output_buffer, std::size_t buffer_size, const char *output_name, IconTarget target);
void ConvertImage(IconTarget target, const char *input_path, const char *output_path, bool circular_mask = false,
                  const char *background_colour = "#3F51B5");
void ConvertImage(const char *input_path, const char *output_path, int width, int height, bool circular_mask = false,
                  const char *background_colour = "");

// END:  Function declarations

// START:  Common functions
void InvalidArgumentError(const std::string message1, const std::string message2) {
    const std::string message = message1 + ": " + message2;
    bbError(String(message.c_str()));
    //throw std::invalid_argument(message1 + std::string(": ") + message2);
}

void RuntimeError(const std::string message1, const std::string message2) {
    const std::string message = message1 + ": " + message2;
    bbError(String(message.c_str()));
    //throw std::runtime_error(std::string(message1) + ": " + message2);
}

void OverFlowError(const std::string message1, const std::string message2) {
    const std::string message = message1 + ": " + message2;
    bbError(String(message.c_str()));
    //throw std::overflow_error(std::string(message1) + ": " + message2);
}

std::size_t GetPixelBufferSize(int width, int height) {

    ValidateImageDimensions(width, height, "Image width and height dimensions must be greater than zero.");

    const std::size_t w = static_cast<std::size_t>(width);
    const std::size_t h = static_cast<std::size_t>(height);

    constexpr std::size_t bytesPerPixel = 4;
    const std::size_t maxSize = (std::numeric_limits<std::size_t>::max)();

    // Check before multiplying so the overflow check itself cannot overflow.
    if (w > maxSize / h)
        InvalidArgumentError("Pixel Buffer", "Image pixel count overflow");

    const std::size_t pixelCount = w * h;
    if (pixelCount > maxSize / bytesPerPixel)
        InvalidArgumentError("Pixel Buffer", "Image pixel count overflow");

    return pixelCount * bytesPerPixel;
}

std::string ToLower(std::string str) {
    std::transform(str.begin(), str.end(), str.begin(), [](unsigned char c) { return std::tolower(c); });
    return str;
}

bool HasSvgExtension(const std::string &filename) {
    const std::size_t separator = filename.find_last_of("/\\");
    const std::size_t extension = filename.find_last_of(".");

    if (extension == std::string::npos || (separator != std::string::npos && extension < separator)) return false;
    return ToLower(filename.substr(extension)) == ".svg";
}

bool IsDirectory(const char *path) {
    if (!path || *path == '\0') return false;

    STAT_STRUCT st;
    if (STAT_FUNC(path, &st) != 0) return false;
    return S_ISDIR_MACRO(st.st_mode);
}

bool IsRegularFile(const char *path) {
    if (!path || *path == '\0') return false;

    STAT_STRUCT st;
    if (STAT_FUNC(path, &st) != 0) return false;
    return S_ISREG_MACRO(st.st_mode);
}

bool EndsWidth(const char *str, const char *suffix) {
    if (!str || !suffix) return false;

    const size_t len = std::strlen(str);
    const size_t suffixLen = std::strlen(suffix);

    if (suffixLen > len) return false;
    return std::strcmp(str + len - suffixLen, suffix) == 0;
}

bool HasExtension(const char *path) {
    if (!path) return false;

    const char *lastDot = std::strrchr(path, '.');
    if (!lastDot || lastDot == path) return false;

    // Check both forward and backward slashes for cross-platform safety
    const char *lastSlash = std::strrchr(path, '/');
    const char *lastWinSlash = std::strrchr(path, '\\');

    // Pick whichever separator appears later in the string
    const char *lastSep = (lastWinSlash > lastSlash) ? lastWinSlash : lastSlash;
    return lastSep ? (lastDot > lastSep) : true;
}

bool FileExists(const char *path, STAT_STRUCT *out_st) {
    if (!path || *path == '\0') return false;

    STAT_STRUCT st;
    if (STAT_FUNC(path, &st) != 0) return false;
    if (out_st) *out_st = st;

    return true;
}

bool IsconsetDirectory(const char *path) { return IsDirectory(path) && EndsWidth(path, ".iconset"); }

bool IsWindowsDirectory(const char *path) {
    if (IsDirectory(path)) {
        if (EndsWidth(path, ".winnt") || EndsWidth(path, ".windows")) return true;
    }
    return false;
}

std::string JointPath(const char *dir, const char *file) {
    std::string result = dir ? dir : "";
    if (!result.empty() && result.back() != '/' && result.back() != '\\') result += PATH_SEPARATOR;
    if (file) result += file;
    return result;
}

void PathValidation(const char *input_path, const char *output_path) {
    if (input_path == nullptr || input_path[0] == '\0')
        InvalidArgumentError("Path Error", "Input path cannot be empty");
    if (output_path == nullptr || output_path[0] == '\0')
        InvalidArgumentError("Path Error", "Output path cannot be empty");
}

void ValidateImageDimensions(int width, int height, const char *error_message) {
    if (width <= 0 || height <= 0) InvalidArgumentError("Dimensions Error", error_message);
}

void CreateDirectoryOrThrow(const char *path) {
    if (path == nullptr || *path == '\0') InvalidArgumentError("Failed to create directory", path);

#if defined(_WIN32)
    if (_mkdir(path) == 0) return;
#else
    if (mkdir(path, 0777) == 0) return;
#endif

    if (errno == EEXIST && IsDirectory(path)) return;

    InvalidArgumentError("Failed to create directory", path);
}

void WriteTextFile(const char *path, const std::string &contents) {
    std::ofstream file(path, std::ios::binary | std::ios::trunc);

    if (!file) RuntimeError("Write Text File Error",std::string("Failed to create file: ") + path);

    file.write(contents.data(), static_cast<std::streamsize>(contents.size()));

    if (!file) RuntimeError("Write Text File Error",std::string("Failed to write file: ") + path);
}

IconTarget ParseIconTarget(const char *value) {
    if (value == nullptr || *value == '\0') InvalidArgumentError("Parse Icon Target Error", "Target cannot be empty");

    std::string lower_value(value);

    // Convert to lowercase without a variable-length array (not standard C++).
    for (char &ch : lower_value) ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));

    // Compare the lowercase string to the target values
    if (lower_value == "windows" || lower_value == "winnt") return IconTarget::Windows;
    if (lower_value == "macos") return IconTarget::MacOS;
    if (lower_value == "android") return IconTarget::Android;
    if (lower_value == "ios") return IconTarget::IOS;

    char buf[256];
    snprintf(buf, sizeof(buf), "Unknown icon target %s", value);
    InvalidArgumentError("Icon Target Error", buf);
    return IconTarget::NONE;
}

// Return os id based on the target icon
std::string GetIconTargetName(IconTarget target) {
    switch (target) {
    case IconTarget::Windows:
        return "windows";
    case IconTarget::MacOS:
        return "macos";
    case IconTarget::Android:
        return "android";
    case IconTarget::IOS:
        return "ios";
    }

    InvalidArgumentError("Get Icon Target Error", "Invalid icon target");
    return "";
}

/*
    Return a vector of integers for the icon sizes
    Android and iOS use a different method.
*/
std::vector<int> GetIconTargetIconSizes(IconTarget target) {
    switch (target) {
    case IconTarget::Windows:
        return {16, 24, 32, 40, 48, 64, 96, 128, 256};
    case IconTarget::MacOS:
        return {16, 32, 64, 128, 256, 512, 1024};
    case IconTarget::Android:
    case IconTarget::IOS:
        return {};
    }

    InvalidArgumentError("Get Icon Target Size Error", "Invalid icon target");
    return {};
}

// The file extention is based on the icon target type
const char *GetOutputExtension(IconTarget target) {
    switch (target) {
    case IconTarget::Windows:
        return ".ico";
    case IconTarget::MacOS:
        return ".icns";
    case IconTarget::Android:
    case IconTarget::IOS:
        return "";
    }

    InvalidArgumentError("Get Icon Target Extension Error", "Invalid icon target");
    return "";
}

int ParseResizeHexDigit(char value) {
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    return -1;
}

std::uint8_t ParseResizeHexByte(const char *value) {
    const int high = ParseResizeHexDigit(value[0]);
    const int low = ParseResizeHexDigit(value[1]);

    if (high < 0 || low < 0)
        InvalidArgumentError("Parse Resize Hex Byte Error", "Invalid background colour: expected hexadecimal RGB");
    return static_cast<std::uint8_t>((high << 4) | low);
}

// Check WritePngToDisk
void WritePngToDisk(const char *path, const ImageData &image) {
    const std::vector<std::uint8_t> png = EncodePng(image);
    std::ofstream file(path, std::ios::binary | std::ios::trunc);
    if (!file) RuntimeError("Write Png Error", std::string("Failed to create PNG: ") + path);
    file.write(reinterpret_cast<const char *>(png.data()), static_cast<std::streamsize>(png.size()));
    if (!file) RuntimeError("Write Png Error", std::string("Failed to write PNG: ") + path);
}

void ParseResizeBackgroundColour(const char *background_colour, std::uint8_t &red, std::uint8_t &green,
                                 std::uint8_t &blue) {
    if (background_colour == nullptr || *background_colour == '\0')
        InvalidArgumentError("Parse Resize Background Colour Error", "Background colour cannot be empty");

    const char *hex = background_colour;

    if (*hex == '#') ++hex;
    if (std::strlen(hex) != 6)
        InvalidArgumentError("Parse Resize Background Colour Error", "Invalid background colour: expected #RRGGBB");

    red = ParseResizeHexByte(hex);
    green = ParseResizeHexByte(hex + 2);
    blue = ParseResizeHexByte(hex + 4);
}

void ApplyResizeBackgroundColour(ImageData &image, const char *background_colour) {
    ValidateImageData(image);

    std::uint8_t background_red;
    std::uint8_t background_green;
    std::uint8_t background_blue;

    ParseResizeBackgroundColour(background_colour, background_red, background_green, background_blue);

    for (int y = 0; y < image.height; ++y) {
        for (int x = 0; x < image.width; ++x) {
            const std::size_t index =
                (static_cast<std::size_t>(y) * static_cast<std::size_t>(image.width) + static_cast<std::size_t>(x)) * 4;

            const unsigned int alpha = image.pixels[index + 3];
            const unsigned int inverse_alpha = 255 - alpha;

            image.pixels[index] =
                static_cast<std::uint8_t>((image.pixels[index] * alpha + background_red * inverse_alpha + 127) / 255);

            image.pixels[index + 1] = static_cast<std::uint8_t>(
                (image.pixels[index + 1] * alpha + background_green * inverse_alpha + 127) / 255);

            image.pixels[index + 2] = static_cast<std::uint8_t>(
                (image.pixels[index + 2] * alpha + background_blue * inverse_alpha + 127) / 255);

            image.pixels[index + 3] = 255;
        }
    }
}
// END:  Common functions

// START:  Core image functions
void ValidateImageData(const ImageData &image) {
    const std::size_t expectedSize = GetPixelBufferSize(image.width, image.height);

    if (image.pixels.size() != expectedSize)
        InvalidArgumentError("Validate Image Error", "Image pixel data does not match it's dimensions");
}

ImageData LoadRasterImage(const std::string &filename) {
    if (HasSvgExtension(filename))
        InvalidArgumentError("Load Raster Image Error",
                             "SVG images require a target size. Use LoadSvgImage() instead.");

    int width = 0;
    int height = 0;
    int channels = 0;

    using StbiPtr = std::unique_ptr<stbi_uc, decltype(&stbi_image_free)>;
    StbiPtr decoded(stbi_load(filename.c_str(), &width, &height, &channels, 4), &stbi_image_free);
    if (!decoded) {
        const char *reason = stbi_failure_reason();

        RuntimeError("Load Raster Image Error", std::string("Failed to load image '") + filename + std::string("': ") +
                                                    (reason != nullptr ? reason : "unknown error"));
    }

    const std::size_t byteCount = GetPixelBufferSize(width, height);

    ImageData image;
    image.width = width;
    image.height = height;

    image.pixels.assign(decoded.get(), decoded.get() + byteCount);

    return image;
}

ImageData LoadSvgImage(const std::string &filename, int width, int height) {

    ValidateImageDimensions(width, height, "SVG output dimensions must be positive.");

    std::unique_ptr<NSVGimage, decltype(&nsvgDelete)> image(nsvgParseFromFile(filename.c_str(), "px", 96.0f),
                                                            &nsvgDelete);

    if (!image) RuntimeError("Load SVG Image Error", std::string("Failed to parse SVG file: ") + filename);

    if (image->width <= 0.0f || image->height <= 0.0f)
        RuntimeError("Load SVG Image Error", "SVG has invalid dimensions: " + filename);

    std::unique_ptr<NSVGrasterizer, decltype(&nsvgDeleteRasterizer)> rasterizer(nsvgCreateRasterizer(),
                                                                                &nsvgDeleteRasterizer);

    if (!rasterizer) RuntimeError("Load SVG Error", "Failed to create SVG rasterizer");

    // Preserve the SVG viewport aspect ratio.
    const float scaleX = static_cast<float>(width) / image->width;
    const float scaleY = static_cast<float>(height) / image->height;
    const float scale = std::min(scaleX, scaleY);

    // Dimensions occupied by the scaled SVG viewport.
    const float renderedWidth = image->width * scale;
    const float renderedHeight = image->height * scale;

    // Centre the viewport in the output canvas.
    const float offsetX = (static_cast<float>(width) - renderedWidth) * 0.5f;
    const float offsetY = (static_cast<float>(height) - renderedHeight) * 0.5f;

    ImageData result;
    result.width = width;
    result.height = height;

    result.pixels.assign(GetPixelBufferSize(width, height), 0);

    nsvgRasterize(rasterizer.get(), image.get(), offsetX, offsetY, scale, result.pixels.data(), width, height,
                  width * 4);

    ValidateImageData(result);

    return result;
}

ImageData ResizeImage(const ImageData &source, int width, int height) {

    ValidateImageDimensions(width, height, "Resize width and height dimensions must be positive integers");
    ValidateImageData(source);

    // Calculate the largest size that fits inside the destination while preserving the source aspect ratio.
    const float scaleX = static_cast<float>(width) / static_cast<float>(source.width);
    const float scaleY = static_cast<float>(height) / static_cast<float>(source.height);
    const float scale = std::min(scaleX, scaleY);
    int resizedWidth = static_cast<int>(std::round(static_cast<float>(source.width) * scale));
    int resizedHeight = static_cast<int>(std::round(static_cast<float>(source.height) * scale));

    // Protect against rounding producing zero for extremely small dimensions.
    resizedWidth = std::max(resizedWidth, 1);
    resizedHeight = std::max(resizedHeight, 1);

    ImageData result;
    result.width = width;
    result.height = height;

    // ImageData is RGBA, so value-initializing the vector gives us a completely transparent destination.
    result.pixels.assign(GetPixelBufferSize(width, height), 0);

    // Resize into a temporary RGBA image.
    ImageData resized;
    resized.width = resizedWidth;
    resized.height = resizedHeight;
    resized.pixels.resize(GetPixelBufferSize(resizedWidth, resizedHeight));

    const int sourceStride = source.width * 4;
    const int resizedStride = resizedWidth * 4;

    if (!stbir_resize(source.pixels.data(), source.width, source.height, sourceStride, resized.pixels.data(),
                      resizedWidth, resizedHeight, resizedStride, STBIR_RGBA, STBIR_TYPE_UINT8, STBIR_EDGE_CLAMP,
                      STBIR_FILTER_DEFAULT)) {
        RuntimeError("Resize Image Error", "Failed to resize image");
    }

    // Center the resized image inside the transparent destination canvas.
    const int offsetX = (width - resizedWidth) / 2;
    const int offsetY = (height - resizedHeight) / 2;

    for (int y = 0; y < resizedHeight; ++y) {
        const std::uint8_t *sourceRow =
            resized.pixels.data() + static_cast<std::size_t>(y) * static_cast<std::size_t>(resizedStride);

        std::uint8_t *destinationRow = result.pixels.data() +
                                       static_cast<std::size_t>(y + offsetY) * static_cast<std::size_t>(width * 4) +
                                       static_cast<std::size_t>(offsetX) * 4;

        std::copy(sourceRow, sourceRow + resizedStride, destinationRow);
    }

    ValidateImageData(result);

    return result;
}

void ApplyCircularMask(ImageData &image) {
    ValidateImageData(image);

    const double centerX = (static_cast<double>(image.width) - 1.0) / 2.0;
    const double centerY = (static_cast<double>(image.height) - 1.0) / 2.0;
    const double radius = static_cast<double>(std::min(image.width, image.height)) / 2.0;
    const double radiusSquared = radius * radius;

    for (int y = 0; y < image.height; ++y) {
        for (int x = 0; x < image.width; ++x) {
            const double dx = static_cast<double>(x) - centerX;
            const double dy = static_cast<double>(y) - centerY;

            if ((dx * dx) + (dy * dy) > radiusSquared) {
                const std::size_t index = (static_cast<std::size_t>(y) * static_cast<std::size_t>(image.width) +
                                           static_cast<std::size_t>(x)) *
                                          4;

                image.pixels[index + 3] = 0;
            }
        }
    }
}
// END:  Core image functions

// START:  Functions to handle image variations
ImageSource LoadImageSource(const std::string &filename) {

    if (filename.empty()) InvalidArgumentError("Load Image Source Error", "Image file name cannot be empty.");

    ImageSource source;
    source.filename = filename;

    if (HasSvgExtension(filename)) {
        source.type = ImageSourceType::SVG;
    } else {
        source.type = ImageSourceType::Raster;
        source.raster = LoadRasterImage(filename);
    }

    return source;
}

std::vector<ImageVariant> CreateImageVariants(const ImageSource &source, const std::vector<int> &sizes, bool circular) {
    if (source.type == ImageSourceType::Raster) ValidateImageData(source.raster);

    if (sizes.empty()) InvalidArgumentError("Create Image Variants Error", "At least one image size is required.");

    std::vector<ImageVariant> variants;
    variants.reserve(sizes.size());

    for (const int size : sizes) {
        if (size <= 0)
            InvalidArgumentError("Create Image Variants Error", "Image variant size must be greater than zero.");

        ImageVariant variant;
        variant.size = size;

        if (source.type == ImageSourceType::SVG)
            variant.image = LoadSvgImage(source.filename, size, size);
        else
            variant.image = ResizeImage(source.raster, size, size);

        if (circular) ApplyCircularMask(variant.image);

        variants.push_back(std::move(variant));
    }

    return variants;
}

// END:  Functions to handle image variations

// START:  Functions to handle PNG encoding
void WriteCallback(void *context, void *data, int size) {
    auto *output = static_cast<PngWriteContext *>(context);
    if (output == nullptr || output->failed) return;

    if (data == nullptr || size < 0) {
        output->failed = true;
        return;
    }

    try {
        const auto *bytes = static_cast<const std::uint8_t *>(data);

        output->data.insert(output->data.end(), bytes, bytes + size);
    } catch (...) {
        output->failed = true;
    }
}

std::vector<std::uint8_t> EncodePng(const ImageData &image) {
    ValidateImageData(image);
    if (image.width > std::numeric_limits<int>::max() / 4)
        InvalidArgumentError("Encode PNG Error", "Image row stride exceeds the supported range");

    PngWriteContext output;
    const int result = stbi_write_png_to_func(WriteCallback, &output, image.width, image.height, 4, image.pixels.data(),
                                              image.width * 4);

    if (result == 0 || output.failed || output.data.empty()) RuntimeError("Encode PNG Error", "Failed to encode PNG");

    return std::move(output.data);
}

// END:  Functions to handle PNG encoding

// START:  Functions for macos icon set directories
constexpr std::array<IconsetEntry, 10> Entries = {{{16, false, "icon_16x16.png"},
                                                   {16, true, "icon_16x16@2x.png"},

                                                   {32, false, "icon_32x32.png"},
                                                   {32, true, "icon_32x32@2x.png"},

                                                   {128, false, "icon_128x128.png"},
                                                   {128, true, "icon_128x128@2x.png"},

                                                   {256, false, "icon_256x256.png"},
                                                   {256, true, "icon_256x256@2x.png"},

                                                   {512, false, "icon_512x512.png"},
                                                   {512, true, "icon_512x512@2x.png"}}};

int ExpectedPixelSize(const IconsetEntry &entry) { return entry.retina ? entry.size * 2 : entry.size; }

std::vector<ImageVariant> LoadIconset(const char *directory) {
    if (!directory || *directory == '\0')
        InvalidArgumentError("Load Icon Set Error", "Iconset directory cannot be empty");

    STAT_STRUCT dirSt;
    if (!FileExists(directory, &dirSt))
        RuntimeError("Load Icon Set Error", std::string("Iconset directory does not exist: ") + directory);

    if (!S_ISDIR_MACRO(dirSt.st_mode)) RuntimeError(std::string("Iconset path is not a directory: ") + directory);

    if (!EndsWidth(directory, ".iconset"))
        RuntimeError(std::string("Iconset directory must have a .iconset extension: ") + directory);

    std::vector<ImageVariant> variants;

    for (const IconsetEntry &entry : Entries) {
        const std::string filename = JointPath(directory, entry.filename);

        STAT_STRUCT fileSt;
        if (!FileExists(filename.c_str(), &fileSt)) continue;
        if (!S_ISREG_MACRO(fileSt.st_mode))
            RuntimeError("Load Icon Set Error", "Iconset entry is not a regular file: " + filename);

        ImageData image = LoadRasterImage(filename.c_str());
        const int expectedSize = ExpectedPixelSize(entry);
        if (image.width != expectedSize || image.height != expectedSize) {
            RuntimeError("Load Icon Set Error",std::string("Invalid dimensions for iconset entry: " + filename + " (expected " +
                                                 std::to_string(expectedSize) + "x" + std::to_string(expectedSize) +
                                                 ", got " + std::to_string(expectedSize) + "x" +
                                                 std::to_string(expectedSize) + ")"));
        }

        ImageVariant variant;
        variant.size = entry.size;
        variant.retina = entry.retina;
        variant.image = std::move(image);
        variants.push_back(std::move(variant));
    }

    if (variants.empty())
        RuntimeError("Load Icon Set Error", std::string("Iconset contains no recognised images: ") + directory);

    return variants;
}

// END:  Functions for macos icon set directories

// START:  Functions for windows icon set directories
constexpr PreparedImage preparedImages[] = {{16, "16.png"}, {24, "24.png"},   {32, "32.png"},
                                            {40, "40.png"}, {48, "48.png"},   {64, "64.png"},
                                            {96, "96.png"}, {128, "128.png"}, {256, "256.png"}};

std::vector<ImageVariant> LoadWindowIconDirectoryImages(const char *directory) {
    if (!directory || *directory == '\0')
        InvalidArgumentError("Load Window Icon Directory Error", "Prepared image directory path cannot be empty");

    STAT_STRUCT dirSt;
    if (!FileExists(directory, &dirSt))
        RuntimeError("Load Window Icon Directory Error",
                     std::string("Prepared image directory does not exist: ") + directory);

    if (!S_ISDIR_MACRO(dirSt.st_mode))
        RuntimeError(std::string("Prepared image path is not a directory: ") + directory);

    if (!(EndsWidth(directory, ".windows") || EndsWidth(directory, ".winnt")))
        RuntimeError("Load Window Icon Directory Error",
                     std::string("Prepared image directory must have a .windows or .winnt extension: ") + directory);

    std::vector<ImageVariant> variants;

    for (const PreparedImage &prepared : preparedImages) {
        const std::string filename = JointPath(directory, prepared.filename);

        STAT_STRUCT fileSt;
        if (!FileExists(filename.c_str(), &fileSt)) continue;
        if (!S_ISREG_MACRO(fileSt.st_mode))
            RuntimeError("Load Window Icon Directory Error",
                         std::string("Prepared image is not a regular file: ") + filename);

        const ImageData image = LoadRasterImage(filename.c_str());

        if (image.width != prepared.size || image.height != prepared.size)
            RuntimeError("Load Window Icon Directory Error",
                         std::string("Prepared image has incorrect dimensions: ") + filename);

        ImageVariant variant;
        variant.size = prepared.size;
        variant.retina = false;
        variant.image = image;
        variants.push_back(std::move(variant));
    }

    if (variants.empty())
        RuntimeError("Load Window Icon Directory Error",
                     std::string("No recognized prepared images found in: ") + directory);

    return variants;
}
// END:  Functions for windows icon set directories

// START:  Functions to handle the writing of ico files.
using Byte = std::uint8_t;
using Bytes = std::vector<Byte>;

void AppendUInt16LE(Bytes &output, std::uint16_t value) {
    output.push_back(static_cast<Byte>(value & 0xFF));
    output.push_back(static_cast<Byte>((value >> 8) & 0xFF));
}

void AppendUInt32LE(Bytes &output, std::uint32_t value) {
    output.push_back(static_cast<Byte>(value & 0xFF));
    output.push_back(static_cast<Byte>((value >> 8) & 0xFF));
    output.push_back(static_cast<Byte>((value >> 16) & 0xFF));
    output.push_back(static_cast<Byte>((value >> 24) & 0xFF));
}

Byte EncodeDimensions(int dimensions) { return dimensions == 256 ? 0 : static_cast<Byte>(dimensions); }

std::uint32_t CheckUint32(std::size_t value) {
    if (value > std::numeric_limits<std::uint32_t>::max())
        RuntimeError("Check UInt32 Error", std::string("ICO file exceeds 32-bit size limits"));

    return static_cast<std::uint32_t>(value);
}

void WriteIco(const std::string &filename, const ImageSource &source, const std::vector<int> &sizes, bool circular) {

    if (sizes.size() > std::numeric_limits<std::uint16_t>::max())
        InvalidArgumentError("Write Icon Error", "Too many ICO images");

    for (std::size_t i = 0; i < sizes.size(); ++i) {
        if (sizes[i] <= 0 || sizes[i] > 256)
            InvalidArgumentError("Write Icon Error", "ICO dimensions must be between 1 and 256");

        for (std::size_t j = 0; j < i; ++j)
            if (sizes[i] == sizes[j]) InvalidArgumentError("Write Icon Error", "Duplicate ICO image size");
    }

    const std::vector<ImageVariant> variants = CreateImageVariants(source, sizes, circular);

    WriteIco(filename, variants);
}

void WriteIco(const std::string &filename, const std::vector<ImageVariant> &variants) {

    if (variants.size() > std::numeric_limits<std::uint16_t>::max())
        InvalidArgumentError("Write Icon Error", "Too many ICO images");

    for (std::size_t i = 0; i < variants.size(); ++i) {
        const ImageVariant &variant = variants[i];

        if (variant.retina) InvalidArgumentError("Write Icon Error", "ICO images cannot be Retina variants");
        if (variant.size <= 0 || variant.size > 256)
            InvalidArgumentError("Write Icon Error", "ICO dimensions must be between 1 and 256");
        if (variant.image.width != variant.size || variant.image.height != variant.size)
            InvalidArgumentError("Write Icon Error", "ICO image dimensions do not match the variant size");

        for (std::size_t j = 0; j < i; ++j)
            if (variant.size == variants[j].size) InvalidArgumentError("Write Icon Error", "Duplicate ICO image size");
    }

    std::vector<Bytes> pngImages;
    pngImages.reserve(variants.size());

    for (const ImageVariant &variant : variants) pngImages.push_back(EncodePng(variant.image));

    constexpr std::size_t headerSize = 6;
    constexpr std::size_t entrySize = 16;
    const std::size_t directorySize = headerSize + entrySize * variants.size();
    std::size_t totalSize = directorySize;

    for (const Bytes &png : pngImages) {
        if (png.empty() || png.size() > std::numeric_limits<std::size_t>::max() - totalSize)
            RuntimeError("Write Icon Error", "ICO file size overflow");

        totalSize += png.size();
    }

    CheckUint32(totalSize);

    Bytes icoData;
    icoData.reserve(totalSize);

    AppendUInt16LE(icoData, 0);
    AppendUInt16LE(icoData, 1);
    AppendUInt16LE(icoData, static_cast<std::uint16_t>(variants.size()));

    std::size_t imageOffset = directorySize;

    for (std::size_t i = 0; i < variants.size(); ++i) {
        const ImageVariant &variant = variants[i];

        const Bytes &png = pngImages[i];

        icoData.push_back(EncodeDimensions(variant.image.width));
        icoData.push_back(EncodeDimensions(variant.image.height));

        icoData.push_back(0);
        icoData.push_back(0);

        AppendUInt16LE(icoData, 1);
        AppendUInt16LE(icoData, 32);

        AppendUInt32LE(icoData, CheckUint32(png.size()));
        AppendUInt32LE(icoData, CheckUint32(imageOffset));

        imageOffset += png.size();
    }

    for (const Bytes &png : pngImages) icoData.insert(icoData.end(), png.begin(), png.end());

    if (icoData.size() > static_cast<std::size_t>(std::numeric_limits<std::streamsize>::max()))
        RuntimeError("Write Icon Error", "ICO file is too large to write");

    std::ofstream file(filename, std::ios::binary | std::ios::trunc);

    if (!file) RuntimeError("Write Icon Error", "Failed to open ICO output file: " + filename);

    file.write(reinterpret_cast<const char *>(icoData.data()), static_cast<std::streamsize>(icoData.size()));

    if (!file) RuntimeError("Write Icon Error", "Failed to write ICO output file: " + filename);
}
// END:  Functions to handle the writing of ico files.

// START:  Functions to handle the writing of icns files.
void WriteBigEndianUInt32(std::vector<std::uint8_t> &output, std::uint32_t value) {
    output.push_back(static_cast<std::uint8_t>((value >> 24) & 0xff));
    output.push_back(static_cast<std::uint8_t>((value >> 16) & 0xff));
    output.push_back(static_cast<std::uint8_t>((value >> 8) & 0xff));
    output.push_back(static_cast<std::uint8_t>(value & 0xff));
}

void WriteBinaryFile(const std::string &filename, const std::vector<std::uint8_t> &data) {
    std::ofstream file(filename, std::ios::binary);

    if (!file) RuntimeError("Write Binary File Error","Failed to open output file: " + filename);

    if (!data.empty())
        file.write(reinterpret_cast<const char *>(data.data()), static_cast<std::streamsize>(data.size()));

    if (!file) RuntimeError("Write Binary File Error","Failed to write output file: " + filename);
}

const char *GetIcnsTypeForPixelSize(int size) {
    switch (size) {
    case 16:
        return "icp4";

    case 32:
        return "icp5";

    case 64:
        return "icp6";

    case 128:
        return "ic07";

    case 256:
        return "ic08";

    case 512:
        return "ic09";

    case 1024:
        return "ic10";

    default:
        InvalidArgumentError("Get Icns Type For Pixel Size Error",
                             "Unsupported ICNS image size: " + std::to_string(size));
    }

    return "";
}

const char *GetIcnsTypeForVariant(const ImageVariant &variant) {
    if (variant.size == 16) return variant.retina ? "ic11" : "icp4";

    if (variant.size == 32) return variant.retina ? "ic12" : "icp5";

    if (variant.size == 128) return variant.retina ? "ic13" : "ic07";

    if (variant.size == 256) return variant.retina ? "ic14" : "ic08";

    if (variant.size == 512) return variant.retina ? "ic10" : "ic09";

    InvalidArgumentError("Get Icns Type For Variant Error",
                         "Unsupported ICNS logical image size: " + std::to_string(variant.size));
    return "\0";
}

void ValidatePixelVariant(const ImageVariant &variant) {
    if (variant.retina)
        InvalidArgumentError("Validate Pixel Variant Error",
                             "Retina variants are not valid for the standard ICNS image-size writer");

    if (variant.size <= 0) InvalidArgumentError("Validate Pixel Variant Error", "ICNS image size must be positive");

    ValidateImageData(variant.image);

    if (variant.image.width != variant.size || variant.image.height != variant.size) {
        InvalidArgumentError(
            "Validate Pixel Variant Error",
            "ICNS image variant size does not match image dimensions: " + std::to_string(variant.size) + " (" +
                std::to_string(variant.image.width) + "x" + std::to_string(variant.image.height) + ")");
    }
}

void ValidateIconsetVariant(const ImageVariant &variant) {
    if (variant.size != 16 && variant.size != 32 && variant.size != 128 && variant.size != 256 && variant.size != 512)
        InvalidArgumentError("Validate Icon Set Variant Error",
                             "Unsupported ICNS logical image size: " + std::to_string(variant.size));

    ValidateImageData(variant.image);

    const int expectedSize = variant.retina ? variant.size * 2 : variant.size;

    if (variant.image.width != expectedSize || variant.image.height != expectedSize) {
        InvalidArgumentError("Validate Icon Set Variant Error",
                             "Invalid ICNS image dimensions for " + std::to_string(variant.size) +
                                 (variant.retina ? "@2x" : "") + ": expected " + std::to_string(expectedSize) + "x" +
                                 std::to_string(expectedSize) + ", got " + std::to_string(variant.image.width) + "x" +
                                 std::to_string(variant.image.height));
    }
}

std::vector<std::uint8_t> BuildIcns(const std::vector<IcnsChunk> &chunks) {
    if (chunks.empty()) InvalidArgumentError("Build Icns Error", "ICNS requires at least one image");

    std::uint64_t totalSize = 8;

    for (const IcnsChunk &chunk : chunks) {
        if (chunk.type.size() != 4)
            InvalidArgumentError("Build Icns Error", "ICNS chunk type must contain exactly four characters");

        if (chunk.data.size() > std::numeric_limits<std::uint32_t>::max() - 8u)
            OverFlowError("Build Icns Error", "ICNS chunk is too large");

        totalSize += 8u + static_cast<std::uint64_t>(chunk.data.size());
    }

    if (totalSize > std::numeric_limits<std::uint32_t>::max())
        OverFlowError("Build Icns Error", "ICNS file is too large");

    std::vector<std::uint8_t> output;

    output.reserve(static_cast<std::size_t>(totalSize));

    output.push_back('i');
    output.push_back('c');
    output.push_back('n');
    output.push_back('s');

    WriteBigEndianUInt32(output, static_cast<std::uint32_t>(totalSize));

    for (const IcnsChunk &chunk : chunks) {
        output.push_back(static_cast<std::uint8_t>(chunk.type[0]));
        output.push_back(static_cast<std::uint8_t>(chunk.type[1]));
        output.push_back(static_cast<std::uint8_t>(chunk.type[2]));
        output.push_back(static_cast<std::uint8_t>(chunk.type[3]));

        const std::uint32_t chunkSize = static_cast<std::uint32_t>(8u + chunk.data.size());

        WriteBigEndianUInt32(output, chunkSize);

        output.insert(output.end(), chunk.data.begin(), chunk.data.end());
    }

    return output;
}

void WriteIcns(const std::string &filename, const ImageSource &source, const std::vector<int> &sizes, bool circular) {

    const std::vector<ImageVariant> variants = CreateImageVariants(source, sizes, circular);
    if (variants.empty()) InvalidArgumentError("Write Icns Error", "ICNS requires at least one variant");
    std::vector<IcnsChunk> chunks;
    chunks.reserve(variants.size());
    std::set<std::string> usedTypes;
    for (const ImageVariant &variant : variants) {
        ValidatePixelVariant(variant);
        const std::string type = GetIcnsTypeForPixelSize(variant.size);
        if (!usedTypes.insert(type).second)
            InvalidArgumentError("Write Icns Error", "Duplicate ICNS image size: " + std::to_string(variant.size));

        IcnsChunk chunk;
        chunk.type = type;
        chunk.data = EncodePng(variant.image);
        chunks.push_back(std::move(chunk));
    }

    const std::vector<std::uint8_t> output = BuildIcns(chunks);
    WriteBinaryFile(filename, output);
}

void WriteIcns(const std::string &filename, const std::vector<ImageVariant> &variants) {

    if (variants.empty()) InvalidArgumentError("Write Icns Error", "ICNS requires at least one image variant");

    std::vector<IcnsChunk> chunks;
    chunks.reserve(variants.size());

    std::set<std::string> usedTypes;
    for (const ImageVariant &variant : variants) {
        ValidateIconsetVariant(variant);
        const std::string type = GetIcnsTypeForVariant(variant);
        if (!usedTypes.insert(type).second)
            InvalidArgumentError("Write Icns Error", "Duplicate ICNS image representation: " + type);

        IcnsChunk chunk;
        chunk.type = type;
        chunk.data = EncodePng(variant.image);
        chunks.push_back(std::move(chunk));
    }

    const std::vector<std::uint8_t> output = BuildIcns(chunks);

    WriteBinaryFile(filename, output);
}
// END:  Functions to handle the writing of icns files.

// START:  Functions to handle the writing of Android resource directories
constexpr std::array<AndroidIconDensity, 5> androidIconDensities = {
    {// mipmap directory,    drawable directory, legacy, canvas, foreground
     {"mipmap-mdpi", "drawable-mdpi", 48, 108, 66},
     {"mipmap-hdpi", "drawable-hdpi", 72, 162, 99},
     {"mipmap-xhdpi", "drawable-xhdpi", 96, 216, 132},
     {"mipmap-xxhdpi", "drawable-xxhdpi", 144, 324, 198},
     {"mipmap-xxxhdpi", "drawable-xxxhdpi", 192, 432, 264}}};

// Default adaptive-icon background colour: #3F51B5.
constexpr std::uint8_t ANDROID_BACKGROUND_RED = 63;
constexpr std::uint8_t ANDROID_BACKGROUND_GREEN = 81;
constexpr std::uint8_t ANDROID_BACKGROUND_BLUE = 181;

void WriteAndroidBackgroundXml(const std::string &resource_root, const char *background_colour) {
    const std::string drawable_directory = JointPath(resource_root.c_str(), "drawable");

    CreateDirectoryOrThrow(drawable_directory.c_str());

    const std::string background_path = JointPath(drawable_directory.c_str(), "ic_launcher_background.xml");

    const std::string xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                            "<shape xmlns:android=\"http://schemas.android.com/apk/res/android\"\n"
                            "    android:shape=\"rectangle\">\n"
                            "    <solid android:color=\"" +
                            std::string(background_colour) +
                            "\" />\n"
                            "</shape>\n";

    WriteTextFile(background_path.c_str(), xml.c_str());
}

// Check CreateAndroidAdaptiveForeground
ImageData CreateAndroidAdaptiveForeground(const ImageSource &source, int canvas_size, int foreground_size) {
    ImageData foreground;
    foreground.width = canvas_size;
    foreground.height = canvas_size;
    foreground.pixels.resize(GetPixelBufferSize(canvas_size, canvas_size), 0);

    const std::vector<ImageVariant> variants = CreateImageVariants(source, {foreground_size});

    const ImageData &icon = variants.front().image;
    const int offset_x = (canvas_size - foreground_size) / 2;
    const int offset_y = (canvas_size - foreground_size) / 2;

    for (int y = 0; y < foreground_size; ++y) {
        for (int x = 0; x < foreground_size; ++x) {
            const std::size_t source_offset = (static_cast<std::size_t>(y) * foreground_size + x) * 4;
            const std::size_t target_offset =
                (static_cast<std::size_t>(y + offset_y) * canvas_size + (x + offset_x)) * 4;

            for (int channel = 0; channel < 4; ++channel)
                foreground.pixels[target_offset + channel] = icon.pixels[source_offset + channel];
        }
    }

    ValidateImageData(foreground);
    return foreground;
}

void WriteAndroidAdaptiveXml(const char *path) {
    const std::string xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                            "<adaptive-icon "
                            "xmlns:android=\"http://schemas.android.com/apk/res/android\">\n"
                            "    <background "
                            "android:drawable=\"@drawable/ic_launcher_background\" />\n"
                            "    <foreground "
                            "android:drawable=\"@drawable/ic_launcher_foreground\" />\n"
                            "</adaptive-icon>\n";

    WriteTextFile(path, xml);
}

// Check WriteAndroidIcons
void WriteAndroidIcons(const char *output_directory, const ImageSource &source, const char *background_colour,
                       bool circular_mask) {
    if (output_directory == nullptr || *output_directory == '\0')
        InvalidArgumentError("Write Android Icons Error", "Android output directory cannot be empty");

    const std::size_t output_length = std::strlen(output_directory);

    const bool has_separator =
        output_directory[output_length - 1] == '/' || output_directory[output_length - 1] == '\\';

    char resource_root[4096];

    const int written = std::snprintf(resource_root, sizeof(resource_root), "%s%sres", output_directory,
                                      has_separator ? "" : (PATH_SEPARATOR == '\\' ? "\\" : "/"));

    if (written < 0 || static_cast<std::size_t>(written) >= sizeof(resource_root))
        RuntimeError("Write Android Icons Error", "Android resource path is too long");

    CreateDirectoryOrThrow(output_directory);
    CreateDirectoryOrThrow(resource_root);
    WriteAndroidBackgroundXml(resource_root, background_colour);

    for (const AndroidIconDensity &density : androidIconDensities) {
        // Standard launcher icons.
        const std::string mipmap_path = JointPath(resource_root, density.mipmap_directory);

        CreateDirectoryOrThrow(mipmap_path.c_str());
        const std::vector<ImageVariant> standard = CreateImageVariants(source, {density.legacy_size});
        const std::string launcher_path = JointPath(mipmap_path.c_str(), "ic_launcher.png");
        const std::string round_path = JointPath(mipmap_path.c_str(), "ic_launcher_round.png");

        WritePngToDisk(launcher_path.c_str(), standard.front().image);
        if (circular_mask) {
            const std::vector<ImageVariant> round = CreateImageVariants(source, {density.legacy_size}, true);
            WritePngToDisk(round_path.c_str(), round.front().image);
        } else {
            WritePngToDisk(round_path.c_str(), standard.front().image);
        }

        // Density-matched adaptive foreground and background layers.
        const std::string drawable_path = JointPath(resource_root, density.drawable_directory);
        CreateDirectoryOrThrow(drawable_path.c_str());

        const ImageData foreground =
            CreateAndroidAdaptiveForeground(source, density.adaptive_canvas_size, density.adaptive_foreground_size);
        const std::string foreground_path = JointPath(drawable_path.c_str(), "ic_launcher_foreground.png");
        const std::string background_path = JointPath(drawable_path.c_str(), "ic_launcher_background.png");

        WritePngToDisk(foreground_path.c_str(), foreground);
    }

    // Adaptive icon XML is used on Android API 26 and later.
    const std::string adaptive_directory = JointPath(resource_root, "mipmap-anydpi-v26");
    CreateDirectoryOrThrow(adaptive_directory.c_str());
    const std::string adaptive_path = JointPath(adaptive_directory.c_str(), "ic_launcher.xml");
    const std::string adaptive_round_path = JointPath(adaptive_directory.c_str(), "ic_launcher_round.xml");

    WriteAndroidAdaptiveXml(adaptive_path.c_str());
    WriteAndroidAdaptiveXml(adaptive_round_path.c_str());
}
// END:  Functions to handle the writing of Android resource directories

// START:  Functions to handle the writing of iOS application icon set directories
constexpr int IOS_APP_ICON_SIZE = 1024;

// Check ApplyIosBackgroundColour
void ApplyIosBackgroundColour(ImageData &image, const char *background_colour) {
    ValidateImageData(image);

    std::uint8_t background_red;
    std::uint8_t background_green;
    std::uint8_t background_blue;

    ParseResizeBackgroundColour(background_colour, background_red, background_green, background_blue);

    for (int y = 0; y < image.height; ++y) {
        for (int x = 0; x < image.width; ++x) {
            const std::size_t index =
                (static_cast<std::size_t>(y) * static_cast<std::size_t>(image.width) + static_cast<std::size_t>(x)) * 4;

            const unsigned int alpha = image.pixels[index + 3];
            const unsigned int inverse_alpha = 255 - alpha;

            image.pixels[index] =
                static_cast<std::uint8_t>((image.pixels[index] * alpha + background_red * inverse_alpha + 127) / 255);

            image.pixels[index + 1] = static_cast<std::uint8_t>(
                (image.pixels[index + 1] * alpha + background_green * inverse_alpha + 127) / 255);

            image.pixels[index + 2] = static_cast<std::uint8_t>(
                (image.pixels[index + 2] * alpha + background_blue * inverse_alpha + 127) / 255);

            image.pixels[index + 3] = 255;
        }
    }
}

void WriteIosIcons(const char *output_directory, const ImageSource &source, const char *background_colour) {
    if (output_directory == nullptr || *output_directory == '\0')
        InvalidArgumentError("Write Ios Icons Error", "iOS output directory cannot be empty");

    const std::vector<ImageVariant> variants = CreateImageVariants(source, {IOS_APP_ICON_SIZE});

    // Composite a copy so the source image and other platform outputs
    // retain their original transparency.
    ImageData icon = variants.front().image;

    ApplyIosBackgroundColour(icon, background_colour);

    const std::string catalog_path = JointPath(output_directory, "Assets.xcassets");

    const std::string icon_set_path = JointPath(catalog_path.c_str(), "AppIcon.appiconset");

    CreateDirectoryOrThrow(output_directory);
    CreateDirectoryOrThrow(catalog_path.c_str());
    CreateDirectoryOrThrow(icon_set_path.c_str());

    const std::string png_path = JointPath(icon_set_path.c_str(), "AppIcon.png");

    WritePngToDisk(png_path.c_str(), icon);

    const std::string catalog_contents = "{\n"
                                         "  \"info\" : {\n"
                                         "    \"author\" : \"xcode\",\n"
                                         "    \"version\" : 1\n"
                                         "  }\n"
                                         "}\n";

    const std::string icon_contents = "{\n"
                                      "  \"images\" : [\n"
                                      "    {\n"
                                      "      \"filename\" : \"AppIcon.png\",\n"
                                      "      \"idiom\" : \"universal\",\n"
                                      "      \"platform\" : \"ios\",\n"
                                      "      \"size\" : \"1024x1024\"\n"
                                      "    }\n"
                                      "  ],\n"
                                      "  \"info\" : {\n"
                                      "    \"author\" : \"xcode\",\n"
                                      "    \"version\" : 1\n"
                                      "  }\n"
                                      "}\n";

    const std::string catalog_json = JointPath(catalog_path.c_str(), "Contents.json");

    const std::string icon_json = JointPath(icon_set_path.c_str(), "Contents.json");

    WriteTextFile(catalog_json.c_str(), catalog_contents);
    WriteTextFile(icon_json.c_str(), icon_contents);
}
// END:  Functions to handle the writing of iOS application icon set directories

// START:  Image converter base interface
void ConvertImage(IconTarget target, const char *input_path, const char *output_path, bool circular_mask,
                  const char *background_colour) {
    PathValidation(input_path, output_path);

    if (IsDirectory(input_path)) {

        if (IsconsetDirectory(input_path)) {
            if (target != IconTarget::MacOS)
                InvalidArgumentError("Convert Image Error",
                                     "A .iconset directory can only be used with the macos target");

            const std::vector<ImageVariant> variants = LoadIconset(input_path);
            WriteIcns(output_path, variants);

            return;
        } else if (IsWindowsDirectory(input_path)) {
            if (target != IconTarget::Windows)
                InvalidArgumentError("Convert Image Error",
                                     "A .winnt/.windows directory can only be used with the MS Windows target");

            const std::vector<ImageVariant> variants = LoadWindowIconDirectoryImages(input_path);
            WriteIco(output_path, variants);

            return;
        }
    }

    if (!IsRegularFile(input_path))
        InvalidArgumentError("Convert Image Error",
                             std::string("Input is not a regular file or directory: ") + input_path);

    const ImageSource source = LoadImageSource(input_path);
    const std::vector<int> sizes = GetIconTargetIconSizes(target);

    switch (target) {
    case IconTarget::Android:
        WriteAndroidIcons(output_path, source, background_colour, circular_mask);
        return;
    case IconTarget::IOS:
        WriteIosIcons(output_path, source, background_colour);
        return;
    case IconTarget::Windows:
        WriteIco(output_path, source, sizes, circular_mask);
        return;
    case IconTarget::MacOS:
        WriteIcns(output_path, source, sizes, circular_mask);
        return;
    }

    InvalidArgumentError("Convert Image Error", "Invalid icon target");
}

void ConvertImage(const char *input_path, const char *output_path, int width, int height, bool circular_mask,
                  const char *background_colour) {
    if (input_path == nullptr || *input_path == '\0')
        InvalidArgumentError("Convert Image Error", "Input path cannot be empty");

    if (output_path == nullptr || *output_path == '\0')
        InvalidArgumentError("Convert Image Error", "Output path cannot be empty");

    if (width <= 0 || height <= 0) InvalidArgumentError("Convert Image Error", "Output dimensions must be positive");

    if (!IsRegularFile(input_path))
        InvalidArgumentError("Convert Image Error", std::string("Input is not a regular file: ") + input_path);

    const ImageSource source = LoadImageSource(input_path);

    ImageData image;

    if (source.type == ImageSourceType::SVG)
        image = LoadSvgImage(source.filename, width, height);
    else
        image = ResizeImage(source.raster, width, height);

    // Apply the background colour only when one was specified.
    if (background_colour != nullptr && background_colour[0] != '\0')
        ApplyResizeBackgroundColour(image, background_colour);

    if (circular_mask) ApplyCircularMask(image);

    WritePngToDisk(output_path, image);
}
// END:  Image converter base interface

/* ============================================================================
 * Cerberus X Binding
 * ============================================================================ */
// START: Cerberus-X binding
void image2icon(String input, String output, int width, int height, bool circular, String colour) {
    ConvertImage(input.ToCString<char>(), output.ToCString<char>(), width, height, circular, colour.ToCString<char>());
}

#include <iostream>
void image2icon(String host_os, String input, String output, bool circular, String colour) {

    IconTarget icon_target = ParseIconTarget(host_os.ToCString<char>());

    ConvertImage(icon_target, input.ToCString<char>(), output.ToCString<char>(), circular, colour.ToCString<char>());
}
// END:  Cerberus-X binding

#if defined(_MSC_VER) && defined(_WIN32)
	#pragma pop_macro("mkdir")
	#pragma pop_macro("rmdir")
	#pragma pop_macro("remove")
	#pragma pop_macro("rename")
	#pragma pop_macro("stat")
	#pragma pop_macro("_fopen")
	#pragma pop_macro("system")
	#pragma pop_macro("realpath")
	#pragma pop_macro("opendir")
	#pragma pop_macro("readdir")
	#pragma pop_macro("closedir")
	#pragma pop_macro("DIR")
	#pragma pop_macro("dirent")
	#pragma pop_macro("min")
	#pragma pop_macro("max")
#endif