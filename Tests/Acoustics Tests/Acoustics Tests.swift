import Acoustics
import Testing

enum `Acoustics Tests` {}

extension `Acoustics Tests` {
    @Suite struct Air {}
}

extension `Acoustics Tests`.Air {
    @Test func `Air in a room is 1.204 kilograms a cubic metre and carries sound at 343.2 metres a second`() {
        #expect(Acoustics.Air.room.density == Density.amount(1.204))
        #expect(Acoustics.Air.room.speed == Velocity.amount(343.2))
    }

    /// Paté, Le Carrou and Fabre (2014, p. 3049) and Issanchou et al. (2017, §2.3.1): "ηair = 1.8 × 10⁻⁵ kg m⁻¹ s⁻¹".
    @Test func `Air in a room has the viscosity the string-loss literature uses, 1.8 × 10⁻⁵ pascal seconds`() {
        #expect(Acoustics.Air.room.viscosity == Viscosity.amount(1.8e-5))
    }
}
