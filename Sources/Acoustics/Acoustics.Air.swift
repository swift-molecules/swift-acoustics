extension Acoustics {
    public struct Air: Hashable, Sendable {
        public var density: Density.Value<Double>
        /// The speed of sound.
        public var speed: Velocity.Value<Double>
        /// Dynamic viscosity: what holds back a string moving through the air.
        public var viscosity: Viscosity.Value<Double>

        public init(
            density: Density.Value<Double>,
            speed: Velocity.Value<Double>,
            viscosity: Viscosity.Value<Double>
        ) {
            self.density = density
            self.speed = speed
            self.viscosity = viscosity
        }
    }
}

extension Acoustics.Air {
    /// Air at 20 °C and sea-level pressure. Its viscosity, 1.8 × 10⁻⁵ Pa·s, is the value the string-loss literature
    /// uses (Paté, Le Carrou and Fabre 2014, p. 3049; Issanchou et al. 2017, §2.3.1).
    public static var room: Self {
        Self(density: Density.amount(1.204), speed: Velocity.amount(343.2), viscosity: Viscosity.amount(1.8e-5))
    }
}
