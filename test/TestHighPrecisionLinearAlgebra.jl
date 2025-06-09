using Test
using HighPrecisionArithmetic # Needed for HighPrecisionInt type
using LinearAlgebra # For dot function

@testset "HighPrecisionLinearAlgebra.jl" begin

    # 1. Type Creation
    @testset "Type Creation" begin
        # HighPrecisionVector
        vec_int = HighPrecisionVector([1, -2, 3])
        @test length(vec_int.elements) == 3
        @test BigInt(vec_int.elements[1]) == 1
        @test BigInt(vec_int.elements[2]) == -2

        vec_hpi = HighPrecisionVector([HighPrecisionInt(10), HighPrecisionInt(-20)])
        @test length(vec_hpi.elements) == 2
        @test BigInt(vec_hpi.elements[1]) == 10

        large_vec = HighPrecisionVector([BigInt(2)^70, -BigInt(2)^75])
        @test length(large_vec.elements) == 2
        @test BigInt(large_vec.elements[1]) == BigInt(2)^70

        # HighPrecisionMatrix
        mat_int = HighPrecisionMatrix([[1, 2], [3, 4]])
        @test mat_int.rows == 2
        @test mat_int.cols == 2
        @test BigInt(mat_int.elements[1][1]) == 1
        @test BigInt(mat_int.elements[2][2]) == 4

        mat_hpi = HighPrecisionMatrix([[HighPrecisionInt(10), HighPrecisionInt(20)], [HighPrecisionInt(30), HighPrecisionInt(40)]])
        @test mat_hpi.rows == 2
        @test mat_hpi.cols == 2
        @test BigInt(mat_hpi.elements[1][2]) == 20

        large_mat = HighPrecisionMatrix([[BigInt(2)^60, -BigInt(2)^62], [BigInt(2)^65, BigInt(2)^67]])
        @test large_mat.rows == 2
        @test BigInt(large_mat.elements[1][1]) == BigInt(2)^60

        # Test error for inconsistent rows
        @test_throws ErrorException HighPrecisionMatrix([[1, 2], [3, 4, 5]])
    end

    # 2. Vector Operations
    @testset "Vector Operations" begin
        v1 = HighPrecisionVector([1, 2, 3])
        v2 = HighPrecisionVector([4, 5, 6])
        v3 = HighPrecisionVector([-1, -2, -3])
        v_diff_len = HighPrecisionVector([1,2]) # For length mismatch tests

        # Addition
        @testset "Vector Addition" begin
            v_sum = v1 + v2
            @test BigInt(v_sum.elements[1]) == 5
            @test BigInt(v_sum.elements[2]) == 7
            @test BigInt(v_sum.elements[3]) == 9
            @test_throws ErrorException v1 + v_diff_len
        end

        # Subtraction
        @testset "Vector Subtraction" begin
            v_sub = v2 - v1
            @test BigInt(v_sub.elements[1]) == 3
            @test BigInt(v_sub.elements[2]) == 3
            @test BigInt(v_sub.elements[3]) == 3
            @test_throws ErrorException v1 - v_diff_len
        end

        # Scalar Multiplication
        @testset "Vector Scalar Multiplication" begin
            scalar_hpi = HighPrecisionInt(10)
            scalar_int = 5
            
            v_scaled_hpi = scalar_hpi * v1
            @test BigInt(v_scaled_hpi.elements[1]) == 10
            @test BigInt(v_scaled_hpi.elements[2]) == 20

            v_scaled_int = v1 * scalar_int
            @test BigInt(v_scaled_int.elements[1]) == 5
            @test BigInt(v_scaled_int.elements[3]) == 15
        end

        # Dot Product
        @testset "Dot Product" begin
            v_dot = LinearAlgebra.dot(v1, v2)
            # (1*4) + (2*5) + (3*6) = 4 + 10 + 18 = 32
            @test BigInt(v_dot) == 32

            # Test with negative numbers
            v_dot_neg = LinearAlgebra.dot(v1, v3)
            # (1*-1) + (2*-2) + (3*-3) = -1 + -4 + -9 = -14
            @test BigInt(v_dot_neg) == -14

            @test_throws ErrorException LinearAlgebra.dot(v1, v_diff_len)

            # Test with large numbers
            v_large_a = HighPrecisionVector([HighPrecisionInt(BigInt(2)^40), HighPrecisionInt(2)])
            v_large_b = HighPrecisionVector([HighPrecisionInt(2), HighPrecisionInt(BigInt(2)^40)])
            # (2^40 * 2) + (2 * 2^40) = 2*2^40 + 2*2^40 = 4 * 2^40 = 2^2 * 2^40 = 2^42
            @test BigInt(LinearAlgebra.dot(v_large_a, v_large_b)) == BigInt(2)^42
        end
    end

    # 3. Matrix Operations
    @testset "Matrix Operations" begin
        m1 = HighPrecisionMatrix([[1, 2], [3, 4]]) # 2x2
        m2 = HighPrecisionMatrix([[5, 6], [7, 8]]) # 2x2
        m_rect = HighPrecisionMatrix([[1, 2, 3], [4, 5, 6]]) # 2x3
        m_tall = HighPrecisionMatrix([[10], [20], [30]]) # 3x1

        # Addition
        @testset "Matrix Addition" begin
            m_sum = m1 + m2
            @test BigInt(m_sum.elements[1][1]) == 6
            @test BigInt(m_sum.elements[1][2]) == 8
            @test BigInt(m_sum.elements[2][1]) == 10
            @test BigInt(m_sum.elements[2][2]) == 12
            @test_throws ErrorException m1 + m_rect # Dimension mismatch
        end

        # Subtraction
        @testset "Matrix Subtraction" begin
            m_sub = m2 - m1
            @test BigInt(m_sub.elements[1][1]) == 4
            @test BigInt(m_sub.elements[1][2]) == 4
            @test BigInt(m_sub.elements[2][1]) == 4
            @test BigInt(m_sub.elements[2][2]) == 4
            @test_throws ErrorException m1 - m_rect # Dimension mismatch
        end

        # Scalar Multiplication
        @testset "Matrix Scalar Multiplication" begin
            scalar_hpi = HighPrecisionInt(3)
            scalar_int = -2

            m_scaled_hpi = scalar_hpi * m1
            @test BigInt(m_scaled_hpi.elements[1][1]) == 3
            @test BigInt(m_scaled_hpi.elements[2][2]) == 12

            m_scaled_int = m2 * scalar_int
            @test BigInt(m_scaled_int.elements[1][1]) == -10
            @test BigInt(m_scaled_int.elements[2][2]) == -16
        end

        # Matrix-Vector Multiplication
        @testset "Matrix-Vector Multiplication" begin
            v_prod = HighPrecisionVector([1, -2]) # 2-element vector, compatible with 2x2 matrix m1
            mv_prod = m1 * v_prod
            # [1*1 + 2*-2, 3*1 + 4*-2] = [1-4, 3-8] = [-3, -5]
            @test BigInt(mv_prod.elements[1]) == -3
            @test BigInt(mv_prod.elements[2]) == -5

            v_prod_rect = HighPrecisionVector([1, 2, 3]) # 3-element vector, compatible with 2x3 matrix m_rect
            mv_prod_rect = m_rect * v_prod_rect
            # [1*1 + 2*2 + 3*3, 4*1 + 5*2 + 6*3] = [1+4+9, 4+10+18] = [14, 32]
            @test BigInt(mv_prod_rect.elements[1]) == 14
            @test BigInt(mv_prod_rect.elements[2]) == 32

            @test_throws ErrorException m1 * v_prod_rect # Dimension mismatch
        end

        # Matrix-Matrix Multiplication
        @testset "Matrix-Matrix Multiplication" begin
            mm_prod = m1 * m2
            # [[1*5+2*7, 1*6+2*8], [3*5+4*7, 3*6+4*8]]
            # [[5+14, 6+16], [15+28, 18+32]]
            # [[19, 22], [43, 50]]
            @test BigInt(mm_prod.elements[1][1]) == 19
            @test BigInt(mm_prod.elements[1][2]) == 22
            @test BigInt(mm_prod.elements[2][1]) == 43
            @test BigInt(mm_prod.elements[2][2]) == 50

            # Test non-square matrices
            mm_prod_rect = m_rect * m_tall # (2x3) * (3x1) = 2x1
            # [[1*10 + 2*20 + 3*30], [4*10 + 5*20 + 6*30]]
            # [[10 + 40 + 90], [40 + 100 + 180]]
            # [[140], [320]]
            @test BigInt(mm_prod_rect.elements[1][1]) == 140
            @test BigInt(mm_prod_rect.elements[2][1]) == 320

            @test_throws ErrorException m1 * m_tall # Dimension mismatch (2x2 * 3x1)
        end
    end
end
