using .Plots

@recipe function f(z::Array{Polar{T}}) where {T}
    projection --> :polar
    angle.(z), abs.(z)
end

@recipe function f(z::Array{Spherical{T}}; sphere=true) where {T}
    delete!(plotattributes, :sphere)
    markersize --> 1
    aspect_ratio --> 1
    xlims --> (-1, 1)
    ylims --> (-1, 1)
    zlims --> (-1, 1)

    @series begin
        x = [cos(z.lat) * cos(z.lon) for z in z]
        y = [cos(z.lat) * sin(z.lon) for z in z]
        z = [sin(z.lat) for z in z]
        x, y, z
    end

    function latcurves(n)
        lats = π * (1-n:2:n-1) / (2n + 2)
        ϕ = π * (-200:200) / 200
        [(cos(θ) * cos.(ϕ), cos(θ) * sin.(ϕ), fill(sin(θ), length(ϕ))) for θ in lats]
    end

    function loncurves(n)
        θ = π * (-100:100) / 200
        longs = 2π * (0:n-1) / n
        [(cos.(θ) * cos(ϕ), cos.(θ) * sin(ϕ), sin.(θ)) for ϕ in longs]
    end

    if isa(sphere, Tuple)
        nlat, nlon = sphere
        sphere = true
    elseif isa(sphere, Int)
        nlat = nlon = sphere
        sphere = true
    else
        nlon = 12
        nlat = 7
    end
    if sphere
        for c in latcurves(nlat)
            @series begin
                group := 2
                seriestype := :path3d
                color := :lightgray
                linestyle := :dot
                linealpha := 0.5
                markershape := :none
                linewidth := 0.5
                label := ""
                c[1], c[2], c[3]
            end
        end

        for c in loncurves(nlon)
            @series begin
                group := 2
                seriestype := :path3d
                color := :lightgray
                linealpha := 0.5
                linestyle := :dot
                markershape := :none
                linewidth := 0.5
                label := ""
                c[1], c[2], c[3]
            end
        end
    end

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
    fig = Plots.plot(size=(1000, 1000), aspect_ratio=:equal, label="")
    return zplot!(fig, args...; kw...)
end

function zplot!(
    ax::Plots.Plot,
    x::AbstractMatrix{<:Number},
    y::AbstractMatrix{<:Number},
    z::AbstractMatrix{<:Number};
    coloring=artist()
    )
    s = coloring.(z)
    return Plots.heatmap!(ax, x[:,1], y[1,:], s'; yflip=false)
end
