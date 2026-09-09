# Procedimento de Deploy — Stack Langfuse

> Passo a passo para implantar a stack via Helm. Baseado na documentação oficial:
> [github.com/langfuse/langfuse-k8s](https://github.com/langfuse/langfuse-k8s) (README +
> `charts/langfuse/values.yaml` + `examples/minimal-installation/`), Context7
> (`/langfuse/langfuse-docs`) e a documentação oficial do ClickHouse
> (clickhouse.com/docs) para os passos do operator/cert-manager — ver seção 0.3.
> Consulte também `README.md` para a visão geral da arquitetura, riscos e segredos.
>
> ⚠️ Esta stack assume **Amazon EKS** como alvo padrão: Ingress ALB, imagens via
> **ECR**, S3 via **IAM Role/IRSA**, StorageClass `gp3`, e **Postgres externo (RDS)** —
> não há Postgres bundled no cluster. Para testar em **Kind/local**, veja os overrides
> na seção 4.1.

---

## 0. Pré-requisitos

### 0.1. Verificar versões

```bash
kubectl version --short          # Client/Server >= 1.28
helm version                     # >= 3.17 (fromToml, exigido pelo chart)
```

### 0.2. Instalar cert-manager

Exigido pelo ClickHouse Kubernetes Operator para emitir os certificados do webhook.

```bash
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.20.2 \
  -n cert-manager --create-namespace \
  --set crds.enabled=true

kubectl wait --for=condition=Established \
  crd/certificates.cert-manager.io crd/issuers.cert-manager.io \
  --timeout=120s
```

### 0.3. Instalar o ClickHouse Kubernetes Operator (CRDs + controller)

Instala as CRDs `ClickHouseCluster` e `KeeperCluster` (apiVersion `clickhouse.com/v1alpha1`)
usadas pelo chart do Langfuse quando `clickhouse.deploy: true`.

```bash
helm install clickhouse-operator oci://ghcr.io/clickhouse/clickhouse-operator-helm \
  --version 0.0.5 \
  -n clickhouse-operator-system --create-namespace

kubectl wait --for=condition=Established \
  crd/clickhouseclusters.clickhouse.com crd/keeperclusters.clickhouse.com \
  --timeout=120s
```

> Alternativa via `kubectl` (sem Helm): [ClickHouse Docs — Install with kubectl](https://clickhouse.com/docs/clickhouse-operator/install/kubectl).
> Fontes: [github.com/langfuse/langfuse-k8s](https://github.com/langfuse/langfuse-k8s) (README) e
> [ClickHouse Docs — Install with Helm](https://clickhouse.com/docs/products/kubernetes-operator/install/helm).

### 0.4. Checklist final antes de instalar o Langfuse

```bash
kubectl get pods -n cert-manager
kubectl get pods -n clickhouse-operator-system
kubectl get crd | grep clickhouse.com   # deve listar clickhousecluster e keepercluster
```

### 0.5. Pré-requisitos ADICIONAIS para Amazon EKS

- **AWS Load Balancer Controller** instalado no cluster (fornece a `IngressClassName: alb`)
- **Addon EBS CSI Driver** habilitado no cluster + **StorageClass `gp3`** criada
  (nem todo cluster EKS vem com uma por padrão — Redis e ClickHouse/Keeper usam)
- **Bucket S3** real criado
- **IAM Role (IRSA)** com permissão de leitura/escrita nesse bucket, associada à
  Service Account do Langfuse via `eks.amazonaws.com/role-arn` (`web.yaml`) — sem
  access key/secret key fixos, autenticação por identidade do pod. Policy mínima
  necessária (confirmada na documentação oficial do Langfuse, seção *Amazon S3*):
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "EventBucketAccess",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:ListBucket", "s3:GetObject"],
      "Resource": ["arn:aws:s3:::<SEU_BUCKET_S3>", "arn:aws:s3:::<SEU_BUCKET_S3>/*"]
    }]
  }
  ```
  Para Data Retention, adicione também `s3:DeleteObject` à Action.
- **Certificado ACM** emitido para o domínio público (referenciado no Ingress)
- **Repositórios ECR** criados para `langfuse-web` e `langfuse-worker` (ver seção 0.6)
- **Instância RDS PostgreSQL** provisionada, acessível a partir do cluster (mesma VPC/
  security group liberado) — ver seção 0.7

```bash
# Verificar
kubectl get pods -n kube-system | grep -i aws-load-balancer
kubectl get sa -n kube-system aws-load-balancer-controller 2>&1
kubectl get storageclass gp3
```

Antes de aplicar, substitua todos os placeholders `<...>` em `web.yaml` (domínio, ARNs,
bucket, região, account ID, repo ECR) e `worker.yaml` (repo ECR, `className: gp3`, se
seu cluster usar outro nome de StorageClass).

### 0.6. Build e push das imagens para o ECR

Este repositório não contém o código-fonte do Langfuse — as imagens usadas são as
oficiais (`docker.langfuse.com/langfuse/langfuse(-worker):4.24.0`), com os Dockerfiles
em `docker/web/` e `docker/worker/` servindo de base para customização (certs, health
check) antes do push para o seu ECR:

```bash
aws ecr create-repository --repository-name langfuse-web --region <SUA_REGIAO_AWS>
aws ecr create-repository --repository-name langfuse-worker --region <SUA_REGIAO_AWS>

