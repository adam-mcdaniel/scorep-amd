#include <stdio.h>
#include <hip/hip_runtime.h>
#include <numeric>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include <thread>
#include <vector>
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


template<typename T, uint64_t iter>
__global__ void vectorAdd(T *buf, const uint64_t n) {
    const uint64_t gid = hipBlockDim_x * hipBlockIdx_x + hipThreadIdx_x;
    const uint64_t nThreads  = gridDim.x * blockDim.x;
    const int64_t nEntriesPerThread = n / nThreads;
    const uint64_t maxOffset = nEntriesPerThread * nThreads;

    T *ptr;
    const T y = (T) 1;

    ptr = &buf[gid];
    T x = (T) 2;

    // For every vector element, its doing one read
    // For every vector element, its doing 2 * iter flops
    // For every thread, its doing one write
    
    for (uint64_t offset = 0; offset < maxOffset; offset += nThreads) {
        for (uint64_t j = 0; j < iter; j++) {
            x = ptr[offset] * x + y;
        }
    }
    ptr[0] = -x;
}

template<typename T, uint64_t iter>
float getPerf(const uint64_t n, const int numExperiments, int blockSize, int gridSize, int numThreads, void *mem_a, float time) {
    // hipEvent_t start, stop;
    // hipEventCreate(&start);
    // hipEventCreate(&stop);
    // hipEventRecord(start);
    for (int run = 0; run < numExperiments; run++) {
        hipLaunchKernelGGL((vectorAdd<T, iter>), dim3(gridSize), dim3(blockSize), 0, 0, (T *)mem_a, n);
    }
    // hipEventRecord(stop);
    // hipEventSynchronize(stop);
    // hipEventElapsedTime(&time, start, stop);
    // hipEventDestroy(start);
    // hipEventDestroy(stop);
    return 0.0;
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


template<typename T, uint64_t iter>
void bench(int n, int n_experiments, void *mem_a) {
    // const uint64_t n = std::stoll(argv[1]);
    // const uint64_t n_experiments = std::stoll(argv[2]);

    // std::cout << "Vector length: " << n << std::endl;
    // std::cout << "N experiments: " << n_experiments << std::endl;


    int factor = std::max(n / 134217728, 1);
    int blockSize = 256;
    int gridSize = 228 * 128 * factor;
    int numThreads = gridSize * blockSize;
    uint64_t flops = n * iter * 2;

    // std::cout << "Number of iterations: " << iter << std::endl;
    // std::cout << "Grid size: " << gridSize << std::endl;
    // std::cout << "Block size: " << blockSize << std::endl;
    // std::cout << "Number of threads: " << gridSize * blockSize << std::endl;
    // std::cout << "Number of elements per thread: " << n / (gridSize * blockSize) << std::endl;
    // std::cout << "Expected number of FP64 Flops: " << flops << std::endl << std::endl;

    float time;
    // hipLaunchKernelGGL((vectorAdd<T, iter>), dim3(gridSize), dim3(blockSize), 0, 0, (T *)mem_a, n);
    time = getPerf<T, iter>(n, n_experiments, blockSize, gridSize, numThreads, mem_a, time);
    // hipDeviceSynchronize();
    
    // std::cout << std::endl;

    // float avg_runtime = time / n_experiments;
    // // std::cout << "Average runtime: " << avg_runtime << " ms" << std::endl;
    
    // std::string filename;
    // float avg_runtime_seconds = avg_runtime / 1000;
    // double tflops = static_cast<double>(flops) / 1e12;

    // std::cout << "Arithmetic Intensity: " << static_cast<float>(flops) / (8 * (n + numThreads)) << std::endl;
    // std::cout << "Average runtime: " << avg_runtime << " ms" << std::endl;
    // std::cout << "Average runtime: " << avg_runtime_seconds << " secs" << std::endl;
    // std::cout << "tera ops/sec: " << tflops / avg_runtime_seconds << std::endl;
}

// Llama a `bench` en una GPU específica
template<typename T, uint64_t iter>
void bench_gpu(int device_id, int n, int n_experiments, void *mem_a) {
    hipSetDevice(device_id);  // Select GPU
    // std::cout << "\n==== Running on GPU " << device_id << " ====" << std::endl;
    bench<T, iter>(n, n_experiments, mem_a);
}

template<typename T, uint64_t iter>
void bench_gpus(int devices[], int num_devices, int n, int n_experiments, void *mem_a) {
    std::vector<std::thread> threads;
    for (int i = 0; i < num_devices; ++i) {
        threads.emplace_back(bench_gpu<T, iter>, devices[i], n, n_experiments, mem_a);
    }
    for (auto& t : threads) {
        t.join();
    }
}

template<typename T, uint64_t iter>
void bench_gpus_for_duration(int devices[], int num_devices, int n, int duration_ms, void *mem_a) {
    std::vector<std::thread> threads;
    for (int i = 0; i < num_devices; ++i) {
        threads.emplace_back([=]() {
            auto start = std::chrono::high_resolution_clock::now();
            auto remaining_time = duration_ms;
            
            while (true) {
                remaining_time = duration_ms - std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::high_resolution_clock::now() - start).count();

                auto n_experiments = remaining_time <= 1000 ? 5
                    : (remaining_time <= 100 ? 20 : 800);

                bench_gpu<T, iter>(devices[i], n, n_experiments, mem_a);
                hipDeviceSynchronize(); // Ensure the GPU has completed before checking duration
                auto now = std::chrono::high_resolution_clock::now();
                if (std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count() >= duration_ms) {
                    std::cout << "GPU " << devices[i] << " completed its duration." << std::endl;
                    break;
                }
            }
        });
    }
    for (auto& t : threads) {
        t.join();
    }
}

