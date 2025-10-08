#!/bin/bash
set -e

echo "=== Full Performance Comparison ==="
echo ""

# Test files
GEOMETRY_FGB="tests/centroids/default.fgb"
CENTROID_FGB="tests/centroids/centroids.fgb"
OUTPUT_SINGLE="/tmp/test_single_layer.pmtiles"
OUTPUT_DUAL_PRELOAD="/tmp/test_dual_with_centroids.pmtiles"
OUTPUT_DUAL_CALC="/tmp/test_dual_calculated.pmtiles"

# Zoom level for testing (higher = more tiles, better performance comparison)
MAX_ZOOM=17

# Check files exist
if [ ! -f "$GEOMETRY_FGB" ]; then
    echo "Error: $GEOMETRY_FGB not found"
    exit 1
fi

# Get feature count
FEATURE_COUNT=$(ogrinfo -al -so "$GEOMETRY_FGB" 2>/dev/null | grep "Feature Count" | awk '{print $3}')
echo "Dataset: $GEOMETRY_FGB"
echo "Features: $FEATURE_COUNT"
echo "Max Zoom: $MAX_ZOOM"
echo ""

# Test 1: Single layer (no centroids at all)
echo "=== Test 1: Single layer (NO dual layers) ==="
rm -f "$OUTPUT_SINGLE"

TIME_START_1=$(date +%s.%N)
./tippecanoe \
  -o "$OUTPUT_SINGLE" \
  -z$MAX_ZOOM \
  --drop-densest-as-needed \
  --extend-zooms-if-still-dropping \
  --force \
  --quiet \
  "$GEOMETRY_FGB" 2>/dev/null

EXIT_CODE_1=$?
TIME_END_1=$(date +%s.%N)
ELAPSED_1=$(echo "$TIME_END_1 - $TIME_START_1" | bc)

if [ $EXIT_CODE_1 -eq 0 ]; then
    SIZE_1=$(ls -lh "$OUTPUT_SINGLE" | awk '{print $5}')
    echo "✅ Success in ${ELAPSED_1}s ($(echo "scale=2; $FEATURE_COUNT / $ELAPSED_1" | bc) features/sec)"
    echo "   Output size: $SIZE_1"
else
    echo "❌ Failed with exit code $EXIT_CODE_1"
    exit 1
fi

echo ""

# Test 2: Dual layers WITH pre-loaded centroids
echo "=== Test 2: Dual layers WITH pre-loaded centroids ==="
rm -f "$OUTPUT_DUAL_PRELOAD"

TIME_START_2=$(date +%s.%N)
./tippecanoe \
  --dual-layers \
  --geometry-layer=default \
  --centroid-layer=centroids \
  --centroid-input="$CENTROID_FGB" \
  -o "$OUTPUT_DUAL_PRELOAD" \
  -z$MAX_ZOOM \
  --drop-densest-as-needed \
  --extend-zooms-if-still-dropping \
  --force \
  --quiet \
  "$GEOMETRY_FGB" 2>/dev/null

EXIT_CODE_2=$?
TIME_END_2=$(date +%s.%N)
ELAPSED_2=$(echo "$TIME_END_2 - $TIME_START_2" | bc)

if [ $EXIT_CODE_2 -eq 0 ]; then
    SIZE_2=$(ls -lh "$OUTPUT_DUAL_PRELOAD" | awk '{print $5}')
    echo "✅ Success in ${ELAPSED_2}s ($(echo "scale=2; $FEATURE_COUNT / $ELAPSED_2" | bc) features/sec)"
    echo "   Output size: $SIZE_2"
else
    echo "❌ Failed with exit code $EXIT_CODE_2"
    exit 1
fi

echo ""

echo ""
echo "=== Comparison Summary ==="
echo ""
printf "%-50s %12s %15s %10s\n" "Mode" "Time" "Features/sec" "Size"
printf "%-50s %12s %15s %10s\n" "----" "----" "------------" "----"
printf "%-50s %10.2fs %15s %10s\n" "Single layer (no centroids)" "$ELAPSED_1" "$(echo "scale=2; $FEATURE_COUNT / $ELAPSED_1" | bc)" "$SIZE_1"
printf "%-50s %10.2fs %15s %10s\n" "Dual layers WITH pre-loaded centroids" "$ELAPSED_2" "$(echo "scale=2; $FEATURE_COUNT / $ELAPSED_2" | bc)" "$SIZE_2"
echo ""

# Find the fastest using bc for float comparison
COMPARISON=$(echo "$ELAPSED_2 < $ELAPSED_1" | bc)
if [ "$COMPARISON" -eq 1 ]; then
    FASTEST=$ELAPSED_2
    FASTEST_NAME="Dual with pre-loaded"
else
    FASTEST=$ELAPSED_1
    FASTEST_NAME="Single layer"
fi

echo "Fastest: $FASTEST_NAME (${FASTEST}s)"
echo ""

# Compare overhead of dual layers
DUAL_PRELOAD_OVERHEAD=$(echo "$ELAPSED_2 - $ELAPSED_1" | bc)
OVERHEAD_IS_POSITIVE=$(echo "$DUAL_PRELOAD_OVERHEAD > 0" | bc)

if [ "$OVERHEAD_IS_POSITIVE" -eq 1 ]; then
    PRELOAD_PERCENT=$(echo "scale=1; $DUAL_PRELOAD_OVERHEAD * 100 / $ELAPSED_1" | bc)
    echo "Dual layers (pre-loaded) overhead: +${DUAL_PRELOAD_OVERHEAD}s (+${PRELOAD_PERCENT}%)"
else
    PRELOAD_PERCENT=$(echo "scale=1; -1 * $DUAL_PRELOAD_OVERHEAD * 100 / $ELAPSED_1" | bc)
    echo "Dual layers (pre-loaded) is FASTER: ${DUAL_PRELOAD_OVERHEAD}s (${PRELOAD_PERCENT}% faster)"
fi

# Clean up
rm -f "$OUTPUT_SINGLE" "$OUTPUT_DUAL_PRELOAD"
