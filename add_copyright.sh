#!/bin/bash
# Add copyright header to C++ files

COPYRIGHT="/*
 * Copyright 2025 Murray Kopit
 *
 * Licensed under the Apache License, Version 2.0 (the \"License\");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an \"AS IS\" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */"

# Process each C++ file
for file in src/*.cpp include/*.h tests/*.cpp cooling_control.cpp test_timing.cpp; do
    if [ -f "$file" ]; then
        # Check if file already has copyright
        if ! grep -q "Copyright" "$file"; then
            echo "Adding copyright to $file"
            # Create temp file with copyright + original content
            echo "$COPYRIGHT" > "${file}.tmp"
            echo "" >> "${file}.tmp"
            cat "$file" >> "${file}.tmp"
            mv "${file}.tmp" "$file"
        fi
    fi
done
