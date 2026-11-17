# Jacoby Demo: Jacobian Matrices in Julia


using FiniteDiff
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
end
