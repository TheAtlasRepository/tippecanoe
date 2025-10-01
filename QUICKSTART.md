# Tippecanoe Development Quick Start

Quick reference for working with the Atlas Tippecanoe fork.

**Repository:** https://github.com/TheAtlasRepository/tippecanoe

## Make Changes

```bash
# Navigate to tippecanoe submodule
cd /Users/jesper/Software/atlas/gis-dev/tippecanoe

# Make your changes to source files
# Edit main.cpp, serial.cpp, etc.

# Build locally to test
make clean && make -j$(nproc)

# Test the binary
./tippecanoe --version
./tippecanoe -o test.pmtiles test.geojson
```

## Test in Docker Locally

```bash
# From gis-dev root
cd /Users/jesper/Software/atlas/gis-dev

# Rebuild tippecanoe image
docker compose -f docker-compose.tippecanoe.yml build --no-cache

# Restart development environment to pick up changes
make upd
```

## Commit and Push

```bash
# In tippecanoe submodule
cd tippecanoe
git add .
git commit -m "feat: improve streaming performance"
git push origin main

# Update submodule reference in gis-dev
cd ..
git add tippecanoe
git commit -m "chore: update tippecanoe submodule"
git push
```

## Trigger Production Build

Once pushed to the tippecanoe repository, GitHub Actions in the gis-dev repository will automatically build and publish binaries to S3 when you push the updated submodule reference.

You can also manually trigger the build:
1. Go to https://github.com/TheAtlasRepository/gis-dev/actions
2. Select "Build and Publish Tippecanoe"
3. Click "Run workflow"

## Common Issues

### "tippecanoe not found" in worker

```bash
# Rebuild everything
docker compose -f docker-compose.tippecanoe.yml build --no-cache
make upd
```

### Submodule not initialized

```bash
git submodule update --init --recursive
```

### Changes not picked up

```bash
# Clear docker cache
docker system prune -a
# Rebuild from scratch
make upd
```

## File Locations

- Source code: `tippecanoe/*.cpp`, `tippecanoe/*.hpp`
- Dockerfile: `tippecanoe/Dockerfile`
- CI workflow: `.github/workflows/build-tippecanoe.yml`
- Backend integration: `backend/atlasco/gis_backend/access/dataset/impl/vector/tippecanoe.py`
- Tile generation: `backend/atlasco/gis_backend/access/dataset/impl/vector/generate_tiles.py`

## Helpful Commands

```bash
# Build tippecanoe only
docker compose -f docker-compose.tippecanoe.yml build

# Build and run development environment
make upd

# View tippecanoe logs in worker
docker compose -p gis-dev logs -f task-worker | grep tippecanoe

# Check tippecanoe version in worker
docker compose -p gis-dev exec task-worker tippecanoe --version

# Test tippecanoe manually in worker
docker compose -p gis-dev exec task-worker bash
# Inside container:
tippecanoe -o /tmp/test.pmtiles -zg /path/to/test.geojson
```

## Production Deployment

To use a new tippecanoe version in production:

1. Ensure binaries are published to S3 (check GitHub Actions)
2. Update `TIPPECANOE_VERSION` in backend/Dockerfile:
   ```dockerfile
   ARG TIPPECANOE_VERSION=2.79.1  # Change this
   ```
3. Rebuild and deploy backend images through your normal deployment process
