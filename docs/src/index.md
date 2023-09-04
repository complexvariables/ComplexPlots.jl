```@meta
CurrentModule = ComplexPlots
```
# ComplexPlots

[ComplexPlots](https://github.com/tobydriscoll/ComplexPlots.jl) provides definitions and recipes useful for making plots in the complex plane. 

Code is provided for the [Plots.jl](https://docs.juliaplots.org/stable/) and [Makie.jl](https://docs.makie.org/stable/) systems. 

## Curves, paths, and regions

Facilities are provided for displaying curves, paths, and regions as defined in the [ComplexRegions](https://complexvariables.github.io/ComplexRegions.jl/stable/) package. 

## Riemann sphere

Vectors of points can be plotted on the surface of the Riemann sphere. The syntax is different for the two plotting environments.

## Function visualization

Plots of complex functions can be made in the style of [Wegert and Semmler](http://arxiv.org/abs/1007.2295) using the `zplot` function. At each point in the complex domain, the hue is selected from a cyclic colormap using the phase of the function value, and the color value (similar to lightness) is chosen by the fractional part of the log of the function value's magnitude.

```@setup
using WGLMakie
```

```@docs
zplot
artist
```
