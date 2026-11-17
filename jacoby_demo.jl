# Jacoby Demo: Jacobian Matrices in Julia


using FiniteDiff
using LinearAlgebra
using Plots

# Define a vector-valued function f: ℝ² → ℝ²
function f(x::AbstractVector)
    return [x[1]^2 + x[2], sin(x[1]) * cos(x[2])]
end

# Compute the Jacobian at a point using FiniteDiff
x = [1.0, 2.0]

# FiniteDiff expects f(x) to return a vector and x to be a vector

J = FiniteDiff.finite_difference_jacobian(f, x)

println("Function value at x: ", f(x))
println("Jacobian at x: ")
println(J)

withenv("GKSwstype" => "100") do
    limit = maximum(abs, J)
    plot = heatmap(
        1:2, 1:2, J;
        color = cgrad(["#2166ac", "#ffffff", "#b2182b"]),
        clims = (-limit, limit),
        colorbar_title = "Derivative",
        xticks = (1:2, ["x1", "x2"]),
        yticks = (1:2, ["f1", "f2"]),
        xlabel = "Input variable (column)",
        ylabel = "Output component (row)",
        title = "Jacobian at x = $(x)",
        yflip = true,
        aspect_ratio = :equal,
        size = (760, 560),
        margin = 8Plots.mm,
    )
    for row in axes(J, 1), col in axes(J, 2)
        label_color = abs(J[row, col]) > 0.6limit ? :white : :black
        annotate!(plot, col, row, text(string(round(J[row, col]; digits = 4)), 16, label_color))
    end
    output_path = joinpath(@__DIR__, "jacobian_heatmap.png")
    savefig(plot, output_path)
    println("Jacobian heatmap saved to: ", output_path)

    halfwidth = 0.1
    corners = halfwidth .* [-1 1 1 -1; -1 -1 1 1]
    boundary = hcat([
        (1 - t) .* corners[:, edge] .+ t .* corners[:, mod1(edge + 1, 4)]
        for edge in 1:4 for t in range(0, 1; length = 21)[1:end-1]
    ]...)
    linear_boundary = J * boundary
    nonlinear_boundary = hcat([f(x + point) - f(x) for point in eachcol(boundary)]...)
    corner_indices = 1:20:80
    extent = 1.2 * maximum(abs, hcat(boundary, linear_boundary, nonlinear_boundary))
    colors = [:black, :orange, :purple, :green]

    # Interpolate shapes for illustration, not repeated applications of f.
    animation = @animate for t in vcat(zeros(10), range(0, 1; length = 61), ones(20))
        shapes = (
            boundary,
            (1 - t) .* boundary .+ t .* linear_boundary,
            (1 - t) .* boundary .+ t .* nonlinear_boundary,
        )
        panels = map(zip(shapes, ("Input square", "Jacobian approximation", "Nonlinear transformation"))) do (points, title)
            panel = Plots.plot(
                Shape(points[1, :], points[2, :]);
                fillcolor = :steelblue,
                fillalpha = 0.2,
                linecolor = :steelblue,
                linewidth = 2,
                title = title,
                xlabel = "Component 1 offset",
                ylabel = "Component 2 offset",
                xlims = (-extent, extent),
                ylims = (-extent, extent),
                aspect_ratio = :equal,
                legend = false,
            )
            Plots.plot!(panel, Shape(boundary[1, :], boundary[2, :]);
                fillalpha = 0, linecolor = :gray, linestyle = :dash)
            scatter!(panel, points[1, corner_indices], points[2, corner_indices];
                markercolor = colors, markersize = 6, markerstrokewidth = 0)
            Plots.plot!(panel, points[1, 5:13], points[2, 5:13];
                linecolor = :black, linewidth = 3, arrow = true)
            panel
        end
        Plots.plot(panels...;
            layout = (1, 3),
            size = (1200, 500),
            margin = 6Plots.mm,
            plot_title = "Near x = $(x): det J = $(round(det(J); digits = 4)) | Morph $(round(Int, 100t))%",
        )
    end
    animation_path = joinpath(@__DIR__, "jacobian_orientation.gif")
    gif(animation, animation_path; fps = 15)
    println("Jacobian orientation animation saved to: ", animation_path)
end
