import { type HybridObject } from 'react-native-nitro-modules'

/**
 * Valid image generation styles for Image Playground
 */
export type ImagePlaygroundStyle = 'animation' | 'illustration' | 'sketch'

export interface NitroImagePlayground extends HybridObject<{ ios: 'swift' }> {
  /**
   * Check if Image Playground is available on this device.
   * Requires iOS 18.4 or later.
   */
  isAvailable(): Promise<boolean>

  /**
   * Get list of available styles on this device.
   * Returns array of style names: 'animation', 'illustration', 'sketch'
   */
  getAvailableStyles(): Promise<string[]>

  /**
   * Generate images from text concepts using Image Playground.
   *
   * @param concepts - Array of text descriptions to generate images from.
   *                   All concepts will be combined for image generation.
   * @param style - Visual style: 'animation', 'illustration', or 'sketch'
   * @param limit - Maximum number of images to generate (1-4)
   * @returns Array of base64-encoded image data URLs (data:image/png;base64,...)
   * @throws InvalidArgument if concepts array is empty, contains blank strings,
   *                         limit is out of range, or style is invalid
   * @throws UnsupportedPlatform if iOS version is below 18.4
   * @throws InitializationFailed if ImageCreator cannot be initialized
   * @throws GenerationFailed if image generation fails
   */
  generateImages(
    concepts: string[],
    style: string,
    limit: number
  ): Promise<string[]>
}