using Revise
using LinearAlgebra

# Include the HighPrecisionArithmetic module before HighPrecisionLinearAlgebra if using outside of HighPrecisionLinearAlgebra module definition
include("HighPrecisionLinearAlgebra.jl") 

using .HighPrecisionLinearAlgebra # Bring the module into scope

println("--- HighPrecisionLinearAlgebra Usage Examples ---")
println("-----------------------------------------------")

println("\n1. HighPrecisionVector Creation:")
# Corrected vec1 length to match mat1's columns for multiplication example
vec1 = HighPrecisionVector([1, -2]) 
println("   vec1 = HighPrecisionVector([1, -2]) => $vec1")

vec2 = HighPrecisionVector([HighPrecisionInt(1000), HighPrecisionInt(-500), HighPrecisionInt(200)])
println("   vec2 = HighPrecisionVector([1000, -500, 200]) => $vec2")

large_vec = HighPrecisionVector([BigInt(2)^70, -BigInt(2)^75, BigInt(2)^80])
println("   large_vec = HighPrecisionVector([2^70, -2^75, 2^80]) => $large_vec")

println("\n2. HighPrecisionVector Addition & Subtraction:")
# Note: vec1 and vec2 now have different lengths, so direct addition/subtraction will error.
# I'll use new compatible vectors for these examples if needed.
vec1_compat = HighPrecisionVector([1, 2, 3])
vec2_compat = HighPrecisionVector([10, 20, 30])
v_sum = vec1_compat + vec2_compat
println("   $vec1_compat + $vec2_compat => $v_sum")
println("   Verification: $(BigInt(v_sum.elements[1]) == 11 && BigInt(v_sum.elements[2]) == 22 && BigInt(v_sum.elements[3]) == 33)")

v_diff = vec1_compat - vec2_compat
println("   $vec1_compat - $vec2_compat => $v_diff")
println("   Verification: $(BigInt(v_diff.elements[1]) == -9 && BigInt(v_diff.elements[2]) == -18 && BigInt(v_diff.elements[3]) == -27)")


println("\n3. HighPrecisionVector Scalar Multiplication:")
scalar_val = HighPrecisionInt(5)
v_scaled = scalar_val * HighPrecisionVector([1, -2, 3]) # Using a fresh vector for this example
println("   $scalar_val * HighPrecisionVector([1, -2, 3]) => $v_scaled")
println("   Verification: $(BigInt(v_scaled.elements[1]) == 5 && BigInt(v_scaled.elements[2]) == -10 && BigInt(v_scaled.elements[3]) == 15)")

println("\n4. HighPrecisionVector Dot Product:")
dot_vec_a = HighPrecisionVector([1, 2, 3])
dot_vec_b = HighPrecisionVector([4, 5, 6])
v_dot = LinearAlgebra.dot(dot_vec_a, dot_vec_b)
println("   dot($dot_vec_a, $dot_vec_b) => $v_dot")
# (1 * 4) + (2 * 5) + (3 * 6) = 4 + 10 + 18 = 32
println("   Verification: $(BigInt(v_dot) == 32)")

println("\n5. HighPrecisionMatrix Creation:")
mat1 = HighPrecisionMatrix([[1, 2], [3, 4]])
println("   mat1 = HighPrecisionMatrix([[1, 2], [3, 4]]) =>\n$mat1")

mat2 = HighPrecisionMatrix([[HighPrecisionInt(5), HighPrecisionInt(6)], [HighPrecisionInt(7), HighPrecisionInt(8)]])
println("   mat2 = HighPrecisionMatrix([[5, 6], [7, 8]]) =>\n$mat2")

large_mat = HighPrecisionMatrix([[BigInt(2)^60, -BigInt(2)^62], [BigInt(2)^65, BigInt(2)^67]])
println("   large_mat = HighPrecisionMatrix([[2^60, -2^62], [2^65, 2^67]]) =>\n$large_mat")

println("\n6. HighPrecisionMatrix Addition & Subtraction:")
m_sum = mat1 + mat2
println("   $mat1 + $mat2 =>\n$m_sum")
println("   Verification: $(BigInt(m_sum.elements[1][1]) == 6 && BigInt(m_sum.elements[2][2]) == 12)")

m_diff = mat1 - mat2
println("   $mat1 - $mat2 =>\n$m_diff")
println("   Verification: $(BigInt(m_diff.elements[1][1]) == -4 && BigInt(m_diff.elements[2][2]) == -4)")

println("\n7. HighPrecisionMatrix Scalar Multiplication:")
m_scaled = HighPrecisionInt(3) * mat1
println("   3 * $mat1 =>\n$m_scaled")
println("   Verification: $(BigInt(m_scaled.elements[1][1]) == 3 && BigInt(m_scaled.elements[2][2]) == 12)")

println("\n8. HighPrecisionMatrix-Vector Multiplication:")
# Using the corrected vec1 for compatibility with mat1 (2x2 matrix * 2-element vector)
m_vec_prod = mat1 * vec1
println("   $mat1 * $vec1 => $m_vec_prod")
# [1*1 + 2*-2, 3*1 + 4*-2] = [1 - 4, 3 - 8] = [-3, -5]
println("   Verification: $(BigInt(m_vec_prod.elements[1]) == -3 && BigInt(m_vec_prod.elements[2]) == -5)")

println("\n9. HighPrecisionMatrix-Matrix Multiplication:")
m_mat_prod = mat1 * mat2
println("   $mat1 * $mat2 =>\n$m_mat_prod")
# [[1*5+2*7, 1*6+2*8], [3*5+4*7, 3*6+4*8]]
# [[5+14, 6+16], [15+28, 18+32]]
# [[19, 22], [43, 50]]
println("   Verification: $(BigInt(m_mat_prod.elements[1][1]) == 19 && BigInt(m_mat_prod.elements[1][2]) == 22 && BigInt(m_mat_prod.elements[2][1]) == 43 && BigInt(m_mat_prod.elements[2][2]) == 50)")

println("\n--- End of Examples ---")
