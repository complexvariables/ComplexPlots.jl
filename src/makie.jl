using .Makie
const Target = Union{Makie.GridPosition, Makie.Axis, Makie.FigureAxisPlot}
const GB = Makie.GeometryBasics
export complex_theme
using ColorSchemes

# Allow plot of any complex vector
z_to_point(z::Complex{T} where T) = Makie.Point2f(reim(z)...)
Makie.convert_arguments(::PointBased, z::AbstractVector{<:Complex}) = (z_to_point.(z), )

#####
##### Sphere plots
#####

"""
    sphereplot(z; kw...)
Plot a vector of complex numbers on the Riemann sphere. Keyword arguments are:
* `sphere`: `false` to disable the sphere, or a tuple `(nlat, nlon)` to set the number of latitude and longitude lines.
* `markersize`: size of the markers
* `line`: `true` to connect the markers with lines
"""
function sphereplot(z::AbstractVector{<:Number}; kw...)
    fig = Makie.Figure()
    ax = Makie.Axis3(fig[1,1], aspect=(1, 1, 1), limits=((-1,1), (-1,1), (-1,1)))
    sphereplot!(ax, z; kw...)
    return fig
end

function sphereplot!(
    ax::Union{Makie.GridPosition,Makie.Axis3},
    z::AbstractVector{<:Number};
    sphere=(12,7), markersize=20, line=false
    )
    if !isnothing(sphere) && (sphere!=false)
        θ = range(0, 2π, 400)
        c, s = cos.(θ), sin.(θ)
        for φ in range(0, π, sphere[1]+1)[1:end-1]
            lines!(ax, cos(φ)*c, sin(φ)*c, s, color = :lightgray)
        end
        lines!(ax, c, 0*c, s, color = :darkgray)
        φ = range(0, 2π, 400)
        c, s = cos.(φ), sin.(φ)
        for θ in range(-π/2, π/2, sphere[2]+2)[2:end-1]
            lines!(ax, c*cos(θ), s*cos(θ), ones(size(c))*sin(θ), color = :lightgray)
        end
        lines!(ax, c, s, 0*s, color = :darkgray)
    end
    converter = z -> Point3f(S2coord(Spherical(z))...)
    points = converter.(z)
    if line
        Makie.scatterlines!(ax, points; markersize)
    else
        Makie.scatter!(ax, points; markersize)
    end
    Makie.hidedecorations!(ax)
    Makie.hidespines!(ax)
    return ax
end

#####
##### Function visualization
#####

function zplot(args...; kw...)
    fig = Makie.Figure(size=(1000, 1000))
    ax = Makie.Axis(fig[1,1], autolimitaspect=1)
    return Makie.FigureAxisPlot(fig, ax, zplot!(ax, args...; kw...))
end

function zplot!(
    ax::Target,
    x::AbstractMatrix{<:Number},
    y::AbstractMatrix{<:Number},
    z::AbstractMatrix{<:Number};
    coloring=artist()
    )
    s = coloring.(z)
    return Makie.surface!(ax, x, y, zero(x); color=s, shading=NoShading)
end

complex_theme = Makie.Theme(
    Axis = (autolimitaspect = 1,),
    Series = (linewidth = 4, color = ColorSchemes.seaborn_colorblind[1:10]),
    Lines = (color = ColorSchemes.seaborn_colorblind[1], linewidth=4),
    patchcolor = ColorSchemes.seaborn_colorblind[1],  # for regions
    Poly = (strokecolor=:black, strokewidth=4),       # also for regions
    )

#####
##### Curves and paths
#####

# Convert a pathlike object to a vector of points
Makie.plottype(::AbstractCurveOrPath) = Lines
Makie.plottype(::AbstractVector{<:AbstractCurveOrPath}) = Series
curve_to_points(c::AbstractCurveOrPath) = z_to_point.(complex(plotdata(c)))
Makie.convert_arguments(::PointBased, c::AbstractCurveOrPath) = (curve_to_points(c), )

# Plot a compound boundary (e.g., from a generic ConnectedRegion)
Compound = Tuple{Union{Nothing,AbstractJordan}, Vector{<:AbstractJordan}}
# plottype(::Compound) = Series
function Makie.plot!(plt::Tuple{Compound})
    outer, inner = plt[1][]
    if !isnothing(outer)
        Makie.plot!(plt, outer)
    end
    Makie.plot!(plt, inner)
    return plt
end

#####
##### Regions
#####

# Convert a generic region to a Makie Polygon
Makie.plottype(::AbstractRegion) = Poly
function Makie.convert_arguments(PT::Type{<:Poly}, R::ConnectedRegion{N}) where N
    outer = curve_to_points(outerboundary(R))
    inner = curve_to_points.(innerboundary(R))
    return convert_arguments(PT, GB.Polygon(outer, inner))
end

# Conversions for particular cases
function Makie.convert_arguments(PT::Type{<:Poly}, R::InteriorSimplyConnectedRegion)
    ∂R = curve_to_points(boundary(R))
    return convert_arguments(PT, GB.Polygon(∂R))
end

function Makie.convert_arguments(PT::Type{<:Poly}, R::ExteriorSimplyConnectedRegion)
    return convert_arguments(PT, truncate(R))
end

function Makie.convert_arguments(PT::Type{<:Poly}, R::ExteriorRegion{N}) where N
    return convert_arguments(PT, truncate(R))
end

function Base.truncate(R::ExteriorSimplyConnectedRegion)
    ∂R = boundary(R)
    C = ComplexRegions.enclosing_circle(ClosedPath(∂R), 8)
    return between(reverse(C), ∂R)
end

function Base.truncate(R::ExteriorRegion)
    ∂R = innerboundary(R)
    C = ComplexRegions.enclosing_circle(ClosedPath.(∂R), 8)
    return ConnectedRegion(C, ∂R)
end

Makie.convert_arguments(PT::Type{<:Poly}, A::Annulus) = convert_arguments(PT, ConnectedRegion{2}(A.outer, [A.inner]))
