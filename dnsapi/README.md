# Custom DNS API integration in ACME setup

This directory contains custom DNS API provider scripts used by `acme.sh` to automate DNS TXT challenges for SSL certificate issuing.

## How it works

1. **`acme-init.sh` Orchestration**:
   - The script [acme-init.sh](file:///D:/Development/pert-estimating-composer/acme-init.sh) reads the `DNS_PROVIDER` variable from `.env` (defaults to `manual`).
   - If a provider is set (e.g. `DNS_PROVIDER=dns_timeweb`), it checks if the corresponding script `dnsapi/dns_timeweb.sh` exists locally.
   - If it doesn't exist, `acme-init.sh` automatically runs the appropriate initializer (e.g., `./dnsapi/dns_timeweb/init.sh`) to download it.

2. **Initialization Subdirectories**:
   - For custom DNS providers, there is a dedicated subdirectory (like `./dnsapi/dns_timeweb/`) that contains:
     - `init.sh` — A script to download the required DNS API script from the correct fork repository (e.g., `https://github.com/YniRus/acme.sh_dnsapi_timeweb.cloud`) and save it to the parent `./dnsapi/` directory.
     - `README.md` — Instructions explaining the provider setup.

3. **Generic Docker Mounting & Custom Entrypoint**:
   - In [docker-compose.acme.yml](file:///D:/Development/pert-estimating-composer/docker-compose.acme.yml), the `./dnsapi` host directory is mounted to `/custom_dnsapi` inside the container.
   - The entrypoint in docker-compose points to the script [acme-entrypoint.sh](file:///D:/Development/pert-estimating-composer/acme-entrypoint.sh) (which inside the container is mounted at `/acme-entrypoint.sh`).
   - This script runs when the container starts, copies all custom `dns_*.sh` scripts from `/custom_dnsapi/` into `/root/.acme.sh/dnsapi/`, and then chains execution to the original container entrypoint (`/entrypoint.sh`).
   - This keeps [docker-compose.acme.yml](file:///D:/Development/pert-estimating-composer/docker-compose.acme.yml) generic, simple, and free of any hardcoded references.

## Adding a New DNS Provider

If you want to use another custom DNS API provider that is not built into `acme.sh` natively:
1. Place the custom script `dns_<provider_name>.sh` in this `./dnsapi/` directory.
2. Update your `.env` file to set:
   ```env
   DNS_PROVIDER=dns_<provider_name>
   ```
3. Pass any required environment variables for your DNS API provider in the `.env` file (e.g., token, secret keys, etc.).
4. Run:
   ```bash
   ./acme-init.sh domain.com
   ```
