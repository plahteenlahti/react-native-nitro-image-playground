//
//  HybridNitroImagePlayground.swift
//  react-native-nitro-image-playground
//
//  Created by Perttu Lähteenlahti on 11/20/2025.
//

import Foundation
import UIKit
import NitroModules

#if canImport(ImagePlayground)
import ImagePlayground
#endif

/// A thread-safe wrapper around Apple's ImagePlayground API for React Native.
/// Provides image generation capabilities using AI with various artistic styles.
/// Requires iOS 18.4+ and Image Playground framework availability.
@available(iOS 18.4, *)
actor ImageCreatorManager {
    private var creator: ImageCreator?

    /// Gets or creates the ImageCreator instance
    func getCreator() async throws -> ImageCreator {
        if let existing = creator {
            return existing
        }
        let newCreator = try await ImageCreator()
        creator = newCreator
        return newCreator
    }

    /// Clears the cached ImageCreator instance
    func clearCreator() {
        creator = nil
    }
}

class HybridNitroImagePlayground: HybridNitroImagePlaygroundSpec {
    private var creatorManager: Any?

    // MARK: - Private Helpers

    @available(iOS 18.4, *)
    private func getManager() -> ImageCreatorManager {
        if let manager = creatorManager as? ImageCreatorManager {
            return manager
        }
        let manager = ImageCreatorManager()
        creatorManager = manager
        return manager
    }

    private func checkPlatformAvailability() -> Bool {
        guard #available(iOS 18.4, *) else { return false }
        #if canImport(ImagePlayground)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Availability Check

    func isAvailable() throws -> Promise<Bool> {
        return Promise.async {
            guard self.checkPlatformAvailability() else { return false }

            #if canImport(ImagePlayground)
            if #available(iOS 18.4, *) {
                do {
                    let manager = self.getManager()
                    _ = try await manager.getCreator()
                    return true
                } catch {
                    return false
                }
            }
            #endif
            return false
        }
    }

    // MARK: - Available Styles

    func getAvailableStyles() throws -> Promise<[String]> {
        return Promise.async {
            guard self.checkPlatformAvailability() else { return [] }

            #if canImport(ImagePlayground)
            if #available(iOS 18.4, *) {
                do {
                    let manager = self.getManager()
                    let creator = try await manager.getCreator()
                    let styles = creator.availableStyles
                    return styles.map { self.styleToString($0) }
                } catch {
                    return []
                }
            }
            #endif
            return []
        }
    }

    // MARK: - Image Generation

    func generateImages(
        concepts: [String],
        style: String,
        limit: Double
    ) throws -> Promise<[String]> {
        return Promise.async {
            guard self.checkPlatformAvailability() else {
                throw RuntimeError.error(withMessage: "Image Playground requires iOS 18.4 or later")
            }

            #if canImport(ImagePlayground)
            if #available(iOS 18.4, *) {
                // Validate inputs
                guard !concepts.isEmpty else {
                    throw RuntimeError.error(withMessage: "Concepts array cannot be empty")
                }

                // Validate that concepts are not blank
                let trimmedConcepts = concepts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let emptyIndices = trimmedConcepts.enumerated().compactMap { $0.element.isEmpty ? $0.offset : nil }
                guard emptyIndices.isEmpty else {
                    let indexList = emptyIndices.map { String($0) }.joined(separator: ", ")
                    throw RuntimeError.error(withMessage: "Concepts at indices [\(indexList)] are empty or contain only whitespace")
                }

                let limitInt = Int(limit)
                guard limitInt >= 1 && limitInt <= 4 else {
                    throw RuntimeError.error(withMessage: "Limit must be between 1 and 4, got \(limitInt)")
                }

                // Get ImageCreator
                let manager = self.getManager()
                let creator: ImageCreator
                do {
                    creator = try await manager.getCreator()
                } catch {
                    throw RuntimeError.error(withMessage: "Failed to initialize ImageCreator: \(error.localizedDescription)")
                }

                // Validate style against available styles
                let availableStyleStrings = creator.availableStyles.map { self.styleToString($0).lowercased() }
                let normalizedStyle = style.lowercased()

                guard availableStyleStrings.contains(normalizedStyle) else {
                    let availableList = availableStyleStrings.joined(separator: ", ")
                    throw RuntimeError.error(withMessage: "Style '\(style)' not available. Available styles: \(availableList)")
                }

                // Get the matching style object
                guard let imageStyle = creator.availableStyles.first(where: {
                    self.styleToString($0).lowercased() == normalizedStyle
                }) else {
                    throw RuntimeError.error(withMessage: "Failed to match style '\(style)' with available styles")
                }

                // Convert concepts to ImagePlaygroundConcept
                let imageConcepts = trimmedConcepts.map { ImagePlaygroundConcept.text($0) }

                // Generate images
                var results: [String] = []
                do {
                    for try await createdImage in creator.images(
                        for: imageConcepts,
                        style: imageStyle,
                        limit: limitInt
                    ) {
                        let base64 = try self.convertCreatedImageToBase64(createdImage)
                        results.append(base64)
                    }
                } catch let error as RuntimeError {
                    // Re-throw RuntimeErrors directly
                    throw error
                } catch {
                    throw RuntimeError.error(withMessage: "Failed to generate images: \(error.localizedDescription)")
                }

                return results
            }
            #endif
            throw RuntimeError.error(withMessage: "ImagePlayground framework is not available")
        }
    }

    // MARK: - Helper Methods

    @available(iOS 18.4, *)
    private func styleToString(_ style: Any) -> String {
        #if canImport(ImagePlayground)
        // Convert style enum to string representation
        let styleDescription = String(describing: style)
        // The description might be something like "animation" or include more info
        // Extract just the style name
        return styleDescription.lowercased().components(separatedBy: ".").last ?? styleDescription.lowercased()
        #else
        return "illustration"
        #endif
    }

    /// Converts a CreatedImage to a base64-encoded data URL.
    /// CreatedImage has an .image property that returns the CGImage directly.
    @available(iOS 18.4, *)
    private func convertCreatedImageToBase64(_ createdImage: Any) throws -> String {
        #if canImport(ImagePlayground)
        // CreatedImage has an .image property according to Apple's documentation
        // Use KVC to access it safely
        guard let imageWithProperty = createdImage as? NSObject else {
            throw RuntimeError.error(withMessage: "CreatedImage does not conform to NSObject")
        }

        do {
            guard let imageValue = imageWithProperty.value(forKey: "image") else {
                throw RuntimeError.error(withMessage: "CreatedImage does not have an 'image' property")
            }

            // Verify it's a CGImage and cast it
            guard CFGetTypeID(imageValue as CFTypeRef) == CGImage.typeID else {
                throw RuntimeError.error(withMessage: "Image property is not a CGImage (type ID: \(CFGetTypeID(imageValue as CFTypeRef)))")
            }

            let cgImage = unsafeBitCast(imageValue, to: CGImage.self)
            return try self.convertCGImageToBase64(cgImage)
        } catch let error as RuntimeError {
            throw error
        } catch {
            throw RuntimeError.error(withMessage: "Failed to access image property: \(error.localizedDescription)")
        }
        #else
        throw RuntimeError.error(withMessage: "ImagePlayground framework is not available")
        #endif
    }

    private func convertCGImageToBase64(_ cgImage: CGImage) throws -> String {
        let uiImage = UIImage(cgImage: cgImage)
        guard let pngData = uiImage.pngData() else {
            throw RuntimeError.error(withMessage: "Failed to convert image to PNG data")
        }
        let base64 = pngData.base64EncodedString()
        return "data:image/png;base64,\(base64)"
    }
}
