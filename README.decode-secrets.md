## Decode Kubernetes Secrets In-place


Working with Kubernetes involves dealing with secrets on a regular basis. Once a secret is created within the cluster, the sensitive data is base64 encoded for security through obscurity. If you want to view the plain text secrets, the encoded values must be decoded. Decoding secret data repeatedly or with many values can lead to fatigue and remorse.

There are a variety of ways to decode Kubernetes secrets, but I was interested in decoding only the encrypted data values and leaving the other portions intact.

I wanted a way to decode Kubernetes secrets in-place. Other approaches I googled resulted in incomplete output (i.e. just the data part). So I wrote a bash script that can accept secrets on standard input or a filename.

### Requirements

Your system must have perl installed. MacOS and most Linux have perl by default.

### Clone

Get repo containing script decode-secrets.

```
git clone https://github.com/rcompos/ktools
```

### Copy script to /usr/local/bin

Copy to /usr/local/bin or somewhere in your executable path (i.e. make sure it's is in your PATH environmental variable).
Now you can run as `decode-secrets` instead of `./decode-secrets`.

```
cp ktools/decode-secrets /usr/local/bin
decode-secrets help me
```

### Create secret

Run kubectl to create a test secret.

```
cd ktools
kubectl apply -f dummy-secret.yaml
```

### Get secret

Run kubectl to get secret from the cluster. Notice the data section values are encoded base64.

```
kubectl get secret dummy-secret -o yaml
```

```
apiVersion: v1
data:
  APP: Y293c2FpZA==
  IP: NTQuMjEzLjE5NC4xNTE=
  PASS: bXktcGFzc3dvcmQ=
  PORT: ODA=
  USER: bXktdXNlcm5hbWU=
kind: Secret
metadata:
  name: dummy-secret
  namespace: default
type: Opaque
```

### Decode in-place

List Kubernetes secret and decode in place using decode-secrets. Now the data values are quoted plain text and type stringData.

```
kubectl get secret dummy-secret -o yaml | decode-secrets
```

```
apiVersion: v1
stringData:
  APP: "cowsaid"
  IP: "54.213.194.151"
  PASS: "my-password"
  PORT: "80"
  USER: "my-username"
kind: Secret
metadata:
  name: dummy-secret
  namespace: default
type: Opaque
```

### Decode, edit, apply

Save decoded secret to file for editing. Then apply to cluster.

```
kubectl get secret dummy-secret -o yaml | decode-secrets > secrets_file.yaml

Edit secrets_file.yaml to change data values

kubectl apply -f secrets_file.yaml
```

### Decode yaml file

Pass a filename argument.

```
decode-secrets dummy-secret.yaml
```

### Clean up

Delete secret.

```
kubectl delete secrets dummy-secret
```

### Script usage

```
Decode kubernetes secrets yaml from file or stdin
Usage:  /usr/local/bin/decode-secrets [secrets_file]
  Supply optional file name for Kubernetes secrets
  yaml as command-line argument

Example:  kubectl get secret dummy-secret -o yaml | decode-secrets
Example:  cat dummy-secret.yaml | decode-secrets
Example:  decode-secrets < `echo dummy-secret.yaml`
```
