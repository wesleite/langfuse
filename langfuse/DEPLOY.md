# Procedimento de Deploy — Stack Langfuse

> Passo a passo para implantar a stack via Helm. Baseado na documentação oficial do
> Langfuse (Context7 `/langfuse/langfuse-docs`) e na documentação oficial do
> ClickHouse (clickhouse.com/docs) para os passos do operator/cert-manager — ver
> fontes na seção 0.3. Consulte também `README.md` para a visão geral da
> arquitetura, riscos e segredos obrigatórios.

---

## 0. Pré-requisitos

### 0.1. Verificar versões

```bash
kubectl version --short          # Client/Server >= 1.28
helm version                     # >= 3.x
```

### 0.2. Instalar cert-manager

Exigido pelo ClickHouse Kubernetes Operator para emitir os certificados do webhook.

```bash
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true
```

```bash
# Verificar
kubectl get pods -n cert-manager
```

### 0.3. Instalar o ClickHouse Kubernetes Operator (CRDs + controller)

Instala as CRDs `ClickHouseCluster` e `KeeperCluster` (apiVersion `clickhouse.com/v1alpha1`)
usadas pelo chart do Langfuse quando `clickhouse.deploy: true`.

```bash
helm install clickhouse-operator oci://ghcr.io/clickhouse/clickhouse-operator-helm \
  -n clickhouse-operator-system --create-namespace
```

```bash
# Verificar
kubectl get pods -n clickhouse-operator-system
kubectl get crd | grep clickhouse.com
```

