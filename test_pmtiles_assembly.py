#!/usr/bin/env python3
"""
Test PMTiles assembly to see what's actually in the generated file.
"""

import json
import struct
import gzip

def read_pmtiles_metadata(filename):
    """Read PMTiles metadata from file."""
    try:
        with open(filename, 'rb') as f:
            # Read magic number and version
            magic = f.read(7)  # "PMTiles"
            version = f.read(1)[0]
            
            print(f"Magic: {magic}")
            print(f"Version: {version}")
            
            if magic != b"PMTiles" or version != 3:
                print("❌ Not a valid PMTiles v3 file")
                return False
            
            # Read header offsets
            root_dir_offset = struct.unpack('<Q', f.read(8))[0]
            root_dir_bytes = struct.unpack('<Q', f.read(8))[0]
            json_metadata_offset = struct.unpack('<Q', f.read(8))[0]
            json_metadata_bytes = struct.unpack('<Q', f.read(8))[0]
            
            print(f"\nHeader info:")
            print(f"  Root dir offset: {root_dir_offset}")
            print(f"  Root dir bytes: {root_dir_bytes}")
            print(f"  JSON metadata offset: {json_metadata_offset}")
            print(f"  JSON metadata bytes: {json_metadata_bytes}")
            
            # Read JSON metadata (may be compressed)
            f.seek(json_metadata_offset)
            json_data = f.read(json_metadata_bytes)
            
            # Try to decompress if it's gzipped
            try:
                if json_data.startswith(b'\x1f\x8b'):  # gzip magic
                    json_data = gzip.decompress(json_data)
                metadata = json.loads(json_data.decode('utf-8'))
            except:
                print("❌ Could not parse JSON metadata")
                return False
            
            print(f"\nJSON Metadata:")
            print(f"  Name: {metadata.get('name', 'unknown')}")
            print(f"  Format: {metadata.get('format', 'unknown')}")
            print(f"  Min zoom: {metadata.get('minzoom', 'unknown')}")
            print(f"  Max zoom: {metadata.get('maxzoom', 'unknown')}")
            
            vector_layers = metadata.get('vector_layers', [])
            print(f"  Vector layers ({len(vector_layers)}):")
            for i, layer in enumerate(vector_layers):
                print(f"    {i+1}. ID: {layer.get('id', 'unknown')}")
                print(f"       Description: {layer.get('description', 'none')}")
                print(f"       Min zoom: {layer.get('minzoom', 'unknown')}")
                print(f"       Max zoom: {layer.get('maxzoom', 'unknown')}")
                print(f"       Fields: {layer.get('fields', {})}")
            
            return metadata
            
    except Exception as e:
        print(f"❌ Error reading PMTiles: {e}")
        return False

def analyze_tile_data(filename):
    """Try to analyze actual tile data."""
    try:
        with open(filename, 'rb') as f:
            # Skip to tile data (simplified - assumes structure)
            # This is a rough approach since PMTiles structure is complex
            f.seek(127)  # Skip header
            
            # For a proper implementation, we'd need to:
            # 1. Parse the root directory to find tile entries
            # 2. Decompress and read individual tiles
            # 3. Parse MVT data to see layers
            
            print(f"\n(Note: Full tile analysis would require implementing PMTiles directory parsing)")
            
    except Exception as e:
        print(f"Error analyzing tiles: {e}")

if __name__ == "__main__":
    import sys
    
    # Test the completely fixed file
    print("=== Testing Completely Fixed PMTiles (should have both layers) ===")
    metadata = read_pmtiles_metadata('test_dual_fixed.pmtiles')
    
    print("\n=== Testing Original PMTiles (should have one layer) ===")
    metadata = read_pmtiles_metadata('test_output.pmtiles')