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
  Service Account do Langfuse via `eks.amazonaws.com/role-arn` (`values.yaml`) — sem
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
  security group liberado) — ver seção 0.7.1
- **External Secrets Operator + parâmetros no AWS Systems Manager Parameter Store**
  configurados (segredos não vêm mais de um YAML estático em homolog/prod) — ver seção 0.7

```bash
# Verificar
kubectl get pods -n kube-system | grep -i aws-load-balancer
kubectl get sa -n kube-system aws-load-balancer-controller 2>&1
kubectl get storageclass gp3
```

Antes de aplicar, substitua todos os placeholders `<...>` em `values.yaml` (domínio,
ARNs, bucket, região, account ID, repos ECR de web/worker, `className: gp3` se seu
cluster usar outro nome de StorageClass).

### 0.6. Build e push das imagens para o ECR

Este repositório não contém o código-fonte do Langfuse — as imagens usadas são as
oficiais (`docker.langfuse.com/langfuse/langfuse(-worker):4.24.0`), com um único
`docker/Dockerfile` (multi-stage, stages `web` e `worker`, selecionados via
`--target`) servindo de base para customização (certs, healthcheck) antes do push
para o seu ECR:

```bash
aws ecr create-repository --repository-name langfuse-web --region <SUA_REGIAO_AWS>
aws ecr create-repository --repository-name langfuse-worker --region <SUA_REGIAO_AWS>

aws ecr get-login-password --region <SUA_REGIAO_AWS> | \
  docker login --username AWS --password-stdin <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com

docker build --target web -t <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-web:4.24.0 \
  -f docker/Dockerfile docker
docker push <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-web:4.24.0

docker build --target worker -t <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-worker:4.24.0 \
  -f docker/Dockerfile docker
docker push <SEU_ACCOUNT_ID>.dkr.ecr.<SUA_REGIAO_AWS>.amazonaws.com/langfuse-worker:4.24.0
```

`values.yaml` já aponta `langfuse.web.image.repository`/
`langfuse.worker.image.repository` para esse padrão de URI — só trocar
`<SEU_ACCOUNT_ID>`/`<SUA_REGIAO_AWS>`.

### 0.7. Segredos via AWS Systems Manager Parameter Store (homolog/prod)

Em homolog/prod, os segredos **não** vêm mais de um `Secret` estático versionado
(`secrets.local.yaml`, mantido só para Kind/lab — seção 4.1). Em vez disso, o
**External Secrets Operator (ESO)** sincroniza os valores do **AWS Systems Manager
Parameter Store** para o mesmo Secret `langfuse-secrets` que `values.yaml` já espera
via `secretKeyRef` — nenhuma mudança nos values do chart. Confirmado via
Context7 (`/websites/external-secrets_io`).