void step1() {
    std::cout << "Step 1: sleeping..." << std::endl;
    std::chrono::milliseconds timespan(1000);
    std::this_thread::sleep_for(timespan);
    std::cout << "Step 1 completed." << std::endl;
}

void step2() {
    std::cout << "Step 2: Running benchmark..." << std::endl;
    // This is where the benchmark would be run
    // For example, you could call bench<double, 1000>(argc, argv);
    // bench<double, 350>(134217728, 20000);
    void *mem_a;
    hipMalloc(&mem_a, 134217728 * sizeof(double)); // Allocate memory for
    bench_gpu<double, 100>(0, 134217728, 10000, mem_a);
    std::cout << "Step 2 completed." << std::endl;
    hipFree(mem_a); // Free the allocated memory
}

void step3() {
    std::cout << "Step 3: sleeping..." << std::endl;
    std::chrono::milliseconds timespan(1000);
    std::this_thread::sleep_for(timespan);
    std::cout << "Step 3 completed." << std::endl;
}

void step4() {
    std::cout << "Step 4: Running benchmark on multiple GCDs..." << std::endl;
    int devices[] = {0, 1}; // Example device IDs, adjust based on your system
    int num_devices = sizeof(devices) / sizeof(devices[0]);
    void *mem_a;
    hipMalloc(&mem_a, 134217728 * sizeof(double)); // Allocate memory for the vector
    bench_gpus<double, 100>(
        devices,     // Array of device IDs
        num_devices, // Number of devices
        134217728,   // Vector length
        10000,      // Number of experiments
        mem_a
    );
    std::cout << "Step 4 completed." << std::endl;
    hipFree(mem_a); // Free the allocated memory
    // run_dummy_kernel();
}

void step5() {
    std::cout << "Step 5: sleeping..." << std::endl;
    std::chrono::milliseconds timespan(2000);
    std::this_thread::sleep_for(timespan);
    std::cout << "Step 5 completed." << std::endl;
}

void step6() {
    std::cout << "Step 6: Running benchmark on multiple GPUs..." << std::endl;
    int devices[] = {0, 2}; // Example device IDs, adjust based on your system
    int num_devices = sizeof(devices) / sizeof(devices[0]);
    void *mem_a;
    hipMalloc(&mem_a, 134217728 * sizeof(double)); // Allocate memory for the vector
    bench_gpus<double, 100>(
        devices,     // Array of device IDs
        num_devices, // Number of devices
        134217728,   // Vector length
        10000,      // Number of experiments
        mem_a
    );
    std::cout << "Step 6 completed." << std::endl;
    hipFree(mem_a); // Free the allocated memory
}


// const double IDLE_COMPUTE_RATIO = 0.1; // Ratio of idle to compute time

