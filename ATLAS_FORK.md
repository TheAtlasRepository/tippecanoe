# Atlas Custom Tippecanoe Fork

This is the Atlas fork of [Felt's Tippecanoe](https://github.com/felt/tippecanoe) with custom performance improvements and features specific to the Atlas GIS platform.

**Repository:** https://github.com/TheAtlasRepository/tippecanoe

## Custom Features

### PMTiles Streaming Support

We've added streaming support for PMTiles format to enable continuous tile generation and upload without buffering entire tilesets in memory. This is particularly useful for very large datasets.

**Key enhancements:**
- Stream tiles directly to S3 or other storage backends
- Reduced memory footprint for large tileset generation
- Real-time progress monitoring via stderr

### Dual Layer Support

Automatic generation of dual layers (geometry + centroids) in a single pass for improved rendering performance at different zoom levels.

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

Our changes are focused on:
1. **Streaming output** - `--stream-tiles` flag for continuous tile emission
2. **PMTiles format improvements** - Better support for PMTiles v3 specification
3. **Dual layer generation** - Automatic centroid layer creation
4. **Performance tuning** - Optimizations for our specific use cases

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
