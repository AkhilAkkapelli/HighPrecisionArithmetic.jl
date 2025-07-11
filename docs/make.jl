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
        assets = String["assets/hpa.ico"],
        inventory_version = "v1", 
    ),
    pages = [
        "Home" => "index.md",
        "High Precision Integer" => "HighPrecisionInteger.md",
        "High Precision Linear Algebra" => "HighPrecisionLinearAlgebra.md",
        "API" => "api/high-precision-arithmetic.md",
    ],
    modules = [
        HighPrecisionArithmetic
    ],
)

deploydocs(
    repo = "github.com/AkhilAkkapelli/HighPrecisionArithmetic.jl.git", 
    devbranch = "master",
)
