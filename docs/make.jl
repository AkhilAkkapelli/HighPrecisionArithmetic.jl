push!(LOAD_PATH,"../src/")

using .HighPrecisionArithmetic
using Documenter
import Documenter.Remotes: GitHub

makedocs(
    sitename = "HighPrecisionArithmetic.jl",
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
        "API" => [
            "High Precision Number API" => "api/high-precision-number.md",
            "High Precision Linear Algebra API" => "api/high-precision-linearalgebra.md",
        ],
    ],
    modules = [
        HighPrecisionArithmetic,
        HighPrecisionArithmetic.HighPrecisionNumber,
        HighPrecisionArithmetic.HighPrecisionLinearAlgebra
    ],
)

deploydocs(
    repo = "github.com/akhilakkapelli/HighPrecisionArithmetic.jl.git", 
    devbranch = "master",
)