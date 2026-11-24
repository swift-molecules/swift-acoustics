extension Acoustics {
    public struct Air: Hashable, Sendable {
        /// Density, in kg/m³.
        public var density: Double
        /// The speed of sound, in m/s.
        public var speed: Double
        /// Dynamic viscosity, in Pa·s: what holds back a string moving through the air.
        public var viscosity: Double

        public init(density: Double, speed: Double, viscosity: Double) {
            self.density = density
            self.speed = speed
            self.viscosity = viscosity
        }
    }
}

extension Acoustics.Air {
    /// Air at 20 °C and sea-level pressure. Its viscosity, 1.8 × 10⁻⁵ Pa·s, is the value the string-loss literature
    /// uses (Paté, Le Carrou and Fabre 2014, p. 3049; Issanchou et al. 2017, §2.3.1).
    public static var room: Self { Self(density: 1.204, speed: 343.2, viscosity: 1.8e-5) }
}
