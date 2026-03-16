# External Resources

## Official Documentation

- **User Guide PDF**: [TP-Link Omada SDN Controller User Guide V6.0](https://static.tp-link.com/upload/manual/2025/202511/20251126/1900000685_Omada%20SDN%20Controller_User%20Guide_V6.0%20(1).pdf)
- **Online API Docs**: Accessible from the controller UI at Global View > Settings > Platform Integration > Open API (upper-right corner)
- **TP-Link Support**: [Omada Software Controller Downloads](https://support.omadanetworks.com/us/product/omada-software-controller/)

## Community References

- **bash/curl examples**: [mbentley/omada-api-examples (GitHub Gist)](https://gist.github.com/mbentley/03c198077c81d52cb029b825e9a6dc18) — covers legacy v2 login-based auth, not Open API
- **Home Assistant integration**: [bullitt186/ha-omada-open-api](https://github.com/bullitt186/ha-omada-open-api) — reference implementation using the Open API

## Live Discovery (per-controller)

- **Swagger UI**: `{OMADA_URL}/swagger-ui/index.html`
- **OpenAPI 3.0.1 spec**: `GET {OMADA_URL}/v3/api-docs`

Both are publicly accessible without authentication.
