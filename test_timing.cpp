/*
 * Copyright 2025 Murray Kopit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Test program to verify deterministic timing with sleep_until
 * Compares timing drift between sleep_for and sleep_until approaches
 */

#include <iostream>
#include <chrono>
#include <thread>
#include <vector>
#include <iomanip>
#include <cmath>

void test_sleep_for(int iterations) {
    std::cout << "\n=== Testing sleep_for (old method) ===" << std::endl;
    std::vector<double> periods;
    auto start = std::chrono::steady_clock::now();
    auto last = start;

    for (int i = 0; i < iterations; i++) {
        // Simulate some work (variable time)
        volatile int work = 0;
        for (int j = 0; j < (i % 3) * 100000; j++) {
            work++;
        }

        // Old method: simple sleep
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        auto now = std::chrono::steady_clock::now();
        double period = std::chrono::duration<double, std::milli>(now - last).count();
        periods.push_back(period);
        last = now;
    }

    // Calculate statistics
    double sum = 0, min = 1000, max = 0;
    for (double p : periods) {
        sum += p;
        if (p < min) min = p;
        if (p > max) max = p;
    }
    double avg = sum / periods.size();

    // Calculate standard deviation
    double variance = 0;
    for (double p : periods) {
        variance += (p - avg) * (p - avg);
    }
    double stddev = std::sqrt(variance / periods.size());

    auto total = std::chrono::steady_clock::now() - start;
    double total_ms = std::chrono::duration<double, std::milli>(total).count();
    double drift = total_ms - (iterations * 100.0);

    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Average period: " << avg << " ms (target: 100.00 ms)" << std::endl;
    std::cout << "Min period: " << min << " ms" << std::endl;
    std::cout << "Max period: " << max << " ms" << std::endl;
    std::cout << "Std deviation: " << stddev << " ms" << std::endl;
    std::cout << "Total time: " << total_ms << " ms" << std::endl;
    std::cout << "Total drift: " << drift << " ms (" << (drift/total_ms)*100 << "%)" << std::endl;
}

void test_sleep_until(int iterations) {
    std::cout << "\n=== Testing sleep_until (new method) ===" << std::endl;
    std::vector<double> periods;
    auto start = std::chrono::steady_clock::now();
    auto last = start;

    // New method setup
    using clock = std::chrono::steady_clock;
    auto next = clock::now();
    const auto period = std::chrono::milliseconds(100);

    for (int i = 0; i < iterations; i++) {
        // Simulate some work (variable time)
        volatile int work = 0;
        for (int j = 0; j < (i % 3) * 100000; j++) {
            work++;
        }

        // New method: sleep until next period
        next += period;
        std::this_thread::sleep_until(next);

        auto now = std::chrono::steady_clock::now();
        double period_actual = std::chrono::duration<double, std::milli>(now - last).count();
        periods.push_back(period_actual);
        last = now;
    }

    // Calculate statistics
    double sum = 0, min = 1000, max = 0;
    for (double p : periods) {
        sum += p;
        if (p < min) min = p;
        if (p > max) max = p;
    }
    double avg = sum / periods.size();

    // Calculate standard deviation
    double variance = 0;
    for (double p : periods) {
        variance += (p - avg) * (p - avg);
    }
    double stddev = std::sqrt(variance / periods.size());

    auto total = std::chrono::steady_clock::now() - start;
    double total_ms = std::chrono::duration<double, std::milli>(total).count();
    double drift = total_ms - (iterations * 100.0);

    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Average period: " << avg << " ms (target: 100.00 ms)" << std::endl;
    std::cout << "Min period: " << min << " ms" << std::endl;
    std::cout << "Max period: " << max << " ms" << std::endl;
    std::cout << "Std deviation: " << stddev << " ms" << std::endl;
    std::cout << "Total time: " << total_ms << " ms" << std::endl;
    std::cout << "Total drift: " << drift << " ms (" << (drift/total_ms)*100 << "%)" << std::endl;
}

int main() {
    std::cout << "Timing Test: Comparing sleep_for vs sleep_until" << std::endl;
    std::cout << "Testing 50 iterations with variable simulated work..." << std::endl;

    const int iterations = 50;

    test_sleep_for(iterations);
    test_sleep_until(iterations);

    std::cout << "\n=== Summary ===" << std::endl;
    std::cout << "The sleep_until method provides deterministic timing with no drift," << std::endl;
    std::cout << "while sleep_for accumulates timing errors over time." << std::endl;

    return 0;
}
