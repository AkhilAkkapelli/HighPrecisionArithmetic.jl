push!(LOAD_PATH, "../src")

using Documenter
import Documenter.Remotes: GitHub

using HighPrecisionArithmetic

makedocs(
    sitename = "HighPrecisionArithmetic.jl",
    authors = "Akhil Akkapelli",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://akhilakkapelli.github.io/HighPrecisionArithmetic.jl/stable/",
        assets = String["assets/julia.ico"],
        inventory_version = "v1", 
    ),
    pages = [
        "Home" => "index.md",
        "High Precision Number" => "HighPrecisionNumber.md",
        "High Precision Linear Algebra" => "HighPrecisionLinearAlgebra.md",
        "API" => "api/high-precision-arithmetic.md",
    ],
    modules = [
        HighPrecisionArithmetic
    ],
)

if get(ENV, "GITHUB_EVENT_NAME", nothing) == "workflow_dispatch"
    ENV["GITHUB_EVENT_NAME"] = "push"
end

deploydocs(
    repo = "github.com/akhilakkapelli/HighPrecisionArithmetic.jl", 
    devbranch = "master",
)
