using .Plots

#####
##### Polar and Spherical
#####

Plots.@recipe function f(z::Array{Polar{T}}) where {T}
    projection --> :polar
    angle.(z), abs.(z)
end

Plots.@recipe function f(z::Array{Spherical{T}}; sphere=true) where {T}
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

#####
##### Function visualization
#####

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

#####
##### Curves and paths
#####

Plots.@recipe function f(::Type{T}, C::T) where T <: AbstractCurve
    aspect_ratio --> 1.0
    plotdata(C)
end

Plots.@recipe function f(P::AbstractPath; vertices=false)
    delete!(plotattributes, :vertices)
    aspect_ratio --> 1.0

    @series begin
        vcat( [plotdata(c) for c in P]... )
    end

    if vertices
        @series begin
            label := ""
            markercolor --> :black
            markershape --> :circle
            seriestype := :scatter
            ComplexRegions.vertices(P)
        end
    end
end

Plots.@recipe function f(p::AbstractCircularPolygon)
    if isfinite(p)
        p.path
    else
        C = ComplexRegions.enclosing_circle(p, 8)
        q = truncate(p, C)
        z, R = C.center, C.radius / 3
        xlims --> (real(z) - R, real(z) + R)
        ylims --> (imag(z) - R, imag(z) + R)
        q.path
    end
end

#####
##### Regions
#####

Plots.@recipe function f(::Type{T}, R::T) where T<:SimplyConnectedRegion
   if R isa ExteriorSimplyConnectedRegion
        seriestype := :shapecomplement
    else
        seriestype := :shape
    end

    C = R.boundary  # could be curve or path
    if C isa Line
        # need to fake with a polygon
        θ = angle(C)
        Polygon([C(0.5),(θ,θ+π)])
#    elseif C isa AbstractCurve
 #       ClosedPath(C)
    else
        C
    end
end

Plots.@recipe function f(R::ExteriorSimplyConnectedRegion)
    P = innerboundary(R)
    C = ComplexRegions.enclosing_circle(ClosedPath(P),8)
    zc = C.center
    r = 0.2*C.radius
    xlims --> [real(zc) - r, real(zc) + r]
    ylims --> [imag(zc) - r, imag(zc) + r]
    between(C,P)
end

Plots.@recipe function f(R::Union{ConnectedRegion,ExteriorRegion})
    p0 = outerboundary(R)
    p1 = innerboundary(R)
    z1 = [plotdata(p) for p in p1]
    if isnothing(p0)
        zc, rho = ComplexRegions.enclosing_circle(reduce(vcat, z1), 8)
        p0 = ComplexRegions.Circle(zc, rho)
        r = 0.2*rho
        xlims --> [real(zc) - r, real(zc) + r]
        ylims --> [imag(zc) - r, imag(zc) + r]
    end
    z0 = plotdata(p0)
    # This is not fast, but I don't see a shortcut...
    # find pairwise distances between components
    comp = [z1...,z0]
    n = length(comp)
    index = Array{Tuple}(undef,n,n)
    dist = fill(Inf,n,n)
    for i in 1:n
        for j in i+1:n
            ka, kb = argclosest(comp[i], comp[j])
            index[i, j] = (ka, kb)
            index[j, i] = (kb, ka)
            dist[i, j] = dist[j, i] = abs(comp[i][ka] - comp[j][kb])
        end
    end

    # find the hops between components
    unused = trues(length(z1))
    curr = n
    path = []
    while sum(unused) > 1
        u = findall(unused)
        k = argmin(dist[curr, u])
        next = u[k]
        push!(path, (curr, next))
        unused[next] = false
        curr = next
    end
    push!(path,(curr,findfirst(unused)))

    # accumulate into the last component
    p = path[1]
    idx = index[p...]
    data_in = z0[idx[1]]
    data_out = [ z0[idx[1]:-1:1]; z0[end:-1:idx[1]] ]
    for k = 1:length(path)-1
        a = idx[2]
        zc = comp[p[2]]
        p = path[k+1]
        idx = index[p...]
        b = idx[1]
        if a > b
            data_in = [data_in; zc[a:-1:b]]
            data_out = [data_out; zc[a:end]; zc[1:b]]
        else
            data_in = [data_in; zc[a:-1:1]; zc[end:-1:b]]
            data_out = [data_out; zc[a:b]]
        end
    end
    a = idx[2]
    zc = comp[p[2]]
    data = [ data_in; zc[a:-1:1]; zc[end:-1:a]; data_out[end:-1:1] ]

    aspectratio --> 1
    @series begin
        seriestype := :shape
        linealpha := 0
       data
    end

    seriestype := :path
    linecolor --> :black
    label := ""
    @series begin
        z0
    end
    for z in z1
        @series begin
            z
        end
    end
end
