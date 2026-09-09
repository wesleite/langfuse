# Docker Daemon Windows (dockerd-win)

Esta documentação descreve a arquitetura e o funcionamento do **dockerd-win** no ambiente de **GitLab CI**, utilizado para a construção de imagens Windows a partir de runners Linux.

## Arquitetura Atual

Utilizamos um **Docker Daemon Windows centralizado**, hospedado em um nó dedicado do cluster Kubernetes.

Neste modelo, os runners Linux despacham as instruções de build via rede (TCP) para este daemon remoto. Essa estratégia permite centralizar a infraestrutura Windows, mas introduz um ponto crítico de contenção.

### Como Utilizar via Terminal

Para que o cliente Docker no Linux saiba que deve enviar o build para o nó Windows, você deve definir a variável de ambiente de rede antes de iniciar o processo.

**Comando de configuração:** export DOCKER_HOST=tcp://dockerd-win.cicd:2375

Após definir a variável acima no seu job, todos os comandos subsequentes como **docker info**, **docker build** e **docker push** serão processados diretamente no nó Windows remoto. O binário no runner Linux ignorará o socket local e enviará todo o contexto de arquivos via rede para o daemon remoto no Windows.

----------

## Desafios de Concorrência

O modelo atual de instância única persistente apresenta limitações críticas quando múltiplos pipelines são executados simultaneamente:

-   **Fila de Processamento (Blocking):** O Docker Daemon processa certos comandos de forma serial ou com paralelismo limitado. Múltiplos builds simultâneos causam disputa por recursos, resultando em timeouts e falhas nos jobs do GitLab.
-   **Poluição do Cache:** Como o ambiente é compartilhado, diferentes pipelines competem pelo mesmo espaço de cache de camadas (layers). Isso pode causar inconsistências ou lentidão inesperada durante o build.
-   **Gargalo de Rede:** O tráfego intenso de dados entre múltiplos runners Linux e um único daemon Windows satura a interface de rede do nó centralizado.
    

----------

## ⚠️ Melhoria Proposta (Não Implementada)

**Status: Em fase de planejamento / Avaliação Técnica**

Para resolver os problemas de concorrência e escalabilidade, a evolução do sistema focará na futura implementação de **Daemons Efêmeros**.

Nesta nova abordagem proposta, em vez de um daemon fixo e compartilhado, cada job de CI dispararia a criação de uma instância temporária do **dockerd-win** dedicada exclusivamente àquela execução.

### Benefícios Esperados (Pós-Implementação):

1.  **Paralelismo Real:** Cada build teria seu próprio processo de daemon, eliminando a fila de espera entre pipelines distintos.
2.  **Performance Previsível:** Sem a interferência de outros jobs no mesmo daemon, o tempo de build tornaria-se constante.
3.  **Isolamento de Cache:** Evitaria conflitos de tags ou corrupção de layers causados por processos simultâneos.
4.  **Escalabilidade Horizontal:** Permitiria que o Kubernetes distribuísse os diversos daemons entre diferentes nós do cluster conforme a demanda.
