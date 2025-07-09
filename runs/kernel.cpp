#include <stdio.h>
#include <hip/hip_runtime.h>
#include <numeric>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cmath>
/*
#ifndef iter
#endif


template<typename T, int iter>
__global__ void vectorAdd(T *buf, const uint64_t n) {
    const uint32_t gid = hipBlockDim_x * hipBlockIdx_x + hipThreadIdx_x;
    const uint32_t nThreads  = gridDim.x * blockDim.x;
    const int nEntriesPerThread = n / nThreads;
    const uint64_t maxOffset = nEntriesPerThread * nThreads;

    T *ptr;
    const T y = (T) 1.0;

    ptr = &buf[gid];
    T x = (T) 2.0;

    // For every vector element, its doing one read
    // For every vector element, its doing 2 * iter flops
    // For every thread, its doing one write
    
    for (uint64_t offset = 0; offset < maxOffset; offset += nThreads) {
        for (int j = 0; j < iter; j++) {
            x = ptr[offset] * x + y;
        }
    }
    ptr[0] = -x;
}

float getPerf(const uint64_t n, const int numExperiments, int blockSize, int gridSize, int numThreads, void *mem_a, float time) {
    hipEvent_t start, stop;
    hipEventCreate(&start);
    hipEventCreate(&stop);
    hipEventRecord(start);
    for (int run = 0; run < numExperiments; run++) {
        
        hipLaunchKernelGGL((vectorAdd<double, iter>), dim3(gridSize), dim3(blockSize), 0, 0, (double *)mem_a, n);

    }
    hipEventRecord(stop);
    hipEventSynchronize(stop);
    hipEventElapsedTime(&time, start, stop);
    hipEventDestroy(start);
    hipEventDestroy(stop);
    return time;
}



int main(int argc, char* argv[]) {
    const uint64_t n = std::stoll(argv[1]);
    const uint64_t n_experiments = std::stoll(argv[2]);

    std::cout << "Vector length: " << n << std::endl;
    std::cout << "N experiments: " << n_experiments << std::endl;

    void *mem_a;
    hipMalloc(&mem_a, n * sizeof(double));

    int factor = n / 134217728;
    int blockSize = 256;
    int gridSize = 228 * 128 * factor;
    int numThreads = gridSize * blockSize;
    uint64_t flops = n * iter * 2;

    std::cout << "Number of iterations: " << iter << std::endl;
    std::cout << "Grid size: " << gridSize << std::endl;
    std::cout << "Block size: " << blockSize << std::endl;
    std::cout << "Number of threads: " << gridSize * blockSize << std::endl;
    std::cout << "Number of elements per thread: " << n / (gridSize * blockSize) << std::endl;
    std::cout << "Expected number of FP64 Flops: " << flops << std::endl << std::endl;

    float *runtimes;
    runtimes = (float *)malloc(n_experiments * sizeof(float));
    float time;
    hipLaunchKernelGGL((vectorAdd<double, iter>), dim3(gridSize), dim3(blockSize), 0, 0, (double *)mem_a, n);
    hipDeviceSynchronize();
    time = getPerf(n, n_experiments, blockSize, gridSize, numThreads, mem_a, time);
    
    std::cout << std::endl;

    float avg_runtime = time / n_experiments;
    std::cout << "Average runtime: " << avg_runtime << " ms" << std::endl;
    
    std::string filename;
    float avg_runtime_seconds = avg_runtime / 1000;
    double tflops = static_cast<double>(flops) / 1e12;

    std::cout << "Arithmetic Intensity: " << static_cast<float>(flops) / (8 * (n + numThreads)) << std::endl;
    std::cout << "Average runtime: " << avg_runtime << " ms" << std::endl;
    std::cout << "Average runtime: " << avg_runtime_seconds << " secs" << std::endl;
    std::cout << "TFLOPS/sec: " << tflops / avg_runtime_seconds << std::endl;

    hipFree(mem_a);

    return 0;
}

*/

#include <stdio.h>
#include <hip/hip_runtime.h>
#include <numeric>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cmath>


template<typename T, int iter>
__global__ void vectorAdd(T *buf, const uint64_t n) {
    const uint32_t gid = hipBlockDim_x * hipBlockIdx_x + hipThreadIdx_x;
    const uint32_t nThreads  = gridDim.x * blockDim.x;
    const int nEntriesPerThread = n / nThreads;
    const uint64_t maxOffset = nEntriesPerThread * nThreads;

    T *ptr;
    const T y = (T) 1;

    ptr = &buf[gid];
    T x = (T) 2;

    // For every vector element, its doing one read
    // For every vector element, its doing 2 * iter flops
    // For every thread, its doing one write
    
    for (uint64_t offset = 0; offset < maxOffset; offset += nThreads) {
        for (int j = 0; j < iter; j++) {
            x = ptr[offset] * x + y;
        }
    }
    ptr[0] = -x;
}

