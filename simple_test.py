#!/usr/bin/env python3
"""
Simple test to check streaming output structure.
"""

import json

def test_streaming_output():
    """Test the streaming output structure."""
    
    with open('streaming_output.pmtiles', 'r') as f:
        lines = f.readlines()
    
    print("=== Analyzing Streaming Output ===")
    
    # Check header
    header = lines[0].strip()
    print(f"Header: {header}")
    
    # Check metadata
    metadata_line = lines[1].strip()
    if metadata_line.startswith('metadata:'):
        metadata_json = metadata_line[9:].strip()
        metadata = json.loads(metadata_json)
        
        print(f"\nMetadata structure:")
        print(f"  Format: {metadata.get('format')}")
        print(f"  Min zoom: {metadata.get('min_zoom')}")
        print(f"  Max zoom: {metadata.get('max_zoom')}")
        
        vector_layers = metadata.get('vector_layers', [])
        print(f"  Vector layers ({len(vector_layers)}):")
        for i, layer in enumerate(vector_layers):
            print(f"    {i+1}. ID: {layer.get('id', 'unknown')}")
            print(f"       Description: {layer.get('description', 'none')}")
            print(f"       Min zoom: {layer.get('minzoom', 'unknown')}")
            print(f"       Max zoom: {layer.get('maxzoom', 'unknown')}")
    
    # Count tiles
    tile_count = 0
    for line in lines[2:]:
        if line.strip() == "TILE":
            tile_count += 1
    
    print(f"\nTotal tiles in stream: {tile_count}")
    
    return metadata if 'metadata' in locals() else None

if __name__ == "__main__":
    metadata = test_streaming_output()
    
    if metadata:
        vector_layers = metadata.get('vector_layers', [])
        expected_layers = ['buildings', 'building_centroids']
        
        print(f"\n=== Layer Analysis ===")
        found_layers = [layer.get('id') for layer in vector_layers]
        print(f"Expected layers: {expected_layers}")
        print(f"Found layers: {found_layers}")
        
        for expected in expected_layers:
            if expected in found_layers:
                print(f"✅ {expected}")
            else:
                print(f"❌ {expected} - MISSING")
        
        if len(found_layers) >= 2:
            print(f"\n✅ SUCCESS: Found {len(found_layers)} layers in stream")
        else:
            print(f"\n❌ FAILURE: Expected 2+ layers, found {len(found_layers)}")