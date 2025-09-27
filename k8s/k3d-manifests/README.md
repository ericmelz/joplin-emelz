# k3d Manifests for compose-app

How to apply:
```bash
kubectl apply -f all-in-one.yaml
kubectl get pods -n default
kubectl get svc -n default
```
## Service Map
- **joplin** → Deployment `compose-app-joplin`, Service `compose-app-joplin` ports: 22300:22300/TCP (image: `joplin/server:latest`)