aws ecr get-login-password --region <SUA_REGIAO_AWS> | \
  docker login --username AWS --password-stdin <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com

docker build -t <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-web:4.24.0 \
  -f docker/web/Dockerfile docker/web
docker push <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-web:4.24.0

docker build -t <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-worker:4.24.0 \
  -f docker/worker/Dockerfile docker/worker
docker push <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-worker:4.24.0
```

`web.yaml`/`worker.yaml` já apontam `langfuse.web.image.repository`/
`langfuse.worker.image.repository` para esse padrão de URI — só trocar
`<SEU_ACCOUNT_ID>`/`<SUA_REGIAO_AWS>`.

### 0.7. Postgres externo (RDS) — sem Postgres bundled

Esta stack **não** implanta Postgres dentro do cluster (`postgresql.deploy: false` em
`web.yaml`). A conexão inteira vem de uma única variável, `DATABASE_URL`, injetada via
`langfuse.additionalEnv` a partir de `secrets.yaml`:

```yaml
DATABASE_URL: "postgresql://usuario:senha@seu-rds.cluster-xxxx.regiao.rds.amazonaws.com:5432/langfuse"
```

⚠️ **Não defina** `postgresql.host`/`postgresql.auth.*` (config estruturada) em nenhum
arquivo — o chart valida que você não misture `additionalEnv` com a config estruturada
do Postgres, e `helm template` falha se os dois estiverem presentes ao mesmo tempo.

Garanta que o banco `langfuse` já exista no RDS (ou que o usuário na connection string
tenha permissão para criá-lo) — as migrações do Prisma rodam automaticamente no
startup do `web` contra essa URL.

---

## 1. Criar o namespace

```bash
kubectl create namespace langfuse
```

---

## 2. Adicionar o repositório Helm oficial

```bash
helm repo add langfuse https://langfuse.github.io/langfuse-k8s
helm repo update
```

> O método "canônico" atual no README oficial é via OCI
> (`oci://ghcr.io/langfuse/langfuse-k8s/charts/langfuse`); o `helm repo add` acima é o
> método "alternativo" documentado — ambos funcionam. Usamos o `helm repo add` por
> manter o histórico de validação deste projeto (`helm lint`/`helm template` testados
> extensivamente com ele).

---

## 3. Aplicar os segredos (secrets.yaml)

Todas as credenciais da stack (app, Postgres externo, Redis/Valkey, ClickHouse e o
bootstrap headless) vêm de um único `Secret` Kubernetes — **`secrets.yaml`, nome
`langfuse-secrets`** — referenciado pelos values via `existingSecret`/`secretKeyRef`.
**S3 não usa segredo nenhum** — autentica via IAM Role (IRSA), ver seção 0.5.
**Aplicar antes do `helm install`**:

```bash
kubectl apply -f secrets.yaml
```

⚠️ **Valores de laboratório** — o arquivo já vem preenchido com senhas fixas para uso
local (exceto `DATABASE_URL`, que já precisa ser um RDS real ou outro Postgres externo
acessível). **Nunca reutilizar em produção**: gere valores únicos (`openssl rand -hex 32`
para `encryption-key`, `openssl rand -base64 32` para `salt`/`nextauth-secret`) e trate
`secrets.yaml` como um arquivo sensível — **não commitar em Git com valores reais**
(adicione ao `.gitignore` fora do laboratório, ou use um secret manager externo +
`kubectl create secret` / External Secrets Operator em vez de um YAML versionado).

