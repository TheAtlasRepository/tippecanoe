#ifndef FLATGEOBUF_HPP
#define FLATGEOBUF_HPP

#include <map>
#include <string>
#include "geometry.hpp"

void parse_flatgeobuf(std::vector<struct serialization_state> *sst, const char *s, size_t len, int layer, std::string layername);
void load_centroid_flatgeobuf(const char *s, size_t len, std::map<unsigned long long, drawvec> &centroids);

#endif