**a) Instalar o External Secrets Operator** (uma vez por cluster, namespace próprio):

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace
```

**b) Criar a IAM Role (IRSA) dedicada ao ESO** — role **separada** da IRSA de S3
(`values.yaml`), least-privilege, restrita ao path `/langfuse/<AMBIENTE>/*`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LangfuseParameterStoreRead",
      "Effect": "Allow",
      "Action": ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
      "Resource": "arn:aws:ssm:<SUA_REGIAO_AWS>:<SEU_ACCOUNT_ID>:parameter/langfuse/<AMBIENTE>/*"
    },
    {
      "Sid": "LangfuseParameterStoreDecrypt",
      "Effect": "Allow",
      "Action": ["kms:Decrypt"],
      "Resource": "arn:aws:kms:<SUA_REGIAO_AWS>:<SEU_ACCOUNT_ID>:key/<ID_DA_CHAVE_KMS>"
    }
  ]
}
```

> ⚠️ Se usar a key gerenciada padrão do SSM (`alias/aws/ssm`, aplicada automaticamente
> a todo parâmetro `SecureString` sem `--key-id` explícito), o `Resource` do statement
> de `kms:Decrypt` precisa ser o **ARN da key** (não o alias) — obtenha com
> `aws kms describe-key --key-id alias/aws/ssm --query KeyMetadata.Arn`. Para
> auditoria via CloudTrail mais granular, prefira uma **CMK dedicada**
> (`aws kms create-key`) e aponte o `--key-id` no `put-parameter` abaixo.

Associe essa role à ServiceAccount `langfuse-external-secrets` via
`eks.amazonaws.com/role-arn` (já preparado em `external-secrets/service-account.yaml`
— só falta substituir `<SEU_ACCOUNT_ID>`/`<NOME_DA_ROLE_IRSA_PARAMETER_STORE>`).

**c) Criar os parâmetros no Parameter Store** (todos como `SecureString`; troque
`<AMBIENTE>` por `homolog`/`prod` e preencha os valores reais):

```bash
REGIAO="<SUA_REGIAO_AWS>"
AMBIENTE="<AMBIENTE>"

aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/database-url" \
  --value "postgresql://usuario:senha@seu-rds.cluster-xxxx.$REGIAO.rds.amazonaws.com:5432/langfuse"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/encryption-key" --value "$(openssl rand -hex 32)"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/salt" --value "$(openssl rand -base64 32)"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/nextauth-secret" --value "$(openssl rand -base64 32)"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/redis-password" --value "<SENHA_REDIS_GERADA>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/clickhouse-password" --value "<SENHA_CLICKHOUSE_GERADA>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-org-id" --value "<ORG_ID>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-org-name" --value "<ORG_NAME>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-project-id" --value "<PROJECT_ID>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-project-name" --value "<PROJECT_NAME>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-project-public-key" --value "pk-lf-$(uuidgen)"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-project-secret-key" --value "sk-lf-$(uuidgen)"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-user-email" --value "<EMAIL_ADMIN>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-user-name" --value "<NOME_ADMIN>"
aws ssm put-parameter --region "$REGIAO" --type SecureString --overwrite \
  --name "/langfuse/$AMBIENTE/init-user-password" --value "<SENHA_ADMIN_GERADA>"
```

**d) Aplicar os manifests do ESO** (substitua `<...>` em
`external-secrets/*.yaml` antes — região, account ID, ARN da role, `<AMBIENTE>`):

```bash
kubectl apply -f external-secrets/service-account.yaml
kubectl apply -f external-secrets/secret-store.yaml
kubectl apply -f external-secrets/external-secret.yaml

# Validar
kubectl get secretstore -n langfuse
kubectl get externalsecret -n langfuse
kubectl get secret langfuse-secrets -n langfuse   # deve existir, criado pelo ESO
```

O `ExternalSecret` recria/atualiza o Secret `langfuse-secrets` automaticamente a cada
`refreshInterval` (1h) e a cada mudança no parâmetro — **não** é necessário
`kubectl apply -f secrets.local.yaml` nem `kubectl rollout restart` manual após trocar
um valor no Parameter Store (o ESO detecta o drift; o rollout dos pods ainda precisa
ser manual, pois `secretKeyRef` não é hot-reload — ver seção 8).

### 0.7.1. Postgres externo (RDS) — sem Postgres bundled

Esta stack **não** implanta Postgres dentro do cluster (`postgresql.deploy: false` em
`values.yaml`). A conexão inteira vem de uma única variável, `DATABASE_URL`, injetada via
`langfuse.additionalEnv` a partir do Secret `langfuse-secrets` (Parameter Store em
homolog/prod — seção 0.7; `secrets.local.yaml` em Kind/lab — seção 4.1):

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

## 3. Aplicar os segredos

Todas as credenciais da stack (app, Postgres externo, Redis/Valkey, ClickHouse e o
bootstrap headless) vêm de um único `Secret` Kubernetes, nome **`langfuse-secrets`**
— referenciado pelos values via `existingSecret`/`secretKeyRef`. **S3 não usa segredo
nenhum** — autentica via IAM Role (IRSA), ver seção 0.5. Como esse Secret é criado
depende do ambiente:

- **Homolog/prod**: o Secret é criado e mantido pelo **External Secrets Operator** a
  partir do **Parameter Store** — nada a aplicar aqui, já feito na seção 0.7
  (`kubectl apply -f external-secrets/*.yaml`). **Aplicar antes do `helm install`.**
- **Kind/lab (seção 4.1)**: `secrets.local.yaml` **não é versionado** (está no
  `.gitignore`, mesmo padrão de `docker-compose/.env`) — copie do template commitado
  `secrets.local.yaml.example` e aplique:

  ```bash
  cp secrets.local.yaml.example secrets.local.yaml
  kubectl apply -f secrets.local.yaml
  ```

  ⚠️ **Nunca usar `secrets.local.yaml`/`secrets.local.yaml.example` em homolog/prod** —
  gere valores únicos (`openssl rand -hex 32` para `encryption-key`, `openssl rand
  -base64 32` para `salt`/`nextauth-secret`) e trate `secrets.local.yaml` como arquivo
  sensível — ele já é ignorado pelo Git, então só o `.example` (com os placeholders de
  laboratório) fica versionado.

Os caminhos corretos no chart usados por `values.yaml` são
`langfuse.salt.secretKeyRef`, `langfuse.encryptionKey.secretKeyRef`,
`langfuse.nextauth.secret.secretKeyRef`, `langfuse.additionalEnv[].valueFrom.secretKeyRef`
(para `DATABASE_URL` e os `LANGFUSE_INIT_*`), `redis.auth.existingSecret`/
`usersExistingSecret` e `clickhouse.auth.existingSecret` — todos apontando para o
Secret **`langfuse-secrets`** (não `langfuse.env.*`, que não existe no schema do chart,
nem um nome de Secret diferente em qualquer arquivo — isso quebra o deploy).

Ajuste também a URL pública em `langfuse.nextauth.url` (`values.yaml`) para
o domínio real antes de aplicar em produção.

---

## 4. Validar o template antes de aplicar (dry-run)

```bash
helm template langfuse langfuse/langfuse \
  -n langfuse \
  -f values.yaml \
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
`docker-compose/` para só o banco) — aponte `DATABASE_URL` em `secrets.local.yaml` para ele.

(`className: ""` faz o cluster usar a StorageClass default — no Kind, `standard`.)

---

## 5. Instalar (primeira vez)

⚠️ O release **precisa se chamar `langfuse`** — os hostnames internos
(`langfuse-redis`, `langfuse-clickhouse-headless`) dependem disso.

```bash
helm install langfuse langfuse/langfuse \
  -n langfuse \
  -f values.yaml \
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
`LANGFUSE_INIT_USER_EMAIL`/`LANGFUSE_INIT_USER_PASSWORD` (Kind: `secrets.local.yaml`;
homolog/prod: parâmetros `init-user-email`/`init-user-password` no Parameter Store) —
a organização, o projeto e o usuário já foram criados automaticamente no primeiro start
(headless initialization), sem precisar passar pela tela de "Sign up".

### Via scripts de teste do SDK

```bash
cd tests
pip install langfuse python-dotenv

# Kind/lab (valores de secrets.local.yaml):
cat <<EOF > .env
LANGFUSE_PUBLIC_KEY=$(grep LANGFUSE_INIT_PROJECT_PUBLIC_KEY ../secrets.local.yaml | cut -d'"' -f2)
LANGFUSE_SECRET_KEY=$(grep LANGFUSE_INIT_PROJECT_SECRET_KEY ../secrets.local.yaml | cut -d'"' -f2)
LANGFUSE_HOST=http://localhost:3000
EOF

# Homolog/prod (valores no Parameter Store):
cat <<EOF > .env
LANGFUSE_PUBLIC_KEY=$(aws ssm get-parameter --name "/langfuse/<AMBIENTE>/init-project-public-key" --with-decryption --query Parameter.Value --output text)
LANGFUSE_SECRET_KEY=$(aws ssm get-parameter --name "/langfuse/<AMBIENTE>/init-project-secret-key" --with-decryption --query Parameter.Value --output text)
LANGFUSE_HOST=http://localhost:3000
EOF

python teste-sdk.py
python teste-langfuse.py
python teste-otel.py
```

Resultado esperado: mensagens de sucesso no console e traces visíveis na UI do
Langfuse (`http://localhost:3000` → seção *Traces*).

---

## 8. Atualizar segredos após o deploy inicial

**Homolog/prod** (Parameter Store): atualize o parâmetro e aguarde o `refreshInterval`
do `ExternalSecret` (1h) recriar o Secret — ou force a sincronização imediata:

```bash
aws ssm put-parameter --region "<SUA_REGIAO_AWS>" --type SecureString --overwrite \
  --name "/langfuse/<AMBIENTE>/<PARAMETRO>" --value "<NOVO_VALOR>"

kubectl annotate externalsecret langfuse-secrets -n langfuse \
  force-sync=$(date +%s) --overwrite
kubectl rollout restart deployment/langfuse-web deployment/langfuse-worker -n langfuse
```

**Kind/lab** (`secrets.local.yaml`):

```bash
kubectl apply -f secrets.local.yaml
kubectl rollout restart deployment/langfuse-web deployment/langfuse-worker -n langfuse
```

Em ambos os casos, `secretKeyRef` não é recarregado a quente pelo Kubernetes — os pods
só leem o valor novo depois de recriados (`rollout restart`).

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
  -f values.yaml \
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
- [ ] Instância RDS provisionada e acessível; parâmetro `database-url` no Parameter Store (homolog/prod) ou `DATABASE_URL` em `secrets.local.yaml` (Kind) aponta pra ela
- [ ] External Secrets Operator instalado e parâmetros criados no Parameter Store (seção 0.7); `external-secrets/*.yaml` aplicados e `kubectl get secret langfuse-secrets -n langfuse` existe — **ou**, só em Kind/lab, `secrets.local.yaml` aplicado (`kubectl apply -f secrets.local.yaml`)
- [ ] Placeholders `<...>` substituídos em `values.yaml`/`external-secrets/*.yaml` (domínio, ARNs, bucket, região, account ID, repo ECR)
- [ ] Pré-requisitos de EKS prontos (seção 0.5) — ou overrides de Kind aplicados (seção 4.1)
- [ ] `helm template` revisado antes do `install`
- [ ] Release instalado com nome exato `langfuse`
- [ ] Pods e PVCs saudáveis (`kubectl get pods/pvc -n langfuse`) — sem pod de Postgres
- [ ] Scripts em `tests/` executados com sucesso
