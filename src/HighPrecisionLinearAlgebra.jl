using LinearAlgebra 

export HighPrecisionVector, HighPrecisionMatrix

"""
    HighPrecisionVector

A mutable struct representing a high-precision vector.
It stores a vector of HighPrecisionInt elements.
"""
mutable struct HighPrecisionVector
    elements::Vector{HighPrecisionInt}

    function HighPrecisionVector(elements::Vector{HighPrecisionInt})
        new(elements)
    end
    function HighPrecisionVector(elements::Vector{T}) where {T<:Union{Integer, BigInt}}
        new([HighPrecisionInt(x) for x in elements])
    end
end

"""
    HighPrecisionMatrix

A mutable struct representing a high-precision matrix.
It stores a 2D array (Vector of Vectors) of HighPrecisionInt elements.
"""
mutable struct HighPrecisionMatrix
    elements::Vector{Vector{HighPrecisionInt}}
    rows::Int
    cols::Int

    function HighPrecisionMatrix(elements::Vector{Vector{HighPrecisionInt}})
        rows = length(elements)
        if rows == 0
            cols = 0
        else
            cols = length(elements[1])
            # Ensure all rows have the same number of columns
            for row in elements
                if length(row) != cols
                    error("All rows in HighPrecisionMatrix must have the same number of columns.")
                end
            end
        end
        new(elements, rows, cols)
    end

    function HighPrecisionMatrix(elements::Vector{Vector{T}}) where {T<:Union{Integer, BigInt}}
        rows = length(elements)
        if rows == 0
            return new(Vector{Vector{HighPrecisionInt}}(), 0, 0)
        end
        cols = length(elements[1])
        converted_elements = Vector{Vector{HighPrecisionInt}}(undef, rows)
        for i in 1:rows
            if length(elements[i]) != cols
                error("All rows in HighPrecisionMatrix must have the same number of columns.")
            end
            converted_elements[i] = [HighPrecisionInt(x) for x in elements[i]]
        end
        new(converted_elements, rows, cols)
    end
end

# --- Vector Operations ---

"""
    Base.:+(v1::HighPrecisionVector, v2::HighPrecisionVector)

Vector addition. Both vectors must have the same length.
"""
function Base.:+(v1::HighPrecisionVector, v2::HighPrecisionVector)
    if length(v1.elements) != length(v2.elements)
        error("Vectors must have the same length for addition.")
    end
    result_elements = HighPrecisionInt[]
    for i in 1:length(v1.elements)
        push!(result_elements, v1.elements[i] + v2.elements[i])
    end
    return HighPrecisionVector(result_elements)
end

"""
    Base.:-(v1::HighPrecisionVector, v2::HighPrecisionVector)

Vector subtraction. Both vectors must have the same length.
"""
function Base.:-(v1::HighPrecisionVector, v2::HighPrecisionVector)
    if length(v1.elements) != length(v2.elements)
        error("Vectors must have the same length for subtraction.")
    end
    result_elements = HighPrecisionInt[]
    for i in 1:length(v1.elements)
        push!(result_elements, v1.elements[i] - v2.elements[i])
    end
    return HighPrecisionVector(result_elements)
end

"""
    Base.:*(scalar::Union{Integer, BigInt, HighPrecisionInt}, v::HighPrecisionVector)

Scalar-vector multiplication (scalar * vector).
"""
function Base.:*(scalar::Union{Integer, BigInt, HighPrecisionInt}, v::HighPrecisionVector)
    hpi_scalar = HighPrecisionInt(scalar)
    result_elements = HighPrecisionInt[]
    for element in v.elements
        push!(result_elements, hpi_scalar * element)
    end
    return HighPrecisionVector(result_elements)
end

"""
    Base.:*(v::HighPrecisionVector, scalar::Union{Integer, BigInt, HighPrecisionInt})

Scalar-vector multiplication (vector * scalar).
"""
Base.:*(v::HighPrecisionVector, scalar::Union{Integer, BigInt, HighPrecisionInt}) = scalar * v

"""
    LinearAlgebra.dot(v1::HighPrecisionVector, v2::HighPrecisionVector)

Calculates the dot product of two vectors. Both vectors must have the same length.
This function extends `LinearAlgebra.dot`.
The multiplication and summation are performed using `BigInt` intermediates
to avoid repeated `HighPrecisionInt` object creation during summation.
"""
function LinearAlgebra.dot(v1::HighPrecisionVector, v2::HighPrecisionVector)
    if length(v1.elements) != length(v2.elements)
        error("Vectors must have the same length for dot product.")
    end
    # Perform multiplication and summation using BigInt to accumulate high precision
    dot_prod_bigint = BigInt(0)
    for i in 1:length(v1.elements)
        # Convert HighPrecisionInt to BigInt for multiplication and summation
        prod_bigint = BigInt(v1.elements[i]) * BigInt(v2.elements[i])
        dot_prod_bigint += prod_bigint
    end
    # Convert the final BigInt sum back to HighPrecisionInt
    return HighPrecisionInt(dot_prod_bigint)
end

# --- Matrix Operations ---

