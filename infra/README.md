# Infrastructure

## Structure

```
infra/
├── modules/          # Reusable Terraform modules
│   ├── network/      # VPC, subnets, routing
│   ├── vpn/          # AWS Client VPN endpoint and configuration
│   └── ec2/          # K3s EC2 instance, security groups, IAM roles
├── nonprod/          # Non-production environment
│   └── main.tf       # Environment-specific configuration
└── scripts/          # Helper scripts
    └── generate-vpn-certs.sh  # VPN certificate generation
```

The infrastructure is organized into reusable modules that can be composed for 
different environments. Each module handles a specific piece of infrastructure 
(networking, VPN, compute) and exposes outputs that other modules can consume.

## Setup

### 1. AWS CLI Setup

Install the AWS CLI and configure your credentials:

```bash
# Install AWS CLI (if not already installed)
# Configure AWS credentials
aws configure
```

You'll need to provide:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (use `us-east-2` for this project)
- Default output format (json recommended)

### 2. Generate VPN Certificates

Run the certificate generation script:

```bash
cd scripts
./generate-vpn-certs.sh
```

### 3. Import Certificates to ACM

Import the server and client certificates to AWS Certificate Manager, like so:

```bash
aws acm import-certificate \
  --certificate fileb://scripts/certs/server.crt \
  --private-key fileb://scripts/certs/server.key \
  --certificate-chain fileb://scripts/certs/ca.crt \
  --region us-east-2

aws acm import-certificate \
  --certificate fileb://scripts/certs/client.crt \
  --private-key fileb://scripts/certs/client.key \
  --certificate-chain fileb://scripts/certs/ca.crt \
  --region us-east-2
```

Note the ARNs returned from both commands. Update the `server_certificate_arn` 
and `client_certificate_arn` values in `infra/nonprod/main.tf` with these ARNs.

### 4. Deploy Infrastructure

```bash
cd nonprod
terraform init
terraform apply
```

### 5. Configure VPN Client

After deploying the infrastructure, download the VPN client configuration:

1. Go to AWS Console > **VPC** > **Client VPN endpoints**
2. Select your VPN endpoint
3. Click **Download Client Configuration** to get the `oli.ovpn` file

Then add the following lines to the `oli.ovpn` file:

```
route-nopull
route 10.5.0.0 255.255.0.0
tun-mtu 1400
mssfix 1360
```

Also add the client certificate and key to the file (similar to the `<ca>` 
block already present):

```
<cert>
[contents of ./scripts/certs/client.crt]
</cert>

<key>
[contents of ./scripts/certs/client.key]
</key>
```

These settings:
- `route-nopull`: Prevents the VPN from becoming your default route
- `route 10.5.0.0 255.255.0.0`: Only routes the 10.5.0.0/16 network through the VPN
- `tun-mtu 1400` and `mssfix 1360`: Optimize packet sizes for better performance

### 6. Connect to VPN

```bash
sudo openvpn --config oli.ovpn
```

