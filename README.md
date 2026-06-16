# Wisecow Kubernetes Deployment

This package contains a complete containerisation and Kubernetes deployment setup for the Wisecow Bash application.

## Files

- `wisecow.sh`: Wisecow application source.
- `Dockerfile`: Builds the app image with `cowsay`, `fortune`, and `netcat`.
- `k8s/`: Kubernetes namespace, deployment, service, ingress, and TLS certificate manifests.
- `k8s/kubearmor-zero-trust-policy.yaml`: KubeArmor zero-trust policy for the Wisecow workload.
- `.github/workflows/ci-cd.yaml`: GitHub Actions pipeline that builds, pushes, and deploys the image.

## Build Locally

```bash
docker build -t wisecow:local .
docker run --rm -p 4499:4499 wisecow:local
```

Open:

```text
http://localhost:4499
```

## Deploy on Minikube

Enable ingress:

```bash
minikube addons enable ingress
```

Install cert-manager:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

Update the deployment image before applying:

```bash
kubectl set image --local -f k8s/deployment.yaml wisecow=ghcr.io/YOUR_GITHUB_USER/YOUR_REPO:latest -o yaml > /tmp/deployment.yaml
mv /tmp/deployment.yaml k8s/deployment.yaml
```

Deploy:

```bash
kubectl apply -k k8s
kubectl -n wisecow rollout status deployment/wisecow
```

Map the local hostname:

```bash
echo "$(minikube ip) wisecow.local" | sudo tee -a /etc/hosts
```

Test TLS:

```bash
curl -k https://wisecow.local
```

## Deploy on Kind

Install an ingress controller for Kind:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Install cert-manager:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

Deploy:

```bash
kubectl apply -k k8s
kubectl -n wisecow rollout status deployment/wisecow
```

Map `wisecow.local` to the ingress address shown by:

```bash
kubectl -n ingress-nginx get service ingress-nginx-controller
```

## CI/CD

The workflow pushes images to GitHub Container Registry:

```text
ghcr.io/<owner>/<repo>:<commit-sha>
ghcr.io/<owner>/<repo>:latest
```

For deployment from GitHub Actions, add this repository secret:

```text
KUBE_CONFIG
```

Its value should be a kubeconfig that can deploy into the target cluster. Without this secret, the deployment job will fail after the image build succeeds.

For Kind or Minikube, run the workflow on a self-hosted GitHub Actions runner that can reach the local cluster, or use a kubeconfig for a reachable remote cluster.

## TLS

The included manifests use cert-manager with a self-signed issuer for local Kind or Minikube testing. For a production domain, replace `issuer-selfsigned.yaml` with a Let's Encrypt `ClusterIssuer`, update `k8s/certificate.yaml` and `k8s/ingress.yaml` to use your real DNS name, and ensure that DNS points to your ingress controller.

## KubeArmor Zero-Trust Policy

The KubeArmor policy applies to pods with:

```text
app=wisecow
```

It uses an allowlist model for process execution and TCP networking. Expected Wisecow binaries such as `/app/wisecow.sh`, `/bin/bash`, `fortune`, `cowsay`, `nc`, `cat`, and `sleep` are allowed. Unexpected process execution inside the container is denied and reported as a policy violation.

Apply the policy with the rest of the manifests:

```bash
kubectl apply -k k8s
```

Generate a test violation:

```bash
POD_NAME=$(kubectl -n wisecow get pods -l app=wisecow -o jsonpath='{.items[0].metadata.name}')
kubectl -n wisecow exec "$POD_NAME" -- /usr/bin/whoami
```

View KubeArmor alerts:

```bash
karmor logs --namespace wisecow --type Alert
```
