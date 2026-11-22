extension Acoustics {
    public struct Air: Hashable, Sendable {
        public var density: Double
        public var speed: Double

        public init(density: Double, speed: Double) {
            self.density = density
            self.speed = speed
        }
    }
}

extension Acoustics.Air {
    public static var room: Self { Self(density: 1.204, speed: 343.2) }
}
