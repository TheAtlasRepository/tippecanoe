#ifndef S3_WRITER_HPP
#define S3_WRITER_HPP

#include "storage_writer.hpp"

// Legacy S3 writer - now uses the new storage writer API
// This maintains backwards compatibility while using the new flexible backend system

class S3StreamWriter {
public:
    S3StreamWriter(const std::string& s3_url);
    ~S3StreamWriter();
    
    // Initialize the multipart upload
    bool initialize();
    
    // Write data at a specific offset (for PMTiles partial writes)
    bool write_partial(const std::vector<uint8_t>& data, uint64_t offset);
    
    // Write data sequentially (for streaming)
    bool write_sequential(const std::vector<uint8_t>& data);
    
    // Write tile data to specific location in PMTiles structure
    bool write_tile(int z, int x, int y, const std::string& tile_data, uint64_t offset);
    
    // Finalize the upload and complete the multipart upload
    bool finalize();
    
    // Get the total bytes written
    uint64_t get_bytes_written() const;
    
    // Check if the writer is ready for operations
    bool is_ready() const;
    
    // Get last error message
    const std::string& get_last_error() const;

private:
    std::unique_ptr<StorageWriter> storage_writer_;
    std::string s3_url_;
    std::vector<std::string> part_etags_;
    bool multipart_started_;
    int next_part_number_;
};

// Factory function to create S3 writer from URL
std::unique_ptr<S3StreamWriter> create_s3_writer_from_url(const std::string& s3_url);

// Utility function to check if a URL is an S3 URL
bool is_s3_url(const std::string& url);

#endif