Os caminhos corretos no chart usados por `web.yaml`/`worker.yaml` são
`langfuse.salt.secretKeyRef`, `langfuse.encryptionKey.secretKeyRef`,
`langfuse.nextauth.secret.secretKeyRef`, `langfuse.additionalEnv[].valueFrom.secretKeyRef`
(para `DATABASE_URL` e os `LANGFUSE_INIT_*`), `redis.auth.existingSecret`/
`usersExistingSecret` e `clickhouse.auth.existingSecret` — todos apontando para o
Secret **`langfuse-secrets`** (não `langfuse.env.*`, que não existe no schema do chart,
nem um nome de Secret diferente em qualquer arquivo — isso quebra o deploy).

Ajuste também a URL pública em `langfuse.nextauth.url` (`web.yaml`/`worker.yaml`) para
o domínio real antes de aplicar em produção.

---

## 4. Validar o template antes de aplicar (dry-run)

```bash
helm template langfuse langfuse/langfuse \
  -n langfuse \
  -f web.yaml \
  -f worker.yaml \
  > /tmp/langfuse-rendered.yaml

# Revise o manifesto renderizado antes de aplicar
less /tmp/langfuse-rendered.yaml
```

> Se rodar isso **fora** de um cluster com o ClickHouse Operator já instalado (ex: numa
> pipeline de CI só para diff/lint), adicione:
> `--api-versions clickhouse.com/v1alpha1/ClickHouseCluster --api-versions clickhouse.com/v1alpha1/KeeperCluster`
> — isso simula as CRDs apenas para permitir a renderização offline. **Não** use isso no
> `helm install` real: lá o `crdCheck: true` deve validar as CRDs de verdade no cluster.

### 4.1. Testar em Kind/local (sem AWS real)

Os arquivos assumem EKS + RDS externo por padrão. Para testar num Kind local (sem ALB
Controller, IAM Role, StorageClass `gp3`, ECR ou RDS), sobrescreva via `--set` sem
editar os arquivos — por exemplo, com um Postgres e S3 (MinIO) locais:

```bash
--set langfuse.ingress.enabled=false \
--set langfuse.serviceAccount.annotations=null \
--set langfuse.web.image.repository=docker.langfuse.com/langfuse/langfuse \
--set langfuse.web.image.tag=4.24.0 \
--set langfuse.worker.image.repository=docker.langfuse.com/langfuse/langfuse-worker \
--set langfuse.worker.image.tag=4.24.0 \
--set redis.dataStorage.className="" \
--set clickhouse.cluster.storage.className="" \
--set clickhouse.keeper.storage.className="" \
--set s3.endpoint=http://minio:9000 \
--set s3.bucket=langfuse \
--set s3.region=us-east-1 \
--set s3.forcePathStyle=true \
--set s3.accessKeyId.value=minio \
--set s3.secretAccessKey.value=miniosecret
```

⚠️ Como não há mais Postgres bundled nesta stack, testar no Kind exige um Postgres
real acessível (ex: `docker run postgres:18` na mesma rede, ou reaproveitar o
`docker-compose/` para só o banco) — aponte `DATABASE_URL` em `secrets.yaml` para ele.

(`className: ""` faz o cluster usar a StorageClass default — no Kind, `standard`.)

---

## 5. Instalar (primeira vez)

⚠️ O release **precisa se chamar `langfuse`** — os hostnames internos
(`langfuse-redis`, `langfuse-clickhouse-headless`) dependem disso.

```bash
helm install langfuse langfuse/langfuse \
  -n langfuse \
  -f web.yaml \
  -f worker.yaml \
  --wait --timeout 10m
```

> Durante o deploy, os pods `langfuse-web` e `langfuse-worker` podem reiniciar
> algumas vezes enquanto o RDS/ClickHouse ainda não respondem — isso é esperado.

---

## 6. Acompanhar o rollout

```bash
kubectl get pods -n langfuse -w
kubectl get pvc -n langfuse
kubectl logs -n langfuse deploy/langfuse-web --tail=100 -f
```

Resultado esperado: todos os pods (`web`, `worker`, `redis`/valkey, `clickhouse`,
`clickhouse-keeper-0/1/2`) em `Running` e `READY`. Sem pod de Postgres (externo/RDS).

---

## 7. Validar a aplicação

### Via port-forward (local/sem Ingress)

```bash
kubectl port-forward -n langfuse svc/langfuse-web 3000:3000
```

