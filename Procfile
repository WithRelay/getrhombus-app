web: bundle exec passenger start -p $PORT --max-pool-size 3

location ~ ^/(assets)/  {
  root /public;
  gzip_static on; # to serve pre-gzipped version
  expires 1y;
  add_header Cache-Control public;

  add_header ETag "";
  break;
}