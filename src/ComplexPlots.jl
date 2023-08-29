module ComplexPlots
using ComplexValues, ComplexRegions, ColorSchemes, Colors, LinearAlgebra

const AbstractCurve = ComplexRegions.AbstractCurve
const AbstractPath = ComplexRegions.AbstractPath
const AbstractCurveOrPath = Union{AbstractCurve, AbstractPath}
const AbstractJordan = ComplexRegions.AbstractJordan
const AbstractCircularPolygon = ComplexRegions.AbstractCircularPolygon
const AbstractRegion = ComplexRegions.AbstractRegion
const ExteriorRegion = ComplexRegions.ExteriorRegion
const ExteriorSimplyConnectedRegion = ComplexRegions.ExteriorSimplyConnectedRegion
const InteriorSimplyConnectedRegion = ComplexRegions.InteriorSimplyConnectedRegion

export sphereplot, sphereplot!, zplot, zplot!, artist
include("common.jl")

using Requires
function __init__()
	@require Makie="ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a" include("makie.jl")
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("plots.jl")
end

end
