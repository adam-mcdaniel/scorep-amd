// scorep hipcc -fno-openmp -g rocblas_gemm.cpp -lrocblas -o rocmgemm
// [oscarh@login04.frontier rocblasgemm-benchmark]$ cat rocblas_gemm.cpp
#include <unistd.h>
#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <hip/hip_runtime.h>
#include <rocblas/rocblas.h>


using namespace std;


// #define FP16MM


const char* rocblasGetErrorString(rocblas_status status)
{
    switch(status)
    {
        case rocblas_status_success: return "rocblas_status_success";
        case rocblas_status_invalid_handle: return "rocblas_status_invalid_handle";
        case rocblas_status_not_implemented: return "rocblas_status_not_implemented";
        case rocblas_status_invalid_pointer: return "rocblas_status_invalid_pointer";
        case rocblas_status_invalid_size: return "rocblas_status_invalid_size";
        case rocblas_status_memory_error: return "rocblas_status_memory_error";
        case rocblas_status_internal_error: return "rocblas_status_internal_error";
    }
    return "unknown error";
}


// Convenience function for checking HIP runtime API results
// can be wrapped around any runtime API call. No-op in release builds.
inline
hipError_t checkHip(hipError_t result)
{
  if (result != hipSuccess) {
    fprintf(stderr, "HIP Runtime Error: %s\n", hipGetErrorString(result));
    assert(result == hipSuccess);
  }
  return result;
}


inline
rocblas_status checkRocblas(rocblas_status result)
{
  if (result != rocblas_status_success) {
    fprintf(stderr, "ROCblas Runtime Error: %s\n", rocblasGetErrorString(result));
    assert(result == rocblas_status_success);
  }
  return result;
}


// Fill the array A(nr_rows_A, nr_cols_A) with random numbers on CPU
void CPU_fill_rand(float *A, int nr_rows_A, int nr_cols_A) {
	int a=1;


    for(int i = 0; i < nr_rows_A * nr_cols_A; i++){
		A[i] = (float)rand()/(float)(RAND_MAX/a);
	}
}


