"""
    artist(base=exp(1), colormap=Makie.ColorSchemes.cyclic_mygbm_30_95_c78_n256)
`artist(b)` returns a function that maps a complex number `z` to a color. The hue is
determined by the angle of `z`. The value (lightness) is determined by the fractional
part of ``\\log_b |z|``. You can optionally specify any colormap, though a cyclic one is
strongly recommended.
"""
function artist(base=exp(1), colormap=ColorSchemes.cyclic_mygbm_30_95_c78_n256)
    return function(z)
        if isnan(z)
            return RGBA{Float32}(0, 0, 0, 0)
        end
        s1 = mod(log(base, abs(z)), 1)
        s2 = mod2pi(angle(z)) / 2π
        col = convert(Colors.HSV, get(colormap, s2, (0, 1)))
        x = 0.6 + 0.4s1
        return Colors.HSVA(col.h, col.s, x*col.v, 1)
    end
end

@doc """
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
zplot(z -> (z^3 - 1) / sin(2im - z))
zplot(tanh)
zplot(tanh, coloring=artist(1.5))  # to see more magnitude contours
```
"""
zplot

function zplot!(
    ax,
    f::Function,
    xlims=(-4, 4),
    ylims=(-4, 4),
    n=800;
    kw...
    )
    x = [x for x in range(xlims..., 800), y in range(ylims..., n)]
    y = [y for x in range(xlims..., 800), y in range(ylims..., n)]
    return zplot!(ax, f, complex.(x, y); kw...)
end

function zplot!(
    ax,
    f::Function,
    z::AbstractMatrix{<:Complex};
    kw...
    )
    w = similar(z)
    Threads.@threads for i in eachindex(z)
        w[i] = f(z[i])
    end
    return zplot!(ax, real(z), imag(z), w; kw...)
end

function zplot!(ax, z::AbstractMatrix{<:Number}; kw...)
    return zplot!(ax, real(z), imag(z), z; kw...)
end

"""
	plotdata(C::AbstractCurve,n=501)

Compute `n` points along the curve `C` suitable to make a plot of it.
"""
plotdata(C::ComplexRegions.AbstractCurve) = adaptpoints(t -> point(C,t), t -> unittangent(C,t), 0, 1)

#In the plane (but not on the sphere), two points are enough to draw a line, and we want to avoid infinity.
plotdata(L::Line{T}) where T<:Union{Complex,Polar} = point(L,[0.1,0.9])

plotdata(P::ComplexRegions.AbstractPath) = vcat(plotdata.(P)...)

# in the plane, use two (finite) points for plotting
plotdata(R::Ray{T}) where T<:Union{Complex,Polar} = R.reverse ? [R(0.3), R.base] : [R.base, R(0.7)]

plotdata(S::Segment{T}) where T<:Union{Complex,Polar} = [S.za, S.zb]

# Select points adaptively to make a smooth-appearing curve.
function adaptpoints(point, utangent, a, b; depth=6, curvemax=0.05)
    function refine(tl, tr, zl, zr, τl, τr, maxdz, d=depth)
        dzkap = dist(τr, τl)  # approximately, the stepsize over radius of curvature
        tm = (tl + tr) / 2
        zm = point(tm)
        τm = utangent(tm)
        if d > 0 && (dzkap > curvemax || dist(zr, zl) > maxdz)
            zl = refine(tl, tm, zl, zm, τl, τm, maxdz, d - 1)
            zr = refine(tm, tr, zm, zr, τm, τr, maxdz, d - 1)
            return [zl; zm; zr]
        else
            return zm
        end
    end

    d = (b - a) / 4
    tt = d * [0, 0.196, 0.41, 0.592, 0.806]   # avoid common symmetry points
    t = [a .+ tt; a + d .+ tt; a + 2d .+ tt; a + 3d .+ tt; b]
    z = point.(t)
    τ = utangent.(t)

    # on the Riemann sphere, use distance in R^3
    if z[1] isa Spherical
        dist = (u, v) -> norm(S2coord(u) - S2coord(v))
    else
        dist = (u, v) -> abs(u - v)
    end
    m = length(t)
    scale = maximum(dist(z[i], z[j]) for i = 2:m-1, j = 2:m-1 if j > i)
    zfinal = z[[1]]
    for j = 1:length(t)-1
        znew = refine(t[j], t[j+1], z[j], z[j+1], τ[j], τ[j+1], scale / 25)
        append!(zfinal, znew)
        push!(zfinal, z[j+1])
    end
    return zfinal
end

# indices of the closest pair of points from two lists
function argclosest(z1, z2)
    i1 = [argmin(abs.(z1 .- z)) for z in z2]
    i2 = argmin(abs.(z2 .- z1[i1]))
    return i1[i2], i2
end
