#include <stdio.h>
#include <hip/hip_runtime.h>
#include <numeric>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include <thread>
#include <vector>


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

                auto n_experiments = remaining_time <= 1000 ? 5 : 800;

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

int main(int argc, char* argv[]) {
    const uint64_t VECTOR_SIZE = 134217728;

    // Allocate memory for the vector
    void *mem_a;
    hipMalloc(&mem_a, (VECTOR_SIZE + 10) * sizeof(double));

    // Get the idle compute ratio from the environment variable or use a default value
    uint32_t idle_period_ms = 1000; // Default value
    uint32_t active_period_ms = 1000; // Default value for active period
    const char* idle_period_ms_env = std::getenv("IDLE_PERIOD_MS");
    const char* active_period_ms_env = std::getenv("ACTIVE_PERIOD_MS");

    // Parse the environment variable for the idle period if it exists
    if (idle_period_ms_env) {
        idle_period_ms = std::stod(idle_period_ms_env);
    } else {
        std::cout << "Environment variable IDLE_PERIOD_MS not set, using default value: " << idle_period_ms << std::endl;
    }
    std::cout << "Idle period: " << idle_period_ms << " milliseconds." << std::endl;

    // Parse the environment variable for the active period if it exists
    if (active_period_ms_env) {
        active_period_ms = std::stoul(active_period_ms_env);
    } else {
        std::cout << "Environment variable ACTIVE_PERIOD_MS not set, using default value: " << active_period_ms << std::endl;
    }
    std::cout << "Active period: " << active_period_ms << " milliseconds." << std::endl;

    // Define the GPUs to be used
    int devices[] = {0};
    int num_devices = sizeof(devices) / sizeof(devices[0]);

    // Warm-up phase: Run the benchmark on all specified GPUs for a short duration
    std::cout << "Warm-up phase: Running benchmark on multiple GPUs..." << std::endl;
    bench_gpus_for_duration<double, 64>(
        devices,                      // Device ID
        num_devices,                  // Number of devices
        VECTOR_SIZE,                  // Vector length
        active_period_ms,             // Duration in milliseconds
        mem_a
    );
    std::cout << "Done with warm-up." << std::endl;

    long long total_runtime_ms = 0;
    long long idle_time_ms = 0;

    auto program_start_time = std::chrono::high_resolution_clock::now();
    uint64_t i = 1;
    while (true) {
        std::cout << "Iteration " << i << ": Running benchmark..." << std::endl;
        // Get the start time
        auto start = std::chrono::high_resolution_clock::now();
        std::cout << "Start time: " 
                  << std::chrono::duration_cast<std::chrono::milliseconds>(start.time_since_epoch()).count() 
                  << " milliseconds since epoch." << std::endl;
        
        // Run the benchmark on the specified GPUs for the active period
        bench_gpus_for_duration<double, 64>(
            devices,                      // Device ID
            num_devices,                  // Number of devices
            VECTOR_SIZE,                  // Vector length
            active_period_ms,             // Duration in milliseconds
            mem_a
        );

        // Get the end time
        auto end = std::chrono::high_resolution_clock::now();

        // Subtract start time from end time to get the duration
        // that it took to run the microbenchmark experiments for one
        // active period
        std::chrono::duration<double, std::milli> duration = end - start;
        std::cout << "Duration time for iteration " << i << ": " 
                  << duration.count() << " milliseconds." << std::endl;

        // Sleep for idle time
        std::chrono::milliseconds idle_time(idle_period_ms);
        std::cout << "Sleeping for " << idle_time.count() << " milliseconds..." << std::endl;
        std::this_thread::sleep_for(idle_time);

        // Get the current time and calculate the total runtime of the program
        auto now = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> total_duration = now - program_start_time;
        
        if (total_duration.count() >= 60000) { // Stop after 60 seconds
            std::cout << "Total runtime exceeded 60 seconds, stopping..." << std::endl;
            break;
        }

        i++;
    }

    std::cout << "Benchmark completed." << std::endl;
    hipFree(mem_a);
    return 0;
}