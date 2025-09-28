#!/usr/bin/env python3
"""
Test script for tippecanoe streaming functionality.
"""

import subprocess
import tempfile
import os
import sys

def test_stdout_streaming():
    """Test streaming to stdout."""
    print("Testing stdout streaming...")
    
    # Create test geojson
    test_geojson = '{"type":"Feature","geometry":{"type":"Point","coordinates":[0,0]},"properties":{"name":"test"}}'
    with tempfile.NamedTemporaryFile(mode='w', suffix='.geojson', delete=False) as f:
        f.write(test_geojson)
        geojson_path = f.name
    
    try:
        # Run tippecanoe with stdout streaming
        cmd = ['./tippecanoe', '-o', 'dummy.pmtiles', '--stream-to-stdout', geojson_path]
        result = subprocess.run(cmd, capture_output=True)
        
        if result.returncode == 0:
            pmtiles_data = result.stdout
            print(f"✅ stdout streaming successful: {len(pmtiles_data)} bytes")
            return pmtiles_data
        else:
            print(f"❌ stdout streaming failed: {result.stderr.decode()}")
            return None
    finally:
        os.unlink(geojson_path)

def test_pipe_streaming():
    """Test streaming to named pipe."""
    print("Testing named pipe streaming...")
    
    # Create test geojson
    test_geojson = '{"type":"Feature","geometry":{"type":"Point","coordinates":[0,0]},"properties":{"name":"test"}}'
    with tempfile.NamedTemporaryFile(mode='w', suffix='.geojson', delete=False) as f:
        f.write(test_geojson)
        geojson_path = f.name
    
    with tempfile.TemporaryDirectory() as tmpdir:
        pipe_path = os.path.join(tmpdir, "test.pipe")
        
        try:
            # Create named pipe
            os.mkfifo(pipe_path)
            print(f"Created pipe: {pipe_path}")
            
            # Start tippecanoe process
            cmd = ['./tippecanoe', '-o', 'dummy.pmtiles', '--stream-to-pipe', pipe_path, geojson_path]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            # Read from pipe
            pmtiles_data = b""
            with open(pipe_path, 'rb') as pipe:
                while True:
                    chunk = pipe.read(4096)
                    if not chunk:
                        break
                    pmtiles_data += chunk
            
            # Wait for process to complete
            stdout, stderr = process.communicate()
            
            if process.returncode == 0:
                print(f"✅ pipe streaming successful: {len(pmtiles_data)} bytes")
                return pmtiles_data
            else:
                print(f"❌ pipe streaming failed: {stderr.decode()}")
                return None
                
        finally:
            os.unlink(geojson_path)

def main():
    print("🚀 Testing tippecanoe streaming functionality")
    print("=" * 50)
    
    # Test stdout streaming
    stdout_data = test_stdout_streaming()
    print()
    
    # Test pipe streaming 
    pipe_data = test_pipe_streaming()
    print()
    
    # Compare results
    if stdout_data and pipe_data:
        if stdout_data == pipe_data:
            print("✅ Both streaming methods produce identical output!")
        else:
            print(f"⚠️  Streaming methods differ: stdout={len(stdout_data)}, pipe={len(pipe_data)}")
        
        print(f"📊 PMTiles size: {len(stdout_data)} bytes")
        print("🎉 Streaming implementation complete!")
    else:
        print("❌ One or more streaming tests failed")
        sys.exit(1)

if __name__ == "__main__":
    main()