Acesse `http://localhost:3000` e faça login com as credenciais de
`LANGFUSE_INIT_USER_EMAIL`/`LANGFUSE_INIT_USER_PASSWORD` em `secrets.yaml` — a
organização, o projeto e o usuário já foram criados automaticamente no primeiro start
(headless initialization), sem precisar passar pela tela de "Sign up".

### Via scripts de teste do SDK

```bash
cd tests
pip install langfuse python-dotenv

cat <<EOF > .env
LANGFUSE_PUBLIC_KEY=$(grep LANGFUSE_INIT_PROJECT_PUBLIC_KEY ../secrets.yaml | cut -d'"' -f2)
LANGFUSE_SECRET_KEY=$(grep LANGFUSE_INIT_PROJECT_SECRET_KEY ../secrets.yaml | cut -d'"' -f2)
LANGFUSE_HOST=http://localhost:3000
EOF

python teste-sdk.py
python teste-langfuse.py
python teste-otel.py
```

Resultado esperado: mensagens de sucesso no console e traces visíveis na UI do
Langfuse (`http://localhost:3000` → seção *Traces*).

---

## 8. Atualizar segredos (secrets.yaml) após o deploy inicial

```bash
kubectl apply -f secrets.yaml
kubectl rollout restart deployment/langfuse-web deployment/langfuse-worker -n langfuse
```

`secretKeyRef` não é recarregado a quente pelo Kubernetes — os pods só leem o valor
novo depois de recriados (`rollout restart`).

⚠️ **Gotcha do bootstrap headless**: ele só *cria* recursos que não existem — não
*atualiza* os existentes. Se você mudar `LANGFUSE_INIT_PROJECT_PUBLIC_KEY`/
`_SECRET_KEY` mantendo o mesmo `LANGFUSE_INIT_PROJECT_ID`, o Langfuse cria uma **API
key adicional** para o projeto; a chave antiga continua ativa. Para revogar a antiga,
use a UI (Project Settings → API Keys) ou a API.

Se `DATABASE_URL` mudar para apontar a outro RDS, o `rollout restart` é suficiente
(não há Postgres bundled para recriar).

---

## 9. Atualizar a stack (upgrades subsequentes)

```bash
helm upgrade langfuse langfuse/langfuse \
  -n langfuse \
  -f web.yaml \
  -f worker.yaml \
  --wait --timeout 10m
```

---

## 10. Rollback

```bash
helm history langfuse -n langfuse
helm rollback langfuse <REVISION> -n langfuse
```

---

## 11. Desinstalar

```bash
helm uninstall langfuse -n langfuse

# PVCs não são removidos automaticamente pelo Helm — decisão explícita:
kubectl get pvc -n langfuse
# kubectl delete pvc -n langfuse --all   # ⚠️ destrutivo: apaga dados do Redis/ClickHouse
```

O RDS (externo) não é afetado pelo `helm uninstall` — gerenciado fora do Helm.

---

## Checklist rápido

- [ ] cert-manager instalado (`helm install cert-manager oci://quay.io/jetstack/charts/cert-manager --version v1.20.2 -n cert-manager --create-namespace --set crds.enabled=true`)
- [ ] ClickHouse Kubernetes Operator instalado (`helm install clickhouse-operator oci://ghcr.io/clickhouse/clickhouse-operator-helm --version 0.0.5 -n clickhouse-operator-system --create-namespace`)
- [ ] `kubectl get crd | grep clickhouse.com` lista `ClickHouseCluster` e `KeeperCluster`
- [ ] Namespace `langfuse` criado
- [ ] Repositório Helm adicionado/atualizado
- [ ] Repositórios ECR criados e imagens (web/worker) buildadas e enviadas (seção 0.6)
- [ ] Instância RDS provisionada e acessível; `DATABASE_URL` em `secrets.yaml` aponta pra ela
- [ ] `secrets.yaml` aplicado (`kubectl apply -f secrets.yaml`) — com valores próprios em homolog/prod, não os de laboratório
- [ ] Placeholders `<...>` substituídos em `web.yaml`/`worker.yaml` (domínio, ARNs, bucket, região, account ID, repo ECR)
- [ ] Pré-requisitos de EKS prontos (seção 0.5) — ou overrides de Kind aplicados (seção 4.1)
- [ ] `helm template` revisado antes do `install`
- [ ] Release instalado com nome exato `langfuse`
- [ ] Pods e PVCs saudáveis (`kubectl get pods/pvc -n langfuse`) — sem pod de Postgres
- [ ] Scripts em `tests/` executados com sucesso