int main(int argc, char ** argv){

  char version[2000];
  rocblas_get_version_string(version, sizeof(version));
  cout << "rocblas version: " << version << endl;

  int min_m_k_n = 2;
  int max_m_k_n = 4096*4;
  // int max_m_k_n = 4096;
  int repeats = 5;
  int verbose = 1;


#ifndef FP16MM
  cout << "\nrocblasSgemm test result:\n" << endl;
#else
  cout << "\nrocblasHgemm test result:\n" << endl;
#endif
  
  if(verbose)
    cout << "running with"
	<< " min_m_k_n: " << min_m_k_n
	<< " max_m_k_n: " << max_m_k_n
	<< " repeats: " << repeats
	<< endl;


  rocblas_status stat;
  rocblas_handle handle;


  checkRocblas(rocblas_create_handle(&handle));


  if(verbose) cout << "allocating device variables" << endl;
  
  // Allocate 3 arrays on CPU
  
  float *h_A = (float *)malloc(max_m_k_n * max_m_k_n * sizeof(float));
  float *h_B = (float *)malloc(max_m_k_n * max_m_k_n * sizeof(float));
  float *h_C = (float *)malloc(max_m_k_n * max_m_k_n * sizeof(float));
  
  CPU_fill_rand(h_A, max_m_k_n, max_m_k_n);
  CPU_fill_rand(h_B, max_m_k_n, max_m_k_n);
  CPU_fill_rand(h_C, max_m_k_n, max_m_k_n);

  #ifndef FP16MM
    // Allocate 3 arrays on GPU
    float *d_A, *d_B, *d_C;
    hipMalloc(&d_A, max_m_k_n * max_m_k_n * sizeof(float));
    hipMalloc(&d_B, max_m_k_n * max_m_k_n * sizeof(float));
    hipMalloc(&d_C, max_m_k_n * max_m_k_n * sizeof(float));
    
    hipMemcpy(d_A,h_A,max_m_k_n * max_m_k_n * sizeof(float),hipMemcpyHostToDevice);
    hipMemcpy(d_B,h_B,max_m_k_n * max_m_k_n * sizeof(float),hipMemcpyHostToDevice);
    hipMemcpy(d_C,h_C,max_m_k_n * max_m_k_n * sizeof(float),hipMemcpyHostToDevice);
    
    int lda, ldb, ldc, m, n, k;
    const float alf = 1.0f;
    const float bet = 0.0f;
    const float *alpha = &alf;
    const float *beta = &bet;
  
#else
    
  	__half *d_A, *d_B, *d_C;
    hipMalloc(&d_A, max_m_k_n * max_m_k_n * sizeof(__half));
    hipMalloc(&d_B, max_m_k_n * max_m_k_n * sizeof(__half));
    hipMalloc(&d_C, max_m_k_n * max_m_k_n * sizeof(__half));
    
    if (d_A == NULL || d_B == NULL || d_C == NULL) {
      cerr << "hipMalloc failed" << endl;
      exit(1);
    }

    for (int i = 0; i < max_m_k_n * max_m_k_n; i++) {
      d_A[i] = approx_float_to_half(h_A[i]);
  	  d_B[i] = approx_float_to_half(h_B[i]);
  	  d_C[i] = approx_float_to_half(h_C[i]);
    }
    
    int lda, ldb, ldc, m, n, k;
    const __half alf = approx_float_to_half(1.0);
    const __half bet = approx_float_to_half(0.0);
    const __half *alpha = &alf;
    const __half *beta = &bet;
	
#endif
  
  hipEvent_t start, stop;
  hipEventCreate(&start);
  hipEventCreate(&stop);


  for(int size = min_m_k_n; size <= max_m_k_n; size=size*2){
    double sum = 0.0;
    for(int rep = 0; rep < repeats; rep++){
      hipEventRecord(start, 0);
	  m=n=k=size;
	  lda = m;
	  ldb = k;
	  ldc = m;
#ifndef FP16MM
    stat = rocblas_sgemm(handle, rocblas_operation_none, rocblas_operation_none, m, n, k, alpha, d_A, lda, d_B, ldb, beta, d_C, ldc);
#else
    stat = rocblas_hgemm(handle, rocblas_operation_none, rocblas_operation_none, m, n, k, alpha, d_A, lda, d_B, ldb, beta, d_C, ldc);
#endif
      hipEventRecord(stop,0);
      hipEventSynchronize(stop);
      if(stat != rocblas_status_success){
	cerr << "rocblasSgemm failed" << endl;
	exit(1);
      }
      assert(!hipGetLastError());
      
      float elapsed;
      hipEventElapsedTime(&elapsed, start, stop);
      elapsed /= 1000.0f;
      sum += elapsed;
    }
#ifndef FP16MM	
  cout << "float32: size "
#else
  cout << "float16: size "
#endif
  << size << " average: " << sum/repeats << " s "<< endl;


  }


  // Free GPU memory
  cout << "Freeing device memory A" << endl;
  assert(hipFree(d_A) == HIP_SUCCESS);
  cout << "Freeing device memory B" << endl;
  assert(hipFree(d_B) == HIP_SUCCESS);
  cout << "Freeing device memory D" << endl;
  assert(hipFree(d_C) == HIP_SUCCESS);


  // // Free CPU memory
  // cout << "Freeing host memory A" << endl;
  // free(h_A);
  // cout << "Freeing host memory B" << endl;
  // free(h_B);
  // cout << "Freeing host memory C" << endl;
  // free(h_C);

  cout << "Destroying rocblas handle" << endl;
  checkRocblas(rocblas_destroy_handle(handle));
  cout << "Done." << endl;
  
  exit(0);
}
