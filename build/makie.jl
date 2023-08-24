using .Makie
const Target = Union{Makie.GridPosition, Makie.Axis, Makie.FigureAxisPlot}

# Allow plot of any complex vector
z_to_point(z::Complex{T} where T) = Makie.Point2f(reim(z)...)
Makie.convert_arguments(::PointBased, z::AbstractVector{<:Complex}) = (z_to_point.(z), )

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

"""
    zplot(f, z; coloring=artist())
    zplot(f, xlims=[-4, 4], ylims=[-4, 4], n=800; coloring=artist())
Plot a complex-valued function `f` evaluated over the points in matrix `z`, or on an
`n`×`n` grid over `xlims`×`ylims` in the complex plane. The method for coloring values
is given by the keyword argument `coloring`.

    zplot(z; coloring=artist())
Plot a matrix of complex values coloring according to the function given by the keyword
argument `coloring`. It is presumed that `z` results from evaluation on a grid in the
complex plane.

# Examples
```julia
using CairoMakie
zplot(z -> (z^3 - 1) / sin(2im - z))
zplot(tanh)
zplot(tanh, coloring=artist(1.5))  # to see more magnitude contours
```
"""
function zplot(args...; kw...)
    fig = Makie.Figure(resolution=(1000, 1000))
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
    return Makie.surface!(ax, x, y, zero(x); color=s, shading=false)
end
