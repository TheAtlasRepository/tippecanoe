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

# Check files exist
if [ ! -f "$GEOMETRY_FGB" ]; then
    echo "Error: $GEOMETRY_FGB not found"
    exit 1
fi

# Get feature count
FEATURE_COUNT=$(ogrinfo -al -so "$GEOMETRY_FGB" 2>/dev/null | grep "Feature Count" | awk '{print $3}')
echo "Dataset: $GEOMETRY_FGB"
echo "Features: $FEATURE_COUNT"
echo ""

# Test 1: Single layer (no centroids at all)
echo "=== Test 1: Single layer (NO dual layers) ==="
rm -f "$OUTPUT_SINGLE"

TIME_START_1=$(date +%s)
./tippecanoe \
  -o "$OUTPUT_SINGLE" \
  -z14 \
  --drop-densest-as-needed \
  --extend-zooms-if-still-dropping \
  --force \
  --quiet \
  "$GEOMETRY_FGB" 2>/dev/null

EXIT_CODE_1=$?
TIME_END_1=$(date +%s)
ELAPSED_1=$((TIME_END_1 - TIME_START_1))

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

TIME_START_2=$(date +%s)
./tippecanoe \
  --dual-layers \
  --geometry-layer=default \
  --centroid-layer=centroids \
  --centroid-input="$CENTROID_FGB" \
  -o "$OUTPUT_DUAL_PRELOAD" \
  -z14 \
  --drop-densest-as-needed \
  --extend-zooms-if-still-dropping \
  --force \
  --quiet \
  "$GEOMETRY_FGB" 2>/dev/null

EXIT_CODE_2=$?
TIME_END_2=$(date +%s)
ELAPSED_2=$((TIME_END_2 - TIME_START_2))

if [ $EXIT_CODE_2 -eq 0 ]; then
    SIZE_2=$(ls -lh "$OUTPUT_DUAL_PRELOAD" | awk '{print $5}')
    echo "✅ Success in ${ELAPSED_2}s ($(echo "scale=2; $FEATURE_COUNT / $ELAPSED_2" | bc) features/sec)"
    echo "   Output size: $SIZE_2"
else
    echo "❌ Failed with exit code $EXIT_CODE_2"
    exit 1
fi

echo ""

# Test 3: Dual layers WITHOUT pre-loaded centroids (calculate on-the-fly)
echo "=== Test 3: Dual layers WITHOUT pre-loaded centroids (calculated) ==="
rm -f "$OUTPUT_DUAL_CALC"

TIME_START_3=$(date +%s)
./tippecanoe \
  --dual-layers \
  --geometry-layer=default \
  --centroid-layer=centroids \
  -o "$OUTPUT_DUAL_CALC" \
  -z14 \
  --drop-densest-as-needed \
  --extend-zooms-if-still-dropping \
  --force \
  --quiet \
  "$GEOMETRY_FGB" 2>/dev/null

EXIT_CODE_3=$?
TIME_END_3=$(date +%s)
ELAPSED_3=$((TIME_END_3 - TIME_START_3))

if [ $EXIT_CODE_3 -eq 0 ]; then
    SIZE_3=$(ls -lh "$OUTPUT_DUAL_CALC" | awk '{print $5}')
    echo "✅ Success in ${ELAPSED_3}s ($(echo "scale=2; $FEATURE_COUNT / $ELAPSED_3" | bc) features/sec)"
    echo "   Output size: $SIZE_3"
else
    echo "❌ Failed with exit code $EXIT_CODE_3"
    exit 1
fi

echo ""
echo "=== Comparison Summary ==="
echo ""
printf "%-50s %10s %15s %10s\n" "Mode" "Time" "Features/sec" "Size"
printf "%-50s %10s %15s %10s\n" "----" "----" "------------" "----"
printf "%-50s %8ss %15s %10s\n" "Single layer (no centroids)" "$ELAPSED_1" "$(echo "scale=2; $FEATURE_COUNT / $ELAPSED_1" | bc)" "$SIZE_1"
printf "%-50s %8ss %15s %10s\n" "Dual layers WITH pre-loaded centroids" "$ELAPSED_2" "$(echo "scale=2; $FEATURE_COUNT / $ELAPSED_2" | bc)" "$SIZE_2"
printf "%-50s %8ss %15s %10s\n" "Dual layers WITHOUT pre-loaded (calculated)" "$ELAPSED_3" "$(echo "scale=2; $FEATURE_COUNT / $ELAPSED_3" | bc)" "$SIZE_3"
echo ""

# Find the fastest
FASTEST=$ELAPSED_1
FASTEST_NAME="Single layer"
if [ $ELAPSED_2 -lt $FASTEST ]; then
    FASTEST=$ELAPSED_2
    FASTEST_NAME="Dual with pre-loaded"
fi
if [ $ELAPSED_3 -lt $FASTEST ]; then
    FASTEST=$ELAPSED_3
    FASTEST_NAME="Dual calculated"
fi

echo "Fastest: $FASTEST_NAME (${FASTEST}s)"
echo ""

# Compare overhead of dual layers
DUAL_CALC_OVERHEAD=$((ELAPSED_3 - ELAPSED_1))
DUAL_PRELOAD_OVERHEAD=$((ELAPSED_2 - ELAPSED_1))

if [ $DUAL_CALC_OVERHEAD -gt 0 ]; then
    CALC_PERCENT=$(echo "scale=1; $DUAL_CALC_OVERHEAD * 100 / $ELAPSED_1" | bc)
    echo "Dual layers (calculated) overhead: +${DUAL_CALC_OVERHEAD}s (+${CALC_PERCENT}%)"
elif [ $DUAL_CALC_OVERHEAD -lt 0 ]; then
    CALC_PERCENT=$(echo "scale=1; -$DUAL_CALC_OVERHEAD * 100 / $ELAPSED_1" | bc)
    echo "Dual layers (calculated) is FASTER: ${DUAL_CALC_OVERHEAD}s (${CALC_PERCENT}%)"
else
    echo "Dual layers (calculated) has no overhead"
fi

if [ $DUAL_PRELOAD_OVERHEAD -gt 0 ]; then
    PRELOAD_PERCENT=$(echo "scale=1; $DUAL_PRELOAD_OVERHEAD * 100 / $ELAPSED_1" | bc)
    echo "Dual layers (pre-loaded) overhead: +${DUAL_PRELOAD_OVERHEAD}s (+${PRELOAD_PERCENT}%)"
elif [ $DUAL_PRELOAD_OVERHEAD -lt 0 ]; then
    PRELOAD_PERCENT=$(echo "scale=1; -$DUAL_PRELOAD_OVERHEAD * 100 / $ELAPSED_1" | bc)
    echo "Dual layers (pre-loaded) is FASTER: ${DUAL_PRELOAD_OVERHEAD}s (${PRELOAD_PERCENT}%)"
else
    echo "Dual layers (pre-loaded) has no overhead"
fi

# Clean up
rm -f "$OUTPUT_SINGLE" "$OUTPUT_DUAL_PRELOAD" "$OUTPUT_DUAL_CALC"