template<typename T, int iter>
float getPerf(const uint64_t n, const int numExperiments, int blockSize, int gridSize, int numThreads, void *mem_a, float time) {
    hipEvent_t start, stop;
    hipEventCreate(&start);
    hipEventCreate(&stop);
    hipEventRecord(start);
    for (int run = 0; run < numExperiments; run++) {
        hipLaunchKernelGGL((vectorAdd<T, iter>), dim3(gridSize), dim3(blockSize), 0, 0, (T *)mem_a, n);
    }
    hipEventRecord(stop);
    hipEventSynchronize(stop);
    hipEventElapsedTime(&time, start, stop);
    hipEventDestroy(start);
    hipEventDestroy(stop);
    return time;
}


__global__ void dummy_kernel(float *result) {
    float x = threadIdx.x;
    for (int i = 0; i < 1e8; ++i) {
        x += 0.1f;
        x *= 0.9f;
        x -= 0.1f;
        x /= 0.9f;
    }
    *result = x; // Store the result to avoid optimization removal
    // printf("Dummy kernel executed by thread %d, result: %f\n", threadIdx.x, x);
}

void run_dummy_kernel() {
    std::cout << "Running dummy kernel to warm up the GPU..." << std::endl;
    // Use all the available threads to run a dummy kernel
    int blockSize = 256;
    // int gridSize = (hipGetDeviceProperties(0)->maxThreadsPerBlock + blockSize - 1) / blockSize;
    int gridSize = 512; // Adjusted for MI250X, can be tuned based on the device properties
    float *d_result;
    hipMalloc(&d_result, sizeof(float));
    hipLaunchKernelGGL(dummy_kernel, dim3(gridSize), dim3(blockSize), 0, 0, d_result);
    hipDeviceSynchronize();
    std::cout << "Dummy kernel completed." << std::endl;
    std::cout << "Result of dummy kernel: " << *d_result << std::endl;
    std::cout << " (not used, just to ensure the kernel runs)" << std::endl;
}


template<typename T, int iter>
void bench(int n, int n_experiments) {
    // const uint64_t n = std::stoll(argv[1]);
    // const uint64_t n_experiments = std::stoll(argv[2]);

    std::cout << "Vector length: " << n << std::endl;
    std::cout << "N experiments: " << n_experiments << std::endl;

    void *mem_a;
    hipMalloc(&mem_a, n * sizeof(T));

    int factor = n / 134217728;
    int blockSize = 256;
    int gridSize = 228 * 128 * factor;
    int numThreads = gridSize * blockSize;
    uint64_t flops = n * iter * 2;

    std::cout << "Number of iterations: " << iter << std::endl;
    std::cout << "Grid size: " << gridSize << std::endl;
    std::cout << "Block size: " << blockSize << std::endl;
    std::cout << "Number of threads: " << gridSize * blockSize << std::endl;
    std::cout << "Number of elements per thread: " << n / (gridSize * blockSize) << std::endl;
    std::cout << "Expected number of FP64 Flops: " << flops << std::endl << std::endl;

    float time;
    hipLaunchKernelGGL((vectorAdd<T, iter>), dim3(gridSize), dim3(blockSize), 0, 0, (T *)mem_a, n);
    hipDeviceSynchronize();
    time = getPerf<T, iter>(n, n_experiments, blockSize, gridSize, numThreads, mem_a, time);
    
    std::cout << std::endl;

    float avg_runtime = time / n_experiments;
    std::cout << "Average runtime: " << avg_runtime << " ms" << std::endl;
    
    std::string filename;
    float avg_runtime_seconds = avg_runtime / 1000;
    double tflops = static_cast<double>(flops) / 1e12;

    std::cout << "Arithmetic Intensity: " << static_cast<float>(flops) / (8 * (n + numThreads)) << std::endl;
    std::cout << "Average runtime: " << avg_runtime << " ms" << std::endl;
    std::cout << "Average runtime: " << avg_runtime_seconds << " secs" << std::endl;
    std::cout << "tera ops/sec: " << tflops / avg_runtime_seconds << std::endl;

    hipFree(mem_a);
}


void step1() {
    std::cout << "Step 1: sleeping..." << std::endl;
    std::chrono::milliseconds timespan(2000);
    std::this_thread::sleep_for(timespan);
    std::cout << "Step 1 completed." << std::endl;
}

void step2() {
    std::cout << "Step 2: Running benchmark..." << std::endl;
    // This is where the benchmark would be run
    // For example, you could call bench<double, 1000>(argc, argv);
    bench<double, 350>(134217728, 20000);
    std::cout << "Step 2 completed." << std::endl;
}

void step3() {
    std::cout << "Step 3: sleeping..." << std::endl;
    std::chrono::milliseconds timespan(2000);
    std::this_thread::sleep_for(timespan);
    std::cout << "Step 3 completed." << std::endl;
}

void step4() {
    run_dummy_kernel();
}

void step5() {
    std::cout << "Step 5: sleeping..." << std::endl;
    std::chrono::milliseconds timespan(2000);
    std::this_thread::sleep_for(timespan);
    std::cout << "Step 5 completed." << std::endl;
}

int main(int argc, char* argv[]) {
    step1();
    step2();
    step3();
    step4();
    step5();
    return 0;
}