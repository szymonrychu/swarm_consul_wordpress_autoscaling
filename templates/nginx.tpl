upstream wordpress {
  least_conn;
  {{range service "wordpress"}}server {{.Address}}:{{.Port}} max_fails=3 fail_timeout=60 weight=1;
  {{else}}server 127.0.0.1:65535;{{end}}
}


server {
  listen                      80;
  server_name                 .demo.org;
  return 301                  https://$host$request_uri;
}

server {
  listen                      443 ssl;
  server_name                 .demo.org;
  ssl_certificate             /etc/nginx/ssl/demo.org.crt;
  ssl_certificate_key         /etc/nginx/ssl/demo.org.key;
  ssl_trusted_certificate     /etc/nginx/ssl/ca.crt;
  ssl_dhparam                 /etc/nginx/ssl/dhparam.pem;
  ssl_session_timeout         1d;
  ssl_session_cache           shared:SSL:50m;
  ssl_session_tickets         off;
  add_header                  Strict-Transport-Security "max-age=31557600; includeSubDomains";
  add_header                  X-Content-Type-Options "nosniff" always;
  add_header                  X-Xss-Protection "1; mode=block" always;
  add_header                  P3P CP="Allowed";
  add_header                  X-Frame-Options "SAMEORIGIN" always;
  add_header                  Referrer-Policy "origin-when-cross-origin" always;

  ssl_protocols               TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers                 ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS;
  ssl_prefer_server_ciphers   on;
  ssl_stapling                on;
  ssl_stapling_verify         on;

  # based on https://gist.github.com/ethanpil/1bfd01a817a8198369efec5c4cde6628
  # Deny access to wp-content folders for suspicious files
  location ~* ^/(wp-content)/(.*?)\.(zip|gz|tar|bzip2|7z)\$ { deny all; }
  location ~ ^/wp-content/uploads/sucuri { deny all; }
  location ~ ^/wp-content/updraft { deny all; }
  location ~* /wp-content/uploads/nginx-helper/ { deny all; }
  location ~* /(?:uploads|files)/.*\.php\$ { deny all; }
  location ~* ^/wp-content/uploads/.*.(html|htm|shtml|php|js|swf|css)$ { deny all; }
  location ~* /wp-content/.*\.php\$ { deny all; }
  location ~* /wp-includes/.*\.php\$ { deny all; }
  location ~* /(?:uploads|files|wp-content|wp-includes)/.*\.php\$ { deny all; }
  location ~* /(\.|wp-config\.php|wp-config\.txt|changelog\.txt|readme\.txt|readme\.html|license\.txt) { deny all; }
  location ~* \.(engine|inc|info|make|module|profile|test|po|sh|.*sql|theme|tpl(\.php)?|xtmpl)\$|^(\..*|Entries.*|Repository|Root|Tag|Template)\$|\.php_ { return 444; }
  location ~* \.(pl|cgi|py|sh|lua)\$ { return 444; }
  location ~* (w00tw00t) { return 444; }

  # based on official nginx documentation
  # Deny access to wp-login.php
  location /wp-login.php {
      limit_req zone=one burst=1 nodelay;
  }

  location / {
    proxy_pass                http://wordpress/wordpress/;
    proxy_http_version        1.1;
    proxy_read_timeout        1200;
    proxy_connect_timeout     240;

    proxy_set_header          Host              $host;
    proxy_set_header          X-Real-IP         $remote_addr;
    proxy_set_header          X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header          X-Forwarded-Host  $host;
    proxy_set_header          X-Forwarded-Port  8443;
    proxy_set_header          X-Forwarded-Proto $scheme;
    proxy_redirect            off;
    client_max_body_size      100M;
  }
}
