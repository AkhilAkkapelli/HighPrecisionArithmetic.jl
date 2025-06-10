push!(LOAD_PATH, "../src")

using Documenter
import Documenter.Remotes: GitHub

using HighPrecisionArithmetic

makedocs(
    sitename = "HighPrecisionArithmetic.jl",
    authors = "Akhil Akkapelli",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://akhilakkapelli.github.io/HighPrecisionArithmetic.jl",
        assets = String["assets/logo.ico"],
        inventory_version = "v1",
        analytics = "G-EBVYFS4TLJ"
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