int main(int argc, char* argv[]) {
    const uint64_t VECTOR_SIZE = 134217728;

    void *mem_a;
    hipMalloc(&mem_a, (VECTOR_SIZE + 10) * sizeof(double));

    // Get the idle compute ratio from the environment variable or use a default value
    uint32_t idle_period_ms = 1000; // Default value
    uint32_t active_period_ms = 1000; // Default value for active period
    const char* idle_period_ms_env = std::getenv("IDLE_PERIOD_MS");
    const char* active_period_ms_env = std::getenv("ACTIVE_PERIOD_MS");

    if (idle_period_ms_env) {
        idle_period_ms = std::stod(idle_period_ms_env);
    } else {
        std::cout << "Environment variable IDLE_PERIOD_MS not set, using default value: " << idle_period_ms << std::endl;
    }
    std::cout << "Idle period: " << idle_period_ms << " milliseconds." << std::endl;

    if (active_period_ms_env) {
        active_period_ms = std::stoul(active_period_ms_env);
    } else {
        std::cout << "Environment variable ACTIVE_PERIOD_MS not set, using default value: " << active_period_ms << std::endl;
    }
    std::cout << "Active period: " << active_period_ms << " milliseconds." << std::endl;

    int devices[] = {0};
    int num_devices = sizeof(devices) / sizeof(devices[0]);

    std::cout << "Warm-up phase: Running benchmark on multiple GPUs..." << std::endl;
    bench_gpus_for_duration<double, 1>(
        devices,                      // Device ID
        num_devices,                  // Number of devices
        VECTOR_SIZE,                  // Vector length
        active_period_ms,             // Duration in milliseconds
        mem_a
    );
    std::cout << "Done with warm-up." << std::endl;

    long long total_runtime_ms = 0;
    long long idle_time_ms = 0;

    auto start_time = std::chrono::high_resolution_clock::now();
    uint64_t i = 1;
    while (true) {
        // Get the start time
        std::cout << "Iteration " << i << ": Running benchmark..." << std::endl;
        auto start = std::chrono::high_resolution_clock::now();
        std::cout << "Start time: " 
                  << std::chrono::duration_cast<std::chrono::milliseconds>(start.time_since_epoch()).count() 
                  << " milliseconds since epoch." << std::endl;
        bench_gpus_for_duration<double, 1>(
            devices,                      // Device ID
            num_devices,                  // Number of devices
            VECTOR_SIZE,                  // Vector length
            active_period_ms,             // Duration in milliseconds
            mem_a
        );
        // hipDeviceSynchronize(); // Ensure the GPU has completed before moving to the next iteration
        // The duration
        // long long duration_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        //               std::chrono::system_clock::now() - std::chrono::system_clock::from_time_t(start_time)).count();

        // Print the start and end times
        auto end = std::chrono::high_resolution_clock::now();

        std::chrono::duration<double, std::milli> duration = end - start;
        std::cout << "Duration time for iteration " << i << ": " 
                  << duration.count() << " milliseconds." << std::endl;

        // Sleep for idle time
        std::chrono::milliseconds idle_time(idle_period_ms);
        std::cout << "Sleeping for " << idle_time.count() << " milliseconds..." << std::endl;
        std::this_thread::sleep_for(idle_time);
        // idle_time_ms += idle_time.count();

        // Get the time since the start of the program
        auto now = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> total_duration = now - start_time;
        
        if (total_duration.count() >= 60000) { // Stop after 60 seconds
            std::cout << "Total runtime exceeded 60 seconds, stopping..." << std::endl;
            break;
        }

        i++;
    }
    // std::time_t end_program = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    // total_runtime_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
    //     std::chrono::system_clock::from_time_t(end_program) - std::chrono::system_clock::from_time_t(start_time)).count();
    // std::cout << "Total runtime: " << total_runtime_ms << " milliseconds." << std::endl;
    // std::cout << "Total idle time: " << idle_time_ms << " milliseconds." << std::endl;
    // std::cout << "Total active time: " << (total_runtime_ms - idle_time_ms) << " milliseconds." << std::endl;
    // std::cout << "Active/Total Ratio: " << static_cast<double>(total_runtime_ms - idle_time_ms) / total_runtime_ms << std::endl;
    std::cout << "Benchmark completed." << std::endl;
    hipFree(mem_a);
    return 0;
}