"""
    Base.:+(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)

Matrix addition. Both matrices must have the same dimensions.
"""
function Base.:+(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)
    if m1.rows != m2.rows || m1.cols != m2.cols
        error("Matrices must have the same dimensions for addition.")
    end
    result_elements = [Vector{HighPrecisionInt}(undef, m1.cols) for _ in 1:m1.rows]
    for i in 1:m1.rows
        for j in 1:m1.cols
            result_elements[i][j] = m1.elements[i][j] + m2.elements[i][j]
        end
    end
    return HighPrecisionMatrix(result_elements)
end

"""
    Base.:-(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)

Matrix subtraction. Both matrices must have the same dimensions.
"""
function Base.:-(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)
    if m1.rows != m2.rows || m1.cols != m2.cols
        error("Matrices must have the same dimensions for subtraction.")
    end
    result_elements = [Vector{HighPrecisionInt}(undef, m1.cols) for _ in 1:m1.rows]
    for i in 1:m1.rows
        for j in 1:m1.cols
            result_elements[i][j] = m1.elements[i][j] - m2.elements[i][j]
        end
    end
    return HighPrecisionMatrix(result_elements)
end

"""
    Base.:*(scalar::Union{Integer, BigInt, HighPrecisionInt}, m::HighPrecisionMatrix)

Scalar-matrix multiplication (scalar * matrix).
"""
function Base.:*(scalar::Union{Integer, BigInt, HighPrecisionInt}, m::HighPrecisionMatrix)
    hpi_scalar = HighPrecisionInt(scalar)
    result_elements = [Vector{HighPrecisionInt}(undef, m.cols) for _ in 1:m.rows]
    for i in 1:m.rows
        for j in 1:m.cols
            result_elements[i][j] = hpi_scalar * m.elements[i][j]
        end
    end
    return HighPrecisionMatrix(result_elements)
end

"""
    Base.:*(m::HighPrecisionMatrix, scalar::Union{Integer, BigInt, HighPrecisionInt})

Scalar-matrix multiplication (matrix * scalar).
"""
Base.:*(m::HighPrecisionMatrix, scalar::Union{Integer, BigInt, HighPrecisionInt}) = scalar * m

"""
    Base.:*(m::HighPrecisionMatrix, v::HighPrecisionVector)

Matrix-vector multiplication. Number of matrix columns must equal vector length.
The multiplication and summation are performed using `BigInt` intermediates
to avoid repeated `HighPrecisionInt` object creation during summation for each element.
"""
function Base.:*(m::HighPrecisionMatrix, v::HighPrecisionVector)
    if m.cols != length(v.elements)
        error("Matrix columns must match vector length for multiplication.")
    end
    result_elements = HighPrecisionInt[]
    for i in 1:m.rows
        sum_val_bigint = BigInt(0)
        for k in 1:m.cols # inner dimension
            # Convert HighPrecisionInt to BigInt for multiplication and summation
            prod_bigint = BigInt(m.elements[i][k]) * BigInt(v.elements[k])
            sum_val_bigint += prod_bigint
        end
        # Convert the final BigInt sum for this element back to HighPrecisionInt
        push!(result_elements, HighPrecisionInt(sum_val_bigint))
    end
    return HighPrecisionVector(result_elements)
end

"""
    Base.:*(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)

Matrix-matrix multiplication. Number of columns in m1 must equal number of rows in m2.
The multiplication and summation are performed using `BigInt` intermediates
to avoid repeated `HighPrecisionInt` object creation during summation for each element.
"""
function Base.:*(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)
    if m1.cols != m2.rows
        error("Number of columns in the first matrix must match the number of rows in the second matrix for multiplication.")
    end

    result_elements = [Vector{HighPrecisionInt}(undef, m2.cols) for _ in 1:m1.rows]

    for i in 1:m1.rows # rows of result
        for j in 1:m2.cols # columns of result
            sum_val_bigint = BigInt(0)
            for k in 1:m1.cols # inner dimension
                # Convert HighPrecisionInt to BigInt for multiplication and summation
                prod_bigint = BigInt(m1.elements[i][k]) * BigInt(m2.elements[k][j])
                sum_val_bigint += prod_bigint
            end
            # Convert the final BigInt sum for this element back to HighPrecisionInt
            result_elements[i][j] = HighPrecisionInt(sum_val_bigint)
        end
    end
    return HighPrecisionMatrix(result_elements)
end

# --- Display Methods ---

function Base.show(io::IO, v::HighPrecisionVector)
    print(io, "HighPrecisionVector([\n")
    for (idx, el) in enumerate(v.elements)
        print(io, "  ")
        show(io, el)
        if idx < length(v.elements)
            print(io, ",\n")
        else
            print(io, "\n")
        end
    end
    print(io, "])")
end

function Base.show(io::IO, m::HighPrecisionMatrix)
    print(io, "HighPrecisionMatrix(\n")
    for (idx_r, row) in enumerate(m.elements)
        print(io, "  [")
        for (idx_c, el) in enumerate(row)
            show(io, el)
            if idx_c < length(row)
                print(io, ", ")
            end
        end
        print(io, "]")
        if idx_r < length(m.elements)
            print(io, ",\n")
        else
            print(io, "\n")
        end
    end
    print(io, ")")
end