> Alternativa via `kubectl` (sem Helm), caso prefira: consulte
> [ClickHouse Docs — Install with kubectl](https://clickhouse.com/docs/clickhouse-operator/install/kubectl).
> Fonte consultada e validada para este procedimento: [ClickHouse Docs — Install with Helm](https://clickhouse.com/docs/products/kubernetes-operator/install/helm).

> ⚠️ Este passo só é necessário quando `clickhouse.deploy: true` (nosso caso, em
> `clickhouse.yaml`). Deployments que apontam para um ClickHouse externo/gerenciado
> (`clickhouse.deploy: false`) não precisam do operator.

### 0.4. Checklist final antes de instalar o Langfuse

```bash
kubectl get pods -n cert-manager
kubectl get pods -n clickhouse-operator-system
kubectl get crd | grep clickhouse.com   # deve listar clickhousecluster e keepercluster
```

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

---

## 3. Aplicar os segredos (secrets.yaml)

Todas as credenciais da stack (app, Postgres, Redis/Valkey, ClickHouse, S3/MinIO e o
bootstrap headless) vêm de um único `Secret` Kubernetes — `secrets.yaml` — referenciado
pelos values via `existingSecret`/`secretKeyRef`. **Aplicar antes do `helm install`**:

```bash
kubectl apply -f secrets.yaml
```

⚠️ **Valores de laboratório** — o arquivo já vem preenchido com senhas fixas para uso
local. **Nunca reutilizar em produção**: gere valores únicos (`openssl rand -hex 32`
para `encryption-key`/senhas, `openssl rand -base64 32` para `salt`/`nextauth-secret`)
e trate `secrets.yaml` como um arquivo sensível — **não commitar em Git com valores
reais** (adicione ao `.gitignore` fora do laboratório, ou use um secret manager externo
+ `kubectl create secret` / External Secrets Operator em vez de um YAML versionado).

Os caminhos corretos no chart usados por `web.yaml`/`worker.yaml`/`postgres.yaml`/
`redis.yaml`/`clickhouse.yaml`/`values.yaml` são `langfuse.salt.secretKeyRef`,
`langfuse.encryptionKey.secretKeyRef`, `langfuse.nextauth.secret.secretKeyRef`,
`postgresql.auth.existingSecret` (+ `settings`/`userDatabase.existingSecret`),
`redis.auth.existingSecret`/`usersExistingSecret`, `clickhouse.auth.existingSecret` e
`s3.accessKeyId`/`secretAccessKey.secretKeyRef` — todos apontando para o Secret
`langfuse` criado por este arquivo (não `langfuse.env.*`, que não existe no schema
do chart).

Para produção, ajuste também a URL pública em `langfuse.nextauth.url` (`web.yaml`/
`worker.yaml`, default `http://localhost:3000`) — pode ser sobrescrita via
`--set langfuse.nextauth.url=https://langfuse.seudominio.com` no install/upgrade sem
editar os arquivos.

---

## 4. Validar o template antes de aplicar (dry-run)

```bash
helm template langfuse langfuse/langfuse \
  -n langfuse \
  -f values.yaml \
  -f web.yaml \
  -f worker.yaml \
  -f postgres.yaml \
  -f redis.yaml \
  -f clickhouse.yaml \
  > /tmp/langfuse-rendered.yaml

# Revise o manifesto renderizado antes de aplicar
less /tmp/langfuse-rendered.yaml
```

> Se rodar isso **fora** de um cluster com o ClickHouse Operator já instalado (ex: numa
> pipeline de CI só para diff/lint), adicione:
> `--api-versions clickhouse.com/v1alpha1/ClickHouseCluster --api-versions clickhouse.com/v1alpha1/KeeperCluster`
> — isso simula as CRDs apenas para permitir a renderização offline. **Não** use isso no
> `helm install` real: lá o `crdCheck: true` deve validar as CRDs de verdade no cluster.

---

## 5. Instalar (primeira vez)

⚠️ O release **precisa se chamar `langfuse`** — os hostnames internos
(`langfuse-postgresql`, `langfuse-redis`, `langfuse-clickhouse-headless`) dependem
disso.

```bash
helm install langfuse langfuse/langfuse \
  -n langfuse \
  -f values.yaml \
  -f web.yaml \
  -f worker.yaml \
  -f postgres.yaml \
  -f redis.yaml \
  -f clickhouse.yaml \
  --wait --timeout 10m
```

> Durante o deploy, os pods `langfuse-web` e `langfuse-worker` podem reiniciar
> algumas vezes enquanto Postgres/ClickHouse ainda estão sendo provisionados —
> isso é esperado (comportamento documentado oficialmente).

---

## 6. Acompanhar o rollout

```bash
kubectl get pods -n langfuse -w
kubectl get pvc -n langfuse
kubectl logs -n langfuse deploy/langfuse-web --tail=100 -f
```

Resultado esperado: todos os pods (`web`, `worker`, `postgresql`, `redis`/valkey,
`clickhouse`, `clickhouse-keeper-0/1/2`) em `Running` e `READY`.

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

Como o bootstrap headless já cria um par de API keys fixo (`LANGFUSE_INIT_PROJECT_PUBLIC_KEY`/
`LANGFUSE_INIT_PROJECT_SECRET_KEY` em `secrets.yaml`), os scripts podem rodar sem
nenhum passo manual na UI:

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

> As chaves acima vêm direto de `secrets.yaml` — use sempre o valor atual do arquivo,
> não copie chaves de exemplos antigos (ver seção 8 sobre o gotcha de chaves
> acumuladas quando `secrets.yaml` é atualizado).

Resultado esperado: mensagens de sucesso no console e traces visíveis na UI do
Langfuse (`http://localhost:3000` → seção *Traces*).

---

## 8. Atualizar segredos (secrets.yaml) após o deploy inicial

Para trocar qualquer valor de `secrets.yaml` (senha, chave, ou as variáveis de
bootstrap `LANGFUSE_INIT_*`) numa stack já rodando:

```bash
kubectl apply -f secrets.yaml
kubectl rollout restart deployment/langfuse-web deployment/langfuse-worker -n langfuse
```

`secretKeyRef` não é recarregado a quente pelo Kubernetes — os pods só leem o valor
novo depois de recriados (`rollout restart`).

⚠️ **Gotcha do bootstrap headless**: ele só *cria* recursos que não existem — não
*atualiza* os existentes. Se você mudar `LANGFUSE_INIT_PROJECT_PUBLIC_KEY`/
`_SECRET_KEY` mantendo o mesmo `LANGFUSE_INIT_PROJECT_ID`, o Langfuse cria uma **API
key adicional** para o projeto; a chave antiga continua ativa (validei consultando a
tabela `api_keys` no Postgres). Para revogar a antiga, use a UI (Project Settings →
API Keys) ou a API — não é uma troca automática.

> Apenas variáveis **realmente lidas pela aplicação** têm efeito ao reiniciar os
> pods — ver a lista oficial de `LANGFUSE_INIT_*` no `README.md`, seção 5. Uma chave
> inventada em `secrets.yaml` (ex: `LANGFUSE_INIT_BASE_URL`, que não existe) fica
> parada no Secret sem nenhum efeito, a menos que também seja referenciada em
> `langfuse.additionalEnv` (`web.yaml`/`worker.yaml`) — e mesmo assim só funcionaria
> se fosse uma env var real da aplicação.

Se as credenciais de **Postgres/Redis/ClickHouse** mudarem (não apenas os segredos da
app/bootstrap), o `rollout restart` sozinho não é suficiente — o banco já foi
inicializado com a senha antiga. Nesse caso é preciso recriar o release e os PVCs
(ver seção 11).

---

## 9. Atualizar a stack (upgrades subsequentes)

```bash
helm upgrade langfuse langfuse/langfuse \
  -n langfuse \
  -f values.yaml \
  -f web.yaml \
  -f worker.yaml \
  -f postgres.yaml \
  -f redis.yaml \
  -f clickhouse.yaml \
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
# kubectl delete pvc -n langfuse --all   # ⚠️ destrutivo: apaga dados do Postgres/ClickHouse
```

---

## Checklist rápido

- [ ] cert-manager instalado (`helm install cert-manager oci://quay.io/jetstack/charts/cert-manager -n cert-manager --create-namespace --set crds.enabled=true`)
- [ ] ClickHouse Kubernetes Operator instalado (`helm install clickhouse-operator oci://ghcr.io/clickhouse/clickhouse-operator-helm -n clickhouse-operator-system --create-namespace`)
- [ ] `kubectl get crd | grep clickhouse.com` lista `ClickHouseCluster` e `KeeperCluster`
- [ ] Namespace `langfuse` criado
- [ ] Repositório Helm adicionado/atualizado
- [ ] `secrets.yaml` aplicado (`kubectl apply -f secrets.yaml`) — com valores próprios em homolog/prod, não os de laboratório
- [ ] `langfuse.nextauth.url` ajustado para o domínio real (produção)
- [ ] `helm template` revisado antes do `install`
- [ ] Release instalado com nome exato `langfuse`
- [ ] Pods e PVCs saudáveis (`kubectl get pods/pvc -n langfuse`)
- [ ] Scripts em `tests/` executados com sucesso
