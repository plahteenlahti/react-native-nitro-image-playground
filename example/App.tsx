import React, { useState, useEffect, useCallback } from 'react'
import {
  Text,
  View,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Image,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native'
import { NitroImagePlayground } from 'react-native-nitro-image-playground'

function App(): React.JSX.Element {
  const [isAvailable, setIsAvailable] = useState<boolean>(false)
  const [availableStyles, setAvailableStyles] = useState<string[]>([])
  const [concept, setConcept] = useState<string>('A cute robot playing with a cat')
  const [selectedStyle, setSelectedStyle] = useState<string>('')
  const [limit, setLimit] = useState<number>(2)
  const [isLoading, setIsLoading] = useState<boolean>(false)
  const [generatedImages, setGeneratedImages] = useState<string[]>([])
  const [checking, setChecking] = useState<boolean>(true)

  const checkAvailability = useCallback(async () => {
    try {
      setChecking(true)
      const available = await NitroImagePlayground.isAvailable()
      setIsAvailable(available)

      if (available) {
        const styles = await NitroImagePlayground.getAvailableStyles()
        setAvailableStyles(styles)
        if (styles.length > 0) {
          setSelectedStyle(styles[0])
        }
      }
    } catch (error) {
      console.error('Error checking availability:', error)
      Alert.alert('Error', 'Failed to check Image Playground availability')
    } finally {
      setChecking(false)
    }
  }, [])

  useEffect(() => {
    checkAvailability()
  }, [checkAvailability])

  const handleGenerate = useCallback(async () => {
    if (!concept.trim()) {
      Alert.alert('Error', 'Please enter a concept description')
      return
    }

    if (!selectedStyle) {
      Alert.alert('Error', 'Please select a style')
      return
    }

    try {
      setIsLoading(true)
      setGeneratedImages([])

      const images = await NitroImagePlayground.generateImages(
        [concept],
        selectedStyle,
        limit
      )

      setGeneratedImages(images)
    } catch (error) {
      console.error('Error generating images:', error)
      const message = error instanceof Error ? error.message : 'Failed to generate images. Please try again.'
      Alert.alert('Error', message)
    } finally {
      setIsLoading(false)
    }
  }, [concept, selectedStyle, limit])

  if (checking) {
    return (
      <View style={styles.container}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.checkingText}>Checking Image Playground availability...</Text>
      </View>
    )
  }

  if (!isAvailable) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorTitle}>⚠️ Not Available</Text>
        <Text style={styles.errorText}>
          Image Playground is not supported on this device.
        </Text>
        <Text style={styles.errorSubtext}>
          Image Playground requires a physical device with Apple Intelligence support (iPhone 15 Pro or later, iPad with M1+).{'\n\n'}
          Simulators are not supported.
        </Text>
      </View>
    )
  }

  console.log('availableStyles', availableStyles)

  return (
    <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
      <View style={styles.header}>
        <Text style={styles.title}>🎨 Image Playground</Text>
        <Text style={styles.subtitle}>Generate images with AI</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>Concept Description</Text>
        <TextInput
          style={styles.input}
          value={concept}
          onChangeText={setConcept}
          placeholder="Describe what you want to see..."
          placeholderTextColor="#999"
          multiline
        />
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>Style</Text>
        <View style={styles.styleContainer}>
          {availableStyles.map((style) => (
            <TouchableOpacity
              key={style}
              style={[
                styles.styleButton,
                selectedStyle === style && styles.styleButtonActive,
              ]}
              onPress={() => setSelectedStyle(style)}
            >
              <Text
                style={[
                  styles.styleButtonText,
                  selectedStyle === style && styles.styleButtonTextActive,
                ]}
              >
                {style.charAt(0).toUpperCase() + style.slice(1)}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>Number of Images (1-4)</Text>
        <View style={styles.limitContainer}>
          {([1, 2, 3, 4] as const).map((num) => (
            <TouchableOpacity
              key={num}
              style={[
                styles.limitButton,
                limit === num && styles.limitButtonActive,
              ]}
              onPress={() => setLimit(num)}
            >
              <Text
                style={[
                  styles.limitButtonText,
                  limit === num && styles.limitButtonTextActive,
                ]}
              >
                {num}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <TouchableOpacity
        style={[styles.generateButton, isLoading && styles.generateButtonDisabled]}
        onPress={handleGenerate}
        disabled={isLoading}
      >
        {isLoading ? (
          <ActivityIndicator color="#FFF" />
        ) : (
          <Text style={styles.generateButtonText}>Generate Images</Text>
        )}
      </TouchableOpacity>

      {isLoading && (
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Generating images...</Text>
          <Text style={styles.loadingSubtext}>This may take a few moments</Text>
        </View>
      )}

      {!isLoading && generatedImages.length > 0 && (
        <View style={styles.resultsSection}>
          <Text style={styles.resultsTitle}>Generated Images</Text>
          {generatedImages.map((imageUri, index) => (
            <View key={index} style={styles.imageContainer}>
              <Image
                source={{ uri: imageUri }}
                style={styles.generatedImage}
                resizeMode="contain"
              />
            </View>
          ))}
        </View>
      )}
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
    backgroundColor: '#F5F5F7',
  },
  scrollContent: {
    padding: 20,
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5F5F7',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginTop: 40,
    marginBottom: 30,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  checkingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  errorTitle: {
    fontSize: 48,
    marginBottom: 16,
  },
  errorText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000',
    textAlign: 'center',
    marginBottom: 8,
  },
  errorSubtext: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  section: {
    marginBottom: 24,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: '#000',
    minHeight: 100,
    textAlignVertical: 'top',
    borderWidth: 1,
    borderColor: '#E5E5EA',
  },
  styleContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  styleButton: {
    flex: 1,
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#E5E5EA',
  },
  styleButtonActive: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  styleButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000',
  },
  styleButtonTextActive: {
    color: '#FFF',
  },
  limitContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  limitButton: {
    flex: 1,
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#E5E5EA',
  },
  limitButtonActive: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  limitButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
  },
  limitButtonTextActive: {
    color: '#FFF',
  },
  generateButton: {
    backgroundColor: '#007AFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  generateButtonDisabled: {
    backgroundColor: '#A0A0A0',
  },
  generateButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFF',
  },
  loadingContainer: {
    alignItems: 'center',
    marginTop: 24,
    padding: 20,
    backgroundColor: '#FFF',
    borderRadius: 12,
  },
  loadingText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
    marginBottom: 4,
  },
  loadingSubtext: {
    fontSize: 14,
    color: '#666',
  },
  resultsSection: {
    marginTop: 32,
    marginBottom: 40,
  },
  resultsTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000',
    marginBottom: 16,
  },
  imageContainer: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E5E5EA',
  },
  generatedImage: {
    width: '100%',
    height: 300,
    borderRadius: 8,
  },
})

export default App