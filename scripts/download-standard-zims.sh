#!/bin/bash
set -e

# Destination relative to the install location
LIBRARY_DIR="/opt/disaster-pi/files/zim-library"
mkdir -p "$LIBRARY_DIR"
cd "$LIBRARY_DIR"

echo "--- Starting Survival Library Download ---"
echo "Target Directory: $LIBRARY_DIR"
echo "Note: These files are large. Ensure you have ~50GB free."

# Function to download with resume capability
download_zim() {
    url="$1"
    filename=$(basename "$url")
    echo "Processing: $filename"
    if [ -f "$filename" ]; then
        echo " - File exists. Checking integrity/resuming..."
    fi
    # wget -c resumes downloads if they get interrupted
    wget -c "$url"
}

# 1. WikiMed (Medical Encyclopedia) - CRITICAL
# The "maxi" version includes images, vital for medical diagnosis.
download_zim "https://download.kiwix.org/zim/wikipedia/wikipedia_en_medicine_maxi_2026-01.zim"

# 2. iFixit (Repair Manuals)
# Essential for repairing radios, generators, and tools.
download_zim "https://download.kiwix.org/zim/ifixit/ifixit_en_all_2025-12.zim"

# 3. Appropedia (Sustainability & Appropriate Technology)
# The gold standard for "rebuilding civilization" (water filtration, solar, farming).
download_zim "https://download.kiwix.org/zim/other/appropedia_en_all_maxi_2025-11.zim"

# 4. Wikibooks (Textbooks)
# Contains "Outdoor Survival", "First Aid", "Knots", etc.
download_zim "https://download.kiwix.org/zim/wikibooks/wikibooks_en_all_maxi_2025-10.zim"

# Optional: StackExchange (DIY & Home Improvement)
# Uncomment if you have space
# download_zim "https://download.kiwix.org/zim/stack_exchange/diy.stackexchange.com_en_all_2025-12.zim"

echo "--- Downloads Complete ---"
echo "Restart the Kiwix container to index new files:"
echo "docker restart disaster-pi-kiwix-1"