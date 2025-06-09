push!(LOAD_PATH, "../src")

using Documenter
import Documenter.Remotes: GitHub

using HighPrecisionArithmetic

makedocs(
    sitename = "HighPrecisionArithmetic.jl",
    authors = "Akhil Akkapelli",
    format = Documenter.HTML(
        assets = String["assets/logo.svg"],
        favicon = "assets/logo.svg",
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://akhilakkapelli.github.io/HighPrecisionArithmetic.jl/stable/",
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

deploydocs(
    repo = "github.com/AkhilAkkapelli/HighPrecisionArithmetic.jl", 
    devbranch = "master",
)
