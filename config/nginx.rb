location ~ ^/(assets)/  {
  root /public;
  gzip_static on;
  expires max;
  add_header Cache-Control public;

  add_header ETag "";
  break;
}