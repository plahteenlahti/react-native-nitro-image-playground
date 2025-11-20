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
            guard self.checkPlatformAvailability() else {
                print("[ImagePlayground] Platform check failed: iOS version < 18.4 or framework not available")
                return false
            }

            #if canImport(ImagePlayground)
            if #available(iOS 18.4, *) {
                do {
                    print("[ImagePlayground] Attempting to initialize ImageCreator...")
                    let manager = self.getManager()
                    _ = try await manager.getCreator()
                    print("[ImagePlayground] ImageCreator initialized successfully")
                    return true
                } catch {
                    print("[ImagePlayground] Failed to initialize ImageCreator: \(error)")
                    print("[ImagePlayground] Error details: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("[ImagePlayground] Error domain: \(nsError.domain), code: \(nsError.code)")
                        print("[ImagePlayground] Error userInfo: \(nsError.userInfo)")
                    }
                    return false
                }
            }
            #endif
            print("[ImagePlayground] Availability check returned false (should not reach here)")
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
        // Convert style to string representation
        let styleDescription = String(describing: style).lowercased()

        // Format: imageplaygroundstyle(id: "animation", _representationinfo: nil)
        // Extract the ID value between quotes
        if let idRange = styleDescription.range(of: "id: \""),
           let endQuoteRange = styleDescription[idRange.upperBound...].range(of: "\"") {
            let id = String(styleDescription[idRange.upperBound..<endQuoteRange.lowerBound])
            return id
        }

        // Fallback: try to extract from simpler formats
        if styleDescription.contains(".") {
            return styleDescription.components(separatedBy: ".").last ?? styleDescription
        }

        return styleDescription
        #else
        return "illustration"
        #endif
    }

    /// Converts a CreatedImage to a base64-encoded data URL.
    /// CreatedImage has a .cgImage property that returns the CGImage directly.
    @available(iOS 18.4, *)
    private func convertCreatedImageToBase64(_ createdImage: Any) throws -> String {
        #if canImport(ImagePlayground)
        // Use reflection to access the cgImage property since CreatedImage is a struct
        let mirror = Mirror(reflecting: createdImage)

        // Look for the "cgImage" property
        for child in mirror.children {
            if child.label == "cgImage" {
                // Verify the value is a CGImage using CFTypeID before casting
                guard CFGetTypeID(child.value as CFTypeRef) == CGImage.typeID else {
                    throw RuntimeError.error(withMessage: "cgImage property is not a CGImage")
                }

                // Use unsafeBitCast since we've verified the type
                let cgImage = unsafeBitCast(child.value as CFTypeRef, to: CGImage.self)
                return try self.convertCGImageToBase64(cgImage)
            }
        }

        throw RuntimeError.error(withMessage: "Failed to find 'cgImage' property in CreatedImage. Properties found: \(mirror.children.compactMap { $0.label }.joined(separator: ", "))")
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
