#!/bin/bash
set -e

echo "=== Testing Dual Layer Generation with Debug Info ==="

# Test files
GEOMETRY_FGB="tests/centroids/default.fgb"
CENTROID_FGB="tests/centroids/centroids.fgb"
OUTPUT_PMTILES="/tmp/test_dual_layers.pmtiles"

# Check files exist
if [ ! -f "$GEOMETRY_FGB" ]; then
    echo "Error: $GEOMETRY_FGB not found"
    exit 1
fi

if [ ! -f "$CENTROID_FGB" ]; then
    echo "Error: $CENTROID_FGB not found"
    exit 1
fi

echo "Geometry file: $GEOMETRY_FGB"
echo "Centroid file: $CENTROID_FGB"
echo "Output: $OUTPUT_PMTILES"
echo ""

# Remove old output if exists
rm -f "$OUTPUT_PMTILES"

echo "Running tippecanoe with dual layers..."
echo "Command: ./tippecanoe \\"
echo "  --dual-layers \\"
echo "  --geometry-layer=default \\"
echo "  --centroid-layer=centroids \\"
echo "  --centroid-input=$CENTROID_FGB \\"
echo "  -o $OUTPUT_PMTILES \\"
echo "  -z20 \\"
echo "  --force \\"
echo "  $GEOMETRY_FGB"
echo ""

# Run tippecanoe with dual layers
./tippecanoe \
  --dual-layers \
  --geometry-layer=default \
  --centroid-layer=centroids \
  --centroid-input="$CENTROID_FGB" \
  -o "$OUTPUT_PMTILES" \
  -z20 \
  --force \
  "$GEOMETRY_FGB"

if [ $? -eq 0 ]; then
    echo ""
    echo "=== SUCCESS ==="
    echo "Output created: $OUTPUT_PMTILES"
    ls -lh "$OUTPUT_PMTILES"
else
    echo ""
    echo "=== FAILED ==="
    exit 1
fi
