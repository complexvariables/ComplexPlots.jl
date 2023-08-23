"""
    artist(base=exp(1), colormap=Makie.ColorSchemes.cyclic_mygbm_30_95_c78_n256)
`artist(b)` returns a function that maps a complex number `z` to a color. The hue is
determined by the angle of `z`. The value (lightness) is determined by the fractional
part of ``\\log_b |z|``. You can optionally specify any colormap, though a cyclic one is
strongly recommended.
"""
function artist(base=exp(1), colormap=ColorSchemes.cyclic_mygbm_30_95_c78_n256)
    return function(z)
        s1 = mod(log(base, abs(z)), 1)
        s2 = mod2pi(angle(z)) / 2π
        col = convert(Colors.HSV, get(colormap, s2, (0, 1)))
        x = 0.6 + 0.4s1
        return Colors.HSVA(col.h, col.s, x*col.v, 1)
    end
end

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
