# swift-acoustics

Use this package for what every vibrating thing shares: the `Acoustics` namespace and the air sound travels in. Each vibrating thing is its own package: swift-acoustics-string, swift-acoustics-resonator, swift-acoustics-striker and swift-acoustics-membrane; the contact law they press with is swift-contact.

## Laws

- `Acoustics.Air.room` is air at 20 °C: 1.204 kg/m³ and 343.2 m/s, with the viscosity the string-loss literature uses, 1.8 × 10⁻⁵ Pa·s.
- The air's density, speed of sound and viscosity are quantities of their kinds: a `Density`, a `Velocity` and a `Viscosity`.
