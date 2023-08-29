# Complex plane plots in `Plots`

```@setup plots
using Plots
default(linewidth=3, legend=false)
```
The plots below are made using the defaults

```@example plots
default(linewidth=3, legend=false);
```

## Point-based plots for complex arrays

Plots of `Polar` values are made on polar axes.

```@example plots
using ComplexPlots, Plots, ComplexValues  
zc = cispi.(2*(0:400) / 400);
plot(@. Polar(0.5 + zc))  
```

Plots of `Spherical` values are made on the Riemann sphere.

```@example plots
z = [complex(2cospi(t), 0.5sinpi(t)) for t in (0:400) / 200]
plot(Spherical.(z))  
```

## Function visualization

Plots of complex functions can be made using the `zplot` function. At each point in the complex domain, the hue is selected from a cyclic colormap using the phase of the function value, and the color value (similar to lightness) is chosen by the fractional part of the log of the function value's magnitude.

Examples:

```@example plots
default(aspect_ratio=1)
zplot(z -> (z^3 - 1) / (3im - z)^2)
```

As you see above, zeros and poles occur where the contours of magnitude collapse into a point. Zeros are characterized by a clockwise progression of the hues green--yellow--magenta--blue around that point, whereas poles have those hues in counterclockwise order. The number of times these hues cycle around the point is the multiplicity of the zero or pole.

```@example plots
zplot(tanh, [-5, 5], [-5, 5])
```

Above you can see poles and zeros alternating on the imaginary axis.

```@example plots
zplot(z -> log((1 + z) / (1im - z)), [-2, 2], [-2, 2], 1000)
```

Above you see how branch cuts create abrupt changes in hue. (The final positional argument in the call specifies the number of points used in each direction.)

## Curves and paths

The [`ComplexRegions`](https://complexvariables.github.com/ComplexRegions.jl) package defines types for lines, circles, rays, segments, and arcs.

```@example plots
using ComplexRegions
plot(Circle(-1, 1))
plot!(Segment(-1-1im, -1+1im))
plot!(Arc(-1, 1im, 1))
```

On the Riemann sphere, lines and circles are all simply circles, as are their inverses:

```@example plots
c = Spherical(Circle(0, 1))
l = Spherical(Line(-1, 1im))
plot(c); plot!(l, sphere=false)
plot!(1/c, sphere=false)
plot!(1/l, sphere=false)
```

You can also create and plot polygons.

```@example plots
L = Polygon([0, 1im, -1+1im, -1-1im, 1-1im, 1])
plot(L)
```

There are some predefined shapes in the `Shapes` submodule.

```@example plots
plot(Shapes.ellipse(1, 0.5))
plot!(2im + Shapes.star)
plot!(-2im + Shapes.cross)
plot!(2 + Shapes.triangle)
plot!(-2 + 0.3im*Shapes.hypo(3))
```

## Regions

The `ComplexRegions` package defines types for regions, which are interior and/or exterior to closed curves and paths.

```@example plots
C = Shapes.circle
S = Shapes.square
plot(interior(S), layout=(2, 2))
plot!(exterior(S), subplot=2)
plot!(between(2C, S), subplot=3)
plot!(ExteriorRegion([C - 2, S + 2]), subplot=4)
```
