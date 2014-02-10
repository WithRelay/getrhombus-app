location ~ ^/(assets)/  {
  root /public;
  gzip_static on; # to serve pre-gzipped version
  expires 1y;
  add_header Cache-Control public;

  add_header ETag "";
  break;
}