using Gadfly
using Colors
export line_plot, scatter_plot
export new_figure, show_figure, save_figure
export set_xlabel, set_ylabel, set_title, set_legend

global cur_figure = nothing
global cairo_supported = Pkg.installed("Cairo") != nothing

# use Colors' built-in utility for 
# generating easily-distinguishable colors
color_rotation = distinguishable_colors(8, colorant"blue");

supported_formats = {
  "svg" => SVG
}

if cairo_supported
  cairo_supported_formats = {
    "ps" =>  PS,
    "pdf" => PDF,
    "png" => PNG,
  }
end

type Figure
  layers::Array{Gadfly.Layer, 1}
  title::String
  xlabel::String
  ylabel::String
  has_legend::Bool
  legend::Dict{RGB{U8},String}
  legend_title::String
  
  function Figure(title::String, xlabel::String, ylabel::String, has_legend::Bool, legend_title::String)
    return new(Gadfly.Layer[], title, xlabel, ylabel, has_legend, Dict{RGB{U8},String}(), legend_title)
  end
end

function build_plot(figure::Figure)
  if length(figure.layers) == 0
    error("No plots have been defined for current figure")
  end
  p = nothing
  if figure.has_legend
    p = Gadfly.plot(
      figure.layers,
      Guide.title(figure.title),
      Guide.xlabel(figure.xlabel),
      Guide.ylabel(figure.ylabel),
      Guide.manual_color_key(figure.legend_title, 
                             collect(values(figure.legend)), 
                             collect(keys(figure.legend)))
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

function new_figure(; title="", xlabel="", ylabel="", has_legend=false, legend_title="")
  figure = Figure(title, xlabel, ylabel, has_legend, legend_title)
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
  if format in keys(supported_formats)
    draw(supported_formats[format](name, width, height), p)
  elseif cairo_supported && format in keys(cairo_supported_formats)
      draw(cairo_supported_formats[format](name, width, height), p)
  else
    error("Unable to write '$format' file. Please use 'svg' (default), or install Cairo and use 'png', 'pdf', or 'ps'.")
  end
  return figure
end

function generic_plot(x, y, geom, color_string, label, figure)
  if length(x) != length(y)
    error("x and y need to have equal length.")
  end
  figure = get_figure(figure)
  parsed_color = nothing
  if color_string == nothing # if no color is specified
    if label in values(figure.legend) # and we already have a label
      # then use the previous color most recently assigned
      parsed_color = collect(keys(filter((k,v) -> v == label)))[end]
    else # otherwise generate a new color
      parsed_color = color_rotation[length(figure.legend) % length(color_rotation) + 1]
    end
  else # if a color was specified, use that one
    parsed_color = parse(Colorant, color_string)
  end
  theme = Theme(default_color = color(parsed_color))
  new_layer = Gadfly.layer(x=x, y=y, geom, theme)
  append!(figure.layers, new_layer)
  figure.legend_entries[parsed_color] = label
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

function set_legend(has_legend::Bool; title=nothing, figure=nothing)
  figure = get_figure(figure)
  figure.has_legend = has_legend 
  if title != nothing
    figure.legend_title = title
  end
end
