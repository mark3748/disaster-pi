#!/bin/bash
set -e

# Destination relative to the install location
LIBRARY_DIR="/opt/disaster-pi/files/zim-library"
mkdir -p "$LIBRARY_DIR"
cd "$LIBRARY_DIR"

echo "--- Starting Survival Library Download ---"
echo "Target Directory: $LIBRARY_DIR"
echo "Note: These files are large. Ensure you have ~20GB free." # Changed to ~20GB based on standard files, ~14GB with a little headroom.

# Function to download with resume capability
download_zim() {
	[[ -z "$1" ]] && return 1
	local url="$1"
	local filename
	filename=$(basename "$url") || return 1
	local sha_url="${url}.sha256"

	echo "Processing: $filename"

	# 1. Grab the checksum file first (they are tiny)
	wget -q "$sha_url" -O "${filename}.sha256"

	# 2. Download/Resume the ZIM
	# -c resumes, --retry-connrefused handles flaky networks
	wget -c --retry-connrefused --tries=10 "$url"

	# 3. Verify Integrity
	echo "Verifying integrity..."
	# Kiwix sha256 files usually contain the filename, so we can use sha256sum -c
	if sha256sum -c "${filename}.sha256" >/dev/null 2>&1; then
		echo " - [SUCCESS] $filename is valid."
		rm "${filename}.sha256" # Clean up the checksum file
	else
		echo " - [ERROR] $filename failed checksum! Suggest deleting and re-downloading."
		return 1
	fi
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

# 5. ArchWiki (Linux & Open Source Software Documentation)
# Vital for troubleshooting and maintaining Linux systems, like Disaster Pi itself. At ~30MB, there's no excuse not to have it.
download_zim "https://download.kiwix.org/zim/other/archlinux_en_all_maxi_2025-09.zim"

# Optional: StackExchange (DIY & Home Improvement)
# Uncomment if you have space
# download_zim "https://download.kiwix.org/zim/stack_exchange/diy.stackexchange.com_en_all_2025-12.zim"

echo "--- Downloads Complete ---"
echo "Restart the Kiwix container to index new files:"
echo "docker restart disaster-pi-kiwix-1"
