#!/usr/bin/env python3
"""
Test script to verify dual layer streaming is working correctly.
"""

import sys
import io
import json
from pathlib import Path

# Add the backend path to test the streaming processor
sys.path.insert(0, '/Users/jesper/Software/atlas/gis-dev/backend')

from atlasco.gis_backend.access.dataset.impl.vector.streaming_processor import TileStreamProcessor
from atlasco.gis_backend.access.dataset.impl.vector.pmtiles_assembler import PMTilesMetadata

def test_dual_layer_streaming():
    """Test that dual layer streaming preserves both layers."""
    
    # Read the streaming output we generated
    with open('streaming_output.pmtiles', 'r') as f:
        stream_content = f.read()
    
    print("=== Stream Content Analysis ===")
    lines = stream_content.strip().split('\n')
    
    # Check header
    if lines[0].startswith('TIPPECANOE_STREAM'):
        print(f"✅ Stream header: {lines[0]}")
    else:
        print(f"❌ Invalid stream header: {lines[0]}")
        return False
    
    # Check metadata
    if lines[1].startswith('metadata:'):
        metadata_json = lines[1][9:].strip()
        metadata = json.loads(metadata_json)
        print(f"✅ Metadata parsed successfully")
        print(f"   Vector layers: {metadata.get('vector_layers', [])}")
        
        vector_layers = metadata.get('vector_layers', [])
        if len(vector_layers) >= 2:
            print(f"✅ Found {len(vector_layers)} vector layers")
            for layer in vector_layers:
                print(f"   - {layer.get('id', 'unknown')}: {layer.get('description', 'no description')}")
        else:
            print(f"❌ Expected 2+ vector layers, found {len(vector_layers)}")
            return False
    else:
        print(f"❌ No metadata found: {lines[1]}")
        return False
    
    # Test the streaming processor
    print("\n=== Testing Streaming Processor ===")
    
    # Create processor
    processor = TileStreamProcessor()
    
    # Create stream from our data
    stream = io.StringIO(stream_content)
    
    # Parse header using the processor
    metadata_obj = processor._parse_stream_header(stream)
    
    if metadata_obj:
        print(f"✅ Processor parsed metadata successfully")
        print(f"   Vector layers: {metadata_obj.vector_layers}")
        
        if len(metadata_obj.vector_layers) >= 2:
            print(f"✅ Processor preserved {len(metadata_obj.vector_layers)} vector layers")
            for layer in metadata_obj.vector_layers:
                print(f"   - {layer.get('id', 'unknown')}: {layer.get('description', 'no description')}")
        else:
            print(f"❌ Processor lost layers: expected 2+, got {len(metadata_obj.vector_layers)}")
            return False
    else:
        print("❌ Processor failed to parse metadata")
        return False
    
    # Test PMTiles metadata JSON generation
    print("\n=== Testing PMTiles Metadata Generation ===")
    
    from atlasco.gis_backend.access.dataset.impl.vector.pmtiles_assembler import PMTilesAssembler
    
    assembler = PMTilesAssembler(metadata_obj)
    json_metadata = assembler._build_metadata_json()
    pmtiles_metadata = json.loads(json_metadata.decode('utf-8'))
    
    print(f"✅ PMTiles metadata generated")
    print(f"   Vector layers in PMTiles: {pmtiles_metadata.get('vector_layers', [])}")
    
    pmtiles_vector_layers = pmtiles_metadata.get('vector_layers', [])
    if len(pmtiles_vector_layers) >= 2:
        print(f"✅ PMTiles preserves {len(pmtiles_vector_layers)} vector layers")
        for layer in pmtiles_vector_layers:
            print(f"   - {layer.get('id', 'unknown')}: {layer.get('description', 'no description')}")
    else:
        print(f"❌ PMTiles lost layers: expected 2+, got {len(pmtiles_vector_layers)}")
        return False
    
    print("\n=== Test Results ===")
    print("✅ All tests passed! Dual layer streaming should work correctly.")
    return True

if __name__ == "__main__":
    success = test_dual_layer_streaming()
    sys.exit(0 if success else 1)