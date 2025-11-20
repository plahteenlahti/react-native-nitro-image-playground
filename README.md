# react-native-nitro-image-playground

A React Native module that provides access to Apple's Image Playground API for generating AI images on iOS 18.4+. Built with [Nitro Modules](https://nitro.margelo.com/) for high-performance native integration.

[![Version](https://img.shields.io/npm/v/react-native-nitro-image-playground.svg)](https://www.npmjs.com/package/react-native-nitro-image-playground)
[![Downloads](https://img.shields.io/npm/dm/react-native-nitro-image-playground.svg)](https://www.npmjs.com/package/react-native-nitro-image-playground)
[![License](https://img.shields.io/npm/l/react-native-nitro-image-playground.svg)](https://github.com/patrickkabwe/react-native-nitro-image-playground/LICENSE)

## Features

- Generate AI images using Apple's Image Playground API
- Support for multiple styles: Animation, Illustration, and Sketch
- Generate up to 4 images per request
- Text-based concept descriptions
- Device availability checking
- Full TypeScript support

## Requirements

- React Native v0.76.0 or higher
- Node 18.0.0 or higher
- iOS 18.4 or higher (for Image Playground API)
- react-native-nitro-modules

> [!IMPORTANT]
> Image Playground requires iOS 18.4 or later. The module will gracefully handle older iOS versions by returning `false` from the `isAvailable()` method.

## Installation

```bash
npm install react-native-nitro-image-playground react-native-nitro-modules
# or
yarn add react-native-nitro-image-playground react-native-nitro-modules
# or
bun add react-native-nitro-image-playground react-native-nitro-modules
```

Then run pod install:

```bash
cd ios && pod install
```

## Usage

### Check Availability

First, check if Image Playground is available on the device:

```typescript
import { NitroImagePlayground } from 'react-native-nitro-image-playground'

const isAvailable = await NitroImagePlayground.isAvailable()

if (isAvailable) {
  // Image Playground is supported
} else {
  // Show fallback UI or message
}
```

### Get Available Styles

Check which styles are supported on the device:

```typescript
const styles = await NitroImagePlayground.getAvailableStyles()
// Returns: ['animation', 'illustration', 'sketch']
```

### Generate Images

Generate images from text descriptions:

```typescript
try {
  const images = await NitroImagePlayground.generateImages(
    ['A cute robot playing with a cat'], // concepts
    'illustration', // style: 'animation' | 'illustration' | 'sketch'
    2 // limit: 1-4 images
  )

  // images is an array of base64-encoded data URLs
  // ['data:image/png;base64,...', 'data:image/png;base64,...']

  // Use with React Native Image component
  images.forEach((imageUri) => {
    console.log('Generated image:', imageUri)
  })
} catch (error) {
  console.error('Failed to generate images:', error)
}
```

### Complete Example

```typescript
import React, { useState, useEffect } from 'react'
import { View, Image, Button, Text } from 'react-native'
import { NitroImagePlayground } from 'react-native-nitro-image-playground'

function ImagePlaygroundExample() {
  const [isAvailable, setIsAvailable] = useState(false)
  const [images, setImages] = useState<string[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    checkAvailability()
  }, [])

  const checkAvailability = async () => {
    const available = await NitroImagePlayground.isAvailable()
    setIsAvailable(available)
  }

  const generateImages = async () => {
    try {
      setLoading(true)
      const generatedImages = await NitroImagePlayground.generateImages(
        ['A robot painting a sunset'],
        'illustration',
        2
      )
      setImages(generatedImages)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  if (!isAvailable) {
    return <Text>Image Playground requires iOS 18.4 or later</Text>
  }

  return (
    <View>
      <Button
        title={loading ? 'Generating...' : 'Generate Images'}
        onPress={generateImages}
        disabled={loading}
      />
      {images.map((uri, index) => (
        <Image
          key={index}
          source={{ uri }}
          style={{ width: 300, height: 300 }}
        />
      ))}
    </View>
  )
}
```

## API Reference

### `isAvailable(): Promise<boolean>`

Check if Image Playground is available on the current device.

**Returns:** `Promise<boolean>` - `true` if iOS 18.4+ and Image Playground is supported

### `getAvailableStyles(): Promise<string[]>`

Get the list of available image styles supported on the device.

**Returns:** `Promise<string[]>` - Array of style names: `['animation', 'illustration', 'sketch']`

### `generateImages(concepts: string[], style: string, limit: number): Promise<string[]>`

Generate images based on text concepts.

**Parameters:**
- `concepts: string[]` - Array of text descriptions. All concepts will be combined for image generation.
- `style: string` - Visual style: `'animation'`, `'illustration'`, or `'sketch'`
- `limit: number` - Number of images to generate (1-4)

**Returns:** `Promise<string[]>` - Array of base64-encoded image data URLs

**Throws:**
- `UnsupportedPlatform` - iOS version is below 18.4
- `InitializationFailed` - Failed to initialize ImageCreator
- `InvalidArgument` - Empty concepts array, contains blank strings, limit is out of range, or invalid style
- `GenerationFailed` - Image generation failed
- `ConversionFailed` - Failed to convert generated image to base64

## Performance Considerations

- Image generation can take several seconds per image
- Images are returned as base64-encoded PNG data URLs
- Each generated image can be several MB in size
- Consider showing loading indicators during generation
- The API generates images progressively (you'll receive them as they complete)

## Limitations

- iOS only (iOS 18.4+)
- Currently supports text concepts only (image and drawing concepts could be added)
- Maximum 4 images per request
- Base64 encoding adds approximately 33% overhead to image size
- Requires device with Neural Engine support
- Thread-safe but sequential: concurrent generation requests will be queued

## Troubleshooting

### Image Playground shows as "not available"

If `isAvailable()` returns `false`, check the Xcode console for diagnostic messages starting with `[ImagePlayground]`.

#### Common Error: "Image Playground is not supported on this device"

**Error Code**: `ImageCreatorError` domain, code 0

**Cause**: You're running on a simulator or unsupported device.

**Solution**:
- **Use a physical device** - Image Playground does not work on simulators
- Ensure device has Apple Intelligence support:
  - iPhone 15 Pro or later
  - iPad with M1 chip or later
  - Mac with Apple Silicon (for Mac Catalyst apps)

#### Common Error: "accessNotGrantedUseCases is unknown"

This is a system log that appears before the actual error. Check the next log line for the real error message.

### Other Issues

1. **Apple Intelligence Not Enabled**:
   - Go to Settings > Apple Intelligence & Siri
   - Enable Apple Intelligence
   - Download required models if prompted

2. **Insufficient Storage**:
   - Image Playground requires several GB for AI models
   - Check Settings > General > [Device] Storage

3. **Regional Restrictions**:
   - Apple Intelligence may not be available in all regions
   - Check Apple's documentation for supported regions

### Debug Logs

The module outputs detailed diagnostic information to help troubleshoot:

```
[ImagePlayground] Platform check failed: iOS version < 18.4 or framework not available
[ImagePlayground] Attempting to initialize ImageCreator...
[ImagePlayground] Failed to initialize ImageCreator: notSupported
[ImagePlayground] Error details: Image Playground is not supported on this device.
[ImagePlayground] Error domain: ImageCreatorError, code: 0
```

### Testing

To properly test Image Playground:
1. **Must use a physical device** running iOS 18.4+ (iOS 26+)
2. Device must support Apple Intelligence
3. Check Xcode console for `[ImagePlayground]` diagnostic messages
4. Verify `isAvailable()` returns `true` before attempting generation

## Development

See the [example](./example) folder for a complete working app demonstrating all features.

## Credits

- Built with [Nitro Modules](https://nitro.margelo.com/)
- Bootstrapped with [create-nitro-module](https://github.com/patrickkabwe/create-nitro-module)

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

MIT
