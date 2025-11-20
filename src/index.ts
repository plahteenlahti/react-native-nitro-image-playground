import { NitroModules } from 'react-native-nitro-modules'
import type { NitroImagePlayground as NitroImagePlaygroundSpec } from './specs/nitro-image-playground.nitro'

export const NitroImagePlayground =
  NitroModules.createHybridObject<NitroImagePlaygroundSpec>('NitroImagePlayground')