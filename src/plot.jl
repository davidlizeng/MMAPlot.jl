using Gadfly
using Colors
export line_plot, scatter_plot
export new_figure, show_figure, save_figure
export set_xlabel, set_ylabel, set_title, set_legend

global cur_figure = nothing
global cairo_supported = Pkg.installed("Cairo") != nothing

color_rotation = [
  colorant"blue",
  colorant"red",
  colorant"green",
  colorant"orange",
  colorant"purple",
  colorant"gold"
];

type Figure
  layers::Array{Gadfly.Layer, 1}
  colors::Array{RGB{U8}, 1}
  labels::Array{String, 1}
  title::String
  xlabel::String
  ylabel::String
  legend::Bool
  legend_title::String

  function Figure(title::String, xlabel::String, ylabel::String, legend::Bool, legend_title::String)
    return new(Gadfly.Layer[], String[], String[], title, xlabel, ylabel, legend, legend_title)
  end
end

function build_plot(figure::Figure)
  if length(figure.layers) == 0
    error("No plots have been defined for current figure")
  end
  p = nothing
  if figure.legend
    p = Gadfly.plot(
      figure.layers,
      Guide.title(figure.title),
      Guide.xlabel(figure.xlabel),
      Guide.ylabel(figure.ylabel),
      Guide.manual_color_key(figure.legend_title, figure.labels, figure.colors)
    )
  else
    p = Gadfly.plot(
      figure.layers,
      Guide.title(figure.title),
      Guide.xlabel(figure.xlabel),
      Guide.ylabel(figure.ylabel)
    )
  end
end

function get_figure(figure)
  if figure == nothing
    if cur_figure != nothing
      figure = cur_figure
    else
      figure = new_figure()
    end
  end
  return figure
end

function new_figure(; title="", xlabel="x", ylabel="y", legend=false, legend_title="")
  figure = Figure(title, xlabel, ylabel, legend, legend_title)
  global cur_figure = figure
  return figure
end

function show_figure(; figure=nothing)
  figure = get_figure(figure)
  p = build_plot(figure)
  display(p)
  return figure
end
show_figure(figure) = show_figure(figure=figure)

function save_figure(name; width=8inch, height=6inch, format="svg", figure=nothing)
  figure = get_figure(figure)
  p = build_plot(figure)
  if format == "svg"
    draw(SVG(name, width, height), p)
  elseif format == "pdf" || format == "ps" || format == "png"
    if cairo_supported
      if format == "pdf"
        draw(PDF(name, width, height), p)
      elseif format == "ps"
        draw(PS(name, width, height), p)
      else
        draw(PNG(name, width, height), p)
      end
    else
      error("The Cairo package needs to be installed to write images in pdf, ps, or png format.")
    end
  else
    error("Unrecognized image format. Please use \"svg\" (default), \"png\", \"pdf\", or \"ps\".")
  end
  return figure
end

function generic_plot(x, y, geom, color_string, label, figure)
  figure = get_figure(figure)
  if color_string == nothing
    color_string = color_rotation[length(figure.layers) % length(color_rotation) + 1]
  end
  theme = Theme(default_color = color(color_string))
  new_layer = Gadfly.layer(x=x, y=y, geom, theme)
  append!(figure.layers, new_layer)
  push!(figure.colors, color_string)
  push!(figure.labels, label)
  return nothing
end

line_plot(x, y; color=nothing, label="", figure=nothing) =
    generic_plot(x, y, Geom.path, color, label, figure)
line_plot(y; color=nothing, label="", figure=nothing) =
    generic_plot(1:length(y), y, Geom.path, color, label, figure)

scatter_plot(x, y; color=nothing, label="", figure=nothing) =
    generic_plot(x, y, Geom.point, color, label, figure)
scatter_plot(y; color=nothing, label="", figure=nothing) =
    generic_plot(1:length(y), y, Geom.point, color, label, figure)

function set_title(title::String; figure=nothing)
  figure = get_figure(figure)
  figure.title = title
end

function set_xlabel(xlabel::String; figure=nothing)
  figure = get_figure(figure)
  figure.xlabel = xlabel
end

function set_ylabel(ylabel::String; figure=nothing)
  figure = get_figure(figure)
  figure.ylabel = ylabel
end

function set_legend(on::Bool; title=nothing, figure=nothing)
  figure = get_figure(figure)
  figure.legend = on
  if title != nothing
    figure.legend_title = title
  end
end
