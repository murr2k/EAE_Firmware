/*
 * EAE Firmware - Test Runner
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#include <gtest/gtest.h>

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}