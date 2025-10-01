# Atlas Custom Tippecanoe Fork

This is the Atlas fork of [Felt's Tippecanoe](https://github.com/felt/tippecanoe) with custom performance improvements and features specific to the Atlas GIS platform.

**Repository:** https://github.com/TheAtlasRepository/tippecanoe

## Custom Features

### Dual Layer Generation (Active)

**Currently in use by Atlas GIS**

Automatic generation of dual layers (geometry + centroids) in a single pass for improved rendering performance at different zoom levels. This is the primary feature we're actively using from this fork.

**Benefits:**
- Single tippecanoe invocation generates both geometry and centroid layers
- Improved map rendering performance at lower zoom levels
- Centroids are pre-calculated and optimized for point representation of polygons

### PMTiles Streaming Support (Experimental)

⚠️ **Note: PMTiles streaming has limitations and is not currently used in production**

We've experimented with streaming support for PMTiles format, but discovered fundamental limitations with the PMTiles file format that make true streaming impractical:

**The PMTiles Problem:**
- PMTiles requires a complete directory/header at the start of the file
- The header contains metadata about all tiles (offsets, sizes, zoom ranges)
- This means you must know all tile information before writing the file
- True streaming (write-as-you-generate) is not possible without buffering all tiles first

**Why This Matters:**
For very large datasets (millions of features), tippecanoe must:
1. Generate all tiles into memory or temporary storage
2. Build the complete tile directory
3. Write the PMTiles file with header + directory + tiles

This defeats the purpose of streaming and causes memory/disk pressure for large datasets.

**Future Alternatives Under Consideration:**

1. **Individual Tile Files (MBTiles/Directory structure)**
   - Store each tile as a separate file: `{z}/{x}/{y}.pbf`
   - Can stream directly to S3 or storage backend
   - No buffering required, true streaming possible
   - Used by many tile servers (tegola, martin)

2. **Custom Tile Archive Format**
   - Design our own streaming-friendly format
   - Write tiles as they're generated with minimal metadata
   - Build index separately or dynamically

3. **MBTiles with Streaming Writes**
   - SQLite-based MBTiles format
   - Can insert tiles as generated without buffering
   - Well-supported format but requires SQLite

**Current Status:** We're using standard PMTiles output (non-streaming) and focusing on the dual layer generation feature which provides the most value.

### Performance Optimizations

Various performance improvements for handling large vector datasets with millions of features.

## Integration with Atlas GIS

This fork is integrated as a git submodule in the main gis-dev repository. See the [integration documentation](https://github.com/TheAtlasRepository/gis-dev/blob/main/docs/tippecanoe-integration.md) for details on:
- How to build and use this fork locally
- How binaries are published for production use
- Development workflow

## Building

### Local Development

```bash
make clean && make -j$(nproc)
```

### Docker Build

```bash
docker build -t tippecanoe:latest .
```

The Dockerfile uses a multi-stage build to produce a minimal runtime image with just the compiled binaries.

## Changes from Upstream

Our primary changes focus on:
1. **Dual layer generation** - Automatic centroid layer creation alongside geometry (actively used)
2. **Centroid calculation improvements** - Better handling of different geometry types
3. **Performance tuning** - Optimizations for our specific use cases
4. **Experimental streaming** - Initial streaming work (see limitations above, not in production)

We try to keep this fork as close to upstream as possible and regularly sync with Felt's repository.

## Testing

Test files are included in the repository:
- `test.geojson` - Basic test data
- `simple_test.py` - Basic functionality tests
- `test_pmtiles_assembly.py` - PMTiles assembly tests
- `test_streaming_fix.py` - Streaming mode tests

Run tests:
```bash
python3 simple_test.py
```

## Updating from Upstream

To sync with the latest upstream changes from Felt:

```bash
# Add upstream remote if not already added
git remote add upstream https://github.com/felt/tippecanoe.git

# Fetch upstream changes
git fetch upstream

# Merge upstream main into our fork
git merge upstream/main

# Resolve any conflicts
# Test thoroughly
# Push to our fork
git push origin main
```

## Contributing

Improvements to this fork should:
1. Be tested locally first
2. Include test cases if adding new features
3. Update documentation
4. Not break existing Atlas GIS functionality

## License

Tippecanoe is licensed under the BSD 2-Clause License. See [LICENSE.md](LICENSE.md) for details.

## Contact

For questions about this fork or its integration with Atlas GIS, please contact the Atlas development team or open an issue in this repository.
